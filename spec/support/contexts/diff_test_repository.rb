# frozen_string_literal: true

# Helper module for setting up diff test repository history.
#
# Extracted to keep shared context block size manageable. Each scenario has
# its own method so that none trips the Metrics cops.
module DiffTestRepositorySetup
  def setup_diff_test_history
    setup_initial_commits
    setup_file_operations
    setup_special_cases
    setup_feature_branch
  end

  private

  # Stage every change in the working tree, commit it, and tag the commit if
  # a tag is given
  def commit_all(message, tag: nil)
    repo.add(all: true)
    repo.commit(message)
    repo.tag_create(tag) if tag
  end

  # Absolute path of a file in the repository
  def repo_path(name)
    File.join(repo_dir, name)
  end

  def setup_initial_commits
    write_file('README.md', "# Project\n\nThis is a test project.\n")
    commit_all('Initial commit', tag: 'initial')

    write_file('README.md', "# Project\n\nThis is a test project.\n\n## Installation\n\nRun `bundle install`.\n")
    commit_all('Add installation section', tag: 'after_modify')
  end

  def setup_file_operations
    # Rename file (with content change for similarity detection)
    FileUtils.mv(repo_path('README.md'), repo_path('docs.md'))
    write_file('docs.md', "# Documentation\n\nThis is a test project.\n\n## Installation\n\nRun `bundle install`.\n")
    commit_all('Rename README to docs', tag: 'after_rename')

    FileUtils.rm(repo_path('docs.md'))
    commit_all('Remove docs file', tag: 'after_delete')

    write_file('lib/main.rb', "# frozen_string_literal: true\n\nmodule Main\n  VERSION = '1.0.0'\nend\n")
    commit_all('Add main library', tag: 'after_add')
  end

  def setup_special_cases
    setup_binary_file
    setup_mode_change
    setup_special_filenames
    setup_tab_filename
    setup_multi_file_change
  end

  def setup_binary_file
    write_file('image.png', "\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01")
    commit_all('Add binary image', tag: 'after_binary')
  end

  def setup_mode_change
    write_file('bin/run', "#!/usr/bin/env ruby\nputs 'Hello'\n")
    commit_all('Add run script')

    # Make the script executable - skip on Windows where chmod isn't supported
    unless Gem.win_platform?
      FileUtils.chmod(0o755, repo_path('bin/run'))
      commit_all('Make run script executable')
    end
    repo.tag_create('after_mode_change')
  end

  def setup_special_filenames
    write_file('path with spaces/file name.txt', "Content in spaced path\n")
    commit_all('Add file with spaces', tag: 'after_spaces')

    # File with UTF-8 characters in its name (skull ☠ = U+2620)
    write_file('file☠skull.rb', "# frozen_string_literal: true\n\nmodule Skull\nend\n")
    commit_all('Add file with UTF-8 name', tag: 'after_utf8')

    FileUtils.mv(repo_path('file☠skull.rb'), repo_path('renamed☠skull.rb'))
    write_file('renamed☠skull.rb', "# frozen_string_literal: true\n\nmodule RenamedSkull\nend\n")
    commit_all('Rename UTF-8 file', tag: 'after_utf8_rename')
  end

  def setup_tab_filename
    # File with a tab character in its name - git will quote and escape this.
    # Skip on Windows where tab characters are not allowed in filenames.
    unless Gem.win_platform?
      write_file("file\twith\ttab.txt", "Content with tab in filename\n")
      commit_all('Add file with tab in name')
    end
    repo.tag_create('after_tab_filename')
  end

  def setup_multi_file_change
    write_file('lib/main.rb', "# frozen_string_literal: true\n\nmodule Main\n  VERSION = '1.1.0'\nend\n")
    write_file('lib/helper.rb', "# frozen_string_literal: true\n\nmodule Helper\nend\n")
    write_file('CHANGELOG.md', "# Changelog\n\n## 1.1.0\n\n- Added helper\n")
    commit_all('Bump version and add helper', tag: 'after_multi')
    repo.tag_create('main_tip')
  end

  def setup_feature_branch
    # Create feature branch from after_add
    repo.checkout('after_add')
    repo.checkout('feature', new_branch: true)

    write_file('lib/feature.rb', "# frozen_string_literal: true\n\nmodule Feature\nend\n")
    commit_all('Add feature module', tag: 'feature_tip')

    # Return to main
    repo.checkout('main')
  end
end

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

  before(:all) do
    @repo_dir = Dir.mktmpdir
    @repo = Git.init(@repo_dir, initial_branch: 'main')
    @repo.config_set('user.email', 'test@example.com')
    @repo.config_set('user.name', 'Test User')
    @repo.config_set('commit.gpgsign', 'false')
    @repo.config_set('core.editor', 'false')

    setup_diff_test_history

    @execution_context = @repo.execution_context
  end

  after(:all) do
    FileUtils.rm_rf(@repo_dir) if @repo_dir
  end
end
