# frozen_string_literal: true

require 'spec_helper'
require 'git/repository'
require 'git/repository/logging'
require 'git/execution_context/repository'

RSpec.describe Git::Repository::Logging, :integration do
  include_context 'in an empty repository'

  let(:execution_context) { Git::ExecutionContext::Repository.from_base(repo) }
  let(:described_instance) { Git::Repository.new(execution_context: execution_context) }

  describe '#full_log_commits' do
    context 'when the repository has no commits' do
      it 'returns an empty array' do
        expect(described_instance.full_log_commits).to eq([])
      end
    end

    context 'when the repository has commits' do
      let(:first_sha) { repo.lib.rev_parse('HEAD~1').strip }

      before do
        write_file('README.md', "line one\n")
        repo.add('README.md')
        repo.commit('Initial commit')

        write_file('CHANGELOG.md', "entry\n")
        repo.add('CHANGELOG.md')
        repo.commit('Add changelog')
      end

      it 'returns parsed commit hashes with expected keys' do
        result = described_instance.full_log_commits

        expect(result).to all(include('sha', 'tree', 'author', 'committer', 'message', 'parent'))
        expect(result.first['message']).to eq("Add changelog\n")
        expect(result.first['parent']).to be_a(Array)
      end

      it 'supports the between option' do
        result = described_instance.full_log_commits(between: [first_sha, 'HEAD'])

        expect(result.length).to eq(1)
        expect(result.first['message']).to eq("Add changelog\n")
      end

      it 'supports the path_limiter option' do
        result = described_instance.full_log_commits(path_limiter: 'README.md')

        expect(result.length).to eq(1)
        expect(result.first['message']).to eq("Initial commit\n")
      end
    end
  end
end
