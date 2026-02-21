# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/tag/list'
require 'git/parsers/tag'

RSpec.describe Git::Commands::Tag::List do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    let(:format_arg) { "--format=#{Git::Parsers::Tag::FORMAT_STRING}" }
    let(:sample_output) { "v1.0.0\x1fabc123\x1f111222\x1ftag\x1fJohn\x1f<j@e.com>\x1f2024-01-15\x1fRelease\n" }

    context 'with no options (basic list)' do
      it 'includes tag and --list literals with format' do
        expect_command('tag', '--list', format_arg)
          .and_return(command_result(sample_output))

        result = command.call

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.stdout).to eq(sample_output)
      end
    end

    context 'with patterns' do
      it 'adds a single pattern argument' do
        expect_command('tag', '--list', format_arg, 'v1.*').and_return(command_result)

        result = command.call('v1.*')

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'adds multiple pattern arguments' do
        expect_command('tag', '--list', format_arg, 'v1.*', 'v2.*').and_return(command_result)

        result = command.call('v1.*', 'v2.*')

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'with :sort option' do
      it 'includes --sort with single key' do
        expect_command('tag', '--list', format_arg, '--sort=refname').and_return(command_result)

        result = command.call(sort: 'refname')

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'includes multiple --sort flags for array' do
        expect_command('tag', '--list', format_arg, '--sort=refname', '--sort=-creatordate')
          .and_return(command_result)

        result = command.call(sort: ['refname', '-creatordate'])

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'supports version:refname sort key' do
        expect_command('tag', '--list', format_arg, '--sort=version:refname').and_return(command_result)

        result = command.call(sort: 'version:refname')

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'with :contains option' do
      it 'includes --contains with commit value' do
        expect_command('tag', '--list', format_arg, '--contains', 'abc123').and_return(command_result)

        result = command.call(contains: 'abc123')

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'includes --contains flag when true' do
        expect_command('tag', '--list', format_arg, '--contains').and_return(command_result)

        result = command.call(contains: true)

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'with :no_contains option' do
      it 'includes --no-contains with commit value' do
        expect_command('tag', '--list', format_arg, '--no-contains', 'abc123').and_return(command_result)

        result = command.call(no_contains: 'abc123')

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'includes --no-contains flag when true' do
        expect_command('tag', '--list', format_arg, '--no-contains').and_return(command_result)

        result = command.call(no_contains: true)

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'with :merged option' do
      it 'includes --merged with commit value' do
        expect_command('tag', '--list', format_arg, '--merged', 'main').and_return(command_result)

        result = command.call(merged: 'main')

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'includes --merged flag when true' do
        expect_command('tag', '--list', format_arg, '--merged').and_return(command_result)

        result = command.call(merged: true)

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'with :no_merged option' do
      it 'includes --no-merged with commit value' do
        expect_command('tag', '--list', format_arg, '--no-merged', 'main').and_return(command_result)

        result = command.call(no_merged: 'main')

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'includes --no-merged flag when true' do
        expect_command('tag', '--list', format_arg, '--no-merged').and_return(command_result)

        result = command.call(no_merged: true)

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'with :points_at option' do
      it 'includes --points-at with object value' do
        expect_command('tag', '--list', format_arg, '--points-at', 'HEAD').and_return(command_result)

        result = command.call(points_at: 'HEAD')

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'includes --points-at flag when true' do
        expect_command('tag', '--list', format_arg, '--points-at').and_return(command_result)

        result = command.call(points_at: true)

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'with :ignore_case option' do
      it 'includes --ignore-case flag' do
        expect_command('tag', '--list', format_arg, '--ignore-case').and_return(command_result)

        result = command.call(ignore_case: true)

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'accepts :i alias' do
        expect_command('tag', '--list', format_arg, '--ignore-case').and_return(command_result)

        result = command.call(i: true)

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'does not add flag when false' do
        expect_command('tag', '--list', format_arg).and_return(command_result)

        result = command.call(ignore_case: false)

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    context 'with multiple options combined' do
      it 'combines flags correctly' do
        expect_command('tag', '--list', format_arg, '--contains', 'abc123', '--sort=refname', 'v1.*')
          .and_return(command_result)

        result = command.call('v1.*', sort: 'refname', contains: 'abc123')

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'combines multiple patterns with options' do
        expect_command('tag', '--list', format_arg, '--merged', 'main', 'release-*', 'v*')
          .and_return(command_result)

        result = command.call('release-*', 'v*', merged: 'main')

        expect(result).to be_a(Git::CommandLineResult)
      end
    end
  end
end
