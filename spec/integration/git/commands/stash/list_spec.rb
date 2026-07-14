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
    describe 'when the command succeeds' do
      context 'with stashes' do
        before do
          write_file('file.txt', 'modified content')
          repo.stash_save('WIP on feature')
        end

        it 'returns CommandLineResult with output' do
          result = command.call

          expect(result).to be_a(Git::CommandLine::Result)
          expect(result.status.exitstatus).to eq(0)
          expect(result.stdout).not_to be_empty
        end
      end
    end

    describe 'when the command fails' do
      before { FileUtils.rm_rf(File.join(repo_dir, '.git')) }

      it 'raises FailedError when the repository is missing' do
        expect { command.call }.to raise_error(Git::FailedError)
      end
    end
  end
end
