# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/name_rev'

RSpec.describe Git::Commands::NameRev, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  before do
    write_file('file.txt', "content\n")
    repo.add('file.txt')
    repo.commit('Initial commit')
  end

  describe '#call' do
    context 'when the command succeeds' do
      it 'returns a CommandLineResult with the symbolic name' do
        result = command.call('HEAD')

        expect(result).to be_a(Git::CommandLine::Result)
        expect(result.stdout).to include('main')
      end
    end

    context 'when the command fails' do
      it 'raises FailedError outside a git repository' do
        execution_context # ensure repo is initialized before removing .git
        FileUtils.rm_rf(File.join(repo_dir, '.git'))
        expect { command.call('HEAD') }.to raise_error(Git::FailedError, /not a git repository/i)
      end
    end
  end
end
