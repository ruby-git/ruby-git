# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/merge/start'

RSpec.describe Git::Commands::Merge::Start, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  before do
    write_file('file.txt', "base\n")
    repo.add('file.txt')
    repo.commit('Initial commit')
  end

  describe '#call' do
    describe 'when the command succeeds' do
      before do
        repo.branch('feature').checkout
        write_file('feature.txt', "feature\n")
        repo.add('feature.txt')
        repo.commit('Feature commit')
        repo.checkout('main')
      end

      it 'returns a CommandLineResult' do
        result = command.call('feature')

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    describe 'when the command fails' do
      it 'raises FailedError with conflicting changes' do
        repo.branch('feature').checkout
        write_file('file.txt', "feature change\n")
        repo.add('file.txt')
        repo.commit('Feature commit')

        repo.checkout('main')
        write_file('file.txt', "main change\n")
        repo.add('file.txt')
        repo.commit('Main commit')

        expect { command.call('feature') }.to raise_error(Git::FailedError)
      end

      it 'raises FailedError with a nonexistent ref' do
        expect { command.call('nonexistent') }.to raise_error(Git::FailedError)
      end
    end
  end
end
