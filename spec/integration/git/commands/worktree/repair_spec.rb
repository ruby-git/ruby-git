# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/worktree/repair'

RSpec.describe Git::Commands::Worktree::Repair, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  before do
    write_file('README.md', "# Hello\n")
    repo.add('README.md')
    repo.commit('Initial commit')
  end

  describe '#call' do
    context 'when the command succeeds' do
      it 'returns a CommandLineResult' do
        # git worktree repair inspects the CWD to detect linked worktree context;
        # run from within the repo directory so it does not mistakenly scan the
        # test runner's CWD.
        Dir.chdir(repo_dir) do
          result = command.call
          expect(result).to be_a(Git::CommandLineResult)
        end
      end
    end

    context 'when the command fails' do
      it 'raises FailedError outside a git repository' do
        Dir.chdir(repo_dir) do
          FileUtils.rm_rf(File.join(repo_dir, '.git'))
          expect { command.call }
            .to raise_error(Git::FailedError, /not a git repository/)
        end
      end
    end
  end
end
