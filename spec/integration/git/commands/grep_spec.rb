# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/grep'

RSpec.describe Git::Commands::Grep, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  before do
    write_file('file.txt', "hello\nworld\nfoo bar\n")
    write_file('other.txt', "nothing here\nfoo baz\n")
    repo.add('.')
    repo.commit('Initial commit')
  end

  describe '#call' do
    context 'when the command succeeds (matches found)' do
      it 'returns a CommandLineResult with exit status 0' do
        result = command.call('HEAD', pattern: 'foo')

        expect(result).to be_a(Git::CommandLine::Result)
        expect(result.status.exitstatus).to eq(0)
        expect(result.stdout).to include('foo')
      end
    end

    context 'when no lines are selected (no matches)' do
      it 'returns exit status 1 without raising an error' do
        result = command.call('HEAD', pattern: 'nonexistent_pattern_xyz')

        expect(result.status.exitstatus).to eq(1)
        expect(result.stdout).to be_empty
      end
    end
  end
end
