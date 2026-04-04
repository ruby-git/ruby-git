# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/show'

RSpec.describe Git::Commands::Show, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  before do
    write_file('test.txt', "Hello, World!\n")
    repo.add('test.txt')
    repo.commit('Initial commit')
  end

  describe '#call' do
    context 'when the command succeeds' do
      it 'returns a CommandLineResult with commit information' do
        result = command.call('HEAD')

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.status.success?).to be true
        expect(result.stdout).not_to be_empty
      end
    end

    context 'with out: streaming to a StringIO' do
      it 'streams blob content into the IO object' do
        io = StringIO.new
        result = command.call('HEAD:test.txt', out: io)

        expect(io.string).to eq("Hello, World!\n")
        expect(result.stdout).to eq('')
      end
    end

    context 'when the command fails' do
      it 'raises FailedError for a nonexistent object' do
        expect { command.call('nonexistent-ref-xyz') }
          .to raise_error(Git::FailedError, /nonexistent-ref-xyz/)
      end
    end
  end
end
