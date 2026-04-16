# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/diff'

RSpec.describe Git::Commands::Diff, :integration do
  include_context 'in a diff test repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'when the command succeeds' do
      it 'returns a CommandLineResult' do
        result = command.call('initial', 'after_modify',
                              numstat: true, shortstat: true,
                              src_prefix: 'a/', dst_prefix: 'b/')

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.stdout).not_to be_empty
      end

      it 'returns exit code 0 with no differences' do
        result = command.call('initial', 'initial',
                              numstat: true, shortstat: true,
                              src_prefix: 'a/', dst_prefix: 'b/')

        expect(result.status.exitstatus).to eq(0)
        expect(result.stdout).to be_empty
      end

      it 'returns exit code 1 with differences when exit_code: true' do
        result = command.call('initial', 'after_modify', exit_code: true)

        expect(result.status.exitstatus).to eq(1)
        expect(result.stdout).not_to be_empty
      end
    end

    context 'when the command fails' do
      it 'raises FailedError for invalid revision' do
        expect do
          command.call('nonexistent-ref', numstat: true, shortstat: true,
                                          src_prefix: 'a/', dst_prefix: 'b/')
        end.to raise_error(Git::FailedError, /nonexistent-ref/)
      end
    end
  end
end
