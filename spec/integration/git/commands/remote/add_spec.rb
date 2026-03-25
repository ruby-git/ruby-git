# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/remote/add'

RSpec.describe Git::Commands::Remote::Add, :integration do
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
      it 'adds a new remote' do
        result = command.call('origin', remote_repo.dir.to_s)

        expect(result).to be_a(Git::CommandLineResult)
        expect(repo.remotes.map(&:name)).to include('origin')
      end
    end

    context 'when the command fails' do
      it 'raises FailedError when the remote already exists' do
        command.call('origin', remote_repo.dir.to_s)

        expect { command.call('origin', remote_repo.dir.to_s) }.to raise_error(Git::FailedError, /already exists/)
      end
    end
  end
end
