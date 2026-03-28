# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/am/quit'

RSpec.describe Git::Commands::Am::Quit, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'when the command succeeds' do
      before do
        write_file('file.txt', "base\n")
        repo.add('file.txt')
        repo.commit('Initial commit')

        # Create a patch that changes file.txt from "base" to "line2"
        write_file('file.txt', "line2\n")
        repo.add('file.txt')
        repo.commit('Change to line2')

        mbox_content = execution_context.command_capturing('format-patch', '--stdout', 'HEAD~1').stdout
        mbox_file = File.join(repo_dir, 'patches.mbox')
        File.write(mbox_file, mbox_content)

        # Reset to the initial commit and create a conflicting change
        repo.reset('HEAD~1', hard: true)
        write_file('file.txt', "conflict\n")
        repo.add('file.txt')
        repo.commit('Conflicting commit')

        # Start an am session — fails due to conflict, leaving rebase-apply state
        execution_context.command_capturing('am', mbox_file, chdir: repo_dir, raise_on_failure: false)
      end

      it 'returns a CommandLineResult' do
        result = command.call

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'when the command fails' do
      it 'raises FailedError when no am session is in progress' do
        expect { command.call }
          .to raise_error(Git::FailedError, /am/)
      end
    end
  end
end
