# commitlint-plugin-release-please

[commitlint](https://commitlint.js.org) rules that keep commit messages as
[release-please](https://github.com/googleapis/release-please) will publish them.

## Rules

### release-please/breaking-change-intact

Fails a commit whose `BREAKING CHANGE:` footer release-please would publish differently
from how the author wrote it.

release-please parses commits with `@conventional-commits/parser`, which reads a footer
continuation line that starts with `word:` or `word #` as a new footer, so a wrapped
`BREAKING CHANGE:` paragraph can lose every line after the first. commitlint's own
parser keeps every line and cannot see this. The rule splits the message into changes
the way release-please does, hands each change to the installed release-please, and
compares what comes back with the paragraph as written. Its error names the line of
the footer, says why release-please cuts it short, and says how to rewrap.

Only `always` is supported, and `never` fails with a message saying so. The rule
imports release-please from `node_modules` the first time it meets a
`BREAKING CHANGE:` paragraph and fails with install advice when the package is
missing. That advice cannot reach a clone whose `node_modules` predates the plugin
itself: commitlint loads plugins before any rule runs, so such a clone fails every
commit until `npm install` is rerun. The plugin pins release-please to an exact
version so that an upgrade is a deliberate change that runs the behavior tests. That
version has to track the release-please bundled by `googleapis/release-please-action`
in the release workflow, which is what publishes the changelog (issue 1921).

## Use

```yaml
# .commitlintrc.yml
plugins: [release-please]
rules:
  release-please/breaking-change-intact: [2, always]
```

## Test

```sh
npm test
```

`fixtures/breaking-change-intact.json` is a table of commit messages with the verdict
and advice the rule must give. `breaking-change-intact.test.mjs` runs the rule over the
table; `release-please-behavior.test.mjs` runs the installed release-please over the
same table so that a release-please upgrade which changes footer parsing fails here
first.
