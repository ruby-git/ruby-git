# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/log'

RSpec.describe Git::Commands::Log, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  before do
    write_file('file.txt', "initial content\n")
    repo.add('file.txt')
    repo.commit('Initial commit')

    write_file('other.txt', "other content\n")
    repo.add('other.txt')
    repo.commit('Second commit')
  end

  describe '#call' do
    context 'when the command succeeds' do
      it 'returns a CommandLineResult with non-empty output' do
        result = command.call

        expect(result).to be_a(Git::CommandLine::Result)
        expect(result.stdout).not_to be_empty
      end
    end

    context 'when the command fails' do
      it 'raises FailedError for an invalid revision' do
        expect { command.call('nonexistent-branch') }
          .to raise_error(Git::FailedError, /nonexistent-branch/)
      end
    end
  end
end
