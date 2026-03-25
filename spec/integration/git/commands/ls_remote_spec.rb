# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/ls_remote'

RSpec.describe Git::Commands::LsRemote, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  let(:bare_dir) { Dir.mktmpdir('bare_repo') }

  before do
    write_file('file.txt', 'content')
    repo.add('file.txt')
    repo.commit('Initial commit')

    Git.init(bare_dir, bare: true, initial_branch: 'main')
    repo.add_remote('origin', bare_dir)
    repo.push('origin', 'main')
  end

  after do
    FileUtils.rm_rf(bare_dir)
  end

  describe '#call' do
    context 'when the command succeeds' do
      it 'returns a CommandLineResult with refs output' do
        result = command.call(bare_dir)

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.status.exitstatus).to eq(0)
        expect(result.stdout).not_to be_empty
      end

      it 'returns exit status 2 when no refs match (--exit-code)' do
        result = command.call(bare_dir, 'refs/heads/nonexistent', exit_code: true)

        expect(result.status.exitstatus).to eq(2)
      end
    end

    context 'when the command fails' do
      it 'raises FailedError for a nonexistent remote' do
        expect { command.call('/nonexistent/path') }
          .to raise_error(Git::FailedError, /nonexistent/)
      end
    end
  end
end
