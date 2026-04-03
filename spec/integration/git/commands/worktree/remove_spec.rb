# frozen_string_literal: true

require 'securerandom'
require 'spec_helper'
require 'git/commands/worktree/remove'

RSpec.describe Git::Commands::Worktree::Remove, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  before do
    write_file('README.md', "# Hello\n")
    repo.add('README.md')
    repo.commit('Initial commit')
  end

  describe '#call' do
    context 'when the command succeeds' do
      let(:worktree_path) { File.join(repo_dir, '..', "worktree-remove-#{SecureRandom.hex(4)}") }

      before do
        execution_context.command_capturing('worktree', 'add', '--', worktree_path, env: { 'GIT_INDEX_FILE' => nil })
      end
      after { FileUtils.rm_rf(worktree_path) }

      it 'returns a CommandLineResult' do
        result = command.call(worktree_path)
        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'removes the worktree directory from disk' do
        command.call(worktree_path)
        expect(File.directory?(worktree_path)).to be(false)
      end
    end

    context 'when the command fails' do
      it 'raises FailedError for a nonexistent worktree path' do
        expect { command.call('/nonexistent/path/xyz') }
          .to raise_error(Git::FailedError, /nonexistent/)
      end
    end
  end
end
