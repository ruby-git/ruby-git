# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/show_ref/verify'

RSpec.describe Git::Commands::ShowRef::Verify, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  before do
    write_file('file.txt', "content\n")
    repo.add('.')
    repo.commit('Initial commit')
  end

  describe '#call' do
    context 'when the command succeeds' do
      it 'returns a CommandLineResult' do
        result = command.call('refs/heads/main')

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'returns exit status 0 for an existing ref' do
        result = command.call('refs/heads/main')

        expect(result.status.exitstatus).to eq(0)
      end
    end

    context 'when the command fails' do
      it 'raises FailedError for a nonexistent ref' do
        expect { command.call('refs/heads/nonexistent') }
          .to raise_error(Git::FailedError, /nonexistent/)
      end

      it 'raises FailedError when not in a git repository' do
        FileUtils.rm_rf(File.join(repo_dir, '.git'))

        expect { command.call('refs/heads/main') }
          .to raise_error(Git::FailedError, /git repository/)
      end
    end
  end
end
