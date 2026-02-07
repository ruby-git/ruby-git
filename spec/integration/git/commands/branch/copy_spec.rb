# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/branch/copy'

RSpec.describe Git::Commands::Branch::Copy, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    before do
      write_file('file.txt', 'content')
      repo.add('file.txt')
      repo.commit('Initial commit')
    end

    it 'returns a CommandLineResult' do
      result = command.call('main-copy')

      expect(result).to be_a(Git::CommandLineResult)
    end

    it 'preserves the original branch' do
      command.call('main-copy')

      branch_list = repo.branches.local.map(&:name)
      expect(branch_list).to include('main', 'main-copy')
    end

    it 'raises FailedError when target exists without force' do
      repo.branch('existing').create

      expect { command.call('existing') }.to raise_error(Git::FailedError)
    end
  end
end
