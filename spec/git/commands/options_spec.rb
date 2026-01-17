# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::Commands::Options do
  describe '.define' do
    it 'returns an Options instance' do
      options = described_class.define
      expect(options).to be_a(described_class)
    end
  end

  describe '#build' do
    context 'with flag options' do
      let(:options) do
        described_class.define do
          flag :force
        end
      end

      it 'outputs --flag when value is true' do
        expect(options.build(force: true)).to eq(['--force'])
      end

      it 'outputs nothing when value is false' do
        expect(options.build(force: false)).to eq([])
      end

      it 'outputs nothing when option is not provided' do
        expect(options.build).to eq([])
      end
    end

    context 'with negatable_flag options' do
      let(:options) do
        described_class.define do
          negatable_flag :full
        end
      end

      it 'outputs --flag when value is true' do
        expect(options.build(full: true)).to eq(['--full'])
      end

      it 'outputs --no-flag when value is false' do
        expect(options.build(full: false)).to eq(['--no-full'])
      end

      it 'outputs nothing when option is not provided' do
        expect(options.build).to eq([])
      end
    end

    context 'with value options' do
      let(:options) do
        described_class.define do
          value :branch
        end
      end

      it 'outputs --flag value as separate arguments' do
        expect(options.build(branch: 'main')).to eq(['--branch', 'main'])
      end

      it 'outputs nothing when value is nil' do
        expect(options.build(branch: nil)).to eq([])
      end

      it 'outputs nothing when option is not provided' do
        expect(options.build).to eq([])
      end
    end

    context 'with inline_value options' do
      let(:options) do
        described_class.define do
          inline_value :abbrev
        end
      end

      it 'outputs --flag=value as single argument' do
        expect(options.build(abbrev: '7')).to eq(['--abbrev=7'])
      end

      it 'outputs nothing when value is nil' do
        expect(options.build(abbrev: nil)).to eq([])
      end

      it 'outputs nothing when option is not provided' do
        expect(options.build).to eq([])
      end
    end

    context 'with multi_value options' do
      let(:options) do
        described_class.define do
          multi_value :config
        end
      end

      it 'outputs --flag value for each array element' do
        expect(options.build(config: %w[a b])).to eq(['--config', 'a', '--config', 'b'])
      end

      it 'outputs --flag value for single value' do
        expect(options.build(config: 'single')).to eq(['--config', 'single'])
      end

      it 'outputs nothing when value is nil' do
        expect(options.build(config: nil)).to eq([])
      end

      it 'outputs nothing when value is empty array' do
        expect(options.build(config: [])).to eq([])
      end
    end

    context 'with static options' do
      let(:options) do
        described_class.define do
          static '--no-progress'
        end
      end

      it 'always outputs the static flag' do
        expect(options.build).to eq(['--no-progress'])
      end

      it 'outputs static flag even with other options' do
        options_with_flag = described_class.define do
          static '-p'
          flag :force
        end
        expect(options_with_flag.build(force: true)).to eq(['-p', '--force'])
      end
    end

    context 'with custom options' do
      let(:options) do
        described_class.define do
          custom :dirty do |value|
            if value == true
              '--dirty'
            elsif value.is_a?(String)
              "--dirty=#{value}"
            end
          end
        end
      end

      it 'uses custom builder when value is true' do
        expect(options.build(dirty: true)).to eq(['--dirty'])
      end

      it 'uses custom builder when value is a string' do
        expect(options.build(dirty: '*')).to eq(['--dirty=*'])
      end

      it 'outputs nothing when custom builder returns nil' do
        expect(options.build(dirty: false)).to eq([])
      end

      it 'outputs nothing when option is not provided' do
        expect(options.build).to eq([])
      end
    end

    context 'with metadata options' do
      let(:options) do
        described_class.define do
          metadata :object
          metadata :path_limiter
        end
      end

      it 'does not output anything for metadata options' do
        expect(options.build(object: 'HEAD', path_limiter: 'src/')).to eq([])
      end

      it 'allows validation of metadata presence' do
        # metadata options are just for validation, not command building
        expect(options.build).to eq([])
      end
    end

    context 'with required positional arguments' do
      let(:options) do
        described_class.define do
          positional :repository, required: true
        end
      end

      it 'includes positional argument in output' do
        expect(options.build('https://github.com/user/repo')).to eq(['https://github.com/user/repo'])
      end

      it 'raises error when required positional is missing' do
        expect { options.build }.to raise_error(ArgumentError, /repository is required/)
      end
    end

    context 'with optional positional arguments' do
      let(:options) do
        described_class.define do
          positional :repository, required: true
          positional :directory
        end
      end

      it 'includes optional positional when provided' do
        expect(options.build('https://example.com', 'my-dir')).to eq(%w[https://example.com my-dir])
      end

      it 'excludes optional positional when not provided' do
        expect(options.build('https://example.com')).to eq(['https://example.com'])
      end
    end

    context 'with variadic positional arguments' do
      let(:options) do
        described_class.define do
          positional :paths, variadic: true
        end
      end

      it 'accepts multiple positional arguments' do
        expect(options.build('file1.rb', 'file2.rb')).to eq(%w[file1.rb file2.rb])
      end

      it 'accepts array of arguments' do
        expect(options.build(%w[file1.rb file2.rb])).to eq(%w[file1.rb file2.rb])
      end

      it 'outputs nothing when no paths provided' do
        expect(options.build).to eq([])
      end
    end

    context 'with positional arguments with default values' do
      let(:options) do
        described_class.define do
          positional :paths, variadic: true, default: ['.']
        end
      end

      it 'uses default when no value provided' do
        expect(options.build).to eq(['.'])
      end

      it 'overrides default when value provided' do
        expect(options.build('src/')).to eq(['src/'])
      end
    end

    context 'with positional arguments with separator' do
      let(:options) do
        described_class.define do
          flag :force
          positional :paths, variadic: true, separator: '--'
        end
      end

      it 'includes separator before positional arguments' do
        expect(options.build('file.rb', force: true)).to eq(['--force', '--', 'file.rb'])
      end

      it 'omits separator when no positional arguments' do
        expect(options.build(force: true)).to eq(['--force'])
      end
    end

    context 'with mixed positionals and keyword options' do
      let(:options) do
        described_class.define do
          flag :bare
          value :branch
          positional :repository, required: true
          positional :directory
        end
      end

      it 'outputs options before positionals' do
        result = options.build('https://example.com', 'my-dir', bare: true, branch: 'main')
        expect(result).to eq(['--bare', '--branch', 'main', 'https://example.com', 'my-dir'])
      end
    end

    context 'with custom flag names' do
      let(:options) do
        described_class.define do
          flag :recursive, flag: '-r'
          value :skip, flag: '--skip-worktree'
        end
      end

      it 'uses custom flag name for flags' do
        expect(options.build(recursive: true)).to eq(['-r'])
      end

      it 'uses custom flag name for valued options' do
        expect(options.build(skip: 'file.txt')).to eq(['--skip-worktree', 'file.txt'])
      end
    end
  end
end
