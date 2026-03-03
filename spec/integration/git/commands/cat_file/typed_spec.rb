# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/cat_file/typed'

RSpec.describe Git::Commands::CatFile::Typed, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  before do
    write_file('README.md', "# Hello\n")
    repo.add('README.md')
    repo.commit('Initial commit')
  end

  describe '#call' do
    describe 'when the command succeeds' do
      it 'returns a CommandLineResult with non-empty output for a commit object' do
        result = command.call('commit', 'HEAD')
        expect(result).to be_a(Git::CommandLineResult)
        expect(result.status.exitstatus).to eq(0)
        expect(result.stdout).not_to be_empty
      end
    end

    describe 'when the command fails' do
      it 'raises FailedError for a mismatched type and object' do
        expect { command.call('tag', 'HEAD') }.to raise_error(Git::FailedError)
      end
    end
  end
end
