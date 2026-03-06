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
      it 'returns a CommandLineResult' do
        result = command.call

        expect(result).to be_a(Git::CommandLineResult)
      end

      context 'with a revision range operand' do
        it 'returns a CommandLineResult' do
          first_sha = repo.lib.rev_parse('HEAD~1')
          result = command.call("#{first_sha}..")

          expect(result).to be_a(Git::CommandLineResult)
        end
      end
    end

    context 'when the command fails' do
      it 'raises FailedError for an invalid revision' do
        expect { command.call('nonexistent-branch') }.to raise_error(Git::FailedError)
      end
    end
  end
end
