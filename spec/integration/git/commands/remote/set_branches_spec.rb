# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/remote/set_branches'

RSpec.describe Git::Commands::Remote::SetBranches, :integration do
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
      it 'returns a CommandLineResult when setting fetch branches' do
        repo.add_remote('origin', remote_repo.dir.to_s)

        result = command.call('origin', 'feature/*')

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'returns a CommandLineResult with :add option' do
        repo.add_remote('origin', remote_repo.dir.to_s)
        command.call('origin', 'main')

        result = command.call('origin', 'release/*', add: true)

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'when the command fails' do
      it 'raises FailedError for a missing remote' do
        expect { command.call('origin', 'feature/*') }.to raise_error(Git::FailedError, /No such remote/i)
      end
    end
  end
end
