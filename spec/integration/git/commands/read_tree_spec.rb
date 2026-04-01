# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/read_tree'

RSpec.describe Git::Commands::ReadTree, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  before do
    write_file('file.txt', "content\n")
    repo.add('file.txt')
    repo.commit('Initial commit')
  end

  describe '#call' do
    context 'when the command succeeds' do
      it 'returns a CommandLineResult' do
        result = command.call('HEAD')

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'when the command fails' do
      it 'raises FailedError for an invalid tree-ish' do
        # git's error message phrasing varies by version — anchor on the stable input value
        expect { command.call('nonexistent-ref') }
          .to raise_error(Git::FailedError, /nonexistent-ref/)
      end
    end
  end
end
