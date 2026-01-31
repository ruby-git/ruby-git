# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/merge/abort'

RSpec.describe Git::Commands::Merge::Abort, :integration do
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

      it 'aborts the merge and restores pre-merge state' do
        command.call

        # Verify file content is restored to pre-merge state
        expect(read_file('file.txt')).to eq("main change\n")

        # Verify no changes are staged or modified
        status = repo.status
        expect(status.changed).to be_empty
        expect(status.added).to be_empty
        expect(status.deleted).to be_empty
        expect(status.untracked).to be_empty
      end

      it 'removes merge conflict markers' do
        # Verify conflict markers exist before abort
        expect(read_file('file.txt')).to include('<<<<<<')

        command.call

        # Verify conflict markers are removed
        expect(read_file('file.txt')).not_to include('<<<<<<')
      end

      it 'allows starting a new merge after abort' do
        command.call

        # Create a different non-conflicting branch
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
      it 'raises an error' do
        expect { command.call }.to raise_error(Git::FailedError, /no merge|not possible/)
      end
    end

    context 'with uncommitted changes before merge' do
      before do
        # Create feature branch
        repo.branch('feature').checkout
        write_file('feature.txt', "feature\n")
        repo.add('feature.txt')
        repo.commit('Feature commit')

        repo.checkout('main')

        # Create uncommitted change
        write_file('uncommitted.txt', "uncommitted\n")
        repo.add('uncommitted.txt')

        # Start merge that conflicts
        write_file('file.txt', "main change\n")
        repo.add('file.txt')
        repo.commit('Main commit')

        repo.branch('feature').checkout
        write_file('file.txt', "feature change\n")
        repo.add('file.txt')
        repo.commit('Feature conflict')

        repo.checkout('main')
        expect { repo.merge('feature') }.to raise_error(Git::FailedError)
      end

      it 'attempts to restore pre-merge state' do
        # NOTE: Git's behavior with uncommitted changes during merge abort
        # can vary, but it should attempt to preserve them
        command.call

        # The main file should be restored
        expect(read_file('file.txt')).to eq("main change\n")
      end
    end
  end
end
