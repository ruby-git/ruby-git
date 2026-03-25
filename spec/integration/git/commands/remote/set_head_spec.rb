# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/remote/set_head'

RSpec.describe Git::Commands::Remote::SetHead, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  let(:remote_dir) { Dir.mktmpdir }
  let(:remote_repo) do
    test_repo = Git.init(remote_dir, initial_branch:)
    test_repo.config('user.email', 'test@example.com')
    test_repo.config('user.name', 'Test User')
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
      it 'sets the remote HEAD to an explicit branch' do
        repo.add_remote('origin', remote_repo.dir.to_s)
        repo.fetch('origin')

        result = command.call('origin', initial_branch)

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'deletes the remote HEAD when :delete is given' do
        repo.add_remote('origin', remote_repo.dir.to_s)
        repo.fetch('origin')
        command.call('origin', initial_branch)

        result = command.call('origin', delete: true)

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'when the command fails' do
      it 'raises FailedError for a missing remote' do
        expect do
          command.call('origin', initial_branch)
        end.to raise_error(Git::FailedError, /No such remote|Not a valid ref/i)
      end
    end
  end
end
