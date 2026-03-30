# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/revert/start'

RSpec.describe Git::Commands::Revert::Start, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  before do
    write_file('file.txt', "base\n")
    repo.add('file.txt')
    repo.commit('Initial commit')

    write_file('file.txt', "updated\n")
    repo.add('file.txt')
    repo.commit('Second commit')
  end

  describe '#call' do
    context 'when the command succeeds' do
      it 'returns a CommandLineResult' do
        result = command.call('HEAD')

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'when the command fails' do
      it 'raises FailedError for a nonexistent commit' do
        # git's error message phrasing varies by version — anchor on the stable input value
        expect { command.call('nonexistent') }
          .to raise_error(Git::FailedError, /nonexistent/)
      end
    end
  end
end
