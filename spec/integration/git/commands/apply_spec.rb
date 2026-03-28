# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/apply'

RSpec.describe Git::Commands::Apply, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  before do
    write_file('file.txt', "line1\n")
    repo.add('file.txt')
    repo.commit('Initial commit')
  end

  describe '#call' do
    context 'when the command succeeds' do
      let(:patch_file) { File.join(repo_dir, 'add_line2.patch') }

      before do
        write_file('file.txt', "line1\nline2\n")
        repo.add('file.txt')
        repo.commit('Add line2')

        patch_content = execution_context.diff_full('HEAD~1', 'HEAD')
        File.write(patch_file, "#{patch_content}\n")

        repo.reset('HEAD~1', hard: true)
      end

      it 'returns a CommandLineResult' do
        result = command.call(patch_file, chdir: repo_dir)

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'applies the patch to the working tree' do
        command.call(patch_file, chdir: repo_dir)

        expect(File.read(File.join(repo_dir, 'file.txt'))).to eq("line1\nline2\n")
      end

      it 'checks the patch cleanly without applying it when :check is passed' do
        result = command.call(patch_file, check: true, chdir: repo_dir)

        expect(result).to be_a(Git::CommandLineResult)
        expect(File.read(File.join(repo_dir, 'file.txt'))).to eq("line1\n")
      end
    end

    context 'when the command fails' do
      it 'raises FailedError for an invalid patch' do
        bad_patch = File.join(repo_dir, 'bad.patch')
        File.write(bad_patch, "This is not a valid patch\n")

        expect { command.call(bad_patch, chdir: repo_dir) }
          .to raise_error(Git::FailedError, /bad\.patch/)
      end
    end
  end
end
