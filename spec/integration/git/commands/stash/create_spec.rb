# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/stash/create'

RSpec.describe Git::Commands::Stash::Create, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  before do
    write_file('file.txt', "content\n")
    repo.add('file.txt')
    repo.commit('Initial commit')
  end

  describe '#call' do
    describe 'when the command succeeds' do
      context 'with local changes' do
        before { write_file('file.txt', "modified\n") }

        it 'returns a CommandLineResult with output' do
          result = command.call

          expect(result).to be_a(Git::CommandLineResult)
          expect(result.stdout.strip).not_to be_empty
        end
      end

      context 'with no local changes' do
        it 'returns a CommandLineResult with empty output' do
          result = command.call

          expect(result).to be_a(Git::CommandLineResult)
          expect(result.stdout.strip).to be_empty
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
