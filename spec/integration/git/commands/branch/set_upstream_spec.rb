# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/branch/set_upstream'

RSpec.describe Git::Commands::Branch::SetUpstream, :integration do
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

    describe 'when the command succeeds' do
      it 'returns a CommandLineResult with output' do
        result = command.call(set_upstream_to: 'origin/main')

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.stdout).not_to be_empty
      end
    end

    describe 'when the command fails' do
      it 'raises FailedError when upstream does not exist' do
        expect { command.call(set_upstream_to: 'origin/nonexistent') }.to raise_error(Git::FailedError)
      end

      it 'raises FailedError when branch does not exist' do
        expect { command.call('nonexistent', set_upstream_to: 'origin/main') }.to raise_error(Git::FailedError)
      end
    end
  end
end
