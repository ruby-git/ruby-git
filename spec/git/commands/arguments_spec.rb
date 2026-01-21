# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::Commands::Arguments do
  describe '.define' do
    it 'returns an Arguments instance' do
      args = described_class.define
      expect(args).to be_a(described_class)
    end
  end

  describe '#build' do
    context 'with flag options' do
      let(:args) do
        described_class.define do
          flag :force
        end
      end

      it 'outputs --flag when value is true' do
        expect(args.build(force: true)).to eq(['--force'])
      end

      it 'outputs nothing when value is false' do
        expect(args.build(force: false)).to eq([])
      end

      it 'outputs nothing when option is not provided' do
        expect(args.build).to eq([])
      end
    end

    context 'with negatable_flag options' do
      let(:args) do
        described_class.define do
          negatable_flag :full
        end
      end

      it 'outputs --flag when value is true' do
        expect(args.build(full: true)).to eq(['--full'])
      end

      it 'outputs --no-flag when value is false' do
        expect(args.build(full: false)).to eq(['--no-full'])
      end

      it 'outputs nothing when option is not provided' do
        expect(args.build).to eq([])
      end

      it 'raises an error when value is not a boolean' do
        expect { args.build(full: 'true') }.to raise_error(
          ArgumentError,
          /negatable_flag expects a boolean value, got "true"/
        )
      end
    end

    context 'with value options' do
      let(:args) do
        described_class.define do
          value :branch
        end
      end

      it 'outputs --flag value as separate arguments' do
        expect(args.build(branch: 'main')).to eq(['--branch', 'main'])
      end

      it 'outputs nothing when value is nil' do
        expect(args.build(branch: nil)).to eq([])
      end

      it 'outputs nothing when option is not provided' do
        expect(args.build).to eq([])
      end
    end

    context 'with inline_value options' do
      let(:args) do
        described_class.define do
          inline_value :abbrev
        end
      end

      it 'outputs --flag=value as single argument' do
        expect(args.build(abbrev: '7')).to eq(['--abbrev=7'])
      end

      it 'outputs nothing when value is nil' do
        expect(args.build(abbrev: nil)).to eq([])
      end

      it 'outputs nothing when option is not provided' do
        expect(args.build).to eq([])
      end
    end

    context 'with flag_or_inline_value options' do
      let(:args) do
        described_class.define do
          flag_or_inline_value :gpg_sign
        end
      end

      it 'outputs --flag when value is true' do
        expect(args.build(gpg_sign: true)).to eq(['--gpg-sign'])
      end

      it 'outputs nothing when value is false' do
        expect(args.build(gpg_sign: false)).to eq([])
      end

      it 'outputs --flag=value when value is a string' do
        expect(args.build(gpg_sign: 'key-id')).to eq(['--gpg-sign=key-id'])
      end

      it 'outputs nothing when option is not provided' do
        expect(args.build).to eq([])
      end

      it 'raises an error when value is not true, false, or a String' do
        expect { args.build(gpg_sign: 1) }.to raise_error(
          ArgumentError,
          /Invalid value for flag_or_inline_value: 1 \(Integer\); expected true, false, or a String/
        )
      end
    end

    context 'with negatable_flag_or_inline_value options' do
      let(:args) do
        described_class.define do
          negatable_flag_or_inline_value :sign
        end
      end

      it 'outputs --flag when value is true' do
        expect(args.build(sign: true)).to eq(['--sign'])
      end

      it 'outputs --no-flag when value is false' do
        expect(args.build(sign: false)).to eq(['--no-sign'])
      end

      it 'outputs --flag=value when value is a string' do
        expect(args.build(sign: 'key-id')).to eq(['--sign=key-id'])
      end

      it 'outputs nothing when option is not provided' do
        expect(args.build).to eq([])
      end

      it 'raises an error when value is not true, false, or a String' do
        expect { args.build(sign: 1) }.to raise_error(
          ArgumentError,
          /Invalid value for negatable_flag_or_inline_value: 1 \(Integer\); expected true, false, or a String/
        )
      end
    end

    context 'with multi_value options' do
      let(:args) do
        described_class.define do
          multi_value :config
        end
      end

      it 'outputs --flag value for each array element' do
        expect(args.build(config: %w[a b])).to eq(['--config', 'a', '--config', 'b'])
      end

      it 'outputs --flag value for single value' do
        expect(args.build(config: 'single')).to eq(['--config', 'single'])
      end

      it 'outputs nothing when value is nil' do
        expect(args.build(config: nil)).to eq([])
      end

      it 'outputs nothing when value is empty array' do
        expect(args.build(config: [])).to eq([])
      end
    end

    context 'with static options' do
      let(:args) do
        described_class.define do
          static '--no-progress'
        end
      end

      it 'always outputs the static flag' do
        expect(args.build).to eq(['--no-progress'])
      end

      it 'outputs static flag even with other options' do
        args_with_flag = described_class.define do
          static '-p'
          flag :force
        end
        expect(args_with_flag.build(force: true)).to eq(['-p', '--force'])
      end
    end

    context 'with custom options' do
      let(:args) do
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
        expect(args.build(dirty: true)).to eq(['--dirty'])
      end

      it 'uses custom builder when value is a string' do
        expect(args.build(dirty: '*')).to eq(['--dirty=*'])
      end

      it 'outputs nothing when custom builder returns nil' do
        expect(args.build(dirty: false)).to eq([])
      end

      it 'outputs nothing when option is not provided' do
        expect(args.build).to eq([])
      end
    end

    context 'with metadata options' do
      let(:args) do
        described_class.define do
          metadata :object
          metadata :path_limiter
        end
      end

      it 'does not output anything for metadata options' do
        expect(args.build(object: 'HEAD', path_limiter: 'src/')).to eq([])
      end

      it 'allows validation of metadata presence' do
        # metadata options are just for validation, not command building
        expect(args.build).to eq([])
      end
    end

    context 'with required positional arguments' do
      let(:args) do
        described_class.define do
          positional :repository, required: true
        end
      end

      it 'includes positional argument in output' do
        expect(args.build('https://github.com/user/repo')).to eq(['https://github.com/user/repo'])
      end

      it 'raises error when required positional is missing' do
        expect { args.build }.to raise_error(ArgumentError, /repository is required/)
      end
    end

    context 'with optional positional arguments' do
      let(:args) do
        described_class.define do
          positional :repository, required: true
          positional :directory
        end
      end

      it 'includes optional positional when provided' do
        expect(args.build('https://example.com', 'my-dir')).to eq(%w[https://example.com my-dir])
      end

      it 'excludes optional positional when not provided' do
        expect(args.build('https://example.com')).to eq(['https://example.com'])
      end
    end

    context 'with variadic positional arguments' do
      let(:args) do
        described_class.define do
          positional :paths, variadic: true
        end
      end

      it 'accepts multiple positional arguments' do
        expect(args.build('file1.rb', 'file2.rb')).to eq(%w[file1.rb file2.rb])
      end

      it 'accepts array of arguments' do
        expect(args.build(%w[file1.rb file2.rb])).to eq(%w[file1.rb file2.rb])
      end

      it 'outputs nothing when no paths provided' do
        expect(args.build).to eq([])
      end
    end

    context 'with required variadic positional arguments' do
      let(:args) do
        described_class.define do
          positional :paths, variadic: true, required: true
        end
      end

      it 'accepts multiple positional arguments' do
        expect(args.build('file1.rb', 'file2.rb')).to eq(%w[file1.rb file2.rb])
      end

      it 'accepts single positional argument' do
        expect(args.build('file.rb')).to eq(['file.rb'])
      end

      it 'raises ArgumentError when no paths provided' do
        expect { args.build }.to raise_error(ArgumentError, /at least one value is required for paths/)
      end

      it 'raises ArgumentError when empty array provided' do
        expect { args.build([]) }.to raise_error(ArgumentError, /at least one value is required for paths/)
      end
    end

    context 'with positional arguments with default values' do
      let(:args) do
        described_class.define do
          positional :paths, variadic: true, default: ['.']
        end
      end

      it 'uses default when no value provided' do
        expect(args.build).to eq(['.'])
      end

      it 'overrides default when value provided' do
        expect(args.build('src/')).to eq(['src/'])
      end
    end

    context 'with positional arguments with separator' do
      let(:args) do
        described_class.define do
          flag :force
          positional :paths, variadic: true, separator: '--'
        end
      end

      it 'includes separator before positional arguments' do
        expect(args.build('file.rb', force: true)).to eq(['--force', '--', 'file.rb'])
      end

      it 'omits separator when no positional arguments' do
        expect(args.build(force: true)).to eq(['--force'])
      end
    end

    context 'with mixed positionals and keyword options' do
      let(:args) do
        described_class.define do
          flag :bare
          value :branch
          positional :repository, required: true
          positional :directory
        end
      end

      it 'outputs options before positionals' do
        result = args.build('https://example.com', 'my-dir', bare: true, branch: 'main')
        expect(result).to eq(['--bare', '--branch', 'main', 'https://example.com', 'my-dir'])
      end
    end

    context 'with custom flag names' do
      let(:args) do
        described_class.define do
          flag :recursive, args: '-r'
          value :skip, args: '--skip-worktree'
        end
      end

      it 'uses custom flag name for flags' do
        expect(args.build(recursive: true)).to eq(['-r'])
      end

      it 'uses custom flag name for valued options' do
        expect(args.build(skip: 'file.txt')).to eq(['--skip-worktree', 'file.txt'])
      end
    end

    context 'with unsupported options' do
      let(:args) do
        described_class.define do
          flag :force
        end
      end

      it 'raises ArgumentError for unknown options' do
        expect { args.build(invalid: true) }.to(
          raise_error(ArgumentError, /Unsupported options: :invalid/)
        )
      end

      it 'raises ArgumentError listing all unknown options' do
        expect { args.build(foo: true, bar: true) }.to(
          raise_error(ArgumentError, /Unsupported options: :foo, :bar/)
        )
      end
    end

    context 'with custom options returning arrays' do
      let(:args) do
        described_class.define do
          custom(:depth) { |v| ['--depth', v.to_i] }
        end
      end

      it 'concatenates array results' do
        expect(args.build(depth: 5)).to eq(['--depth', 5])
      end

      it 'handles string values converted to integers' do
        expect(args.build(depth: '10')).to eq(['--depth', 10])
      end
    end

    context 'with validator on negatable_flag' do
      let(:args) do
        described_class.define do
          negatable_flag :single_branch, validator: ->(v) { [nil, true, false].include?(v) }
        end
      end

      it 'allows valid true value' do
        expect(args.build(single_branch: true)).to eq(['--single-branch'])
      end

      it 'allows valid false value' do
        expect(args.build(single_branch: false)).to eq(['--no-single-branch'])
      end

      it 'allows valid nil value' do
        expect(args.build(single_branch: nil)).to eq([])
      end

      it 'raises ArgumentError for invalid values' do
        expect { args.build(single_branch: 'yes') }.to(
          raise_error(ArgumentError, /Invalid value for option: single_branch/)
        )
      end
    end

    context 'with option aliases' do
      let(:args) do
        described_class.define do
          value %i[origin remote]
        end
      end

      it 'accepts the primary key' do
        expect(args.build(origin: 'upstream')).to eq(['--origin', 'upstream'])
      end

      it 'accepts the alias key' do
        expect(args.build(remote: 'upstream')).to eq(['--origin', 'upstream'])
      end

      it 'uses first key for flag name by default' do
        args = described_class.define { flag %i[verbose v] }
        expect(args.build(verbose: true)).to eq(['--verbose'])
        expect(args.build(v: true)).to eq(['--verbose'])
      end

      it 'allows custom flag with aliases' do
        args = described_class.define { flag %i[recursive r], args: '-R' }
        expect(args.build(recursive: true)).to eq(['-R'])
        expect(args.build(r: true)).to eq(['-R'])
      end

      it 'raises error if both alias and primary provided' do
        expect { args.build(origin: 'one', remote: 'two') }.to(
          raise_error(ArgumentError, /Conflicting options.*origin.*remote/)
        )
      end
    end

    context 'with variadic positional arguments containing nil values' do
      let(:args) do
        described_class.define do
          positional :paths, variadic: true
        end
      end

      it 'rejects nil values with clear ArgumentError' do
        expect { args.build('file1.rb', nil, 'file2.rb') }.to(
          raise_error(ArgumentError, /nil values are not allowed in variadic positional argument: paths/)
        )
      end

      it 'rejects array containing nil values' do
        expect { args.build(['file1.rb', nil, 'file2.rb']) }.to(
          raise_error(ArgumentError, /nil values are not allowed in variadic positional argument: paths/)
        )
      end

      it 'accepts all valid values' do
        expect(args.build('file1.rb', 'file2.rb')).to eq(%w[file1.rb file2.rb])
      end
    end

    context 'with args: parameter arrays' do
      it 'supports arrays for flag type' do
        args = described_class.define do
          flag :amend, args: ['--amend', '--no-edit']
        end
        expect(args.build(amend: true)).to eq(['--amend', '--no-edit'])
      end

      it 'supports arrays for negatable_flag type' do
        args = described_class.define do
          negatable_flag :verbose, args: ['--verbose', '--all']
        end
        expect(args.build(verbose: true)).to eq(['--verbose', '--all'])
        expect(args.build(verbose: false)).to eq(['--no-verbose', '--no-all'])
      end

      it 'rejects arrays for value type' do
        expect do
          described_class.define do
            value :branch, args: ['--branch', '--set-upstream']
          end
        end.to raise_error(ArgumentError, /arrays for args: parameter are only supported for flag types/)
      end

      it 'rejects arrays for inline_value type' do
        expect do
          described_class.define do
            inline_value :message, args: ['--message', '--edit']
          end
        end.to raise_error(ArgumentError, /arrays for args: parameter are only supported for flag types/)
      end

      it 'rejects arrays for multi_value type' do
        expect do
          described_class.define do
            multi_value :config, args: ['--config', '--global']
          end
        end.to raise_error(ArgumentError, /arrays for args: parameter are only supported for flag types/)
      end

      it 'rejects arrays for flag_or_inline_value type' do
        expect do
          described_class.define do
            flag_or_inline_value :gpg_sign, args: ['--gpg-sign', '--verify']
          end
        end.to raise_error(ArgumentError, /arrays for args: parameter are only supported for flag types/)
      end

      it 'rejects arrays for negatable_flag_or_inline_value type' do
        expect do
          described_class.define do
            negatable_flag_or_inline_value :sign, args: ['--sign', '--verify']
          end
        end.to raise_error(ArgumentError, /arrays for args: parameter are only supported for flag types/)
      end
    end

    context 'with allow_empty parameter' do
      context 'for value types' do
        let(:args_without_allow_empty) do
          described_class.define do
            value :message
          end
        end

        let(:args_with_allow_empty) do
          described_class.define do
            value :message, allow_empty: true
          end
        end

        it 'skips empty string by default' do
          expect(args_without_allow_empty.build(message: '')).to eq([])
        end

        it 'includes empty string when allow_empty is true' do
          expect(args_with_allow_empty.build(message: '')).to eq(['--message', ''])
        end

        it 'includes non-empty string regardless of allow_empty' do
          expect(args_without_allow_empty.build(message: 'hello')).to eq(['--message', 'hello'])
          expect(args_with_allow_empty.build(message: 'hello')).to eq(['--message', 'hello'])
        end
      end

      context 'for inline_value types' do
        let(:args_without_allow_empty) do
          described_class.define do
            inline_value :abbrev
          end
        end

        let(:args_with_allow_empty) do
          described_class.define do
            inline_value :abbrev, allow_empty: true
          end
        end

        it 'skips empty string by default' do
          expect(args_without_allow_empty.build(abbrev: '')).to eq([])
        end

        it 'includes empty string when allow_empty is true' do
          expect(args_with_allow_empty.build(abbrev: '')).to eq(['--abbrev='])
        end

        it 'includes non-empty string regardless of allow_empty' do
          expect(args_without_allow_empty.build(abbrev: '7')).to eq(['--abbrev=7'])
          expect(args_with_allow_empty.build(abbrev: '7')).to eq(['--abbrev=7'])
        end
      end

      context 'for multi_value types' do
        let(:args) do
          described_class.define do
            multi_value :config
          end
        end

        it 'skips empty array' do
          expect(args.build(config: [])).to eq([])
        end

        it 'includes empty strings in array (no filtering)' do
          expect(args.build(config: ['', 'value'])).to eq(['--config', '', '--config', 'value'])
        end

        it 'processes all non-empty values' do
          expect(args.build(config: %w[a b c])).to eq(['--config', 'a', '--config', 'b', '--config', 'c'])
        end
      end
    end

    context 'with type: parameter for validation' do
      context 'with String type' do
        let(:args) do
          described_class.define do
            value :message, type: String
          end
        end

        it 'accepts String values' do
          expect(args.build(message: 'hello')).to eq(['--message', 'hello'])
        end

        it 'accepts nil values (skips validation and output)' do
          expect(args.build(message: nil)).to eq([])
        end

        it 'raises descriptive error for non-String values' do
          expect { args.build(message: 123) }.to raise_error(
            ArgumentError,
            /The :message option must be a String, but was a Integer/
          )
        end
      end

      context 'with Integer type' do
        let(:args) do
          described_class.define do
            value :depth, type: Integer
          end
        end

        it 'accepts Integer values' do
          expect(args.build(depth: 42)).to eq(['--depth', '42'])
        end

        it 'accepts nil values (skips validation and output)' do
          expect(args.build(depth: nil)).to eq([])
        end

        it 'raises descriptive error for non-Integer values' do
          expect { args.build(depth: 'not a number') }.to raise_error(
            ArgumentError,
            /The :depth option must be a Integer, but was a String/
          )
        end
      end

      context 'with Array type' do
        let(:args) do
          described_class.define do
            multi_value :paths, type: Array
          end
        end

        it 'accepts Array values' do
          expect(args.build(paths: %w[a b])).to eq(['--paths', 'a', '--paths', 'b'])
        end

        it 'accepts nil values (skips validation and output)' do
          expect(args.build(paths: nil)).to eq([])
        end

        it 'raises descriptive error for non-Array values' do
          expect { args.build(paths: 'single') }.to raise_error(
            ArgumentError,
            /The :paths option must be a Array, but was a String/
          )
        end
      end

      context 'with multiple options having type validation' do
        let(:args) do
          described_class.define do
            value :message, type: String
            value :depth, type: Integer
          end
        end

        it 'validates all typed options independently' do
          expect(args.build(message: 'hello', depth: 5)).to eq(['--message', 'hello', '--depth', '5'])
        end

        it 'raises error for first invalid option encountered' do
          expect { args.build(message: 123, depth: 'invalid') }.to raise_error(
            ArgumentError,
            /The :message option must be a String, but was a Integer/
          )
        end
      end

      context 'with multiple allowed types' do
        let(:args) do
          described_class.define do
            value :timeout, type: [Integer, Float]
          end
        end

        it 'accepts first type' do
          expect(args.build(timeout: 30)).to eq(['--timeout', '30'])
        end

        it 'accepts second type' do
          expect(args.build(timeout: 30.5)).to eq(['--timeout', '30.5'])
        end

        it 'raises descriptive error for invalid type' do
          expect { args.build(timeout: 'thirty') }.to raise_error(
            ArgumentError,
            /The :timeout option must be a Integer or Float, but was a String/
          )
        end
      end

      context 'when type: and validator: are both specified' do
        it 'raises an error at definition time' do
          expect do
            described_class.define do
              negatable_flag :single_branch, type: String, validator: ->(v) { [true, false].include?(v) }
            end
          end.to raise_error(ArgumentError, /cannot specify both type: and validator: for :single_branch/)
        end
      end
    end

    context 'with conflicts method' do
      context 'with two conflicting options' do
        let(:args) do
          described_class.define do
            flag :patch
            flag :stat
            conflicts :patch, :stat
          end
        end

        it 'allows using neither option' do
          expect(args.build).to eq([])
        end

        it 'allows using only first option' do
          expect(args.build(patch: true)).to eq(['--patch'])
        end

        it 'allows using only second option' do
          expect(args.build(stat: true)).to eq(['--stat'])
        end

        it 'raises error when both options are provided' do
          expect { args.build(patch: true, stat: true) }.to raise_error(
            ArgumentError,
            /cannot specify :patch and :stat/
          )
        end

        it 'allows false values (does not trigger conflict)' do
          expect(args.build(patch: true, stat: false)).to eq(['--patch'])
          expect(args.build(patch: false, stat: true)).to eq(['--stat'])
        end

        it 'allows nil values (does not trigger conflict)' do
          expect(args.build(patch: true, stat: nil)).to eq(['--patch'])
        end
      end

      context 'with multiple conflicting options' do
        let(:args) do
          described_class.define do
            flag :patch
            flag :stat
            flag :summary
            conflicts :patch, :stat, :summary
          end
        end

        it 'raises error when any two options are provided' do
          expect { args.build(patch: true, stat: true) }.to raise_error(
            ArgumentError,
            /cannot specify :patch and :stat/
          )
          expect { args.build(patch: true, summary: true) }.to raise_error(
            ArgumentError,
            /cannot specify :patch and :summary/
          )
          expect { args.build(stat: true, summary: true) }.to raise_error(
            ArgumentError,
            /cannot specify :stat and :summary/
          )
        end

        it 'raises error when all three options are provided' do
          expect { args.build(patch: true, stat: true, summary: true) }.to raise_error(
            ArgumentError,
            /cannot specify :patch and :stat/
          )
        end
      end

      context 'with multiple conflict groups' do
        let(:args) do
          described_class.define do
            flag :patch
            flag :stat
            flag :quiet
            flag :verbose
            conflicts :patch, :stat
            conflicts :quiet, :verbose
          end
        end

        it 'validates each conflict group independently' do
          # Allowed: patch with verbose
          expect(args.build(patch: true, verbose: true)).to eq(['--patch', '--verbose'])
          # Allowed: stat with quiet
          expect(args.build(stat: true, quiet: true)).to eq(['--stat', '--quiet'])
        end

        it 'raises error when first conflict group violated' do
          expect { args.build(patch: true, stat: true, verbose: true) }.to raise_error(
            ArgumentError,
            /cannot specify :patch and :stat/
          )
        end

        it 'raises error when second conflict group violated' do
          expect { args.build(patch: true, quiet: true, verbose: true) }.to raise_error(
            ArgumentError,
            /cannot specify :quiet and :verbose/
          )
        end
      end

      context 'with conflicts on valued options' do
        let(:args) do
          described_class.define do
            value :branch
            value :tag
            conflicts :branch, :tag
          end
        end

        it 'raises error when both valued options provided' do
          expect { args.build(branch: 'main', tag: 'v1.0') }.to raise_error(
            ArgumentError,
            /cannot specify :branch and :tag/
          )
        end

        it 'allows one valued option' do
          expect(args.build(branch: 'main')).to eq(['--branch', 'main'])
          expect(args.build(tag: 'v1.0')).to eq(['--tag', 'v1.0'])
        end
      end

      context 'with conflicts on mixed option types' do
        let(:args) do
          described_class.define do
            flag :all
            value :since
            conflicts :all, :since
          end
        end

        it 'raises error when flag and value both provided' do
          expect { args.build(all: true, since: '2020-01-01') }.to raise_error(
            ArgumentError,
            /cannot specify :all and :since/
          )
        end

        it 'allows either option alone' do
          expect(args.build(all: true)).to eq(['--all'])
          expect(args.build(since: '2020-01-01')).to eq(['--since', '2020-01-01'])
        end
      end
    end
  end
end
