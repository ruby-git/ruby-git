<!--
# @markup markdown
# @title Change Log
-->

# Change Log

## [5.0.0](https://github.com/ruby-git/ruby-git/compare/v4.1.2...v5.0.0) (2026-05-07)


### ⚠ BREAKING CHANGES

* **arguments:** flag_option :foo, negatable: true no longer accepts false to emit --no-foo. Before: bind(foo: false) => ["--no-foo"]. After: register two entries; bind(no_foo: true) => ["--no-foo"]. Callers passing foo: false expecting --no-foo will silently get nothing emitted.
* This is a breaking API change for users accessing `fsck_object.sha`. Use `fsck_object.oid` instead.
* force: true is now required to remove files with local modifications
* The .path accessor has been removed. Use .to_s instead:   - repo.dir.path → repo.dir.to_s   - repo.index.path → repo.index.to_s   - repo.repo.path → repo.repo.to_s

### Features

* Add Git::BranchInfo value object ([b9b6168](https://github.com/ruby-git/ruby-git/commit/b9b6168b832ef82589a538e5fa467982a8d594f8))
* Add Git::Commands::Branch::List command ([d1a0230](https://github.com/ruby-git/ruby-git/commit/d1a02307b069e4dace9ae52ea025c6713b251665))
* Add Git::Commands::SymbolicRef command classes ([2703238](https://github.com/ruby-git/ruby-git/commit/27032387e9f9fec0b4304a8c56d5109dd70bd731))
* Add Git::MINIMUM_GIT_VERSION constant ([d5c8604](https://github.com/ruby-git/ruby-git/commit/d5c860419858ed8e9c6f9a4bdd198224d22eed63))
* Add Git::RepositoryContext and Git::GlobalContext (Phase 3 Task 1) ([e2b94ca](https://github.com/ruby-git/ruby-git/commit/e2b94caa42adaface90fbc41c853e0a963a59740))
* Add Git::Version class for git binary versions ([d97b5e3](https://github.com/ruby-git/ruby-git/commit/d97b5e335d694e8b3f948d6bebe8ee3916076373))
* Add Git::VersionConstraint value object ([28599f0](https://github.com/ruby-git/ruby-git/commit/28599f0cd08583453112ef528f9b08892cc6430d))
* Add Git::VersionError exception class ([8ed8713](https://github.com/ruby-git/ruby-git/commit/8ed871322aed2b7802a26dc652a68d9047b8a7c1))
* Add rspec-unit-testing-standards skill ([e914770](https://github.com/ruby-git/ruby-git/commit/e9147709221343996e63669dc36284b89a9298b9))
* Add streaming execution entry points (CommandLine#run, Lib#command) ([9cac2a2](https://github.com/ruby-git/ruby-git/commit/9cac2a2e87d848a3b8cb31656921ead1bc5b6d07)), closes [#1097](https://github.com/ruby-git/ruby-git/issues/1097)
* Add support for git fsck command ([96a0958](https://github.com/ruby-git/ruby-git/commit/96a09588f94ad270cae6e9e3c14fe39d8b141fa1)), closes [#218](https://github.com/ruby-git/ruby-git/issues/218)
* **api:** Add Git.git_version method ([7ae54f3](https://github.com/ruby-git/ruby-git/commit/7ae54f34454af1472192d20fdd64971f989e0557)), closes [#1249](https://github.com/ruby-git/ruby-git/issues/1249)
* **arguments:** Replace negatable tri-state with no_{flag} companion key ([#1260](https://github.com/ruby-git/ruby-git/issues/1260)) ([e305922](https://github.com/ruby-git/ruby-git/commit/e305922aebd6b34b6c50be150ee56d18f558f617))
* **branching:** Add local_branch?, remote_branch?, branch? facade methods ([14dd2b3](https://github.com/ruby-git/ruby-git/commit/14dd2b36466f3dd97ae52e5981fc3d50c1d22ea9))
* **commands:** Add Git::Commands::Maintenance subcommand classes ([5404c5a](https://github.com/ruby-git/ruby-git/commit/5404c5aa5b02f89451b83619ec710f3fc8cd8cff))
* **commands:** Add requires_git_version macro and validation ([3c1f1ec](https://github.com/ruby-git/ruby-git/commit/3c1f1ec053a75705e39065b127ee4e39aaf804c0))
* **commands:** Add validate_version! to custom #call implementations ([9deec1f](https://github.com/ruby-git/ruby-git/commit/9deec1f2ee0fda6328ab6acc15602c72e56b5c54))
* **execution-context:** Add binary_path: keyword and retire Open3 stopgap ([bf94218](https://github.com/ruby-git/ruby-git/commit/bf94218b488ef8e599c13c596f30faa39ae62a56))
* **execution-context:** Forward binary_path from Git::Base via from_base ([8e9af8f](https://github.com/ruby-git/ruby-git/commit/8e9af8f422b53d6142ab15625473075f862066af))
* **git-cat-file:** Add CatFile::ObjectMeta and CatFile::ObjectContent commands ([4ea773d](https://github.com/ruby-git/ruby-git/commit/4ea773debeac6dad22c85aa8997de98dbc4046de))
* Introduce Git::ExecutionContext and Git::Repository classes ([6163fa3](https://github.com/ruby-git/ruby-git/commit/6163fa371e08b95bcb59774919c035a53ef8fab2))
* **lib:** Add git_version method returning Git::Version ([a473978](https://github.com/ruby-git/ruby-git/commit/a47397825769f7181fb63bfaff09c4eb494c4149))
* Migrate mv command to new architecture (Phase 2) ([ffce1c0](https://github.com/ruby-git/ruby-git/commit/ffce1c0e26560b07e0512ebaec0be9c76e7be2fe))
* **repository:** Add Git::Repository::Branching facade module ([cac4962](https://github.com/ruby-git/ruby-git/commit/cac4962c37ab92bd87c902beb4385010c9713cf2))
* **repository:** Add Git::Repository::Committing facade module (closes [#1266](https://github.com/ruby-git/ruby-git/issues/1266)) ([c6fd522](https://github.com/ruby-git/ruby-git/commit/c6fd5228ed5deaa8157c51d4fb4cdcde6a7028bd))
* **repository:** Extract Git::Base#merge to Git::Repository::Merging ([8a95be8](https://github.com/ruby-git/ruby-git/commit/8a95be89d4d7c0a204ef4190f03c4a9793f649f6))
* **repository:** Implement Git::Repository with Staging facade module ([f5e3271](https://github.com/ruby-git/ruby-git/commit/f5e32710fd2c3fe6938cc69650b027542a7946a3))


### Bug Fixes

* **add:** Relax all/ignore-removal conflict handling ([a1bde8c](https://github.com/ruby-git/ruby-git/commit/a1bde8c41289f445a2c60732fb674f9e64df61ab))
* Address clone command test review issues ([556a53d](https://github.com/ruby-git/ruby-git/commit/556a53d0a96abf48345ba5855759f522938fc9a5))
* Address PR review comments in make-skill-template and pull-request-review skills ([76135b2](https://github.com/ruby-git/ruby-git/commit/76135b26093d5ebbc8ee97d693731403a975ee8e))
* Address review feedback on streaming entry points ([8ba5da9](https://github.com/ruby-git/ruby-git/commit/8ba5da940fdae02fb3c92325ce05a643eb7d0a3f))
* **arguments:** Accept any non-nil value for flag_or_value options ([436d803](https://github.com/ruby-git/ruby-git/commit/436d80306f204684cb674447dc35375d13dd9112))
* **checkout-index:** Add allowed_values for :stage and conflicts :all/:file ([2eecb07](https://github.com/ruby-git/ruby-git/commit/2eecb0716c091a07df3d6ba1c0f10b1a49ad759c))
* **ci:** Improve JRuby integration test hang visibility ([ce5267c](https://github.com/ruby-git/ruby-git/commit/ce5267c041ad8975953ea191258588db91b86cc2))
* **commands:** Add required validation for variadic positionals ([f2e9380](https://github.com/ruby-git/ruby-git/commit/f2e9380a5c0a569a816d5118c5249af12dd2a23e))
* Correct MRI-only compatibility claim to include JRuby and TruffleRuby ([f8ed87c](https://github.com/ruby-git/ruby-git/commit/f8ed87c5ba38b11d8f03377024f9dd7aebc3c6c8))
* Disable interactive editor to prevent process hanging ([49e28bc](https://github.com/ruby-git/ruby-git/commit/49e28bc211ddffe1fc3750ff5d85bc21374c0faf)), closes [#953](https://github.com/ruby-git/ruby-git/issues/953)
* **docs:** Pad all markdown table separator cells to fix markdownlint MD055 ([3010608](https://github.com/ruby-git/ruby-git/commit/3010608d07e11c8aaf341271cdaf51ef4a266c6d))
* Fix Rubocop offenses from newly added cops ([113a849](https://github.com/ruby-git/ruby-git/commit/113a849bd4efc37c34e94bd4e3f066d1104e1872))
* Handle Windows paths in branch parser integration test ([cf501d2](https://github.com/ruby-git/ruby-git/commit/cf501d2cb61040c85cf6caa0094dc2265feaa211))
* Overhaul Git::Commands::Clone DSL to match git-clone docs ([71c863e](https://github.com/ruby-git/ruby-git/commit/71c863efba9e3669b4a9dbc4ca854b4f49a1a04e))
* Render arguments in definition order instead of grouped by type ([cbdb482](https://github.com/ruby-git/ruby-git/commit/cbdb4822d9bb36719842439e19203d7705561a65))
* Replace agent-internal tool references with standard CLI commands in development-workflow skill ([a2a333c](https://github.com/ruby-git/ruby-git/commit/a2a333c883cce7c5c56209507f4b47ef1266d00f))
* Return empty array for git log on unborn branch ([b604049](https://github.com/ruby-git/ruby-git/commit/b6040499c2f9fee0c47bd8be26c52b19d5be06c1)), closes [#1155](https://github.com/ruby-git/ruby-git/issues/1155)
* **skills:** Add safe PR body update guidance ([b56f5ad](https://github.com/ruby-git/ruby-git/commit/b56f5ad9422f6c2f2d4559f78dfe1664e2b7431d))
* **staging:** Remove false-stripping workaround from add ([5116a5b](https://github.com/ruby-git/ruby-git/commit/5116a5bd7ce3853d367ae30525240767048e8370))
* **test:** Use crontab scheduler in maintenance start integration spec ([da7aa8d](https://github.com/ruby-git/ruby-git/commit/da7aa8d8ef20fa5cf2656ab01ac7f8e910c391d7))


### Other Changes

* Achieve 100% unit test coverage for all commands ([ffd123e](https://github.com/ruby-git/ruby-git/commit/ffd123e0f922b5cc0885d0de9dbf1d26861021fc))
* Add #call override guidance to review-command-implementation skill ([1df0cdb](https://github.com/ruby-git/ruby-git/commit/1df0cdb4ba552070fdc123d99f7d7d248da04c61))
* Add AI prompt for backward compatibility audit ([e914b9d](https://github.com/ruby-git/ruby-git/commit/e914b9debc16b1612f19e631958ae9dc8c476c18))
* Add AI prompts for Git::Commands development workflows ([a68d8d8](https://github.com/ruby-git/ruby-git/commit/a68d8d89c3ab41d3468eba94d92c1fd3ff6972d6))
* Add architectural insight about option semantics vs ergonomics ([e077820](https://github.com/ruby-git/ruby-git/commit/e07782026c9b8243562f0a11c29882ca58fbaa3b))
* Add architectural insights from branch delete migration ([a7e470b](https://github.com/ruby-git/ruby-git/commit/a7e470baca49e191ff66ed9f44f1f122e02dde31))
* Add architectural insights from branch move implementation ([68b762a](https://github.com/ruby-git/ruby-git/commit/68b762a8d2110e0a900adab9424a4b7d0865c0d5))
* Add architectural insights from checkout migration ([e4da8ce](https://github.com/ruby-git/ruby-git/commit/e4da8ce944f855cc59ceb886677f2a61aaaec929))
* Add branch copy command class for copying branches ([e329654](https://github.com/ruby-git/ruby-git/commit/e329654bb81439724c52ec5cd90d6594413113e3))
* Add clobber tasks for build and npm artifacts ([1a27fa6](https://github.com/ruby-git/ruby-git/commit/1a27fa620a670778c26a7faf9239a59551df8738))
* Add commitlint issue-reference rules and debugging guidance ([8d0d5f5](https://github.com/ruby-git/ruby-git/commit/8d0d5f5ae2b9b5ae761b3dda9e319c7f0bb0f96f))
* Add comprehensive PR readiness prompt for AI agents ([01ed5c1](https://github.com/ruby-git/ruby-git/commit/01ed5c1adc777404ec61eda7dd8dff7e9cde5cf7))
* Add Diff commands with proper exit code handling ([89ad898](https://github.com/ruby-git/ruby-git/commit/89ad898d60621a805b176bc08ee6392596dea27b))
* Add docker-git script to test with specific git versions ([67332c3](https://github.com/ruby-git/ruby-git/commit/67332c381ec950ee07a69f0a5240da44940ad673))
* Add end_of_options placement guidance to review-arguments-dsl and scaffold-new-command skills ([7ed50eb](https://github.com/ruby-git/ruby-git/commit/7ed50eb47d40e83259971f120a5e6b414a77e2f0))
* Add execution_context_double and stub_git_version helpers ([17c486d](https://github.com/ruby-git/ruby-git/commit/17c486d8af0ef083b48527e17763cc85c9591cc0))
* Add git reference document generator ([7812643](https://github.com/ruby-git/ruby-git/commit/78126434ae717ef7a58fcbf77a0cc66114de32f4))
* Add Git::Commands::Remote::* command classes ([8fb1893](https://github.com/ruby-git/ruby-git/commit/8fb18935c0624eb3ddd81bdd65a3ffac02f8e332))
* Add integration specs for Git::Commands::Remote::* commands ([8b7b5fc](https://github.com/ruby-git/ruby-git/commit/8b7b5fc69b99fad7a9f4cbccb9bdafd480177ab9))
* Add multi_valued option to value and inline_value in Arguments DSL ([d12d795](https://github.com/ruby-git/ruby-git/commit/d12d7952d8c2067bc6c905c9355b4511208783f1))
* Add parallel test execution support ([14fe20d](https://github.com/ruby-git/ruby-git/commit/14fe20d5830ed0f2a42158bc103b8bd62a13f9d2))
* Add result class naming conventions to project-context and scaffold-new-command ([b8039e4](https://github.com/ruby-git/ruby-git/commit/b8039e435898da3cec3f0de1142d4accae278cd0))
* Add RSpec integration test infrastructure ([0c364a8](https://github.com/ruby-git/ruby-git/commit/0c364a8df24a7f9f194d424eb03d93b6f3981e52))
* Add RSpec tests for Git::Branch dual-mode initialization ([94d11bb](https://github.com/ruby-git/ruby-git/commit/94d11bb53efd2edefd23858d5758813a0c6f0558))
* Add rubocop disable comments to Add and Clone #call methods ([01a6f07](https://github.com/ruby-git/ruby-git/commit/01a6f0734d98775866ebb5090269d63ee22bde52))
* Add skill-loading enforcement section to copilot-instructions ([55df964](https://github.com/ruby-git/ruby-git/commit/55df964c2450f8412e4da2077f9a9eba4905e954))
* Add sub-action scoping guidance to command skills ([98547c9](https://github.com/ruby-git/ruby-git/commit/98547c9f15b7e5d88661e7c32f9ecb49fe0365e4))
* Add tag-related classes to main git.rb requires ([d94741f](https://github.com/ruby-git/ruby-git/commit/d94741fda3a164e42a569e180c790d60e5d0dea5))
* Add tdd-refactor-step skill and cross-reference in development-workflow ([88c1714](https://github.com/ruby-git/ruby-git/commit/88c1714c6c2d7cf9394404aa240a79eafb004f2d))
* Add test-verbose script for debugging test execution ([5b3041f](https://github.com/ruby-git/ruby-git/commit/5b3041fe782ec72b6c1ba7d25f61904b8ec7faf8))
* Add unit specs for Git::Commands::Remote::* commands ([01b1d5f](https://github.com/ruby-git/ruby-git/commit/01b1d5ff98783b46cf494baf6c9c72e18b5933f5))
* Add with_stdin code example to review-command-implementation skill ([ee150ba](https://github.com/ruby-git/ruby-git/commit/ee150ba2fcac5ac8f8df5e5ac018079341dd6acf))
* **add:** Add integration tests for requires constraint violations ([c73e8ea](https://github.com/ruby-git/ruby-git/commit/c73e8eab5012f35e08e04b301fc36f800e8738e6))
* **add:** Move requires constraint tests to unit spec ([6a5d5f2](https://github.com/ruby-git/ruby-git/commit/6a5d5f2424314d0abe7750df32e1f44d7063f763))
* Address additional copilot review feedback ([5f79882](https://github.com/ruby-git/ruby-git/commit/5f798824460a8ba13b2a672a63ae840be4d81723))
* Address copilot review comments ([15cc7b0](https://github.com/ruby-git/ruby-git/commit/15cc7b081f9ae3c37b83fd737e0b6d87ae0e647d))
* Address Copilot review comments on Arguments DSL YARD docs ([acddfff](https://github.com/ruby-git/ruby-git/commit/acddffff5420aa574f7309fda13349d36f39d997))
* Address PR review comments ([f0cc114](https://github.com/ruby-git/ruby-git/commit/f0cc1149a62e1d7492aedd3d2f1b9438028d5381))
* **add:** Use Options DSL for argument building ([a8b3236](https://github.com/ruby-git/ruby-git/commit/a8b32369607e53b30f3cfed601be23de7c619960))
* Align skill guidance with minimum git version policy ([ac0652d](https://github.com/ruby-git/ruby-git/commit/ac0652d13e8d0d9b1256cce664e87e44691883da))
* **architecture:** Refine layer responsibilities ([d6b6253](https://github.com/ruby-git/ruby-git/commit/d6b6253302796188a667865aae5e31e631ca8c4d)), closes [#993](https://github.com/ruby-git/ruby-git/issues/993)
* **arguments:** Add ? accessor aliases for flag_option on Bound ([24615e5](https://github.com/ruby-git/ruby-git/commit/24615e57c9e450a7c4bf4e56d3a5f02279f341f4)), closes [#1053](https://github.com/ruby-git/ruby-git/issues/1053)
* **arguments:** Add `allowed_values` DSL method for declarative value constraints ([9344e5a](https://github.com/ruby-git/ruby-git/commit/9344e5a15cd04ab470d67b3932726667b4a7126a))
* **arguments:** Add `as:` option to `end_of_options` DSL method ([cd55747](https://github.com/ruby-git/ruby-git/commit/cd557474f36fd84ecbd6b8d322b7ec9e66ef1e20)), closes [#1164](https://github.com/ruby-git/ruby-git/issues/1164)
* **arguments:** Add `requires` DSL and conditional `when:` form of `requires_one_of` ([608e491](https://github.com/ruby-git/ruby-git/commit/608e491fca9908dafc7da06d18715e4d6db92387))
* **arguments:** Add alias resolution and operand coverage for conditional requires ([9308784](https://github.com/ruby-git/ruby-git/commit/930878454ac326d06b252505dcaa03c96fea55ec))
* **arguments:** Add allow_nil option for positional arguments ([c2280b2](https://github.com/ruby-git/ruby-git/commit/c2280b221ec6c5b987b7634ede5f5fc2f954b9ac))
* **arguments:** Add bind and migrate commands ([fc717d2](https://github.com/ruby-git/ruby-git/commit/fc717d2fc6a541314efbdc6cf142966f710662b5))
* **arguments:** Add Bound#execution_options method ([1475426](https://github.com/ruby-git/ruby-git/commit/1475426b7f63792206d3ae696ff411d8baecb2d8))
* **arguments:** Add end_of_options DSL method, remove separator: param ([660e195](https://github.com/ruby-git/ruby-git/commit/660e195ba5f5012c570fb677df3ca07f0746565c))
* **arguments:** Add forbid_values DSL for value-aware constraints ([3787a15](https://github.com/ruby-git/ruby-git/commit/3787a15a0f16bc771b9afbfe7f74696f4c7bce7b)), closes [#1080](https://github.com/ruby-git/ruby-git/issues/1080)
* **arguments:** Add key_value DSL method for key=value options ([3105382](https://github.com/ruby-git/ruby-git/commit/31053825d68e5d9ae1d487c61d95642e5bb246de))
* **arguments:** Add max_times: to flag_option for count-limited repeatable flags ([6f6c9a4](https://github.com/ruby-git/ruby-git/commit/6f6c9a42bb1ff162268e23a83251b4ea2c126007))
* **arguments:** Add option-like operand validation to Arguments DSL ([9dc86a6](https://github.com/ruby-git/ruby-git/commit/9dc86a6a25a2e025dc8e76dc9cc43367e0678dfd)), closes [#1023](https://github.com/ruby-git/ruby-git/issues/1023)
* **arguments:** Add required and allow_nil parameters to DSL ([4ce91fb](https://github.com/ruby-git/ruby-git/commit/4ce91fb4b7c0038f55390992908d59bf1da3ce4e))
* **arguments:** Add requires_exactly_one_of DSL convenience method ([be85b7e](https://github.com/ruby-git/ruby-git/commit/be85b7ebc4759a2153c17747db03169031cb6c72))
* **arguments:** Add requires_one_of DSL method for at-least-one validation ([1014495](https://github.com/ruby-git/ruby-git/commit/1014495b108d870148b3e73e33ce9e1add55e3ba))
* **arguments:** Add String Conversion section to Arguments DSL YARD docs ([8a235be](https://github.com/ruby-git/ruby-git/commit/8a235be7574c94f439514cbfe9ab46652e4d1427))
* **arguments:** Add value_to_positional option type ([f87f2f3](https://github.com/ruby-git/ruby-git/commit/f87f2f387da58485fa86ee7583c24c0dbf41a1b4))
* **arguments:** Auto-detect short option format for single-character names ([2da6d94](https://github.com/ruby-git/ruby-git/commit/2da6d94c3bad698173b7faa5c3ad031255a74908)), closes [#985](https://github.com/ruby-git/ruby-git/issues/985)
* **arguments:** Consolidate DSL with orthogonal modifiers ([6737f27](https://github.com/ruby-git/ruby-git/commit/6737f2797ec04f2813276584dd50585d7e1544f1))
* **arguments:** Extend conflicts to support operands ([633c56c](https://github.com/ruby-git/ruby-git/commit/633c56c0a54774724ddd5068df90b5d88b7e8301)), closes [#1062](https://github.com/ruby-git/ruby-git/issues/1062)
* **arguments:** Harden requires_one_of against empty groups and duplicate aliases ([6fde4ca](https://github.com/ruby-git/ruby-git/commit/6fde4ca1afb4c5ab5a3cb3b819a7502454777659))
* **arguments:** Remove duplicate requires_one_of positional operand test ([6578f37](https://github.com/ruby-git/ruby-git/commit/6578f37be14a84785e76827c46fffc4d4ab754c5))
* **arguments:** Remove validator: param from flag_option public API ([367c2c4](https://github.com/ruby-git/ruby-git/commit/367c2c4bd905f925e742fd62015fb071e18a898b)), closes [#1121](https://github.com/ruby-git/ruby-git/issues/1121)
* **arguments:** Rename args: to as: in flag_option and value_option DSL methods ([01d31e3](https://github.com/ruby-git/ruby-git/commit/01d31e3687f87d83aecf2a9f11e8c87075d33a80)), closes [#1051](https://github.com/ruby-git/ruby-git/issues/1051)
* **arguments:** Rename metadata DSL method to execution_option ([2e77931](https://github.com/ruby-git/ruby-git/commit/2e77931f8afef8db78075a257e4e4166f10be4ed)), closes [#1025](https://github.com/ruby-git/ruby-git/issues/1025)
* **arguments:** Support ruby-like positional allocation with optional + variadic ([5e02bbf](https://github.com/ruby-git/ruby-git/commit/5e02bbf5a6028dcd2f8592fc44ac58522884c072))
* **arguments:** Support skip_cli operands and cat-file DSL constraints ([01c38f7](https://github.com/ruby-git/ruby-git/commit/01c38f74abc90110a300591d103f8978482f7fb5)), closes [#1052](https://github.com/ruby-git/ruby-git/issues/1052)
* **arguments:** Treat negatable false as present in conflict and satisfied-by checks ([9a212d3](https://github.com/ruby-git/ruby-git/commit/9a212d322205dac9e33ea966c4187be571a57eed)), closes [#1078](https://github.com/ruby-git/ruby-git/issues/1078)
* **base:** Simplify path resolution and init flow ([3badcc7](https://github.com/ruby-git/ruby-git/commit/3badcc79505cffba55953c2a2047999fc9a27ba3))
* **branch:** Add move command class for branch renaming ([97625e6](https://github.com/ruby-git/ruby-git/commit/97625e65a689303cd3763f129aac196257a5455f))
* **branch:** Add target_oid and upstream attributes to BranchInfo ([4a0814a](https://github.com/ruby-git/ruby-git/commit/4a0814ac348c23141c703b0be4320b0887b0184f)), closes [#962](https://github.com/ruby-git/ruby-git/issues/962)
* **branch:** Modernize commands with structured return types ([f1695b3](https://github.com/ruby-git/ruby-git/commit/f1695b317e5370efc867191e2419048b8c0a7337))
* **branch:** Return CommandLineResult from all Branch command classes ([6286966](https://github.com/ruby-git/ruby-git/commit/6286966baacd6dbd4e19a2cc569faf91bb24ddb0))
* Capture learnings from implementing stash commands ([84abd3b](https://github.com/ruby-git/ruby-git/commit/84abd3b12994cdcc14b5ebb31d72a4ed44599831))
* **cat-file:** Delegate Git::Lib cat_file_* methods to Git::Commands::CatFile::* ([31d7cac](https://github.com/ruby-git/ruby-git/commit/31d7cac34c094d08bff3acfb10d47a7e89bebf7f)), closes [#1092](https://github.com/ruby-git/ruby-git/issues/1092)
* **ci:** Update GitHub Actions dependencies to latest major versions ([c73088f](https://github.com/ruby-git/ruby-git/commit/c73088f59bafc25d5eaaae4af763c7085b77e2c9))
* Clarify integration test guidance in implementation plan ([21fcfbd](https://github.com/ruby-git/ruby-git/commit/21fcfbd7a631bbda541b5fe9187aaa6513e3f75d))
* **clean:** Replace force_force workaround with max_times: 2 ([fbb7e22](https://github.com/ruby-git/ruby-git/commit/fbb7e225722bb3d7d38d973f4f1c89077fda4a7d))
* **clone:** Return CommandLineResult from Clone#call ([0ab515e](https://github.com/ruby-git/ruby-git/commit/0ab515e7c087d606b5b9929c39629259eddc42bb))
* **clone:** Use Options DSL for argument building ([2e4047d](https://github.com/ruby-git/ruby-git/commit/2e4047da960a8c1a48420215d2ef32bd14a0c579))
* **command_line:** Split into Capturing and Streaming subclasses ([1394f5a](https://github.com/ruby-git/ruby-git/commit/1394f5a7eb77cee81dc3e6f45132c64e0f7a4ed6))
* **command:** Add Git::Commands::CheckoutIndex class ([b468000](https://github.com/ruby-git/ruby-git/commit/b46800045f0b597ce99abd1158fe7f82df705075))
* **command:** Add Git::Commands::CommitTree class ([fa1fd51](https://github.com/ruby-git/ruby-git/commit/fa1fd518d046d3b928f7669141686320f43b5724))
* **command:** Add Git::Commands::LsFiles class ([571e2e1](https://github.com/ruby-git/ruby-git/commit/571e2e117e5e3b7165e679f307cbb66c801b78d1))
* **command:** Add Git::Commands::NameRev class ([bb53aef](https://github.com/ruby-git/ruby-git/commit/bb53aefe7fb043adf6243b88ccfde9f4cfee5307))
* **command:** Add Git::Commands::Pull class ([000114d](https://github.com/ruby-git/ruby-git/commit/000114dcbd9a75def164b2cd5001e2be18d78bec))
* **command:** Add Git::Commands::Revert::* classes ([eb26aad](https://github.com/ruby-git/ruby-git/commit/eb26aad364f54e12e7696555d0e51fcd68bbfa29))
* **command:** Add Git::Commands::RevParse class ([9ea66d0](https://github.com/ruby-git/ruby-git/commit/9ea66d06a68800af7cf0cceacfec858b7ec03954))
* **command:** Add Git::Commands::UpdateRef classes ([a446493](https://github.com/ruby-git/ruby-git/commit/a4464932e4ce60a318f56187786e1e50c93d08d2))
* **command:** Migrate archive to Git::Commands::Archive ([deee122](https://github.com/ruby-git/ruby-git/commit/deee122ec4af4d6eb7a52ce7fa2297298eeee7a6))
* **command:** Migrate fetch to Git::Commands::Fetch ([5a2ec77](https://github.com/ruby-git/ruby-git/commit/5a2ec7748794dbfe790fd99a7626b5716c11fbe3))
* **command:** Migrate Git::Lib#gc to Git::Commands::Gc ([3379e73](https://github.com/ruby-git/ruby-git/commit/3379e73134e0cfc8764ec35cc1d0a3a3db89a67c))
* **command:** Migrate Git::Lib#push to Git::Commands::Push ([f4b2930](https://github.com/ruby-git/ruby-git/commit/f4b293043f2e8a23b1a0dd942f71d367cd902a28))
* **command:** Migrate Git::Lib#repack to Git::Commands::Repack ([283a128](https://github.com/ruby-git/ruby-git/commit/283a128ace67aa74a92ddb9905c29399dc809113))
* **command:** Migrate ls_tree/full_tree/tree_depth to Git::Commands::LsTree ([0d3481c](https://github.com/ruby-git/ruby-git/commit/0d3481c7d027d76a2073ba75a4835874d7bb93aa))
* **command:** Migrate write_tree to Git::Commands::WriteTree ([3b5a3ed](https://github.com/ruby-git/ruby-git/commit/3b5a3ed3c853bb43aad2463323f47c5a44e36f07))
* **commands:** Add [@note](https://github.com/note) audit tag and fix YARD tag ordering in branch commands ([71ee983](https://github.com/ruby-git/ruby-git/commit/71ee983145b7e569dd0ce7ada0d194d71b2ab52b))
* **commands:** Add Git::Commands::ConfigOptionSyntax classes ([8c02e99](https://github.com/ruby-git/ruby-git/commit/8c02e99968e1053275194cc32e2c29b864aa446a))
* **commands:** Add Git::Commands::DiffIndex command class ([3b4ddc7](https://github.com/ruby-git/ruby-git/commit/3b4ddc781486368c8af951bf03c72add0e6107bf))
* **commands:** Add Git::Commands::Grep ([eb52ea5](https://github.com/ruby-git/ruby-git/commit/eb52ea5aaa2ec2d2832ce8ad6674ee24610ba3dc))
* **commands:** Add Git::Commands::Options DSL ([21401e0](https://github.com/ruby-git/ruby-git/commit/21401e0c0f5d52fa90d6387767ecd776a9fd270f))
* **commands:** Add Git::Commands::Status ([7dbc949](https://github.com/ruby-git/ruby-git/commit/7dbc949edfe4e9b9d70d4055fc19ec5dc1408457))
* **commands:** Add Git::Commands::Version for git version ([7d54afe](https://github.com/ruby-git/ruby-git/commit/7d54afe1d4783f0e092bf2445a339ed4c31d0d2e))
* **commands:** Add Git::Commands::Worktree command classes ([1e04a60](https://github.com/ruby-git/ruby-git/commit/1e04a6087ac73bfabb3426115beeadb7f786e4a9))
* **commands:** Add namespace modules for branch, checkout, merge, stash, and tag ([459daf5](https://github.com/ruby-git/ruby-git/commit/459daf593d94394242473530233a1d5c4d0161c4))
* **commands:** Add output-normalization hooks to Base ([a7d5795](https://github.com/ruby-git/ruby-git/commit/a7d5795c37985da7eab10871d54d446d953f1c32)), closes [#1187](https://github.com/ruby-git/ruby-git/issues/1187)
* **commands:** Add require_relative statements to existing namespace modules ([58cbcb9](https://github.com/ruby-git/ruby-git/commit/58cbcb904bd9c0d9c08841f03b9a6ffe1f9cd3ea))
* **commands:** Add ShowRef::Verify, ExcludeExisting, and Exists ([70bcee5](https://github.com/ruby-git/ruby-git/commit/70bcee50d69e0ee4b937cc64b7eaabc928442e21))
* **commands:** Add top-level Git::Commands module with YARD docs ([ed3e639](https://github.com/ruby-git/ruby-git/commit/ed3e63977e55983630af96e2b29b7ee01217b84f))
* **commands:** Add unit tests for Git::Lib#branch_contains delegation ([8d75603](https://github.com/ruby-git/ruby-git/commit/8d7560392d35ce8bccd171f3b4e56aec8e62b657))
* **commands:** Apply command-implementation skill to grep; backfill log options ([6e0da11](https://github.com/ruby-git/ruby-git/commit/6e0da117d5e93c9e604e98d933073d84901ff73b))
* **commands:** Audit config_option_syntax YARD docs (issue [#1196](https://github.com/ruby-git/ruby-git/issues/1196)) ([70ce8e2](https://github.com/ruby-git/ruby-git/commit/70ce8e26598f19865e526226ffd33b9e57a46a8e))
* **commands:** Audit revert/abort, revert/continue, revert/quit against git 2.53.0 ([472cb34](https://github.com/ruby-git/ruby-git/commit/472cb346f88af4218963bff9c2b2281e2fe2789a))
* **commands:** Audit YARD docs for archive/list_formats, version, worktree/add/list/lock ([2b29f54](https://github.com/ruby-git/ruby-git/commit/2b29f54353df3708eb3d6ed4bf57f96931bd8604))
* **commands:** Backfill post-2.28.0 options for am subcommands ([42642f4](https://github.com/ruby-git/ruby-git/commit/42642f4a0586fb1cf6ab245faed3bd444d7b8223))
* **commands:** Backfill post-2.28.0 options for cat_file/batch, filtered, raw ([9370bba](https://github.com/ruby-git/ruby-git/commit/9370bba7ccbf62009eeaab03bc1b3271874ef0cd))
* **commands:** Backfill post-2.28.0 options for show_ref/exclude_existing, exists, list, verify ([ad24544](https://github.com/ruby-git/ruby-git/commit/ad24544c4cf0a27ddb33a2a8675fb2739891e443))
* **commands:** Backfill post-2.28.0 options for stash/apply, branch, clear, create, drop ([d613115](https://github.com/ruby-git/ruby-git/commit/d613115c5eea9323051acc7a80cade92322b6d21))
* **commands:** Backfill post-2.28.0 options for stash/list, pop, push, show, store ([3853278](https://github.com/ruby-git/ruby-git/commit/3853278722466393915091d4c1b94df6e866e752))
* **commands:** Backfill post-2.28.0 options for update_ref/batch, delete, update ([7c94ba9](https://github.com/ruby-git/ruby-git/commit/7c94ba9046be084377a02089bd992e0af527eefb))
* **commands:** Backfill post-2.28.0 options for worktree/add, list, lock, move, prune ([82c6b4a](https://github.com/ruby-git/ruby-git/commit/82c6b4ad064f42f5e5b85c7a4479b6564a8f8b6d))
* **commands:** Backfill post-2.28.0 options for worktree/remove, repair, unlock ([efa16c9](https://github.com/ruby-git/ruby-git/commit/efa16c92fd2822657d374c8a34b653685c164ca6))
* **commands:** Backfill post-2.28.0 options into branch/create and branch/list ([f3733cb](https://github.com/ruby-git/ruby-git/commit/f3733cb0b9e5bb9444b63ea7cd5dd53cfa5a0434))
* **commands:** Backfill post-2.28.0 style into all remote/* command classes ([5b0bc4d](https://github.com/ruby-git/ruby-git/commit/5b0bc4d3bd898d76cd86f73272cd29d8dab8713a))
* **commands:** Complete config_option_syntax YARD audit and spec updates (issue [#1196](https://github.com/ruby-git/ruby-git/issues/1196)) ([3ad2365](https://github.com/ruby-git/ruby-git/commit/3ad236589db587d03b9d106c6eb31e6c67cf66f5))
* **commands:** Consolidate CatFile commands into Raw, Batch, and Filtered ([7f2c7da](https://github.com/ruby-git/ruby-git/commit/7f2c7daa54108be8d31c1ed37ba0e6cff437df2e))
* **commands:** Create Git::Commands::Base (issue [#996](https://github.com/ruby-git/ruby-git/issues/996) task 1) ([1615829](https://github.com/ruby-git/ruby-git/commit/16158294dc42cee66ac94fcccd9e249591f017f8))
* **commands:** Fix command classes and standardize signatures ([e26e562](https://github.com/ruby-git/ruby-git/commit/e26e562ab43c9a49d52ffd1b466b96a7e7bc9833))
* **commands:** Fix YARD inheritance and replace call shim with @!method directive ([ec662ad](https://github.com/ruby-git/ruby-git/commit/ec662ad9b538273172a227d4026037247f330911)), closes [#1071](https://github.com/ruby-git/ruby-git/issues/1071)
* **commands:** Improve DiffFiles YARD docs and test coverage ([2726ec1](https://github.com/ruby-git/ruby-git/commit/2726ec160f1e43b1d5b7cf40e321b4630cb4882f))
* **commands:** Migrate 8 commands to Commands::Base ([d18bb49](https://github.com/ruby-git/ruby-git/commit/d18bb495fa178db6d83e91e35b34a770625729a5))
* **commands:** Migrate Add, Branch::Delete, Clone to Commands::Base (issue [#996](https://github.com/ruby-git/ruby-git/issues/996) task 2) ([c51406f](https://github.com/ruby-git/ruby-git/commit/c51406f3cbffae82c223796678d3838adc88393d))
* **commands:** Migrate all negatable options to no_{flag} companion key ([#1260](https://github.com/ruby-git/ruby-git/issues/1260)) ([204ca2a](https://github.com/ruby-git/ruby-git/commit/204ca2ab5abb8c5b6b1c6a5d5f505e2bbf54df7d))
* **commands:** Migrate branch family to Commands::Base ([37448de](https://github.com/ruby-git/ruby-git/commit/37448de4f82acc1999abe44405aabe0f0f595df8))
* **commands:** Migrate Checkout and Diff to Commands::Base ([4e81cef](https://github.com/ruby-git/ruby-git/commit/4e81cefd41d79b829da8b76cb7a772951eb3b463)), closes [#996](https://github.com/ruby-git/ruby-git/issues/996)
* **commands:** Migrate git apply and git am to Commands architecture ([2f5db4a](https://github.com/ruby-git/ruby-git/commit/2f5db4af513f7c659ee1091b0a201be46b6bbd02))
* **commands:** Migrate ls_remote and repository_default_branch to Git::Commands::LsRemote ([83ceed9](https://github.com/ruby-git/ruby-git/commit/83ceed9114a7256c6ae1b015d42dad54b75f83ab))
* **commands:** Migrate merge and tag commands to Base pattern ([df6dfa4](https://github.com/ruby-git/ruby-git/commit/df6dfa43c6363eb3c162c4f46763be5ef3ec4dee))
* **commands:** Move parsing from diff commands to facade layer ([d83e270](https://github.com/ruby-git/ruby-git/commit/d83e2707f1a1be331161b088d68b5004c8fe721e))
* **commands:** Register ShowRef sub-commands in lib/git/lib.rb ([532c025](https://github.com/ruby-git/ruby-git/commit/532c02525c6f56a5c06435c86fd3b8c16da86444))
* **commands:** Remove constraint declarations from command classes ([5bf3881](https://github.com/ruby-git/ruby-git/commit/5bf3881f12221881fc2eed04e7f41934ec4c48ea))
* **commands:** Standardize command definitions and update AI prompts ([88ceeb1](https://github.com/ruby-git/ruby-git/commit/88ceeb117ad71fab198f32b94ac6ead906db3e10))
* **commands:** Standardize Yardoc for #call methods ([31a3f20](https://github.com/ruby-git/ruby-git/commit/31a3f208e69e0e77ea5038dfefa4b4649fcd85cd))
* **commands:** Update Apply command class per implementation skill ([0240b95](https://github.com/ruby-git/ruby-git/commit/0240b9579ebf2e91ff2e0310b0f4cc785ed5f0dd))
* **commands:** Update Archive command class per implementation skill ([696b703](https://github.com/ruby-git/ruby-git/commit/696b7034bed61450810f064dbfe4bbcbda5b116b))
* **commands:** Update branch/copy and branch/delete commands (issue [#1196](https://github.com/ruby-git/ruby-git/issues/1196), batch 1) ([843a0e1](https://github.com/ruby-git/ruby-git/commit/843a0e176c9fdbead529cd22d921c5dce9f2a5e8))
* **commands:** Update Checkout namespace module per implementation skill ([f1fec1f](https://github.com/ruby-git/ruby-git/commit/f1fec1f352e69f99d3fc9268e144ad19b09478ea))
* **commands:** Update Checkout::Branch command class per implementation skill ([fb19d53](https://github.com/ruby-git/ruby-git/commit/fb19d5308bc9803e57d44f7e6f5d95d75e35a24c))
* **commands:** Update Checkout::Files command class per implementation skill ([ca2fea5](https://github.com/ruby-git/ruby-git/commit/ca2fea567720496a57f859463f97d6c0224fbb70))
* **commands:** Update CheckoutIndex command class per implementation skill ([f301e1d](https://github.com/ruby-git/ruby-git/commit/f301e1d99257bb45d7169cc229dd06217831f088))
* **commands:** Update Clean command class per implementation skill ([12132be](https://github.com/ruby-git/ruby-git/commit/12132be8c722c12e85a65dfda233adc822635fa7))
* **commands:** Update Clone command class per implementation skill ([64dad0c](https://github.com/ruby-git/ruby-git/commit/64dad0cc36e441f4dbb749a50378d4a8c263b605))
* **commands:** Update Commit command class per implementation skill ([7bf5cef](https://github.com/ruby-git/ruby-git/commit/7bf5cefb996661d8196828f8c7589c6410987f32))
* **commands:** Update CommitTree command class per implementation skill ([07c7bff](https://github.com/ruby-git/ruby-git/commit/07c7bff071ebbb68f216ff343ba885bdc1fe558c))
* **commands:** Update config_option_syntax/replace_all, set, unset, unset_all (issue [#1196](https://github.com/ruby-git/ruby-git/issues/1196)) ([a1dd913](https://github.com/ruby-git/ruby-git/commit/a1dd9137967586791d0ec6e1d3a4d4b887069319))
* **commands:** Update Describe command class per implementation skill ([7b0abfa](https://github.com/ruby-git/ruby-git/commit/7b0abfab303691bdd73f0e9364a5780776d1c16d))
* **commands:** Update Diff command class per implementation skill ([07b36ff](https://github.com/ruby-git/ruby-git/commit/07b36ffae1f3cb786e816595193bf41bcf16202f))
* **commands:** Update DiffFiles command class per implementation skill ([5244687](https://github.com/ruby-git/ruby-git/commit/5244687e0537a44eaf3a010c1977bd722c58f8a0))
* **commands:** Update DiffIndex command class per implementation skill ([e16bade](https://github.com/ruby-git/ruby-git/commit/e16bade53ea8054d970180cc1926f2dcfdf1d6ad))
* **commands:** Update Fetch command class per implementation skill ([7252861](https://github.com/ruby-git/ruby-git/commit/725286161d4bc68bcee7ba67ae6f0dd5e21dfa58))
* **commands:** Update Fsck command class per implementation skill ([fc5a826](https://github.com/ruby-git/ruby-git/commit/fc5a826e55fb12d4e2e11f8c39af35a267a07a28))
* **commands:** Update Gc command class per implementation skill ([19779a0](https://github.com/ruby-git/ruby-git/commit/19779a03c32bd6b34754d72d7cd1d638accd9738))
* **commands:** Update Git::Commands::Add to command-implementation standards ([125887b](https://github.com/ruby-git/ruby-git/commit/125887b19550b7f184104597006e364dcaa9ce44))
* **commands:** Update Init command class per implementation skill ([5eb536a](https://github.com/ruby-git/ruby-git/commit/5eb536abd171ed68f58d61d0f58e93769fd99629))
* **commands:** Update ls-files, ls-remote, ls-tree per implementation skill ([4fef064](https://github.com/ruby-git/ruby-git/commit/4fef06435ca68b353c1c84eebad6d18f4111f1a6))
* **commands:** Update merge-base, mv, name-rev, pull, push per implementation skill ([96bc933](https://github.com/ruby-git/ruby-git/commit/96bc933576de457299e6cd7cf45c5a5336832b37))
* **commands:** Update merge/* command classes per issue [#1196](https://github.com/ruby-git/ruby-git/issues/1196) ([fd20bef](https://github.com/ruby-git/ruby-git/commit/fd20bef5b306cfbe99299e1f69c5c5babda45728))
* **commands:** Update read-tree, repack, reset, rev-parse, rm (batch 7) ([9460450](https://github.com/ruby-git/ruby-git/commit/946045098a1685308efd01c6fd83b395a4548906))
* **commands:** Update revert/skip and revert/start command classes ([d8edb2c](https://github.com/ruby-git/ruby-git/commit/d8edb2cb667de841056339348abb7cc59b03a43a))
* **commands:** Update show, status, tag per implementation skill (batch 7) ([de1064a](https://github.com/ruby-git/ruby-git/commit/de1064a36d5ff010715403a15a300ffd8209b194))
* **commands:** Update symbolic-ref, tag/verify, write-tree (batch 7) ([9977656](https://github.com/ruby-git/ruby-git/commit/99776565c9b159fef672561a3b519cb719a752ab))
* **commands:** Update test examples to use expect_command helper ([add89b4](https://github.com/ruby-git/ruby-git/commit/add89b42ffba1b4820d3b0fcd87dc9db508d70ab))
* **commands:** Update worktree/move, prune, remove, repair per implementation skill ([fe33764](https://github.com/ruby-git/ruby-git/commit/fe337641686da76655f522e57001c4827460ed29))
* **commands:** Use expect_command helper in unit tests ([dde57fa](https://github.com/ruby-git/ruby-git/commit/dde57fa01ebd861262ab77c8869cfbbdbe59b7b7))
* Configure git and clean up build deps in Dockerfile ([5ccf327](https://github.com/ruby-git/ruby-git/commit/5ccf3275e8ebee07b08695a2561f9b48251e24a0))
* Configure prerelease releases ([94064ae](https://github.com/ruby-git/ruby-git/commit/94064ae4a90ab7448203bb59c0a4545efd8bb72e))
* Correct Phase 2 progress count in tracker ([d30f1f3](https://github.com/ruby-git/ruby-git/commit/d30f1f3a8843661cf264075110ee76882ab95516))
* Delegate change_head_branch to SymbolicRef::Update ([dc0c74e](https://github.com/ruby-git/ruby-git/commit/dc0c74e63ac1992f3a0e8950c9e2124a0094a36e))
* Deprecate :path in Git::Lib#clone, add :chdir option ([de02f29](https://github.com/ruby-git/ruby-git/commit/de02f299c7d5ad57362ebe211b9e81155f899d93)), closes [#991](https://github.com/ruby-git/ruby-git/issues/991)
* Deprecate legacy git version methods (closes [#1193](https://github.com/ruby-git/ruby-git/issues/1193)) ([02a7514](https://github.com/ruby-git/ruby-git/commit/02a75147a46aeef0f049d21f50b6572c096a1b64))
* **diff:** Wire Git::Lib diff methods to Diff command classes ([2fe116f](https://github.com/ruby-git/ruby-git/commit/2fe116f997a3d54db8f6848fbff7f6217870e62e)), closes [#1021](https://github.com/ruby-git/ruby-git/issues/1021)
* **docs:** Update redesign doc for ls_files migration ([3b36e63](https://github.com/ruby-git/ruby-git/commit/3b36e63061cb1b1256fea0622b6a63d2847ee357))
* **doctest:** Add YARD doctest integration for documentation examples ([6b882c8](https://github.com/ruby-git/ruby-git/commit/6b882c844a67e76ad7bd2af56fe443e6e8518967))
* Document architectural insights from Branch::List migration ([52f322c](https://github.com/ruby-git/ruby-git/commit/52f322cb01b9e27df305e3dd8b4efbd8324cf1f4))
* Document per-command timeout/env capability in Lib#command and Clone#call ([63122b8](https://github.com/ruby-git/ruby-git/commit/63122b8428b41ce5089b1d3cbd744ac37d28ab84)), closes [#1026](https://github.com/ruby-git/ruby-git/issues/1026)
* Document requires_one_of in prompts, CONTRIBUTING, and copilot instructions ([ed5de89](https://github.com/ruby-git/ruby-git/commit/ed5de891a6f3c33e71eeedeb8a7deab480041361))
* Document validation delegation policy ([b65ed34](https://github.com/ruby-git/ruby-git/commit/b65ed34590c475db4c452c8c71c547c1deb66bc6))
* Enable option validation in Add and Fsck commands ([37aa0d5](https://github.com/ruby-git/ruby-git/commit/37aa0d5b4f513f30ff7a7d6fecff8c78a7a5a915))
* Enforce command-layer neutrality and facade-owned policy ([da22791](https://github.com/ruby-git/ruby-git/commit/da22791b555483eb1841bb1b0a3ee406ebd77e0e))
* Enhance Arguments DSL with new features ([88e6d5d](https://github.com/ruby-git/ruby-git/commit/88e6d5df2c1867ce2484de8f4c7a61ff3b2c77d9))
* Establish method signature convention for Git::Commands::* #call ([d1e103c](https://github.com/ruby-git/ruby-git/commit/d1e103cb35a27abe8d18e7f8c67257595af52eec))
* Exclude spec/**/* from Metrics/BlockLength ([1cc1001](https://github.com/ruby-git/ruby-git/commit/1cc10012a3a0c59db046aa5c9d7b5b3c86bbdb8f))
* Extract branch creation to Git::Commands::Branch::Create ([6252090](https://github.com/ruby-git/ruby-git/commit/62520904a39bcec9490bbf51bec991d351812a12))
* Extract branch delete to Git::Commands::Branch::Delete ([90bb682](https://github.com/ruby-git/ruby-git/commit/90bb68271ac93329f85fb5f5ecfef839421f088f))
* Extract git add to Git::Commands::Add ([baf2a76](https://github.com/ruby-git/ruby-git/commit/baf2a761e3e165be59c185f665c02424dc05cd9e))
* Extract git fsck to Git::Commands::Fsck ([ad28871](https://github.com/ruby-git/ruby-git/commit/ad2887103ff99ac17faa907ba5fa730da9e71f1e))
* Finalize architectural redesign documentation for PR ([40255b3](https://github.com/ruby-git/ruby-git/commit/40255b3f5e7f27b86543cf11d692cdfcfc74a16f))
* Fix awkward wording in command-implementation skill description ([20ee143](https://github.com/ruby-git/ruby-git/commit/20ee14324df9701ea7a732b439af78533dff3a10))
* Fix markdown style rule violations in CONTRIBUTING.md ([14528fc](https://github.com/ruby-git/ruby-git/commit/14528fccbbfe345ca1b9d462cb7abd0db594f446))
* Fix output-mode subclass violations and move literal options to facade ([3954052](https://github.com/ruby-git/ruby-git/commit/3954052fff8c8a92b7813e40c79dec605276f0a1))
* Fix RSpec deprecation warning and suppress git command output ([ab34fef](https://github.com/ruby-git/ruby-git/commit/ab34fef89c8e4f94ee06a1f37c7b6195bae9a213))
* Fix stale plan entries and add missing commands to redesign tracker ([996b032](https://github.com/ruby-git/ruby-git/commit/996b0321f98bfdf46bbc52761e7bde3375cd3fb2))
* Fix tagger_date regex to handle both timezone offset and Z format ([5d4686b](https://github.com/ruby-git/ruby-git/commit/5d4686b6395b933d4184a783b57dab682037c1dd))
* **fsck:** Return CommandLineResult from Fsck#call ([29a31d4](https://github.com/ruby-git/ruby-git/commit/29a31d4dc39b3e2ac61ee9a216e4aa63800ffe52)), closes [#1017](https://github.com/ruby-git/ruby-git/issues/1017)
* **fsck:** Use Options DSL for argument building ([7464439](https://github.com/ruby-git/ruby-git/commit/7464439b8915640563e1c4d609f206856ed9bc73))
* Implement Branch::SetUpstream and Branch::UnsetUpstream commands ([bf1f634](https://github.com/ruby-git/ruby-git/commit/bf1f634f6fd19cc05d8ffcfcee5ad641aa32c783))
* Implement Ruby-style positional argument mapping in Arguments DSL ([895f9f2](https://github.com/ruby-git/ruby-git/commit/895f9f2b2621ebaf2252bcdba8c8098f0dbe9b69))
* Implement tag delete command with structured result objects ([5908a0e](https://github.com/ruby-git/ruby-git/commit/5908a0ef25a837482f45826e3128f52e885fd799))
* Improve command-implementation skill discoverability ([67c43e4](https://github.com/ruby-git/ruby-git/commit/67c43e40fdae65f6cdc3951f24fe740b4936cf7c))
* Improve YARD documentation for Arguments DSL public methods ([acddfff](https://github.com/ruby-git/ruby-git/commit/acddffff5420aa574f7309fda13349d36f39d997))
* **integration:** Fix Git::Log#first deprecation in branching_spec ([6f83fbc](https://github.com/ruby-git/ruby-git/commit/6f83fbc63f3f5b4da263923dcc32386d86c1ba5e))
* **lib:** Add Git::Commands::Version for git version ([89311b6](https://github.com/ruby-git/ruby-git/commit/89311b63f62e85c1470d0d1133dd9635562c751a))
* **lib:** Delegate checkout_index to Git::Commands::CheckoutIndex ([1967c21](https://github.com/ruby-git/ruby-git/commit/1967c211f768757eb9a8e535759369476e0be0ae))
* **lib:** Delegate commit_tree to Git::Commands::CommitTree ([d27fbdd](https://github.com/ruby-git/ruby-git/commit/d27fbdd85b767b53e979df9478bb228b464689cc))
* **lib:** Delegate current_branch_state and branch_contains to Git::Commands::Branch ([dae1af7](https://github.com/ruby-git/ruby-git/commit/dae1af783fc32687e9c2323309eef3e3c18cd7b0))
* **lib:** Delegate Git::Lib#grep to Git::Commands::Grep ([16f2416](https://github.com/ruby-git/ruby-git/commit/16f2416017bf99a1671a29fe3edec41faeaa1b25))
* **lib:** Delegate Git::Lib#pull to Git::Commands::Pull ([fcabef0](https://github.com/ruby-git/ruby-git/commit/fcabef082123a418339bb85561858731bb741978))
* **lib:** Delegate ls_files/ignored_files/untracked_files to Git::Commands::LsFiles ([7c9761a](https://github.com/ruby-git/ruby-git/commit/7c9761a980b4f538fd7987b54c8d3e557460e73c))
* **lib:** Delegate name_rev to Git::Commands::NameRev ([cdc4fb4](https://github.com/ruby-git/ruby-git/commit/cdc4fb4ca63094bde0c7924279cb81de05d84951))
* **lib:** Delegate rev-parse calls to Git::Commands::RevParse ([276cf9c](https://github.com/ruby-git/ruby-git/commit/276cf9cb4bc0eab7470c7c46374deff5e1f39756))
* **lib:** Delegate revert to Git::Commands::Revert::Start ([0c4d691](https://github.com/ruby-git/ruby-git/commit/0c4d691957432fcabca15551cf391afe6f46309c))
* **lib:** Delegate unmerged to Git::Commands::Diff ([ff744d9](https://github.com/ruby-git/ruby-git/commit/ff744d91b7c4d6dfbf26ce5f11dc1a099d83031c))
* **lib:** Delegate update_ref to Git::Commands::UpdateRef::Update ([e9fa2b2](https://github.com/ruby-git/ruby-git/commit/e9fa2b2accf5671c57b186fcabd14702328ee11d))
* **lib:** Delegate write_staged_content to Git::Commands::Show ([e7db4d2](https://github.com/ruby-git/ruby-git/commit/e7db4d2cf84092a2048c25d84e91480b2d6a01b2))
* **lib:** Extract clean deprecation helpers to fix method length ([f003ff5](https://github.com/ruby-git/ruby-git/commit/f003ff592c9ad09f8309701fb8842a9000ab923f))
* **lib:** Migrate Git::Lib config methods to ConfigOptionSyntax commands ([6d366cb](https://github.com/ruby-git/ruby-git/commit/6d366cb37b167ba02c8f29542c2dee7fb9fd22e4))
* **lib:** Migrate Git::Lib worktree methods to Worktree commands ([be7616e](https://github.com/ruby-git/ruby-git/commit/be7616e06940a429992ea0811d42ef6c92e07f31))
* **lib:** Migrate Git::Lib#tag_sha to use Git::Commands::ShowRef::List ([dc698ba](https://github.com/ruby-git/ruby-git/commit/dc698ba38b658d9dfa82867f3fd55f017d1fe201))
* **lib:** Rename lib entry points for capturing/streaming split ([2c5d34d](https://github.com/ruby-git/ruby-git/commit/2c5d34d781fdb1dafb5ed6559afb6513cdf78d65)), closes [#1100](https://github.com/ruby-git/ruby-git/issues/1100)
* **lib:** Update clean backward compat for force: 2 ([90cb1af](https://github.com/ruby-git/ruby-git/commit/90cb1af035a930587c3b817961c29d03e3f0e899))
* Make default rake task run tests in parallel ([9eb43c7](https://github.com/ruby-git/ruby-git/commit/9eb43c70e82dc454c5a41d3ac015c4cffadca37f))
* Make Git::Lib#command public for Command classes ([e946d04](https://github.com/ruby-git/ruby-git/commit/e946d043e4fcab192e4d7761db9fa836dae51366))
* Mark checkout command as migrated and update next task ([a1b354f](https://github.com/ruby-git/ruby-git/commit/a1b354fad5f87029280dcd819efc97b6008075e9))
* Mark diff_as_hash migrated, update Next Task to status ([34b3faf](https://github.com/ruby-git/ruby-git/commit/34b3faffd1b07d3af431003dd8b08c24f69bf132))
* Mark git remote commands as complete in architecture implementation ([48c4beb](https://github.com/ruby-git/ruby-git/commit/48c4bebd62831952dc772baee58ab1c73acde5dd))
* Mark main releases as prerelease ([1dca79a](https://github.com/ruby-git/ruby-git/commit/1dca79a8cb4827e4954f04d2918ccfb8a1737dba))
* Mark revert migration done in redesign checklist ([8b11ecd](https://github.com/ruby-git/ruby-git/commit/8b11ecd41d77bc8baff74558f4af1da4435deb51))
* Mark unmerged as migrated in implementation plan ([7decdbb](https://github.com/ruby-git/ruby-git/commit/7decdbbef039978ceae9851b9d8ff30ca54ff282))
* Merge Exclude arrays with inherited rubocop config ([0d7b582](https://github.com/ruby-git/ruby-git/commit/0d7b58260c571f8371b133f0b36fcb6a84c4e618))
* **merge-base:** Return CommandLineResult instead of parsed Array ([81bdc69](https://github.com/ruby-git/ruby-git/commit/81bdc69d0d56097713a5ebccb8256dddc7d9d7ad))
* Migrate checkout to Commands architecture ([89b79ed](https://github.com/ruby-git/ruby-git/commit/89b79ed6f827f90987ff8cd7709edcbcdf6ca1df))
* Migrate clean command to Git::Commands::Clean ([87e6bcb](https://github.com/ruby-git/ruby-git/commit/87e6bcbe17aabac4173fc512857e2fb7b1f8c191))
* Migrate commit command to Git::Commands::Commit ([03cb887](https://github.com/ruby-git/ruby-git/commit/03cb887e8dd52e82e0860485d732011e595d7da1))
* Migrate describe to Git::Commands::Describe ([9fac884](https://github.com/ruby-git/ruby-git/commit/9fac8843fdbfbd6bcb219ddc5e6a6f9182d5db6c))
* Migrate diff_files and diff_index to use command classes ([2fc0bce](https://github.com/ruby-git/ruby-git/commit/2fc0bceb27f0bf72cc277c460b8c82991febf159))
* Migrate git clone to Git::Commands::Clone ([a16d14a](https://github.com/ruby-git/ruby-git/commit/a16d14afc5bc1447ecd9c56cb39ecf85c206c87c))
* Migrate git stash commands to new architecture ([cd83218](https://github.com/ruby-git/ruby-git/commit/cd83218a64313f581b93a8ff103f0a252d4e9fed))
* Migrate git tag commands to new architecture ([717fca2](https://github.com/ruby-git/ruby-git/commit/717fca25d48663fc620ec71aa4a3b4b27fb1bb13))
* Migrate init command to new architecture ([482e5f0](https://github.com/ruby-git/ruby-git/commit/482e5f0d7e4b2b1aaab2dc359a781fc283342731))
* Migrate log_commits/full_log_commits to Git::Commands::Log ([86dee4e](https://github.com/ruby-git/ruby-git/commit/86dee4e7fce57de0fcc748f6ce0812c3fe4d3aee))
* Migrate merge commands to Commands layer ([e6e3866](https://github.com/ruby-git/ruby-git/commit/e6e386636bf6e0c69115e15fa0ee5368de80d403))
* Migrate read_tree to Git::Commands::ReadTree ([a2b2b00](https://github.com/ruby-git/ruby-git/commit/a2b2b0071409762820168d0e5e3650864691deb7))
* Migrate remaining stash commands to Git::Commands ([666ab61](https://github.com/ruby-git/ruby-git/commit/666ab61ececcad755d37977756109b02d0002317))
* Migrate reset command to Git::Commands::Reset ([6e3cca7](https://github.com/ruby-git/ruby-git/commit/6e3cca72536c57f8aea06ff91f04c451ea86a4f8))
* Migrate rm command to Git::Commands::Rm ([61d8940](https://github.com/ruby-git/ruby-git/commit/61d894047c1e7a899791cd9224ae118395d82ec2))
* Migrate show to Git::Commands::Show ([e33a41e](https://github.com/ruby-git/ruby-git/commit/e33a41e67d2b3b36a09b4dc26c0bae933607cbb6))
* Move static command names into Arguments.define ([175fe0e](https://github.com/ruby-git/ruby-git/commit/175fe0eeaaf6d16bf6d29c775680be71b0a919bd)), closes [#949](https://github.com/ruby-git/ruby-git/issues/949)
* **options:** Add nil validation for variadic positional arguments ([5b793da](https://github.com/ruby-git/ruby-git/commit/5b793da11a24408701e6b8e5fd69524484f00977))
* **parsers:** Extract parsing logic into dedicated parser classes ([8b2ee26](https://github.com/ruby-git/ruby-git/commit/8b2ee26898f411f80027b7e159601d884f7dd2bc)), closes [#1002](https://github.com/ruby-git/ruby-git/issues/1002)
* Populate TagInfo with rich metadata using git tag --format ([c8c455d](https://github.com/ruby-git/ruby-git/commit/c8c455dd3255a62e1012aec23fd8edc573592688)), closes [#955](https://github.com/ruby-git/ruby-git/issues/955)
* **prompts:** Add branch workflow guidance to all prompts ([c540a86](https://github.com/ruby-git/ruby-git/commit/c540a8677b9c48ebd7afe093db0fefcd3232d495))
* **prompts:** Add execution_option to DSL method table ([71f249b](https://github.com/ruby-git/ruby-git/commit/71f249bb7afdc1909cc6e0b4caff8f21f0edad4a)), closes [#1019](https://github.com/ruby-git/ruby-git/issues/1019)
* **prompts:** Add Extract Command from Lib prompt and usage instructions ([7101309](https://github.com/ruby-git/ruby-git/commit/71013094e1104ea27c4a5ef5a30b22ebe6bfbfac))
* **prompts:** Update Review Arguments DSL and Review YARD Documentation ([431aacb](https://github.com/ruby-git/ruby-git/commit/431aacb8769c4a4eb6560d33e625f6774318333a))
* **redesign:** Add checkout_index migrated table entry ([3729e74](https://github.com/ruby-git/ruby-git/commit/3729e74fb1927084f09e64f394807822ea36797f))
* **redesign:** Add ShowRef rows to implementation progress table ([4272d99](https://github.com/ruby-git/ruby-git/commit/4272d993fe3b937f93bb7aad7b4b43e100bee6d5))
* **redesign:** Mark config migration complete, set next task to worktree ([382358a](https://github.com/ruby-git/ruby-git/commit/382358a3e1466a33b5cf7d21f590edbe4431aebf))
* **redesign:** Mark rev_parse migrated in checklist ([7bd2af6](https://github.com/ruby-git/ruby-git/commit/7bd2af6877a0ef14f597970524558873ceacea72))
* **redesign:** Mark tag_sha migrated, update Next Task to apply/apply_mail ([4dfc1b3](https://github.com/ruby-git/ruby-git/commit/4dfc1b3573348282ec65b0d28c969976bfc22a26))
* **redesign:** Mark worktree migration complete, set next task to branch_contains ([a792deb](https://github.com/ruby-git/ruby-git/commit/a792debf649f0ccbabe71ffe08e0dc4ffaca80ec))
* **redesign:** Update architecture doc to reflect Commands::Base implementation ([dee64d9](https://github.com/ruby-git/ruby-git/commit/dee64d9c616eae4b6abd1b2f6c7c165259289d8e))
* **redesign:** Update checklist — pull migrated to Git::Commands::Pull ([52e01e9](https://github.com/ruby-git/ruby-git/commit/52e01e9bcbcf144caee2f818fa72139b7a480ece))
* **redesign:** Update checklist after grep migration ([6263dce](https://github.com/ruby-git/ruby-git/commit/6263dce6428e8bcf55175e34a2e20936e771c46f))
* **redesign:** Update command migration checklist status ([09ccd79](https://github.com/ruby-git/ruby-git/commit/09ccd79888dfb2694a80dad4037792f6f857c68d))
* **redesign:** Update tracker for apply/am migration (40/54) ([c3c0957](https://github.com/ruby-git/ruby-git/commit/c3c0957d243e0c88375a66e7fe52ddae165856ac))
* Refactor copilot-instructions.md into skills ([a5bad70](https://github.com/ruby-git/ruby-git/commit/a5bad702569ada28851eda5656cdf265d525d5bd))
* Remove inline trailing comments from arguments DSL blocks ([370dffb](https://github.com/ruby-git/ruby-git/commit/370dffb198641463cda1675475faedcaf04aa5da))
* Remove new methods from Git::Lib added after v4.3.0 ([b1b5bac](https://github.com/ruby-git/ruby-git/commit/b1b5bac853646d50b3b36394219bceca4826ac7f))
* Rename Arguments DSL methods to use CLI terminology ([df35b6c](https://github.com/ruby-git/ruby-git/commit/df35b6ca01d1e335cc22c1c0d2320844491d9733)), closes [#994](https://github.com/ruby-git/ruby-git/issues/994)
* Rename capturing entry points to prepare for streaming API ([6fa3af2](https://github.com/ruby-git/ruby-git/commit/6fa3af2899031ed02fa15003d193f2b8c15a5adf)), closes [#1097](https://github.com/ruby-git/ruby-git/issues/1097)
* Rename FsckObject sha to oid ([c84d317](https://github.com/ruby-git/ruby-git/commit/c84d3175b2000c7566bc022cc85cacb09d0a8aa5)), closes [#967](https://github.com/ruby-git/ruby-git/issues/967)
* Rename Options to Arguments and OPTIONS to ARGS ([b76c9c3](https://github.com/ruby-git/ruby-git/commit/b76c9c388d43fe26d7a7be0c4eaeaeafea0a6abb))
* Rename StashInfo sha/short_sha to oid/short_oid ([789cb41](https://github.com/ruby-git/ruby-git/commit/789cb41c5025ada7d8cd751038210ca5b34442e3)), closes [#966](https://github.com/ruby-git/ruby-git/issues/966)
* Rename TagInfo sha to oid and add target_oid ([39ca36b](https://github.com/ruby-git/ruby-git/commit/39ca36bd813fe60573dabb85bb7a9000843c1f44)), closes [#963](https://github.com/ruby-git/ruby-git/issues/963)
* Replace path wrapper classes with Pathname ([c7b7b1f](https://github.com/ruby-git/ruby-git/commit/c7b7b1f1e782533140ba22b831385097da2e3d09))
* Replace unknown [@yieldself](https://github.com/yieldself) tag with standard [@yield](https://github.com/yield) ([acddfff](https://github.com/ruby-git/ruby-git/commit/acddffff5420aa574f7309fda13349d36f39d997))
* Replace yard-doctest with yard_example_test ([5acffeb](https://github.com/ruby-git/ruby-git/commit/5acffeb580e26ebe04e39fb0a61d31c558d7d2cb))
* Restore agent tool references in development-workflow skill ([bbb32aa](https://github.com/ruby-git/ruby-git/commit/bbb32aa72c516d89e47d481676d2d72b8e3c3ea2))
* Restructure CONTRIBUTING.md and link from copilot-instructions ([7e3481b](https://github.com/ruby-git/ruby-git/commit/7e3481b42b306ec00111cc91d6bd8ab282766ee8))
* Return BranchInfo from Branch::Create command ([a23f384](https://github.com/ruby-git/ruby-git/commit/a23f384602861abc1ad7263405ade42039a969f2))
* Return TagInfo from Tag::Create command ([2dde55c](https://github.com/ruby-git/ruby-git/commit/2dde55cfb8f45fcc8043b5058ddeb0938511eab5))
* Set up RSpec testing environment ([452929a](https://github.com/ruby-git/ruby-git/commit/452929aa63d2fb022a107e441417e777de5c038f))
* **show_current:** Use Arguments DSL and align tests with guidelines ([7c58e17](https://github.com/ruby-git/ruby-git/commit/7c58e1717255b107840fbe16dd3b74ca3686c34e))
* Silence superfluous test output ([1da9f66](https://github.com/ruby-git/ruby-git/commit/1da9f669409b9dfbfd248edac66d9e71aa9b0a47))
* **skill:** Add execution_option pinning rule and operand repeatable guidance ([4718557](https://github.com/ruby-git/ruby-git/commit/471855726829b10b6d8dc243acc333bda9243b63))
* **skill:** Add YARD tag formatting rules and multi-sentence option example to scaffold skill ([c5c235a](https://github.com/ruby-git/ruby-git/commit/c5c235a6acce0b8eb937a68595f5e949b319b150))
* **skill:** Clarify YARD call doc placement for explicit def call overrides ([c73a6b6](https://github.com/ruby-git/ruby-git/commit/c73a6b616fc9cc2315c6216c29d55c09fa2bbe38))
* **skill:** Improve command extraction skills with DSL and scaffold guidance ([ffd27f8](https://github.com/ruby-git/ruby-git/commit/ffd27f82e3f7deb7898449a100a28f9a036e230c))
* **skill:** Resolve inconsistencies in review-command-tests and rspec-standards ([007fcb9](https://github.com/ruby-git/ruby-git/commit/007fcb9506c668f47259b74bc1fe3b8d69b54710))
* **skills:** Add [@api](https://github.com/api) public checklist item to command-yard-documentation ([ef4206f](https://github.com/ruby-git/ruby-git/commit/ef4206f34fd9b7753219436aa43fd484f4ae26d8))
* **skills:** Add [@note](https://github.com/note) audit convention and bin/latest-git-version guidance ([d774420](https://github.com/ruby-git/ruby-git/commit/d774420d845dbc90434b2773d3db06aa44dad437))
* **skills:** Add [@note](https://github.com/note) placement-order check to review-arguments-dsl CHECKLIST ([a49e5bb](https://github.com/ruby-git/ruby-git/commit/a49e5bb2948d0045d4536efb5bbf6a0de050fc53))
* **skills:** Add [@overload](https://github.com/overload) /**options rule to command-yard-documentation skill ([0f0456f](https://github.com/ruby-git/ruby-git/commit/0f0456f7ccb1c9981ea4cc54f37aa44045842399))
* **skills:** Add [@raise](https://github.com/raise) [ArgumentError] to command template and override example in REFERENCE.md ([b28fdea](https://github.com/ruby-git/ruby-git/commit/b28fdea50a2aa3dc74fcde6932b0dd91482ffe21))
* **skills:** Add action-option-with-optional-value pattern ([b8e270d](https://github.com/ruby-git/ruby-git/commit/b8e270d5d2d37ae04bc3155cd39c4c2b2180ad8e))
* **skills:** Add ALLOWED_OPTS pattern, initial_branch rule, and initialize spec guidance ([8361fe1](https://github.com/ruby-git/ruby-git/commit/8361fe1db5f8859a6acd1e9be85871db361e36c3))
* **skills:** Add audit version guidance; add (nil) vs (false) flag option common issue ([c4fbb90](https://github.com/ruby-git/ruby-git/commit/c4fbb904770e1782979f3e23a9224e1a6194c653))
* **skills:** Add bulk file text substitution guideline to development workflow ([8a2c1ce](https://github.com/ruby-git/ruby-git/commit/8a2c1ce02d2eee3d6672cb7827e5f32d2dfb2436))
* **skills:** Add call-override, stdin, and sub-command namespace guidance ([7e0c6de](https://github.com/ruby-git/ruby-git/commit/7e0c6deb835befea72419b8778234ada27870a58))
* **skills:** Add explicit [@option](https://github.com/option) default checklist item to command-yard-documentation ([45cedc3](https://github.com/ruby-git/ruby-git/commit/45cedc3b4e819a90b9d2945065123927eb3e4d6b))
* **skills:** Add facade skills and update related skills with facade links ([9ade70a](https://github.com/ruby-git/ruby-git/commit/9ade70abf27518e42bf533e3f30ee82d52c4dfde))
* **skills:** Add mode-scoped flag constraint guidance; clarify negatable and flag_option defaults ([64a5ea2](https://github.com/ruby-git/ruby-git/commit/64a5ea2c9a36f7a32a1dd03a6ddf2870b29b22ee))
* **skills:** Add option allowlist guidance to extract-facade-from-base-lib skill ([ad0a62e](https://github.com/ruby-git/ruby-git/commit/ad0a62e3f3eeb8cf08690734617beda5729c9863))
* **skills:** Add unnecessary-require failure pattern and clarify one-task-at-a-time quality gate ([2a7379c](https://github.com/ruby-git/ruby-git/commit/2a7379c631cc4ab867c0f2121a7adbe8a9b31e9f))
* **skills:** Add YARD tag punctuation and paragraph rules ([065f0b5](https://github.com/ruby-git/ruby-git/commit/065f0b5ad7b8de5494a073aa1823effce3005f32))
* **skills:** Automate redesign tracker sync checks ([ea6ead0](https://github.com/ruby-git/ruby-git/commit/ea6ead02bcd52a44208cdf786a89ead1ab425474))
* **skills:** Clarify negatable inline comment rule in review-arguments-dsl checklist ([33b4846](https://github.com/ruby-git/ruby-git/commit/33b4846ffca5b3b1925ec988b5bb437a8135ab32))
* **skills:** Clarify value_option YARD type and require long-flag form in it descriptions ([8195cf7](https://github.com/ruby-git/ruby-git/commit/8195cf737e7ff4c8f4a717a26922c88648e892b0))
* **skills:** Clarify YARD docs skills ([5a73437](https://github.com/ruby-git/ruby-git/commit/5a73437be18778a6fde3f06308f7bcaab188009e))
* **skills:** Enforce command test and YARD doc review in VERIFY and PR readiness ([3f372fd](https://github.com/ruby-git/ruby-git/commit/3f372fd367e57b81cce78a0c8f44166d6be04c11))
* **skills:** Expand namespace module template in command-implementation skill ([b40221b](https://github.com/ruby-git/ruby-git/commit/b40221b270a4a0e6e0231d667be83582ce79bf15))
* **skills:** Fix [@raise](https://github.com/raise) wording in command-implementation REFERENCE.md example ([db31a3b](https://github.com/ruby-git/ruby-git/commit/db31a3b36e2b6dbcc6ad88179ed1390ac6b9ea45))
* **skills:** Merge scaffold and review-command into command-implementation ([917036b](https://github.com/ruby-git/ruby-git/commit/917036b035ad29610163612e6bfc2f95642c5b1a))
* **skills:** Pr 1 — update skills to describe new negatable DSL contract (issue [#1260](https://github.com/ruby-git/ruby-git/issues/1260)) ([53f0eed](https://github.com/ruby-git/ruby-git/commit/53f0eeddf84f4ce513fbd941b2bc249443072770))
* **skills:** Prohibit local git help output in command implementation ([fa7d0cb](https://github.com/ruby-git/ruby-git/commit/fa7d0cb48b97d9a9733cd59647934fae2665c847))
* **skills:** Remove negatable flag normalization from extract-facade skill ([#1260](https://github.com/ruby-git/ruby-git/issues/1260)) ([83d52c3](https://github.com/ruby-git/ruby-git/commit/83d52c3b60a4d63c833e280f9e6b4d2f2d40627b))
* **skills:** Rename and clarify YARD documentation skills ([4d5758a](https://github.com/ruby-git/ruby-git/commit/4d5758aa3511698f6e51ec76ec76eefdcf4efd58))
* **skills:** Slim copilot-instructions and add pre-commit branch guard ([2b5448a](https://github.com/ruby-git/ruby-git/commit/2b5448abacf994db24556d030e16548811a2da7a))
* **skills:** Strengthen prohibition of trailing inline DSL comments ([678b637](https://github.com/ruby-git/ruby-git/commit/678b637ba2eaabefbee510e0536662ebd0df202e))
* **skills:** Update command-yard-documentation and command-test-conventions skills ([9594c04](https://github.com/ruby-git/ruby-git/commit/9594c04d8588ebab4d37d1b8cf16676f9b2055d8))
* **skills:** Update instructions and yard-documentation skill ([ad05db9](https://github.com/ruby-git/ruby-git/commit/ad05db913acb08efd61c886deb4f3f31a339fd7a))
* **skill:** Update scaffold-new-command to require review skills ([9e7bb1c](https://github.com/ruby-git/ruby-git/commit/9e7bb1cec0ae9077c06ea19f6054bc535d309448))
* **specs:** Use execution_context_double across command specs ([821f7d9](https://github.com/ruby-git/ruby-git/commit/821f7d9cb1010b9a8216a959f3448468ada842c8))
* Split Merge::Resolve into separate Abort, Continue, and Quit commands ([1ac31f6](https://github.com/ruby-git/ruby-git/commit/1ac31f65ed1d746bd042f8c14f6ca0db14fb2bab))
* **stash:** Migrate commands to Base pattern ([1b72c1d](https://github.com/ruby-git/ruby-git/commit/1b72c1d248f572733afaa2f72671a4e6fb75d7d0))
* **stash:** Restore v4.0.0 backward compatibility for Git::Lib stash methods ([34318a3](https://github.com/ruby-git/ruby-git/commit/34318a38856f3a3fc1aca224bb5fb03409daa0e5))
* Sync implementation plan command checklist with issue 1043 ([ac56234](https://github.com/ruby-git/ruby-git/commit/ac5623426912a207ea7537bda92f060cfb613a97))
* **tag/create:** Move requires constraint tests to unit spec ([0441179](https://github.com/ruby-git/ruby-git/commit/0441179ec9f01cc4d162c9cc5c5982c3a977e445))
* **tag:** Enhance tag commands with multi-line messages and verify support ([5138898](https://github.com/ruby-git/ruby-git/commit/513889875c32f828f3a4c680adff0c819deb0ac8))
* **tag:** Migrate Tag commands to return CommandLineResult ([672bc23](https://github.com/ruby-git/ruby-git/commit/672bc2306401ff55a40e68b41595ef1f22cf8e7d))
* **tag:** Restore backward-compatible Git::Lib tag methods ([1d54ba1](https://github.com/ruby-git/ruby-git/commit/1d54ba1339e405db5c4121d9446a2a89a1b1ece3))
* **test:** Add legacy tests for checkout_index ([5f9857a](https://github.com/ruby-git/ruby-git/commit/5f9857ab9d66970d1696d32e61218536673d4066))
* **test:** Audit integration tests for Git::Commands classes ([0a8bfc0](https://github.com/ruby-git/ruby-git/commit/0a8bfc039957ed2ae7dc3c2ae4cdbdcc600d21f5))
* **test:** Audit unit tests for Git::Commands classes ([80306e0](https://github.com/ruby-git/ruby-git/commit/80306e0f2de304c56e8f67688ff6527bcc270dee))
* Unify command execution with raise_on_failure and env options ([a2fc5de](https://github.com/ruby-git/ruby-git/commit/a2fc5de2c9a44d630195be729467a8c68774dd34))
* Update all Commands to use new Arguments DSL names and remove aliases ([49cd648](https://github.com/ruby-git/ruby-git/commit/49cd648d5d9dbf6db273760622c2b90ddf11f797)), closes [#994](https://github.com/ruby-git/ruby-git/issues/994)
* Update architecture documentation for redesign phases and public API ([8544cc7](https://github.com/ruby-git/ruby-git/commit/8544cc7209d41428b5a52733b3a3b3324739c5af))
* Update architecture implementation plan with branch create insights ([1736617](https://github.com/ruby-git/ruby-git/commit/1736617aa8cfd76d7df5a3131324bc39b1763c5a))
* Update architecture implementation tracker ([dce1883](https://github.com/ruby-git/ruby-git/commit/dce1883dae3883168fe1863f59a8493f8d5498fb))
* Update branch consumers to use BranchInfo ([dffc94a](https://github.com/ruby-git/ruby-git/commit/dffc94ab0a051541a2c2c489844f2dc4362e7167))
* Update documentation for Commands::Base architecture ([27be4d6](https://github.com/ruby-git/ruby-git/commit/27be4d61d4c5a2d4b42722198d929ca607d7ab03)), closes [#996](https://github.com/ruby-git/ruby-git/issues/996)
* Update Git::Commands::* to use keyword arguments ([ece055d](https://github.com/ruby-git/ruby-git/commit/ece055dfb0aa9aadc1ac3a99de1315c11f470574))
* Update implementation checklist after log command migration ([b37cccb](https://github.com/ruby-git/ruby-git/commit/b37cccb70839cc91388fecaa030a245f5bf0a079))
* Update implementation checklist for update_ref migration ([c6be6df](https://github.com/ruby-git/ruby-git/commit/c6be6df477d481967e21892e2d1e8e5175176931))
* Update implementation plan - fetch migrated, next task is pull ([969befe](https://github.com/ruby-git/ruby-git/commit/969befe0b187eb9ada2e38ab77776989c98b5d20))
* Update implementation plan for SymbolicRef migration ([22543b5](https://github.com/ruby-git/ruby-git/commit/22543b5fa7473a104164f3132c70ebd86333d388))
* Update implementation plan for Version command migration ([9de9389](https://github.com/ruby-git/ruby-git/commit/9de938994665af5c159ce68050c9fa179564ed56))
* Update migration checklist for commit_tree ([4096724](https://github.com/ruby-git/ruby-git/commit/40967243c3f8211db2f376afddc9db750c244f1b))
* Update migration checklist for name_rev ([c71905c](https://github.com/ruby-git/ruby-git/commit/c71905ce49aa3b602263d0c9b2d499421c36e825))
* Update Phase 2 migration progress tracker to 41/~50 commands ([b529ffa](https://github.com/ruby-git/ruby-git/commit/b529ffaaadc0c919cf197233c87210ba3a965353))
* Update Phase 2 migration progress tracker to 41/~50 commands ([db2db46](https://github.com/ruby-git/ruby-git/commit/db2db46dad3fc039cdfd9e310900d8c82e997959))
* Update plan - mark Phase 3 Task 1 complete, add Task 2 workflow ([913a27c](https://github.com/ruby-git/ruby-git/commit/913a27ca78130769c7b5d2a49586e1af1cf9f9cd))
* Update plan - mark Phase 3 Task 3 complete, add Task 4 workflow ([29eee69](https://github.com/ruby-git/ruby-git/commit/29eee6973b279cd2f4f2f585f053a1ec797373ec))
* Update plan - mark Phase 3 Task 4 staging module complete, update Next Task ([cdadb3f](https://github.com/ruby-git/ruby-git/commit/cdadb3fc3d2b7f8673d5de6c986ae37398b123b9))
* Update redesign doc for Git::Commands::Status migration ([a722c4c](https://github.com/ruby-git/ruby-git/commit/a722c4c6a901d4df96c2611b6b3b5dfa23c1479e))
* Update redesign progress and next task to name_rev ([c7c9ada](https://github.com/ruby-git/ruby-git/commit/c7c9adafd0c1aa94ee3d958b000dc4f82e92e175))
* Update rspec-unit-testing-standards based on Git::CommandLine tests ([a91cd81](https://github.com/ruby-git/ruby-git/commit/a91cd818fdbdd15934538628219ca9da19ec1510))
* Update skill files for Git::Version ([f07ec74](https://github.com/ruby-git/ruby-git/commit/f07ec74bfe1b79351d61e5824c5d2b8065cefe87))
* Update skills for latest-version option completeness and add bin/latest-git-version ([98d551c](https://github.com/ruby-git/ruby-git/commit/98d551c5aaf147b55bba4b0372c1c086f7ec8f09)), closes [#1195](https://github.com/ruby-git/ruby-git/issues/1195)
* Update skills to document max_times: flag_option modifier ([ce0711a](https://github.com/ruby-git/ruby-git/commit/ce0711a3a447352c36700e5cfe190ff3c2d745f9))
* Update test infrastructure for version validation ([e90fa5d](https://github.com/ruby-git/ruby-git/commit/e90fa5df6c111d1ce7be597c2675fb9718cb29a5))
* Update testing guidelines for Git::Commands classes ([69c1fb1](https://github.com/ruby-git/ruby-git/commit/69c1fb1c446073306e7f6398fb908bb573d212b9))
* Update write-yard-documentation skill with lessons from CommandLine docs ([e5b6bad](https://github.com/ruby-git/ruby-git/commit/e5b6bad7ef62aa9e3fb396afc67e5012f3838086))
* Use Branch::List command in Git::Lib#branches_all ([d872f17](https://github.com/ruby-git/ruby-git/commit/d872f17332f0f872926e7ba3a27608cb4705986b))
* Use streaming path for archive, cat_file_contents block form, and write_staged_content ([4102034](https://github.com/ruby-git/ruby-git/commit/410203409fee7126a98f8f0aa0dcd42ba05e51e6))
* Wire Git::Lib remote methods to Git::Commands::Remote::* ([97c0c8c](https://github.com/ruby-git/ruby-git/commit/97c0c8c06dd9d9cd9e4575fa7f0e026a3e2a0086))
* **worktree:** Add max_times: 2 to Worktree::Add force option ([519b497](https://github.com/ruby-git/ruby-git/commit/519b4974f78933e601dddd2492fdd32fbf0b4eaa))
* **worktree:** Add max_times: 2 to Worktree::Move force option ([6332944](https://github.com/ruby-git/ruby-git/commit/6332944784c17c322c700d182c03317bdb590f74))
* **worktree:** Add max_times: 2 to Worktree::Remove force option ([d300b23](https://github.com/ruby-git/ruby-git/commit/d300b23cabaababb726edc5895ce051e7c6d1d5e))
* **yard:** Consolidate YARD tasks into namespaced structure ([ccb1d9a](https://github.com/ruby-git/ruby-git/commit/ccb1d9a36c939979385669137b34036102d2afdf))

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
