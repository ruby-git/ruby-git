# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/diff'

RSpec.describe Git::Commands::Diff, :integration do
  include_context 'in a diff test repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    describe 'with numstat output mode' do
      it 'returns a CommandLineResult with numstat output' do
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
    end

    describe 'with patch output mode' do
      it 'returns a CommandLineResult with patch output' do
        result = command.call('initial', 'after_modify',
                              patch: true, numstat: true, shortstat: true,
                              src_prefix: 'a/', dst_prefix: 'b/')

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.stdout).not_to be_empty
        expect(result.stdout).to include('diff --git')
      end
    end

    describe 'with raw output mode' do
      it 'returns a CommandLineResult with raw output' do
        result = command.call('initial', 'after_modify',
                              raw: true, numstat: true, shortstat: true,
                              src_prefix: 'a/', dst_prefix: 'b/')

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.stdout).not_to be_empty
      end
    end

    describe 'when the command fails' do
      it 'raises FailedError for invalid revision' do
        expect do
          command.call('nonexistent-ref', numstat: true, shortstat: true,
                                          src_prefix: 'a/', dst_prefix: 'b/')
        end.to raise_error(Git::FailedError)
      end
    end
  end
end
