# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/push'

RSpec.describe Git::Commands::Push, :integration do
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
    end

    context 'when the command succeeds' do
      it 'returns a CommandLineResult' do
        result = command.call('origin', 'main')

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'returns result with exit status 0' do
        result = command.call('origin', 'main')

        expect(result.status.exitstatus).to eq(0)
      end
    end

    context 'when the command fails' do
      it 'raises FailedError when remote does not exist' do
        # git's error message phrasing varies by version — anchor on the stable input value
        expect { command.call('nonexistent-remote', 'main') }
          .to raise_error(Git::FailedError, /nonexistent-remote/)
      end
    end
  end
end
