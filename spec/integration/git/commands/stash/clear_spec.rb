# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/stash/clear'
require 'git/commands/stash/list'

RSpec.describe Git::Commands::Stash::Clear, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  before do
    # Create initial commit
    write_file('file.txt', "initial content\n")
    repo.add('file.txt')
    repo.commit('Initial commit')
  end

  describe '#call' do
    it 'returns CommandLineResult' do
      result = command.call

      expect(result).to be_a(Git::CommandLineResult)
      expect(result.status.exitstatus).to eq(0)
    end
  end
end
