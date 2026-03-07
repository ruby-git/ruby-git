# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/grep'

RSpec.describe Git::Commands::Grep, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  before do
    write_file('file.txt', "hello\nworld\nfoo bar\n")
    write_file('other.txt', "nothing here\nfoo baz\n")
    repo.add('.')
    repo.commit('Initial commit')
  end

  describe '#call' do
    context 'when the command succeeds (matches found)' do
      it 'returns a CommandLineResult with exit status 0' do
        result = command.call('HEAD', pattern: 'foo')

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.status.exitstatus).to eq(0)
        expect(result.stdout).to include('foo')
      end

      it 'respects the :ignore_case option' do
        result_sensitive = command.call('HEAD', pattern: 'HELLO')
        result_insensitive = command.call('HEAD', pattern: 'HELLO', ignore_case: true)

        expect(result_sensitive.status.exitstatus).to eq(1)
        expect(result_insensitive.status.exitstatus).to eq(0)
        expect(result_insensitive.stdout).to include('hello')
      end

      it 'respects the :invert_match option' do
        result = command.call('HEAD', pattern: 'foo', invert_match: true)

        expect(result.status.exitstatus).to eq(0)
        expect(result.stdout).not_to include('foo')
      end

      it 'respects the :extended_regexp option' do
        result = command.call('HEAD', pattern: 'foo|hello', extended_regexp: true)

        expect(result.status.exitstatus).to eq(0)
        expect(result.stdout).to include('hello')
        expect(result.stdout).to include('foo')
      end

      it 'respects the :pathspec option' do
        result = command.call('HEAD', pattern: 'foo', pathspec: 'file.txt')

        expect(result.status.exitstatus).to eq(0)
        expect(result.stdout).to include('file.txt')
        expect(result.stdout).not_to include('other.txt')
      end
    end

    context 'when no lines are selected (no matches)' do
      it 'returns exit status 1 without raising an error' do
        result = command.call('HEAD', pattern: 'nonexistent_pattern_xyz')

        expect(result.status.exitstatus).to eq(1)
        expect(result.stdout).to be_empty
      end
    end

    context 'when the pattern is missing' do
      it 'raises ArgumentError before executing git' do
        expect { command.call('HEAD') }.to raise_error(ArgumentError, /pattern/)
      end
    end

    context 'with an Array pattern (compound boolean expression)' do
      it 'matches lines containing both patterns with --and' do
        result = command.call('HEAD', pattern: ['-e', 'foo', '--and', '-e', 'bar'])

        expect(result.status.exitstatus).to eq(0)
        expect(result.stdout).to include('foo bar')
      end

      it 'matches lines containing either pattern with --or' do
        result = command.call('HEAD', pattern: ['-e', 'hello', '--or', '-e', 'foo'])

        expect(result.status.exitstatus).to eq(0)
        expect(result.stdout).to include('hello')
        expect(result.stdout).to include('foo')
      end

      it 'negates a pattern with --not' do
        result = command.call('HEAD', pattern: ['--not', '-e', 'foo'])

        expect(result.status.exitstatus).to eq(0)
        expect(result.stdout).to include('hello')
        expect(result.stdout).not_to match(/foo/)
      end
    end
  end
end
