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
        expect(execution_context).to receive(:command)
          .with('clone', '--', repository_url, directory, timeout: nil)

        command.call(repository_url, directory)
      end

      it 'returns working_directory in result' do
        allow(execution_context).to receive(:command)

        result = command.call(repository_url, directory)

        expect(result).to eq({ working_directory: directory })
      end
    end

    context 'with :path option' do
      it 'uses path as the directory' do
        expect(execution_context).to receive(:command)
          .with('clone', '--', repository_url, 'custom/path', timeout: nil)

        command.call(repository_url, directory, path: 'custom/path')
      end

      it 'returns the path in result' do
        allow(execution_context).to receive(:command)

        result = command.call(repository_url, directory, path: 'custom/path')

        expect(result).to eq({ working_directory: 'custom/path' })
      end
    end

    context 'with nil directory' do
      it 'determines default directory from URL' do
        expect(execution_context).to receive(:command)
          .with('clone', '--', repository_url, 'ruby-git', timeout: nil)

        command.call(repository_url, nil)
      end

      it 'strips .git extension from URL' do
        url = 'https://github.com/ruby-git/ruby-git.git'
        expect(execution_context).to receive(:command)
          .with('clone', '--', url, 'ruby-git', timeout: nil)

        command.call(url, nil)
      end

      it 'adds .git extension for bare clones' do
        expect(execution_context).to receive(:command)
          .with('clone', '--bare', '--', repository_url, 'ruby-git.git', timeout: nil)

        command.call(repository_url, nil, bare: true)
      end

      it 'adds .git extension for mirror clones' do
        expect(execution_context).to receive(:command)
          .with('clone', '--mirror', '--', repository_url, 'ruby-git.git', timeout: nil)

        command.call(repository_url, nil, mirror: true)
      end
    end

    context 'with :bare option' do
      it 'includes the --bare flag' do
        expect(execution_context).to receive(:command)
          .with('clone', '--bare', '--', repository_url, directory, timeout: nil)

        command.call(repository_url, directory, bare: true)
      end

      it 'returns repository instead of working_directory' do
        allow(execution_context).to receive(:command)

        result = command.call(repository_url, directory, bare: true)

        expect(result).to eq({ repository: directory })
      end

      it 'does not include the flag when false' do
        expect(execution_context).to receive(:command)
          .with('clone', '--', repository_url, directory, timeout: nil)

        command.call(repository_url, directory, bare: false)
      end
    end

    context 'with :mirror option' do
      it 'includes the --mirror flag' do
        expect(execution_context).to receive(:command)
          .with('clone', '--mirror', '--', repository_url, directory, timeout: nil)

        command.call(repository_url, directory, mirror: true)
      end

      it 'returns repository instead of working_directory' do
        allow(execution_context).to receive(:command)

        result = command.call(repository_url, directory, mirror: true)

        expect(result).to eq({ repository: directory })
      end
    end

    context 'with :recursive option' do
      it 'includes the --recursive flag' do
        expect(execution_context).to receive(:command)
          .with('clone', '--recursive', '--', repository_url, directory, timeout: nil)

        command.call(repository_url, directory, recursive: true)
      end
    end

    context 'with :branch option' do
      it 'includes the --branch flag with value' do
        expect(execution_context).to receive(:command)
          .with('clone', '--branch', 'development', '--', repository_url, directory, timeout: nil)

        command.call(repository_url, directory, branch: 'development')
      end
    end

    context 'with :filter option' do
      it 'includes the --filter flag with value' do
        expect(execution_context).to receive(:command)
          .with('clone', '--filter', 'tree:0', '--', repository_url, directory, timeout: nil)

        command.call(repository_url, directory, filter: 'tree:0')
      end

      it 'handles blob:none filter' do
        expect(execution_context).to receive(:command)
          .with('clone', '--filter', 'blob:none', '--', repository_url, directory, timeout: nil)

        command.call(repository_url, directory, filter: 'blob:none')
      end
    end

    context 'with :origin option' do
      it 'includes the --origin flag with value' do
        expect(execution_context).to receive(:command)
          .with('clone', '--origin', 'upstream', '--', repository_url, directory, timeout: nil)

        command.call(repository_url, directory, origin: 'upstream')
      end
    end

    context 'with :remote option (alias for origin)' do
      it 'includes the --origin flag with value' do
        expect(execution_context).to receive(:command)
          .with('clone', '--origin', 'upstream', '--', repository_url, directory, timeout: nil)

        command.call(repository_url, directory, remote: 'upstream')
      end
    end

    context 'with :config option' do
      it 'includes a single config option' do
        expect(execution_context).to receive(:command)
          .with('clone', '--config', 'user.name=John Doe', '--', repository_url, directory, timeout: nil)

        command.call(repository_url, directory, config: 'user.name=John Doe')
      end

      it 'includes multiple config options' do
        expect(execution_context).to receive(:command)
          .with('clone', '--config', 'user.name=John Doe', '--config', 'user.email=john@doe.com',
                '--', repository_url, directory, timeout: nil)

        command.call(repository_url, directory, config: ['user.name=John Doe', 'user.email=john@doe.com'])
      end
    end

    context 'with :single_branch option' do
      it 'includes --single-branch when true' do
        expect(execution_context).to receive(:command)
          .with('clone', '--single-branch', '--', repository_url, directory, timeout: nil)

        command.call(repository_url, directory, single_branch: true)
      end

      it 'includes --no-single-branch when false' do
        expect(execution_context).to receive(:command)
          .with('clone', '--no-single-branch', '--', repository_url, directory, timeout: nil)

        command.call(repository_url, directory, single_branch: false)
      end

      it 'includes no flag when nil' do
        expect(execution_context).to receive(:command)
          .with('clone', '--', repository_url, directory, timeout: nil)

        command.call(repository_url, directory, single_branch: nil)
      end

      it 'raises ArgumentError for invalid values' do
        expect { command.call(repository_url, directory, single_branch: 'yes') }
          .to raise_error(ArgumentError, /Invalid value for option/)
      end
    end

    context 'with :depth option' do
      it 'includes --depth with integer value' do
        expect(execution_context).to receive(:command)
          .with('clone', '--depth', 1, '--', repository_url, directory, timeout: nil)

        command.call(repository_url, directory, depth: 1)
      end

      it 'converts string depth to integer' do
        expect(execution_context).to receive(:command)
          .with('clone', '--depth', 5, '--', repository_url, directory, timeout: nil)

        command.call(repository_url, directory, depth: '5')
      end
    end

    context 'with :timeout option' do
      it 'passes timeout to the command' do
        expect(execution_context).to receive(:command)
          .with('clone', '--', repository_url, directory, timeout: 30)

        command.call(repository_url, directory, timeout: 30)
      end
    end

    context 'with :log option' do
      it 'includes log in the result' do
        logger = double('Logger')
        allow(execution_context).to receive(:command)

        result = command.call(repository_url, directory, log: logger)

        expect(result[:log]).to eq(logger)
      end
    end

    context 'with :git_ssh option' do
      it 'includes git_ssh in the result' do
        allow(execution_context).to receive(:command)

        result = command.call(repository_url, directory, git_ssh: 'ssh -i /path/to/key')

        expect(result[:git_ssh]).to eq('ssh -i /path/to/key')
      end

      it 'includes git_ssh even when nil' do
        allow(execution_context).to receive(:command)

        result = command.call(repository_url, directory, git_ssh: nil)

        expect(result).to have_key(:git_ssh)
        expect(result[:git_ssh]).to be_nil
      end
    end

    context 'with multiple options combined' do
      it 'includes all specified flags' do
        expect(execution_context).to receive(:command)
          .with('clone', '--recursive', '--branch', 'main', '--single-branch', '--depth', 1,
                '--', repository_url, directory, timeout: 60)

        command.call(repository_url, directory,
                     recursive: true,
                     branch: 'main',
                     depth: 1,
                     single_branch: true,
                     timeout: 60)
      end
    end

    context 'with URLs containing special characters' do
      it 'handles URLs with authentication' do
        url = 'https://user:pass@github.com/ruby-git/ruby-git.git'
        expect(execution_context).to receive(:command)
          .with('clone', '--', url, directory, timeout: nil)

        command.call(url, directory)
      end

      it 'handles SSH URLs' do
        url = 'git@github.com:ruby-git/ruby-git.git'
        expect(execution_context).to receive(:command)
          .with('clone', '--', url, directory, timeout: nil)

        command.call(url, directory)
      end

      it 'handles local paths' do
        url = '/path/to/local/repo'
        expect(execution_context).to receive(:command)
          .with('clone', '--', url, directory, timeout: nil)

        command.call(url, directory)
      end
    end

    context 'with directory names containing special characters' do
      it 'handles directories with spaces' do
        dir = 'my repo'
        expect(execution_context).to receive(:command)
          .with('clone', '--', repository_url, dir, timeout: nil)

        command.call(repository_url, dir)
      end

      it 'handles directories with unicode characters' do
        dir = 'репозиторий'
        expect(execution_context).to receive(:command)
          .with('clone', '--', repository_url, dir, timeout: nil)

        command.call(repository_url, dir)
      end
    end
  end
end
