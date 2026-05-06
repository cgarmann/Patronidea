const fs = require('fs');
const path = require('path');
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const {
  doc,
  getDoc,
  setDoc,
  updateDoc,
  serverTimestamp,
  Timestamp,
} = require('firebase/firestore');

let testEnv;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'share-idea-rules-test',
    firestore: {
      rules: fs.readFileSync(path.join(__dirname, '../../firestore.rules'), 'utf8'),
    },
  });
});

beforeEach(async () => {
  await testEnv.clearFirestore();
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'users/innovator1'), {
      displayName: 'Innovator',
      email: 'innovator@example.com',
      role: 'innovator',
      createdAt: serverTimestamp(),
    });
    await setDoc(doc(db, 'users/patron1'), {
      displayName: 'Patron',
      email: 'patron@example.com',
      role: 'patron',
      createdAt: serverTimestamp(),
    });
    await setDoc(doc(db, 'users/patron1/consents/nda_v1'), {
      type: 'nda',
      version: 'v1',
      textHash: 'test-nda-hash',
      acceptedAt: serverTimestamp(),
    });
    await setDoc(doc(db, 'users/expiredPatron'), {
      displayName: 'Expired Patron',
      email: 'expired@example.com',
      role: 'patron',
      createdAt: serverTimestamp(),
    });
    await setDoc(doc(db, 'users/expiredPatron/consents/nda_v1'), {
      type: 'nda',
      version: 'v1',
      textHash: 'test-nda-hash',
      acceptedAt: serverTimestamp(),
    });
    await setDoc(doc(db, 'users/noNdaPatron'), {
      displayName: 'No NDA Patron',
      email: 'no-nda@example.com',
      role: 'patron',
      createdAt: serverTimestamp(),
    });
    await setDoc(doc(db, 'users/suspendedPatron'), {
      displayName: 'Suspended Patron',
      email: 'suspended@example.com',
      role: 'patron',
      accountStatus: 'suspended',
      createdAt: serverTimestamp(),
    });
    await setDoc(doc(db, 'users/suspendedPatron/consents/nda_v1'), {
      type: 'nda',
      version: 'v1',
      textHash: 'test-nda-hash',
      acceptedAt: serverTimestamp(),
    });
    await setDoc(doc(db, 'subscriptions/patron1'), {
      status: 'active',
      endDate: Timestamp.fromDate(new Date(Date.now() + 60 * 60 * 1000)),
    });
    await setDoc(doc(db, 'subscriptions/expiredPatron'), {
      status: 'active',
      endDate: Timestamp.fromDate(new Date(Date.now() - 60 * 60 * 1000)),
    });
    await setDoc(doc(db, 'subscriptions/noNdaPatron'), {
      status: 'active',
      endDate: Timestamp.fromDate(new Date(Date.now() + 60 * 60 * 1000)),
    });
    await setDoc(doc(db, 'subscriptions/suspendedPatron'), {
      status: 'active',
      endDate: Timestamp.fromDate(new Date(Date.now() + 60 * 60 * 1000)),
    });
    await setDoc(doc(db, 'admins/admin1'), {
      active: true,
      createdAt: serverTimestamp(),
    });
    await setDoc(doc(db, 'ideas/idea1'), {
      title: 'Private idea',
      body: 'Secret owner details live here.',
      category: 'Technology',
      price: 5000,
      status: 'active',
      innovatorId: 'innovator1',
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });
    await setDoc(doc(db, 'publicIdeas/idea1'), {
      title: 'Public idea',
      body: 'Patron-safe idea text.',
      category: 'Technology',
      price: 5000,
      status: 'active',
      visibility: 'public',
      uniquenessScore: 91,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });
    await setDoc(doc(db, 'ideas/pendingIdea'), {
      title: 'Pending private idea',
      body: 'Only admins and owners should see this.',
      category: 'SaaS',
      price: 5000,
      status: 'pending_review',
      visibility: 'private',
      innovatorId: 'innovator1',
      submittedAt: serverTimestamp(),
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });
    await setDoc(doc(db, 'publicIdeas/privatePreview'), {
      title: 'Should not be visible',
      body: 'This projection is not public.',
      category: 'SaaS',
      price: 5000,
      status: 'active',
      visibility: 'private',
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });
    await setDoc(doc(db, 'pitches/pitch1'), {
      ideaId: 'idea1',
      patronId: 'patron1',
      innovatorId: 'innovator1',
      status: 'pending',
      patronMessage: 'Interested.',
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });
    await setDoc(doc(db, 'ideaReports/report1'), {
      ideaId: 'idea1',
      reporterId: 'patron1',
      patronId: 'patron1',
      innovatorId: 'innovator1',
      reasonCode: 'illegal_content',
      reasonLabel: 'Illegal content',
      status: 'open',
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });
    await setDoc(doc(db, 'reportStats/patron1'), {
      patronId: 'patron1',
      totalReports: 1,
      openReports: 1,
      falseReports: 0,
      validReports: 0,
      lastReportAt: serverTimestamp(),
    });
  });
});

afterAll(async () => {
  if (testEnv) await testEnv.cleanup();
});

test('active patrons can read public ideas but not private ideas', async () => {
  const db = testEnv.authenticatedContext('patron1', { email_verified: true }).firestore();
  await assertSucceeds(getDoc(doc(db, 'publicIdeas/idea1')));
  await assertFails(getDoc(doc(db, 'ideas/idea1')));
});

test('expired patrons cannot read public ideas', async () => {
  const db = testEnv.authenticatedContext('expiredPatron', { email_verified: true }).firestore();
  await assertFails(getDoc(doc(db, 'publicIdeas/idea1')));
});

test('unverified patrons cannot read public ideas', async () => {
  const db = testEnv.authenticatedContext('patron1', { email_verified: false }).firestore();
  await assertFails(getDoc(doc(db, 'publicIdeas/idea1')));
});

test('patrons must accept the current NDA before reading public ideas', async () => {
  const db = testEnv.authenticatedContext('noNdaPatron', { email_verified: true }).firestore();
  await assertFails(getDoc(doc(db, 'publicIdeas/idea1')));
});

test('suspended patrons cannot read public ideas', async () => {
  const db = testEnv.authenticatedContext('suspendedPatron', { email_verified: true }).firestore();
  await assertFails(getDoc(doc(db, 'publicIdeas/idea1')));
});

test('active patrons cannot read non-public projections', async () => {
  const db = testEnv.authenticatedContext('patron1', { email_verified: true }).firestore();
  await assertFails(getDoc(doc(db, 'publicIdeas/privatePreview')));
});

test('innovators can read only their own private idea records', async () => {
  const ownerDb = testEnv.authenticatedContext('innovator1').firestore();
  const otherDb = testEnv.authenticatedContext('innovator2').firestore();
  await assertSucceeds(getDoc(doc(ownerDb, 'ideas/idea1')));
  await assertFails(getDoc(doc(otherDb, 'ideas/idea1')));
});

test('admins can read pending private ideas for review', async () => {
  const adminDb = testEnv.authenticatedContext('admin1').firestore();
  await assertSucceeds(getDoc(doc(adminDb, 'ideas/pendingIdea')));
});

test('admins can read users, idea reports, and report stats', async () => {
  const adminDb = testEnv.authenticatedContext('admin1').firestore();
  await assertSucceeds(getDoc(doc(adminDb, 'users/patron1')));
  await assertSucceeds(getDoc(doc(adminDb, 'ideaReports/report1')));
  await assertSucceeds(getDoc(doc(adminDb, 'reportStats/patron1')));
});

test('patrons can read their reports but cannot write reports directly', async () => {
  const patronDb = testEnv.authenticatedContext('patron1', { email_verified: true }).firestore();
  const strangerDb = testEnv.authenticatedContext('expiredPatron', { email_verified: true }).firestore();
  await assertSucceeds(getDoc(doc(patronDb, 'ideaReports/report1')));
  await assertFails(getDoc(doc(strangerDb, 'ideaReports/report1')));
  await assertFails(setDoc(doc(patronDb, 'ideaReports/newReport'), {
    ideaId: 'idea1',
    reporterId: 'patron1',
    status: 'open',
  }));
});

test('clients cannot directly create or mutate ideas, public ideas, or pitches', async () => {
  const db = testEnv.authenticatedContext('innovator1').firestore();
  await assertFails(setDoc(doc(db, 'ideas/newIdea'), {
    title: 'No direct writes',
    body: 'This must go through a callable.',
    status: 'processing',
    innovatorId: 'innovator1',
  }));
  await assertFails(updateDoc(doc(db, 'publicIdeas/idea1'), { status: 'sold' }));
  await assertFails(updateDoc(doc(db, 'pitches/pitch1'), { status: 'accepted' }));
});

test('only pitch participants can read pitch documents', async () => {
  const patronDb = testEnv.authenticatedContext('patron1').firestore();
  const innovatorDb = testEnv.authenticatedContext('innovator1').firestore();
  const strangerDb = testEnv.authenticatedContext('stranger').firestore();
  await assertSucceeds(getDoc(doc(patronDb, 'pitches/pitch1')));
  await assertSucceeds(getDoc(doc(innovatorDb, 'pitches/pitch1')));
  await assertFails(getDoc(doc(strangerDb, 'pitches/pitch1')));
});
