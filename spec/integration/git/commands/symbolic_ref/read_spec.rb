# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/symbolic_ref/read'

RSpec.describe Git::Commands::SymbolicRef::Read, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'when the command succeeds' do
      it 'returns the full ref path' do
        result = command.call('HEAD')

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.stdout.strip).to eq('refs/heads/main')
      end

      it 'returns the shortened ref name with :short' do
        result = command.call('HEAD', short: true)

        expect(result.stdout.strip).to eq('main')
      end

      context 'when HEAD is detached' do
        before do
          write_file('initial.txt', 'content')
          repo.add('initial.txt')
          repo.commit('initial')
          execution_context.command_capturing('checkout', '--detach', 'HEAD')
        end

        it 'returns exit status 1 without raising' do
          result = command.call('HEAD', quiet: true)

          expect(result.status.exitstatus).to eq(1)
        end
      end
    end

    context 'when the command fails' do
      it 'raises FailedError when not in a git repository' do
        FileUtils.rm_rf(File.join(repo_dir, '.git'))

        # git's "not a git repository" message varies across versions — anchor on stable text
        expect { command.call('HEAD') }.to raise_error(Git::FailedError, /git repository/)
      end
    end
  end
end
