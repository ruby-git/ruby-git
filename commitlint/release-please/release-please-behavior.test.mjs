// The rule's advice describes how release-please reads a BREAKING CHANGE footer.
// These tests pin that behavior with the installed release-please so that an
// upgrade which changes it fails here, with the fixture's name saying what moved,
// rather than in a published changelog.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { loadReleasePlease, numberedLines, splitLikeReleasePlease } from './breaking-change-intact.mjs';
import fixtures from './fixtures.mjs';

const parseConventionalCommits = await loadReleasePlease();
const quiet = { error() {}, warn() {}, info() {}, debug() {}, trace() {} };

const published = (raw) =>
  parseConventionalCommits([{ sha: 'HEAD', message: raw, files: [] }], quiet)
    .flatMap((commit) => commit.notes)
    .filter((note) => note.title === 'BREAKING CHANGE')
    .map((note) => note.text);

test('release-please is installed', () => {
  assert.notEqual(parseConventionalCommits, null);
});

for (const fixture of fixtures.filter((f) => f.published)) {
  test(`release-please: ${fixture.name}`, { todo: fixture.todo }, () => {
    assert.deepEqual(published(fixture.raw), fixture.published);
  });
}

// The rule checks each change on its own, so its copy of release-please's split must
// produce the notes release-please produces from the whole message.
for (const fixture of fixtures.filter((f) => f.published)) {
  test(`split: ${fixture.name}`, { todo: fixture.todo }, () => {
    const perChange = splitLikeReleasePlease(numberedLines(fixture.raw))
      .map((lines) => lines.map((line) => line.text).join('\n'))
      .flatMap((text) => published(text));
    assert.deepEqual(perChange, fixture.published);
  });
}
