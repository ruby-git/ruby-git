# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/merge/quit'

RSpec.describe Git::Commands::Merge::Quit, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  before do
    # Create initial commit
    write_file('file.txt', "base\n")
    repo.add('file.txt')
    repo.commit('Initial commit')
  end

  describe '#call' do
    context 'when a merge is in progress due to conflicts' do
      before do
        # Create feature branch with conflicting change
        repo.branch('feature').checkout
        write_file('file.txt', "feature change\n")
        repo.add('file.txt')
        repo.commit('Feature commit')

        # Create conflicting change on main
        repo.checkout('main')
        write_file('file.txt', "main change\n")
        repo.add('file.txt')
        repo.commit('Main commit')

        # Start merge that will conflict
        expect { repo.merge('feature') }.to raise_error(Git::FailedError)
      end

      it 'quits the merge leaving working tree as-is' do
        # Verify conflict markers exist before quit
        expect(read_file('file.txt')).to include('<<<<<<')

        command.call

        # Working tree still has conflict markers
        expect(read_file('file.txt')).to include('<<<<<<')
        expect(read_file('file.txt')).to include('======')
        expect(read_file('file.txt')).to include('>>>>>>')
      end

      it 'removes merge state but keeps working tree changes' do
        merge_head_path = File.join(repo_dir, '.git', 'MERGE_HEAD')

        # Sanity check: a merge should be in progress before quitting
        expect(File).to exist(merge_head_path)

        command.call

        # After quit, merge state should be cleared
        expect(File).not_to exist(merge_head_path)

        # But working tree/index should still reflect the conflicted file
        status_output = repo.status
        expect(status_output['file.txt']).not_to be_nil
      end

      it 'leaves the file as modified in git status' do
        command.call

        status = repo.status
        expect(status['file.txt']).not_to be_nil
        expect(status['file.txt'].type).to match(/M/)
      end

      it 'allows starting a new merge after quit' do
        command.call

        # Reset the conflicted file before attempting new merge
        repo.reset(nil, hard: true)

        # Create a non-conflicting branch
        repo.branch('other').checkout
        write_file('other.txt', "other content\n")
        repo.add('other.txt')
        repo.commit('Other commit')

        repo.checkout('main')

        # Should be able to merge cleanly
        expect { repo.merge('other') }.not_to raise_error
        expect(File.exist?(File.join(repo_dir, 'other.txt'))).to be true
      end
    end

    context 'when no merge is in progress' do
      it 'handles no active merge consistently across git versions' do
        # current_command_version returns an Array like [2, 42, 0]
        if repo.lib.compare_version_to(2, 35, 0) >= 0
          # git merge --quit succeeds even when no merge is in progress on git 2.35+
          expect { command.call }.not_to raise_error
        else
          # On older supported git versions (< 2.35), merge --quit may fail
          expect { command.call }.to raise_error(Git::FailedError)
        end
      end
    end

    context 'compared to abort behavior' do
      before do
        # Create conflict scenario
        repo.branch('feature').checkout
        write_file('file.txt', "feature\n")
        repo.add('file.txt')
        repo.commit('Feature')

        repo.checkout('main')
        write_file('file.txt', "main\n")
        repo.add('file.txt')
        repo.commit('Main')

        expect { repo.merge('feature') }.to raise_error(Git::FailedError)
      end

      it 'leaves conflict markers unlike abort which removes them' do
        # Record content with conflict markers
        conflicted_content = read_file('file.txt')
        expect(conflicted_content).to include('<<<<<<')

        command.call

        # Quit leaves conflict markers
        expect(read_file('file.txt')).to eq(conflicted_content)
        expect(read_file('file.txt')).to include('<<<<<<')
      end
    end

    context 'with multiple conflicting files' do
      before do
        write_file('file1.txt', "base1\n")
        write_file('file2.txt', "base2\n")
        repo.add('.')
        repo.commit('Add files')

        repo.branch('feature').checkout
        write_file('file1.txt', "feature1\n")
        write_file('file2.txt', "feature2\n")
        repo.add('.')
        repo.commit('Feature changes')

        repo.checkout('main')
        write_file('file1.txt', "main1\n")
        write_file('file2.txt', "main2\n")
        repo.add('.')
        repo.commit('Main changes')

        expect { repo.merge('feature') }.to raise_error(Git::FailedError)
      end

      it 'leaves all files with conflict markers' do
        command.call

        # Both files should still have conflicts
        expect(read_file('file1.txt')).to include('<<<<<<')
        expect(read_file('file2.txt')).to include('<<<<<<')
      end

      it 'shows both files as modified in status' do
        command.call

        status = repo.status
        expect(status['file1.txt']).not_to be_nil
        expect(status['file2.txt']).not_to be_nil
      end
    end
  end
end
