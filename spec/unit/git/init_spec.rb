# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git do
  describe '.init' do
    let(:logger) { instance_double(Logger) }
    let(:git_base) { instance_double(Git::Base) }

    before do
      # Mock Git::Commands::Init to avoid actual git execution
      command = instance_double(Git::Commands::Init)
      allow(Git::Commands::Init).to receive(:new).and_return(command)
      allow(command).to receive(:call)
    end

    context 'with bare: false (non-bare repository)' do
      it 'forwards correct options to Git.open' do
        expect(Git).to receive(:open).with(
          'my-repo',
          { log: logger, git_ssh: 'custom-ssh', index: 'my-index', repository: 'repo.git' }
        ).and_return(git_base)

        Git.init(
          'my-repo',
          bare: false,
          log: logger,
          git_ssh: 'custom-ssh',
          index: 'my-index',
          repository: 'repo.git'
        )
      end

      it 'does not forward :bare or :initial_branch to Git.open' do
        expect(Git).to receive(:open).with(
          'my-repo',
          { log: logger }
        ).and_return(git_base)

        Git.init('my-repo', bare: false, initial_branch: 'main', log: logger)
      end

      it 'consolidates :separate_git_dir to :repository' do
        expect(Git).to receive(:open).with(
          'my-repo',
          { repository: 'repo.git' }
        ).and_return(git_base)

        Git.init('my-repo', separate_git_dir: 'repo.git')
      end

      it 'prefers :repository over :separate_git_dir when both provided' do
        expect(Git).to receive(:open).with(
          'my-repo',
          { repository: 'repo.git' }
        ).and_return(git_base)

        Git.init('my-repo', repository: 'repo.git', separate_git_dir: 'other.git')
      end
    end

    context 'with bare: true (bare repository)' do
      it 'forwards correct options to Git.bare (excluding :index and :repository)' do
        expect(Git).to receive(:bare).with(
          'my-repo.git',
          { log: logger, git_ssh: 'custom-ssh' }
        ).and_return(git_base)

        Git.init(
          'my-repo.git',
          bare: true,
          log: logger,
          git_ssh: 'custom-ssh',
          index: 'my-index'
        )
      end

      it 'uses :repository path as the bare repository location' do
        expect(Git).to receive(:bare).with(
          'repo.git',
          { log: logger }
        ).and_return(git_base)

        Git.init('work', bare: true, repository: 'repo.git', log: logger)
      end

      it 'uses directory when :repository not provided' do
        expect(Git).to receive(:bare).with(
          'my-repo.git',
          {}
        ).and_return(git_base)

        Git.init('my-repo.git', bare: true)
      end

      it 'does not forward :initial_branch to Git.bare' do
        expect(Git).to receive(:bare).with(
          'my-repo.git',
          {}
        ).and_return(git_base)

        Git.init('my-repo.git', bare: true, initial_branch: 'main')
      end
    end

    context 'with minimal options' do
      it 'calls Git.open with directory and empty options when bare not specified' do
        expect(Git).to receive(:open).with('.', {}).and_return(git_base)

        Git.init
      end
    end
  end
end
