# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/cat_file/batch'

RSpec.describe Git::Commands::CatFile::Batch, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  before do
    write_file('README.md', "# Hello\n")
    repo.add('README.md')
    repo.commit('Initial commit')
  end

  describe '#call' do
    context 'when the command succeeds' do
      context 'with --batch mode' do
        it 'returns a CommandLineResult with output for the specified object' do
          result = command.call('HEAD:README.md', batch: true)

          expect(result).to be_a(Git::CommandLine::Result)
          expect(result.stdout).not_to be_empty
        end
      end
    end

    context 'when the command fails' do
      it 'raises FailedError when the git repository is corrupted' do
        FileUtils.rm_rf(File.join(repo_dir, '.git'))

        expect { command.call('HEAD', batch: true) }.to raise_error(Git::FailedError)
      end
    end
  end
end
