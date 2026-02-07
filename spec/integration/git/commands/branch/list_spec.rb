# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/branch/list'

RSpec.describe Git::Commands::Branch::List, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    it 'returns a CommandLineResult with output' do
      write_file('file.txt')
      repo.add('file.txt')
      repo.commit('Initial commit')

      result = command.call

      expect(result).to be_a(Git::CommandLineResult)
      expect(result.stdout).not_to be_empty
    end

    it 'returns empty output when there are no branches' do
      result = command.call

      expect(result).to be_a(Git::CommandLineResult)
      expect(result.stdout).to be_empty
    end

    it 'raises FailedError for invalid options' do
      write_file('file.txt')
      repo.add('file.txt')
      repo.commit('Initial commit')

      expect { command.call(sort: 'invalid-key') }.to raise_error(Git::FailedError)
    end
  end
end
