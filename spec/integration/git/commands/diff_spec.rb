# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/diff'

RSpec.describe Git::Commands::Diff, :integration do
  include_context 'in a diff test repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'when the command succeeds' do
      it 'returns a CommandLineResult' do
        result = command.call('initial', 'after_modify',
                              numstat: true, shortstat: true,
                              src_prefix: 'a/', dst_prefix: 'b/')

        expect(result).to be_a(Git::CommandLine::Result)
        expect(result.stdout).not_to be_empty
      end

      it 'returns exit code 0 with no differences' do
        result = command.call('initial', 'initial',
                              numstat: true, shortstat: true,
                              src_prefix: 'a/', dst_prefix: 'b/')

        expect(result.status.exitstatus).to eq(0)
        expect(result.stdout).to be_empty
      end

      it 'returns exit code 1 with differences when exit_code: true' do
        result = command.call('initial', 'after_modify', exit_code: true)

        expect(result.status.exitstatus).to eq(1)
        expect(result.stdout).not_to be_empty
      end
    end

    context 'when the command fails' do
      it 'raises FailedError for invalid revision' do
        expect do
          command.call('nonexistent-ref', numstat: true, shortstat: true,
                                          src_prefix: 'a/', dst_prefix: 'b/')
        end.to raise_error(Git::FailedError, /nonexistent-ref/)
      end
    end

    context 'with --check option' do
      attr_reader :check_repo_dir, :check_command

      before(:all) do
        @check_repo_dir = Dir.mktmpdir
        check_repo = Git.init(@check_repo_dir, initial_branch: 'main')
        check_repo.config_set('user.email', 'test@example.com')
        check_repo.config_set('user.name', 'Test User')
        check_repo.config_set('commit.gpgsign', 'false')

        # Initial commit with clean content
        File.write(File.join(@check_repo_dir, 'file.txt'), "clean content\n")
        check_repo.add('file.txt')
        check_repo.commit('Initial commit')
        check_repo.tag_add('check_clean')

        # Commit that introduces trailing whitespace
        File.write(File.join(@check_repo_dir, 'file.txt'), "trailing whitespace   \n")
        check_repo.add('file.txt')
        check_repo.commit('Add trailing whitespace')
        check_repo.tag_add('check_dirty')

        @check_command = described_class.new(check_repo.execution_context)
      end

      after(:all) do
        FileUtils.rm_rf(@check_repo_dir) if @check_repo_dir
      end

      it 'returns exit code 0 when no whitespace issues are found' do
        result = check_command.call('check_clean', 'check_clean', check: true)
        expect(result.status.exitstatus).to eq(0)
      end

      it 'returns exit code 2 when whitespace issues are found' do
        result = check_command.call('check_clean', 'check_dirty', check: true)
        expect(result.status.exitstatus).to eq(2)
      end
    end
  end
end
