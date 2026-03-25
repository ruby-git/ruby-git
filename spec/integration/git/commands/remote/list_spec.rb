# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/remote/list'

RSpec.describe Git::Commands::Remote::List, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  let(:remote_dir) { Dir.mktmpdir }
  let(:remote_repo) do
    test_repo = Git.init(remote_dir, initial_branch:)
    test_repo.config('user.email', 'test@example.com')
    test_repo.config('user.name', 'Test User')
    test_repo
  end

  after do
    FileUtils.rm_rf(remote_dir)
  end

  describe '#call' do
    context 'when the command succeeds' do
      it 'lists configured remotes' do
        repo.add_remote('origin', remote_repo.dir.to_s)

        result = command.call

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.stdout.lines.map(&:strip)).to include('origin')
      end
    end

    context 'when the command fails' do
      it 'raises FailedError outside a git repository' do
        execution_context # ensure repo is initialized before removing .git
        FileUtils.rm_rf(File.join(repo_dir, '.git'))
        expect { command.call }.to raise_error(Git::FailedError, /not a git repository/i)
      end
    end
  end
end
