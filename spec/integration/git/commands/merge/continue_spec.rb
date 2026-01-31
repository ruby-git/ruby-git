# frozen_string_literal: true

require 'spec_helper'
require 'timeout'
require 'git/commands/merge/continue'

RSpec.describe Git::Commands::Merge::Continue, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  before do
    # Create initial commit
    write_file('file.txt', "base\n")
    repo.add('file.txt')
    repo.commit('Initial commit')
  end

  describe '#call' do
    context 'when conflicts have been resolved' do
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

        # Resolve the conflict
        write_file('file.txt', "resolved\n")
        repo.add('file.txt')
      end

      it 'completes the merge and creates a merge commit' do
        command.call

        # Verify we're no longer in a merge state
        expect { command.call }.to raise_error(Git::FailedError)

        # Verify merge commit was created
        log = repo.log.execute.first
        expect(log.message).to match(/merge/i)
        expect(log.parents.size).to eq(2)
      end

      it 'includes resolved content in the merge commit' do
        command.call

        # Verify the resolved content is in the working tree
        expect(read_file('file.txt')).to eq("resolved\n")
      end

      it 'returns a CommandLineResult' do
        result = command.call

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.stdout).to match(/merge/i)
      end
    end

    context 'when no merge is in progress' do
      it 'raises an error' do
        expect { command.call }.to raise_error(Git::FailedError, /no merge|not possible/)
      end
    end

    context 'when conflicts are not fully resolved' do
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

        # Do NOT resolve the conflict - leave conflict markers
      end

      it 'raises an error' do
        expect { command.call }.to raise_error(Git::FailedError, /unmerged|conflict/i)
      end
    end

    context 'with multiple conflicting files' do
      before do
        # Create multiple files
        write_file('file1.txt', "base1\n")
        write_file('file2.txt', "base2\n")
        repo.add('.')
        repo.commit('Add files')

        # Create feature branch with changes
        repo.branch('feature').checkout
        write_file('file1.txt', "feature1\n")
        write_file('file2.txt', "feature2\n")
        repo.add('.')
        repo.commit('Feature changes')

        # Create conflicting changes on main
        repo.checkout('main')
        write_file('file1.txt', "main1\n")
        write_file('file2.txt', "main2\n")
        repo.add('.')
        repo.commit('Main changes')

        # Start merge that will conflict
        expect { repo.merge('feature') }.to raise_error(Git::FailedError)

        # Resolve all conflicts
        write_file('file1.txt', "resolved1\n")
        write_file('file2.txt', "resolved2\n")
        repo.add('.')
      end

      it 'completes merge with all conflicts resolved' do
        command.call

        # Verify both files have resolved content
        expect(read_file('file1.txt')).to eq("resolved1\n")
        expect(read_file('file2.txt')).to eq("resolved2\n")

        # Verify merge commit was created
        expect(repo.log.execute.first.parents.size).to eq(2)
      end
    end

    context 'when continuing merge does not require editor' do
      before do
        # Create a simple conflict scenario
        repo.branch('feature').checkout
        write_file('file.txt', "feature\n")
        repo.add('file.txt')
        repo.commit('Feature')

        repo.checkout('main')
        write_file('file.txt', "main\n")
        repo.add('file.txt')
        repo.commit('Main')

        expect { repo.merge('feature') }.to raise_error(Git::FailedError)

        write_file('file.txt', "resolved\n")
        repo.add('file.txt')
      end

      it 'completes without opening an editor' do
        # This test verifies that merge --continue completes without hanging
        # or requiring user interaction. GIT_EDITOR is set to 'true' (a no-op)
        # so Git proceeds without interactive editing.
        result = nil
        expect do
          result = Timeout.timeout(5) { command.call }
        end.not_to raise_error

        expect(result).to be_a(Git::CommandLineResult)
      end
    end
  end
end
