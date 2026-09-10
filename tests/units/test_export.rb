# frozen_string_literal: true

require 'test_helper'

# Tests for Git.export
#
# Git.export forwards its options to Git.clone, so :branch accepts what
# `git clone --branch` accepts: a branch short name or a tag name, resolved against
# the refs the remote advertises. Full ref paths and SHAs are not accepted.
#
class TestExport < Test::Unit::TestCase
  def test_export_without_branch_exports_the_default_branch
    in_temp_dir do |path|
      source = create_source_repo
      export_dir = File.join(path, 'exported')

      Git.export(source.dir.to_s, export_dir)

      assert_equal(['a.txt', 'b.txt'], exported_entries(export_dir))
    end
  end

  def test_export_with_a_branch_short_name
    in_temp_dir do |path|
      source = create_source_repo
      export_dir = File.join(path, 'exported')

      Git.export(source.dir.to_s, export_dir, branch: 'topic')

      assert_equal(['a.txt', 'topic.txt'], exported_entries(export_dir))
    end
  end

  def test_export_with_a_lightweight_tag
    in_temp_dir do |path|
      source = create_source_repo
      export_dir = File.join(path, 'exported')

      Git.export(source.dir.to_s, export_dir, branch: 'v1.0.0')

      assert_equal(['a.txt'], exported_entries(export_dir))
    end
  end

  def test_export_with_an_annotated_tag
    in_temp_dir do |path|
      source = create_source_repo
      export_dir = File.join(path, 'exported')

      Git.export(source.dir.to_s, export_dir, branch: 'v2.0.0')

      assert_equal(['a.txt'], exported_entries(export_dir))
    end
  end

  def test_export_with_a_full_ref_path_fails_and_leaves_nothing_behind
    in_temp_dir do |path|
      source = create_source_repo
      export_dir = File.join(path, 'exported')

      assert_raise(Git::FailedError) do
        Git.export(source.dir.to_s, export_dir, branch: 'refs/tags/v1.0.0')
      end

      assert(!File.exist?(export_dir))
    end
  end

  def test_export_with_a_commit_sha_fails
    in_temp_dir do |path|
      source = create_source_repo
      export_dir = File.join(path, 'exported')

      assert_raise(Git::FailedError) do
        Git.export(source.dir.to_s, export_dir, branch: source.rev_parse('HEAD'))
      end
    end
  end

  private

  # Build a repository whose default branch, topic branch, and tags each hold a
  # different set of files, so an export can be told apart by what it contains
  #
  def create_source_repo
    Dir.mkdir('source')
    repo = Git.init('source', initial_branch: 'main')
    repo.config('user.name', 'Test User')
    repo.config('user.email', 'test@example.com')

    repo.chdir { commit_source_history(repo) }

    repo
  end

  def commit_source_history(repo)
    commit_file(repo, 'a.txt', 'Initial commit')
    repo.add_tag('v1.0.0')
    repo.add_tag('v2.0.0', annotate: true, message: 'Release 2.0.0')

    repo.branch('topic').checkout
    commit_file(repo, 'topic.txt', 'Topic commit')

    repo.checkout('main')
    commit_file(repo, 'b.txt', 'Second commit')
  end

  def commit_file(repo, name, message)
    new_file(name, name)
    repo.add(name)
    repo.commit(message)
  end

  # Dir.children lists dotfiles, so an expected list that omits '.git' also asserts
  # that the .git directory was removed from the export
  #
  def exported_entries(dir)
    Dir.children(dir).sort
  end
end
