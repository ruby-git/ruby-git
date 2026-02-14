# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/merge_base'

RSpec.describe Git::Commands::MergeBase, :integration do
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

      it 'returns an Array of commit SHAs' do
        result = command.call('main', 'feature')

        expect(result).to be_an(Array)
        expect(result).not_to be_empty
      end
    end

    describe 'when the command fails' do
      it 'raises FailedError with a nonexistent ref' do
        expect { command.call('main', 'nonexistent') }.to raise_error(Git::FailedError)
      end
    end
  end
end
