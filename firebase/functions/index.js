/**
 * Production Cloud Functions for Share Your Idea.
 *
 * Canonical Smart Engine:
 * - Node.js Cloud Functions
 * - OpenAI text-embedding-3-small
 * - Pinecone vector search
 *
 * Python/S-BERT code is deprecated tooling only and is not deployed from
 * firebase.json.
 */

const { createHash } = require('crypto');
const { onCall, onRequest, HttpsError } = require('firebase-functions/v2/https');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { setGlobalOptions } = require('firebase-functions/v2');
const { defineSecret, defineString } = require('firebase-functions/params');
const admin = require('firebase-admin');
const Stripe = require('stripe');
const { Pinecone } = require('@pinecone-database/pinecone');
const OpenAI = require('openai').default;
const { GoogleAuth } = require('google-auth-library');

admin.initializeApp();
const db = admin.firestore();

setGlobalOptions({ region: 'europe-west1', maxInstances: 10 });

const OPENAI_API_KEY = defineSecret('OPENAI_API_KEY');
const PINECONE_API_KEY = defineSecret('PINECONE_API_KEY');
const STRIPE_SECRET_KEY = defineSecret('STRIPE_SECRET_KEY');
const STRIPE_WEBHOOK_SECRET = defineSecret('STRIPE_WEBHOOK_SECRET');
const GOOGLE_PLAY_SERVICE_ACCOUNT_JSON = defineSecret('GOOGLE_PLAY_SERVICE_ACCOUNT_JSON');
const PINECONE_INDEX_NAME = defineString('PINECONE_INDEX_NAME', { default: 'ideabank' });
const GOOGLE_PLAY_PACKAGE_NAME = defineString('GOOGLE_PLAY_PACKAGE_NAME', { default: 'com.shareyouridea.app' });
const ADMIN_UIDS = defineString('ADMIN_UIDS', { default: '' });

const SMART_ENGINE_VERSION = '2026-04-v1';
const EMBEDDING_MODEL = 'text-embedding-3-small';
const THRESHOLDS = {
  duplicate: 0.85,
  needsReview: 0.65,
};

const IDEA_STATUSES = new Set([
  'draft',
  'processing',
  'pending_review',
  'active',
  'flagged',
  'returned',
  'needs_review',
  'rejected',
  'sold',
  'archived',
  'error',
]);
const PITCH_STATUSES = new Set(['pending', 'accepted', 'rejected', 'submitted', 'completed']);
const DEAL_ROOM_PITCH_STATUSES = new Set(['accepted', 'submitted', 'completed']);
const DEAL_PROPOSAL_STATUSES = new Set(['active', 'accepted', 'declined', 'countered']);
const DEAL_ACTIONS = new Set(['accept', 'decline']);
const DEAL_TYPES = new Set(['Buy', 'Partnership', 'License', 'Open']);
const DEAL_CURRENCIES = new Set(['NOK', 'USD', 'EUR']);
const USER_ROLES = new Set(['innovator', 'patron', 'both']);
const ACCOUNT_STATUSES = new Set(['active', 'suspended', 'banned']);
const REPORT_REASONS = {
  duplicate_false_negative: 'Duplicate of existing idea (IIAE false negative)',
  misleading_or_false_description: 'Misleading or false description',
  tos_violation: 'Violation of ToS',
  illegal_content: 'Illegal content',
};
const REPORT_RESOLUTIONS = new Set(['keep', 'reject', 'request_edit']);
const PATRON_SUBSCRIPTION_PRODUCT_IDS = new Set(['patron_monthly_v1', 'patron_yearly_v1']);
const CATEGORIES = new Set([
  'SaaS',
  'Green Tech',
  'Local Solutions',
  'Technology',
  'Health & Wellness',
  'Education',
  'Entertainment',
  'Sustainability',
  'Finance',
  'Social Impact',
  'Food & Beverage',
  'Fashion & Design',
  'Other',
]);
const PRICE_MIN = 5000;
const PRICE_MAX = 500000;

let _openai = null;
let _pinecone = null;
let _stripe = null;

function getOpenAI() {
  if (!_openai) _openai = new OpenAI({ apiKey: OPENAI_API_KEY.value() });
  return _openai;
}

function getPineconeIndex() {
  if (!_pinecone) _pinecone = new Pinecone({ apiKey: PINECONE_API_KEY.value() });
  return _pinecone.index(PINECONE_INDEX_NAME.value() || 'ideabank');
}

function getStripe() {
  if (!_stripe) {
    _stripe = new Stripe(STRIPE_SECRET_KEY.value(), { apiVersion: '2024-04-10' });
  }
  return _stripe;
}

function getGooglePlayCredentials() {
  try {
    const raw = GOOGLE_PLAY_SERVICE_ACCOUNT_JSON.value();
    const credentials = JSON.parse(raw);
    if (!credentials.client_email || !credentials.private_key) {
      throw new Error('Missing client_email or private_key.');
    }
    return credentials;
  } catch (err) {
    throw new HttpsError(
      'failed-precondition',
      'Google Play service account secret is not configured correctly.',
    );
  }
}

async function getGooglePlayClient() {
  const auth = new GoogleAuth({
    credentials: getGooglePlayCredentials(),
    scopes: ['https://www.googleapis.com/auth/androidpublisher'],
  });
  return auth.getClient();
}

function assertGooglePlayPurchaseToken(value) {
  const token = assertString(value, 'receiptToken', 4096);
  if (
    token.startsWith('mvp-') ||
    token.startsWith('manual-') ||
    token.startsWith('test-') ||
    token.includes('manual-access')
  ) {
    throw new HttpsError('invalid-argument', 'Google Play purchase token is required.');
  }
  return token;
}

async function validateGooglePlaySubscription({ productId, purchaseToken }) {
  if (!PATRON_SUBSCRIPTION_PRODUCT_IDS.has(productId)) {
    throw new HttpsError('invalid-argument', 'Unknown Patron subscription product.');
  }

  const packageName = GOOGLE_PLAY_PACKAGE_NAME.value();
  const client = await getGooglePlayClient();
  const url =
    `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${encodeURIComponent(packageName)}` +
    `/purchases/subscriptions/${encodeURIComponent(productId)}/tokens/${encodeURIComponent(purchaseToken)}`;

  let response;
  try {
    response = await client.request({ url, method: 'GET' });
  } catch (err) {
    console.error('[Google Play] subscription validation failed:', err.message);
    throw new HttpsError('permission-denied', 'Google Play receipt validation failed.');
  }

  const subscription = response.data || {};
  const expiryTimeMillis = Number(subscription.expiryTimeMillis || 0);
  const paymentState = subscription.paymentState == null ? null : Number(subscription.paymentState);
  const acknowledgementState =
    subscription.acknowledgementState == null ? null : Number(subscription.acknowledgementState);

  if (!expiryTimeMillis || expiryTimeMillis <= Date.now()) {
    throw new HttpsError('failed-precondition', 'Google Play subscription is expired.');
  }
  if (paymentState === 0) {
    throw new HttpsError('failed-precondition', 'Google Play payment is still pending.');
  }

  if (acknowledgementState === 0) {
    const acknowledgeUrl = `${url}:acknowledge`;
    try {
      await client.request({
        url: acknowledgeUrl,
        method: 'POST',
        data: { developerPayload: '' },
      });
    } catch (err) {
      console.warn('[Google Play] subscription acknowledgement failed:', err.message);
    }
  }

  return {
    endDate: admin.firestore.Timestamp.fromMillis(expiryTimeMillis),
    orderId: subscription.orderId || null,
    paymentState,
    acknowledgementState,
    autoRenewing: subscription.autoRenewing === true,
    purchaseType: subscription.purchaseType ?? null,
    rawStatus: {
      cancelReason: subscription.cancelReason ?? null,
      priceCurrencyCode: subscription.priceCurrencyCode ?? null,
      countryCode: subscription.countryCode ?? null,
    },
  };
}

function requireAuth(request) {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Login required.');
  return request.auth.uid;
}

function requireVerifiedEmail(request) {
  if (request.auth?.token?.email_verified !== true) {
    throw new HttpsError('permission-denied', 'Verified email required.');
  }
}

async function getUser(uid) {
  const snap = await db.collection('users').doc(uid).get();
  if (!snap.exists) throw new HttpsError('failed-precondition', 'User profile missing.');
  return snap.data();
}

function assertAccountUsable(user) {
  const status = user.accountStatus || 'active';
  if (!ACCOUNT_STATUSES.has(status)) {
    throw new HttpsError('failed-precondition', 'Account status is invalid.');
  }
  if (status === 'suspended' || status === 'banned') {
    throw new HttpsError('permission-denied', 'This account is not allowed to perform this action.');
  }
}

async function requireUsableUser(uid) {
  const user = await getUser(uid);
  assertAccountUsable(user);
  return user;
}

async function requireRole(uid, allowedRoles) {
  const user = await getUser(uid);
  assertAccountUsable(user);
  if (!USER_ROLES.has(user.role) || !allowedRoles.includes(user.role)) {
    throw new HttpsError('permission-denied', 'This account role cannot perform this action.');
  }
  return user;
}

async function isAdminUser(uid, token = {}) {
  if (!uid) return false;
  if (token.admin === true) return true;

  const configuredUids = (ADMIN_UIDS.value() || '')
    .split(',')
    .map((v) => v.trim())
    .filter(Boolean);
  if (configuredUids.includes(uid)) return true;

  const adminSnap = await db.collection('admins').doc(uid).get();
  return adminSnap.exists && adminSnap.data()?.active !== false;
}

async function requireAdmin(request) {
  const uid = requireAuth(request);
  if (!(await isAdminUser(uid, request.auth?.token || {}))) {
    throw new HttpsError('permission-denied', 'Admin access required.');
  }
  return uid;
}

async function hasActiveSubscription(uid) {
  const snap = await db.collection('subscriptions').doc(uid).get();
  if (!snap.exists) return false;
  const sub = snap.data();
  const endDate = sub.endDate;
  return sub.status === 'active' &&
    endDate &&
    endDate.toMillis &&
    endDate.toMillis() > Date.now();
}

async function hasAcceptedCurrentNDA(uid) {
  const snap = await db.collection('users').doc(uid).collection('consents').doc('nda_v1').get();
  if (!snap.exists) return false;
  const consent = snap.data() || {};
  return consent.type === 'nda' &&
    consent.version === 'v1' &&
    typeof consent.textHash === 'string' &&
    consent.textHash.length > 0 &&
    typeof consent.acceptedAt?.toMillis === 'function' &&
    consent.acceptedAt.toMillis() <= Date.now();
}

async function requireCurrentNDA(uid) {
  if (!(await hasAcceptedCurrentNDA(uid))) {
    throw new HttpsError('permission-denied', 'Current NDA acceptance required.');
  }
}

async function requireActiveSubscription(request) {
  const uid = requireAuth(request);
  requireVerifiedEmail(request);
  await requireUsableUser(uid);
  if (!(await hasActiveSubscription(uid))) {
    throw new HttpsError('permission-denied', 'Active Patron subscription required.');
  }
  await requireCurrentNDA(uid);
  return uid;
}

function countWords(value) {
  const text = String(value || '').trim();
  return text.length === 0 ? 0 : text.split(/\s+/).length;
}

function assertString(value, field, maxChars = 2000) {
  if (typeof value !== 'string') {
    throw new HttpsError('invalid-argument', `${field} must be a string.`);
  }
  const trimmed = value.trim();
  if (trimmed.length === 0) {
    throw new HttpsError('invalid-argument', `${field} is required.`);
  }
  if (trimmed.length > maxChars) {
    throw new HttpsError('invalid-argument', `${field} is too long.`);
  }
  return trimmed;
}

function assertEmail(value) {
  const email = assertString(value, 'contactEmail', 320).toLowerCase();
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    throw new HttpsError('invalid-argument', 'contactEmail is invalid.');
  }
  return email;
}

function optionalTrimmedString(value, field, maxChars = 2000) {
  if (value == null) return undefined;
  if (typeof value !== 'string') {
    throw new HttpsError('invalid-argument', `${field} must be a string.`);
  }
  const trimmed = value.trim();
  if (trimmed.length > maxChars) {
    throw new HttpsError('invalid-argument', `${field} is too long.`);
  }
  return trimmed;
}

function parseReportReason(value) {
  const reasonCode = assertString(value, 'reason', 80);
  const reasonLabel = REPORT_REASONS[reasonCode];
  if (!reasonLabel) {
    throw new HttpsError('invalid-argument', 'Invalid report reason.');
  }
  return { reasonCode, reasonLabel };
}

function assertDealCurrency(value) {
  const currency = assertString(value || 'NOK', 'currency', 8).toUpperCase();
  if (!DEAL_CURRENCIES.has(currency)) {
    throw new HttpsError('invalid-argument', 'Invalid currency.');
  }
  return currency;
}

function assertDealType(value) {
  const raw = assertString(value || 'Open', 'collaborationType', 40);
  const normalized = raw.trim().toLowerCase();
  const type = [...DEAL_TYPES].find((candidate) => candidate.toLowerCase() === normalized);
  if (!type) throw new HttpsError('invalid-argument', 'Invalid collaboration type.');
  return type;
}

function assertDealAmount(value) {
  const amount = Number(value);
  if (!Number.isInteger(amount) || amount < 100 || amount > 100000000) {
    throw new HttpsError('invalid-argument', 'Invalid proposal amount.');
  }
  return amount;
}

function roleForPitch(pitch, uid) {
  if (pitch.patronId === uid) return 'patron';
  if (pitch.innovatorId === uid) return 'innovator';
  throw new HttpsError('permission-denied', 'Not part of this Deal Room.');
}

async function getPitchForParticipant(uid, pitchId) {
  const pitchRef = db.collection('pitches').doc(pitchId);
  const snap = await pitchRef.get();
  if (!snap.exists) throw new HttpsError('not-found', 'Pitch not found.');
  const pitch = snap.data();
  const role = roleForPitch(pitch, uid);
  return { pitchRef, pitch, role };
}

function assertDealRoomOpen(pitch) {
  if (!DEAL_ROOM_PITCH_STATUSES.has(pitch.status)) {
    throw new HttpsError('failed-precondition', 'Deal Room opens after the request is accepted.');
  }
}

function normalizeText({
  title,
  body,
  category,
  problem = '',
  targetAudience = '',
  executionPlan = '',
}) {
  return [
    `category: ${category}`,
    `title: ${title}`,
    `body: ${body}`,
    `problem: ${problem}`,
    `target audience: ${targetAudience}`,
    `execution plan: ${executionPlan}`,
  ]
    .join('\n')
    .normalize('NFKC')
    .toLowerCase()
    .replace(/[^\S\r\n]+/g, ' ')
    .replace(/[!?.,;:]{3,}/g, '.')
    .trim();
}

function sha256(value) {
  return createHash('sha256').update(value).digest('hex');
}

const BLOCKED_WORDS = [
  'fuck', 'shit', 'bitch', 'asshole', 'bastard', 'crap', 'piss', 'dick',
  'cock', 'pussy', 'cunt', 'whore', 'slut',
];
const BLOCKED_REGEX = new RegExp(BLOCKED_WORDS.join('|'), 'i');

function isGibberishWord(word) {
  if (word.length <= 3) return false;
  const vowels = (word.match(/[aeiouaeoAEIOUAEO]/g) || []).length;
  return vowels / word.length < 0.15;
}

function sanitizeSegment(text) {
  const t = String(text || '').trim();
  if (t.length < 3) return { ok: true };
  if (/^(.)\1{9,}$/.test(t)) return { ok: false, reason: 'Teksten ser ut som spam.' };

  const tokens = t.toLowerCase().split(/\s+/);
  const freq = {};
  for (const w of tokens) freq[w] = (freq[w] || 0) + 1;
  const maxFreq = Math.max(...Object.values(freq));
  if (tokens.length > 3 && maxFreq / tokens.length > 0.6) {
    return { ok: false, reason: 'Teksten inneholder for mye repetisjon.' };
  }

  const wordTokens = tokens.filter((w) => /^\p{L}+$/u.test(w));
  if (wordTokens.length >= 2) {
    const gibCount = wordTokens.filter(isGibberishWord).length;
    if (gibCount / wordTokens.length > 0.5) {
      return { ok: false, reason: 'Teksten ser ut som tilfeldig tastatur-input.' };
    }
  }

  if (BLOCKED_REGEX.test(t)) return { ok: false, reason: 'Teksten inneholder upassende innhold.' };
  return { ok: true };
}

function sanitizeIdea({ title, body }) {
  const combined = `${title} ${body}`.trim();
  if (combined.length < 15) {
    return { ok: false, reason: 'Teksten er for kort til aa vaere en fullstendig ide.' };
  }
  const titleCheck = sanitizeSegment(title);
  if (!titleCheck.ok) return titleCheck;
  const bodyCheck = sanitizeSegment(body);
  if (!bodyCheck.ok) return bodyCheck;
  return { ok: true };
}

function defaultMaturityChecklist() {
  return {
    problemDefinition: false,
    targetAudience: false,
    executionPlan: false,
  };
}

function calculateMaturity({ problem = '', targetAudience = '', executionPlan = '' }) {
  const checklist = {
    problemDefinition: countWords(problem) >= 8,
    targetAudience: countWords(targetAudience) >= 5,
    executionPlan: countWords(executionPlan) >= 10,
  };
  const completed = Object.values(checklist).filter(Boolean).length;
  return {
    checklist,
    score: Math.round((completed / 3) * 100),
    isReady: completed === 3,
  };
}

function polishHintsForIdea({ problem = '', targetAudience = '', executionPlan = '', category = '' }) {
  const hints = [];
  if (countWords(problem) < 8) hints.push('Clarify the problem in concrete terms.');
  if (countWords(targetAudience) < 5) hints.push('Name the customer segment more specifically.');
  if (countWords(executionPlan) < 10) hints.push('Describe the first usable version and how it would be built.');
  if (!category) hints.push('Choose a category when the idea is ready for review.');
  if (category && ['SaaS', 'Green Tech', 'Local Solutions'].includes(category)) {
    hints.push('This is a priority launch category; make the use case especially clear.');
  }
  return hints.slice(0, 4);
}

function parseIdeaInput(data) {
  const title = assertString(data?.title, 'title', 120);
  const body = assertString(data?.body, 'body', 1200);
  const category = assertString(data?.category, 'category', 80);
  const price = Number(data?.price);
  const problem = optionalTrimmedString(data?.problem, 'problem', 1200) || '';
  const targetAudience = optionalTrimmedString(data?.targetAudience, 'targetAudience', 800) || '';
  const executionPlan = optionalTrimmedString(data?.executionPlan, 'executionPlan', 1600) || '';

  if (countWords(title) > 15) throw new HttpsError('invalid-argument', 'Title may not exceed 15 words.');
  if (countWords(body) > 150) throw new HttpsError('invalid-argument', 'Body may not exceed 150 words.');
  if (!CATEGORIES.has(category)) throw new HttpsError('invalid-argument', 'Invalid category.');
  if (!Number.isInteger(price) || price < PRICE_MIN || price > PRICE_MAX) {
    throw new HttpsError('invalid-argument', 'Invalid price.');
  }

  const check = sanitizeIdea({ title, body });
  if (!check.ok) throw new HttpsError('invalid-argument', check.reason);

  const normalizedText = normalizeText({ title, body, category, problem, targetAudience, executionPlan });
  return {
    title,
    body,
    category,
    price,
    problem,
    targetAudience,
    executionPlan,
    normalizedText,
    normalizedTextHash: sha256(normalizedText),
  };
}

function parseQuickCaptureInput(data) {
  const rawCapture = assertString(data?.rawText ?? data?.rawCapture, 'rawText', 2000);
  const check = sanitizeSegment(rawCapture);
  if (!check.ok) throw new HttpsError('invalid-argument', check.reason);
  const words = rawCapture.split(/\s+/).filter(Boolean);
  const title = words.slice(0, 8).join(' ') || 'Untitled idea';
  return {
    rawCapture,
    title: title.length > 120 ? `${title.slice(0, 117)}...` : title,
  };
}

function parseDraftPatchInput(data) {
  const patch = {};
  for (const [field, maxChars] of [
    ['rawCapture', 2000],
    ['title', 120],
    ['body', 1200],
    ['category', 80],
    ['problem', 1200],
    ['targetAudience', 800],
    ['executionPlan', 1600],
  ]) {
    const value = optionalTrimmedString(data?.[field], field, maxChars);
    if (value !== undefined) patch[field] = value;
  }

  if ('title' in patch && patch.title && countWords(patch.title) > 15) {
    throw new HttpsError('invalid-argument', 'Title may not exceed 15 words.');
  }
  if ('body' in patch && patch.body && countWords(patch.body) > 150) {
    throw new HttpsError('invalid-argument', 'Body may not exceed 150 words.');
  }
  if ('category' in patch && patch.category && !CATEGORIES.has(patch.category)) {
    throw new HttpsError('invalid-argument', 'Invalid category.');
  }
  if ('price' in (data || {})) {
    const price = Number(data.price);
    if (!Number.isInteger(price) || price < 0 || (price > 0 && (price < PRICE_MIN || price > PRICE_MAX))) {
      throw new HttpsError('invalid-argument', 'Invalid price.');
    }
    patch.price = price;
  }
  return patch;
}

function statusFromMatch(matchScore) {
  if (matchScore >= THRESHOLDS.duplicate) return 'rejected';
  return 'pending_review';
}

function publicIdeaFromPrivate(idea, ideaId) {
  return {
    title: idea.title || '',
    body: idea.body || '',
    category: idea.category || '',
    price: idea.price || 0,
    status: idea.status === 'sold' ? 'sold' : 'active',
    visibility: 'public',
    uniquenessScore: idea.smartEngine?.uniquenessScore ?? idea.uniquenessScore ?? 0,
    createdAt: idea.createdAt || admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    sourceIdeaId: ideaId,
  };
}

function writePublicProjection(tx, publicRef, idea, ideaId) {
  if (['active', 'flagged'].includes(idea.status) && idea.visibility === 'public') {
    tx.set(publicRef, publicIdeaFromPrivate(idea, ideaId), { merge: true });
  } else if (['draft', 'processing', 'pending_review', 'returned', 'rejected', 'needs_review', 'archived', 'error'].includes(idea.status)) {
    tx.delete(publicRef);
  } else if (idea.status === 'sold') {
    tx.set(publicRef, publicIdeaFromPrivate(idea, ideaId), { merge: true });
  }
}

exports.quickCaptureIdea = onCall({ enforceAppCheck: true }, async (request) => {
  const uid = requireAuth(request);
  await requireRole(uid, ['innovator', 'both']);

  const parsed = parseQuickCaptureInput(request.data || {});
  const ideaRef = db.collection('ideas').doc();
  const now = admin.firestore.FieldValue.serverTimestamp();
  const maturity = calculateMaturity({});

  await ideaRef.set({
    title: parsed.title,
    body: '',
    category: '',
    price: 0,
    rawCapture: parsed.rawCapture,
    problem: '',
    targetAudience: '',
    executionPlan: '',
    maturityChecklist: maturity.checklist,
    maturityScore: maturity.score,
    polishHints: polishHintsForIdea({}),
    innovatorId: uid,
    status: 'draft',
    visibility: 'private',
    isArchived: false,
    isDeleted: false,
    createdAt: now,
    updatedAt: now,
  });

  return { ideaId: ideaRef.id, status: 'draft' };
});

exports.updateIdeaDraft = onCall({ enforceAppCheck: true }, async (request) => {
  const uid = requireAuth(request);
  await requireRole(uid, ['innovator', 'both']);

  const ideaId = assertString(request.data?.ideaId, 'ideaId', 120);
  const patch = parseDraftPatchInput(request.data || {});
  delete patch.ideaId;
  if (Object.keys(patch).length === 0) {
    throw new HttpsError('invalid-argument', 'No draft fields supplied.');
  }

  let result;
  await db.runTransaction(async (tx) => {
    const ideaRef = db.collection('ideas').doc(ideaId);
    const snap = await tx.get(ideaRef);
    if (!snap.exists) throw new HttpsError('not-found', 'Idea not found.');
    const idea = snap.data();
    if (idea.innovatorId !== uid) throw new HttpsError('permission-denied', 'Not your idea.');
    if (!['draft', 'returned', 'error'].includes(idea.status)) {
      throw new HttpsError('failed-precondition', 'Only draft ideas can be edited.');
    }

    const merged = { ...idea, ...patch };
    const maturity = calculateMaturity(merged);
    const hints = polishHintsForIdea(merged);
    result = { maturityScore: maturity.score, maturityChecklist: maturity.checklist, polishHints: hints };

    tx.update(ideaRef, {
      ...patch,
      ...result,
      status: idea.status === 'error' ? 'draft' : idea.status,
      visibility: 'private',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  return { success: true, ...result };
});

exports.submitIdeaForReview = onCall({
  enforceAppCheck: true,
  secrets: [OPENAI_API_KEY, PINECONE_API_KEY],
}, async (request) => {
  const uid = requireAuth(request);
  await requireRole(uid, ['innovator', 'both']);

  const ideaId = assertString(request.data?.ideaId, 'ideaId', 120);
  const ideaRef = db.collection('ideas').doc(ideaId);
  let idea;

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ideaRef);
    if (!snap.exists) throw new HttpsError('not-found', 'Idea not found.');
    idea = snap.data();
    if (idea.innovatorId !== uid) throw new HttpsError('permission-denied', 'Not your idea.');
    if (!['draft', 'returned', 'error'].includes(idea.status)) {
      throw new HttpsError('failed-precondition', 'Idea is not editable for review submission.');
    }

    const maturity = calculateMaturity(idea);
    if (!maturity.isReady) {
      throw new HttpsError('failed-precondition', 'Complete the Vault Ready checklist before submitting.');
    }

    const parsed = parseIdeaInput(idea);
    idea = { ...idea, ...parsed, maturityChecklist: maturity.checklist, maturityScore: maturity.score };
    tx.update(ideaRef, {
      ...parsed,
      maturityChecklist: maturity.checklist,
      maturityScore: maturity.score,
      polishHints: polishHintsForIdea(parsed),
      status: 'processing',
      visibility: 'private',
      submittedAt: admin.firestore.FieldValue.serverTimestamp(),
      reviewNote: admin.firestore.FieldValue.delete(),
      reviewedAt: admin.firestore.FieldValue.delete(),
      reviewedBy: admin.firestore.FieldValue.delete(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      smartEngine: {
        provider: 'openai',
        embeddingModel: EMBEDDING_MODEL,
        vectorStore: 'pinecone',
        version: SMART_ENGINE_VERSION,
        thresholdVersion: 'idea-similarity-v1',
        normalizedTextHash: parsed.normalizedTextHash,
        normalizedText: parsed.normalizedText,
        duplicateThreshold: THRESHOLDS.duplicate,
        needsReviewThreshold: THRESHOLDS.needsReview,
      },
    });
  });

  await runSmartEngineForIdea(ideaId, { ...idea, status: 'processing' });
  const finalSnap = await ideaRef.get();
  return { ideaId, status: finalSnap.data()?.status || 'processing' };
});

exports.submitIdea = onCall({ enforceAppCheck: true }, async (request) => {
  const uid = requireAuth(request);
  await requireRole(uid, ['innovator', 'both']);

  const parsed = parseIdeaInput(request.data || {});
  const ideaRef = db.collection('ideas').doc();
  const now = admin.firestore.FieldValue.serverTimestamp();

  await ideaRef.set({
    title: parsed.title,
    body: parsed.body,
    category: parsed.category,
    price: parsed.price,
    rawCapture: '',
    problem: parsed.problem,
    targetAudience: parsed.targetAudience,
    executionPlan: parsed.executionPlan,
    maturityChecklist: calculateMaturity(parsed).checklist,
    maturityScore: calculateMaturity(parsed).score,
    polishHints: polishHintsForIdea(parsed),
    innovatorId: uid,
    status: 'processing',
    visibility: 'private',
    isArchived: false,
    isDeleted: false,
    smartEngine: {
      provider: 'openai',
      embeddingModel: EMBEDDING_MODEL,
      vectorStore: 'pinecone',
      version: SMART_ENGINE_VERSION,
      thresholdVersion: 'idea-similarity-v1',
      normalizedTextHash: parsed.normalizedTextHash,
      normalizedText: parsed.normalizedText,
      duplicateThreshold: THRESHOLDS.duplicate,
      needsReviewThreshold: THRESHOLDS.needsReview,
    },
    createdAt: now,
    updatedAt: now,
  });

  return { ideaId: ideaRef.id, status: 'processing' };
});

exports.processIdea = onDocumentCreated({
  document: 'ideas/{ideaId}',
  secrets: [OPENAI_API_KEY, PINECONE_API_KEY],
}, async (event) => {
  const snap = event.data;
  if (!snap) return;

  const data = snap.data();
  const ideaId = event.params.ideaId;
  if (data.status !== 'processing') return;

  await runSmartEngineForIdea(ideaId, data);
});

async function runSmartEngineForIdea(ideaId, data) {
  const ideaRef = db.collection('ideas').doc(ideaId);
  const publicRef = db.collection('publicIdeas').doc(ideaId);
  const normalizedText = data.smartEngine?.normalizedText ||
    normalizeText({
      title: data.title || '',
      body: data.body || '',
      category: data.category || '',
      problem: data.problem || '',
      targetAudience: data.targetAudience || '',
      executionPlan: data.executionPlan || '',
    });
  const normalizedTextHash = data.smartEngine?.normalizedTextHash || sha256(normalizedText);

  async function setResult(fields) {
    await db.runTransaction(async (tx) => {
      const ideaSnap = await tx.get(ideaRef);
      if (!ideaSnap.exists) return;
      const update = {
        ...fields,
        visibility: 'private',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };
      tx.update(ideaRef, update);
      writePublicProjection(tx, publicRef, { ...ideaSnap.data(), ...update }, ideaId);
    });
  }

  try {
    const check = sanitizeIdea({ title: data.title || '', body: data.body || '' });
    if (!check.ok) {
      await setResult({
        status: 'rejected',
        rejectionReason: check.reason,
        smartEngine: {
          ...(data.smartEngine || {}),
          normalizedTextHash,
          uniquenessScore: 0,
          matchScore: 1,
          processedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
      });
      return;
    }

    const exactDup = await db.collection('ideas')
      .where('smartEngine.normalizedTextHash', '==', normalizedTextHash)
      .limit(10)
      .get();
    const exactMatch = exactDup.docs.find((doc) => {
      const candidate = doc.data();
      return doc.id !== ideaId && ['active', 'flagged', 'pending_review', 'needs_review', 'sold'].includes(candidate.status);
    });
    if (exactMatch) {
      await setResult({
        status: 'rejected',
        rejectionReason: 'Exact normalized duplicate.',
        smartEngine: {
          ...(data.smartEngine || {}),
          normalizedTextHash,
          uniquenessScore: 0,
          matchScore: 1,
          matchedIdeaId: exactMatch.id,
          matchedIdeaTitle: exactMatch.data().title || null,
          processedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
      });
      return;
    }

    const res = await getOpenAI().embeddings.create({
      model: EMBEDDING_MODEL,
      input: normalizedText,
    });
    const embedding = res.data?.[0]?.embedding;
    if (!embedding || embedding.length === 0) throw new Error('Empty embedding returned.');

    const queryResult = await getPineconeIndex().query({
      vector: embedding,
      topK: 1,
      includeMetadata: true,
      filter: { status: { $in: ['active', 'flagged', 'pending_review', 'needs_review'] } },
    });

    const topMatch = queryResult.matches?.[0];
    const matchScore = topMatch?.score ?? 0;
    const uniquenessScore = Math.max(0, Math.min(100, Math.round((1 - matchScore) * 100)));
    const status = statusFromMatch(matchScore);

    if (status !== 'rejected') {
      await getPineconeIndex().upsert({
        records: [{
          id: ideaId,
          values: embedding,
          metadata: {
            ideaId,
            category: data.category || '',
            status,
            title: data.title || '',
            normalizedTextHash,
            modelVersion: SMART_ENGINE_VERSION,
            createdAt: Date.now(),
          },
        }],
      });
    }

    await setResult({
      status,
      reviewNote: status === 'pending_review' && matchScore >= THRESHOLDS.needsReview
        ? 'Smart Engine found a similar idea. Review carefully before approval.'
        : admin.firestore.FieldValue.delete(),
      rejectionReason: status === 'rejected' ? 'Similar idea already exists.' : admin.firestore.FieldValue.delete(),
      smartEngine: {
        ...(data.smartEngine || {}),
        provider: 'openai',
        embeddingModel: EMBEDDING_MODEL,
        vectorStore: 'pinecone',
        version: SMART_ENGINE_VERSION,
        thresholdVersion: 'idea-similarity-v1',
        normalizedTextHash,
        uniquenessScore,
        matchScore,
        matchedIdeaId: topMatch?.id || null,
        matchedIdeaTitle: topMatch?.metadata?.title || null,
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      // Legacy fields kept for existing app model compatibility.
      uniquenessScore,
      matchScore,
      matchedIdeaId: topMatch?.id || null,
      matchedIdeaTitle: topMatch?.metadata?.title || null,
    });
  } catch (err) {
    console.error('[processIdea] error:', err);
    await setResult({
      status: 'error',
      smartEngine: {
        ...(data.smartEngine || {}),
        normalizedTextHash,
        error: err.message,
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      uniquenessScore: 0,
    });
  }
}

exports.approveIdea = onCall({ enforceAppCheck: true }, async (request) => {
  const adminUid = await requireAdmin(request);
  const ideaId = assertString(request.data?.ideaId, 'ideaId', 120);
  const ideaRef = db.collection('ideas').doc(ideaId);
  const publicRef = db.collection('publicIdeas').doc(ideaId);

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ideaRef);
    if (!snap.exists) throw new HttpsError('not-found', 'Idea not found.');
    const idea = snap.data();
    if (!['pending_review', 'needs_review'].includes(idea.status)) {
      throw new HttpsError('failed-precondition', 'Idea must be pending review.');
    }
    if (idea.isDeleted === true || idea.isArchived === true) {
      throw new HttpsError('failed-precondition', 'Archived ideas cannot be approved.');
    }

    const update = {
      status: 'active',
      visibility: 'public',
      reviewedAt: admin.firestore.FieldValue.serverTimestamp(),
      reviewedBy: adminUid,
      reviewNote: admin.firestore.FieldValue.delete(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    tx.update(ideaRef, update);
    tx.set(publicRef, publicIdeaFromPrivate({ ...idea, ...update }, ideaId), { merge: true });
  });

  return { success: true, status: 'active' };
});

exports.returnIdeaForImprovement = onCall({ enforceAppCheck: true }, async (request) => {
  const adminUid = await requireAdmin(request);
  const ideaId = assertString(request.data?.ideaId, 'ideaId', 120);
  const reviewNote = assertString(request.data?.reviewNote, 'reviewNote', 1200);
  const ideaRef = db.collection('ideas').doc(ideaId);
  const publicRef = db.collection('publicIdeas').doc(ideaId);

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ideaRef);
    if (!snap.exists) throw new HttpsError('not-found', 'Idea not found.');
    const idea = snap.data();
    if (!['pending_review', 'needs_review'].includes(idea.status)) {
      throw new HttpsError('failed-precondition', 'Idea must be pending review.');
    }
    tx.update(ideaRef, {
      status: 'returned',
      visibility: 'private',
      reviewNote,
      reviewedAt: admin.firestore.FieldValue.serverTimestamp(),
      reviewedBy: adminUid,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    tx.delete(publicRef);
  });

  return { success: true, status: 'returned' };
});

exports.rejectIdea = onCall({ enforceAppCheck: true }, async (request) => {
  const adminUid = await requireAdmin(request);
  const ideaId = assertString(request.data?.ideaId, 'ideaId', 120);
  const reviewNote = optionalTrimmedString(request.data?.reviewNote, 'reviewNote', 1200) || 'Rejected during review.';
  const ideaRef = db.collection('ideas').doc(ideaId);
  const publicRef = db.collection('publicIdeas').doc(ideaId);

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ideaRef);
    if (!snap.exists) throw new HttpsError('not-found', 'Idea not found.');
    const idea = snap.data();
    if (!['pending_review', 'needs_review', 'returned'].includes(idea.status)) {
      throw new HttpsError('failed-precondition', 'Idea is not reviewable.');
    }
    tx.update(ideaRef, {
      status: 'rejected',
      visibility: 'private',
      reviewNote,
      reviewedAt: admin.firestore.FieldValue.serverTimestamp(),
      reviewedBy: adminUid,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    tx.delete(publicRef);
  });

  return { success: true, status: 'rejected' };
});

exports.reportIdea = onCall({ enforceAppCheck: true }, async (request) => {
  const patronId = await requireActiveSubscription(request);
  await requireRole(patronId, ['patron', 'both']);

  const ideaId = assertString(request.data?.ideaId, 'ideaId', 120);
  const { reasonCode, reasonLabel } = parseReportReason(request.data?.reason);
  const details = optionalTrimmedString(request.data?.details, 'details', 1200) || '';

  const existingOpen = await db.collection('ideaReports')
    .where('ideaId', '==', ideaId)
    .where('reporterId', '==', patronId)
    .where('status', '==', 'open')
    .limit(1)
    .get();
  if (!existingOpen.empty) {
    throw new HttpsError('already-exists', 'You already have an open report for this idea.');
  }

  const ideaRef = db.collection('ideas').doc(ideaId);
  const publicRef = db.collection('publicIdeas').doc(ideaId);
  const reportRef = db.collection('ideaReports').doc();
  const statsRef = db.collection('reportStats').doc(patronId);
  const userRef = db.collection('users').doc(patronId);
  let innovatorId = '';

  await db.runTransaction(async (tx) => {
    const ideaSnap = await tx.get(ideaRef);
    if (!ideaSnap.exists) throw new HttpsError('not-found', 'Idea not found.');
    const idea = ideaSnap.data();
    if (!['active', 'flagged'].includes(idea.status)) {
      throw new HttpsError('failed-precondition', 'Only live ideas can be reported.');
    }
    if (idea.innovatorId === patronId) {
      throw new HttpsError('failed-precondition', 'You cannot report your own idea.');
    }

    innovatorId = idea.innovatorId;
    const now = admin.firestore.FieldValue.serverTimestamp();
    const openReportCount = Number(idea.reportSummary?.openReportCount || 0) + 1;

    tx.set(reportRef, {
      ideaId,
      reporterId: patronId,
      patronId,
      innovatorId,
      reasonCode,
      reasonLabel,
      details,
      status: 'open',
      resolution: null,
      falseReport: null,
      ideaSnapshot: {
        title: idea.title || '',
        category: idea.category || '',
        uniquenessScore: idea.smartEngine?.uniquenessScore ?? idea.uniquenessScore ?? 0,
        matchScore: idea.smartEngine?.matchScore ?? idea.matchScore ?? 0,
      },
      createdAt: now,
      updatedAt: now,
    });

    tx.update(ideaRef, {
      status: 'flagged',
      visibility: 'public',
      flaggedAt: idea.flaggedAt || now,
      updatedAt: now,
      reportSummary: {
        openReportCount,
        lastReportId: reportRef.id,
        lastReasonCode: reasonCode,
        lastReasonLabel: reasonLabel,
        lastReportedAt: now,
      },
    });
    tx.set(publicRef, publicIdeaFromPrivate({ ...idea, status: 'flagged', visibility: 'public' }, ideaId), { merge: true });
    tx.set(statsRef, {
      patronId,
      uid: patronId,
      totalReports: admin.firestore.FieldValue.increment(1),
      openReports: admin.firestore.FieldValue.increment(1),
      lastReportAt: now,
      updatedAt: now,
    }, { merge: true });
    tx.set(userRef, {
      'reportStats.totalReports': admin.firestore.FieldValue.increment(1),
      'reportStats.openReports': admin.firestore.FieldValue.increment(1),
      updatedAt: now,
    }, { merge: true });
  });

  await sendFcm(innovatorId, {
    title: 'Idea under manual review',
    body: 'A Patron report was submitted. The idea stays visible while admin reviews it.',
    data: { ideaId, reportId: reportRef.id },
  });

  return { reportId: reportRef.id, status: 'flagged' };
});

exports.resolveIdeaReport = onCall({ enforceAppCheck: true }, async (request) => {
  const adminUid = await requireAdmin(request);
  const ideaId = assertString(request.data?.ideaId, 'ideaId', 120);
  const resolution = assertString(request.data?.resolution, 'resolution', 40).toLowerCase();
  if (!REPORT_RESOLUTIONS.has(resolution)) {
    throw new HttpsError('invalid-argument', 'Invalid report resolution.');
  }
  const reviewNote = optionalTrimmedString(request.data?.reviewNote, 'reviewNote', 1200) || '';
  if (resolution === 'request_edit' && !reviewNote) {
    throw new HttpsError('invalid-argument', 'reviewNote is required when requesting an edit.');
  }

  const openReportsSnap = await db.collection('ideaReports')
    .where('ideaId', '==', ideaId)
    .where('status', '==', 'open')
    .get();

  const reportCountsByPatron = new Map();
  for (const doc of openReportsSnap.docs) {
    const reporterId = doc.data().reporterId;
    if (!reporterId) continue;
    reportCountsByPatron.set(reporterId, (reportCountsByPatron.get(reporterId) || 0) + 1);
  }

  const ideaRef = db.collection('ideas').doc(ideaId);
  const publicRef = db.collection('publicIdeas').doc(ideaId);

  await db.runTransaction(async (tx) => {
    const ideaSnap = await tx.get(ideaRef);
    if (!ideaSnap.exists) throw new HttpsError('not-found', 'Idea not found.');
    const idea = ideaSnap.data();
    if (idea.status !== 'flagged') {
      throw new HttpsError('failed-precondition', 'Idea is not flagged for report review.');
    }

    const statsByPatron = new Map();
    for (const patronId of reportCountsByPatron.keys()) {
      const statsRef = db.collection('reportStats').doc(patronId);
      const statsSnap = await tx.get(statsRef);
      statsByPatron.set(patronId, statsSnap.exists ? statsSnap.data() : {});
    }

    const now = admin.firestore.FieldValue.serverTimestamp();
    const publicUpdate = resolution === 'keep';
    const status = resolution === 'keep'
      ? 'active'
      : resolution === 'reject'
        ? 'rejected'
        : 'returned';
    const note = reviewNote || (resolution === 'reject'
      ? 'Rejected after patron report review.'
      : 'Report reviewed; idea remains live.');

    tx.update(ideaRef, {
      status,
      visibility: publicUpdate ? 'public' : 'private',
      reviewNote: publicUpdate ? admin.firestore.FieldValue.delete() : note,
      reviewedAt: now,
      reviewedBy: adminUid,
      updatedAt: now,
      reportSummary: {
        openReportCount: 0,
        lastResolution: resolution,
        lastResolvedAt: now,
        lastResolvedBy: adminUid,
      },
    });
    if (publicUpdate) {
      tx.set(publicRef, publicIdeaFromPrivate({ ...idea, status: 'active', visibility: 'public' }, ideaId), { merge: true });
    } else {
      tx.delete(publicRef);
    }

    for (const reportDoc of openReportsSnap.docs) {
      tx.update(reportDoc.ref, {
        status: 'resolved',
        resolution,
        falseReport: resolution === 'keep',
        reviewNote: note,
        resolvedAt: now,
        resolvedBy: adminUid,
        updatedAt: now,
      });
    }

    for (const [patronId, reportCount] of reportCountsByPatron.entries()) {
      const stats = statsByPatron.get(patronId) || {};
      const falseDelta = resolution === 'keep' ? reportCount : 0;
      const validDelta = resolution === 'keep' ? 0 : reportCount;
      const nextFalseReports = Number(stats.falseReports || 0) + falseDelta;
      const nextValidReports = Number(stats.validReports || 0) + validDelta;
      const nextOpenReports = Math.max(0, Number(stats.openReports || 0) - reportCount);
      const accountReviewFlag = stats.accountReviewFlag === true || nextFalseReports >= 3;

      tx.set(db.collection('reportStats').doc(patronId), {
        patronId,
        uid: patronId,
        falseReports: nextFalseReports,
        validReports: nextValidReports,
        openReports: nextOpenReports,
        resolvedReports: admin.firestore.FieldValue.increment(reportCount),
        accountReviewFlag,
        lastResolvedAt: now,
        updatedAt: now,
      }, { merge: true });
      tx.set(db.collection('users').doc(patronId), {
        reportReviewFlag: accountReviewFlag,
        'reportStats.falseReports': nextFalseReports,
        'reportStats.validReports': nextValidReports,
        'reportStats.openReports': nextOpenReports,
        updatedAt: now,
      }, { merge: true });
    }
  });

  return { success: true, status: resolution };
});

exports.moderateUser = onCall({ enforceAppCheck: true }, async (request) => {
  const adminUid = await requireAdmin(request);
  const uid = assertString(request.data?.uid, 'uid', 128);
  const accountStatus = assertString(request.data?.accountStatus, 'accountStatus', 40).toLowerCase();
  const moderationNote = optionalTrimmedString(request.data?.moderationNote, 'moderationNote', 1200);

  if (!ACCOUNT_STATUSES.has(accountStatus)) {
    throw new HttpsError('invalid-argument', 'Invalid account status.');
  }
  if (uid === adminUid && accountStatus !== 'active') {
    throw new HttpsError('failed-precondition', 'Admins cannot suspend or ban themselves.');
  }

  await db.collection('users').doc(uid).set({
    accountStatus,
    moderationNote: moderationNote || admin.firestore.FieldValue.delete(),
    moderatedAt: admin.firestore.FieldValue.serverTimestamp(),
    moderatedBy: adminUid,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });

  try {
    await admin.auth().updateUser(uid, { disabled: accountStatus !== 'active' });
  } catch (err) {
    console.warn('[moderateUser] Firebase Auth status update failed:', err.message);
  }

  return { success: true, accountStatus };
});

exports.archiveIdea = onCall({ enforceAppCheck: true }, async (request) => {
  const uid = requireAuth(request);
  await requireUsableUser(uid);
  const ideaId = assertString(request.data?.ideaId, 'ideaId', 120);
  const archive = request.data?.archive !== false;
  const ideaRef = db.collection('ideas').doc(ideaId);
  const publicRef = db.collection('publicIdeas').doc(ideaId);

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ideaRef);
    if (!snap.exists) throw new HttpsError('not-found', 'Idea not found.');
    const idea = snap.data();
    if (idea.innovatorId !== uid) throw new HttpsError('permission-denied', 'Not your idea.');
    if (!['draft', 'returned', 'rejected', 'active', 'archived'].includes(idea.status)) {
      throw new HttpsError('failed-precondition', 'Idea cannot be archived in this state.');
    }
    const status = archive ? 'archived' : (idea.previousStatus || 'draft');
    const visibility = status === 'active' ? 'public' : 'private';
    tx.update(ideaRef, {
      status,
      visibility,
      isArchived: archive,
      previousStatus: archive ? idea.status : admin.firestore.FieldValue.delete(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    if (archive) {
      tx.delete(publicRef);
    } else if (status === 'active') {
      tx.set(publicRef, publicIdeaFromPrivate({ ...idea, status, visibility }, ideaId), { merge: true });
    }
  });

  return { success: true };
});

exports.deleteIdea = onCall({ enforceAppCheck: true }, async (request) => {
  const uid = requireAuth(request);
  await requireUsableUser(uid);
  const ideaId = assertString(request.data?.ideaId, 'ideaId', 120);
  const ideaRef = db.collection('ideas').doc(ideaId);
  const publicRef = db.collection('publicIdeas').doc(ideaId);

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ideaRef);
    if (!snap.exists) throw new HttpsError('not-found', 'Idea not found.');
    const idea = snap.data();
    if (idea.innovatorId !== uid) throw new HttpsError('permission-denied', 'Not your idea.');
    if (idea.status === 'sold') throw new HttpsError('failed-precondition', 'Sold ideas cannot be deleted.');
    tx.update(ideaRef, {
      status: 'archived',
      isDeleted: true,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    tx.delete(publicRef);
  });

  return { success: true };
});

exports.purchaseIdea = onCall({
  enforceAppCheck: true,
  secrets: [STRIPE_SECRET_KEY],
}, async (request) => {
  const uid = await requireActiveSubscription(request);

  const ideaId = assertString(request.data?.ideaId, 'ideaId', 120);
  const ideaSnap = await db.collection('ideas').doc(ideaId).get();
  if (!ideaSnap.exists) throw new HttpsError('not-found', 'Idea not found.');

  const idea = ideaSnap.data();
  if (!['active', 'flagged'].includes(idea.status)) {
    throw new HttpsError('failed-precondition', 'Idea not available for purchase.');
  }
  if (idea.innovatorId === uid) throw new HttpsError('failed-precondition', 'Cannot buy your own idea.');

  const intent = await getStripe().paymentIntents.create({
    amount: idea.price,
    currency: 'usd',
    metadata: { ideaId, patronId: uid },
    automatic_payment_methods: { enabled: true },
  });

  return { clientSecret: intent.client_secret };
});

exports.stripeWebhook = onRequest({
  cors: false,
  secrets: [STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET],
}, async (req, res) => {
  const sig = req.headers['stripe-signature'];
  let event;

  try {
    event = getStripe().webhooks.constructEvent(req.rawBody, sig, STRIPE_WEBHOOK_SECRET.value());
  } catch (err) {
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  if (event.type === 'payment_intent.succeeded') {
    const intent = event.data.object;
    const { ideaId, patronId } = intent.metadata || {};

    await db.runTransaction(async (tx) => {
      const ideaRef = db.collection('ideas').doc(ideaId);
      const publicRef = db.collection('publicIdeas').doc(ideaId);
      const snap = await tx.get(ideaRef);
      if (!snap.exists || snap.data()?.status !== 'active') return;
      const update = {
        status: 'sold',
        buyerId: patronId,
        soldAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };
      tx.update(ideaRef, update);
      tx.delete(publicRef);
    });
  }

  res.json({ received: true });
});

exports.activateSubscription = onCall({
  enforceAppCheck: true,
  secrets: [GOOGLE_PLAY_SERVICE_ACCOUNT_JSON],
}, async (request) => {
  const uid = requireAuth(request);
  await requireUsableUser(uid);
  requireVerifiedEmail(request);
  const planId = assertString(request.data?.planId, 'planId', 120);
  const provider = assertString(request.data?.provider || 'google_play', 'provider', 40);
  if (provider !== 'google_play') {
    throw new HttpsError('invalid-argument', 'Patron subscriptions must be validated through Google Play.');
  }

  const receiptToken = assertGooglePlayPurchaseToken(request.data?.receiptToken);
  const validation = await validateGooglePlaySubscription({
    productId: planId,
    purchaseToken: receiptToken,
  });
  const now = admin.firestore.FieldValue.serverTimestamp();

  await db.collection('subscriptions').doc(uid).set({
    status: 'active',
    provider,
    planId,
    orderId: validation.orderId,
    purchaseTokenHash: sha256(receiptToken),
    paymentState: validation.paymentState,
    acknowledgementState: validation.acknowledgementState,
    autoRenewing: validation.autoRenewing,
    purchaseType: validation.purchaseType,
    rawStatus: validation.rawStatus,
    startDate: admin.firestore.FieldValue.serverTimestamp(),
    endDate: validation.endDate,
    lastValidatedAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: now,
  }, { merge: true });

  return { status: 'active', endDate: validation.endDate.toMillis() };
});

exports.validateSubscription = onCall({ enforceAppCheck: true }, async (request) => {
  const uid = requireAuth(request);
  await requireUsableUser(uid);
  requireVerifiedEmail(request);
  const subRef = db.collection('subscriptions').doc(uid);
  const snap = await subRef.get();
  if (!snap.exists) return { active: false, status: 'missing' };

  const sub = snap.data();
  const active = sub.status === 'active' &&
    sub.endDate?.toMillis &&
    sub.endDate.toMillis() > Date.now();
  const status = active ? 'active' : 'expired';

  await subRef.set({
    status,
    lastValidatedAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });

  return {
    active,
    status,
    endDate: sub.endDate?.toMillis ? sub.endDate.toMillis() : null,
  };
});

exports.requestPitch = onCall({ enforceAppCheck: true }, async (request) => {
  const uid = await requireActiveSubscription(request);

  const ideaId = assertString(request.data?.ideaId, 'ideaId', 120);
  const message = typeof request.data?.message === 'string'
    ? request.data.message.trim().slice(0, 1000)
    : '';

  const ideaSnap = await db.collection('ideas').doc(ideaId).get();
  if (!ideaSnap.exists || !['active', 'flagged'].includes(ideaSnap.data().status)) {
    throw new HttpsError('not-found', 'Idea not available.');
  }

  const idea = ideaSnap.data();
  if (idea.innovatorId === uid) {
    throw new HttpsError('failed-precondition', 'Cannot request a pitch on your own idea.');
  }

  const existing = await db.collection('pitches')
    .where('ideaId', '==', ideaId)
    .where('patronId', '==', uid)
    .where('status', 'in', ['pending', 'accepted', 'submitted'])
    .limit(1)
    .get();
  if (!existing.empty) throw new HttpsError('already-exists', 'You already sent a request for this idea.');

  const pitchRef = db.collection('pitches').doc();
  await pitchRef.set({
    ideaId,
    publicIdeaSnapshot: {
      title: idea.title,
      category: idea.category,
      price: idea.price,
    },
    patronId: uid,
    innovatorId: idea.innovatorId,
    status: 'pending',
    patronMessage: message,
    innovatorPitch: '',
    contactEmail: '',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  await sendFcm(idea.innovatorId, {
    title: 'New partnership request!',
    body: 'A Patron wants to discuss your idea.',
    data: { pitchId: pitchRef.id, ideaId },
  });

  return { pitchId: pitchRef.id };
});

exports.acceptPitch = onCall({ enforceAppCheck: true }, async (request) => {
  const uid = requireAuth(request);
  await requireUsableUser(uid);
  const pitchId = assertString(request.data?.pitchId, 'pitchId', 120);
  await transitionPitch({
    uid,
    pitchId,
    from: 'pending',
    update: { status: 'accepted' },
  });
  return { success: true };
});

exports.rejectPitch = onCall({ enforceAppCheck: true }, async (request) => {
  const uid = requireAuth(request);
  await requireUsableUser(uid);
  const pitchId = assertString(request.data?.pitchId, 'pitchId', 120);
  await transitionPitch({
    uid,
    pitchId,
    from: 'pending',
    update: { status: 'rejected' },
  });
  return { success: true };
});

exports.submitPitch = onCall({ enforceAppCheck: true }, async (request) => {
  const uid = requireAuth(request);
  await requireUsableUser(uid);
  const pitchId = assertString(request.data?.pitchId, 'pitchId', 120);
  const pitchText = assertString(request.data?.pitchText, 'pitchText', 2000);
  const contactEmail = assertEmail(request.data?.contactEmail);
  if (countWords(pitchText) > 150) {
    throw new HttpsError('invalid-argument', 'Pitch text may not exceed 150 words.');
  }

  const pitch = await transitionPitch({
    uid,
    pitchId,
    from: 'accepted',
    update: {
      status: 'submitted',
      innovatorPitch: pitchText,
      contactEmail,
    },
  });

  await sendFcm(pitch.patronId, {
    title: 'Pitch received!',
    body: 'The innovator has sent their pitch. Check it out.',
    data: { pitchId },
  });

  return { success: true };
});

exports.sendDealMessage = onCall({ enforceAppCheck: true }, async (request) => {
  const uid = requireAuth(request);
  await requireUsableUser(uid);
  const pitchId = assertString(request.data?.pitchId, 'pitchId', 120);
  const body = assertString(request.data?.body, 'body', 1200);
  const { pitchRef, pitch, role } = await getPitchForParticipant(uid, pitchId);
  assertDealRoomOpen(pitch);

  const messageRef = pitchRef.collection('messages').doc();
  await messageRef.set({
    senderId: uid,
    senderRole: role,
    body,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  await pitchRef.set({
    deal: {
      ...(pitch.deal || {}),
      status: pitch.deal?.status || 'open',
      lastActivityAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });

  return { messageId: messageRef.id };
});

exports.submitDealProposal = onCall({ enforceAppCheck: true }, async (request) => {
  const uid = requireAuth(request);
  await requireUsableUser(uid);
  const pitchId = assertString(request.data?.pitchId, 'pitchId', 120);
  const amount = assertDealAmount(request.data?.amount);
  const currency = assertDealCurrency(request.data?.currency);
  const collaborationType = assertDealType(request.data?.collaborationType);
  const message = optionalTrimmedString(request.data?.message, 'message', 1000) || '';

  const pitchRef = db.collection('pitches').doc(pitchId);
  const proposalRef = pitchRef.collection('proposals').doc();
  let role = '';
  let replacedProposalId = null;

  await db.runTransaction(async (tx) => {
    const pitchSnap = await tx.get(pitchRef);
    if (!pitchSnap.exists) throw new HttpsError('not-found', 'Pitch not found.');
    const pitch = pitchSnap.data();
    role = roleForPitch(pitch, uid);
    assertDealRoomOpen(pitch);

    const activeProposalId = pitch.deal?.activeProposalId;
    if (activeProposalId) {
      const activeRef = pitchRef.collection('proposals').doc(activeProposalId);
      const activeSnap = await tx.get(activeRef);
      if (activeSnap.exists && activeSnap.data()?.status === 'active') {
        const active = activeSnap.data();
        if (active.senderId === uid) {
          throw new HttpsError('failed-precondition', 'Waiting for the other party to respond.');
        }
        replacedProposalId = activeProposalId;
        tx.update(activeRef, {
          status: 'countered',
          replacedByProposalId: proposalRef.id,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    }

    tx.set(proposalRef, {
      senderId: uid,
      senderRole: role,
      status: 'active',
      amount,
      currency,
      collaborationType,
      message,
      replacesProposalId: replacedProposalId,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    tx.set(pitchRef, {
      deal: {
        ...(pitch.deal || {}),
        status: replacedProposalId ? 'counter_pending' : 'proposal_pending',
        activeProposalId: proposalRef.id,
        lastProposalBy: uid,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        lastActivityAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
  });

  return { proposalId: proposalRef.id, status: 'active' };
});

exports.respondDealProposal = onCall({ enforceAppCheck: true }, async (request) => {
  const uid = requireAuth(request);
  await requireUsableUser(uid);
  const pitchId = assertString(request.data?.pitchId, 'pitchId', 120);
  const proposalId = assertString(request.data?.proposalId, 'proposalId', 120);
  const action = assertString(request.data?.action, 'action', 20).toLowerCase();
  if (!DEAL_ACTIONS.has(action)) throw new HttpsError('invalid-argument', 'Invalid proposal action.');

  const pitchRef = db.collection('pitches').doc(pitchId);
  const proposalRef = pitchRef.collection('proposals').doc(proposalId);
  let proposal;

  await db.runTransaction(async (tx) => {
    const pitchSnap = await tx.get(pitchRef);
    if (!pitchSnap.exists) throw new HttpsError('not-found', 'Pitch not found.');
    const pitch = pitchSnap.data();
    roleForPitch(pitch, uid);
    assertDealRoomOpen(pitch);

    const proposalSnap = await tx.get(proposalRef);
    if (!proposalSnap.exists) throw new HttpsError('not-found', 'Proposal not found.');
    proposal = proposalSnap.data();
    if (!DEAL_PROPOSAL_STATUSES.has(proposal.status) || proposal.status !== 'active') {
      throw new HttpsError('failed-precondition', 'Proposal is not active.');
    }
    if (proposal.senderId === uid) {
      throw new HttpsError('failed-precondition', 'You cannot accept your own proposal.');
    }
    if (pitch.deal?.activeProposalId !== proposalId) {
      throw new HttpsError('failed-precondition', 'Proposal is no longer active.');
    }

    const accepted = action === 'accept';
    tx.update(proposalRef, {
      status: accepted ? 'accepted' : 'declined',
      respondedBy: uid,
      respondedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    tx.update(pitchRef, {
      'deal.status': accepted ? 'accepted' : 'open',
      'deal.activeProposalId': admin.firestore.FieldValue.delete(),
      'deal.acceptedProposalId': accepted ? proposalId : admin.firestore.FieldValue.delete(),
      'deal.acceptedAt': accepted ? admin.firestore.FieldValue.serverTimestamp() : admin.firestore.FieldValue.delete(),
      'deal.lastActivityAt': admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  return { success: true, status: action === 'accept' ? 'accepted' : 'declined' };
});

exports.reportDealIssue = onCall({ enforceAppCheck: true }, async (request) => {
  const uid = requireAuth(request);
  await requireUsableUser(uid);
  const pitchId = assertString(request.data?.pitchId, 'pitchId', 120);
  const reason = assertString(request.data?.reason, 'reason', 1200);
  const { pitchRef, pitch, role } = await getPitchForParticipant(uid, pitchId);
  assertDealRoomOpen(pitch);

  const reportRef = pitchRef.collection('reports').doc();
  await db.runTransaction(async (tx) => {
    tx.set(reportRef, {
      reporterId: uid,
      reporterRole: role,
      reason,
      status: 'open',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    tx.set(pitchRef, {
      deal: {
        ...(pitch.deal || {}),
        status: 'reported',
        reportedAt: admin.firestore.FieldValue.serverTimestamp(),
        lastActivityAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
  });

  return { reportId: reportRef.id };
});

async function transitionPitch({ uid, pitchId, from, update }) {
  let prior;
  await db.runTransaction(async (tx) => {
    const pitchRef = db.collection('pitches').doc(pitchId);
    const pitchSnap = await tx.get(pitchRef);
    if (!pitchSnap.exists) throw new HttpsError('not-found', 'Pitch not found.');
    const pitch = pitchSnap.data();
    if (pitch.innovatorId !== uid) throw new HttpsError('permission-denied', 'Not your pitch.');
    if (!PITCH_STATUSES.has(pitch.status) || pitch.status !== from) {
      throw new HttpsError('failed-precondition', `Pitch must be ${from}.`);
    }
    prior = pitch;
    tx.update(pitchRef, {
      ...update,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });
  return prior;
}

async function sendFcm(uid, { title, body, data = {} }) {
  try {
    const userSnap = await db.collection('users').doc(uid).get();
    const token = userSnap.data()?.fcmToken;
    if (!token) return;
    await admin.messaging().send({
      token,
      notification: { title, body },
      data: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)])),
      android: { priority: 'high' },
    });
  } catch (err) {
    console.warn('[FCM] failed to send:', err.message);
  }
}

exports._test = {
  ACCOUNT_STATUSES,
  CATEGORIES,
  IDEA_STATUSES,
  PITCH_STATUSES,
  REPORT_REASONS,
  THRESHOLDS,
  calculateMaturity,
  countWords,
  defaultMaturityChecklist,
  isAdminUser,
  normalizeText,
  parseReportReason,
  parseDraftPatchInput,
  parseIdeaInput,
  parseQuickCaptureInput,
  polishHintsForIdea,
  publicIdeaFromPrivate,
  sha256,
  statusFromMatch,
};
