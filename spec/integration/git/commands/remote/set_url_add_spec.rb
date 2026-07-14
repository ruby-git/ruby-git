# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/remote/set_url_add'

RSpec.describe Git::Commands::Remote::SetUrlAdd, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  let(:remote_dir) { Dir.mktmpdir }
  let(:extra_dir) { Dir.mktmpdir }
  let(:remote_repo) do
    init_test_repo(remote_dir, initial_branch:)
  end
  let(:extra_repo) do
    init_test_repo(extra_dir, initial_branch:)
  end

  after do
    FileUtils.rm_rf(remote_dir)
    FileUtils.rm_rf(extra_dir)
  end

  describe '#call' do
    context 'when the command succeeds' do
      it 'adds an additional fetch url' do
        repo.remote_add('origin', remote_repo.dir.to_s)

        result = command.call('origin', extra_repo.dir.to_s)

        expect(result).to be_a(Git::CommandLine::Result)
      end
    end

    context 'when the command fails' do
      it 'raises FailedError for a missing remote' do
        expect { command.call('origin', extra_repo.dir.to_s) }.to raise_error(Git::FailedError, /No such remote/i)
      end
    end
  end
end
