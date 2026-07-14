# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/symbolic_ref/update'

RSpec.describe Git::Commands::SymbolicRef::Update, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'when the command succeeds' do
      it 'changes the symbolic ref target' do
        result = command.call('HEAD', 'refs/heads/new-branch')

        expect(result).to be_a(Git::CommandLine::Result)
        expect(result.status.exitstatus).to eq(0)

        head_content = File.read(File.join(repo_dir, '.git', 'HEAD')).strip
        expect(head_content).to eq('ref: refs/heads/new-branch')
      end
    end

    context 'when the command fails' do
      it 'raises FailedError when not in a git repository' do
        FileUtils.rm_rf(File.join(repo_dir, '.git'))

        # git's "not a git repository" message varies across versions — anchor on stable text
        expect { command.call('HEAD', 'refs/heads/main') }
          .to raise_error(Git::FailedError, /git repository/)
      end
    end
  end
end
