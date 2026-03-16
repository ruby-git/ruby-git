# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/ls_tree'

RSpec.describe Git::Commands::LsTree, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  before do
    write_file('README.md', "# Hello\n")
    write_file('lib/git.rb', "# git\n")
    write_file('lib/git/base.rb', "# base\n")
    repo.add('.')
    repo.commit('Initial commit')
  end

  describe '#call' do
    context 'when the command succeeds' do
      it 'returns a CommandLineResult with output' do
        result = command.call('HEAD')

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.stdout).not_to be_empty
      end

      context 'with the :r option (recursive)' do
        it 'returns a CommandLineResult' do
          result = command.call('HEAD', r: true)

          expect(result).to be_a(Git::CommandLineResult)
        end
      end

      context 'with the :name_only option' do
        it 'returns a CommandLineResult' do
          result = command.call('HEAD', r: true, name_only: true)

          expect(result).to be_a(Git::CommandLineResult)
        end
      end

      context 'with a path operand' do
        it 'returns a CommandLineResult' do
          result = command.call('HEAD', 'lib/')

          expect(result).to be_a(Git::CommandLineResult)
        end
      end
    end

    context 'when the command fails' do
      it 'raises Git::FailedError for a nonexistent tree-ish' do
        # git's error message varies by version — Rule 22 version-variance exception applies
        expect { command.call('nonexistent-sha-1234567') }.to raise_error(Git::FailedError)
      end
    end
  end
end
