# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/am/apply'

RSpec.describe Git::Commands::Am::Apply, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'when the command succeeds' do
      let(:mbox_file) { File.join(repo_dir, 'patches.mbox') }

      before do
        write_file('file.txt', "line1\n")
        repo.add('file.txt')
        repo.commit('Initial commit')

        write_file('file.txt', "line1\nline2\n")
        repo.add('file.txt')
        repo.commit('Add line2')

        # Generate mbox-format patch from last commit using the real execution context
        result = execution_context.command_capturing(
          'format-patch', '--stdout', 'HEAD~1', chdir: repo_dir, raise_on_failure: false
        )
        File.write(mbox_file, result.stdout)

        repo.reset('HEAD~1', hard: true)
      end

      it 'returns a CommandLineResult' do
        result = command.call(mbox_file, chdir: repo_dir)

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'applies the patch as a new commit' do
        command.call(mbox_file, chdir: repo_dir)

        expect(File.read(File.join(repo_dir, 'file.txt'))).to eq("line1\nline2\n")
      end
    end

    context 'when the command fails' do
      before do
        write_file('file.txt', "line1\n")
        repo.add('file.txt')
        repo.commit('Initial commit')
      end

      it 'raises FailedError for an invalid mbox file' do
        bad_mbox = File.join(repo_dir, 'bad.mbox')
        File.write(bad_mbox, "This is not a valid mbox\n")

        expect { command.call(bad_mbox, chdir: repo_dir) }.to raise_error(Git::FailedError, /bad\.mbox/)
      end
    end
  end
end
