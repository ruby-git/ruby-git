# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/remote/update'

RSpec.describe Git::Commands::Remote::Update, :integration do
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
      it 'fetches updates for the named remote' do
        repo.add_remote('origin', remote_repo.dir.to_s)

        result = command.call('origin')

        expect(result).to be_a(Git::CommandLineResult)
        expect(repo.branches.remote.map(&:full)).to include("remotes/origin/#{initial_branch}")
      end
    end

    context 'when the command fails' do
      it 'raises FailedError for an unknown remote' do
        expect { command.call('nonexistent') }.to raise_error(Git::FailedError, /No such remote/i)
      end
    end
  end
end
