# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/stash/list'

RSpec.describe Git::Commands::Stash::List do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  # Default stash line attributes for building test data
  let(:default_stash_attrs) do
    {
      oid: 'abc1234567890abcdef1234567890abcdef123456',
      short_oid: 'abc1234',
      reflog: 'stash@{0}',
      message: 'WIP on main: abc1234 Initial commit',
      author_name: 'Test Author',
      author_email: 'author@test.com',
      author_date: '2026-01-24T10:00:00-08:00',
      committer_name: 'Test Committer',
      committer_email: 'committer@test.com',
      committer_date: '2026-01-24T10:00:00-08:00'
    }
  end

  # Helper to build stash format line with unit separator (0x1F)
  def stash_line(attrs)
    [
      attrs[:oid], attrs[:short_oid], attrs[:reflog], attrs[:message],
      attrs[:author_name], attrs[:author_email], attrs[:author_date],
      attrs[:committer_name], attrs[:committer_email], attrs[:committer_date]
    ].join("\x1f")
  end

  # Helper to expect command call - verifies the command is called with specific arguments
  def expect_command(*args, stdout: '')
    expect(execution_context).to receive(:command).with(*args, any_args).and_return(command_result(stdout))
  end

  # Helper to stub command call for parsing tests where other expectations do the verification
  def allow_command(*args, stdout: '')
    allow(execution_context).to receive(:command).with(*args, any_args).and_return(command_result(stdout))
  end

  describe '#call' do
    let(:format_arg) { "--format=#{described_class::STASH_FORMAT}" }

    context 'with no stashes' do
      it 'returns an empty array' do
        expect_command('stash', 'list', format_arg)
        result = command.call
        expect(result).to eq([])
      end
    end

    context 'with stashes' do
      let(:stash_output) do
        [
          stash_line(default_stash_attrs.merge(
                       oid: 'abc1234567890abcdef1234567890abcdef123456',
                       short_oid: 'abc1234',
                       reflog: 'stash@{0}',
                       message: 'WIP on main: abc1234 Initial commit'
                     )),
          stash_line(default_stash_attrs.merge(
                       oid: 'def5678901234567890abcdef1234567890abcdef',
                       short_oid: 'def5678',
                       reflog: 'stash@{1}',
                       message: 'On feature: def5678 Add feature'
                     )),
          stash_line(default_stash_attrs.merge(
                       oid: '9876543210abcdef1234567890abcdef12345678',
                       short_oid: '9876543',
                       reflog: 'stash@{2}',
                       message: 'WIP on bugfix: 9876543 Fix bug'
                     ))
        ].join("\n")
      end

      it 'returns an array of StashInfo objects' do
        allow_command('stash', 'list', format_arg, stdout: stash_output)
        result = command.call

        expect(result).to be_an(Array)
        expect(result.size).to eq(3)
        expect(result).to all(be_a(Git::StashInfo))
      end

      it 'parses stash index correctly' do
        allow_command('stash', 'list', format_arg, stdout: stash_output)
        result = command.call

        expect(result[0].index).to eq(0)
        expect(result[1].index).to eq(1)
        expect(result[2].index).to eq(2)
      end

      it 'parses stash name correctly' do
        allow_command('stash', 'list', format_arg, stdout: stash_output)
        result = command.call

        expect(result[0].name).to eq('stash@{0}')
        expect(result[1].name).to eq('stash@{1}')
        expect(result[2].name).to eq('stash@{2}')
      end

      it 'parses SHA correctly' do
        allow_command('stash', 'list', format_arg, stdout: stash_output)
        result = command.call

        expect(result[0].oid).to eq('abc1234567890abcdef1234567890abcdef123456')
        expect(result[0].short_oid).to eq('abc1234')
        expect(result[1].oid).to eq('def5678901234567890abcdef1234567890abcdef')
        expect(result[1].short_oid).to eq('def5678')
      end

      it 'parses branch name correctly' do
        allow_command('stash', 'list', format_arg, stdout: stash_output)
        result = command.call

        expect(result[0].branch).to eq('main')
        expect(result[1].branch).to eq('feature')
        expect(result[2].branch).to eq('bugfix')
      end

      it 'parses message correctly' do
        allow_command('stash', 'list', format_arg, stdout: stash_output)
        result = command.call

        expect(result[0].message).to eq('WIP on main: abc1234 Initial commit')
        expect(result[1].message).to eq('On feature: def5678 Add feature')
        expect(result[2].message).to eq('WIP on bugfix: 9876543 Fix bug')
      end

      it 'parses author information correctly' do
        allow_command('stash', 'list', format_arg, stdout: stash_output)
        result = command.call

        expect(result[0].author_name).to eq('Test Author')
        expect(result[0].author_email).to eq('author@test.com')
        expect(result[0].author_date).to eq('2026-01-24T10:00:00-08:00')
      end

      it 'parses committer information correctly' do
        allow_command('stash', 'list', format_arg, stdout: stash_output)
        result = command.call

        expect(result[0].committer_name).to eq('Test Committer')
        expect(result[0].committer_email).to eq('committer@test.com')
        expect(result[0].committer_date).to eq('2026-01-24T10:00:00-08:00')
      end
    end

    context 'with custom stash message' do
      let(:stash_output) do
        stash_line(default_stash_attrs.merge(
                     reflog: 'stash@{0}',
                     message: 'On main: My custom message'
                   ))
      end

      it 'parses custom messages correctly' do
        allow_command('stash', 'list', format_arg, stdout: stash_output)
        result = command.call

        expect(result[0].branch).to eq('main')
        expect(result[0].message).to eq('On main: My custom message')
      end
    end

    context 'with message containing colons' do
      let(:stash_output) do
        stash_line(default_stash_attrs.merge(
                     reflog: 'stash@{0}',
                     message: 'WIP on main: abc123 Fix: something: important'
                   ))
      end

      it 'preserves colons in the message' do
        allow_command('stash', 'list', format_arg, stdout: stash_output)
        result = command.call

        expect(result[0].message).to eq('WIP on main: abc123 Fix: something: important')
      end
    end

    context 'with custom stash message (via git stash store)' do
      let(:stash_output) do
        stash_line(default_stash_attrs.merge(
                     reflog: 'stash@{0}',
                     message: 'custom message'
                   ))
      end

      it 'parses custom messages without branch info' do
        allow_command('stash', 'list', format_arg, stdout: stash_output)
        result = command.call

        expect(result.size).to eq(1)
        expect(result[0].index).to eq(0)
        expect(result[0].name).to eq('stash@{0}')
        expect(result[0].branch).to be_nil
        expect(result[0].message).to eq('custom message')
      end
    end

    context 'with custom stash message containing colon' do
      let(:stash_output) do
        stash_line(default_stash_attrs.merge(
                     reflog: 'stash@{0}',
                     message: 'testing: custom message'
                   ))
      end

      it 'parses full custom message with colons' do
        allow_command('stash', 'list', format_arg, stdout: stash_output)
        result = command.call

        expect(result[0].branch).to be_nil
        expect(result[0].message).to eq('testing: custom message')
      end
    end

    context 'with different author and committer' do
      let(:stash_output) do
        stash_line(default_stash_attrs.merge(
                     reflog: 'stash@{0}',
                     message: 'WIP on main: abc1234 Test commit',
                     author_name: 'Alice Author',
                     author_email: 'alice@example.com',
                     author_date: '2026-01-20T09:00:00-08:00',
                     committer_name: 'Bob Committer',
                     committer_email: 'bob@example.com',
                     committer_date: '2026-01-24T15:30:00-08:00'
                   ))
      end

      it 'correctly distinguishes author and committer' do
        allow_command('stash', 'list', format_arg, stdout: stash_output)
        result = command.call

        expect(result[0].author_name).to eq('Alice Author')
        expect(result[0].author_email).to eq('alice@example.com')
        expect(result[0].author_date).to eq('2026-01-20T09:00:00-08:00')
        expect(result[0].committer_name).to eq('Bob Committer')
        expect(result[0].committer_email).to eq('bob@example.com')
        expect(result[0].committer_date).to eq('2026-01-24T15:30:00-08:00')
      end
    end

    context 'with unexpected output format' do
      it 'raises UnexpectedResultError when field count is wrong' do
        # Malformed line with only 5 fields instead of 10
        malformed_line = %w[oid short_oid reflog message author_name].join("\x1f")
        allow_command('stash', 'list', format_arg, stdout: malformed_line)

        expect { command.call }.to raise_error(
          Git::UnexpectedResultError,
          /Unexpected line in output.*at index 0.*Expected 10 fields.*got 5/m
        )
      end

      it 'raises UnexpectedResultError with correct index for later entries' do
        valid_line = stash_line(default_stash_attrs.merge(reflog: 'stash@{0}'))
        # Second line is malformed
        malformed_line = 'incomplete data'
        allow_command('stash', 'list', format_arg, stdout: "#{valid_line}\n#{malformed_line}")

        expect { command.call }.to raise_error(
          Git::UnexpectedResultError,
          /Unexpected line in output.*at index 1/m
        )
      end

      it 'includes the full output and problematic line in error message' do
        malformed_line = 'not-enough-fields'
        allow_command('stash', 'list', format_arg, stdout: malformed_line)

        expect { command.call }.to raise_error(Git::UnexpectedResultError) do |error|
          expect(error.message).to include('Full output:')
          expect(error.message).to include('not-enough-fields')
          expect(error.message).to include('Line at index 0:')
        end
      end
    end
  end
end
