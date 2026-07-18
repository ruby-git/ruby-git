<!--
# @markup markdown
# @title Change Log
-->

# Change Log

## [5.0.0](https://github.com/ruby-git/ruby-git/compare/v4.1.2...v5.0.0) (2026-07-18)


### ⚠ BREAKING CHANGES

* Git::Base and Git::Lib are removed. All public API is now surfaced through Git::Repository (for repo-bound operations) and the Git module-level methods (Git.open, .clone, .init, .bare, .default_branch, .git_version). Internal command execution goes through Git::Commands::* and Git::ExecutionContext, not Git::Lib.
* Git.open, Git.bare, Git.clone, and Git.init now return Git::Repository instead of Git::Base. Code that depends on the Git::Base return type must be updated to use Git::Repository. Git::Repository provides all the same public API methods as Git::Base.
* **arguments:** flag_option :foo, negatable: true no longer accepts false to emit --no-foo. Before: bind(foo: false) => ["--no-foo"]. After: register two entries; bind(no_foo: true) => ["--no-foo"]. Callers passing foo: false expecting --no-foo will silently get nothing emitted.

### Features

* Add branch_current delegator to Git::Base ([8b92b54](https://github.com/ruby-git/ruby-git/commit/8b92b541b20f422c581582701625b459b1359670))
* Add deprecated config_get/list/set aliases to Git::Repository::Configuring ([fb964d3](https://github.com/ruby-git/ruby-git/commit/fb964d3878ecf63fdc0e0b285b616fac8191daae))
* Add deprecated conflicts wrapper on Git::Repository::Merging ([cc3907d](https://github.com/ruby-git/ruby-git/commit/cc3907daabe9d0c0ebde5a3728c6a2496694c9ec))
* Add deprecated empty? wrapper on Git::Repository::StatusOperations ([e0dbd1c](https://github.com/ruby-git/ruby-git/commit/e0dbd1c9ebe408dbbbebf3dc6ee18026fa42051d))
* Add deprecated Git::Repository::Stashing#stash_list facade ([9e532bd](https://github.com/ruby-git/ruby-git/commit/9e532bd3916924700c843688c97dbc15aaef2cc1))
* Add Git::Base compatibility shim with deprecation warnings ([d37710b](https://github.com/ruby-git/ruby-git/commit/d37710bbe5d576c8b04a17d53a2d901f4750eef1))
* Add Git::MINIMUM_GIT_VERSION constant ([d5c8604](https://github.com/ruby-git/ruby-git/commit/d5c860419858ed8e9c6f9a4bdd198224d22eed63))
* Add Git::Repository remote_names facade method ([4f52a7b](https://github.com/ruby-git/ruby-git/commit/4f52a7b1beecf4c85b7a4419999099e5af38e2fb))
* Add Git::Repository::Branching#change_head_branch facade ([e8d6af6](https://github.com/ruby-git/ruby-git/commit/e8d6af6bf8c3e5fd42b2d78123f7eb6c2a980c30))
* Add Git::Repository::Branching#current_branch_state facade ([fa798a7](https://github.com/ruby-git/ruby-git/commit/fa798a7bdfe9cd790ed426df051813b7b188f98e))
* Add Git::Repository::Configuring#global_config facade and deprecated aliases ([12b2e59](https://github.com/ruby-git/ruby-git/commit/12b2e59bfaeb06f5bb7046d8e72501ac164e4055))
* Add Git::Repository::Diffing#diff factory ([33db465](https://github.com/ruby-git/ruby-git/commit/33db465aa5e6d354df5fda0e7914e3ff92744946))
* Add Git::Repository::Merging#unmerged facade ([7d4b1fe](https://github.com/ruby-git/ruby-git/commit/7d4b1fe4e7215c11603f0aa004319faf65ee1653))
* Add Git::Repository::RemoteOperations#ls_remote facade ([4c63567](https://github.com/ruby-git/ruby-git/commit/4c6356775fec7fcd40acc29cf810dbcf07f10996))
* Add Git::Repository#branches factory to Branching module ([92e4cc6](https://github.com/ruby-git/ruby-git/commit/92e4cc65d28ac0b2598204aec1151eed2b3cb435))
* Add Git::RepositoryContext and Git::GlobalContext (Phase 3 Task 1) ([e2b94ca](https://github.com/ruby-git/ruby-git/commit/e2b94caa42adaface90fbc41c853e0a963a59740))
* Add Git::Version class for git binary versions ([d97b5e3](https://github.com/ruby-git/ruby-git/commit/d97b5e335d694e8b3f948d6bebe8ee3916076373))
* Add Git::VersionConstraint value object ([28599f0](https://github.com/ruby-git/ruby-git/commit/28599f0cd08583453112ef528f9b08892cc6430d))
* Add Git::VersionError exception class ([8ed8713](https://github.com/ruby-git/ruby-git/commit/8ed871322aed2b7802a26dc652a68d9047b8a7c1))
* Add upstream and upstream_remote to Git::Branch ([ef16e94](https://github.com/ruby-git/ruby-git/commit/ef16e94113a8e18eed6e60319aa7e223e6292d67)), closes [#1270](https://github.com/ruby-git/ruby-git/issues/1270)
* Allow deprecation behavior env var ([49ae5a8](https://github.com/ruby-git/ruby-git/commit/49ae5a8ee7f83ee10ba1ae00a7dd5fdee0f1c43b))
* **api:** Add Git.git_version method ([7ae54f3](https://github.com/ruby-git/ruby-git/commit/7ae54f34454af1472192d20fdd64971f989e0557)), closes [#1249](https://github.com/ruby-git/ruby-git/issues/1249)
* **arguments:** Replace negatable tri-state with no_{flag} companion key ([#1260](https://github.com/ruby-git/ruby-git/issues/1260)) ([e305922](https://github.com/ruby-git/ruby-git/commit/e305922aebd6b34b6c50be150ee56d18f558f617))
* **base:** Add diff_numstat delegator to Git::Base ([5a8a0ec](https://github.com/ruby-git/ruby-git/commit/5a8a0ec7c33e607745ad79a01c7e0830c075b310))
* **base:** Add Git::Base delegators for 23 Bucket 6 orphans ([513e6a2](https://github.com/ruby-git/ruby-git/commit/513e6a2033f934cc0df8e90b45b0b6a72e0acb19))
* **base:** Add Git::Base#git_version delegator ([026f738](https://github.com/ruby-git/ruby-git/commit/026f738ad1d9c445f7455601af7228c5797b45b9))
* **branching:** Add deprecated is_branch?/is_local_branch?/is_remote_branch? stubs ([9484e4f](https://github.com/ruby-git/ruby-git/commit/9484e4fe9d388cca750f4ebeff885625009345ed))
* **branching:** Add local_branch?, remote_branch?, branch? facade methods ([14dd2b3](https://github.com/ruby-git/ruby-git/commit/14dd2b36466f3dd97ae52e5981fc3d50c1d22ea9))
* **commands:** Add Git::Commands::Maintenance subcommand classes ([5404c5a](https://github.com/ruby-git/ruby-git/commit/5404c5aa5b02f89451b83619ec710f3fc8cd8cff))
* **commands:** Add requires_git_version macro and validation ([3c1f1ec](https://github.com/ruby-git/ruby-git/commit/3c1f1ec053a75705e39065b127ee4e39aaf804c0))
* **commands:** Add validate_version! to custom #call implementations ([9deec1f](https://github.com/ruby-git/ruby-git/commit/9deec1f2ee0fda6328ab6acc15602c72e56b5c54))
* **config:** Add Git::Configuring mixin, parsers, and ConfigEntryInfo ([cf0d813](https://github.com/ruby-git/ruby-git/commit/cf0d8132709f51670c9be8275978a1a384f0d7ce))
* **config:** Extend Git::Configuring into the Git module ([eb5be7a](https://github.com/ruby-git/ruby-git/commit/eb5be7abee4cf27933a2553c68a17701daf74d99))
* **config:** Include Git::Configuring in Git::Repository and remove clashing deprecated aliases ([68ca900](https://github.com/ruby-git/ruby-git/commit/68ca900bb89928bee2ccabee68bff4123353d357))
* **diff_stats:** Migrate DiffStats to Git::Repository and add diff_stats factory ([1a7b28f](https://github.com/ruby-git/ruby-git/commit/1a7b28f69cc17f2d6e0db06cababaca757c95229))
* **execution-context:** Add binary_path: keyword and retire Open3 stopgap ([bf94218](https://github.com/ruby-git/ruby-git/commit/bf94218b488ef8e599c13c596f30faa39ae62a56))
* **execution-context:** Forward binary_path from Git::Base via from_base ([8e9af8f](https://github.com/ruby-git/ruby-git/commit/8e9af8f422b53d6142ab15625473075f862066af))
* Extend config() with :file option for reads; add deprecated parse_config wrapper ([c2be049](https://github.com/ruby-git/ruby-git/commit/c2be0494c3b008d9b40a471a876632c4dd53d5fc))
* Extract gblob/gcommit/gtree/tag/object to Git::Repository::ObjectOperations ([199bcf9](https://github.com/ruby-git/ruby-git/commit/199bcf9e278e8c19a17c952621f42ebd5d3fd148))
* Flip Git.open/bare/clone/init to return Git::Repository (C1d-1) ([eb1a5b2](https://github.com/ruby-git/ruby-git/commit/eb1a5b21e59949f87e9a2586cd9a9b44aed5e80e))
* **lib:** Add git_version method returning Git::Version ([a473978](https://github.com/ruby-git/ruby-git/commit/a47397825769f7181fb63bfaff09c4eb494c4149))
* Migrate branch and remote constructor polymorphism to repository facade ([4a05e39](https://github.com/ruby-git/ruby-git/commit/4a05e398ecbc07b29c56459b8b2f77347909b9b1))
* Migrate Git::DiffPathStatus to Git::Repository::Diffing facade (iter 2) ([2d23eec](https://github.com/ruby-git/ruby-git/commit/2d23eec37c82409e393806e3b31b822f26cb3100))
* Migrate Git::Object::* to accept Git::Repository ([e1b2365](https://github.com/ruby-git/ruby-git/commit/e1b236536750b5f8ff433f79cf56bd67c756fb9b))
* **object-operations:** Add 6 legacy aliases to ObjectOperations (PR 2e) ([ecd4f45](https://github.com/ruby-git/ruby-git/commit/ecd4f452ba95b828ce0d627606da438aa271b642))
* **remote:** Add Git::RemoteInfo value object and Parsers::Remote ([6527633](https://github.com/ruby-git/ruby-git/commit/65276339f4549fc9c075d5daeba11a87f269dd5a))
* **remote:** Add remote_list facade method ([bf711a9](https://github.com/ruby-git/ruby-git/commit/bf711a96dc685a6c8e0d161805b853ae388df84c))
* **remote:** Add remotes, set_remote_url, remote_set_branches to facade ([592c549](https://github.com/ruby-git/ruby-git/commit/592c549574ef5d17c10883a48f70755e08e498a4))
* Rename facade methods to {noun}_{verb} convention; keep old names as deprecated aliases ([c381397](https://github.com/ruby-git/ruby-git/commit/c3813970b9e8e97720304308e435e06f10cd2f69))
* **repository:** Add branch_contains facade method to Git::Repository::Branching ([6b3b218](https://github.com/ruby-git/ruby-git/commit/6b3b2182f659181c181f1c8d388da1a709ac74d1))
* **repository:** Add compatibility aliases remove and revparse ([6b4ca81](https://github.com/ruby-git/ruby-git/commit/6b4ca81d43a9834d1819f89ebacf104c41889676))
* **repository:** Add describe, repack, and gc facade methods ([973d8a3](https://github.com/ruby-git/ruby-git/commit/973d8a3764b6e002f33b6f69cdcd9682ade6e9ce))
* **repository:** Add Git::Repository::Branching facade module ([cac4962](https://github.com/ruby-git/ruby-git/commit/cac4962c37ab92bd87c902beb4385010c9713cf2))
* **repository:** Add Git::Repository::Branching#branch_delete facade method ([0b73e74](https://github.com/ruby-git/ruby-git/commit/0b73e744282b78ba1b00048870159bbcf85b8b72))
* **repository:** Add Git::Repository::Committing facade module (closes [#1266](https://github.com/ruby-git/ruby-git/issues/1266)) ([c6fd522](https://github.com/ruby-git/ruby-git/commit/c6fd5228ed5deaa8157c51d4fb4cdcde6a7028bd))
* **repository:** Add Git::Repository::Configuring facade module ([a41e886](https://github.com/ruby-git/ruby-git/commit/a41e886535ff9eeeb658d1b4ae5deb8ce8ddcdcf))
* **repository:** Add Git::Repository::Diffing#diff_files facade method ([9428aad](https://github.com/ruby-git/ruby-git/commit/9428aadbb10ccba5769c731db09e0841fe78de4a))
* **repository:** Add Git::Repository::Inspecting facade (show, fsck) ([c8d478b](https://github.com/ruby-git/ruby-git/commit/c8d478bdeefc90d3b7f8f9ca7e5cede93730ca96))
* **repository:** Add Git::Repository::Merging#each_conflict facade method ([a47cb60](https://github.com/ruby-git/ruby-git/commit/a47cb60dca90b4885c0efd0e702d4217ab739c24))
* **repository:** Add Git::Repository::Merging#revert facade method ([2cd57b4](https://github.com/ruby-git/ruby-git/commit/2cd57b407358adcd74d5d117cbf1412cbe6e7d7b))
* **repository:** Add Git::Repository::RemoteOperations#add_remote facade method ([d1d2a58](https://github.com/ruby-git/ruby-git/commit/d1d2a58c72669ca74c4350eee657708c6f3a1990))
* **repository:** Add Git::Repository::RemoteOperations#push facade method ([19d0bd0](https://github.com/ruby-git/ruby-git/commit/19d0bd00f57927888138d016a45ba791733d3758))
* **repository:** Add Git::Repository::Stashing#stash_save facade method ([305626c](https://github.com/ruby-git/ruby-git/commit/305626c11e9178ff7435aab331b66d6f332692ba))
* **repository:** Add Git::Repository::StatusOperations#ls_files facade method ([db89efa](https://github.com/ruby-git/ruby-git/commit/db89efa2bd6b2d2a9a4a2b596f4af19831f0227a))
* **repository:** Add Git::Repository::StatusOperations#no_commits? facade method ([949c5fa](https://github.com/ruby-git/ruby-git/commit/949c5fa642b227e5b0ec396106c48eb9a8a8ee8f))
* **repository:** Add Git::Repository::StatusOperations#status facade factory ([ba54363](https://github.com/ruby-git/ruby-git/commit/ba543636a4fff42eec7b5e65de77fb32d0e8edca))
* **repository:** Add Git::Repository::WorktreeOperations facade module ([a7bb5c3](https://github.com/ruby-git/ruby-git/commit/a7bb5c32e78815cefc45fee9128d3444ba7de8c8))
* **repository:** Add Git::Repository.clone and .init factory class methods ([3e9d4d2](https://github.com/ruby-git/ruby-git/commit/3e9d4d23d8fcde790a7a7c8bd13de59904207dd5))
* **repository:** Add Git::Repository.open/.bare factories and path state ([4d11f33](https://github.com/ruby-git/ruby-git/commit/4d11f3374adc6f88c076001dc85179872bf5e7fd))
* **repository:** Add Git::Repository#branch_new facade method ([93ec899](https://github.com/ruby-git/ruby-git/commit/93ec8995af1be3b79833d9c249c6566a434d7381))
* **repository:** Add Git::Repository#cat_file_commit facade method ([7a22502](https://github.com/ruby-git/ruby-git/commit/7a22502696751b7735c8ab2f51285f8beb1f63d1))
* **repository:** Add Git::Repository#cat_file_contents facade method ([97f74d2](https://github.com/ruby-git/ruby-git/commit/97f74d2d802dca6cfe27fcde71968c0f8395870a))
* **repository:** Add Git::Repository#cat_file_size facade method ([945738c](https://github.com/ruby-git/ruby-git/commit/945738cbff8be50a6129a2f4e73be8db8565909c))
* **repository:** Add Git::Repository#cat_file_tag facade method ([f95d3b3](https://github.com/ruby-git/ruby-git/commit/f95d3b3277da609e98e17cefa0ec230e7ca5b2c5))
* **repository:** Add Git::Repository#cat_file_type facade method ([f2351fb](https://github.com/ruby-git/ruby-git/commit/f2351fbf5569d36fdca2a38dcf2b5097b8e93f5e))
* **repository:** Add Git::Repository#config_remote facade method ([d28405f](https://github.com/ruby-git/ruby-git/commit/d28405f24e94c22f7e03b3e1ae9af73756445445))
* **repository:** Add Git::Repository#diff_full facade method ([21d4cac](https://github.com/ruby-git/ruby-git/commit/21d4cac77b6b680fc944246ae2fead346051d570))
* **repository:** Add Git::Repository#diff_index facade method ([ab41c39](https://github.com/ruby-git/ruby-git/commit/ab41c39aaa32162706e28402be3b87d5cb66dc2a))
* **repository:** Add Git::Repository#diff_numstat facade method ([474b869](https://github.com/ruby-git/ruby-git/commit/474b869ead8d9be9da6e3a1e98f4ec906b5222aa))
* **repository:** Add Git::Repository#full_log_commits facade method ([73ad1ba](https://github.com/ruby-git/ruby-git/commit/73ad1ba75603ccc5565e8ff7e16dbcc5b04dc6da))
* **repository:** Add Git::Repository#full_tree facade method ([e3e99fd](https://github.com/ruby-git/ruby-git/commit/e3e99fd8d68a14901576244b12d7427de61a4cdb))
* **repository:** Add Git::Repository#ls_tree facade method ([cd305d2](https://github.com/ruby-git/ruby-git/commit/cd305d22fe5527e5fd78dd06db5d38dd66be8070))
* **repository:** Add Git::Repository#merge_base facade method ([46abcef](https://github.com/ruby-git/ruby-git/commit/46abcef8ba26c1058eeb6e53696a8f491a6bbd6f))
* **repository:** Add Git::Repository#name_rev facade method ([2bca93f](https://github.com/ruby-git/ruby-git/commit/2bca93f5e5ae24cce968d274d0aa3bf80e58ae8f))
* **repository:** Add Git::Repository#pull facade method ([aef659a](https://github.com/ruby-git/ruby-git/commit/aef659a38ef50ce3063de251f9994b5b65bd936c))
* **repository:** Add Git::Repository#remove_remote facade method ([4582c2f](https://github.com/ruby-git/ruby-git/commit/4582c2f6b4bea69a32053867882d1892eb46c18b))
* **repository:** Add Git::Repository#rev_parse facade method ([6889f74](https://github.com/ruby-git/ruby-git/commit/6889f7449b5a69bbe3bfe74805d4b3ed716e2120))
* **repository:** Add Git::Repository#stash_apply facade method ([bb1dad5](https://github.com/ruby-git/ruby-git/commit/bb1dad531ec9daa01c5f38cdb295df1fd271aef6))
* **repository:** Add Git::Repository#stash_clear facade method ([643f32e](https://github.com/ruby-git/ruby-git/commit/643f32e6956c715412fb0d605e36ef8bf997ccfd))
* **repository:** Add Git::Repository#stashes_all facade method ([85cf0a0](https://github.com/ruby-git/ruby-git/commit/85cf0a0019c1d1bff86ab2de5be0019fadf2737c))
* **repository:** Add Git::Repository#tag_sha facade method ([e9f4bdd](https://github.com/ruby-git/ruby-git/commit/e9f4bdde2527689b38dbb844ee56fd38cb7fe217))
* **repository:** Add Git::Repository#untracked_files facade method ([cbe2d65](https://github.com/ruby-git/ruby-git/commit/cbe2d651404bcbe0fde44892f2d4986d429e2a57))
* **repository:** Add update_ref facade method with tests ([d88ec4e](https://github.com/ruby-git/ruby-git/commit/d88ec4e98cf55a0d7246e31052374898f08d3e10))
* **repository:** Add worktree and worktrees factory methods to WorktreeOperations ([bde5528](https://github.com/ruby-git/ruby-git/commit/bde5528a3c1524c715bcab2970fba9f4b48aff5c))
* **repository:** Extract Git::Base#fetch to Git::Repository::RemoteOperations ([e3a9b6e](https://github.com/ruby-git/ruby-git/commit/e3a9b6ef7c4de28d61cb4660a285a7dc36413a9d)), closes [#1266](https://github.com/ruby-git/ruby-git/issues/1266)
* **repository:** Extract Git::Base#merge to Git::Repository::Merging ([8a95be8](https://github.com/ruby-git/ruby-git/commit/8a95be89d4d7c0a204ef4190f03c4a9793f649f6))
* **repository:** Extract Git::Lib#archive as Git::Repository::ObjectOperations#archive ([0f81d42](https://github.com/ruby-git/ruby-git/commit/0f81d42c633e66a28766274a4581f5b8df998eda))
* **repository:** Extract Git::Lib#grep as Git::Repository::ObjectOperations#grep ([e42c18f](https://github.com/ruby-git/ruby-git/commit/e42c18fe7dd1b4a519fc2270bed6635caa3e2d0e))
* **repository:** Extract Git::Repository#branches_all from Git::Lib ([182ab41](https://github.com/ruby-git/ruby-git/commit/182ab41800ca5b315ed32f22bdef0276513acabd))
* **repository:** Extract tree_depth facade method ([ece713e](https://github.com/ruby-git/ruby-git/commit/ece713e0470f733b0f27398d8f4753493f96aeec))
* **repository:** Implement Git::Repository with Staging facade module ([f5e3271](https://github.com/ruby-git/ruby-git/commit/f5e32710fd2c3fe6938cc69650b027542a7946a3))
* **repository:** Implement Git::Repository::ContextHelpers (Step E) ([b3da4e3](https://github.com/ruby-git/ruby-git/commit/b3da4e32adf6ced5c390d82fa0b87f68c2ce47c0))
* **repository:** Migrate Git::Log to Git::Repository (iter 4B) ([6056ae1](https://github.com/ruby-git/ruby-git/commit/6056ae11ca47fd4beec8689c7dd92e79f8851e43))
* **repository:** Replace silent lib shim with deprecation warning ([1121278](https://github.com/ruby-git/ruby-git/commit/1121278538f8097d087ee7c72f42cd0fff8893b3))
* **skills:** Add rebase skill workflow ([01b8680](https://github.com/ruby-git/ruby-git/commit/01b8680bd11300db0943801d45ddbac07d710c97))
* **staging:** Add apply, apply_mail, and read_tree facade methods ([8a2828f](https://github.com/ruby-git/ruby-git/commit/8a2828f8055da47f9522fa01abda3fb14df2562a))
* **staging:** Add deprecated reset_hard wrapper to Git::Repository::Staging ([48f5cbe](https://github.com/ruby-git/ruby-git/commit/48f5cbebb375487aae4cc08d9acb75c84ac5f270))
* **staging:** Add Git::Repository::Staging#mv facade and Git::Base delegator ([0a0fd47](https://github.com/ruby-git/ruby-git/commit/0a0fd473f28e1dcf7a89ec7179b732dbddf48ddb))
* **staging:** Add rm, clean, and ignored_files facade methods ([0756fe3](https://github.com/ruby-git/ruby-git/commit/0756fe3d930e37783d994317b4f896ae5dd4318d))
* **tags:** Add tags, add_tag, and delete_tag facade methods ([ee3308f](https://github.com/ruby-git/ruby-git/commit/ee3308f15e2207bcc5963e5b6b19edd1e702030e))


### Bug Fixes

* **am:** Remove abort YARD lint exclusion ([84c016a](https://github.com/ruby-git/ruby-git/commit/84c016a7266c942fe3e3ef33eff3f9a080e387dc))
* Audit deprecation warning messages ([7de996a](https://github.com/ruby-git/ruby-git/commit/7de996a45b1850edd7e68337ec11e1d8cb7a386b))
* Avoid circular require warnings ([9d0e93c](https://github.com/ruby-git/ruby-git/commit/9d0e93c1a1ce75d814348d3f83ef252d988600db))
* **branch:** Delete remote-tracking refs correctly ([c44a0f4](https://github.com/ruby-git/ruby-git/commit/c44a0f46b1c46c83ea24a9f810c2157346129102)), closes [#1280](https://github.com/ruby-git/ruby-git/issues/1280)
* **branch:** Parse slash remote names ([6f8f43a](https://github.com/ruby-git/ruby-git/commit/6f8f43a7583d16cd1004eda714c493605bcadbfe))
* **branch:** Wire branch_list slash remote parsing ([e56913e](https://github.com/ruby-git/ruby-git/commit/e56913ea0107fb24bee7cd01d4881e4fcce91e1e))
* **ci:** Improve JRuby integration test hang visibility ([ce5267c](https://github.com/ruby-git/ruby-git/commit/ce5267c041ad8975953ea191258588db91b86cc2))
* **ci:** Pin i18n &lt; 1.15 on TruffleRuby &lt; 34.0.0 ([af25d3b](https://github.com/ruby-git/ruby-git/commit/af25d3b6e4c9e0097cb63de347c9a332c8e78283))
* **commands/diff:** Allow exit status 2 for git diff --check whitespace errors ([159902c](https://github.com/ruby-git/ruby-git/commit/159902c41119b6c3bbe83fcb3d3ea59fdb73af84))
* **commands:** Allow empty string for Tag::Create message option ([4923364](https://github.com/ruby-git/ruby-git/commit/4923364788d9cf390e3b89f2ec1a2971488e56e3))
* **commands:** Document option tags for rm show-ref and stash apply ([a0fdeb6](https://github.com/ruby-git/ruby-git/commit/a0fdeb6c3ddb1a5955d241e462eb47c51fe13c35))
* **commands:** Remove yard-lint exclusions for fetch/fsck/gc/grep/init ([8bd1bf7](https://github.com/ruby-git/ruby-git/commit/8bd1bf748fa20c773641c5aadddda19926aedda8))
* Correct deprecation messages for Git#config and Git#global_config mixins ([c1895a4](https://github.com/ruby-git/ruby-git/commit/c1895a43f5c2f8a0920b5cde51febe95fdb1b51c))
* **diff:** Return nil from DiffFile#blob(:src) for a null source SHA ([2e62492](https://github.com/ruby-git/ruby-git/commit/2e6249270a9c8f993201069a1f54e3883df37dbc))
* **docs:** Pad all markdown table separator cells to fix markdownlint MD055 ([3010608](https://github.com/ruby-git/ruby-git/commit/3010608d07e11c8aaf341271cdaf51ef4a266c6d))
* False value in config set/get and improve git.rb YARD docs ([6ba995c](https://github.com/ruby-git/ruby-git/commit/6ba995c229276e5d2e567d3202b10ec5d7d4b487))
* **git:** Delegate Git::Base#reset_hard through facade_repository ([46c1902](https://github.com/ruby-git/ruby-git/commit/46c190295c7dba830e8a4b0b48e6132454bbdac8))
* Inline deprecation and const_missing to fix YARD Git module overview ([a974be9](https://github.com/ruby-git/ruby-git/commit/a974be9d097388612dc95dfc9ef38d7d43575e8f))
* Parse grep output with null delimiters ([2dec93a](https://github.com/ruby-git/ruby-git/commit/2dec93aea71f103b4f91126b29329363867a964b))
* Reject :get_url and :symref in ls_remote to prevent parser corruption ([52d657d](https://github.com/ruby-git/ruby-git/commit/52d657d738d6f324640c7c18c219d866f6fa1682))
* **remote_operations:** Raise ArgumentError when :ref has no explicit remote ([#1291](https://github.com/ruby-git/ruby-git/issues/1291)) ([0391a00](https://github.com/ruby-git/ruby-git/commit/0391a00b673e74c968d593b9627b915bba7bab08))
* **repository:** Align 6 facade signatures with 4.x legacy contracts ([e472bbb](https://github.com/ruby-git/ruby-git/commit/e472bbb9747cf5489ad96e95d051b5e971b27e35))
* **repository:** Cat_file_tag handles annotated tags with an empty message ([e453775](https://github.com/ruby-git/ruby-git/commit/e453775ae55fdbadea08fbbbe0a0055917b6957b))
* **repository:** Inline deprecated config facade methods ([230a1dc](https://github.com/ruby-git/ruby-git/commit/230a1dc378c06d5c0dcaec72d3e86845c99e3c29))
* **repository:** Map nil commitish to HEAD in revert; add integration tests ([97a902e](https://github.com/ruby-git/ruby-git/commit/97a902e5968095ac12227b7b26ce31e624f4b2b9))
* Rescue Errno::ESRCH from process_executer timeout race (Ruby 4.0+) ([030f017](https://github.com/ruby-git/ruby-git/commit/030f0173a562a540cab2bd7446aa9f4733961fdd))
* Restrict factory methods to Git module only ([ef9b9cf](https://github.com/ruby-git/ruby-git/commit/ef9b9cf6cd267e57b2cbc9f0dbe84e2eeb66ddb2))
* **staging:** Remove false-stripping workaround from add ([5116a5b](https://github.com/ruby-git/ruby-git/commit/5116a5bd7ce3853d367ae30525240767048e8370))
* **test:** Use crontab scheduler in maintenance start integration spec ([da7aa8d](https://github.com/ruby-git/ruby-git/commit/da7aa8d8ef20fa5cf2656ab01ac7f8e910c391d7))
* Update deprecation horizon ([0414398](https://github.com/ruby-git/ruby-git/commit/0414398e98f84234d23277fae91fa84d421f9748))
* **yard:** Remove selected undocumented-options exclusions ([6787d2a](https://github.com/ruby-git/ruby-git/commit/6787d2aa7061f16cc9484b1d6d17191594a74cc6))
* **yard:** Resolve command documentation lint offenses ([5217b62](https://github.com/ruby-git/ruby-git/commit/5217b62c7d15bac02c4a5f6ac17bd962e13db1c9))


### Other Changes

* Add archive YARD examples ([6f9ae0a](https://github.com/ruby-git/ruby-git/commit/6f9ae0a6c804d17c529cbf7cd0e3a6e06cf6c6e3))
* Add beta release process guide ([fe78a77](https://github.com/ruby-git/ruby-git/commit/fe78a77a55d0e3e6c26fa56ff35e99601139cedb))
* Add branch_parse_refactor_plan to redesign/ ([9524654](https://github.com/ruby-git/ruby-git/commit/95246546039d4207627c7a1b71a8079b5e9b242d))
* Add Bucket 6 decision brief, UPGRADING guide, and beta install docs ([626f294](https://github.com/ruby-git/ruby-git/commit/626f29423c31352c8c9cf294b199a59bd49de8c3))
* Add config design document for Git::Configuring module ([dccdb6d](https://github.com/ruby-git/ruby-git/commit/dccdb6d999b6026322252c5bdac97ed3da5e8e3e))
* Add effort and completion columns to redesign progress tracker ([0537da6](https://github.com/ruby-git/ruby-git/commit/0537da66abebbf2f1ec8738abc19b4336f39903a))
* Add execution_context_double and stub_git_version helpers ([17c486d](https://github.com/ruby-git/ruby-git/commit/17c486d8af0ef083b48527e17763cc85c9591cc0))
* Add full YARD docs to Git::Commands::Arguments and remove from exclusions ([10e1f2d](https://github.com/ruby-git/ruby-git/commit/10e1f2d59bd7af321da2b3ed9a31cbe79c908b85))
* Add Git::Diff#patch polymorphism for Git::Repository ([99a63fb](https://github.com/ruby-git/ruby-git/commit/99a63fbb67c4866a60adbea7ec32b248ba71ce3b))
* Add init_test_repo helper to Git::IntegrationTestHelpers ([11f173a](https://github.com/ruby-git/ruby-git/commit/11f173a1fa6afe1814da0c0e2c50d7bb397b921d)), closes [#1467](https://github.com/ruby-git/ruby-git/issues/1467)
* Add integration test analysis document ([e2c4cec](https://github.com/ruby-git/ruby-git/commit/e2c4cecaee7d050dc8cb75a5ea1151acf551a57b))
* Add measured CI results to integration_test_analysis.md ([7f53ef8](https://github.com/ruby-git/ruby-git/commit/7f53ef866f02dd686594783f6f630804f3e15c57))
* Add Phase 4 Step A execution plan ([61e4556](https://github.com/ruby-git/ruby-git/commit/61e45562d346b5676355bfc8c6c0e497b8d9d875))
* Add prompt to iteratively address Copilot PR reviews ([05f1c03](https://github.com/ruby-git/ruby-git/commit/05f1c03c2583b0818c610e4e09f298e9c80582ca))
* Add RemoteInfo + RemoteOperations refactor plan ([bda2063](https://github.com/ruby-git/ruby-git/commit/bda2063a7834d4a1e323ebc89ef3414766344be8))
* Add resolve-feedback skill ([6bef759](https://github.com/ruby-git/ruby-git/commit/6bef759b31e9276de7a5b61af18ac7dadf4b32f0))
* Add reverse dependency query ([21c9977](https://github.com/ruby-git/ruby-git/commit/21c9977dc0fdb5c02522ff520eb596460fed811d))
* Add spec:unit hang diagnostics for JRuby ([#1286](https://github.com/ruby-git/ruby-git/issues/1286)) ([52d00cb](https://github.com/ruby-git/ruby-git/commit/52d00cb0c87f6476454d4e49f6708537af64208f))
* Add W6 plan for removing stale Git::Base/Git::Lib skill refs ([9f4482d](https://github.com/ruby-git/ruby-git/commit/9f4482d29d6b5867b74838f1335cf63ce20d2883))
* Add YARD docs to CommandLine::Capturing and Streaming private methods ([e7e8a95](https://github.com/ruby-git/ruby-git/commit/e7e8a95a561c680f46f3f44afc3bb18a098e96d3))
* Add YARD docs to Git::Author and remove from yard-lint exclusions ([cabc21b](https://github.com/ruby-git/ruby-git/commit/cabc21b0e5faa8ec2305bea9cb7493ae038c48a4))
* Add YARD docs to undocumented methods in git.rb ([2bb8218](https://github.com/ruby-git/ruby-git/commit/2bb82188fccd5c8a676108cad69b7220f6848a2c))
* **add:** Remove yard-lint todo exclusion ([000c0f0](https://github.com/ruby-git/ruby-git/commit/000c0f080bec5e30c3a257ca782989f4c6d77bbe))
* Advance iteration tracker — mark iter 8 complete, set iter 9 as next ([63fe469](https://github.com/ruby-git/ruby-git/commit/63fe4690f884ad1772a303794efe3e26bea1b3b3))
* Align skill tag-order examples with Tags/Order config ([ac9f83a](https://github.com/ruby-git/ruby-git/commit/ac9f83a6c50637c89e473e5a484aa3a43d0e38af))
* **am:** Remove apply yard-lint todo exclusion ([670a35c](https://github.com/ruby-git/ruby-git/commit/670a35c4fef9b702ec3d084a3e6ef130b4ccc7ac))
* **am:** Remove yard-lint todo exclusion for continue ([470d203](https://github.com/ruby-git/ruby-git/commit/470d20395bcdcd90d866b91041418362c0b94013))
* **base:** Delegate add_remote to Git::Repository ([9170bc6](https://github.com/ruby-git/ruby-git/commit/9170bc6db4877dbd1568ae3f5513e0b49458225c))
* **base:** Delegate each_conflict to Git::Repository ([6515d75](https://github.com/ruby-git/ruby-git/commit/6515d7593076c865cd67f100819b9ca4e2ff46f6))
* **base:** Delegate full_log_commits to Git::Repository ([de3d43c](https://github.com/ruby-git/ruby-git/commit/de3d43c384196b09a577d6b79e904bef317b0721))
* **base:** Delegate Git::Base#diff_files to Git::Repository ([ef3114f](https://github.com/ruby-git/ruby-git/commit/ef3114f536996f5d28ce375a9faeccc159acc2dc))
* **base:** Delegate Git::Base#ls_files and #config to facade_repository ([f2b1c72](https://github.com/ruby-git/ruby-git/commit/f2b1c723ed1a5531f27a73db35cc7a64a06e1c14))
* **base:** Delegate Git::Base#push to Git::Repository facade ([ca307b3](https://github.com/ruby-git/ruby-git/commit/ca307b3a4e496a47a21a2c06307cdae547ffe8e5))
* **base:** Delegate ls_tree to Git::Repository ([1b0c63c](https://github.com/ruby-git/ruby-git/commit/1b0c63cf57e8e315841e279f58655783f00c4b88))
* **base:** Delegate pull to Git::Repository ([4a60de2](https://github.com/ruby-git/ruby-git/commit/4a60de20412befa6831d00f0a6aea42b8dfc2fd8))
* **base:** Delegate remove_remote to Git::Repository ([536668b](https://github.com/ruby-git/ruby-git/commit/536668bed795be047ce68211039ef8e4315541b7))
* **base:** Delegate revert to Git::Repository ([739f627](https://github.com/ruby-git/ruby-git/commit/739f627368fc68b1efcd52e41e3e6fef8a40729f))
* **base:** Delegate update_ref to Git::Repository ([cdcd5b8](https://github.com/ruby-git/ruby-git/commit/cdcd5b87e90454628ee0f67917b25c186be86123))
* **branches:** Add unit and integration coverage for Git::Branches ([049b6f5](https://github.com/ruby-git/ruby-git/commit/049b6f5f81a038066b4995f8144d969946345718))
* **branches:** Finalize facade module docs and tests ([36f6e80](https://github.com/ruby-git/ruby-git/commit/36f6e80dbf7659bf58ef102588a6e1fc40c5a238))
* **branches:** Migrate Git::Branches to repository-polymorphic access ([d1019ba](https://github.com/ruby-git/ruby-git/commit/d1019ba84b5b846b135dbe61220c38fbf58388cc))
* **branch:** Redesign BranchInfo value object ([a6875ea](https://github.com/ruby-git/ruby-git/commit/a6875eaf9d743d6c31f3776afed38afc4cef443b))
* **branch:** Remove parser baseline exclusion and add module docs ([3562543](https://github.com/ruby-git/ruby-git/commit/35625433aabbfae692d43b78b4f7c107dfb681ac))
* **branch:** Remove yard-lint todo exclusions for branch commands ([df774bc](https://github.com/ruby-git/ruby-git/commit/df774bce745fff7f092ef1ac3b8f58ad0b8bfcdc))
* Centralize execution-context option defaulting ([283a3ab](https://github.com/ruby-git/ruby-git/commit/283a3abe99a66c260b64b81d4eecf244d0cccdb2))
* **ci:** Update GitHub Actions dependencies to latest major versions ([c73088f](https://github.com/ruby-git/ruby-git/commit/c73088f59bafc25d5eaaae4af763c7085b77e2c9))
* Clarify documentation for nested state/path classes in facade modules ([0d26303](https://github.com/ruby-git/ruby-git/commit/0d263037dafa26bbe9feca3e4b634adcf15adba8))
* Clarify Phase 3 PR slicing, release lanes, and backward-compat rules ([a5b9291](https://github.com/ruby-git/ruby-git/commit/a5b9291ffbd6d5578c812f50ba6e3d8ed03f043f))
* **command_line:** Port logger output examples to capturing_spec ([5236085](https://github.com/ruby-git/ruby-git/commit/5236085a67a980cbe8452b0ac8d809b4067f3bb0))
* **command_line:** Port normalize: false byte-preservation example ([2bbaf58](https://github.com/ruby-git/ruby-git/commit/2bbaf58add144cd4c6b2d0f676b2a67b6a53cb9b))
* **commands:** Apply command-implementation skill to grep; backfill log options ([6e0da11](https://github.com/ruby-git/ruby-git/commit/6e0da117d5e93c9e604e98d933073d84901ff73b))
* **commands:** Audit config_option_syntax YARD docs (issue [#1196](https://github.com/ruby-git/ruby-git/issues/1196)) ([70ce8e2](https://github.com/ruby-git/ruby-git/commit/70ce8e26598f19865e526226ffd33b9e57a46a8e))
* **commands:** Audit YARD docs for archive/list_formats, version, worktree/add/list/lock ([2b29f54](https://github.com/ruby-git/ruby-git/commit/2b29f54353df3708eb3d6ed4bf57f96931bd8604))
* **commands:** Complete config_option_syntax YARD audit and spec updates (issue [#1196](https://github.com/ruby-git/ruby-git/issues/1196)) ([3ad2365](https://github.com/ruby-git/ruby-git/commit/3ad236589db587d03b9d106c6eb31e6c67cf66f5))
* **commands:** Define explicit call methods for YARD option docs ([c71e3a1](https://github.com/ruby-git/ruby-git/commit/c71e3a101878222cf3a3d4163b575f38f58f70c5))
* **commands:** Migrate all negatable options to no_{flag} companion key ([#1260](https://github.com/ruby-git/ruby-git/issues/1260)) ([204ca2a](https://github.com/ruby-git/ruby-git/commit/204ca2ab5abb8c5b6b1c6a5d5f505e2bbf54df7d))
* **commands:** Remove YARD todo exclusions for selected command files ([42e3867](https://github.com/ruby-git/ruby-git/commit/42e3867040ce350be91cc1990721943d719d3646))
* **commands:** Remove yard-lint exclusions for call docs ([c65a4dc](https://github.com/ruby-git/ruby-git/commit/c65a4dc19398da4e425e4ba2c3cb87b0e3cf33a3))
* **commands:** Remove yard-lint exclusions for merge and mv ([7504a8b](https://github.com/ruby-git/ruby-git/commit/7504a8beb6181dd86f3552aa7b6979180849e3b6))
* **commands:** Remove yard-lint todo exclusions for symbolic-ref and tag ([6c37035](https://github.com/ruby-git/ruby-git/commit/6c3703520dca084c23966ac11253006ce315f452))
* **commands:** Remove yard-lint todo exclusions for worktree and version ([65403e5](https://github.com/ruby-git/ruby-git/commit/65403e530be1a82acc2864e2aacfd201b62eb507))
* **commands:** Unbaseline and fix YARD docs for remote/reset/repack/rev-parse ([9109c91](https://github.com/ruby-git/ruby-git/commit/9109c91155412fac45f5383c31d2bc91da53b795))
* **commands:** Update Checkout namespace module per implementation skill ([f1fec1f](https://github.com/ruby-git/ruby-git/commit/f1fec1f352e69f99d3fc9268e144ad19b09478ea))
* **commands:** Update Checkout::Branch command class per implementation skill ([fb19d53](https://github.com/ruby-git/ruby-git/commit/fb19d5308bc9803e57d44f7e6f5d95d75e35a24c))
* **commands:** Update Checkout::Files command class per implementation skill ([ca2fea5](https://github.com/ruby-git/ruby-git/commit/ca2fea567720496a57f859463f97d6c0224fbb70))
* **commands:** Update CheckoutIndex command class per implementation skill ([f301e1d](https://github.com/ruby-git/ruby-git/commit/f301e1d99257bb45d7169cc229dd06217831f088))
* **commands:** Update Clean command class per implementation skill ([12132be](https://github.com/ruby-git/ruby-git/commit/12132be8c722c12e85a65dfda233adc822635fa7))
* **commands:** Update Clone command class per implementation skill ([64dad0c](https://github.com/ruby-git/ruby-git/commit/64dad0cc36e441f4dbb749a50378d4a8c263b605))
* **commands:** Update command-layer YARD to reference Git::Repository/ExecutionContext ([9e773a0](https://github.com/ruby-git/ruby-git/commit/9e773a09957716aca8848435588f7e58ad0a8cd7))
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
* **commands:** Update Init command class per implementation skill ([5eb536a](https://github.com/ruby-git/ruby-git/commit/5eb536abd171ed68f58d61d0f58e93769fd99629))
* **commands:** Update ls-files, ls-remote, ls-tree per implementation skill ([4fef064](https://github.com/ruby-git/ruby-git/commit/4fef06435ca68b353c1c84eebad6d18f4111f1a6))
* **commands:** Update merge-base, mv, name-rev, pull, push per implementation skill ([96bc933](https://github.com/ruby-git/ruby-git/commit/96bc933576de457299e6cd7cf45c5a5336832b37))
* **commands:** Update read-tree, repack, reset, rev-parse, rm (batch 7) ([9460450](https://github.com/ruby-git/ruby-git/commit/946045098a1685308efd01c6fd83b395a4548906))
* **commands:** Update show, status, tag per implementation skill (batch 7) ([de1064a](https://github.com/ruby-git/ruby-git/commit/de1064a36d5ff010715403a15a300ffd8209b194))
* **commands:** Update symbolic-ref, tag/verify, write-tree (batch 7) ([9977656](https://github.com/ruby-git/ruby-git/commit/99776565c9b159fef672561a3b519cb719a752ab))
* **commands:** Update worktree/move, prune, remove, repair per implementation skill ([fe33764](https://github.com/ruby-git/ruby-git/commit/fe337641686da76655f522e57001c4827460ed29))
* **config-option-syntax:** Remove yard-lint todo exclusions ([b44d764](https://github.com/ruby-git/ruby-git/commit/b44d764bcbae4e29d8559856e073b3c3c17636cc))
* **config:** Add integration tests pinning 4.x-equivalent behavior ([f05e31f](https://github.com/ruby-git/ruby-git/commit/f05e31fb6ab5ba4091e190136ba6343c88ddf6fb))
* **config:** Move global config singleton ownership to Git::Config (Step C1b) ([e8bf00f](https://github.com/ruby-git/ruby-git/commit/e8bf00f89fca6eb847394ea416a0add1749f5db9))
* **contributing:** Document and enforce local development setup ([e33d6c6](https://github.com/ruby-git/ruby-git/commit/e33d6c6c0a1f57173f21092a8fbe0fd6893d7d41)), closes [#1297](https://github.com/ruby-git/ruby-git/issues/1297)
* Cover merge BranchInfo coercion ([413074b](https://github.com/ruby-git/ruby-git/commit/413074b910e895253efaaa4a7a170b3bddcf0d41))
* Create Phase 4 Step C execution plan ([38cc2fd](https://github.com/ruby-git/ruby-git/commit/38cc2fd692f605efaf68dd4bd96a9f52ecccdac4))
* Define fine-grained PR granularity for Phase 4 Step C ([541bb94](https://github.com/ruby-git/ruby-git/commit/541bb942ba1103728863d7f563e290d7bc6c8abc))
* Delegate Git::Base domain-object factories to facade_repository ([e8f2266](https://github.com/ruby-git/ruby-git/commit/e8f22665b8e070358ac123466c2dcd2fde2417e6))
* Delegate Git::Base#diff to facade_repository ([306f5a3](https://github.com/ruby-git/ruby-git/commit/306f5a3dcb79cede49d61626c2d65b52648d648d))
* Delete confirmed-removable Test::Unit files (Phase 4 PR 3a) ([f07e735](https://github.com/ruby-git/ruby-git/commit/f07e735c7710c93dee8dad06943cb9b702491048))
* Delete RSpec specs that only test Git::Base and Git::Lib (PR 3c) ([457e066](https://github.com/ruby-git/ruby-git/commit/457e06690155254dbbeb155b07854b6791510ccb))
* Deprecate finished extract-* skills ([2064b2a](https://github.com/ruby-git/ruby-git/commit/2064b2aacf601280b140687d9082f5b4a33633ea))
* Deprecate Git module mixin methods #config and #global_config ([5fc672b](https://github.com/ruby-git/ruby-git/commit/5fc672bc7b3511fb96d4a4ed401c4a86238f2e85))
* Deprecate Git::CommandLineResult in favor of Git::CommandLine::Result ([c307ef3](https://github.com/ruby-git/ruby-git/commit/c307ef3f2b60d2b59fd05628387f2795c718eb5d))
* Deprecate legacy git version methods (closes [#1193](https://github.com/ruby-git/ruby-git/issues/1193)) ([02a7514](https://github.com/ruby-git/ruby-git/commit/02a75147a46aeef0f049d21f50b6572c096a1b64))
* **diff:** Document DiffPathStatus initialize args ([7a29252](https://github.com/ruby-git/ruby-git/commit/7a29252e658ce8f506ebf9808a0956f785a0b7d6))
* **diff:** Port W2-U3 diff unit rows to RSpec ([e1eb4f0](https://github.com/ruby-git/ruby-git/commit/e1eb4f041ce4319fc53d771696244254d8cf879d))
* **diff:** Port W2-U4 diff remainder rows to RSpec ([65c244c](https://github.com/ruby-git/ruby-git/commit/65c244c05ab2d5ef0b19f5c2ee7b6e78da69255b))
* Display rake command in task header for easy copy-paste ([15560a7](https://github.com/ruby-git/ruby-git/commit/15560a71326665910297d28b36e67e72f0900127))
* Document [@api](https://github.com/api) private cache helper and Deprecation constant ([be54e0d](https://github.com/ruby-git/ruby-git/commit/be54e0dc5cef6ad611760522e8cfff1d0d3694be))
* Document arbitrary keyword YARD convention ([a0007e9](https://github.com/ruby-git/ruby-git/commit/a0007e948e1689217d41eff2df844da4cadc77c3))
* Document Array&lt;&gt; vs Array() type distinction in yard skill ([cf18947](https://github.com/ruby-git/ruby-git/commit/cf18947b1901c043a097bb674e2b867c220ae4a2))
* Document branch archive options ([f933bb1](https://github.com/ruby-git/ruby-git/commit/f933bb137877bc9830b068d35bd9890cd590e380))
* Document Configuring config options ([c82867e](https://github.com/ruby-git/ruby-git/commit/c82867e9e4a7d219b429151243680574211ddb0d))
* Document encoding utils and remove YARD TODO exclusions ([5b4e89a](https://github.com/ruby-git/ruby-git/commit/5b4e89a5e7c459ba4c5b9303f848c6ffe1345f9e))
* Document Git object YARD lint coverage ([f96e389](https://github.com/ruby-git/ruby-git/commit/f96e3895574a19bac3cda12968c1f9de1b94f734))
* Document Git::Config readers ([2421466](https://github.com/ruby-git/ruby-git/commit/24214661bf8e2ba36084ec96688c595bec0f878f))
* Document Git::Log path filtering upgrade note ([c2043f9](https://github.com/ruby-git/ruby-git/commit/c2043f9777c58f997a4e389582aace7dbcab10e7))
* Document stricter option validation ([5f8f9b0](https://github.com/ruby-git/ruby-git/commit/5f8f9b03c841d52db0f718b66afba9ef0c2ad855))
* Enforce a blank line between YARD tags ([b900d9f](https://github.com/ruby-git/ruby-git/commit/b900d9f4a4899ee5f31ecce2a32bc04e087e1382))
* Enrich Phase 4 Step B audit matrix (W1.5) ([5b48be9](https://github.com/ruby-git/ruby-git/commit/5b48be90a22d815001dbb7c9c0cfac5b70f32046))
* **errors:** Add command_line_error_spec for #initialize and #to_s ([7ab11d7](https://github.com/ruby-git/ruby-git/commit/7ab11d7dce6ca291410d91854c6ae088b705fcbb))
* **errors:** Add timeout_error_spec for #initialize and #to_s ([29aaf0f](https://github.com/ruby-git/ruby-git/commit/29aaf0f311b754bbcf7166779aa57c37023bf5eb))
* **execution-context:** Finalize W2-U6 ExecutionContext, path, and clone-log coverage ([d7ee1e6](https://github.com/ruby-git/ruby-git/commit/d7ee1e6cd953f900290d50692cc3edfb39797d8f))
* **execution-context:** Port W2-U5 env_overrides rows to RSpec ([cf5a0d5](https://github.com/ruby-git/ruby-git/commit/cf5a0d5a8f80754d35199e020b535630376584d2))
* Expand UPGRADING.md with comprehensive v5.0.0 migration guide (C2a) ([fb66404](https://github.com/ruby-git/ruby-git/commit/fb66404a8b7b1eac35fb41376c54a675f67c555b))
* Extract output parsers from ObjectOperations::Private to Git::Parsers ([5f312fe](https://github.com/ruby-git/ruby-git/commit/5f312feb0d784b56310b8321d408d2beb55d67b7))
* Fix commands base YARD lint ([4aac838](https://github.com/ruby-git/ruby-git/commit/4aac838fbc57a45c9184a9571dea352eedd817f5))
* Fix DiffPathStatus#fetch_path_status to support Git::Repository ([42892b3](https://github.com/ruby-git/ruby-git/commit/42892b3369da734f2f00f4044310f9d5e2686b0f))
* Fix Documentation/BlankLineBeforeDefinition offense in diff_info.rb ([175edba](https://github.com/ruby-git/ruby-git/commit/175edbafc192341c4bb52683419f3b2ae5a2b0eb))
* Fix Documentation/OrphanedDocComment offenses ([5ace823](https://github.com/ruby-git/ruby-git/commit/5ace823ec1acafc1f1dee50202a2625a942338d6))
* Fix execution context YARD option docs ([b1b3f9b](https://github.com/ruby-git/ruby-git/commit/b1b3f9bd5ae2cbe32b84309e21e963aea8ba70f9))
* Fix repository execution context yard docs ([d8c6e49](https://github.com/ruby-git/ruby-git/commit/d8c6e490643d266781c5e6113b551064b5f3cb2e))
* Fix rubocop offenses in object_operations_spec.rb ([ad7594b](https://github.com/ruby-git/ruby-git/commit/ad7594bff4362d49b02b151a07f61089a9c3018e))
* Fix stale plan entries and add missing commands to redesign tracker ([996b032](https://github.com/ruby-git/ruby-git/commit/996b0321f98bfdf46bbc52761e7bde3375cd3fb2))
* Fix Tags/ExampleSyntax offenses ([c48ca8c](https://github.com/ruby-git/ruby-git/commit/c48ca8c39b6df8f470db6f15d9fbe8f04263f7cc))
* Fix Tags/InformalNotation offenses ([6670c97](https://github.com/ruby-git/ruby-git/commit/6670c975a190805540b794160f3ab52299dc929c))
* Fix Tags/InvalidTypes offenses ([017153c](https://github.com/ruby-git/ruby-git/commit/017153c1b64d33d8693cfddf129ce563b290faa7))
* Fix Tags/Order offenses across lib/ ([8eb498e](https://github.com/ruby-git/ruby-git/commit/8eb498e5a52ae4f71ec31f4e0e7e191dcb9e6902))
* Fix Tags/RedundantParamDescription in CommandLine::Base ([e4418f2](https://github.com/ruby-git/ruby-git/commit/e4418f23d9e14c4048e87bdb5fb4b512c06c2bab))
* Fix Tags/TagSeparator offenses across lib/ ([c22c700](https://github.com/ruby-git/ruby-git/commit/c22c70004b2756efb750e67b072c9e3ac3861141))
* Fix Tags/TagTypePosition offenses in Git module ([0b7c2b9](https://github.com/ruby-git/ruby-git/commit/0b7c2b9addc71fd69f78e4d0170bc058ef38f1a9))
* Fix Tags/TypeSyntax offenses ([65c096a](https://github.com/ruby-git/ruby-git/commit/65c096a681284e73817d45901076a19cec7ff623))
* **git:** Migrate F1 ls-remote utilities off Git::Lib ([38e5d3d](https://github.com/ruby-git/ruby-git/commit/38e5d3d6814ef9bf72324e9fc02db8061b188a14))
* **git:** Migrate F2 config utilities off Git::Lib ([2e94e2b](https://github.com/ruby-git/ruby-git/commit/2e94e2b7f35e641a340c1d1ddf62ce2f0e177f58))
* **git:** Migrate Git.global_config and Git#config off Git::Lib ([3657e94](https://github.com/ruby-git/ruby-git/commit/3657e94485f709ca2601bff63b718be05aee049f))
* **git:** Rewire Git.default_branch off Git::Base (Phase 4 PR 1a) ([9b8a27d](https://github.com/ruby-git/ruby-git/commit/9b8a27d48dc808aaf4bd4d9bae5a33c5f91a136e))
* **git:** Rewire Git.git_version off Git::Lib (Phase 4 PR 1b) ([b961ec0](https://github.com/ruby-git/ruby-git/commit/b961ec01d97edd273ba9da839d9724108f5a1115))
* Harden Phase 4 Step C plan for executability and accuracy ([a5692f5](https://github.com/ruby-git/ruby-git/commit/a5692f50e6b5358daa7d4fef4ff404702cbbc741))
* Improve Phase 3 plan agent-discoverability and PR tracking ([b2a813d](https://github.com/ruby-git/ruby-git/commit/b2a813d47aad5f812e7ce16190ac18c2ef027df8))
* Improve skill authoring review guidance ([b9c25c9](https://github.com/ruby-git/ruby-git/commit/b9c25c942675da40a811fef61961287d6fd99164))
* Improve YARD documentation for Git::Branch ([#1277](https://github.com/ruby-git/ruby-git/issues/1277)) ([92c2bf2](https://github.com/ruby-git/ruby-git/commit/92c2bf24b1750b03e118e275fcd70a72c4e6afaf))
* **integration:** Fix Git::Log#first deprecation in branching_spec ([6f83fbc](https://github.com/ruby-git/ruby-git/commit/6f83fbc63f3f5b4da263923dcc32386d86c1ba5e))
* **lib:** Add [@api](https://github.com/api) private YARD tags to 12 internal plumbing methods ([9c760a1](https://github.com/ruby-git/ruby-git/commit/9c760a183b043d786d283bbed6daf3ec95cdf4f8))
* **lib:** Remove FORMAT_STRING from Git::Lib#branch_contains for 4.x compat ([5621d34](https://github.com/ruby-git/ruby-git/commit/5621d3422137b7525920132e63196b428c24e337))
* **logging:** Remove yard-lint todo exclusions ([c8cbc71](https://github.com/ruby-git/ruby-git/commit/c8cbc7164ac39d7e4feacd64267b9180a5c6f8cf))
* **log:** Port W2-U10 Log#execute snapshot semantics; dedup test_log_execute.rb ([939a616](https://github.com/ruby-git/ruby-git/commit/939a61603169cc2b5ff24a8f7115aace4b8951ff))
* **log:** Port W2-U8 Log deprecation and max_count/all coverage to RSpec ([567e4ac](https://github.com/ruby-git/ruby-git/commit/567e4ac3f57c6607260cc2f9e343fc9348e89c21))
* **log:** Port W2-U9 Log query-builder and Result#to_s coverage to RSpec ([fd7982b](https://github.com/ruby-git/ruby-git/commit/fd7982b038e3838779ab15d3abded9a030834e12))
* **log:** Remove YARD todo exclusions and document log API ([5f33710](https://github.com/ruby-git/ruby-git/commit/5f33710a5a406e5196ef59bc293119903121b597))
* Loosen yard-lint dependency constraint to ~&gt; 1.8 ([b582f00](https://github.com/ruby-git/ruby-git/commit/b582f00feda848bd46e2e9f205026be1f294378f))
* Mark Git::Object::* migration complete in tracker ([e690474](https://github.com/ruby-git/ruby-git/commit/e69047482662b241fda99f42019ddc2e8df67f44))
* Mark Git::Worktree as complete in iter 9 checklist ([bdf4bf2](https://github.com/ruby-git/ruby-git/commit/bdf4bf2f4ccd35bf386d691232a34b89d9db3c34))
* Mark iter 5 complete, advance Next Task to iter 6 ([93ffbde](https://github.com/ruby-git/ruby-git/commit/93ffbde4affe77e925e47f57d9db45a579d7366f))
* Mark Phase 4 Step B complete after W5 gate passes ([e5ed0e4](https://github.com/ruby-git/ruby-git/commit/e5ed0e434b44c2bd18e57a4a5358ac11ff7c1b21))
* Mark Phase 4 Step B complete with W6 merged (PR 1509) ([06997ab](https://github.com/ruby-git/ruby-git/commit/06997aba34074fec6c58577e0387a0f20cbd90b6))
* Mark Phase 4 Step C C1c complete in redesign tracker ([1aa268e](https://github.com/ruby-git/ruby-git/commit/1aa268e8b584848f956e087ce571e2aab38abedb))
* Mark Phase 4 Step C C2a complete in redesign tracker ([5bc4809](https://github.com/ruby-git/ruby-git/commit/5bc480982b0c70ccdc5f03694b1ed6d6f87d5496))
* Mark redesign Step A3 complete ([a306c7e](https://github.com/ruby-git/ruby-git/commit/a306c7e81044d68acd0ea9f7f4d844f84704e8d0))
* Mark Step B (Base factory delegation) complete in redesign plan ([c6fd2b8](https://github.com/ruby-git/ruby-git/commit/c6fd2b8c967eb12772c2e96d9f408de3fb558c69))
* Mark Step C1a-1 complete and update Phase 3 progress to 50% ([b2e1602](https://github.com/ruby-git/ruby-git/commit/b2e1602ad2cc6eef6e72a39a694c3b42ccd6803e))
* Mark Step C1c-2 complete in implementation plan ([10937df](https://github.com/ruby-git/ruby-git/commit/10937df2d8b24bb58403b370d3b66a7276ff3eb2))
* Migrate from_base and base_object references in RSpec (Phase 4 PR 3d) ([a9035b0](https://github.com/ruby-git/ruby-git/commit/a9035b0d010acac3f2a94c13cdc202f9dbb68aa2))
* **object_operations:** Fix tag_add third overload YARD docs ([be7e111](https://github.com/ruby-git/ruby-git/commit/be7e11132321678881e948cb75c486964e03be4a))
* Phase 4 step C3 — documentation completeness verification ([e0fba71](https://github.com/ruby-git/ruby-git/commit/e0fba71c41947457d1c018273f43284890a703a4))
* Port W2-U12 object/repository/remote miscellaneous coverage to RSpec ([7bf9ad0](https://github.com/ruby-git/ruby-git/commit/7bf9ad03f9b7430f6bf1b75ad6cbfcd3abf9a4ac))
* Port W2-U13 committing/staging miscellaneous coverage to RSpec ([1c62815](https://github.com/ruby-git/ruby-git/commit/1c62815839e1f9a8a7585491b899a58f97f0f4d2))
* Port W2-U14 FsckObject and FsckResult unit coverage to RSpec ([611c547](https://github.com/ruby-git/ruby-git/commit/611c5474dfee77891115b657123c9f20d2b5df8c))
* Port W2-U15 Git::Status collection methods and ignore-case boolean coverage ([22d5e9a](https://github.com/ruby-git/ruby-git/commit/22d5e9ae550f29c2cc952af72872d4fe02f33502))
* Port W2-U16 StatusFileFactory merge scenarios and DiffPathStatus empty-path coverage ([50e1621](https://github.com/ruby-git/ruby-git/commit/50e16210fbdcca664955aa2ea006faa038eded95))
* Port W2-U17 StatusFileFactory file3 staged scenarios and empty-repo StatusFileFactory coverage ([a17483f](https://github.com/ruby-git/ruby-git/commit/a17483f3f99692bcf2eb14fa308b4eeddcc7c430))
* Port W2-U18 remaining empty-repo factory, EscapedPath, and DiffStats empty-array coverage ([37e19e4](https://github.com/ruby-git/ruby-git/commit/37e19e408176ab23cfee350e19a64300b5bfe748))
* Port W2-U19 CommandLine subprocess, diff encoding, and bare-repo integration coverage ([421a626](https://github.com/ruby-git/ruby-git/commit/421a626c811fecd4c115573090277de6a68d9beb))
* Port W2-U20 integration tests (branch, checkout, commit, config, push, rm, set_index) ([c7fe3b3](https://github.com/ruby-git/ruby-git/commit/c7fe3b3a84ee9d183c5a83e2579e45e5363b6c55))
* Port W2-U21 stash, status, submodule, worktree, thread-safety, and SSH-signed commit coverage ([6d9af7d](https://github.com/ruby-git/ruby-git/commit/6d9af7d8538c2ac29330e87aea37847ce578fc23))
* Produce C1a public API scope TSV (Phase 4 Step C) ([06da9ae](https://github.com/ruby-git/ruby-git/commit/06da9aecf86274932360ff3ea125c5a36c9f2e2f))
* **prompts:** Improve Copilot review wait logic with timestamp validation ([e89d313](https://github.com/ruby-git/ruby-git/commit/e89d313f0fe384bbe0258107c19bb980f06c38f7))
* **redesign:** Add branch_delete to Branching facade table in implementation doc ([dfe0fed](https://github.com/ruby-git/ruby-git/commit/dfe0fed712e3b15fb417dad2d4745df43e90b17b))
* **redesign:** Add C1c-2 audit inventory ([4aa46a1](https://github.com/ruby-git/ruby-git/commit/4aa46a119769db145c882ecf8138f1ebc14ce341))
* **redesign:** Add no_commits? to StatusOperations in facade modules completed table ([a7d2c67](https://github.com/ruby-git/ruby-git/commit/a7d2c67344b07eee9dacc2608d1a12e1852d7e0a))
* **redesign:** Add Phase 4 Step B plan and W1 test audit ([0b09a54](https://github.com/ruby-git/ruby-git/commit/0b09a54186fd33bbe00934a2f1bcd38e6e89319c))
* **redesign:** Add PR 1d to Phase 4 Step A execution plan ([e427bbb](https://github.com/ruby-git/ruby-git/commit/e427bbb8d9f3853c0de62a97cded8ab78a40ccee))
* **redesign:** Add StatusOperations to facade modules completed table ([9e62113](https://github.com/ruby-git/ruby-git/commit/9e62113c7a9dea43e5b951bef7fca2d7ba363e6f))
* **redesign:** Add untracked_files to StatusOperations completed table ([b852b97](https://github.com/ruby-git/ruby-git/commit/b852b9703836d188f1a165029374781e5d56a13c))
* **redesign:** Advance Next Task to iter 7, mark Git::Status complete, update facade table ([f6fa95a](https://github.com/ruby-git/ruby-git/commit/f6fa95a4d8b0e7cb878329e4b99c7a659d2696fb))
* **redesign:** Correct iter 3 grep method name in implementation plan ([1e5c8ba](https://github.com/ruby-git/ruby-git/commit/1e5c8ba0d8987a17a07a0e85d29b3eb9298eb319))
* **redesign:** Flip 5 W2-U1 rows from port to covered ([3724b04](https://github.com/ruby-git/ruby-git/commit/3724b045b75cdcf89165f0855a90d26963b9a4a8))
* **redesign:** Flip 5 W2-U2 rows from port to covered ([8b469b0](https://github.com/ruby-git/ruby-git/commit/8b469b01cbae9f7d21b88213ea72ababf1c1078c))
* **redesign:** Mark F2 complete, Phase 3 complete; Phase 4 ready to begin ([8e8ee0f](https://github.com/ruby-git/ruby-git/commit/8e8ee0fb6a905332469b0cb6b815cf3482853301))
* **redesign:** Mark iter 1 domain objects complete, advance next task to iter 2 ([e2e57e4](https://github.com/ruby-git/ruby-git/commit/e2e57e4735651e425f5fccf3c0873965389d9231))
* **redesign:** Mark Phase 4 Step A complete in progress tracker ([6a48cb7](https://github.com/ruby-git/ruby-git/commit/6a48cb73533dedc553383a89193cb5445f2fd82c))
* **redesign:** Mark Step A2 facade extension complete ([c38d5b6](https://github.com/ruby-git/ruby-git/commit/c38d5b66f8c976299d63c1f6569f3ee13998cf31))
* **redesign:** Mark Step A4 (Inspecting facade) complete ([b562ad6](https://github.com/ruby-git/ruby-git/commit/b562ad6b5d23c5b883450e5fccb60e01a733a72f))
* **redesign:** Sync architecture implementation tracker ([3dfea52](https://github.com/ruby-git/ruby-git/commit/3dfea52ee982c0ab0302b79aa4f5f9d0fff4ac6a))
* **redesign:** Update Branching facade implementation plan for update_ref ([c6dbe73](https://github.com/ruby-git/ruby-git/commit/c6dbe7374f67d9362b9d7b9062434ac23d64b4b6))
* **redesign:** Update facade modules table to include Diffing, ObjectOperations, Logging ([3afc272](https://github.com/ruby-git/ruby-git/commit/3afc272712dfd764aa7fa191845a2ccecd0499a6))
* **redesign:** Update Phase 3 tracker with domain object migration plan ([f341f8a](https://github.com/ruby-git/ruby-git/commit/f341f8aaeb8cfd9e586ad7aa445e227d429eec02))
* **redesign:** Update phase 4 plan in tracker ([97a00db](https://github.com/ruby-git/ruby-git/commit/97a00dbf7f782878df9af2ebe87889c52d4b09a0))
* **redesign:** Update progress tracker — C1b/C1c-2 complete, C1d is next task ([d044aae](https://github.com/ruby-git/ruby-git/commit/d044aae4fd16905642033046f69c008bcd97cb86))
* Refine Phase 4 Step C PR structure and documentation requirements ([19bbb36](https://github.com/ruby-git/ruby-git/commit/19bbb36393ee3e6962c7bbef3157c09dd75842b5))
* Release v5.0.0.beta.1 ([e0b452c](https://github.com/ruby-git/ruby-git/commit/e0b452c47025d3e8bec9116a2c88ab3323907b94))
* Release v5.0.0.beta.2 ([c35f47a](https://github.com/ruby-git/ruby-git/commit/c35f47ad58be29be4b8734b9c5b0b3283daf7a06))
* Release v5.0.0.beta.3 ([#1479](https://github.com/ruby-git/ruby-git/issues/1479)) ([9d7d2dd](https://github.com/ruby-git/ruby-git/commit/9d7d2dd9d1a400c695890a248f7c86386767424e))
* Release v5.0.0.beta.4 ([05dbe23](https://github.com/ruby-git/ruby-git/commit/05dbe2374c1a815af3cd5688e6294761974dbd1a))
* Release v5.0.0.beta.5 ([476cbdd](https://github.com/ruby-git/ruby-git/commit/476cbdd170f74a4279761472d7870c636a2d75cf))
* **remote-operations:** Remove yard-lint exclusions ([90ff15c](https://github.com/ruby-git/ruby-git/commit/90ff15c5edae68123b35041c783045ba64727889))
* **remote:** Refine facade tests and YARD docs for Step A2 ([0c33699](https://github.com/ruby-git/ruby-git/commit/0c33699c70faf26959f2b59ae13c47e4b4306392))
* **remote:** Remote_add and remote_set_url return nil ([d2ffb59](https://github.com/ruby-git/ruby-git/commit/d2ffb5902f1b268f80260ae82f861540d15bab0a))
* **remote:** Remove YARD todo exclusions and add API docs ([a06b34b](https://github.com/ruby-git/ruby-git/commit/a06b34b4b730b2de76b250a9930de7e3f3212bf5))
* **remote:** Remove yard-lint todo exclusions ([2ad6300](https://github.com/ruby-git/ruby-git/commit/2ad6300c2f058cfbe215e170390f025f7d650eb2))
* **remote:** Remove yard-lint todo exclusions for set commands ([3dfe067](https://github.com/ruby-git/ruby-git/commit/3dfe067d4c49f2d526fdbf80534ee79ff10b4a03))
* Remove 328 excessive integration tests to reduce CI build time ([9a18570](https://github.com/ruby-git/ruby-git/commit/9a1857037569b97438e80a2b9f5ef49f4f4b8a14))
* Remove commitlint.test ([2502bcd](https://github.com/ruby-git/ruby-git/commit/2502bcde765f44f709fbe9d9fb3d2421efc680f7))
* Remove dead respond_to?/.lib fallback branches from domain objects ([9184542](https://github.com/ruby-git/ruby-git/commit/9184542bd4188050a3f9d05d631c874efd0ecf6a))
* Remove diff parser YARD todo exclusions ([8869157](https://github.com/ruby-git/ruby-git/commit/8869157bada72d0bf50f5561bc57f3d505f056e2))
* Remove diff_stats YARD exclusion and add arg docs ([c274992](https://github.com/ruby-git/ruby-git/commit/c274992e6930ec69611f8653ca5588f6b6f34d19))
* Remove empty example groups left after it-block deletions ([68370f3](https://github.com/ruby-git/ruby-git/commit/68370f34b9a7a4cf2bd0884b6141263e700087f6))
* Remove errors.rb yard-lint exclusion ([7c0fb75](https://github.com/ruby-git/ruby-git/commit/7c0fb756c2ad64ae0803597bfa91bf4ddbe501e3))
* Remove escaped_path YARD exclusions ([f932106](https://github.com/ruby-git/ruby-git/commit/f9321067b9a0abf04bfd487c62002a0ddcaf1670))
* Remove Git::Base, Git::Lib, and ExecutionContext::Repository bridge ([c1c5399](https://github.com/ruby-git/ruby-git/commit/c1c539990f86b0efb5e17a3982c4190f7d535ebc))
* Remove inert tests/files fixture directory ([0588d31](https://github.com/ruby-git/ruby-git/commit/0588d310fd9c59d018a1d2d354ac2c5a5804f26d))
* Remove inline trailing comments from arguments DSL blocks ([370dffb](https://github.com/ruby-git/ruby-git/commit/370dffb198641463cda1675475faedcaf04aa5da))
* Remove invalid [@attribute](https://github.com/attribute) YARD tags ([a1874c4](https://github.com/ruby-git/ruby-git/commit/a1874c404ca6af83e199104b1ef33d9d5042354c))
* Remove is_a?(Git::Base) compatibility guards from domain objects ([ba2a6d0](https://github.com/ruby-git/ruby-git/commit/ba2a6d038c3d9f8b7390e9473782f879fb321f8d))
* Remove lib/git.rb from remaining yard-lint exclusions ([19e076e](https://github.com/ruby-git/ruby-git/commit/19e076e4ae2b01e06cd45788e2b9831177f5c63d))
* Remove require 'git/base' from domain object files ([98a1494](https://github.com/ruby-git/ruby-git/commit/98a1494efeaa7f87b4df24941ad67e6666f7151d))
* Remove Test::Unit infrastructure (W3) ([606b1f4](https://github.com/ruby-git/ruby-git/commit/606b1f49c4a4386fb7bb33d190f54bcf158b0020))
* Remove Test::Unit references now that RSpec is the sole suite ([8e5def9](https://github.com/ruby-git/ruby-git/commit/8e5def973cf19f9cec3bd51fac548b7ef8d48e77))
* Remove unused ArgsBuilder class ([ad4589b](https://github.com/ruby-git/ruby-git/commit/ad4589b9ec4b4f1b37cf58362fc6ed1bbf4184aa))
* Remove yard-lint todo baseline ([53a24a2](https://github.com/ruby-git/ruby-git/commit/53a24a22259a45408ee554a644a108906f5c7463))
* Replace {Git::Base}/{Git::Lib} YARD cross-references in domain and command files ([39a8bcc](https://github.com/ruby-git/ruby-git/commit/39a8bcc4f241888ae8920ca29d7c74a38a96166a))
* Replace deprecated config/global_config calls with config_get/config_set/config_list in README ([ac3c47f](https://github.com/ruby-git/ruby-git/commit/ac3c47fd88e58082a3de8558267f037b343d9125))
* Replace subprocess deprecation tests with direct unit tests ([6437d67](https://github.com/ruby-git/ruby-git/commit/6437d67a2659fb6f915159d927ddc6d8109e8eba))
* Replace yardstick with yard-lint for YARD documentation linting ([20b51dc](https://github.com/ruby-git/ruby-git/commit/20b51dcaba280a36ddf6cc24c734c93f6ca236ad))
* **repository:** Add and fix YARD docs for ls_tree extraction ([91087dc](https://github.com/ruby-git/ruby-git/commit/91087dc9d1de85d2b7c2e706ce2c72e5392479c7))
* **repository:** Add tests and refine docs for Git::Repository#config_remote ([08fd73a](https://github.com/ruby-git/ruby-git/commit/08fd73afb3355026ad2c939eef5f28de950c7811))
* **repository:** Add unit and integration tests for Git::Repository::Configuring ([54717f3](https://github.com/ruby-git/ruby-git/commit/54717f3fe57bccf5e7df986852d0ab283344e327))
* **repository:** Add unit and integration tests for Git::Repository#diff_full ([0204bcf](https://github.com/ruby-git/ruby-git/commit/0204bcf9aabc6b06e9fd03e419e21ee547e4805a))
* **repository:** Add unit and integration tests for Git::Repository#diff_numstat ([611243b](https://github.com/ruby-git/ruby-git/commit/611243bea87458067af7a3572a52215ae9aa5a72))
* **repository:** Add unit and integration tests for StatusOperations#ls_files ([17b1352](https://github.com/ruby-git/ruby-git/commit/17b135263f2b4c05c57160be67f559079bcaa9cb))
* **repository:** Add unit tests for gblob/gcommit/gtree/tag/object facade methods ([4df51ad](https://github.com/ruby-git/ruby-git/commit/4df51ade2aba8b6827f74670958e3f3677f956e5))
* **repository:** Add unit tests for Git::Repository#lib deprecation ([305e224](https://github.com/ruby-git/ruby-git/commit/305e224130c044a58f30e724357c9813ffe20d4f))
* **repository:** Document committing option tags ([b94683d](https://github.com/ruby-git/ruby-git/commit/b94683d383dda4ee9e3e9189ffd8d29c4846d022))
* **repository:** Fix yard doc issues in cat_file_contents ([d0dc2d0](https://github.com/ruby-git/ruby-git/commit/d0dc2d05aaef67d07d3b6fd99f3c1107b28876f4))
* **repository:** Improve name_rev YARD docs ([9ff24cd](https://github.com/ruby-git/ruby-git/commit/9ff24cd00aceded94e18812f2db9c48ee1209bbe))
* **repository:** Remove command_capturing/streaming/env_overrides shim methods ([79ffde8](https://github.com/ruby-git/ruby-git/commit/79ffde802e91faeeaf308e417347a53b275f1297))
* **repository:** Remove context helpers yard-lint exclusions ([d236409](https://github.com/ruby-git/ruby-git/commit/d23640932d3fce1045bb424c6d22e8c86a7a92f1))
* **repository:** Remove factories yard-lint exclusions ([9a904d6](https://github.com/ruby-git/ruby-git/commit/9a904d6fd44551efd8570c562b083da9c8356cf6))
* **repository:** Remove repository yard-lint todo exclusions ([acae35e](https://github.com/ruby-git/ruby-git/commit/acae35e4191f59cb4788556379e7f36a20ed193c))
* **repository:** Remove staging yard-lint exclusions ([e66b971](https://github.com/ruby-git/ruby-git/commit/e66b971412898c79b9d375c2145d1bd95b967b22))
* **repository:** Rename Internal to SharedPrivate ([d95e3ba](https://github.com/ruby-git/ruby-git/commit/d95e3bac28c3a60dc0eb19cffa1f41b5671b4ba0))
* **repository:** Replace deprecated facade method usages ([c40eb8b](https://github.com/ruby-git/ruby-git/commit/c40eb8b55302f69f6eff7480a9e9e7776d6b99ab))
* **repository:** Review and fix configuring RSpec tests ([dc58805](https://github.com/ruby-git/ruby-git/commit/dc588059f5f0526eb5114e7245286d2128792034))
* **repository:** Review and fix StatusOperations RSpec tests ([34d95cb](https://github.com/ruby-git/ruby-git/commit/34d95cbb48d636fc88c45e3bf0fec03ec0b4c6e8))
* **repository:** Review and fix YARD docs for Configuring and StatusOperations ([3174da3](https://github.com/ruby-git/ruby-git/commit/3174da311809044b5ebce9d4179a6570dd78a181))
* **repository:** Review and fix YARD docs for StatusOperations#ls_files ([063f708](https://github.com/ruby-git/ruby-git/commit/063f70871dda54130e9cbcf3d2b35d78a87a754a))
* **repository:** Update configuring spec subjects ([506a015](https://github.com/ruby-git/ruby-git/commit/506a015fb9176be98e457179b19e1e1cc5d9a511))
* **repository:** Update Git::Base/Lib YARD refs to Git::Repository/Git (Phase 4 PR 2b) ([785ccf6](https://github.com/ruby-git/ruby-git/commit/785ccf6a8a8ed297312e796cf45a0dfdc4baf23d))
* Resolve branch_delete classification as legacy-contract, no change required ([e067077](https://github.com/ruby-git/ruby-git/commit/e067077e8fced1328b30a56d01da1bb38ce7b510))
* Restore Git::Base#branch_current delegator ([f3efbb6](https://github.com/ruby-git/ruby-git/commit/f3efbb6ff0f7722a490176222133519c62afd3d3))
* Restore ruby 3.4, jruby, truffleruby, and windows builds ([47bda0e](https://github.com/ruby-git/ruby-git/commit/47bda0ea7b7105c6d42e90a883e6cad81c403f86))
* Restructure YARD documentation skill ([4bfbe0f](https://github.com/ruby-git/ruby-git/commit/4bfbe0f9a882f6df961efb6dc9d7f379e76a01e7))
* Revert branch_current delegator; mark as no longer needed in audit ([ef8e9eb](https://github.com/ruby-git/ruby-git/commit/ef8e9ebf83168ed8f783eadde78cd1f47a6e343f))
* **revert:** Fix yard-lint docs for revert commands ([e371aa1](https://github.com/ruby-git/ruby-git/commit/e371aa1112535cd913b4d35eb93533235df0c443))
* Run bin/setup once per worktree session ([568d71d](https://github.com/ruby-git/ruby-git/commit/568d71de764a109795d96edf257a48238766c3fc))
* Set correct [@api](https://github.com/api) tags for all public and internal classes (C1c) ([83225f3](https://github.com/ruby-git/ruby-git/commit/83225f3f729c8cc84d6ba7a10fab15b04a7f0df4))
* Silence empty-repository clone warnings in url_spec ([0302e92](https://github.com/ruby-git/ruby-git/commit/0302e92afcaa8e41f49f1696bd0f0884578cb80d))
* **skills:** Add [@api](https://github.com/api) public checklist item to command-yard-documentation ([ef4206f](https://github.com/ruby-git/ruby-git/commit/ef4206f34fd9b7753219436aa43fd484f4ae26d8))
* **skills:** Add explicit [@option](https://github.com/option) default checklist item to command-yard-documentation ([45cedc3](https://github.com/ruby-git/ruby-git/commit/45cedc3b4e819a90b9d2945065123927eb3e4d6b))
* **skills:** Add facade skills and update related skills with facade links ([9ade70a](https://github.com/ruby-git/ruby-git/commit/9ade70abf27518e42bf533e3f30ee82d52c4dfde))
* **skills:** Add option allowlist guidance to extract-facade-from-base-lib skill ([ad0a62e](https://github.com/ruby-git/ruby-git/commit/ad0a62e3f3eeb8cf08690734617beda5729c9863))
* **skills:** Add signature-compatibility policy for facade extraction and review ([198e809](https://github.com/ruby-git/ruby-git/commit/198e80913cfdcae8dc118e96027074ffb47a766a))
* **skills:** Clarify negatable inline comment rule in review-arguments-dsl checklist ([33b4846](https://github.com/ruby-git/ruby-git/commit/33b4846ffca5b3b1925ec988b5bb437a8135ab32))
* **skills:** Clarify tag summary length rule in yard-documentation skill ([a2238c4](https://github.com/ruby-git/ruby-git/commit/a2238c49a254b1779afbad2032367300dddc9dbe))
* **skills:** Clarify YARD overload and [@raise](https://github.com/raise) scoping rules ([a5f5435](https://github.com/ruby-git/ruby-git/commit/a5f5435b1bf5ac1fe8067ac887ba75209032967b))
* **skills:** Deprecate review-backward-compatibility skill ([bf58571](https://github.com/ruby-git/ruby-git/commit/bf585713279b35785d3283d256e41a90b953c411))
* **skills:** Enforce *_ALLOWED_OPTS proximity rule in facade skills ([4a674f2](https://github.com/ruby-git/ruby-git/commit/4a674f29493957990a651955684fd4dd8d0ee5dd))
* **skills:** Expand namespace module template in command-implementation skill ([b40221b](https://github.com/ruby-git/ruby-git/commit/b40221b270a4a0e6e0231d667be83582ce79bf15))
* **skills:** Fix Copilot review comments in yard-documentation skill ([e6a7db2](https://github.com/ruby-git/ruby-git/commit/e6a7db23de08c8cb21a55044dfa85019b9779d90))
* **skills:** Fix skill review findings from post-implementation audit ([9797219](https://github.com/ruby-git/ruby-git/commit/97972199b90badf8746e0102fdba533165cc1a87))
* **skills:** Pr 1 — update skills to describe new negatable DSL contract (issue [#1260](https://github.com/ruby-git/ruby-git/issues/1260)) ([53f0eed](https://github.com/ruby-git/ruby-git/commit/53f0eeddf84f4ce513fbd941b2bc249443072770))
* **skills:** Prohibit local git help output in command implementation ([fa7d0cb](https://github.com/ruby-git/ruby-git/commit/fa7d0cb48b97d9a9733cd59647934fae2665c847))
* **skills:** Remove negatable flag normalization from extract-facade skill ([#1260](https://github.com/ruby-git/ruby-git/issues/1260)) ([83d52c3](https://github.com/ruby-git/ruby-git/commit/83d52c3b60a4d63c833e280f9e6b4d2f2d40627b))
* **skills:** Replace stale Git::Base/Lib refs with current architecture ([d4e0487](https://github.com/ruby-git/ruby-git/commit/d4e0487c4ecaa0c22e3ef2d473e7de9bdf246719))
* **skills:** Strengthen prohibition of trailing inline DSL comments ([678b637](https://github.com/ruby-git/ruby-git/commit/678b637ba2eaabefbee510e0536662ebd0df202e))
* **skills:** Update facade-implementation skill for SharedPrivate pattern ([19052fc](https://github.com/ruby-git/ruby-git/commit/19052fc5426a6d62cfc35bc7cdf77537cdfa3e30)), closes [#1282](https://github.com/ruby-git/ruby-git/issues/1282)
* **skills:** Update instructions and yard-documentation skill ([ad05db9](https://github.com/ruby-git/ruby-git/commit/ad05db913acb08efd61c886deb4f3f31a339fd7a))
* **specs:** Use execution_context_double across command specs ([821f7d9](https://github.com/ruby-git/ruby-git/commit/821f7d9cb1010b9a8216a959f3448468ada842c8))
* **stash:** Accept Git::Repository via constructor polymorphism ([7615ddc](https://github.com/ruby-git/ruby-git/commit/7615ddc15ca114ef6655f2e9c0c999848f53054b))
* **stashes:** Accept Git::Repository via constructor polymorphism ([e69d286](https://github.com/ruby-git/ruby-git/commit/e69d286d73088e3c64d17fb13c9df0653c14bf8c))
* **stash:** Remove YARD exclusions and add parser docs ([d21aaca](https://github.com/ruby-git/ruby-git/commit/d21aaca60970814e41aa6737c5c948cce5bf4dc8))
* **stash:** Remove yard-lint exclusions for stash commands ([fd3d875](https://github.com/ruby-git/ruby-git/commit/fd3d875f0dc1681e0b73b21386175aa6e1068e09))
* **status:** Use config_get in ignore_case? ([418d918](https://github.com/ruby-git/ruby-git/commit/418d918a6e2977b931e5138fca9d0550d5c7535a))
* Strengthen iteratively-address-copilot-reviews prompt ([097ed3c](https://github.com/ruby-git/ruby-git/commit/097ed3c8d9a21e2b7a610dbadd6ad79a8c9b7087))
* **tag:** Remove YARD exclusions and document parser helpers ([f9460da](https://github.com/ruby-git/ruby-git/commit/f9460da3fd97362d209a1f508993fac32abca1de))
* Temporarily remove ruby 3.4 build ([96bb983](https://github.com/ruby-git/ruby-git/commit/96bb983070aeeea7ebc92a91ef86a1744a4f9475))
* **test:** Add unit and integration tests for Git::Repository#diff_index ([91429b9](https://github.com/ruby-git/ruby-git/commit/91429b96cc819ae9bf6ca00844966d7ce27ff0ac))
* **tests:** Add Git::Deprecation.behavior = :raise enforcement to rspec suite ([0077de5](https://github.com/ruby-git/ruby-git/commit/0077de59db36331ffc8ed8d5e53ec00db4f16012))
* **tests:** Clean up test_helper stubs and deprecation test callers ([5cc17a8](https://github.com/ruby-git/ruby-git/commit/5cc17a80b3d030612761e20732384be771a6baff))
* **tests:** Fix remaining test callers of .lib discovered by deprecation enforcement ([06f13e4](https://github.com/ruby-git/ruby-git/commit/06f13e48573398bb541e8860ad1f0ec14c2c2ef2))
* **tests:** Fix RuboCop offenses from C1d-2 phases ([ee4f662](https://github.com/ruby-git/ruby-git/commit/ee4f662001a7bab7857274e88da9b4515b8b03a1))
* **tests:** Migrate incidental #config calls to config_set/config_get ([9036ad9](https://github.com/ruby-git/ruby-git/commit/9036ad947c56e171acfbd943a81685b9395c8e1d)), closes [#1468](https://github.com/ruby-git/ruby-git/issues/1468)
* **tests:** Patch incidental Git::Base/Git::Lib refs in Test::Unit ([7acfa1d](https://github.com/ruby-git/ruby-git/commit/7acfa1d553b0ba87c1370ba60e2c5442648833ef))
* **tests:** Replace git.lib env_overrides calls in test_command_line_env_overrides ([707fb65](https://github.com/ruby-git/ruby-git/commit/707fb65984e4a80806d3ef3d55335fcb420ccdce))
* **tests:** Replace git.lib facade calls in Test::Unit unit tests ([99294a6](https://github.com/ruby-git/ruby-git/commit/99294a687f4d7cfddc94b1be1653594135f74a9c))
* **tests:** Replace git.lib.command_capturing calls in Test::Unit unit tests ([f7e0d87](https://github.com/ruby-git/ruby-git/commit/f7e0d8787979700c38c35d9dc605959bca710f08))
* **tests:** Replace repo.lib calls in rspec parser specs ([4a14ce7](https://github.com/ruby-git/ruby-git/commit/4a14ce724ef78170255d85bac6e5bdc8a9e01f51))
* **tests:** Replace repo.lib with repo.execution_context in command and support specs ([0c16682](https://github.com/ruby-git/ruby-git/commit/0c1668271f5daa406e75b0d9ff3908aa80162a02))
* **tests:** Replace repo.lib.method with repo.method in rspec integration specs ([c1ddf48](https://github.com/ruby-git/ruby-git/commit/c1ddf487e2384ef7446b715dfd65733935502f45))
* Update [@param](https://github.com/param) base YARD types to Git::Repository only ([2d882b5](https://github.com/ruby-git/ruby-git/commit/2d882b53348bbc68c9dfd589e43a2c4939afb90b))
* Update [@param](https://github.com/param) base YARD types to Git::Repository only in diff files ([208b77b](https://github.com/ruby-git/ruby-git/commit/208b77b22d180796d299ccb30566499f508b6d6c))
* Update c1c2 audit documents to reflect completed work ([fe5223c](https://github.com/ruby-git/ruby-git/commit/fe5223c5696b2ca3dad408e127fef7792dea3eda))
* Update c1c2 audit documents to reflect completed work ([fd1c431](https://github.com/ruby-git/ruby-git/commit/fd1c431405433c0b6dbefe1c51e6b5c27406deac))
* Update CONTRIBUTING.md to reflect v5.0.0 architecture ([b437f7e](https://github.com/ruby-git/ruby-git/commit/b437f7e90a219f28ff190a63dea449d56755f889))
* Update implementation plan for branch/remote polymorphism migration ([0c8c577](https://github.com/ruby-git/ruby-git/commit/0c8c57773b72c9bdc5b685d7058887b6a9388720))
* Update legacy Test::Unit tests to use new canonical method names ([d9b3979](https://github.com/ruby-git/ruby-git/commit/d9b3979f0383ddcab2e2909a172f37d5bd39e224))
* Update model names in iterative Copilot review prompt ([c7cc07b](https://github.com/ruby-git/ruby-git/commit/c7cc07bf14b5a88cf176a8becfe6815b502e90ae))
* Update Phase 4 Step B progress after W2-U10 merge ([c92ed24](https://github.com/ruby-git/ruby-git/commit/c92ed243eef18b0dbfe04ad67c3a0660d2bc3c30))
* Update Phase 4 Step B progress after W3/W4a/W4b/W6-plan merge ([07659b0](https://github.com/ruby-git/ruby-git/commit/07659b0df36bb075c4307213210951f90c88ae2f))
* Update plan - mark Phase 3 Task 1 complete, add Task 2 workflow ([913a27c](https://github.com/ruby-git/ruby-git/commit/913a27ca78130769c7b5d2a49586e1af1cf9f9cd))
* Update plan - mark Phase 3 Task 3 complete, add Task 4 workflow ([29eee69](https://github.com/ruby-git/ruby-git/commit/29eee6973b279cd2f4f2f585f053a1ec797373ec))
* Update plan - mark Phase 3 Task 4 staging module complete, update Next Task ([cdadb3f](https://github.com/ruby-git/ruby-git/commit/cdadb3fc3d2b7f8673d5de6c986ae37398b123b9))
* Update README.md for v5.0.0 release (Phase 4 Step C2b) ([a6ce582](https://github.com/ruby-git/ruby-git/commit/a6ce582aba661684d2bc53115f03a209cafd1dde))
* Update skill files for Git::Version ([f07ec74](https://github.com/ruby-git/ruby-git/commit/f07ec74bfe1b79351d61e5824c5d2b8065cefe87))
* Update test infrastructure for version validation ([e90fa5d](https://github.com/ruby-git/ruby-git/commit/e90fa5df6c111d1ce7be597c2675fb9718cb29a5))
* **url:** Port W2-U7 Git remote URL utility coverage to RSpec ([88a874f](https://github.com/ruby-git/ruby-git/commit/88a874f0f5e80df467223e231f48954d1d97beca))
* Use [Boolean, nil] type with (nil) default for flag options ([6ecd37e](https://github.com/ruby-git/ruby-git/commit/6ecd37ead93815c77418241532b44fef3bf27daf))
* Warn against YARD tags inside arguments blocks in command skills ([224259e](https://github.com/ruby-git/ruby-git/commit/224259ebe7c47e9680fdad701d7190599cbc97ce))
* **workflow:** Temporarily disable windows, jruby, and truffleruby builds ([e81dc55](https://github.com/ruby-git/ruby-git/commit/e81dc551c17d3747b31e1c45f6f8f09b2542b46c))
* **worktree:** Apply constructor polymorphism to Git::Worktree ([6b93666](https://github.com/ruby-git/ruby-git/commit/6b93666cc73fe28582d82cce867ae535019e60a2))
* **worktree:** Delegate base worktree methods to repository facade with coverage ([3ebb65f](https://github.com/ruby-git/ruby-git/commit/3ebb65f07a7662ee747123e27c3525c78ae8331b))
* **worktrees:** Add integration spec for Git::Worktrees collection and prune cycle ([126f9dc](https://github.com/ruby-git/ruby-git/commit/126f9dcd25a74667456e6cb49651903defdf70b5))
* **worktrees:** Add unit spec for Git::Worktrees polymorphism ([5e26a0e](https://github.com/ruby-git/ruby-git/commit/5e26a0e25102410c414dc8ac88f1641e17fb2e39))
* **worktrees:** Apply constructor polymorphism to Git::Worktrees ([bca7adb](https://github.com/ruby-git/ruby-git/commit/bca7adbe3756db6391137ee1586581cfe3f92c4c))
* **worktrees:** Fix YARD violations in worktree command classes ([e0b17e5](https://github.com/ruby-git/ruby-git/commit/e0b17e55667debca51164b86adf896d9fc77796b))
* **worktree:** Update command YARD annotations and architecture notes ([adeb8fa](https://github.com/ruby-git/ruby-git/commit/adeb8fa866e16cafcfd763e68b4391cbf155be52))
* **yard-documentation:** Codify class/module [@api](https://github.com/api) visibility ([58b869f](https://github.com/ruby-git/ruby-git/commit/58b869f1c3ae720e0f04da3335cea9a334f0249a))
* **yard:** Clarify [@api](https://github.com/api) placement with [@overload](https://github.com/overload) ([5b8a68d](https://github.com/ruby-git/ruby-git/commit/5b8a68d234a204ac6d5f2827f97f258af75569ff))
* **yard:** Clarify overload placement for return and raise tags ([0e7d321](https://github.com/ruby-git/ruby-git/commit/0e7d3218a6bf680659d411f2aa86c981704ae37f))
* **yard:** Link @!method section to overload placement rules ([09abc32](https://github.com/ruby-git/ruby-git/commit/09abc326c8c84622d9886c82a42aa61ef2825dc2))
* **yard:** Remove am quit yard-lint todo exclusion ([2520a30](https://github.com/ruby-git/ruby-git/commit/2520a309480f476f18c54b1defe00c967e73fa48))
* **yard:** Remove baselines for worktree and write-tree commands ([f4ef40c](https://github.com/ruby-git/ruby-git/commit/f4ef40c0fb4944caa08258727e49434b67741e07))
* **yard:** Remove branching todo exclusions ([980e0a9](https://github.com/ruby-git/ruby-git/commit/980e0a9b9b780088317a2f18b7da92afb8516e87))
* **yard:** Remove command exclusions and fix option docs ([ab687ba](https://github.com/ruby-git/ruby-git/commit/ab687bab841478799aa93c18a81e7dd0d798af92))
* **yard:** Remove command exclusions from yard todo ([7693566](https://github.com/ruby-git/ruby-git/commit/7693566735b33001f6b3ed72d9d0e2ec7d4d66d3))
* **yard:** Remove config option syntax exclusions ([51a200e](https://github.com/ruby-git/ruby-git/commit/51a200ef8c2c10c2358eab45695842918027a089))
* **yard:** Remove diffing exclusions and document options ([c8dbf1f](https://github.com/ruby-git/ruby-git/commit/c8dbf1f007ea4020a89ee2e9fa9234939d667f2a))
* **yard:** Remove object_operations todo exclusions ([2fb2cdb](https://github.com/ruby-git/ruby-git/commit/2fb2cdb5d93b747c9c4f625a315a995f0f491f33))
* **yard:** Remove selected todo exclusions ([7ba0a34](https://github.com/ruby-git/ruby-git/commit/7ba0a3491a09d74e1bf432d48805cef75d033a0e))
* **yard:** Remove shared_private lint exclusions ([3be7ea2](https://github.com/ruby-git/ruby-git/commit/3be7ea212d4b524175d69112375da2519c02db2c))
* **yard:** Remove stash and status lint baselines ([407d7af](https://github.com/ruby-git/ruby-git/commit/407d7aff08edeee9f4daaedb88b933eb74c30936))
* **yard:** Remove url todo exclusion and document clone_to args ([5123df5](https://github.com/ruby-git/ruby-git/commit/5123df544f85f9dd44e3e9340dda4d562d56cfe6))

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
