# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/describe'

RSpec.describe Git::Commands::Describe, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  before do
    write_file('file.txt', 'content')
    repo.add('file.txt')
    repo.commit('Initial commit')
    repo.tag_add('v1.0.0')
  end

  describe '#call' do
    describe 'when the command succeeds' do
      it 'returns a CommandLineResult describing HEAD' do
        result = command.call(tags: true)

        expect(result).to be_a(Git::CommandLine::Result)
        expect(result.stdout).not_to be_empty
      end
    end

    describe 'when the command fails' do
      it 'raises FailedError for a nonexistent commit-ish' do
        expect { command.call('nonexistent-sha') }.to raise_error(Git::FailedError)
      end
    end
  end
end
