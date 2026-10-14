# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/fetch'

RSpec.describe Git::Commands::Fetch, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  let(:bare_dir) { Dir.mktmpdir('bare_repo') }

  after do
    FileUtils.rm_rf(bare_dir)
  end

  describe '#call' do
    before do
      write_file('file.txt', 'content')
      repo.add('file.txt')
      repo.commit('Initial commit')

      Git.init(bare_dir, bare: true, initial_branch: 'main')
      repo.remote_add('origin', bare_dir)
      repo.push('origin', 'main')
    end

    context 'when the command succeeds' do
      it 'returns a Git::CommandLine::Result' do
        result = command.call('origin', merge: true)

        expect(result).to be_a(Git::CommandLine::Result)
      end
    end

    context 'when the command fails' do
      it 'raises FailedError when remote does not exist' do
        # merge: true sends git's stderr to stdout, so the error text is in stdout
        expect { command.call('nonexistent-remote', merge: true) }
          .to raise_error(Git::FailedError) { |error| expect(error.result.stdout).to include('nonexistent-remote') }
      end
    end
  end
end
