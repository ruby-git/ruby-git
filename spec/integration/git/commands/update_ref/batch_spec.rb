# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/update_ref/batch'

RSpec.describe Git::Commands::UpdateRef::Batch, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    before do
      write_file('file.txt', "content\n")
      repo.add('file.txt')
      repo.commit('Initial commit')
    end

    context 'when the command succeeds' do
      it 'atomically creates and updates refs via stdin' do
        head_sha = repo.rev_parse('HEAD')

        result = command.call(
          "create refs/heads/batch-a #{head_sha}",
          "create refs/heads/batch-b #{head_sha}"
        )

        expect(result).to be_a(Git::CommandLineResult)
        expect(repo.rev_parse('refs/heads/batch-a')).to eq(head_sha)
        expect(repo.rev_parse('refs/heads/batch-b')).to eq(head_sha)
      end

      it 'atomically deletes refs via stdin' do
        head_sha = repo.rev_parse('HEAD')
        repo.branch('to-delete').create

        result = command.call("delete refs/heads/to-delete #{head_sha}")

        expect(result).to be_a(Git::CommandLineResult)
        expect { repo.rev_parse('refs/heads/to-delete') }.to raise_error(Git::FailedError)
      end

      it 'atomically updates and deletes refs in one call' do
        head_sha = repo.rev_parse('HEAD')
        repo.branch('to-update').create
        repo.branch('to-delete').create

        # Create a new commit to update to
        write_file('file.txt', "updated\n")
        repo.add('file.txt')
        repo.commit('Second commit')
        new_sha = repo.rev_parse('HEAD')

        result = command.call(
          "update refs/heads/to-update #{new_sha} #{head_sha}",
          "delete refs/heads/to-delete #{head_sha}"
        )

        expect(result).to be_a(Git::CommandLineResult)
        expect(repo.rev_parse('refs/heads/to-update')).to eq(new_sha)
        expect { repo.rev_parse('refs/heads/to-delete') }.to raise_error(Git::FailedError)
      end
    end

    context 'when the command fails' do
      it 'raises FailedError when any instruction is invalid' do
        head_sha = repo.rev_parse('HEAD')
        repo.branch('survive').create

        expect do
          command.call(
            "update refs/heads/survive #{'0' * 40} #{head_sha}",
            "delete refs/heads/nonexistent #{head_sha}"
          )
        end.to raise_error(Git::FailedError, /update-ref/)

        # survive branch should be untouched because the transaction failed atomically
        expect(repo.rev_parse('refs/heads/survive')).to eq(head_sha)
      end
    end
  end
end
