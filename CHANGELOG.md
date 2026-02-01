<!--
# @markup markdown
# @title Change Log
-->

# Change Log

## [5.0.0](https://github.com/ruby-git/ruby-git/compare/v4.1.2...v5.0.0) (2026-02-01)


### ⚠ BREAKING CHANGES

* This is a breaking API change for users accessing `fsck_object.sha`. Use `fsck_object.oid` instead.
* force: true is now required to remove files with local modifications
* The .path accessor has been removed. Use .to_s instead:   - repo.dir.path → repo.dir.to_s   - repo.index.path → repo.index.to_s   - repo.repo.path → repo.repo.to_s

### Features

* Add Git::BranchInfo value object ([b9b6168](https://github.com/ruby-git/ruby-git/commit/b9b6168b832ef82589a538e5fa467982a8d594f8))
* Add Git::Commands::Branch::List command ([d1a0230](https://github.com/ruby-git/ruby-git/commit/d1a02307b069e4dace9ae52ea025c6713b251665))
* Add support for git fsck command ([96a0958](https://github.com/ruby-git/ruby-git/commit/96a09588f94ad270cae6e9e3c14fe39d8b141fa1)), closes [#218](https://github.com/ruby-git/ruby-git/issues/218)
* Introduce Git::ExecutionContext and Git::Repository classes ([6163fa3](https://github.com/ruby-git/ruby-git/commit/6163fa371e08b95bcb59774919c035a53ef8fab2))
* Migrate mv command to new architecture (Phase 2) ([ffce1c0](https://github.com/ruby-git/ruby-git/commit/ffce1c0e26560b07e0512ebaec0be9c76e7be2fe))


### Bug Fixes

* **commands:** Add required validation for variadic positionals ([f2e9380](https://github.com/ruby-git/ruby-git/commit/f2e9380a5c0a569a816d5118c5249af12dd2a23e))
* Disable interactive editor to prevent process hanging ([49e28bc](https://github.com/ruby-git/ruby-git/commit/49e28bc211ddffe1fc3750ff5d85bc21374c0faf)), closes [#953](https://github.com/ruby-git/ruby-git/issues/953)
* Render arguments in definition order instead of grouped by type ([cbdb482](https://github.com/ruby-git/ruby-git/commit/cbdb4822d9bb36719842439e19203d7705561a65))


### Other Changes

* Achieve 100% unit test coverage for all commands ([ffd123e](https://github.com/ruby-git/ruby-git/commit/ffd123e0f922b5cc0885d0de9dbf1d26861021fc))
* Add architectural insight about option semantics vs ergonomics ([e077820](https://github.com/ruby-git/ruby-git/commit/e07782026c9b8243562f0a11c29882ca58fbaa3b))
* Add architectural insights from branch delete migration ([a7e470b](https://github.com/ruby-git/ruby-git/commit/a7e470baca49e191ff66ed9f44f1f122e02dde31))
* Add architectural insights from branch move implementation ([68b762a](https://github.com/ruby-git/ruby-git/commit/68b762a8d2110e0a900adab9424a4b7d0865c0d5))
* Add architectural insights from checkout migration ([e4da8ce](https://github.com/ruby-git/ruby-git/commit/e4da8ce944f855cc59ceb886677f2a61aaaec929))
* Add branch copy command class for copying branches ([e329654](https://github.com/ruby-git/ruby-git/commit/e329654bb81439724c52ec5cd90d6594413113e3))
* Add comprehensive PR readiness prompt for AI agents ([01ed5c1](https://github.com/ruby-git/ruby-git/commit/01ed5c1adc777404ec61eda7dd8dff7e9cde5cf7))
* Add Diff commands with proper exit code handling ([89ad898](https://github.com/ruby-git/ruby-git/commit/89ad898d60621a805b176bc08ee6392596dea27b))
* Add multi_valued option to value and inline_value in Arguments DSL ([d12d795](https://github.com/ruby-git/ruby-git/commit/d12d7952d8c2067bc6c905c9355b4511208783f1))
* Add RSpec integration test infrastructure ([0c364a8](https://github.com/ruby-git/ruby-git/commit/0c364a8df24a7f9f194d424eb03d93b6f3981e52))
* Add RSpec tests for Git::Branch dual-mode initialization ([94d11bb](https://github.com/ruby-git/ruby-git/commit/94d11bb53efd2edefd23858d5758813a0c6f0558))
* Add tag-related classes to main git.rb requires ([d94741f](https://github.com/ruby-git/ruby-git/commit/d94741fda3a164e42a569e180c790d60e5d0dea5))
* Add test-verbose script for debugging test execution ([5b3041f](https://github.com/ruby-git/ruby-git/commit/5b3041fe782ec72b6c1ba7d25f61904b8ec7faf8))
* Address additional copilot review feedback ([5f79882](https://github.com/ruby-git/ruby-git/commit/5f798824460a8ba13b2a672a63ae840be4d81723))
* Address copilot review comments ([15cc7b0](https://github.com/ruby-git/ruby-git/commit/15cc7b081f9ae3c37b83fd737e0b6d87ae0e647d))
* **add:** Use Options DSL for argument building ([a8b3236](https://github.com/ruby-git/ruby-git/commit/a8b32369607e53b30f3cfed601be23de7c619960))
* **arguments:** Add allow_nil option for positional arguments ([c2280b2](https://github.com/ruby-git/ruby-git/commit/c2280b221ec6c5b987b7634ede5f5fc2f954b9ac))
* **arguments:** Add required and allow_nil parameters to DSL ([4ce91fb](https://github.com/ruby-git/ruby-git/commit/4ce91fb4b7c0038f55390992908d59bf1da3ce4e))
* **arguments:** Add value_to_positional option type ([f87f2f3](https://github.com/ruby-git/ruby-git/commit/f87f2f387da58485fa86ee7583c24c0dbf41a1b4))
* **arguments:** Support ruby-like positional allocation with optional + variadic ([5e02bbf](https://github.com/ruby-git/ruby-git/commit/5e02bbf5a6028dcd2f8592fc44ac58522884c072))
* **base:** Simplify path resolution and init flow ([3badcc7](https://github.com/ruby-git/ruby-git/commit/3badcc79505cffba55953c2a2047999fc9a27ba3))
* **branch:** Add move command class for branch renaming ([97625e6](https://github.com/ruby-git/ruby-git/commit/97625e65a689303cd3763f129aac196257a5455f))
* **branch:** Add target_oid and upstream attributes to BranchInfo ([4a0814a](https://github.com/ruby-git/ruby-git/commit/4a0814ac348c23141c703b0be4320b0887b0184f)), closes [#962](https://github.com/ruby-git/ruby-git/issues/962)
* Capture learnings from implementing stash commands ([84abd3b](https://github.com/ruby-git/ruby-git/commit/84abd3b12994cdcc14b5ebb31d72a4ed44599831))
* Clarify integration test guidance in implementation plan ([21fcfbd](https://github.com/ruby-git/ruby-git/commit/21fcfbd7a631bbda541b5fe9187aaa6513e3f75d))
* **clone:** Use Options DSL for argument building ([2e4047d](https://github.com/ruby-git/ruby-git/commit/2e4047da960a8c1a48420215d2ef32bd14a0c579))
* **commands:** Add Git::Commands::Options DSL ([21401e0](https://github.com/ruby-git/ruby-git/commit/21401e0c0f5d52fa90d6387767ecd776a9fd270f))
* **commands:** Fix command classes and standardize signatures ([e26e562](https://github.com/ruby-git/ruby-git/commit/e26e562ab43c9a49d52ffd1b466b96a7e7bc9833))
* **commands:** Standardize Yardoc for #call methods ([31a3f20](https://github.com/ruby-git/ruby-git/commit/31a3f208e69e0e77ea5038dfefa4b4649fcd85cd))
* Configure prerelease releases ([94064ae](https://github.com/ruby-git/ruby-git/commit/94064ae4a90ab7448203bb59c0a4545efd8bb72e))
* Document architectural insights from Branch::List migration ([52f322c](https://github.com/ruby-git/ruby-git/commit/52f322cb01b9e27df305e3dd8b4efbd8324cf1f4))
* Enable option validation in Add and Fsck commands ([37aa0d5](https://github.com/ruby-git/ruby-git/commit/37aa0d5b4f513f30ff7a7d6fecff8c78a7a5a915))
* Enhance Arguments DSL with new features ([88e6d5d](https://github.com/ruby-git/ruby-git/commit/88e6d5df2c1867ce2484de8f4c7a61ff3b2c77d9))
* Establish method signature convention for Git::Commands::* #call ([d1e103c](https://github.com/ruby-git/ruby-git/commit/d1e103cb35a27abe8d18e7f8c67257595af52eec))
* Exclude spec/**/* from Metrics/BlockLength ([1cc1001](https://github.com/ruby-git/ruby-git/commit/1cc10012a3a0c59db046aa5c9d7b5b3c86bbdb8f))
* Extract branch creation to Git::Commands::Branch::Create ([6252090](https://github.com/ruby-git/ruby-git/commit/62520904a39bcec9490bbf51bec991d351812a12))
* Extract branch delete to Git::Commands::Branch::Delete ([90bb682](https://github.com/ruby-git/ruby-git/commit/90bb68271ac93329f85fb5f5ecfef839421f088f))
* Extract git add to Git::Commands::Add ([baf2a76](https://github.com/ruby-git/ruby-git/commit/baf2a761e3e165be59c185f665c02424dc05cd9e))
* Extract git fsck to Git::Commands::Fsck ([ad28871](https://github.com/ruby-git/ruby-git/commit/ad2887103ff99ac17faa907ba5fa730da9e71f1e))
* Finalize architectural redesign documentation for PR ([40255b3](https://github.com/ruby-git/ruby-git/commit/40255b3f5e7f27b86543cf11d692cdfcfc74a16f))
* Fix RSpec deprecation warning and suppress git command output ([ab34fef](https://github.com/ruby-git/ruby-git/commit/ab34fef89c8e4f94ee06a1f37c7b6195bae9a213))
* Fix tagger_date regex to handle both timezone offset and Z format ([5d4686b](https://github.com/ruby-git/ruby-git/commit/5d4686b6395b933d4184a783b57dab682037c1dd))
* **fsck:** Use Options DSL for argument building ([7464439](https://github.com/ruby-git/ruby-git/commit/7464439b8915640563e1c4d609f206856ed9bc73))
* Implement Branch::SetUpstream and Branch::UnsetUpstream commands ([bf1f634](https://github.com/ruby-git/ruby-git/commit/bf1f634f6fd19cc05d8ffcfcee5ad641aa32c783))
* Implement Ruby-style positional argument mapping in Arguments DSL ([895f9f2](https://github.com/ruby-git/ruby-git/commit/895f9f2b2621ebaf2252bcdba8c8098f0dbe9b69))
* Implement tag delete command with structured result objects ([5908a0e](https://github.com/ruby-git/ruby-git/commit/5908a0ef25a837482f45826e3128f52e885fd799))
* Make Git::Lib#command public for Command classes ([e946d04](https://github.com/ruby-git/ruby-git/commit/e946d043e4fcab192e4d7761db9fa836dae51366))
* Mark checkout command as migrated and update next task ([a1b354f](https://github.com/ruby-git/ruby-git/commit/a1b354fad5f87029280dcd819efc97b6008075e9))
* Mark main releases as prerelease ([1dca79a](https://github.com/ruby-git/ruby-git/commit/1dca79a8cb4827e4954f04d2918ccfb8a1737dba))
* Merge Exclude arrays with inherited rubocop config ([0d7b582](https://github.com/ruby-git/ruby-git/commit/0d7b58260c571f8371b133f0b36fcb6a84c4e618))
* Migrate checkout to Commands architecture ([89b79ed](https://github.com/ruby-git/ruby-git/commit/89b79ed6f827f90987ff8cd7709edcbcdf6ca1df))
* Migrate clean command to Git::Commands::Clean ([87e6bcb](https://github.com/ruby-git/ruby-git/commit/87e6bcbe17aabac4173fc512857e2fb7b1f8c191))
* Migrate commit command to Git::Commands::Commit ([03cb887](https://github.com/ruby-git/ruby-git/commit/03cb887e8dd52e82e0860485d732011e595d7da1))
* Migrate git clone to Git::Commands::Clone ([a16d14a](https://github.com/ruby-git/ruby-git/commit/a16d14afc5bc1447ecd9c56cb39ecf85c206c87c))
* Migrate git stash commands to new architecture ([cd83218](https://github.com/ruby-git/ruby-git/commit/cd83218a64313f581b93a8ff103f0a252d4e9fed))
* Migrate git tag commands to new architecture ([717fca2](https://github.com/ruby-git/ruby-git/commit/717fca25d48663fc620ec71aa4a3b4b27fb1bb13))
* Migrate init command to new architecture ([482e5f0](https://github.com/ruby-git/ruby-git/commit/482e5f0d7e4b2b1aaab2dc359a781fc283342731))
* Migrate merge commands to Commands layer ([e6e3866](https://github.com/ruby-git/ruby-git/commit/e6e386636bf6e0c69115e15fa0ee5368de80d403))
* Migrate remaining stash commands to Git::Commands ([666ab61](https://github.com/ruby-git/ruby-git/commit/666ab61ececcad755d37977756109b02d0002317))
* Migrate reset command to Git::Commands::Reset ([6e3cca7](https://github.com/ruby-git/ruby-git/commit/6e3cca72536c57f8aea06ff91f04c451ea86a4f8))
* Migrate rm command to Git::Commands::Rm ([61d8940](https://github.com/ruby-git/ruby-git/commit/61d894047c1e7a899791cd9224ae118395d82ec2))
* Move static command names into Arguments.define ([175fe0e](https://github.com/ruby-git/ruby-git/commit/175fe0eeaaf6d16bf6d29c775680be71b0a919bd)), closes [#949](https://github.com/ruby-git/ruby-git/issues/949)
* **options:** Add nil validation for variadic positional arguments ([5b793da](https://github.com/ruby-git/ruby-git/commit/5b793da11a24408701e6b8e5fd69524484f00977))
* Populate TagInfo with rich metadata using git tag --format ([c8c455d](https://github.com/ruby-git/ruby-git/commit/c8c455dd3255a62e1012aec23fd8edc573592688)), closes [#955](https://github.com/ruby-git/ruby-git/issues/955)
* Rename FsckObject sha to oid ([c84d317](https://github.com/ruby-git/ruby-git/commit/c84d3175b2000c7566bc022cc85cacb09d0a8aa5)), closes [#967](https://github.com/ruby-git/ruby-git/issues/967)
* Rename Options to Arguments and OPTIONS to ARGS ([b76c9c3](https://github.com/ruby-git/ruby-git/commit/b76c9c388d43fe26d7a7be0c4eaeaeafea0a6abb))
* Rename StashInfo sha/short_sha to oid/short_oid ([789cb41](https://github.com/ruby-git/ruby-git/commit/789cb41c5025ada7d8cd751038210ca5b34442e3)), closes [#966](https://github.com/ruby-git/ruby-git/issues/966)
* Rename TagInfo sha to oid and add target_oid ([39ca36b](https://github.com/ruby-git/ruby-git/commit/39ca36bd813fe60573dabb85bb7a9000843c1f44)), closes [#963](https://github.com/ruby-git/ruby-git/issues/963)
* Replace path wrapper classes with Pathname ([c7b7b1f](https://github.com/ruby-git/ruby-git/commit/c7b7b1f1e782533140ba22b831385097da2e3d09))
* Restructure CONTRIBUTING.md and link from copilot-instructions ([7e3481b](https://github.com/ruby-git/ruby-git/commit/7e3481b42b306ec00111cc91d6bd8ab282766ee8))
* Return BranchInfo from Branch::Create command ([a23f384](https://github.com/ruby-git/ruby-git/commit/a23f384602861abc1ad7263405ade42039a969f2))
* Return TagInfo from Tag::Create command ([2dde55c](https://github.com/ruby-git/ruby-git/commit/2dde55cfb8f45fcc8043b5058ddeb0938511eab5))
* Set up RSpec testing environment ([452929a](https://github.com/ruby-git/ruby-git/commit/452929aa63d2fb022a107e441417e777de5c038f))
* Silence superfluous test output ([1da9f66](https://github.com/ruby-git/ruby-git/commit/1da9f669409b9dfbfd248edac66d9e71aa9b0a47))
* Split Merge::Resolve into separate Abort, Continue, and Quit commands ([1ac31f6](https://github.com/ruby-git/ruby-git/commit/1ac31f65ed1d746bd042f8c14f6ca0db14fb2bab))
* Unify command execution with raise_on_failure and env options ([a2fc5de](https://github.com/ruby-git/ruby-git/commit/a2fc5de2c9a44d630195be729467a8c68774dd34))
* Update architecture documentation for redesign phases and public API ([8544cc7](https://github.com/ruby-git/ruby-git/commit/8544cc7209d41428b5a52733b3a3b3324739c5af))
* Update architecture implementation plan with branch create insights ([1736617](https://github.com/ruby-git/ruby-git/commit/1736617aa8cfd76d7df5a3131324bc39b1763c5a))
* Update architecture implementation tracker ([dce1883](https://github.com/ruby-git/ruby-git/commit/dce1883dae3883168fe1863f59a8493f8d5498fb))
* Update branch consumers to use BranchInfo ([dffc94a](https://github.com/ruby-git/ruby-git/commit/dffc94ab0a051541a2c2c489844f2dc4362e7167))
* Update Git::Commands::* to use keyword arguments ([ece055d](https://github.com/ruby-git/ruby-git/commit/ece055dfb0aa9aadc1ac3a99de1315c11f470574))
* Use Branch::List command in Git::Lib#branches_all ([d872f17](https://github.com/ruby-git/ruby-git/commit/d872f17332f0f872926e7ba3a27608cb4705986b))

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
