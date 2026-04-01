# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/archive'

RSpec.describe Git::Commands::Archive do
  # Duck-type collaborator: command specs depend on the #command_capturing interface,
  # not a single concrete ExecutionContext class.
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with only the tree_ish operand' do
      it 'runs git archive with the tree-ish' do
        expected_result = command_result
        expect_command_capturing('archive', '--', 'HEAD', normalize: false, chomp: false)
          .and_return(expected_result)

        result = command.call('HEAD')

        expect(result).to eq(expected_result)
      end
    end

    context 'with path operands' do
      it 'includes paths after the tree-ish' do
        expect_command_capturing('archive', '--', 'HEAD', 'src/', normalize: false, chomp: false)
          .and_return(command_result)

        command.call('HEAD', 'src/')
      end

      it 'includes multiple paths' do
        expect_command_capturing('archive', '--', 'HEAD', 'src/', 'lib/', normalize: false, chomp: false)
          .and_return(command_result)

        command.call('HEAD', 'src/', 'lib/')
      end
    end

    context 'with the :format option' do
      it 'adds --format=<value> to the command line' do
        expect_command_capturing('archive', '--format=tar', '--', 'HEAD', normalize: false, chomp: false)
          .and_return(command_result)

        command.call('HEAD', format: 'tar')
      end
    end

    context 'with the :prefix option' do
      it 'adds --prefix=<value> to the command line' do
        expect_command_capturing('archive', '--prefix=myproject/', '--', 'HEAD', normalize: false, chomp: false)
          .and_return(command_result)

        command.call('HEAD', prefix: 'myproject/')
      end
    end

    context 'with the :output option' do
      it 'adds --output=<value> to the command line' do
        expect_command_capturing('archive', '--output=release.zip', '--', 'HEAD', normalize: false, chomp: false)
          .and_return(command_result)

        command.call('HEAD', output: 'release.zip')
      end

      it 'supports the :o alias' do
        expect_command_capturing('archive', '--output=release.tar', '--', 'HEAD', normalize: false, chomp: false)
          .and_return(command_result)

        command.call('HEAD', o: 'release.tar')
      end
    end

    context 'with the :worktree_attributes option' do
      it 'adds --worktree-attributes to the command line' do
        expect_command_capturing('archive', '--worktree-attributes', '--', 'HEAD', normalize: false, chomp: false)
          .and_return(command_result)

        command.call('HEAD', worktree_attributes: true)
      end
    end

    context 'with the :remote option' do
      it 'adds --remote=<value> to the command line' do
        expect_command_capturing(
          'archive', '--remote=git://example.com/repo.git', '--', 'HEAD',
          normalize: false, chomp: false
        ).and_return(command_result)

        command.call('HEAD', remote: 'git://example.com/repo.git')
      end
    end

    context 'with the :exec option' do
      it 'adds --exec=<value> to the command line' do
        expect_command_capturing(
          'archive', '--exec=/usr/bin/git-upload-archive', '--', 'HEAD',
          normalize: false, chomp: false
        ).and_return(command_result)

        command.call('HEAD', exec: '/usr/bin/git-upload-archive')
      end
    end

    context 'with the :verbose option' do
      it 'adds --verbose when true' do
        expect_command_capturing('archive', '--verbose', '--', 'HEAD', normalize: false, chomp: false)
          .and_return(command_result)

        command.call('HEAD', verbose: true)
      end

      it 'supports the :v alias' do
        expect_command_capturing('archive', '--verbose', '--', 'HEAD', normalize: false, chomp: false)
          .and_return(command_result)

        command.call('HEAD', v: true)
      end
    end

    context 'with out: execution option (streaming)' do
      it 'dispatches to command_streaming when out: is given' do
        out_io = instance_double(File)
        expect_command_streaming('archive', '--', 'HEAD', out: out_io).and_return(command_result)

        command.call('HEAD', out: out_io)
      end
    end

    context 'with multiple options combined' do
      it 'includes all specified options in definition order' do
        expect_command_capturing(
          'archive',
          '--format=tar',
          '--verbose',
          '--prefix=release-1.0/',
          '--remote=git://example.com/repo.git',
          '--', 'v1.0', 'src/',
          normalize: false, chomp: false
        ).and_return(command_result)

        command.call('v1.0', 'src/', format: 'tar', prefix: 'release-1.0/',
                                     remote: 'git://example.com/repo.git', verbose: true)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError when tree_ish is missing' do
        expect { command.call }
          .to raise_error(ArgumentError, /tree_ish is required/)
      end

      it 'raises ArgumentError for unsupported options' do
        expect { command.call('HEAD', unknown: true) }
          .to raise_error(ArgumentError, /Unsupported options/)
      end

      it 'raises ArgumentError when both output: and out: are given' do
        expect { command.call('HEAD', output: 'release.tar', out: instance_double(File)) }
          .to raise_error(ArgumentError, /cannot specify :output and :out/)
      end
    end
  end
end
