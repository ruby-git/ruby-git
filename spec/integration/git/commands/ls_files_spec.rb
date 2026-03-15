# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/ls_files'

RSpec.describe Git::Commands::LsFiles, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  before do
    write_file('tracked.txt', "content\n")
    repo.add('tracked.txt')
    repo.commit('Initial commit')
  end

  describe '#call' do
    context 'when the command succeeds' do
      context 'with no arguments' do
        it 'returns a CommandLineResult' do
          result = command.call

          expect(result).to be_a(Git::CommandLineResult)
        end
      end

      context 'with the :stage option and a pathspec' do
        it 'returns a CommandLineResult' do
          result = command.call('.', stage: true)

          expect(result).to be_a(Git::CommandLineResult)
        end
      end

      context 'with :others and :exclude_standard options' do
        before { write_file('untracked.txt', "new content\n") }

        it 'returns a CommandLineResult' do
          result = command.call(others: true, exclude_standard: true)

          expect(result).to be_a(Git::CommandLineResult)
        end
      end

      context 'with :others, :ignored, and :exclude_standard options' do
        before do
          write_file('ignored_file.log', "log content\n")
          write_file('.gitignore', "*.log\n")
          repo.add('.gitignore')
          repo.commit('Add gitignore')
        end

        it 'returns a CommandLineResult' do
          result = command.call(others: true, ignored: true, exclude_standard: true)

          expect(result).to be_a(Git::CommandLineResult)
        end
      end

      context 'with the :chdir execution option' do
        it 'reports paths relative to the chdir directory' do
          write_file('subdir/untracked.txt', "content\n")

          result_from_root = command.call(others: true, exclude_standard: true, chdir: repo_dir)
          result_from_subdir = command.call(others: true, exclude_standard: true,
                                            chdir: File.join(repo_dir, 'subdir'))

          expect(result_from_root.stdout.split("\n")).to include('subdir/untracked.txt')
          expect(result_from_subdir.stdout.split("\n")).to include('untracked.txt')
        end
      end
    end

    context 'when the command fails' do
      it 'raises ArgumentError for unsupported options' do
        expect { command.call(unknown_flag: true) }.to raise_error(ArgumentError, /Unsupported options/)
      end

      it 'raises FailedError when a path is not in the index' do
        expect { command.call('nonexistent.txt', error_unmatch: true) }
          .to raise_error(Git::FailedError)
      end
    end
  end
end
