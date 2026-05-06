const functions = require('../index');

const {
  calculateMaturity,
  normalizeText,
  parseQuickCaptureInput,
  parseIdeaInput,
  parseReportReason,
  publicIdeaFromPrivate,
  sha256,
  statusFromMatch,
} = functions._test;

describe('Smart Engine canonical helpers', () => {
  test('normalization is stable before hashing', () => {
    const a = normalizeText({
      title: '  AI  Garden!!!',
      body: 'Helps growers   plan better.',
      category: 'Technology',
    });
    const b = normalizeText({
      title: 'ai garden.',
      body: 'helps growers plan better.',
      category: 'technology',
    });

    expect(sha256(a)).toHaveLength(64);
    expect(a).toContain('category: technology');
    expect(b).toContain('body: helps growers plan better.');
  });

  test('thresholds map scores to production statuses', () => {
    expect(statusFromMatch(0.9)).toBe('rejected');
    expect(statusFromMatch(0.85)).toBe('rejected');
    expect(statusFromMatch(0.7)).toBe('pending_review');
    expect(statusFromMatch(0.65)).toBe('pending_review');
    expect(statusFromMatch(0.2)).toBe('pending_review');
  });

  test('flagged ideas stay visible in the public projection', () => {
    const projection = publicIdeaFromPrivate({
      title: 'Flagged live idea',
      body: 'Still visible while admin decides.',
      category: 'Technology',
      status: 'flagged',
      visibility: 'public',
      uniquenessScore: 77,
      createdAt: 'created',
    }, 'idea-1');

    expect(projection.status).toBe('active');
    expect(projection.visibility).toBe('public');
  });

  test('report reasons are required and canonical', () => {
    expect(parseReportReason('illegal_content').reasonLabel).toBe('Illegal content');
    expect(() => parseReportReason('')).toThrow();
    expect(() => parseReportReason('not_a_reason')).toThrow();
  });

  test('quick capture accepts raw notes without full idea structure', () => {
    const parsed = parseQuickCaptureInput({
      rawText: 'A field service app that helps local electricians quote recurring maintenance jobs faster.',
    });
    expect(parsed.rawCapture).toContain('field service');
    expect(parsed.title.split(/\s+/).length).toBeLessThanOrEqual(8);
  });

  test('maturity requires problem, audience, and execution plan', () => {
    const early = calculateMaturity({
      problem: 'Too vague.',
      targetAudience: '',
      executionPlan: '',
    });
    expect(early.isReady).toBe(false);
    expect(early.score).toBeLessThan(100);

    const ready = calculateMaturity({
      problem: 'Small contractors lose hours creating quotes because pricing and materials are scattered.',
      targetAudience: 'Independent electricians and small local contractor teams.',
      executionPlan: 'Start with a mobile quote builder, reusable material templates, and exportable customer proposals.',
    });
    expect(ready.isReady).toBe(true);
    expect(ready.score).toBe(100);
  });

  test('idea input validation accepts bounded production input', () => {
    const parsed = parseIdeaInput({
      title: 'AI garden planner',
      body: 'A planning tool that helps small farms forecast crop rotation and watering needs.',
      category: 'Technology',
      price: 5000,
    });

    expect(parsed.normalizedTextHash).toHaveLength(64);
    expect(parsed.price).toBe(5000);
  });

  test('idea input validation rejects invalid categories and prices', () => {
    expect(() => parseIdeaInput({
      title: 'AI garden planner',
      body: 'A planning tool that helps small farms forecast crop rotation and watering needs.',
      category: 'Unknown',
      price: 5000,
    })).toThrow();

    expect(() => parseIdeaInput({
      title: 'AI garden planner',
      body: 'A planning tool that helps small farms forecast crop rotation and watering needs.',
      category: 'Technology',
      price: 10,
    })).toThrow();
  });
});
