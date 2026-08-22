<!--
# @markup markdown
# @title Change Log
-->

# Change Log

## [5.2.0](https://github.com/ruby-git/ruby-git/compare/v5.1.0...v5.2.0) (2026-08-22)


### Features

* **checkout:** Support the :orphan option in Repository#checkout ([265a997](https://github.com/ruby-git/ruby-git/commit/265a997ca972868a392ee71489b0e34e42ff70ec))


### Bug Fixes

* Exclude the .claude/skills symlink and other dev files from the gem ([ae4ef0e](https://github.com/ruby-git/ruby-git/commit/ae4ef0e6185285ee325fabdc9bc9214527a80ac5))


### Other Changes

* Add a markdown link checker ([8000810](https://github.com/ruby-git/ruby-git/commit/80008103ea7c3ad71404b75f0c04f8e81fd226f9))
* Archive the v5.x redesign documents ([4bed4ce](https://github.com/ruby-git/ruby-git/commit/4bed4ce1a520dda9cea9336ea4f8784f48cba306))
* Fix broken relative links and heading anchors ([0bf31b8](https://github.com/ruby-git/ruby-git/commit/0bf31b85877f30746c51a6af765b4c707fcfe9ed))
* Fold the remaining plan documents into issues and adrs ([74944d9](https://github.com/ruby-git/ruby-git/commit/74944d9909e4a35f1fc7a88841e82b93e16a7e21))
* **fsck:** Build the second root commit through the public API ([3a7f083](https://github.com/ruby-git/ruby-git/commit/3a7f083b00498ace343622c8e7e20af6d498f247))
* Make command-class policy self-contained in the skills ([8158d2a](https://github.com/ruby-git/ruby-git/commit/8158d2ae8c1e0d108f2ad978056669dc95be6035))

## [5.1.0](https://github.com/ruby-git/ruby-git/compare/v5.0.5...v5.1.0) (2026-08-18)


### Features

* **grep:** Expose perl_regexp on the Git::Repository#grep facade ([759436f](https://github.com/ruby-git/ruby-git/commit/759436f7b59ac5028e38a2158a9a354720640415))
* **log:** Expose perl_regexp on the log path ([df8ea33](https://github.com/ruby-git/ruby-git/commit/df8ea33bb7d019d1a52fbb99370d9ffd67bf279f))


### Other Changes

* Add fiddle as a Windows development dependency ([1847989](https://github.com/ruby-git/ruby-git/commit/18479892529bd1f992596cbc055a9a42be326680))
* Bound the locale job's apt step so a stalled mirror fails fast ([3a5d83b](https://github.com/ruby-git/ruby-git/commit/3a5d83b7685091a4abbde2c84c0136214fa66e5d))
* Cover the perl_regexp escape hatch for non-ASCII regex matching ([55e2ded](https://github.com/ruby-git/ruby-git/commit/55e2ded4563a39a0389dbbd52f8425da9a1e3aea))
* Document the Git for Windows byte-matching regex limitation ([9aaedbd](https://github.com/ruby-git/ruby-git/commit/9aaedbd94488bcfeef05cc56dfce61ce69f529fc))
* Document the windows symlink privilege requirement ([696dff3](https://github.com/ruby-git/ruby-git/commit/696dff3cbf09647bbfa51279f7e35fc8a85eaab4))
* Express development dependency conditions as named predicates ([acca20a](https://github.com/ruby-git/ruby-git/commit/acca20a43a6fb79f6b36de900ac8aa8c2488d87f))
* Fix a broken section link in the pre-review checklist ([719f595](https://github.com/ruby-git/ruby-git/commit/719f595af69c1afcf6b025d1a2bb920963738f80))
* Make integration fixtures independent of git and platform settings ([c2a1592](https://github.com/ruby-git/ruby-git/commit/c2a159287ec007793c125929029303707669c8ad))
* Pin rubocop to lf line endings ([7f40413](https://github.com/ruby-git/ruby-git/commit/7f40413c3eded1af7a3dede02e1d94d7dc9c829b))
* Pin test repository config from a single source ([6e227b7](https://github.com/ruby-git/ruby-git/commit/6e227b70f59f4bbaf2bbc1d30a4b1b86ffbe6afc))
* Scope the symlink rescue to the symlink call ([c2bed8f](https://github.com/ruby-git/ruby-git/commit/c2bed8fefdd8bdf2efa84432c318b2b39ba223d2))
* Skip the symlink specs when the host cannot create symlinks ([8e9b667](https://github.com/ruby-git/ruby-git/commit/8e9b667daeb6a179a02df7c946a495c7b7e6fce5))

## [5.0.5](https://github.com/ruby-git/ruby-git/compare/v5.0.4...v5.0.5) (2026-08-09)


### Bug Fixes

* Detect Darwin under JRuby when pinning LC_ALL ([89bf625](https://github.com/ruby-git/ruby-git/commit/89bf62579999bec27a9b0f1aab16d37e7d5af2b8)), closes [#1669](https://github.com/ruby-git/ruby-git/issues/1669)
* Pin LC_ALL to a locale that exists on the host platform ([5a4e0d6](https://github.com/ruby-git/ruby-git/commit/5a4e0d657b0e0828de0b38f283ae60dfbe2d4cc6)), closes [#1669](https://github.com/ruby-git/ruby-git/issues/1669)


### Other Changes

* Correct two imprecise claims in the build-complete comment ([c4391cd](https://github.com/ruby-git/ruby-git/commit/c4391cdf441a8379dee4cda59f800da41bf8e8b2)), closes [#1675](https://github.com/ruby-git/ruby-git/issues/1675)
* Gate merges on a matrix-free job instead of the per-matrix checks ([47f2d17](https://github.com/ruby-git/ruby-git/commit/47f2d17d16d1ea201bf9cc8f74aedffa7619eb0a)), closes [#1675](https://github.com/ruby-git/ruby-git/issues/1675)
* Remove vestigial matrix dimensions ([3a89886](https://github.com/ruby-git/ruby-git/commit/3a8988650a7d8f0a81c093c470fb9f524142c9b9)), closes [#1676](https://github.com/ruby-git/ruby-git/issues/1676)
* Run RuboCop and YARD once instead of on every matrix job ([0726964](https://github.com/ruby-git/ruby-git/commit/072696491662867cfbc0424febcf36542548f051))
* Run the suite once with en_US.UTF-8 unavailable ([6e012c5](https://github.com/ruby-git/ruby-git/commit/6e012c54d52c8b0c25bf629f07e310b6fcbac229)), closes [#1669](https://github.com/ruby-git/ruby-git/issues/1669)
* Run the test suite under a non-English locale ([c65d402](https://github.com/ruby-git/ruby-git/commit/c65d4022f358a4e4e676dbf2492427851205cdd6)), closes [#1670](https://github.com/ruby-git/ruby-git/issues/1670)
* Skip the All Specs Passed gate on release PRs ([6dfeee0](https://github.com/ruby-git/ruby-git/commit/6dfeee0ed508932393106c8887d9b7c9ef9dbbca)), closes [#1675](https://github.com/ruby-git/ruby-git/issues/1675)
* Warm bundler caches at default-branch scope on push to main ([2821477](https://github.com/ruby-git/ruby-git/commit/282147796f6b859fb9c7f8b5a614cab399cc9539)), closes [#1674](https://github.com/ruby-git/ruby-git/issues/1674)

## [5.0.4](https://github.com/ruby-git/ruby-git/compare/v5.0.3...v5.0.4) (2026-08-07)


### Bug Fixes

* Return the full ref path in the ls_remote :ref value ([34b0b06](https://github.com/ruby-git/ruby-git/commit/34b0b0678c6ab47f77afaf7331fb6b41160def1a)), closes [#1416](https://github.com/ruby-git/ruby-git/issues/1416)


### Other Changes

* Pin the locale for the CommandLine::Capturing integration spec ([6040867](https://github.com/ruby-git/ruby-git/commit/6040867ecfb44434a26006f9b79bebfb590d1ca8))

## [5.0.3](https://github.com/ruby-git/ruby-git/compare/v5.0.2...v5.0.3) (2026-08-07)


### Bug Fixes

* Drop unsupported -- separator from remote remove/rename commands ([8ec466f](https://github.com/ruby-git/ruby-git/commit/8ec466f8b282a5e94abd7d499bc26a92d94b2fc3))
* Remove unreachable case branch in Patch#apply_file_mode ([896fc49](https://github.com/ruby-git/ruby-git/commit/896fc49e3c2c03c401fe1b213c3f75bb40730521))
* Remove unreachable nil check in Git::Parsers::Grep.parse ([74e919a](https://github.com/ruby-git/ruby-git/commit/74e919a401126ad4415615f92cc9597e966239c6))


### Other Changes

* Add Claude Code support alongside GitHub Copilot ([37f7d6a](https://github.com/ruby-git/ruby-git/commit/37f7d6a14c6d53bcf5b9644b8023d323290a5977))
* Add unit spec for Git::EncodingUtils ([5f0f10e](https://github.com/ruby-git/ruby-git/commit/5f0f10e4db78324bbe453de49598564a25f3428a))
* Consolidate parallel and serial spec rake tasks ([49616b1](https://github.com/ruby-git/ruby-git/commit/49616b12f52c6941a8617afbf7c56e7d7d5fe0f6))
* Cover :index option in Git::Factories#worktree_open_options_after_init ([efeba22](https://github.com/ruby-git/ruby-git/commit/efeba2294bb05327489a6523c46f26dc7392a84e))
* Cover #path when both src and dst are nil ([3a1a05a](https://github.com/ruby-git/ruby-git/commit/3a1a05a9be13057a1fc304df5008866634179124))
* Cover edge-case branches in Git::Parsers::Diff ([38d8b3f](https://github.com/ruby-git/ruby-git/commit/38d8b3f88f4f76a65776e9f6b8b87c6bb839e710))
* Cover Errno::ESRCH timeout-race rescue in run_process_executer ([899bf36](https://github.com/ruby-git/ruby-git/commit/899bf36399489038524cecf1d7ac2c606df03bde))
* Cover Git::Branch#merge ([71c0ea3](https://github.com/ruby-git/ruby-git/commit/71c0ea39d4c786a38245a8fb95fd93235ee03903))
* Cover Git::Branch#stashes ([27ba130](https://github.com/ruby-git/ruby-git/commit/27ba130a6cd3ef78171d1bb20230459c3f678a3a))
* Cover Git::Diff#name_status ([fa2ee98](https://github.com/ruby-git/ruby-git/commit/fa2ee98fd4613177843d285f7bc4a2ffb44ca79c))
* Cover Git::Factories#parse_clone_stderr unparseable-output branch ([65aa9b9](https://github.com/ruby-git/ruby-git/commit/65aa9b9318c7f8a8986c2aaae7dd0af0aeec4d69))
* Cover Git::Parsers::CatFile.each_header without trailing separator ([b7a9ed9](https://github.com/ruby-git/ruby-git/commit/b7a9ed93e03dcbd22a4fb25e9bb7b9c49647262d))
* Cover Git::Parsers::LsTree.parse with no tab-separated filename ([98b9ebf](https://github.com/ruby-git/ruby-git/commit/98b9ebf03c49f51c76b2e56dd670a9f68f220da8))
* Cover Git::Parsers::Remote.apply_pair unrecognized-variable branch ([03b10f6](https://github.com/ruby-git/ruby-git/commit/03b10f618a2f012b578ab995120cedbcd96ed8d1))
* Cover Git::Stashes#save ([7bca04c](https://github.com/ruby-git/ruby-git/commit/7bca04c53e64c747627784773d0c03ad0b9ff2e3))
* Cover Git.const_missing fallback branch for unrelated constants ([05c3c43](https://github.com/ruby-git/ruby-git/commit/05c3c4350e18bf1403fa314902708cfc40848c70))
* Cover Git.export ([4bd7f58](https://github.com/ruby-git/ruby-git/commit/4bd7f58432a19385ff55aecca9e89e2d9a96fa4a))
* Cover normalize_fetch_keys with a String option key ([47fb7fe](https://github.com/ruby-git/ruby-git/commit/47fb7fe061df9177a26ec7ada90b35b902ffc1df))
* Disable coverage for spec:integration, add SPEC filtering, fix formatters ([cb53d03](https://github.com/ruby-git/ruby-git/commit/cb53d03f8b671873f24368aadcafec638de32345))
* Document the project test coverage policy ([d378c1e](https://github.com/ruby-git/ruby-git/commit/d378c1e8b75e0c4209e17cc040ed36eb93053797))
* Enforce 100% unit test coverage on pull requests ([a446098](https://github.com/ruby-git/ruby-git/commit/a446098af548039b2c8b68bbb6562a53cb79fe40))
* Guard checkout-index nonexistent-path spec for git &lt; 2.30.0 ([cf212a9](https://github.com/ruby-git/ruby-git/commit/cf212a98b41218a7940ce54aa9b7c56a630412c3))
* Guard worktree repair spec for git &lt; 2.29.0 ([c527fb1](https://github.com/ruby-git/ruby-git/commit/c527fb15c2f21f9be5913192d43c847cf49681eb))
* **merge:** Fix incorrect version-gated failure expectation in quit_spec ([24c5ba4](https://github.com/ruby-git/ruby-git/commit/24c5ba4ce77b02413485d226a94b283f6af9d110))
* Read the gem version without loading lib/git/version.rb ([45c4b14](https://github.com/ruby-git/ruby-git/commit/45c4b14e944fcb43bda800823e377cf954ce2d3b))
* Require git 2.39.0 for maintenance register/unregister --config-file specs ([5b1fd52](https://github.com/ruby-git/ruby-git/commit/5b1fd527c39e4b3f1796851795a44694d94f4402))
* Skip get-urlmatch scope spec on git &lt; 2.42.0 ([e1ede7a](https://github.com/ruby-git/ruby-git/commit/e1ede7adddea28b654a183c618fc2336b5ffb83b))
* Upgrade simplecov and simplecov-rspec to ~&gt; 1.0 ([65e92b9](https://github.com/ruby-git/ruby-git/commit/65e92b9a9a621435efbf2a0855d48c47bb62425d))

## [5.0.2](https://github.com/ruby-git/ruby-git/compare/v5.0.1...v5.0.2) (2026-08-02)


### Bug Fixes

* Add bin/build-git-versions and bin/test-git-versions scripts ([3314503](https://github.com/ruby-git/ruby-git/commit/3314503708efcec2f386ca97bb6d96309a6c5c1a))


### Other Changes

* Align CONTRIBUTING.md with current architecture and testing conventions ([60ac8e9](https://github.com/ruby-git/ruby-git/commit/60ac8e940776a3fb4efe46a98574ca5bbfcd718e))
* Allow disabling SimpleCov via COVERAGE=false env var ([3788418](https://github.com/ruby-git/ruby-git/commit/37884189eb646013628f78b6671e9876f0ebb925))
* Allow disabling SimpleCov via COVERAGE=false env var ([3788418](https://github.com/ruby-git/ruby-git/commit/37884189eb646013628f78b6671e9876f0ebb925))
* Avoid git-version-dependent all-zero SHA in stash store integration spec ([82a15e5](https://github.com/ruby-git/ruby-git/commit/82a15e57ebca03df3c3802f153c3545bc46920f4))
* Make 5.0.0 release more prominent in README ([2c8c42d](https://github.com/ruby-git/ruby-git/commit/2c8c42d30a7d7d35e03f1c4f8489fa49c866cded))
* Move Git::Repository::Factories and PathResolver to Git namespace ([dd0ae7b](https://github.com/ruby-git/ruby-git/commit/dd0ae7b34b912187f150d56b38f6eeb14b8882bf))
* Update README badges ([079a121](https://github.com/ruby-git/ruby-git/commit/079a1211216666f190583b2bfd3124ebb823ae58))

## [5.0.1](https://github.com/ruby-git/ruby-git/compare/v5.0.0...v5.0.1) (2026-07-30)


### Other Changes

* Review and streamline AI agent instructions ([536eb86](https://github.com/ruby-git/ruby-git/commit/536eb865440da8c0e74de0dfc32828b82fc675db))
* Summarize v5.0.0 as architectural redesign in CHANGELOG ([712c93e](https://github.com/ruby-git/ruby-git/commit/712c93ea237490be3b037250af44cd6633baf68f))

## [5.0.0](https://github.com/ruby-git/ruby-git/compare/v4.1.2...v5.0.0) (2026-07-28)

v5.0.0 is a complete architectural redesign of the `git` gem. The monolithic
`Git::Base` and `Git::Lib` classes have been replaced by a layered design:
`Git::Commands::*` for git command execution, `Git::Repository` as the public
API surface, and dedicated parser classes. Most v4.x code requires **no
changes** — compatibility shims emit deprecation warnings pointing to the v5.x
equivalents.

For a full migration guide, including deprecated method renames and code
examples, see [UPGRADING.md](UPGRADING.md).

### ⚠ BREAKING CHANGES

* **`Git::Base` class removed; constant remains as a deprecated shim.**
  `Git::Base.new` raises an error and `require 'git/base'` raises `LoadError`.
  The `Git::Base` constant still exists as a deprecated module included in
  `Git::Repository`, so `is_a?(Git::Base)` checks and monkeypatches continue to
  work but emit deprecation warnings. Update explicit `Git::Base` class
  references to use `Git::Repository`; the shim is removed in v6.0.0.
* **`Git::Lib` removed.** Calling `#lib` on a repository object returns `self`
  with a deprecation warning (forwarding to `Git::Repository` methods where
  possible), but `Git::Lib` itself no longer exists. Methods unique to
  `Git::Lib` with no `Git::Repository` counterpart raise `NoMethodError`.
* **`Git.open`, `Git.bare`, `Git.clone`, and `Git.init` return `Git::Repository`
  instead of `Git::Base`.** For most callers this is transparent. Code that
  explicitly checks `is_a?(Git::Base)` must be updated to `is_a?(Git::Repository)`.
* **Unsupported options now raise `ArgumentError`.** Unknown keyword options
  that were silently ignored in v4.x may now raise `ArgumentError`. Check
  option names against the documented API when upgrading.
* **`Git::Log#object` is not a path limiter.** Use `Git::Log#path` to filter
  log results by file path.
* **`Git::CommandLineResult` is deprecated** (removed in v6.0.0). Use
  `Git::CommandLine::Result` instead.

For the full list of commits included in this release, see the
[v5.0.0 commit history](https://github.com/ruby-git/ruby-git/compare/v4.1.2...v5.0.0).

## [4.1.2](https://github.com/ruby-git/ruby-git/compare/v4.1.1...v4.1.2) (2026-01-10)


### Other Changes

* Add Continuity section to Governance ([a2f644c](https://github.com/ruby-git/ruby-git/commit/a2f644c0caa7b60137e0a1ef79eabaf880d18ac6))
* Add Roberto Decurnex to Maintainers Emeritus ([5104537](https://github.com/ruby-git/ruby-git/commit/5104537e15c5d14357c353b08706973c2669ad31))
* Enable releases from 4.x maintenance branch ([5377de6](https://github.com/ruby-git/ruby-git/commit/5377de602e6ecd947d3feadb3df49d6a63556f53))
* Move inactive maintainers to Emeritus per governance policy ([f09e4d1](https://github.com/ruby-git/ruby-git/commit/f09e4d1e68cd5db6535ba737720eb495ea8422ec))

## [4.1.1](https://github.com/ruby-git/ruby-git/compare/v4.1.0...v4.1.1) (2026-01-09)


### Other Changes

* Add AI Policy and update documentation ([8616cdf](https://github.com/ruby-git/ruby-git/commit/8616cdf7c6cfd1a3f2ccb931f59367b0fdfa36d1))
* Add code of conduct links ([0769c8e](https://github.com/ruby-git/ruby-git/commit/0769c8ede791a2578291fa301d74144bc7fb2bfb))
* Add governance policy and update project policies ([8d8263c](https://github.com/ruby-git/ruby-git/commit/8d8263c8395ff4e127b7dc6eb25b0371c272593a))
* Add Quick Start section and reorganize README for new users ([1811a75](https://github.com/ruby-git/ruby-git/commit/1811a75e4b0b8b8233988d38a411ba585f35c044))
* Clarify JRuby on Windows support policy ([c37b3d6](https://github.com/ruby-git/ruby-git/commit/c37b3d6c256cdc925578c7ff198f6b351dcb5844))

## [4.1.0](https://github.com/ruby-git/ruby-git/compare/v4.0.7...v4.1.0) (2026-01-02)


### Features

* Add per-instance git_ssh configuration support ([26c1199](https://github.com/ruby-git/ruby-git/commit/26c119969ec71c23c965f55f0570471f8ddf333a))
* **clone:** Add single_branch option ([a6929bb](https://github.com/ruby-git/ruby-git/commit/a6929bb0bfd51cba3a595e47740897ca619da468))
* **diff:** Allow multiple paths in diff path limiter ([c663b62](https://github.com/ruby-git/ruby-git/commit/c663b62a0c9075a18c112e2cda3744f88f42ab7e))
* **remote:** Add remote set-branches helper ([a7dab2b](https://github.com/ruby-git/ruby-git/commit/a7dab2bdf9088f0610dfbf3e3b78677b90195f75))


### Bug Fixes

* Prevent GIT_INDEX_FILE from corrupting worktree indexes ([27c0f16](https://github.com/ruby-git/ruby-git/commit/27c0f1629927ae23a5bb8efc4df79756a9e4406b))
* **test:** Use larger timeout values on JRuby to prevent flaky tests ([aa8fd8b](https://github.com/ruby-git/ruby-git/commit/aa8fd8b0435246f70579bfab3cde8d45bc23233a))


### Other Changes

* Add git version support policy ([fbb0c60](https://github.com/ruby-git/ruby-git/commit/fbb0c60c56a01222133b61eb5267148773b4239c))
* **clone:** Simplify single_branch validator ([3900233](https://github.com/ruby-git/ruby-git/commit/39002330d42c4a2b3f0413ba920e6fd534880e03))
* Expand AI instructions with comprehensive workflows ([04907ed](https://github.com/ruby-git/ruby-git/commit/04907edd89dd716d85f190d828cbf6a0c43d47f6))
* Make env_overrides more flexible and idiomatic ([dc0b43b](https://github.com/ruby-git/ruby-git/commit/dc0b43bccbc9c57c445efc303a3e0f6a71cbd66f))

## [4.0.7](https://github.com/ruby-git/ruby-git/compare/v4.0.6...v4.0.7) (2025-12-29)


### Other Changes

* Add GitHub Copilot instructions ([edf10ec](https://github.com/ruby-git/ruby-git/commit/edf10ec83e0f54153629e32a53fe38856b779aa0))
* Add redesign index page ([3fdf9e2](https://github.com/ruby-git/ruby-git/commit/3fdf9e2cc2e03f0c3ce26bd17c878c3443fb1323))
* Add Ruby 4.0 to continuous integration test matrix ([be3cb89](https://github.com/ruby-git/ruby-git/commit/be3cb894f8c346eb8ed0128bbc32b84f90f8b0e3))
* Address PR review feedback ([c82a3b4](https://github.com/ruby-git/ruby-git/commit/c82a3b41ecd0a7c779726abe30582148ba9e81eb))

## [4.0.6](https://github.com/ruby-git/ruby-git/compare/v4.0.5...v4.0.6) (2025-11-11)


### Bug Fixes

* Standardize deprecation handling and consolidate tests (fixes [#842](https://github.com/ruby-git/ruby-git/issues/842)) ([a731110](https://github.com/ruby-git/ruby-git/commit/a73111017a64bd1ae83d35f9d5f4a18f43f7c2eb))


### Other Changes

* Refactor Rakefile by splitting tasks into separate files ([bd69f9b](https://github.com/ruby-git/ruby-git/commit/bd69f9b6a48298a9c6eed1987bec55b67384b89c))
* Remove redundant escape in BRANCH_LINE_REGEXP (Style/RedundantRegexpEscape) ([4a03b5c](https://github.com/ruby-git/ruby-git/commit/4a03b5ce2939ad8a92496a443a6edcd6ce059a70))

## [4.0.5](https://github.com/ruby-git/ruby-git/compare/v4.0.4...v4.0.5) (2025-08-20)


### Bug Fixes

* Properly parse UTF-8(multibyte) file paths in git output ([8e6a11e](https://github.com/ruby-git/ruby-git/commit/8e6a11e5f3749a25e1d56ffbc0332a98846a395b))


### Other Changes

* Document and announce the proposed architectural redesign ([e27255a](https://github.com/ruby-git/ruby-git/commit/e27255ad6d06fbf84c1bc32efc2e0f8eb48290a7))
* Minor change to the architecture redesign document ([b4634b5](https://github.com/ruby-git/ruby-git/commit/b4634b596d71bd59857b7723d20f393eb5024faa))
* Rearrange README so that Summary is at the top ([3d2c473](https://github.com/ruby-git/ruby-git/commit/3d2c47388b9d4dc730964fc316afb2fc0fb7c90a))
* Update ClassLength max in .rubocop_todo.yml for CI passing ([4430478](https://github.com/ruby-git/ruby-git/commit/4430478e087b33839d1a3b307a418b806197f279))

## [4.0.4](https://github.com/ruby-git/ruby-git/compare/v4.0.3...v4.0.4) (2025-07-09)


### Bug Fixes

* Remove deprecation from Git::Path ([ab1e207](https://github.com/ruby-git/ruby-git/commit/ab1e20773c6a300b546841f79adf8dd6e707250e))
* Remove deprecation from Git::Stash ([9da1e91](https://github.com/ruby-git/ruby-git/commit/9da1e9112e38c0e964dd2bc638bda7aebe45ba91))


### Other Changes

* Add tests for Git::Base#set_index including deprecation ([e6ccb11](https://github.com/ruby-git/ruby-git/commit/e6ccb11830a794f12235e47032235c3284c84cf6))
* Add tests for Git::Base#set_working including deprecation ([ee11137](https://github.com/ruby-git/ruby-git/commit/ee1113706a8e34e9631f0e2d89bd602bca87f05f))
* Add tests to verify Git::Object.new creates the right type of object ([ab17621](https://github.com/ruby-git/ruby-git/commit/ab17621d65a02b70844fde3127c9cbb219add7f5))
* Verify deprecated Git::Log methods emit a deprecation warning ([abb0efb](https://github.com/ruby-git/ruby-git/commit/abb0efbdb3b6bb49352d097b1fece708477d4362))

## [4.0.3](https://github.com/ruby-git/ruby-git/compare/v4.0.2...v4.0.3) (2025-07-08)


### Bug Fixes

* Correct the deprecation horizon for Git deprecations ([b7b7f38](https://github.com/ruby-git/ruby-git/commit/b7b7f38ccb88ba719e8ea7cb3fea14474b19a00c))
* Fix Rubocop Layout/EmptyLinesAroundClassBody offense ([1de27da](https://github.com/ruby-git/ruby-git/commit/1de27daabed18b47a42539fe69b735d8ee90cbbb))
* Internally create a Stash with non-deprecated initializer args ([8b9b9e2](https://github.com/ruby-git/ruby-git/commit/8b9b9e2f3b3fa525973785f642331317ade35936))
* Report correct line number in deprecation warnings ([cca0deb](https://github.com/ruby-git/ruby-git/commit/cca0debb4166c809af76f9dc586e4fd06e142d44))
* Un-deprecate Git::Diff methods ([761b6ff](https://github.com/ruby-git/ruby-git/commit/761b6ffcd363f4329a9cbafbf1379513a19ff174))


### Other Changes

* Make tests that emit a deprecation warning fail ([7e211d7](https://github.com/ruby-git/ruby-git/commit/7e211d7b2b7cc8d9da4a860361bef52280a5e73b))
* Update all tests to not use deprecated features ([33ab0e2](https://github.com/ruby-git/ruby-git/commit/33ab0e255e229e22d84b14a4d4f5fb829c1fe37c))

## [4.0.2](https://github.com/ruby-git/ruby-git/compare/v4.0.1...v4.0.2) (2025-07-08)


### Bug Fixes

* Call Git::Index#new correctly from initialize_components ([07dfab5](https://github.com/ruby-git/ruby-git/commit/07dfab5804874cbc52469bd40203b6d0b08be7a1))


### Other Changes

* Announce that the project has adopted RuboCop ([3d6cac9](https://github.com/ruby-git/ruby-git/commit/3d6cac94b47b3c1b1915f5c37f9e811041210ddc))
* Update comment to be accurate ([3a87722](https://github.com/ruby-git/ruby-git/commit/3a87722760176db54dfef9631de6191b183ab223))

## [4.0.1](https://github.com/ruby-git/ruby-git/compare/v4.0.0...v4.0.1) (2025-07-06)


### Bug Fixes

* Fix Rubocop Layout/LineLength offense ([52d80ac](https://github.com/ruby-git/ruby-git/commit/52d80ac592d9139655d47af8e764eebf8577fda7))
* Fix Rubocop Lint/EmptyBlock offense ([9081f0f](https://github.com/ruby-git/ruby-git/commit/9081f0fb055e0d6cc693fd8f8bf47b2fa13efef0))
* Fix Rubocop Lint/MissingSuper offense ([e9e91a8](https://github.com/ruby-git/ruby-git/commit/e9e91a88fc338944b816ee6929cadf06ff1daab5))
* Fix Rubocop Lint/StructNewOverride offense ([141c2cf](https://github.com/ruby-git/ruby-git/commit/141c2cfd8215f5120f536f78b3c066751d74aabe))
* Fix Rubocop Lint/SuppressedException offense ([4372a20](https://github.com/ruby-git/ruby-git/commit/4372a20b0b61e862efb7558f2274769ae17aa2c9))
* Fix Rubocop Lint/UselessConstantScoping offense ([54c4a3b](https://github.com/ruby-git/ruby-git/commit/54c4a3bba206ab379a0849fbc9478db5b61e192a))
* Fix Rubocop Metrics/AbcSize offense ([256d860](https://github.com/ruby-git/ruby-git/commit/256d8602a4024d1fbe432eda8bbcb1891fb726bc))
* Fix Rubocop Metrics/BlockLength offense ([9c856ba](https://github.com/ruby-git/ruby-git/commit/9c856ba42d0955cb6c3f5848f9c3253b54fd3735))
* Fix Rubocop Metrics/ClassLength offense (exclude tests) ([d70c800](https://github.com/ruby-git/ruby-git/commit/d70c800263ff1347109688dbb5b66940c6d64f2c))
* Fix Rubocop Metrics/ClassLength offense (refactor Git::Log) ([1aae57a](https://github.com/ruby-git/ruby-git/commit/1aae57a631aa331a84c37122ffc8fa09b415c6c5))
* Fix Rubocop Metrics/ClassLength offense (refactor Git::Status) ([e3a378b](https://github.com/ruby-git/ruby-git/commit/e3a378b6384bf1d0dc80ebc5aea792f9ff5b512a))
* Fix Rubocop Metrics/CyclomaticComplexity offense ([abfcf94](https://github.com/ruby-git/ruby-git/commit/abfcf948a08578635f7e832c31deaf992e6f3fb1))
* Fix Rubocop Metrics/MethodLength offense ([e708c36](https://github.com/ruby-git/ruby-git/commit/e708c3673321bdcae13516bd63f3c5d051b3ba33))
* Fix Rubocop Metrics/ParameterLists offense ([c7946b0](https://github.com/ruby-git/ruby-git/commit/c7946b089aba648d0e56a7435f85ed337e33d116))
* Fix Rubocop Metrics/PerceivedComplexity offense ([5dd5e0c](https://github.com/ruby-git/ruby-git/commit/5dd5e0c55fd37bb4baf3cf196f752a4f6c142ca7))
* Fix Rubocop Naming/AccessorMethodName offense ([e9d9c4f](https://github.com/ruby-git/ruby-git/commit/e9d9c4f2488d2527176b87c547caecfae4040219))
* Fix Rubocop Naming/HeredocDelimiterNaming offense ([b4297a5](https://github.com/ruby-git/ruby-git/commit/b4297a54ef4a0106e9786d10230a7219dcdbf0e8))
* Fix Rubocop Naming/PredicateMethod offense ([d33f7a8](https://github.com/ruby-git/ruby-git/commit/d33f7a8969ef1bf47adbca16589021647d5d2bb9))
* Fix Rubocop Naming/PredicatePrefix offense ([57edc79](https://github.com/ruby-git/ruby-git/commit/57edc7995750b8c1f792bcae480b9082e86d14d3))
* Fix Rubocop Naming/VariableNumber offense ([3fba6fa](https://github.com/ruby-git/ruby-git/commit/3fba6fa02908c632891c67f32ef7decc388e8147))
* Fix Rubocop Style/ClassVars offense ([a2f651a](https://github.com/ruby-git/ruby-git/commit/a2f651aea60e43b9b41271f03fe6cb6c4ef12b70))
* Fix Rubocop Style/Documentation offense ([e80c27d](https://github.com/ruby-git/ruby-git/commit/e80c27dbb50b38e71db55187ce1a630682d2ef3b))
* Fix Rubocop Style/IfUnlessModifier offense ([c974832](https://github.com/ruby-git/ruby-git/commit/c97483239e64477adab4ad047c094401ea008591))
* Fix Rubocop Style/MultilineBlockChain offense ([dd4e4ec](https://github.com/ruby-git/ruby-git/commit/dd4e4ecf0932ab02fa58ebe7a4189b44828729f5))
* Fix Rubocop Style/OptionalBooleanParameter offense ([c010a86](https://github.com/ruby-git/ruby-git/commit/c010a86cfc265054dc02ab4b7d778e4ba7e5426c))
* Fix typo in status.rb ([284fae7](https://github.com/ruby-git/ruby-git/commit/284fae7d3606724325ec21b0da7794d9eae2f0bd))
* Remove duplicate methods found by rubocop ([bd691c5](https://github.com/ruby-git/ruby-git/commit/bd691c58e3312662f07f8f96a1b48a7533f9a2e1))
* Result of running rake rubocop:autocorrect ([8f1e3bb](https://github.com/ruby-git/ruby-git/commit/8f1e3bb25fb4567093e9b49af42847a918d7d0c4))
* Result of running rake rubocop:autocorrect_all ([5c75783](https://github.com/ruby-git/ruby-git/commit/5c75783c0f50fb48d59012176cef7e985f7f83e2))


### Other Changes

* Add rubocop todo file to silence known offenses until they can be fixed ([2c36f8c](https://github.com/ruby-git/ruby-git/commit/2c36f8c9eb8ff14defe8f6fff1b6eb81d277f620))
* Avoid deprecated dsa for tests keys ([1da8c28](https://github.com/ruby-git/ruby-git/commit/1da8c2894b727757a909d015fb5a4bcd00133f59))
* Fix yarddoc error caused by rubocop autocorrect ([58c4af3](https://github.com/ruby-git/ruby-git/commit/58c4af3513df3c854e49380adfe5685023275684))
* Integrate Rubocop with the project ([a04297d](https://github.com/ruby-git/ruby-git/commit/a04297d8d6568691b71402d9dbba36c45427ebc3))
* Rename Gem::Specification variable from s to spec ([4d976c4](https://github.com/ruby-git/ruby-git/commit/4d976c443c3a3cf25cc2fec7caa213ae7f090853))

## [4.0.0](https://github.com/ruby-git/ruby-git/compare/v3.1.1...v4.0.0) (2025-07-02)


### ⚠ BREAKING CHANGES

* Users will need to be on Ruby 3.2 or greater

### Features

* Add Log#execute to run the log and return an immutable result ([ded54c4](https://github.com/ruby-git/ruby-git/commit/ded54c4b551aefb7de35b9505ce14f2061d1708c))
* **diff:** Refactor Git::Diff to separate concerns and improve AP ([e22eb10](https://github.com/ruby-git/ruby-git/commit/e22eb10bf2e4049f1a0fb325341ef7489f25e66e))
* Upgrade minimally supported Ruby to 3.2 ([fb93ef1](https://github.com/ruby-git/ruby-git/commit/fb93ef14def222d6eca29f49a5f810a3d6de5787))


### Other Changes

* Remove unneeded explicit return statements ([28e07ae](https://github.com/ruby-git/ruby-git/commit/28e07ae2e91a8defd52549393bf6f3fcbede122e))
* Upgrade to ProcessExecuter 4.x ([5b00d3b](https://github.com/ruby-git/ruby-git/commit/5b00d3b9c4063c9988d844eec9ddedddb8c26446))

## [3.1.1](https://github.com/ruby-git/ruby-git/compare/v3.1.0...v3.1.1) (2025-07-02)


### Bug Fixes

* Raise a Git::FailedError if depth &lt; 0 is passed to Git.clone ([803253e](https://github.com/ruby-git/ruby-git/commit/803253ea2dd2b69b099c0d1919b03ac65c800264)), closes [#805](https://github.com/ruby-git/ruby-git/issues/805)


### Other Changes

* Announce default branch change in README ([e04f08e](https://github.com/ruby-git/ruby-git/commit/e04f08e202ae54286033b4d0a75c47f124bd63e2))
* Update the project's default branch from 'master' to 'main' ([a5aa75f](https://github.com/ruby-git/ruby-git/commit/a5aa75fd04a71cd8236b8c8481a067c0a47b24b9))

## [3.1.0](https://github.com/ruby-git/ruby-git/compare/v3.0.2...v3.1.0) (2025-05-18)


### Features

* Make Git::Log support the git log --merges option ([df3b07d](https://github.com/ruby-git/ruby-git/commit/df3b07d0f14d79c6c77edc04550c1ad0207c920a))


### Other Changes

* Announce and document guidelines for using Conventional Commits ([a832259](https://github.com/ruby-git/ruby-git/commit/a832259314aa9c8bdd7719e50d425917df1df831))
* Skip continuous integration workflow for release PRs ([f647a18](https://github.com/ruby-git/ruby-git/commit/f647a18c8a3ae78f49c8cd485db4660aa10a92fc))
* Skip the experiemental build workflow if a release commit is pushed to master ([3dab0b3](https://github.com/ruby-git/ruby-git/commit/3dab0b34e41393a43437c53a53b96895fd3d2cc5))

## [3.0.2](https://github.com/ruby-git/ruby-git/compare/v3.0.1...v3.0.2) (2025-05-15)


### Bug Fixes

* Trigger the release workflow on a change to 'master' insetad of 'main' ([c8611f1](https://github.com/ruby-git/ruby-git/commit/c8611f1e68e73825fd16bd475752a40b0088d4ae))


### Other Changes

* Automate continuous delivery workflow ([06480e6](https://github.com/ruby-git/ruby-git/commit/06480e65e2441348230ef10e05cc1c563d0e7ea8))
* Enforce conventional commit messages with a GitHub action ([1da4c44](https://github.com/ruby-git/ruby-git/commit/1da4c44620a3264d4e837befd3f40416c5d8f1d8))
* Enforce conventional commit messages with husky and commitlint ([7ebe0f8](https://github.com/ruby-git/ruby-git/commit/7ebe0f8626ecb2f0da023b903b82f7332d8afaf6))

## v3.0.1 (2025-05-14)

[Full Changelog](https://github.com/ruby-git/ruby-git/compare/v3.0.0..v3.0.1)

Changes since v3.0.0:

* b47eedc Improved error message of rev_parse
* 9d44146 chore: update the development dependency on the minitar gem
* f407b92 feat: set the locale to en_US.UTF-8 for git commands
* b060e47 test: verify that command line envionment variables are set as expected
* 1a5092a chore: release v3.0.0

## v3.0.0 (2025-02-27)

[Full Changelog](https://github.com/ruby-git/ruby-git/compare/v2.3.3..v3.0.0)

Changes since v2.3.3:

* 534fcf5 chore: use ProcessExecuter.run instead of the implementing it in this gem
* 629f3b6 feat: update dependenices
* 501d135 feat: add support for Ruby 3.4 and drop support for Ruby 3.0
* 38c0eb5 build: update the CI build to use current versions to TruffleRuby and JRuby
* d3f3a9d chore: add frozen_string_literal: true magic comment

## v2.3.3 (2024-12-04)

[Full Changelog](https://github.com/ruby-git/ruby-git/compare/v2.3.2..v2.3.3)

Changes since v2.3.2:

* c25e5e0 test: add tests for spaces in the git binary path or the working dir
* 5f43a1a fix: open3 errors on binary paths with spaces
* 60b58ba test: add #run_command for tests to use instead of backticks

## v2.3.2 (2024-11-19)

[Full Changelog](https://github.com/ruby-git/ruby-git/compare/v2.3.1..v2.3.2)

Changes since v2.3.1:

* 7646e38 fix: improve error message for Git::Lib#branches_all

## v2.3.1 (2024-10-23)

[Full Changelog](https://github.com/ruby-git/ruby-git/compare/v2.3.0..v2.3.1)

Changes since v2.3.0:

* e236007 test: allow bin/test-in-docker to accept the test file(s) to run on command line
* f4747e1 test: rename bin/tests to bin/test-in-docker
* 51f781c test: remove duplicate test from test_stashes.rb
* 2e79dbe Fixed "unbranched" stash message support:
* da6fa6e Conatinerised the test suite with Docker:
* 2e23d47 Update instructions for building a specific version of Git
* 70565e3 Add Git.binary_version to return the version of the git command line

## v2.3.0 (2024-09-01)

[Full Changelog](https://github.com/ruby-git/ruby-git/compare/v2.2.0..v2.3.0)

Changes since v2.2.0:

* f8bc987 Fix windows CI build error
* 471f5a8 Sanatize object ref sent to cat-file command
* 604a9a2 Make Git::Base#branch work when HEAD is detached

## v2.2.0 (2024-08-26)

[Full Changelog](https://github.com/ruby-git/ruby-git/compare/v2.1.1..v2.2.0)

Changes since v2.1.1:

* 7292f2c Omit the test for signed commit data on Windows
* 2d6157c Document this gem's (aspirational) design philosophy
* d4f66ab Sanitize non-option arguments passed to `git name-rev`
* 0296442 Refactor Git::Lib#rev_parse
* 9b9b31e Verify that the revision-range passed to git log does not resemble a command-line option
* dc46ede Verify that the commit-ish passed to git describe does not resemble a command-line option
* 00c4939 Verify that the commit(s) passed to git diff do not resemble a command-line option
* a08f89b Update README
* 737c4bb ls-tree optional recursion into subtrees

## v2.1.1 (2024-06-01)

[Full Changelog](https://github.com/ruby-git/ruby-git/compare/v2.1.0..v2.1.1)

Changes since v2.1.0:

* 6ce3d4d Handle ignored files with quoted (non-ASCII) filenames
* dd8e8d4 Supply all of the _specific_ color options too
* 749a72d Memoize all of the significant calls in Git::Status
* 2bacccc When core.ignoreCase, check for untracked files case-insensitively
* 7758ee4 When core.ignoreCase, check for deleted files case-insensitively
* 993eb78 When core.ignoreCase, check for added files case-insensitively
* d943bf4 When core.ignoreCase, check for changed files case-insensitively

## v2.1.0 (2024-05-31)

[Full Changelog](https://github.com/ruby-git/ruby-git/compare/v2.0.1..v2.1.0)

Changes since v2.0.1:

* 93c8210 Add Git::Log#max_count
* d84097b Update YARDoc for a few a few method

## v2.0.1 (2024-05-21)

[Full Changelog](https://github.com/ruby-git/ruby-git/compare/v2.0.0..v2.0.1)

Changes since v2.0.0:

* da435b1 Document and add tests for Git::Status
* c8a77db Fix Git::Base#status on an empty repo
* 712fdad Fix Git::Status#untracked when run from worktree subdir
* 6a59bc8 Remove the Git::Base::Factory module

## v2.0.0 (2024-05-10)

[Full Changelog](https://github.com/ruby-git/ruby-git/compare/v2.0.0.pre4..v2.0.0)

Changes since v2.0.0.pre4:

* 1afc4c6 Update 2.x release line description
* ed52420 Make the pull request template more concise
* 299ae6b Remove stale bot integration
* efb724b Remove the DCO requirement for commits

## v2.0.0.pre4 (2024-05-10)

[Full Changelog](https://jcouball@github.com/ruby-git/ruby-git/compare/v2.0.0.pre3..v2.0.0.pre4)

Changes since v2.0.0.pre3:

* 56783e7 Update create_github_release dependency so pre-releases can be made
* 8566929 Add dependency on create_github_release gem used for releasing the git gem
* 7376d76 Refactor errors that are raised by this gem
* 7e99b17 Update documentation for new timeout functionality
* 705e983 Move experimental builds to a separate workflow that only runs when pushed to master
* e056d64 Build with jruby-head on Windows until jruby/jruby#7515 is fixed
* ec7c257 Remove unneeded scripts to create a new release
* d9570ab Move issue and pull request templates to the .github directory
* e4d6a77 Show log(x).since combination in README

## v2.0.0.pre3 (2024-03-15)

[Full Changelog](https://github.com/ruby-git/ruby-git/compare/v2.0.0.pre2..v2.0.0.pre3)

Changes since v2.0.0.pre2:

* 5d4b34e Allow allow_unrelated_histories option for Base#pull

## v2.0.0.pre2 (2024-02-24)

[Full Changelog](https://github.com/ruby-git/ruby-git/compare/v2.0.0.pre1..v2.0.0.pre2)

Changes since v2.0.0.pre1:

* 023017b Add a timeout for git commands (#692)
* 8286ceb Refactor the Error heriarchy (#693)

## v2.0.0.pre1 (2024-01-15)

[Full Changelog](https://github.com/ruby-git/ruby-git/compare/v1.19.1..v2.0.0.pre1)

Changes since v1.19.1:

* 7585c39 Change how the git CLI subprocess is executed (#684)
* f93e042 Update instructions for releasing a new version of the git gem (#686)
* f48930d Update minimum required version of Ruby and Git (#685)

## v1.19.1 (2024-01-13)

[Full Changelog](https://github.com/ruby-git/ruby-git/compare/v1.19.0..v1.19.1)

Changes since v1.19.0:

* f97c57c Announce the 2.0.0 pre-release (#682)

## v1.19.0 (2023-12-28)

[Full Changelog](https://github.com/ruby-git/ruby-git/compare/v1.18.0..v1.19.0)

Changes since v1.18.0:

* 3bdb280 Add option to push all branches to a remote repo at one time (#678)
* b0d89ac Remove calls to Dir.chdir (#673)
* e64c2f6 Refactor tests for read_tree, write_tree, and commit_tree (#679)
* 0bb965d Explicitly name remote tracking branch in test (#676)
* 8481f8c Document how to delete a remote branch (#672)
* dce6816 show .log example with count in README, fixes #667 (#668)
* b1799f6 Update test of 'git worktree add' with no commits (#670)
* dd5a24d Add --filter to Git.clone for partial clones (#663)

## v1.18.0 (2023-03-19)

[Full Changelog](https://github.com/ruby-git/ruby-git/compare/v1.17.2..v1.18.0)

Changes since v1.17.2:

* 3c70 Add support for `--update-head-ok` to `fetch` (#660)
* b53d Do not generate yard documentation when building in TruffleRuby (#659)
* 5af1 Correctly report command output when there is an error (#658)
* b27a Add test to ensure that `Git.open` works to open a submodule (#655)
* 5b0e Update Git.clone to set multiple config variables (#653)

## v1.17.2 (2023-03-07)

[Full Changelog](https://github.com/ruby-git/ruby-git/compare/v1.17.1..v1.17.2)

Changes since v1.17.1:

* f43d6 Fix branch name parsing to handle names that include slashes (#651)

## v1.17.1 (2023-03-06)

[Full Changelog](https://github.com/ruby-git/ruby-git/compare/v1.17.0..v1.17.1)

Changes since v1.17.0:

* 774e Revert introduction of ActiveSupport dependency (#649)

## v1.17.0 (2023-03-05)

[Full Changelog](https://github.com/ruby-git/ruby-git/compare/v1.16.0..v1.17.0)

Changes since v1.16.0:

* 1311 Add deprecation mechanism (introduces runtime dependency on ActiveSupport) (#645)
* 50b8 Add the push_option option for Git::Lib#push (#644)
* a799 Make Git::Base#ls_tree handle commit objects (#643)
* 6db3 Implememt Git.default_branch (#571)

## v1.16.0 (2023-03-03)

[Full Changelog](https://github.com/ruby-git/ruby-git/compare/v1.15.0..v1.16.0)

Changes since v1.15.0:

* 536d Fix parsing when in detached HEAD state in Git::Lib#branches_all (#641)
* 5c68 Fix parsing of symbolic refs in `Git::Lib#branches_all` (#640)
* 7d88 Remote#branch and #merge should default to current branch instead of "master" (#639)
* 3dda0 `#branch` name should default to current branch instead of `master` (#638)
* d33d #checkout without args should do same as `git checkout` with no args (#637)
* 0c90 #push without args should do same as `git push` with no args (#636)
* 2b19 Make it easier to run test files from the command line (#635)

## v1.15.0 (2023-03-01)

[Full Changelog](https://github.com/ruby-git/ruby-git/compare/v1.14.0..v1.15.0)

Changes since v1.14.0:

* b40d #pull with no options should do the same thing as `git pull` with no options (#633)
* 9c5e Fix error when calling `Git::Lib#remove` with `recursive` or `cached` options (#632)
* 806e Add Git::Log#all option (#630)
* d905 Allow a repo to be opened giving a non-root repo directory (#629)
* 1ccd Rewrite worktree tests (#628)
* 4409 Fix Git::Branch#update_ref (#626)

## v1.14.0 (2023-02-25)

[Full Changelog](https://github.com/ruby-git/ruby-git/compare/v1.13.2..v1.14.0)

Changes since v1.13.2:

* 0f7c4a5 Allow the use of an array of path_limiters and add extended_regexp option to grep (#624)
* 8992701 Refactor error thrown when a git command fails (#622)
* cf74b91 Simplify how temp files are used when testing Git::Base#archive (#621)
* a8bfb9d Set init.defaultBranch when running tests if it is not already set (#620)
* 9ee7ca9 Create a null logger if a logger is not provided (#619)
* 872de4c Internal refactor of Git::Lib command (#618)
* 29e157d Simplify test running and fixture repo cloning (#615)
* 08d04ef Use dynamically-created repo for signed commits test (#614)

## v1.13.2 (2023-02-02)

[Full Changelog](https://github.com/ruby-git/ruby-git/compare/v1.13.1..v1.13.2)

Changes since v1.13.1:

* b6e031d Fix `Git::Lib#commit_data` for GPG-signed commits (#610)
* b12b820 Fix escaped path decoding (#612)

## v1.13.1 (2023-01-12)

[Full Changelog](https://github.com/ruby-git/ruby-git/compare/v1.13.0...v1.13.1)

* 667b830 Update the GitHub Action step "actions/checkout" from v2 to v3 (#608)
* 23a0ac4 Fix version parsing (#605)
* 429f0bb Update release instructions (#606)
* 68d76b8 Drop ruby 2.3 build and add 3.1 and 3.2 builds (#607)

## v1.13.0 (2022-12-10)

[Full Changelog](https://github.com/ruby-git/ruby-git/compare/v1.12.0...v1.13.0)

* 8349224 Update list of maintainers (#598)
* 4fe8738 In ls-files do not unescape file paths with eval (#602)
* 74b8e11 Add start_point option for checkout command (#597)
* ff6dcf4 Do not assume the default branch is 'master' in tests
* 8279298 Fix exception when Git is autoloaded (#594)

## v1.12.0

See https://github.com/ruby-git/ruby-git/releases/tag/v1.12.0

## v1.11.0

* 292087e Supress unneeded test output (#570)
* 19dfe5e Add support for fetch options "--force/-f" and "--prune-tags/-P". (#563)
* 018d919 Fix bug when grepping lines that contain numbers surrounded by colons (#566)
* c04d16e remove from maintainer (#567)
* 291ca09 Address command line injection in Git::Lib#fetch
* 521b8e7 Release v1.10.2 (#561)

See https://github.com/ruby-git/ruby-git/releases/tag/v1.11.0

## v1.10.2

See https://github.com/ruby-git/ruby-git/releases/tag/v1.10.2

## 1.10.1

See https://github.com/ruby-git/ruby-git/releases/tag/v1.10.1

## 1.10.0

See https://github.com/ruby-git/ruby-git/releases/tag/v1.10.0

## 1.9.1

See https://github.com/ruby-git/ruby-git/releases/tag/v1.9.1

## 1.9.0

See https://github.com/ruby-git/ruby-git/releases/tag/v1.9.0

## 1.8.1

See https://github.com/ruby-git/ruby-git/releases/tag/v1.8.1

## 1.8.0

See https://github.com/ruby-git/ruby-git/releases/tag/v1.8.0

## 1.7.0

See https://github.com/ruby-git/ruby-git/releases/tag/v1.7.0

## 1.6.0

See https://github.com/ruby-git/ruby-git/releases/tag/v1.6.0

## 1.6.0.pre1

See https://github.com/ruby-git/ruby-git/releases/tag/v1.6.0.pre1

## 1.5.0

See https://github.com/ruby-git/ruby-git/releases/tag/v1.5.0

## 1.4.0

See https://github.com/ruby-git/ruby-git/releases/tag/v1.4.0

## 1.3.0

 * Dropping Ruby 1.8.x support

## 1.2.10

 * Adding Git::Diff.name_status
 * Checking and fixing encoding on commands output to prevent encoding errors afterwards

## 1.2.9

* Adding Git.configure (to configure the git env)
* Adding Git.ls_remote [Git.ls_remote(repo_path_or_url='.')]
* Adding Git.describe [repo.describe(objectish, opts)]
* Adding Git.show [repo.show(objectish=nil, path=nil)]
* Fixing Git::Diff to support default references (implicit references)
* Fixing Git::Diff to support diff over git .patch files
* Fixing Git.checkout when using :new_branch opt
* Fixing Git::Object::Commit to preserve its sha after fetching metadata
* Fixing Git.is_remote_branch? to actually check against remote branches
* Improvements over how ENV variables are modified
* Improving thrade safety (using --git-dir and --work-tree git opts)
* Improving Git::Object::Tag. Adding annotated?, tagger and message
* Supporting a submodule path as a valid repo
* Git.checkout - supporting -f and -b
* Git.clone - supporting --branch
* Git.fetch - supporting --prune
* Git.tag - supporting

## 1.2.8

* Keeping the old escape format for windows users
* revparse: Supporting ref names containing SHA like substrings (40-hex strings)
* Fix warnings on Ruby 2.1.2

## 1.2.7

* Fixing mesages encoding
* Fixing -f flag in git push
* Fixing log parser for multiline messages
* Supporting object references on Git.add_tag
* Including dotfiles on Git.status
* Git.fetch - supporting --tags
* Git.clean - supporting -x
* Git.add_tag options - supporting -a, -m and -s
* Added Git.delete_tag

## 1.2.6

* Ruby 1.9.X/2.0 fully supported
* JRuby 1.8/1.9 support
* Rubinius support
* Git.clone - supporting --recursive and --config
* Git.log - supporting last and [] over the results
* Git.add_remote - supporting -f and -t
* Git.add - supporting --fore
* Git.init - supporting --bare
* Git.commit - supporting --all and --amend
* Added Git.remote_remote, Git.revert and Git.clean
* Added Bundler to the formula
* Travis configuration
* Licence included with the gem

## 1.0.4

* added camping/gitweb.rb frontend
* added a number of speed-ups

## 1.0.3

* Sped up most of the operations
* Added some predicate functions (commit?, tree?, etc)
* Added a number of lower level operations (read-tree, write-tree, checkout-index, etc)
* Fixed a bug with using bare repositories
* Updated a good amount of the documentation

## 1.0.2

* Added methods to the git objects that might be helpful

## 1.0.1

* Initial version
