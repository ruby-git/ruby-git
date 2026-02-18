# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/clone'

RSpec.describe Git::Commands::Clone, :integration do
  # Clone creates new repositories, so it uses an unbound execution context
  # (no pre-existing repo), matching how Git.clone calls it in production.
  subject(:command) { described_class.new(execution_context) }

  let(:execution_context) { Git::Lib.new(nil) }
  let(:source_dir) { Dir.mktmpdir }
  let(:clone_dir) { Dir.mktmpdir }

  before do
    source_repo = Git.init(source_dir, initial_branch: 'main')
    source_repo.config('user.email', 'test@example.com')
    source_repo.config('user.name', 'Test User')
    File.write(File.join(source_dir, 'file.txt'), "content\n")
    source_repo.add('file.txt')
    source_repo.commit('Initial commit')
  end

  after do
    FileUtils.rm_rf(source_dir)
    FileUtils.rm_rf(clone_dir)
  end

  describe '#call' do
    describe 'when the command succeeds' do
      it 'returns a CommandLineResult' do
        result = command.call(source_dir, File.join(clone_dir, 'cloned'))

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'returns a CommandLineResult when cloning with chdir' do
        result = command.call(source_dir, 'chdir-cloned', chdir: clone_dir)

        expect(result).to be_a(Git::CommandLineResult)
        expect(File.directory?(File.join(clone_dir, 'chdir-cloned'))).to be true
      end

      it 'returns a CommandLineResult for a bare clone' do
        result = command.call(source_dir, File.join(clone_dir, 'bare.git'), bare: true)

        expect(result).to be_a(Git::CommandLineResult)
        expect(File.directory?(File.join(clone_dir, 'bare.git'))).to be true
      end
    end

    describe 'when the command fails' do
      it 'raises FailedError with a nonexistent source' do
        expect { command.call('/nonexistent/repo', File.join(clone_dir, 'cloned')) }.to raise_error(Git::FailedError)
      end
    end
  end
end
