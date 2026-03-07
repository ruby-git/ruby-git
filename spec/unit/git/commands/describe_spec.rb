# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/describe'

RSpec.describe Git::Commands::Describe do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with no arguments' do
      it 'runs git describe with no extra arguments and returns the result' do
        expected_result = command_result('v1.0')
        expect_command_capturing('describe').and_return(expected_result)

        result = command.call

        expect(result).to eq(expected_result)
      end
    end

    context 'with a commit-ish' do
      it 'passes a single commit-ish as a positional argument' do
        expect_command_capturing('describe', 'abc123').and_return(command_result('v1.0-3-gabc123'))

        command.call('abc123')
      end

      it 'passes multiple commit-ishes as positional arguments' do
        expect_command_capturing('describe', 'abc123', 'def456').and_return(command_result("v1.0\nv1.1"))

        command.call('abc123', 'def456')
      end

      it 'omits commit-ish when none are given' do
        expect_command_capturing('describe').and_return(command_result('v1.0'))

        command.call
      end
    end

    context 'with :all option' do
      it 'includes --all flag' do
        expect_command_capturing('describe', '--all').and_return(command_result('heads/main'))

        command.call(all: true)
      end

      it 'does not include --all when false' do
        expect_command_capturing('describe').and_return(command_result('v1.0'))

        command.call(all: false)
      end
    end

    context 'with :tags option' do
      it 'includes --tags flag' do
        expect_command_capturing('describe', '--tags').and_return(command_result('v1.0'))

        command.call(tags: true)
      end
    end

    context 'with :contains option' do
      it 'includes --contains flag' do
        expect_command_capturing('describe', '--contains').and_return(command_result('v1.0^0'))

        command.call(contains: true)
      end
    end

    context 'with :debug option' do
      it 'includes --debug flag' do
        expect_command_capturing('describe', '--debug').and_return(command_result('v1.0'))

        command.call(debug: true)
      end
    end

    context 'with :long option' do
      it 'includes --long flag' do
        expect_command_capturing('describe', '--long').and_return(command_result('v1.0-0-g1234567'))

        command.call(long: true)
      end
    end

    context 'with :always option' do
      it 'includes --always flag' do
        expect_command_capturing('describe', '--always').and_return(command_result('1234567'))

        command.call(always: true)
      end
    end

    context 'with :exact_match option' do
      it 'includes --exact-match flag' do
        expect_command_capturing('describe', '--exact-match').and_return(command_result('v1.0'))

        command.call(exact_match: true)
      end
    end

    context 'with :first_parent option' do
      it 'includes --first-parent flag' do
        expect_command_capturing('describe', '--first-parent').and_return(command_result('v1.0'))

        command.call(first_parent: true)
      end
    end

    context 'with :abbrev option' do
      it 'includes --abbrev=<n> as inline value' do
        expect_command_capturing('describe', '--abbrev=10').and_return(command_result('v1.0-3-gabcdef0123'))

        command.call(abbrev: '10')
      end

      it 'includes bare --abbrev when true' do
        expect_command_capturing('describe', '--abbrev').and_return(command_result('v1.0-3-gabcdef'))

        command.call(abbrev: true)
      end
    end

    context 'with :candidates option' do
      it 'includes --candidates=<n> as inline value' do
        expect_command_capturing('describe', '--candidates=50').and_return(command_result('v1.0'))

        command.call(candidates: '50')
      end
    end

    context 'with :match option' do
      it 'includes --match <pattern> as space-separated value' do
        expect_command_capturing('describe', '--match', 'v[0-9]*').and_return(command_result('v1.0'))

        command.call(match: 'v[0-9]*')
      end

      it 'accepts an array of patterns (repeatable)' do
        expect_command_capturing('describe', '--match', 'v[0-9]*',
                                 '--match', 'release-*').and_return(command_result('v1.0'))

        command.call(match: ['v[0-9]*', 'release-*'])
      end
    end

    context 'with :exclude option' do
      it 'includes --exclude <pattern> as space-separated value' do
        expect_command_capturing('describe', '--exclude', 'rc*').and_return(command_result('v1.0'))

        command.call(exclude: 'rc*')
      end

      it 'accepts an array of patterns (repeatable)' do
        expect_command_capturing('describe', '--exclude', 'rc*',
                                 '--exclude', 'beta-*').and_return(command_result('v1.0'))

        command.call(exclude: ['rc*', 'beta-*'])
      end
    end

    context 'with :dirty option' do
      it 'includes --dirty flag when true' do
        expect_command_capturing('describe', '--dirty').and_return(command_result('v1.0-dirty'))

        command.call(dirty: true)
      end

      it 'includes --dirty=<mark> when a string is given' do
        expect_command_capturing('describe', '--dirty=-modified').and_return(command_result('v1.0-modified'))

        command.call(dirty: '-modified')
      end

      it 'omits --dirty when false' do
        expect_command_capturing('describe').and_return(command_result('v1.0'))

        command.call(dirty: false)
      end
    end

    context 'with :broken option' do
      it 'includes --broken flag when true' do
        expect_command_capturing('describe', '--broken').and_return(command_result('v1.0-broken'))

        command.call(broken: true)
      end

      it 'includes --broken=<mark> when a string is given' do
        expect_command_capturing('describe', '--broken=-invalid').and_return(command_result('v1.0-invalid'))

        command.call(broken: '-invalid')
      end
    end

    context 'with multiple options combined' do
      it 'includes all specified flags in definition order' do
        expect_command_capturing(
          'describe',
          '--tags',
          '--long',
          '--abbrev=7',
          '--match', 'v[0-9]*',
          'HEAD'
        ).and_return(command_result('v1.0-0-g1234567'))

        command.call('HEAD', tags: true, long: true, abbrev: '7', match: 'v[0-9]*')
      end

      it 'combines dirty with options (no commit-ish) in definition order' do
        expect_command_capturing(
          'describe',
          '--tags',
          '--long',
          '--dirty',
          '--abbrev=7'
        ).and_return(command_result('v1.0-0-g1234567-dirty'))

        command.call(tags: true, long: true, abbrev: '7', dirty: true)
      end
    end

    context 'with conflicting :exact_match and :candidates' do
      it 'raises ArgumentError because --exact-match is a synonym for --candidates=0' do
        expect { command.call(exact_match: true, candidates: '5') }.to raise_error(ArgumentError)
      end
    end

    context 'with conflicting :dirty and commit_ish' do
      it 'raises ArgumentError when dirty is true and a commit-ish is given' do
        expect { command.call('abc123', dirty: true) }.to raise_error(ArgumentError)
      end

      it 'raises ArgumentError when dirty is a string and a commit-ish is given' do
        expect { command.call('abc123', dirty: '-wip') }.to raise_error(ArgumentError)
      end
    end

    context 'with conflicting :broken and commit_ish' do
      it 'raises ArgumentError when broken is true and a commit-ish is given' do
        expect { command.call('abc123', broken: true) }.to raise_error(ArgumentError)
      end

      it 'raises ArgumentError when broken is a string and a commit-ish is given' do
        expect { command.call('abc123', broken: '-invalid') }.to raise_error(ArgumentError)
      end
    end

    context 'with an unrecognised keyword argument' do
      it 'raises ArgumentError' do
        expect { command.call(foo: true) }.to raise_error(ArgumentError)
      end
    end
  end
end
