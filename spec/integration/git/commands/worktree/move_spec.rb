# frozen_string_literal: true

require 'securerandom'
require 'spec_helper'
require 'git/commands/worktree/move'

RSpec.describe Git::Commands::Worktree::Move, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  before do
    write_file('README.md', "# Hello\n")
    repo.add('README.md')
    repo.commit('Initial commit')
  end

  describe '#call' do
    context 'when the command succeeds' do
      let(:src_path) { File.join(repo_dir, '..', "worktree-src-#{SecureRandom.hex(4)}") }
      let(:dst_path) { File.join(repo_dir, '..', "worktree-dst-#{SecureRandom.hex(4)}") }

      before do
        execution_context.command_capturing(
          'worktree', 'add', '--', src_path,
          env: { 'GIT_INDEX_FILE' => nil }
        )
      end

      after do
        FileUtils.rm_rf(src_path)
        FileUtils.rm_rf(dst_path)
      end

      it 'returns a CommandLineResult' do
        result = command.call(src_path, dst_path)
        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'when the command fails' do
      it 'raises FailedError for a nonexistent worktree path' do
        expect { command.call('/nonexistent/path/xyz', '/tmp/dst') }
          .to raise_error(Git::FailedError, /nonexistent/)
      end
    end
  end
end
