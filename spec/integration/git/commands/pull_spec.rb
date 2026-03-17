# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/pull'

RSpec.describe Git::Commands::Pull, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  let(:bare_dir) { Dir.mktmpdir('bare_repo') }
  let(:second_clone_dir) { Dir.mktmpdir('second_clone') }

  after do
    FileUtils.rm_rf(bare_dir)
    FileUtils.rm_rf(second_clone_dir)
  end

  describe '#call' do
    before do
      # Set up repo with initial commit and push to bare remote
      write_file('file.txt', 'content')
      repo.add('file.txt')
      repo.commit('Initial commit')

      Git.init(bare_dir, bare: true, initial_branch: 'main')
      repo.add_remote('origin', bare_dir)
      repo.push('origin', 'main')

      # Create a second clone, add a commit, and push to the bare remote
      # so the original repo can pull it
      Git.clone(bare_dir, second_clone_dir)
      second_clone = Git.open(second_clone_dir)
      second_clone.config('user.email', 'test@example.com')
      second_clone.config('user.name', 'Test User')
      second_clone.config('commit.gpgsign', 'false')
      File.write(File.join(second_clone_dir, 'new_file.txt'), 'New content')
      second_clone.add('new_file.txt')
      second_clone.commit('Second commit')
      second_clone.push('origin', 'main')
    end

    context 'when the command succeeds' do
      it 'returns a CommandLineResult' do
        result = command.call('origin', 'main')

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'when the command fails' do
      it 'raises FailedError when remote does not exist' do
        expect do
          command.call('nonexistent-remote')
        end.to raise_error(Git::FailedError, /nonexistent-remote/)
      end
    end
  end
end
