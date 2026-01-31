# frozen_string_literal: true

# Helper module for setting up diff test repository history.
#
# Extracted to keep shared context block size manageable.
#
# rubocop:disable Metrics/ModuleLength
module DiffTestRepositorySetup
  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def setup_diff_test_history
    setup_initial_commits
    setup_file_operations
    setup_special_cases
    setup_submodule
    setup_feature_branch
  end

  private

  def setup_initial_commits
    # Initial commit
    write_file('README.md', "# Project\n\nThis is a test project.\n")
    repo.add('README.md')
    repo.commit('Initial commit')
    repo.add_tag('initial')

    # Modify file
    write_file('README.md', "# Project\n\nThis is a test project.\n\n## Installation\n\nRun `bundle install`.\n")
    repo.add('README.md')
    repo.commit('Add installation section')
    repo.add_tag('after_modify')
  end

  def setup_file_operations
    # Rename file (with content change for similarity detection)
    FileUtils.mv(File.join(repo_dir, 'README.md'), File.join(repo_dir, 'docs.md'))
    write_file('docs.md', "# Documentation\n\nThis is a test project.\n\n## Installation\n\nRun `bundle install`.\n")
    repo.add(all: true)
    repo.commit('Rename README to docs')
    repo.add_tag('after_rename')

    # Delete file
    FileUtils.rm(File.join(repo_dir, 'docs.md'))
    repo.add(all: true)
    repo.commit('Remove docs file')
    repo.add_tag('after_delete')

    # Add new file
    write_file('lib/main.rb', "# frozen_string_literal: true\n\nmodule Main\n  VERSION = '1.0.0'\nend\n")
    repo.add('lib/main.rb')
    repo.commit('Add main library')
    repo.add_tag('after_add')
  end

  def setup_special_cases
    # Add binary file
    write_file('image.png', "\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01")
    repo.add('image.png')
    repo.commit('Add binary image')
    repo.add_tag('after_binary')

    # Change file mode (make executable) - skip on Windows where chmod isn't supported
    write_file('bin/run', "#!/usr/bin/env ruby\nputs 'Hello'\n")
    repo.add('bin/run')
    repo.commit('Add run script')
    unless Gem.win_platform?
      FileUtils.chmod(0o755, File.join(repo_dir, 'bin/run'))
      repo.add('bin/run')
      repo.commit('Make run script executable')
    end
    repo.add_tag('after_mode_change')

    # Add file with spaces in path
    write_file('path with spaces/file name.txt', "Content in spaced path\n")
    repo.add(all: true)
    repo.commit('Add file with spaces')
    repo.add_tag('after_spaces')

    # Add file with UTF-8 characters (skull ☠ = U+2620)
    write_file('file☠skull.rb', "# frozen_string_literal: true\n\nmodule Skull\nend\n")
    repo.add(all: true)
    repo.commit('Add file with UTF-8 name')
    repo.add_tag('after_utf8')

    # Rename UTF-8 file
    FileUtils.mv(File.join(repo_dir, 'file☠skull.rb'), File.join(repo_dir, 'renamed☠skull.rb'))
    write_file('renamed☠skull.rb', "# frozen_string_literal: true\n\nmodule RenamedSkull\nend\n")
    repo.add(all: true)
    repo.commit('Rename UTF-8 file')
    repo.add_tag('after_utf8_rename')

    # Add file with tab in name (git escapes as \t)
    setup_tab_filename

    # Multiple file changes
    write_file('lib/main.rb', "# frozen_string_literal: true\n\nmodule Main\n  VERSION = '1.1.0'\nend\n")
    write_file('lib/helper.rb', "# frozen_string_literal: true\n\nmodule Helper\nend\n")
    write_file('CHANGELOG.md', "# Changelog\n\n## 1.1.0\n\n- Added helper\n")
    repo.add(all: true)
    repo.commit('Bump version and add helper')
    repo.add_tag('after_multi')
    repo.add_tag('main_tip')
  end

  def setup_tab_filename
    # Create file with tab character in name - git will quote and escape this
    # Skip on Windows where tab characters are not allowed in filenames
    unless Gem.win_platform?
      tab_file = File.join(repo_dir, "file\twith\ttab.txt")
      File.write(tab_file, "Content with tab in filename\n")
      repo.add(all: true)
      repo.commit('Add file with tab in name')
    end
    repo.add_tag('after_tab_filename')
  end

  def setup_submodule
    # Create a separate repository to use as submodule
    submodule_source = Dir.mktmpdir('submodule-source')
    sub_repo = Git.init(submodule_source, initial_branch: 'main')
    sub_repo.config('user.email', 'test@example.com')
    sub_repo.config('user.name', 'Test User')
    File.write(File.join(submodule_source, 'sub.txt'), "Submodule content\n")
    sub_repo.add('sub.txt')
    sub_repo.commit('Initial submodule commit')

    # Add submodule to main repo
    repo.add_tag('before_submodule')
    submodule_path = File.join(repo_dir, 'vendor/submodule')
    Dir.chdir(repo_dir) do
      # Allow file:// protocol for local submodule (needed for newer git versions)
      system('git', 'config', 'protocol.file.allow', 'always', out: File::NULL, err: File::NULL)
      # git submodule add stages the changes
      system('git', 'submodule', 'add', submodule_source, 'vendor/submodule', out: File::NULL, err: File::NULL)
      system('git', 'commit', '-m', 'Add submodule', out: File::NULL, err: File::NULL)
    end
    repo.add_tag('after_submodule')

    # Update submodule to new commit (only if submodule was successfully added)
    if Dir.exist?(submodule_path)
      File.write(File.join(submodule_source, 'sub.txt'), "Updated submodule content\n")
      sub_repo.add('sub.txt')
      sub_repo.commit('Update submodule')
      Dir.chdir(submodule_path) do
        system('git', 'pull', 'origin', 'main', out: File::NULL, err: File::NULL)
      end
      Dir.chdir(repo_dir) do
        system('git', 'add', 'vendor/submodule', out: File::NULL, err: File::NULL)
        system('git', 'commit', '-m', 'Update submodule pointer', out: File::NULL, err: File::NULL)
      end
    end
    repo.add_tag('after_submodule_update')
  end

  def setup_feature_branch
    # Create feature branch from after_add
    repo.checkout('after_add')
    repo.branch('feature').checkout

    write_file('lib/feature.rb', "# frozen_string_literal: true\n\nmodule Feature\nend\n")
    repo.add('lib/feature.rb')
    repo.commit('Add feature module')
    repo.add_tag('feature_tip')

    # Return to main
    repo.checkout('main')
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
end
# rubocop:enable Metrics/ModuleLength

# Shared context providing a repository with a rich git history for diff testing.
#
# This context creates a repository with multiple tagged commits representing
# various diff scenarios. Tests can use tags to create precise, predictable
# diff comparisons.
#
# ## Tags provided:
#
# - `initial`: First commit with a single file
# - `after_modify`: File modified with line changes
# - `after_rename`: File renamed (with content change)
# - `after_delete`: File deleted
# - `after_add`: New file added
# - `after_binary`: Binary file added
# - `after_mode_change`: File mode changed to executable
# - `after_spaces`: File with spaces in path added
# - `after_utf8`: File with UTF-8 characters in name added
# - `after_utf8_rename`: UTF-8 named file renamed
# - `after_tab_filename`: File with tab character in name added
# - `after_multi`: Multiple files changed in one commit
# - `before_submodule`: Before submodule added
# - `after_submodule`: Submodule added
# - `after_submodule_update`: Submodule pointer updated
# - `feature_tip`: Tip of the feature branch
# - `main_tip`: Final commit on main branch
#
# ## Usage:
#
#   RSpec.describe Git::Commands::Diff::Patch do
#     include_context 'in a diff test repository'
#
#     it 'diffs between tags' do
#       result = command.call(from: 'initial', to: 'after_modify')
#       expect(result.files).not_to be_empty
#     end
#   end
#
RSpec.shared_context 'in a diff test repository' do
  include Git::IntegrationTestHelpers
  include DiffTestRepositorySetup

  # Use instance variables for before(:all) since let blocks aren't available
  attr_reader :repo_dir, :repo, :execution_context

  # Check if submodule tests can run (submodule setup may fail in some CI environments)
  def submodule_available?
    Dir.exist?(File.join(repo_dir, 'vendor/submodule'))
  end

  before(:all) do
    @repo_dir = Dir.mktmpdir
    @repo = Git.init(@repo_dir, initial_branch: 'main')
    @repo.config('user.email', 'test@example.com')
    @repo.config('user.name', 'Test User')
    @repo.config('commit.gpgsign', 'false')
    @repo.config('core.editor', 'false')

    setup_diff_test_history

    @execution_context = @repo.lib
  end

  after(:all) do
    FileUtils.rm_rf(@repo_dir) if @repo_dir
  end
end
