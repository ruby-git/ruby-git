# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/branch/create'

RSpec.describe Git::Commands::Branch::Create, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    before do
      write_file('file.txt', 'content')
      repo.add('file.txt')
      repo.commit('Initial commit')
    end

    context 'when the command succeeds' do
      it 'returns a Git::CommandLine::Result' do
        result = command.call('feature-branch')

        expect(result).to be_a(Git::CommandLine::Result)
      end

      it 'creates the branch without switching to it' do
        current = repo.current_branch

        command.call('feature-branch')

        expect(repo.local_branch?('feature-branch')).to be(true)
        expect(repo.current_branch).to eq(current)
      end
    end

    context 'when the command fails' do
      it 'raises FailedError when the branch already exists' do
        repo.branch_new('existing-branch')

        expect { command.call('existing-branch') }.to raise_error(Git::FailedError, /existing-branch/)
      end
    end
  end
end
