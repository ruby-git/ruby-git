# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/show_ref/exclude_existing'

RSpec.describe Git::Commands::ShowRef::ExcludeExisting, :integration do
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
        result = command.call

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'returns exit status 0' do
        result = command.call

        expect(result.status.exitstatus).to eq(0)
      end

      it 'returns exit status 0 with a mix of existing and nonexistent refs' do
        result = command.call('refs/heads/main', 'refs/heads/nonexistent')

        expect(result.status.exitstatus).to eq(0)
      end

      it 'echoes only refs that do not already exist locally' do
        result = command.call('refs/heads/main', 'refs/heads/nonexistent')

        stdout_refs = result.stdout.lines.map(&:chomp).reject(&:empty?)
        expect(stdout_refs).to eq(['refs/heads/nonexistent'])
      end
    end

    context 'when the command fails' do
      it 'raises FailedError when not in a git repository' do
        FileUtils.rm_rf(File.join(repo_dir, '.git'))

        expect { command.call }
          .to raise_error(Git::FailedError, /git repository/)
      end
    end
  end
end
