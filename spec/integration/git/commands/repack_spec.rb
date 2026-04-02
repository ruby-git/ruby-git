# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/repack'

RSpec.describe Git::Commands::Repack, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'when the command succeeds' do
      it 'returns a CommandLineResult' do
        result = command.call

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.status.exitstatus).to eq(0)
      end

      it 'returns a CommandLineResult with :a and :d options' do
        result = command.call(a: true, d: true)

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.status.exitstatus).to eq(0)
      end
    end

    context 'when the command fails' do
      it 'raises FailedError when not in a git repository' do
        FileUtils.rm_rf(File.join(repo_dir, '.git'))

        # git's "not a git repository" message varies across versions — anchor on stable text
        expect { command.call }.to raise_error(Git::FailedError, /git repository/)
      end
    end
  end
end
