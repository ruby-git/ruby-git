# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/stash/show'

RSpec.describe Git::Commands::Stash::Show, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  before do
    write_file('file.txt', "content\n")
    repo.add('file.txt')
    repo.commit('Initial commit')

    write_file('file.txt', "modified\n")
    repo.lib.stash_save('WIP')
  end

  describe '#call' do
    describe 'when the command succeeds' do
      it 'returns a CommandLineResult with numstat output' do
        result = command.call(numstat: true, shortstat: true)

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.stdout).not_to be_empty
      end

      it 'returns a CommandLineResult with patch output' do
        result = command.call(patch: true, numstat: true, shortstat: true)

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.stdout).not_to be_empty
      end

      it 'returns a CommandLineResult with raw output' do
        result = command.call(raw: true)

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.stdout).not_to be_empty
      end
    end

    describe 'when the command fails' do
      it 'raises FailedError with a nonexistent stash' do
        expect { command.call('stash@{99}', numstat: true, shortstat: true) }.to raise_error(Git::FailedError)
      end
    end
  end
end
