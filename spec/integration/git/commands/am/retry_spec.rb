# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/am/retry'

RSpec.describe Git::Commands::Am::Retry, :integration,
               skip: unless_git('2.46', 'git am --retry') do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'when the command succeeds' do
      before do
        write_file('file.txt', "base\n")
        repo.add('file.txt')
        repo.commit('Initial commit')

        # Create a patch that changes file.txt from "base" to "changed"
        write_file('file.txt', "changed\n")
        repo.add('file.txt')
        repo.commit('Change to changed')

        mbox_content = execution_context.command_capturing(
          'format-patch', '--stdout', 'HEAD~1', raise_on_failure: false
        ).stdout
        mbox_file = File.join(repo_dir, 'patches.mbox')
        File.write(mbox_file, mbox_content)

        # Reset to initial state, then create a conflicting commit so the apply fails
        repo.reset('HEAD~1', hard: true)
        write_file('file.txt', "conflict\n")
        repo.add('file.txt')
        repo.commit('Conflicting commit')

        # Start am session — fails due to conflict, persisting .git/rebase-apply/
        execution_context.command_capturing('am', '--', mbox_file, chdir: repo_dir, raise_on_failure: false)

        # Remove the conflicting commit so the retry can apply the patch cleanly
        repo.reset('HEAD~1', hard: true)
      end

      it 'returns a CommandLineResult' do
        result = command.call

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'when the command fails' do
      it 'raises FailedError when no am session is in progress' do
        expect { command.call }
          .to raise_error(Git::FailedError, /--retry/)
      end
    end
  end
end
