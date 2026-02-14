# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/merge/quit'

RSpec.describe Git::Commands::Merge::Quit, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  before do
    write_file('file.txt', "base\n")
    repo.add('file.txt')
    repo.commit('Initial commit')
  end

  describe '#call' do
    describe 'when the command succeeds' do
      context 'when a merge is in progress' do
        before do
          repo.branch('feature').checkout
          write_file('file.txt', "feature change\n")
          repo.add('file.txt')
          repo.commit('Feature commit')

          repo.checkout('main')
          write_file('file.txt', "main change\n")
          repo.add('file.txt')
          repo.commit('Main commit')

          expect { repo.merge('feature') }.to raise_error(Git::FailedError)
        end

        it 'returns a CommandLineResult' do
          result = command.call

          expect(result).to be_a(Git::CommandLineResult)
        end
      end

      it 'succeeds when no merge is in progress (git 2.35+)' do
        skip 'git < 2.35' if repo.lib.compare_version_to(2, 35, 0) < 0
        expect { command.call }.not_to raise_error
      end
    end

    describe 'when the command fails' do
      it 'raises FailedError when no merge is in progress (git < 2.35)' do
        skip 'git >= 2.35' if repo.lib.compare_version_to(2, 35, 0) >= 0
        expect { command.call }.to raise_error(Git::FailedError)
      end
    end
  end
end
