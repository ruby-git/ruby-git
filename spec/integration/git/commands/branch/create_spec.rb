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

    it 'returns a CommandLineResult' do
      result = command.call('feature-branch')

      expect(result).to be_a(Git::CommandLineResult)
    end

    it 'creates the branch in the repository' do
      command.call('feature-branch')

      branch_list = repo.branches.local.map(&:name)
      expect(branch_list).to include('feature-branch')
    end

    it 'raises FailedError when the branch already exists' do
      repo.branch('existing-branch').create

      expect { command.call('existing-branch') }.to raise_error(Git::FailedError)
    end
  end
end
