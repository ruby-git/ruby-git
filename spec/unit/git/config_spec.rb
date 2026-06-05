# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::Config do
  let(:described_instance) { described_class.new }

  describe '.instance' do
    it 'returns a Git::Config instance' do
      expect(described_class.instance).to be_a(described_class)
    end

    it 'returns the same object on repeated calls (singleton)' do
      expect(described_class.instance).to be(described_class.instance)
    end
  end

  describe '#initialize' do
    subject(:instance) { described_instance }

    # Clear env vars that the readers fall through to, so defaults are deterministic
    around do |example|
      saved_path    = ENV.delete('GIT_PATH')
      saved_ssh     = ENV.delete('GIT_SSH')
      saved_timeout = ENV.delete('GIT_TIMEOUT')
      example.run
    ensure
      ENV['GIT_PATH']    = saved_path    if saved_path
      ENV['GIT_SSH']     = saved_ssh     if saved_ssh
      ENV['GIT_TIMEOUT'] = saved_timeout if saved_timeout
    end

    it 'initializes all attributes to nil, producing hardcoded reader defaults' do
      expect(instance).to have_attributes(
        binary_path: 'git',
        git_ssh: nil,
        timeout: nil
      )
    end
  end

  describe '#binary_path' do
    subject(:result) { described_instance.binary_path }

    context 'when the binary_path attribute has been set' do
      before { described_instance.binary_path = '/explicit/git' }

      it 'returns the set value' do
        expect(result).to eq('/explicit/git')
      end
    end

    context 'when the binary_path attribute is nil but GIT_PATH env is set' do
      around do |example|
        ENV['GIT_PATH'] = '/env/git/dir'
        example.run
      ensure
        ENV.delete('GIT_PATH')
      end

      it 'returns File.join(GIT_PATH, "git")' do
        expect(result).to eq(File.join('/env/git/dir', 'git'))
      end
    end

    context 'when neither the binary_path attribute nor GIT_PATH env is set' do
      around do |example|
        saved = ENV.delete('GIT_PATH')
        example.run
      ensure
        ENV['GIT_PATH'] = saved if saved
      end

      it 'returns "git"' do
        expect(result).to eq('git')
      end
    end
  end

  describe '#git_ssh' do
    subject(:result) { described_instance.git_ssh }

    context 'when the git_ssh attribute has been set' do
      before { described_instance.git_ssh = '/explicit/ssh' }

      it 'returns the set value' do
        expect(result).to eq('/explicit/ssh')
      end
    end

    context 'when the git_ssh attribute is nil but GIT_SSH env is set' do
      around do |example|
        ENV['GIT_SSH'] = '/env/ssh'
        example.run
      ensure
        ENV.delete('GIT_SSH')
      end

      it 'returns the GIT_SSH env value' do
        expect(result).to eq('/env/ssh')
      end
    end

    context 'when neither the git_ssh attribute nor GIT_SSH env is set' do
      around do |example|
        saved = ENV.delete('GIT_SSH')
        example.run
      ensure
        ENV['GIT_SSH'] = saved if saved
      end

      it 'returns nil' do
        expect(result).to be_nil
      end
    end
  end

  describe '#timeout' do
    subject(:result) { described_instance.timeout }

    context 'when the timeout attribute has been set' do
      before { described_instance.timeout = 30 }

      it 'returns the set value' do
        expect(result).to eq(30)
      end
    end

    context 'when the timeout attribute is nil but GIT_TIMEOUT env is set' do
      around do |example|
        ENV['GIT_TIMEOUT'] = '60'
        example.run
      ensure
        ENV.delete('GIT_TIMEOUT')
      end

      it 'returns the GIT_TIMEOUT env value as an integer' do
        expect(result).to eq(60)
      end
    end

    context 'when neither the timeout attribute nor GIT_TIMEOUT env is set' do
      around do |example|
        saved = ENV.delete('GIT_TIMEOUT')
        example.run
      ensure
        ENV['GIT_TIMEOUT'] = saved if saved
      end

      it 'returns nil' do
        expect(result).to be_nil
      end
    end
  end

  # End-to-end: runtime changes to Git.configure are honored by ExecutionContext subclasses
  describe 'end-to-end runtime change propagation' do
    around do |example|
      # Capture the raw instance variables (not the resolved reader values) so
      # that nil is preserved as-is. Using the reader would convert a nil ivar
      # into "git" or an ENV value, causing state to leak into later examples.
      saved_binary_path = Git::Config.instance.instance_variable_get(:@binary_path)
      saved_git_ssh     = Git::Config.instance.instance_variable_get(:@git_ssh)
      example.run
    ensure
      Git::Config.instance.binary_path = saved_binary_path
      Git::Config.instance.git_ssh     = saved_git_ssh
    end

    it 'Git::ExecutionContext::Global picks up a runtime binary_path change via Git.configure' do
      Git.configure { |c| c.binary_path = '/custom/git' }
      context = Git::ExecutionContext::Global.new
      expect(context.binary_path).to eq('/custom/git')
    end

    it 'Git::ExecutionContext::Global picks up a runtime git_ssh change via Git.configure' do
      Git.configure { |c| c.git_ssh = '/custom/ssh' }
      context = Git::ExecutionContext::Global.new
      expect(context.git_ssh).to eq('/custom/ssh')
    end

    it 'Git::ExecutionContext::Repository picks up a runtime binary_path change via Git.configure' do
      Git.configure { |c| c.binary_path = '/custom/git2' }
      context = Git::ExecutionContext::Repository.new(git_dir: '/repo/.git')
      expect(context.binary_path).to eq('/custom/git2')
    end

    it 'Git::ExecutionContext::Repository picks up a runtime git_ssh change via Git.configure' do
      Git.configure { |c| c.git_ssh = '/custom/ssh2' }
      context = Git::ExecutionContext::Repository.new(git_dir: '/repo/.git')
      expect(context.git_ssh).to eq('/custom/ssh2')
    end
  end
end
