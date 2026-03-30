# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/revert/abort'

RSpec.describe Git::Commands::Revert::Abort, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  before do
    write_file('file.txt', "base\n")
    repo.add('file.txt')
    repo.commit('Initial commit')

    # Second commit — the one whose revert will conflict with the third
    write_file('file.txt', "version2\n")
    repo.add('file.txt')
    repo.commit('Second commit')

    # Third commit — conflicts with reverting the second
    write_file('file.txt', "version3\n")
    repo.add('file.txt')
    repo.commit('Third commit')
  end

  describe '#call' do
    context 'when the command succeeds' do
      before do
        # Attempt revert of second commit — conflicts with third, leaving session open
        execution_context.command_capturing(
          'revert', '--no-edit', 'HEAD~1',
          chdir: repo_dir, raise_on_failure: false
        )
      end

      it 'returns a CommandLineResult' do
        result = command.call

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'when the command fails' do
      it 'raises FailedError when no revert is in progress' do
        # git error message varies by version — anchor on the stable subcommand keyword
        expect { command.call }.to raise_error(Git::FailedError, /revert/)
      end
    end
  end
end
