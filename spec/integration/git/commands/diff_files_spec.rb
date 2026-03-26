# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/diff_files'

RSpec.describe Git::Commands::DiffFiles, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  before do
    write_file('file.txt', "initial content\n")
    repo.add('.')
    repo.commit('Initial commit')
  end

  describe '#call' do
    context 'when the command succeeds' do
      it 'returns a CommandLineResult with exit code 0 when no unstaged changes exist' do
        result = command.call
        expect(result).to be_a(Git::CommandLineResult)
        expect(result.status.exitstatus).to eq(0)
      end

      it 'returns a CommandLineResult with diff output when unstaged changes exist' do
        write_file('file.txt', "modified content\n")

        result = command.call
        expect(result).to be_a(Git::CommandLineResult)
        expect(result.stdout).not_to be_empty
      end

      it 'accepts a path operand and returns a CommandLineResult' do
        result = command.call('file.txt')
        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'when the command fails' do
      it 'raises FailedError when not in a git repository' do
        FileUtils.rm_rf(File.join(repo_dir, '.git'))

        # git's "not a git repository" message varies across versions — anchor on stable text
        expect { command.call }.to raise_error(Git::FailedError, /git repository/)
      end
    end
  end
end
