# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/cat_file/filtered'

RSpec.describe Git::Commands::CatFile::Filtered, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  before do
    write_file('README.md', "# Hello\n")
    repo.add('README.md')
    repo.commit('Initial commit')
  end

  describe '#call' do
    context 'when the command succeeds' do
      context 'with --textconv mode' do
        it 'returns a CommandLineResult with the processed blob content' do
          result = command.call('HEAD:README.md', textconv: true)

          expect(result).to be_a(Git::CommandLineResult)
          expect(result.stdout).not_to be_empty
        end

        it 'accepts a blob ref with --path= to identify the filter path' do
          result = command.call('HEAD:README.md', textconv: true, path: 'README.md')

          expect(result).to be_a(Git::CommandLineResult)
          expect(result.stdout).not_to be_empty
        end
      end

      context 'with --filters mode' do
        it 'returns a CommandLineResult with the processed blob content' do
          result = command.call('HEAD:README.md', filters: true)

          expect(result).to be_a(Git::CommandLineResult)
          expect(result.stdout).not_to be_empty
        end
      end
    end

    context 'when the command fails' do
      it 'raises FailedError with a nonexistent path' do
        # git's error message varies by version — Rule 22 version-variance exception applies
        expect { command.call('HEAD:nonexistent.txt', textconv: true) }.to raise_error(Git::FailedError)
      end
    end
  end
end
