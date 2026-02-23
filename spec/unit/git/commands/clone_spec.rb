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

    context 'with :recurse_submodules option' do
      it 'includes the --recurse-submodules flag' do
        expect_command('clone', '--recurse-submodules', '--', repository_url, directory).and_return(command_result)

        command.call(repository_url, directory, recurse_submodules: true)
      end

      it 'includes --recurse-submodules=<pathspec> with inline value' do
        expect_command('clone', '--recurse-submodules=lib/', '--', repository_url, directory).and_return(command_result)

        command.call(repository_url, directory, recurse_submodules: 'lib/')
      end

      it 'includes multiple --recurse-submodules=<pathspec> options' do
        expect_command('clone', '--recurse-submodules=lib/', '--recurse-submodules=ext/', '--',
                       repository_url, directory).and_return(command_result)

        command.call(repository_url, directory, recurse_submodules: %w[lib/ ext/])
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
        expect_command('clone', '--filter=tree:0', '--', repository_url, directory).and_return(command_result)

        command.call(repository_url, directory, filter: 'tree:0')
      end
    end

    context 'with :origin option' do
      it 'includes the --origin flag with value' do
        expect_command('clone', '--origin', 'upstream', '--', repository_url, directory).and_return(command_result)

        command.call(repository_url, directory, origin: 'upstream')
      end
    end

    context 'with :o option (alias for origin)' do
      it 'includes the --origin flag with value' do
        expect_command('clone', '--origin', 'upstream', '--', repository_url, directory).and_return(command_result)

        command.call(repository_url, directory, o: 'upstream')
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
    end

    context 'with :depth option' do
      it 'includes --depth with integer value' do
        expect_command('clone', '--depth', '1', '--', repository_url, directory).and_return(command_result)

        command.call(repository_url, directory, depth: 1)
      end
    end

    context 'with :timeout option' do
      it 'passes timeout to the command' do
        expect_command('clone', '--', repository_url, directory, timeout: 30).and_return(command_result)

        command.call(repository_url, directory, timeout: 30)
      end
    end

    context 'with :chdir option' do
      it 'passes chdir to the command' do
        expect_command('clone', '--', repository_url, directory, chdir: '/parent/dir').and_return(command_result)

        command.call(repository_url, directory, chdir: '/parent/dir')
      end
    end

    context 'with :template option' do
      it 'includes --template=<dir> with inline value' do
        expect_command('clone', '--template=/usr/share/git-core/templates', '--', repository_url,
                       directory).and_return(command_result)

        command.call(repository_url, directory, template: '/usr/share/git-core/templates')
      end
    end

    context 'with :local option' do
      it 'includes --local flag' do
        expect_command('clone', '--local', '--', repository_url, directory).and_return(command_result)

        command.call(repository_url, directory, local: true)
      end

      it 'includes --no-local when false' do
        expect_command('clone', '--no-local', '--', repository_url, directory).and_return(command_result)

        command.call(repository_url, directory, local: false)
      end

      it 'accepts the :l alias' do
        expect_command('clone', '--local', '--', repository_url, directory).and_return(command_result)

        command.call(repository_url, directory, l: true)
      end
    end

    context 'with :shared option' do
      it 'includes --shared flag' do
        expect_command('clone', '--shared', '--', repository_url, directory).and_return(command_result)

        command.call(repository_url, directory, shared: true)
      end

      it 'accepts the :s alias' do
        expect_command('clone', '--shared', '--', repository_url, directory).and_return(command_result)

        command.call(repository_url, directory, s: true)
      end
    end

    context 'with :no_hardlinks option' do
      it 'includes --no-hardlinks flag' do
        expect_command('clone', '--no-hardlinks', '--', repository_url, directory).and_return(command_result)

        command.call(repository_url, directory, no_hardlinks: true)
      end
    end

    context 'with :no_checkout option' do
      it 'includes --no-checkout flag' do
        expect_command('clone', '--no-checkout', '--', repository_url, directory).and_return(command_result)

        command.call(repository_url, directory, no_checkout: true)
      end

      it 'accepts the :n alias' do
        expect_command('clone', '--no-checkout', '--', repository_url, directory).and_return(command_result)

        command.call(repository_url, directory, n: true)
      end
    end

    context 'with :upload_pack option' do
      it 'includes --upload-pack <path>' do
        expect_command('clone', '--upload-pack', '/usr/bin/git-upload-pack', '--', repository_url,
                       directory).and_return(command_result)

        command.call(repository_url, directory, upload_pack: '/usr/bin/git-upload-pack')
      end

      it 'accepts the :u alias' do
        expect_command('clone', '--upload-pack', '/usr/bin/git-upload-pack', '--', repository_url,
                       directory).and_return(command_result)

        command.call(repository_url, directory, u: '/usr/bin/git-upload-pack')
      end
    end

    context 'with :reference option' do
      it 'includes --reference <repository>' do
        expect_command('clone', '--reference', '/path/to/local', '--', repository_url,
                       directory).and_return(command_result)

        command.call(repository_url, directory, reference: '/path/to/local')
      end

      it 'includes multiple --reference options' do
        expect_command('clone', '--reference', '/path/one', '--reference', '/path/two', '--',
                       repository_url, directory).and_return(command_result)

        command.call(repository_url, directory, reference: ['/path/one', '/path/two'])
      end
    end

    context 'with :reference_if_able option' do
      it 'includes --reference-if-able <repository>' do
        expect_command('clone', '--reference-if-able', '/path/to/local', '--', repository_url,
                       directory).and_return(command_result)

        command.call(repository_url, directory, reference_if_able: '/path/to/local')
      end

      it 'includes multiple --reference-if-able options' do
        expect_command('clone', '--reference-if-able', '/path/one', '--reference-if-able', '/path/two',
                       '--', repository_url, directory).and_return(command_result)

        command.call(repository_url, directory, reference_if_able: ['/path/one', '/path/two'])
      end
    end

    context 'with :dissociate option' do
      it 'includes --dissociate flag' do
        expect_command('clone', '--dissociate', '--', repository_url, directory).and_return(command_result)

        command.call(repository_url, directory, dissociate: true)
      end
    end

    context 'with :separate_git_dir option' do
      it 'includes --separate-git-dir=<dir>' do
        expect_command('clone', '--separate-git-dir=/path/to/git-dir', '--', repository_url,
                       directory).and_return(command_result)

        command.call(repository_url, directory, separate_git_dir: '/path/to/git-dir')
      end
    end

    context 'with :server_option option' do
      it 'includes a single --server-option=<opt>' do
        expect_command('clone', '--server-option=version=2', '--', repository_url,
                       directory).and_return(command_result)

        command.call(repository_url, directory, server_option: 'version=2')
      end

      it 'includes multiple --server-option flags' do
        expect_command('clone', '--server-option=version=2', '--server-option=key=val',
                       '--', repository_url, directory).and_return(command_result)

        command.call(repository_url, directory, server_option: %w[version=2 key=val])
      end
    end

    context 'with :shallow_since option' do
      it 'includes --shallow-since=<date>' do
        expect_command('clone', '--shallow-since=2020-01-01', '--', repository_url,
                       directory).and_return(command_result)

        command.call(repository_url, directory, shallow_since: '2020-01-01')
      end
    end

    context 'with :shallow_exclude option' do
      it 'includes a single --shallow-exclude=<ref>' do
        expect_command('clone', '--shallow-exclude=v1.0', '--', repository_url,
                       directory).and_return(command_result)

        command.call(repository_url, directory, shallow_exclude: 'v1.0')
      end

      it 'includes multiple --shallow-exclude flags' do
        expect_command('clone', '--shallow-exclude=v1.0', '--shallow-exclude=v2.0',
                       '--', repository_url, directory).and_return(command_result)

        command.call(repository_url, directory, shallow_exclude: %w[v1.0 v2.0])
      end
    end

    context 'with :tags option' do
      it 'includes --tags when true' do
        expect_command('clone', '--tags', '--', repository_url, directory).and_return(command_result)

        command.call(repository_url, directory, tags: true)
      end

      it 'includes --no-tags when false' do
        expect_command('clone', '--no-tags', '--', repository_url, directory).and_return(command_result)

        command.call(repository_url, directory, tags: false)
      end
    end

    context 'with :shallow_submodules option' do
      it 'includes --shallow-submodules when true' do
        expect_command('clone', '--shallow-submodules', '--', repository_url, directory).and_return(command_result)

        command.call(repository_url, directory, shallow_submodules: true)
      end

      it 'includes --no-shallow-submodules when false' do
        expect_command('clone', '--no-shallow-submodules', '--', repository_url,
                       directory).and_return(command_result)

        command.call(repository_url, directory, shallow_submodules: false)
      end
    end

    context 'with :remote_submodules option' do
      it 'includes --remote-submodules when true' do
        expect_command('clone', '--remote-submodules', '--', repository_url, directory).and_return(command_result)

        command.call(repository_url, directory, remote_submodules: true)
      end

      it 'includes --no-remote-submodules when false' do
        expect_command('clone', '--no-remote-submodules', '--', repository_url,
                       directory).and_return(command_result)

        command.call(repository_url, directory, remote_submodules: false)
      end
    end

    context 'with :jobs option' do
      it 'includes --jobs <n>' do
        expect_command('clone', '--jobs', '4', '--', repository_url, directory).and_return(command_result)

        command.call(repository_url, directory, jobs: 4)
      end

      it 'accepts the :j alias' do
        expect_command('clone', '--jobs', '4', '--', repository_url, directory).and_return(command_result)

        command.call(repository_url, directory, j: 4)
      end
    end

    context 'with :sparse option' do
      it 'includes --sparse flag' do
        expect_command('clone', '--sparse', '--', repository_url, directory).and_return(command_result)

        command.call(repository_url, directory, sparse: true)
      end
    end

    context 'with :reject_shallow option' do
      it 'includes --reject-shallow when true' do
        expect_command('clone', '--reject-shallow', '--', repository_url, directory).and_return(command_result)

        command.call(repository_url, directory, reject_shallow: true)
      end

      it 'includes --no-reject-shallow when false' do
        expect_command('clone', '--no-reject-shallow', '--', repository_url, directory).and_return(command_result)

        command.call(repository_url, directory, reject_shallow: false)
      end
    end

    context 'with :also_filter_submodules option' do
      it 'includes --also-filter-submodules alongside --filter and --recurse-submodules' do
        expect_command('clone', '--recurse-submodules', '--filter=blob:none', '--also-filter-submodules',
                       '--', repository_url, directory).and_return(command_result)

        command.call(repository_url, directory, filter: 'blob:none', recurse_submodules: true,
                                                also_filter_submodules: true)
      end
    end

    context 'with :bundle_uri option' do
      it 'includes --bundle-uri=<uri>' do
        expect_command('clone', '--bundle-uri=https://example.com/bundle', '--', repository_url,
                       directory).and_return(command_result)

        command.call(repository_url, directory, bundle_uri: 'https://example.com/bundle')
      end
    end

    context 'with :ref_format option' do
      it 'includes --ref-format=<fmt>' do
        expect_command('clone', '--ref-format=reftable', '--', repository_url, directory).and_return(command_result)

        command.call(repository_url, directory, ref_format: 'reftable')
      end

      it 'rejects invalid ref_format values' do
        expect do
          command.call(repository_url, directory, ref_format: 'invalid')
        end.to raise_error(ArgumentError, /Invalid value for :ref_format/)
      end
    end

    context 'with :revision option' do
      it 'includes --revision=<rev>' do
        expect_command('clone', '--revision=refs/heads/main', '--', repository_url,
                       directory).and_return(command_result)

        command.call(repository_url, directory, revision: 'refs/heads/main')
      end
    end

    context 'with constraint violations' do
      it 'raises ArgumentError when :also_filter_submodules is given without :filter' do
        expect { command.call(repository_url, directory, recurse_submodules: true, also_filter_submodules: true) }
          .to raise_error(ArgumentError, /:also_filter_submodules requires :filter/)
      end

      it 'raises ArgumentError when :also_filter_submodules is given without :recurse_submodules' do
        expect do
          command.call(repository_url, directory, filter: 'blob:none', also_filter_submodules: true)
        end.to raise_error(ArgumentError, /:also_filter_submodules requires :recurse_submodules/)
      end

      it 'raises ArgumentError when :revision and :branch are both given' do
        expect do
          command.call(repository_url, directory, revision: 'refs/heads/main', branch: 'main')
        end.to raise_error(ArgumentError, /:revision.*:branch|:branch.*:revision/)
      end

      it 'raises ArgumentError when :revision and :mirror are both given' do
        expect do
          command.call(repository_url, directory, revision: 'refs/heads/main', mirror: true)
        end.to raise_error(ArgumentError, /:revision.*:mirror|:mirror.*:revision/)
      end

      it 'raises ArgumentError when :bundle_uri and :depth are both given' do
        expect do
          command.call(repository_url, directory, bundle_uri: 'https://example.com/bundle', depth: 1)
        end.to raise_error(ArgumentError, /:bundle_uri.*:depth|:depth.*:bundle_uri/)
      end

      it 'raises ArgumentError when :bundle_uri and :shallow_since are both given' do
        expect do
          command.call(repository_url, directory, bundle_uri: 'https://example.com/bundle',
                                                  shallow_since: '2020-01-01')
        end.to raise_error(ArgumentError, /:bundle_uri.*:shallow_since|:shallow_since.*:bundle_uri/)
      end

      it 'raises ArgumentError when :bundle_uri and :shallow_exclude are both given' do
        expect do
          command.call(repository_url, directory, bundle_uri: 'https://example.com/bundle',
                                                  shallow_exclude: 'v1.0')
        end.to raise_error(ArgumentError, /:bundle_uri.*:shallow_exclude|:shallow_exclude.*:bundle_uri/)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError for non-boolean single_branch values' do
        expect { command.call(repository_url, directory, single_branch: 'yes') }
          .to raise_error(ArgumentError, /negatable_flag expects a boolean value/)
      end
    end
  end
end
