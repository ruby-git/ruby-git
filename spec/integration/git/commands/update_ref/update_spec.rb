# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/update_ref/update'

RSpec.describe Git::Commands::UpdateRef::Update, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    before do
      write_file('file.txt', "content\n")
      repo.add('file.txt')
      repo.commit('Initial commit')
    end

    context 'when the command succeeds' do
      it 'updates a ref to a new commit' do
        repo.rev_parse('HEAD')
        repo.branch('test-branch').create

        write_file('file.txt', "updated\n")
        repo.add('file.txt')
        repo.commit('Second commit')
        new_sha = repo.rev_parse('HEAD')

        result = command.call('refs/heads/test-branch', new_sha)

        expect(result).to be_a(Git::CommandLineResult)
        expect(repo.rev_parse('refs/heads/test-branch')).to eq(new_sha)
      end
    end

    context 'when the command fails' do
      it 'raises FailedError when oldvalue does not match' do
        repo.branch('test-branch').create
        new_sha = repo.rev_parse('HEAD')

        expect { command.call('refs/heads/test-branch', new_sha, 'bad0' * 10) }
          .to raise_error(Git::FailedError, /bad0/)
      end
    end
  end
end
