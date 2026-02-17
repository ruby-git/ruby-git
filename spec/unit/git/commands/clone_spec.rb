# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::Commands::Clone do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    let(:repository_url) { 'https://github.com/ruby-git/ruby-git.git' }
    let(:directory) { 'ruby-git' }

    context 'with minimal arguments' do
      it 'clones into the specified directory' do
        expected_result = command_result
        expect_command('clone', '--', repository_url, directory).and_return(expected_result)

        result = command.call(repository_url, directory)

        expect(result).to eq(expected_result)
      end
    end

    context 'with nil directory' do
      it 'omits the directory operand' do
        expect_command('clone', '--', repository_url).and_return(command_result)

        command.call(repository_url, nil)
      end
    end

    context 'with :bare option' do
      it 'includes the --bare flag' do
        expect_command('clone', '--bare', '--', repository_url, directory).and_return(command_result)

        command.call(repository_url, directory, bare: true)
      end
    end

    context 'with :mirror option' do
      it 'includes the --mirror flag' do
        expect_command('clone', '--mirror', '--', repository_url, directory).and_return(command_result)

        command.call(repository_url, directory, mirror: true)
      end
    end

    context 'with :recursive option' do
      it 'includes the --recursive flag' do
        expect_command('clone', '--recursive', '--', repository_url, directory).and_return(command_result)

        command.call(repository_url, directory, recursive: true)
      end
    end

    context 'with :branch option' do
      it 'includes the --branch flag with value' do
        expect_command('clone', '--branch', 'development', '--', repository_url, directory).and_return(command_result)

        command.call(repository_url, directory, branch: 'development')
      end
    end

    context 'with :filter option' do
      it 'includes the --filter flag with value' do
        expect_command('clone', '--filter', 'tree:0', '--', repository_url, directory).and_return(command_result)

        command.call(repository_url, directory, filter: 'tree:0')
      end
    end

    context 'with :origin option' do
      it 'includes the --origin flag with value' do
        expect_command('clone', '--origin', 'upstream', '--', repository_url, directory).and_return(command_result)

        command.call(repository_url, directory, origin: 'upstream')
      end
    end

    context 'with :remote option (alias for origin)' do
      it 'includes the --origin flag with value' do
        expect_command('clone', '--origin', 'upstream', '--', repository_url, directory).and_return(command_result)

        command.call(repository_url, directory, remote: 'upstream')
      end
    end

    context 'with :config option' do
      it 'includes a single config option' do
        expect_command('clone', '--config', 'user.name=John Doe', '--', repository_url,
                       directory).and_return(command_result)

        command.call(repository_url, directory, config: 'user.name=John Doe')
      end

      it 'includes multiple config options' do
        expect_command('clone', '--config', 'user.name=John Doe', '--config', 'user.email=john@doe.com',
                       '--', repository_url, directory).and_return(command_result)

        command.call(repository_url, directory, config: ['user.name=John Doe', 'user.email=john@doe.com'])
      end
    end

    context 'with :single_branch option' do
      it 'includes --single-branch when true' do
        expect_command('clone', '--single-branch', '--', repository_url, directory).and_return(command_result)

        command.call(repository_url, directory, single_branch: true)
      end

      it 'includes --no-single-branch when false' do
        expect_command('clone', '--no-single-branch', '--', repository_url, directory).and_return(command_result)

        command.call(repository_url, directory, single_branch: false)
      end

      it 'includes no flag when nil' do
        expect_command('clone', '--', repository_url, directory).and_return(command_result)

        command.call(repository_url, directory, single_branch: nil)
      end
    end

    context 'with :depth option' do
      it 'includes --depth with integer value' do
        expect_command('clone', '--depth', 1, '--', repository_url, directory).and_return(command_result)

        command.call(repository_url, directory, depth: 1)
      end

      it 'converts string depth to integer' do
        expect_command('clone', '--depth', 5, '--', repository_url, directory).and_return(command_result)

        command.call(repository_url, directory, depth: '5')
      end
    end

    context 'with :timeout option' do
      it 'passes timeout to the command' do
        expect_command('clone', '--', repository_url, directory, timeout: 30).and_return(command_result)

        command.call(repository_url, directory, timeout: 30)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError for invalid single_branch values' do
        expect { command.call(repository_url, directory, single_branch: 'yes') }
          .to raise_error(ArgumentError, /Invalid value for option/)
      end
    end
  end
end
