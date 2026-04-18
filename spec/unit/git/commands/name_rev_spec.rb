# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/name_rev'

RSpec.describe Git::Commands::NameRev do
  # Duck-type collaborator: command specs depend on the #command_capturing
  # interface, not a single concrete ExecutionContext class.
  let(:execution_context) { execution_context_double }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with a single commit-ish' do
      it 'runs git name-rev with the commit-ish as a positional argument' do
        expected_result = command_result("abc123 tags/v1.0\n")
        expect_command_capturing('name-rev', '--', 'abc123').and_return(expected_result)

        result = command.call('abc123')

        expect(result).to eq(expected_result)
      end
    end

    context 'with multiple commit-ishes' do
      it 'passes all commit-ishes as positional arguments' do
        expect_command_capturing('name-rev', '--', 'abc123', 'def456').and_return(command_result)

        command.call('abc123', 'def456')
      end
    end

    context 'with the :tags option' do
      it 'adds --tags to the command line' do
        expect_command_capturing('name-rev', '--tags', '--', 'abc123').and_return(command_result)

        command.call('abc123', tags: true)
      end
    end

    context 'with the :refs option' do
      it 'adds --refs=<pattern> as an inline value' do
        expect_command_capturing('name-rev', '--refs=heads/main', '--', 'abc123')
          .and_return(command_result)

        command.call('abc123', refs: 'heads/main')
      end

      it 'accepts an array of patterns (repeatable)' do
        expect_command_capturing(
          'name-rev',
          '--refs=heads/*', '--refs=tags/*',
          '--', 'abc123'
        ).and_return(command_result)

        command.call('abc123', refs: ['heads/*', 'tags/*'])
      end
    end

    context 'with the :exclude option' do
      it 'adds --exclude=<pattern> as an inline value' do
        expect_command_capturing('name-rev', '--exclude=tags/test*', '--', 'abc123')
          .and_return(command_result)

        command.call('abc123', exclude: 'tags/test*')
      end

      it 'accepts an array of patterns (repeatable)' do
        expect_command_capturing(
          'name-rev',
          '--exclude=tags/test*', '--exclude=tags/rc*',
          '--', 'abc123'
        ).and_return(command_result)

        command.call('abc123', exclude: ['tags/test*', 'tags/rc*'])
      end
    end

    context 'with the :no_refs option' do
      it 'adds --no-refs to the command line' do
        expect_command_capturing('name-rev', '--no-refs', '--', 'abc123')
          .and_return(command_result)

        command.call('abc123', no_refs: true)
      end
    end

    context 'with the :no_exclude option' do
      it 'adds --no-exclude to the command line' do
        expect_command_capturing('name-rev', '--no-exclude', '--', 'abc123')
          .and_return(command_result)

        command.call('abc123', no_exclude: true)
      end
    end

    context 'with the :all option' do
      it 'adds --all to the command line' do
        expect_command_capturing('name-rev', '--all').and_return(command_result)

        command.call(all: true)
      end
    end

    context 'with the :annotate_stdin option' do
      it 'adds --annotate-stdin to the command line' do
        expect_command_capturing('name-rev', '--annotate-stdin').and_return(command_result)

        command.call(annotate_stdin: true)
      end
    end

    context 'with the :name_only option' do
      it 'adds --name-only to the command line' do
        expect_command_capturing('name-rev', '--name-only', '--', 'abc123')
          .and_return(command_result)

        command.call('abc123', name_only: true)
      end
    end

    context 'with the :no_undefined option' do
      it 'adds --no-undefined to the command line' do
        expect_command_capturing('name-rev', '--no-undefined', '--', 'abc123')
          .and_return(command_result)

        command.call('abc123', no_undefined: true)
      end
    end

    context 'with the :always option' do
      it 'adds --always to the command line' do
        expect_command_capturing('name-rev', '--always', '--', 'abc123')
          .and_return(command_result)

        command.call('abc123', always: true)
      end
    end

    context 'with multiple options combined' do
      it 'includes all specified flags in definition order' do
        expect_command_capturing(
          'name-rev',
          '--tags',
          '--refs=heads/*',
          '--name-only',
          '--always',
          '--', 'abc123'
        ).and_return(command_result)

        command.call('abc123', tags: true, refs: 'heads/*', name_only: true, always: true)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError for unsupported options' do
        expect { command.call('abc123', unknown: true) }
          .to raise_error(ArgumentError, /Unsupported options/)
      end
    end
  end
end
