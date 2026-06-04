# Beta Release Process

## Why This Is a Manual Process

Pre-releases of the `git` gem (e.g., `5.0.0.beta.1`) are published manually rather
than through the normal release-please automation. This is necessary because:

- **release-please does not support Ruby pre-release version formats** such as
  `5.0.0.beta.1`. release-please follows SemVer prerelease formatting and produces
  versions with a dash separator (e.g., `5.0.0-beta.0`), which is incompatible with
  RubyGems' dotted prerelease format (`5.0.0.beta.X`). For this reason,
  `.release-please-config.json` explicitly sets `"prerelease": false` — there is no
  configuration that makes release-please produce the right format.
- **We want release-please to keep accumulating commits toward the final `5.0.0`
  release.** If we merged a release-please PR for a beta version, it would update
  `.release-please-manifest.json` and lose the record of changes that should appear
  in the `5.0.0` changelog. By managing betas manually and leaving the manifest
  untouched, release-please continues to build the `5.0.0` release PR in the
  background.
- **Beta tags use a `pre/` prefix** (e.g., `pre/v5.0.0.beta.1`) so that
  release-please does not match them when searching for the last release SHA. This
  keeps the change accumulation correct.

---

## Beta Release Checklist

### 0. Set the beta number

Set `BETA` once at the start of each session. All commands below use it.

```bash
BETA=2  # replace with the actual beta number
```

> **Note:** Steps 1–3 are done before merging the release PR; steps 4–6 are done
> after. You will need to re-set `BETA` if you start a new shell session between
> the two phases.

### 1. Prepare the release branch

```bash
git switch main && git pull
git switch -c release/5.0.0.beta.${BETA}
```

### 2. Update files

- [ ] Bump `lib/git/version.rb`:

  ```bash
  sed -i "" "s/VERSION = '.*'/VERSION = '5.0.0.beta.${BETA}'/" lib/git/version.rb
  ```

- [ ] Update the announcement in `README.md`:
  - Change the heading date and version number
  - Update the % complete estimate
  - Update the RubyGems link to point to the new version

### 3. Commit and open a PR

```bash
git add lib/git/version.rb README.md
git commit -m "chore: release v5.0.0.beta.${BETA}"
git push -u origin release/5.0.0.beta.${BETA}
```

Open a PR targeting `main` and merge it once CI passes.

> **Important:** Do **not** update `.release-please-manifest.json`. Leaving it at
> the last stable 4.x release version is what allows release-please to keep
> accumulating changes toward `5.0.0`.

### 4. Tag the release commit

Tag before building to ensure the gem and the GitHub release are pinned to the
exact same commit. If `main` advances after the PR merges, building first and
tagging later would cause the published gem and tag to diverge.

```bash
BETA=2  # re-set if this is a new shell session
git switch main && git pull
git tag pre/v5.0.0.beta.${BETA}
git push origin pre/v5.0.0.beta.${BETA}
```

### 5. Build, publish, and create a GitHub release

Check out the tag before building to guarantee the gem is built from the exact
tagged commit, not from whatever `main` happens to be at build time.

```bash
git checkout pre/v5.0.0.beta.${BETA}
bundle exec rake build
gem push pkg/git-5.0.0.beta.${BETA}.gem

gh release create pre/v5.0.0.beta.${BETA} \
  pkg/git-5.0.0.beta.${BETA}.gem \
  --title "v5.0.0.beta.${BETA}" \
  --notes "Beta ${BETA} pre-release of v5.0.0. See the README for details." \
  --prerelease
```

### 6. Verify

- [ ] RubyGems: `https://rubygems.org/gems/git/versions/5.0.0.beta.${BETA}`
- [ ] GitHub release: `https://github.com/ruby-git/ruby-git/releases/tag/pre/v5.0.0.beta.${BETA}`
