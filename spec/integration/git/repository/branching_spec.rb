# frozen_string_literal: true

require 'spec_helper'
require 'git/repository'
require 'git/repository/branching'

RSpec.describe Git::Repository::Branching, :integration do
  include_context 'in an empty repository'

  let(:execution_context) { Git::ExecutionContext::Repository.from_base(repo) }
  let(:described_instance) { Git::Repository.new(execution_context: execution_context) }

  # Create an initial commit so we have a proper HEAD
  before do
    write_file('README.md', "# Hello\n")
    repo.add('README.md')
    repo.commit('Initial commit')
  end

  describe '#current_branch' do
    context 'when on the default branch' do
      it 'returns the current branch name (a non-empty string)' do
        branch_name = described_instance.current_branch
        expect(branch_name).to be_a(String)
        expect(branch_name).not_to be_empty
      end
    end

    context 'in detached HEAD state' do
      before do
        sha = repo.log(1).first.sha
        repo.lib.checkout(sha)
      end

      it "returns 'HEAD'" do
        expect(described_instance.current_branch).to eq('HEAD')
      end
    end
  end

  describe '#checkout_file' do
    before do
      write_file('README.md', "# Modified\n")
    end

    it 'restores the file to the HEAD version' do
      described_instance.checkout_file('HEAD', 'README.md')
      content = File.read(File.join(repo.dir.to_s, 'README.md'))
      expect(content).to eq("# Hello\n")
    end

    it 'returns a String' do
      result = described_instance.checkout_file('HEAD', 'README.md')
      expect(result).to be_a(String)
    end
  end

  describe '#checkout' do
    context 'checking out an existing branch' do
      before do
        repo.branch('new-branch').create
      end

      it 'switches to that branch' do
        described_instance.checkout('new-branch')
        expect(described_instance.current_branch).to eq('new-branch')
      end
    end

    context 'creating and checking out a new branch' do
      it 'creates and switches to the new branch' do
        described_instance.checkout('feature', new_branch: true, start_point: 'HEAD')
        expect(described_instance.current_branch).to eq('feature')
      end
    end
  end

  describe '#checkout_index' do
    before do
      write_file('indexed.txt', "indexed content\n")
      repo.add('indexed.txt')
    end

    context 'with all: true' do
      it 'returns a String' do
        result = described_instance.checkout_index(all: true, force: true)
        expect(result).to be_a(String)
      end
    end

    context 'with path_limiter' do
      it 'returns a String' do
        result = described_instance.checkout_index(path_limiter: 'indexed.txt', force: true)
        expect(result).to be_a(String)
      end
    end
  end
end
