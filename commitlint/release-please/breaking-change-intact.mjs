// The release-please/breaking-change-intact rule. index.mjs wraps it as a commitlint plugin.
//
// release-please parses commit messages with @conventional-commits/parser, which
// follows the Conventional Commits grammar strictly. A continuation line of a footer
// that begins with a word followed by ":" or by " #" is read as the start of a new
// footer when every line after it through the end of the paragraph reads that way
// too; a later line of prose restores the paragraph. "Git::AuthorInfo is ..." and
// "global: true ..." both start a new footer this way. commitlint's own parser is
// lenient and keeps every line, so it cannot see the problem.
//
// This rule splits the message into changes the way release-please does, hands each
// change to release-please's own commit parser, which wraps
// @conventional-commits/parser with release-please's retries and changelog rendering,
// and requires that every BREAKING CHANGE paragraph in the change comes out as the
// author wrote it. release-please is loaded when the rule first meets a BREAKING
// CHANGE paragraph, so a message without one never pays for the import. That does
// not cover a clone whose node_modules predates the plugin: commitlint resolves
// plugins before any rule runs, so such a clone fails every commit until npm install
// is rerun, and the commit-msg hook says so.
//
// The rule supports only the `always` applicability; `never` fails with a message
// saying so rather than inverting the rule.
//
// Exports: the rule itself as the default export, `createRule` to build one with a
// different release-please loader (tests inject a fake), the `ADVICE` texts the error
// messages are built from, and the message-handling helpers.

// What git removes from a message before recording the commit: trailing whitespace
// on every line, every line that starts with the comment character, and, with
// `git commit -v`, the scissors line and the diff below it. commitlint strips the
// comments for its own parse but hands this rule the raw file, so the rule applies
// the same cleanup, with "#" as the comment character. git strips comment lines
// only from an edited message; a message given with -m or -F keeps them, and the
// rule cannot tell the two apart, so a body line that starts with "#" is checked as
// if git had removed it (issue 1921). Lines keep the numbers they have in the raw
// message so the error can name them.
const COMMENT_LINE = /^#/;
const SCISSORS_LINE = /^# -+ >8 -+$/;

export const numberedLines = (text) =>
  text.split(/\r?\n/).map((line, index) => ({ number: index + 1, text: line }));

export const cleanupLikeGit = (raw) => {
  const kept = [];
  for (const line of numberedLines(raw)) {
    if (SCISSORS_LINE.test(line.text)) break;
    if (COMMENT_LINE.test(line.text)) continue;
    kept.push({ number: line.number, text: line.text.trimEnd() });
  }
  return kept;
};

// release-please reads a message as one or more changes, each parsed as a commit of
// its own with its own notes: every BEGIN_NESTED_COMMIT ... END_NESTED_COMMIT block is
// a change, and the rest of the message splits at each blank line followed by a
// conventional header. Lifting a block out leaves one blank line in its place, as
// release-please's join of the text around it does when the markers sit on lines of
// their own. release-please splits at a marker wherever it appears in a line; the
// rule mirrors only a marker on a line of its own and fails a message with any other
// (`misplacedMarker`). The header pattern is a copy of release-please's
// splitMessages, which is not exported; release-please-behavior.test.mjs checks that
// the changes' notes add up to the whole message's so an upgrade that moves the split
// fails there. The input and each change are lists of numbered lines.
const CHANGE_HEADER =
  /^(?:feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(?:\(.*?\))?: /;
const MARKERS = ['BEGIN_NESTED_COMMIT', 'END_NESTED_COMMIT'];

export const misplacedMarker = (lines) =>
  lines.find((line) =>
    MARKERS.some((marker) => line.text.includes(marker) && line.text !== marker));

export const splitLikeReleasePlease = (lines) => {
  const main = [];
  const nested = [];
  let block = null;
  for (const line of lines) {
    if (line.text === 'BEGIN_NESTED_COMMIT') {
      block = [];
      nested.push(block);
      main.push({ number: line.number, text: '' });
    } else if (line.text === 'END_NESTED_COMMIT') {
      block = null;
    } else {
      (block ?? main).push(line);
    }
  }
  const changes = [];
  main.forEach((line, index) => {
    if (index === 0 || (main[index - 1].text === '' && CHANGE_HEADER.test(line.text))) {
      changes.push([]);
    }
    changes.at(-1).push(line);
  });
  return [...changes, ...nested];
};

// Each BREAKING CHANGE paragraph of a change: the line number of its BREAKING CHANGE
// marker, the marker's text and the lines after it, and the number of the first
// indented one. The paragraph runs up to a blank line, the end of the change, or a
// line that reads as a git trailer: a capitalized hyphenated token such as
// "Signed-off-by" or "Co-authored-by", or one of the short single-word tokens below,
// followed by ": " or " #". A line that starts with any other "word:" is treated as
// part of the paragraph, which is how the author meant it and how the mismatch is
// detected. The parser's BREAKING CHANGE literal is case-sensitive, so these
// patterns are too.
const TRAILER_LINE =
  /^([A-Z][A-Za-z]*(?:-[A-Za-z]+)+|Closes|Fixes|Resolves|Refs|Cc|BREAKING CHANGE)(: | #)/;
const BREAKING_CHANGE_LINE = /^BREAKING[ -]CHANGE:\s*(.*)$/;

export const breakingChangeParagraphs = (lines) => {
  const paragraphs = [];
  for (let i = 0; i < lines.length; i += 1) {
    const match = lines[i].text.match(BREAKING_CHANGE_LINE);
    if (!match) continue;
    const paragraph = { line: lines[i].number, lines: [match[1].trim()], indentedLine: undefined };
    for (let j = i + 1; j < lines.length; j += 1) {
      const { number, text } = lines[j];
      if (text === '' || TRAILER_LINE.test(text)) break;
      if (/^\s/.test(text)) paragraph.indentedLine ??= number;
      paragraph.lines.push(text.trim());
      i = j;
    }
    paragraphs.push(paragraph);
  }
  return paragraphs;
};

// release-please renders a note for the changelog by joining its lines with spaces
// and indenting bullet and heading lines under the entry, so the comparison ignores
// how whitespace is laid out and looks only at the words.
const words = (text) => text.replace(/\s+/g, ' ').trim();

// parseConventionalCommits is what release-please runs over the commits of a
// release. It is not in the package's public index, so it is imported from its build
// path; a missing module here means release-please is not installed or has moved
// the file, and an exports map that hides the path reads the same way.
const MISSING_MODULE_CODES = new Set(['ERR_MODULE_NOT_FOUND', 'ERR_PACKAGE_PATH_NOT_EXPORTED']);
export const loadReleasePlease = async () => {
  try {
    const commit = await import('release-please/build/src/commit.js');
    return commit.parseConventionalCommits ?? commit.default.parseConventionalCommits;
  } catch (error) {
    if (!MISSING_MODULE_CODES.has(error.code)) throw error;
    return null;
  }
};

// A message the parser throws on is left out of the release entirely; release-please
// only logs the error at debug level. The logger below captures it for the rule's
// own message.
const capturingLogger = () => {
  const errors = [];
  const ignore = () => {};
  const debug = (line) => {
    const match = String(line).match(/^error message: (.*)$/s);
    if (match) errors.push(match[1]);
  };
  return { errors, logger: { error: ignore, warn: ignore, info: ignore, debug, trace: ignore } };
};

const publishedEntries = (parseConventionalCommits, message) => {
  const { errors, logger } = capturingLogger();
  const commits = parseConventionalCommits([{ sha: 'HEAD', message, files: [] }], logger);
  if (commits.length === 0) throw new Error(errors[0] ?? 'the message could not be parsed');
  return commits
    .flatMap((commit) => commit.notes)
    .filter((note) => note.title === 'BREAKING CHANGE')
    .map((note) => note.text);
};

// The fix each kind of failure asks for. The rule's message names the line of the
// BREAKING CHANGE marker, says what release-please will do and why, and ends with one
// of these; tests match on them.
export const ADVICE = {
  NEVER:
    'release-please/breaking-change-intact supports only the always applicability; ' +
    'never does not invert it.',

  MARKER:
    'release-please splits the message at a BEGIN_NESTED_COMMIT or END_NESTED_COMMIT ' +
    'marker wherever it appears in a line, which this rule mirrors only for a marker ' +
    'on a line of its own. Put the marker on a line of its own.',

  MISSING:
    'release-please is not installed, so this BREAKING CHANGE footer cannot be checked ' +
    'against it. Run `npm install` in the project root (bin/setup does this) and commit ' +
    'again.',

  UNPARSEABLE:
    'release-please cannot parse this commit message and would leave it out of the ' +
    'changelog entirely. The usual cause is a body line that starts in the first column ' +
    'with a word followed by "(" and has no closing ")" on the same line; rewrap or ' +
    'indent that line. The parser said:',

  MULTIPLE: 'Merge the BREAKING CHANGE paragraphs into one.',

  INDENTED: 'Start every line of the description in the first column.',

  TRUNCATED:
    'Rewrap the description so no line after the first starts that way. If the line is ' +
    'a footer or a change of its own, put a blank line before it.',

  OTHER:
    'Compare this with the description as written and rewrap it so release-please reads ' +
    'it as written.',
};

const indent = (text) => text.replace(/^/gm, '  ');

const FOOTER_SHAPE = 'starts with a word followed by ":" or " #"';

// The 1-based number of the first line of the paragraph that release-please read as
// a new footer: the line after the ones whose words make up the published entry.
// Undefined when the published entry does not end on a line boundary.
const firstDroppedLine = (paragraph, published) => {
  const kept = words(published ?? '');
  for (let i = 1; i < paragraph.lines.length; i += 1) {
    if (words(paragraph.lines.slice(0, i).join(' ')) === kept) return paragraph.line + i;
  }
  return undefined;
};

// Pairs each paragraph of a change with the entry release-please published for it.
// Exact matches are claimed first, so a footer that release-please dropped for a later
// one cannot take the later footer's entry as its own truncated form; then each
// unmatched paragraph claims the first remaining entry that is a prefix of it on a
// word boundary, which is what a later line cutting the paragraph short leaves
// behind. A paragraph with no entry of its own claims none.
const claimEntries = (paragraphs, published) => {
  const unclaimed = [...published];
  const claim = (paragraph, matches) => {
    const index = unclaimed.findIndex((entry) => words(entry) !== '' && matches(words(entry)));
    return index === -1 ? undefined : unclaimed.splice(index, 1)[0];
  };
  const claims = paragraphs.map((paragraph) => {
    const text = words(paragraph.lines.join(' '));
    const entry = claim(paragraph, (candidate) => candidate === text);
    return { paragraph, entry, intact: entry !== undefined };
  });
  for (const item of claims) {
    if (item.intact) continue;
    const text = words(item.paragraph.lines.join(' '));
    item.entry = claim(item.paragraph, (candidate) => text.startsWith(`${candidate} `));
  }
  return { claims, unclaimed };
};

// Explains why the paragraph is missing from what release-please publishes. `entry`
// is the published prefix the paragraph claimed, if any; `winner` the next paragraph
// release-please published, intact or cut short, if any; `unclaimed` the entries no
// paragraph claimed. A claimed prefix means a later line was read as a footer; no
// prefix while a later paragraph was published means this footer lost to a later one
// (release-please keeps the last BREAKING CHANGE footer of each change); anything
// else is reported with an unclaimed entry for comparison.
const explain = (paragraph, entry, winner, unclaimed) => {
  const at = `Line ${paragraph.line}: release-please will`;
  if (paragraph.indentedLine !== undefined) {
    return (
      `${at} truncate this BREAKING CHANGE description because line ` +
      `${paragraph.indentedLine} is indented, which release-please interprets as a footer of ` +
      `its own, dropping the lines before it. ${ADVICE.INDENTED}`
    );
  }
  if (entry !== undefined) {
    const dropped = firstDroppedLine(paragraph, entry);
    if (dropped !== undefined) {
      return (
        `${at} truncate this BREAKING CHANGE description because line ${dropped} ` +
        `${FOOTER_SHAPE}, which release-please interprets as the start of another footer. ` +
        ADVICE.TRUNCATED
      );
    }
    return (
      `${at} truncate this BREAKING CHANGE description to:\n${indent(entry)}\n` +
      `because a later line ${FOOTER_SHAPE}, which release-please interprets as the start of ` +
      `another footer. ${ADVICE.TRUNCATED}`
    );
  }
  if (winner !== undefined) {
    return (
      `${at} drop this BREAKING CHANGE footer and publish only the one on line ` +
      `${winner.line}. ${ADVICE.MULTIPLE}`
    );
  }
  const first = words(paragraph.lines[0]);
  const shown = unclaimed.find((candidate) => words(candidate).startsWith(first)) ?? unclaimed[0];
  return (
    `${at} publish this BREAKING CHANGE description as:\n` +
    `${indent(shown ?? '(nothing)')}\n${ADVICE.OTHER}`
  );
};

export const createRule = ({ loadParser = loadReleasePlease } = {}) =>
  async (parsed, when = 'always') => {
    if (when === 'never') return [false, ADVICE.NEVER];

    const message = cleanupLikeGit(parsed.raw ?? '');
    if (!message.some((line) => BREAKING_CHANGE_LINE.test(line.text))) return [true];

    const marker = misplacedMarker(message);
    if (marker !== undefined) return [false, `Line ${marker.number}: ${ADVICE.MARKER}`];

    const changes = splitLikeReleasePlease(message)
      .map((lines) => ({ lines, paragraphs: breakingChangeParagraphs(lines) }))
      .filter((change) => change.paragraphs.length > 0);
    if (changes.length === 0) return [true];

    const parseConventionalCommits = await loadParser();
    if (parseConventionalCommits === null) return [false, ADVICE.MISSING];

    for (const { lines, paragraphs } of changes) {
      let published;
      try {
        const text = lines.map((line) => line.text).join('\n');
        published = publishedEntries(parseConventionalCommits, text);
      } catch (error) {
        return [false, `${ADVICE.UNPARSEABLE}\n  ${error.message}`];
      }

      const { claims, unclaimed } = claimEntries(paragraphs, published);
      const missing = claims.find((claim) => !claim.intact);
      if (missing === undefined) continue;

      const winner = claims.find(
        (claim) => claim.entry !== undefined && claim.paragraph.line > missing.paragraph.line
      );
      return [false, explain(missing.paragraph, missing.entry, winner?.paragraph, unclaimed)];
    }
    return [true];
  };

export default createRule();
