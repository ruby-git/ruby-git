# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/branch/unset_upstream'

RSpec.describe Git::Commands::Branch::UnsetUpstream, :integration do
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
      execution_context.command('branch', '--set-upstream-to=origin/main', 'main')
    end

    describe 'when the command succeeds' do
      it 'returns a CommandLineResult' do
        result = command.call

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    describe 'when the command fails' do
      it 'raises FailedError when branch has no upstream' do
        command.call # unset it first

        expect { command.call }.to raise_error(Git::FailedError)
      end

      it 'raises FailedError when branch does not exist' do
        expect { command.call('nonexistent') }.to raise_error(Git::FailedError)
      end
    end
  end
end
