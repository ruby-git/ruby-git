# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/worktree/list'

RSpec.describe Git::Commands::Worktree::List, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  before do
    write_file('README.md', "# Hello\n")
    repo.add('README.md')
    repo.commit('Initial commit')
  end

  describe '#call' do
    context 'when the command succeeds' do
      it 'returns a CommandLineResult with no options' do
        result = command.call
        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'returns a CommandLineResult with the :porcelain option' do
        result = command.call(porcelain: true)
        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'returns a CommandLineResult with the :verbose option',
         skip: unless_git('2.33.0', 'git worktree list --verbose') do
        result = command.call(verbose: true)
        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'returns a CommandLineResult with the :z option combined with :porcelain',
         skip: unless_git('2.36.0', 'git worktree list --porcelain -z') do
        result = command.call(porcelain: true, z: true)
        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'returns a CommandLineResult with the :expire option',
         skip: unless_git('2.33.0', 'git worktree list --expire') do
        result = command.call(expire: '2.weeks.ago')
        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'when the command fails' do
      it 'raises FailedError when not in a git repository' do
        FileUtils.rm_rf(File.join(repo_dir, '.git'))
        expect { command.call }.to raise_error(Git::FailedError, /not a git repository/)
      end
    end
  end
end
