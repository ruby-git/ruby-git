# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/stash/drop'

RSpec.describe Git::Commands::Stash::Drop, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  before do
    write_file('file.txt', "content\n")
    repo.add('file.txt')
    repo.commit('Initial commit')
  end

  describe '#call' do
    describe 'when the command succeeds' do
      before do
        write_file('file.txt', "modified\n")
        repo.lib.stash_save('WIP')
      end

      it 'returns a CommandLineResult' do
        result = command.call

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    describe 'when the command fails' do
      it 'raises FailedError with no stash entries' do
        expect { command.call }.to raise_error(Git::FailedError)
      end
    end
  end
end
