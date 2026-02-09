# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/stash/list'

# Integration tests for Git::Commands::Stash::List
#
RSpec.describe Git::Commands::Stash::List, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  before do
    write_file('file.txt', 'initial content')
    repo.add('file.txt')
    repo.commit('Initial commit')
  end

  describe '#call' do
    context 'with no stashes' do
      it 'returns CommandLineResult with empty output' do
        result = command.call

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.status.exitstatus).to eq(0)
        expect(result.stdout).to be_empty
      end
    end

    context 'with stashes' do
      before do
        write_file('file.txt', 'modified content')
        repo.lib.stash_save('WIP on feature')
      end

      it 'returns CommandLineResult with output' do
        result = command.call

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.status.exitstatus).to eq(0)
        expect(result.stdout).not_to be_empty
      end
    end
  end
end
