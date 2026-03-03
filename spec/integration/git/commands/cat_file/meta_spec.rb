# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/cat_file/meta'

RSpec.describe Git::Commands::CatFile::Meta, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  before do
    write_file('README.md', "# Hello\n")
    repo.add('README.md')
    repo.commit('Initial commit')
  end

  describe '#call' do
    describe 'when the command succeeds' do
      it 'returns a CommandLineResult for a single object' do
        result = command.call('HEAD')
        expect(result).to be_a(Git::CommandLineResult)
        expect(result.status.exitstatus).to eq(0)
        expect(result.stdout).not_to be_empty
      end

      it 'returns a non-empty result for multiple objects' do
        result = command.call('HEAD', 'HEAD:README.md')
        expect(result.status.exitstatus).to eq(0)
        expect(result.stdout).not_to be_empty
      end

      it 'returns a non-empty result with batch_all_objects' do
        result = command.call(batch_all_objects: true)
        expect(result.status.exitstatus).to eq(0)
        expect(result.stdout).not_to be_empty
      end

      it 'returns exit 0 for a missing object (reported inline)' do
        result = command.call('not-a-valid-ref')
        expect(result.status.exitstatus).to eq(0)
      end
    end

    describe 'when the command fails' do
      it 'raises FailedError when the repository is not valid' do
        FileUtils.rm_rf(File.join(repo_dir, '.git'))
        expect { command.call('HEAD') }.to raise_error(Git::FailedError)
      end
    end
  end
end
