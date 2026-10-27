import { test } from 'node:test';
import assert from 'node:assert/strict';
import rule, { ADVICE, createRule } from './breaking-change-intact.mjs';
import fixtures from './fixtures.mjs';

for (const fixture of fixtures) {
  test(fixture.name, { todo: fixture.todo }, async () => {
    const [ok, message] = await rule({ raw: fixture.raw });
    assert.equal(ok, fixture.verdict === 'pass', message ?? 'rule passed');
    if (fixture.advice) {
      assert.ok(ADVICE[fixture.advice], `ADVICE.${fixture.advice} is not defined`);
      assert.ok(message.includes(ADVICE[fixture.advice]), `expected ${fixture.advice} advice in:\n${message}`);
    }
  });
}

test('a truncated paragraph names its line and the line read as a footer', async () => {
  const raw = 'feat!: x\n\nBREAKING CHANGE: foo bar\nGit::AuthorInfo is gone.\n';
  const [ok, message] = await rule({ raw });
  assert.equal(ok, false);
  assert.equal(
    message,
    'Line 3: release-please will truncate this BREAKING CHANGE description because line 4 ' +
    'starts with a word followed by ":" or " #", which release-please interprets as the start of another footer. ' +
    ADVICE.TRUNCATED
  );
});

test('a truncated paragraph in a nested commit block keeps its line numbers', async () => {
  const raw = 'feat: a\n\nBEGIN_NESTED_COMMIT\nfix: n\n\nBREAKING CHANGE: foo\nGit::A is gone.\nEND_NESTED_COMMIT\n';
  const [ok, message] = await rule({ raw });
  assert.equal(ok, false);
  assert.match(message, /^Line 6: .* because line 7 starts/);
});

test('line numbers count comment lines that git strips', async () => {
  const raw = '# template comment\nfeat!: x\n\nBREAKING CHANGE: foo bar\nGit::A is gone.\n';
  const [ok, message] = await rule({ raw });
  assert.equal(ok, false);
  assert.match(message, /^Line 4: .* because line 5 starts/);
});

test('a misplaced nested commit marker names its line', async () => {
  const raw = 'feat: a\n\nBREAKING CHANGE: alpha BEGIN_NESTED_COMMIT\nfix: n\n\nBREAKING CHANGE: x\nEND_NESTED_COMMIT\n';
  assert.deepEqual(await rule({ raw }), [false, `Line 3: ${ADVICE.MARKER}`]);
});

test('the never applicability is refused', async () => {
  assert.deepEqual(await rule({ raw: 'docs: y\n' }, 'never'), [false, ADVICE.NEVER]);
});

test('an unparseable message includes what the parser said', async () => {
  const raw = 'feat!: x\n\nGit.clone(url, File.join(dir, name)) now expands the path.\n\nBREAKING CHANGE: foo bar.\n';
  const [, message] = await rule({ raw });
  assert.match(message, /unexpected token '\('/);
});

test('without release-please, a message with no BREAKING CHANGE paragraph passes', async () => {
  const withoutReleasePlease = createRule({ loadParser: async () => null });
  assert.deepEqual(await withoutReleasePlease({ raw: 'docs: y\n' }), [true]);
});

test('without release-please, a BREAKING CHANGE paragraph fails with the install advice', async () => {
  const withoutReleasePlease = createRule({ loadParser: async () => null });
  const [ok, message] = await withoutReleasePlease({ raw: 'feat!: x\n\nBREAKING CHANGE: foo\n' });
  assert.equal(ok, false);
  assert.equal(message, ADVICE.MISSING);
});

test('a missing raw message passes', async () => {
  assert.deepEqual(await rule({}), [true]);
});
