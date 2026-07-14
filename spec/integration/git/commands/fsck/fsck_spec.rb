# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/fsck'

# Integration tests for Git::Commands::Fsck
#
# These tests verify the command's execution behavior. Parsing logic is
# tested separately in spec/integration/git/fsck_parser_spec.rb.
#
RSpec.describe Git::Commands::Fsck, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    before do
      write_file('file.txt', 'content')
      repo.add('file.txt')
      repo.commit('Initial commit')
    end

    describe 'when the command succeeds' do
      it 'returns a CommandLineResult' do
        result = command.call

        expect(result).to be_a(Git::CommandLine::Result)
      end
    end

    describe 'when the command fails' do
      it 'raises FailedError' do
        # Remove the repository to trigger a fatal git error (exit 128 > 7)
        FileUtils.rm_rf(File.join(repo_dir, '.git'))

        expect { command.call }.to raise_error(Git::FailedError)
      end
    end
  end
end
