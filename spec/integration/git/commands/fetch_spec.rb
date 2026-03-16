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

      Git.init(bare_dir, bare: true)
      repo.add_remote('origin', bare_dir)
      repo.push('origin', 'main')
    end

    context 'when the command succeeds' do
      it 'returns a CommandLineResult' do
        result = command.call('origin', merge: true)

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'when the command fails' do
      it 'raises FailedError when remote does not exist' do
        # git's error message varies by version - Rule 22 version-variance exception applies
        expect { command.call('nonexistent-remote', merge: true) }.to raise_error(Git::FailedError)
      end
    end
  end
end
