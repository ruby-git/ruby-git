# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/remote/set_branches'

RSpec.describe Git::Commands::Remote::SetBranches, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  let(:remote_dir) { Dir.mktmpdir }
  let(:remote_repo) do
    init_test_repo(remote_dir, initial_branch:)
  end

  after do
    FileUtils.rm_rf(remote_dir)
  end

  describe '#call' do
    context 'when the command succeeds' do
      it 'returns a CommandLineResult when setting fetch branches' do
        repo.remote_add('origin', remote_repo.dir.to_s)

        result = command.call('origin', 'feature/*')

        expect(result).to be_a(Git::CommandLine::Result)
      end
    end

    context 'when the command fails' do
      it 'raises FailedError for a missing remote' do
        expect { command.call('origin', 'feature/*') }.to raise_error(Git::FailedError, /No such remote/i)
      end
    end
  end
end
