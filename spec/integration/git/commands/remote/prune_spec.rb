# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/remote/prune'

RSpec.describe Git::Commands::Remote::Prune, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  let(:remote_dir) { Dir.mktmpdir }
  let(:remote_repo) do
    test_repo = init_test_repo(remote_dir, initial_branch:)
    File.write(File.join(remote_dir, 'README.md'), "seed\n")
    test_repo.add('README.md')
    test_repo.commit('Initial commit')
    test_repo
  end

  after do
    FileUtils.rm_rf(remote_dir)
  end

  describe '#call' do
    context 'when the command succeeds' do
      it 'prunes stale tracking refs for a configured remote' do
        repo.remote_add('origin', remote_repo.dir.to_s)
        repo.fetch('origin')

        result = command.call('origin')

        expect(result).to be_a(Git::CommandLine::Result)
      end
    end

    context 'when the command fails' do
      it 'raises FailedError for a missing remote' do
        expect do
          command.call('origin', dry_run: true)
        end.to raise_error(Git::FailedError, /No such remote|remote repository/i)
      end
    end
  end
end
