# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/ls_files'

RSpec.describe Git::Commands::LsFiles, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  before do
    write_file('tracked.txt', "content\n")
    repo.add('tracked.txt')
    repo.commit('Initial commit')
  end

  describe '#call' do
    context 'when the command succeeds' do
      context 'with no arguments' do
        it 'returns a CommandLineResult' do
          result = command.call

          expect(result).to be_a(Git::CommandLine::Result)
        end
      end
    end

    context 'when the command fails' do
      it 'raises FailedError when a path is not in the index' do
        expect { command.call('nonexistent.txt', error_unmatch: true) }
          .to raise_error(Git::FailedError)
      end
    end
  end
end
