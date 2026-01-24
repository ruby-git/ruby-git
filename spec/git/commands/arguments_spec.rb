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

    context 'with value multi_valued: true' do
      let(:args) do
        described_class.define do
          value :config, multi_valued: true
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

      it 'includes empty strings in array even with allow_empty: false (default)' do
        expect(args.build(config: ['', 'value'])).to eq(['--config', '', '--config', 'value'])
      end

      it 'outputs nothing for single empty string with allow_empty: false (default)' do
        expect(args.build(config: '')).to eq([])
      end

      context 'with allow_empty: true' do
        let(:args) do
          described_class.define do
            value :config, multi_valued: true, allow_empty: true
          end
        end

        it 'includes empty strings in the array' do
          expect(args.build(config: ['', 'value'])).to eq(['--config', '', '--config', 'value'])
        end

        it 'outputs flag with empty value for single empty string' do
          expect(args.build(config: '')).to eq(['--config', ''])
        end
      end
    end

    context 'with inline_value multi_valued: true' do
      let(:args) do
        described_class.define do
          inline_value :sort, multi_valued: true
        end
      end

      it 'outputs --flag=value for each array element' do
        expect(args.build(sort: %w[refname -committerdate])).to eq(['--sort=refname', '--sort=-committerdate'])
      end

      it 'outputs --flag=value for single value' do
        expect(args.build(sort: 'refname')).to eq(['--sort=refname'])
      end

      it 'outputs nothing when value is nil' do
        expect(args.build(sort: nil)).to eq([])
      end

      it 'outputs nothing when value is empty array' do
        expect(args.build(sort: [])).to eq([])
      end

      it 'includes empty strings in array even with allow_empty: false (default)' do
        expect(args.build(sort: ['', 'refname'])).to eq(['--sort=', '--sort=refname'])
      end

      it 'outputs nothing for single empty string with allow_empty: false (default)' do
        expect(args.build(sort: '')).to eq([])
      end

      context 'with allow_empty: true' do
        let(:args) do
          described_class.define do
            inline_value :sort, multi_valued: true, allow_empty: true
          end
        end

        it 'includes empty strings in the array' do
          expect(args.build(sort: ['', 'refname'])).to eq(['--sort=', '--sort=refname'])
        end

        it 'outputs flag with empty value for single empty string' do
          expect(args.build(sort: '')).to eq(['--sort='])
        end
      end

      context 'with type: validation' do
        let(:args) do
          described_class.define do
            inline_value :sort, multi_valued: true, type: String
          end
        end

        it 'validates type against the provided value (not array elements)' do
          # Type validation applies to the entire value, not individual elements
          # Arrays pass String validation because type check happens before Array() normalization
          expect(args.build(sort: 'refname')).to eq(['--sort=refname'])
        end

        it 'rejects values that do not match the type' do
          expect { args.build(sort: 123) }.to raise_error(ArgumentError, /must be a String/)
        end
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

      it 'accepts empty string as valid value for required positional' do
        expect(args.build('')).to eq([''])
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

      it 'accepts empty string as valid value in variadic positional' do
        expect(args.build('', 'file.rb')).to eq(['', 'file.rb'])
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

    context 'with unexpected positional arguments' do
      context 'when no positionals are defined' do
        let(:args) do
          described_class.define do
            flag :force
          end
        end

        it 'raises ArgumentError for single unexpected positional' do
          expect { args.build('unexpected') }.to raise_error(
            ArgumentError,
            /Unexpected positional arguments: unexpected/
          )
        end

        it 'raises ArgumentError for multiple unexpected positionals' do
          expect { args.build('arg1', 'arg2', 'arg3') }.to raise_error(
            ArgumentError,
            /Unexpected positional arguments: arg1, arg2, arg3/
          )
        end

        it 'does not raise for nil positional arguments' do
          expect(args.build(nil)).to eq([])
        end

        it 'does not raise for multiple nil positional arguments' do
          expect(args.build(nil, nil)).to eq([])
        end
      end

      context 'when optional positional is defined' do
        let(:args) do
          described_class.define do
            positional :commit, required: false
          end
        end

        it 'accepts expected positional' do
          expect(args.build('HEAD~1')).to eq(['HEAD~1'])
        end

        it 'accepts nil as the positional (treated as not provided)' do
          expect(args.build(nil)).to eq([])
        end

        it 'raises ArgumentError for extra positional beyond defined ones' do
          expect { args.build('HEAD~1', 'unexpected') }.to raise_error(
            ArgumentError,
            /Unexpected positional arguments: unexpected/
          )
        end

        it 'raises ArgumentError for multiple extra positionals' do
          expect { args.build('HEAD~1', 'extra1', 'extra2') }.to raise_error(
            ArgumentError,
            /Unexpected positional arguments: extra1, extra2/
          )
        end

        it 'does not count trailing nils as unexpected' do
          expect(args.build('HEAD~1', nil, nil)).to eq(['HEAD~1'])
        end

        it 'raises for non-nil unexpected arguments even with trailing nils' do
          expect { args.build('HEAD~1', 'unexpected', nil) }.to raise_error(
            ArgumentError,
            /Unexpected positional arguments: unexpected/
          )
        end
      end

      context 'when required positional is defined' do
        let(:args) do
          described_class.define do
            positional :repository, required: true
          end
        end

        it 'accepts the required positional' do
          expect(args.build('https://example.com')).to eq(['https://example.com'])
        end

        it 'raises ArgumentError for extra positional beyond required one' do
          expect { args.build('https://example.com', 'unexpected') }.to raise_error(
            ArgumentError,
            /Unexpected positional arguments: unexpected/
          )
        end
      end

      context 'when multiple positionals are defined' do
        let(:args) do
          described_class.define do
            positional :repository, required: true
            positional :directory, required: false
          end
        end

        it 'accepts both defined positionals' do
          expect(args.build('https://example.com', 'my-dir')).to eq(['https://example.com', 'my-dir'])
        end

        it 'accepts only the required positional' do
          expect(args.build('https://example.com')).to eq(['https://example.com'])
        end

        it 'raises ArgumentError for extra positionals beyond defined ones' do
          expect { args.build('https://example.com', 'my-dir', 'unexpected') }.to raise_error(
            ArgumentError,
            /Unexpected positional arguments: unexpected/
          )
        end

        it 'raises ArgumentError for multiple extra positionals' do
          expect { args.build('repo', 'dir', 'extra1', 'extra2', 'extra3') }.to raise_error(
            ArgumentError,
            /Unexpected positional arguments: extra1, extra2, extra3/
          )
        end
      end

      context 'when variadic positional is defined' do
        let(:args) do
          described_class.define do
            positional :paths, variadic: true
          end
        end

        it 'accepts any number of positionals (no unexpected arguments)' do
          expect(args.build('file1.rb', 'file2.rb', 'file3.rb')).to eq(['file1.rb', 'file2.rb', 'file3.rb'])
        end

        it 'accepts many positionals without raising' do
          many_files = (1..10).map { |i| "file#{i}.rb" }
          expect(args.build(*many_files)).to eq(many_files)
        end
      end

      context 'when variadic positional comes after regular positional' do
        let(:args) do
          described_class.define do
            positional :command, required: true
            positional :args, variadic: true
          end
        end

        it 'accepts command with variadic args (no unexpected arguments)' do
          expect(args.build('run', '--verbose', '--debug')).to eq(['run', '--verbose', '--debug'])
        end

        it 'accepts just the required command' do
          expect(args.build('run')).to eq(['run'])
        end
      end

      context 'edge case: empty strings vs nil for positionals' do
        let(:args) do
          described_class.define do
            positional :commit, required: false
          end
        end

        it 'passes through empty string as a valid positional value' do
          expect(args.build('')).to eq([''])
        end

        it 'treats nil as not provided' do
          expect(args.build(nil)).to eq([])
        end

        it 'raises for unexpected positional after empty string' do
          expect { args.build('', 'unexpected') }.to raise_error(
            ArgumentError,
            /Unexpected positional arguments: unexpected/
          )
        end

        it 'does not count nil as unexpected' do
          expect { args.build('valid', nil) }.to_not raise_error
          expect(args.build('valid', nil)).to eq(['valid'])
        end
      end

      context 'edge case: empty arrays for variadic positionals' do
        let(:args) do
          described_class.define do
            positional :paths, variadic: true
          end
        end

        it 'treats empty array as not provided (equivalent to nil)' do
          expect(args.build([])).to eq([])
        end

        it 'treats nil as not provided' do
          expect(args.build(nil)).to eq([])
        end

        it 'accepts non-empty array' do
          expect(args.build(['file1.rb', 'file2.rb'])).to eq(['file1.rb', 'file2.rb'])
        end

        context 'with separator' do
          let(:args) do
            described_class.define do
              flag :force
              positional :paths, variadic: true, separator: '--'
            end
          end

          it 'omits separator when empty array provided' do
            expect(args.build([], force: true)).to eq(['--force'])
          end

          it 'omits separator when nil provided' do
            expect(args.build(nil, force: true)).to eq(['--force'])
          end

          it 'includes separator when non-empty array provided' do
            expect(args.build(['file.rb'], force: true)).to eq(['--force', '--', 'file.rb'])
          end
        end

        context 'with default value' do
          let(:args) do
            described_class.define do
              positional :paths, variadic: true, default: ['.']
            end
          end

          it 'uses default when empty array provided' do
            expect(args.build([])).to eq(['.'])
          end

          it 'uses default when nil provided' do
            expect(args.build(nil)).to eq(['.'])
          end

          it 'overrides default when non-empty array provided' do
            expect(args.build(['src/'])).to eq(['src/'])
          end

          it 'accepts value identical to the default (no false positive unexpected)' do
            # This is a regression test: passing a value that equals the default
            # should not be treated as unexpected
            expect(args.build(['.'])).to eq(['.'])
            expect(args.build('.')).to eq(['.'])
          end
        end
      end

      context 'multiple variadic positionals (rejected at definition time)' do
        it 'raises ArgumentError when defining a second variadic positional' do
          expect do
            described_class.define do
              positional :sources, variadic: true
              positional :middle
              positional :paths, variadic: true
            end
          end.to raise_error(
            ArgumentError,
            /only one variadic positional is allowed.*:sources is already variadic.*cannot add :paths/
          )
        end
      end

      context 'with mixed options and unexpected positionals' do
        let(:args) do
          described_class.define do
            flag :force
            positional :path, required: false
          end
        end

        it 'raises for unexpected positional even when options are present' do
          expect { args.build('expected', 'unexpected', force: true) }.to raise_error(
            ArgumentError,
            /Unexpected positional arguments: unexpected/
          )
        end

        it 'allows expected positional with options' do
          expect(args.build('expected', force: true)).to eq(['--force', 'expected'])
        end
      end

      # =======================================================================
      # Positional Argument Mapping (Ruby Method Signature Semantics)
      # =======================================================================
      #
      # These tests verify that positional arguments are mapped following the
      # same rules as Ruby method signatures:
      #
      # 1. Required positionals before variadic are filled first (left to right)
      # 2. Required positionals after variadic are filled from the end
      # 3. Optional positionals (with defaults) are filled with remaining args
      # 4. Variadic positional gets whatever is left in the middle
      #
      # Example Ruby method: def foo(a, b, *middle, c, d)
      #   foo(1, 2, 3)       => a=1, b=2, middle=[], c=3, d raises ArgumentError
      #   foo(1, 2, 3, 4)    => a=1, b=2, middle=[], c=3, d=4
      #   foo(1, 2, 3, 4, 5) => a=1, b=2, middle=[3], c=4, d=5
      #
      # =======================================================================

      context 'positional mapping (Ruby semantics)' do
        # Pattern: def foo(arg1)
        context 'single required positional' do
          let(:args) do
            described_class.define do
              positional :arg1, required: true
            end
          end

          it 'maps the argument correctly' do
            expect(args.build('value1')).to eq(['value1'])
          end

          it 'raises when not provided' do
            expect { args.build }.to raise_error(ArgumentError, /arg1 is required/)
          end
        end

        # Pattern: def foo(arg1 = 'default')
        context 'single optional positional with default' do
          let(:args) do
            described_class.define do
              positional :arg1, default: 'default_value'
            end
          end

          it 'uses provided value' do
            expect(args.build('provided')).to eq(['provided'])
          end

          it 'uses default when not provided' do
            expect(args.build).to eq(['default_value'])
          end
        end

        # Pattern: def foo(arg1, arg2)
        context 'two required positionals' do
          let(:args) do
            described_class.define do
              positional :arg1, required: true
              positional :arg2, required: true
            end
          end

          it 'maps arguments in order' do
            expect(args.build('value1', 'value2')).to eq(%w[value1 value2])
          end

          it 'raises when second is missing' do
            expect { args.build('value1') }.to raise_error(ArgumentError, /arg2 is required/)
          end
        end

        # Pattern: def foo(arg1, arg2 = 'default')
        context 'required followed by optional' do
          let(:args) do
            described_class.define do
              positional :arg1, required: true
              positional :arg2, default: 'default2'
            end
          end

          it 'maps both when both provided' do
            expect(args.build('val1', 'val2')).to eq(%w[val1 val2])
          end

          it 'uses default for second when only first provided' do
            expect(args.build('val1')).to eq(%w[val1 default2])
          end
        end

        # Pattern: def foo(arg1 = 'default', arg2)
        # Ruby fills required args first (from the end), then optional from remaining
        context 'optional followed by required' do
          let(:args) do
            described_class.define do
              positional :arg1, default: 'default1'
              positional :arg2, required: true
            end
          end

          it 'maps both when both provided' do
            expect(args.build('val1', 'val2')).to eq(%w[val1 val2])
          end

          it 'uses default for first when only one arg provided (Ruby semantics)' do
            # Ruby: def foo(a = 1, b); foo(2) => a=1, b=2
            expect(args.build('val2')).to eq(%w[default1 val2])
          end

          it 'raises when no arguments provided' do
            expect { args.build }.to raise_error(ArgumentError, /arg2 is required/)
          end
        end

        # Pattern: def foo(arg1 = 'default1', arg2 = 'default2', arg3)
        context 'two optionals followed by required' do
          let(:args) do
            described_class.define do
              positional :arg1, default: 'default1'
              positional :arg2, default: 'default2'
              positional :arg3, required: true
            end
          end

          it 'maps all when all provided' do
            expect(args.build('val1', 'val2', 'val3')).to eq(%w[val1 val2 val3])
          end

          it 'uses both defaults when only required provided' do
            expect(args.build('val3')).to eq(%w[default1 default2 val3])
          end

          it 'fills first optional when two args provided' do
            # Ruby: def foo(a = 1, b = 2, c); foo('x', 'y') => a='x', b=2, c='y'
            expect(args.build('val1', 'val3')).to eq(%w[val1 default2 val3])
          end
        end

        # Pattern: def foo(arg1, arg2 = 'default2', arg3)
        context 'required, optional, required' do
          let(:args) do
            described_class.define do
              positional :arg1, required: true
              positional :arg2, default: 'default2'
              positional :arg3, required: true
            end
          end

          it 'maps all when all provided' do
            expect(args.build('val1', 'val2', 'val3')).to eq(%w[val1 val2 val3])
          end

          it 'uses default for middle when only two args provided' do
            # Ruby: def foo(a, b = 2, c); foo('x', 'y') => a='x', b=2, c='y'
            expect(args.build('val1', 'val3')).to eq(%w[val1 default2 val3])
          end

          it 'raises when only one argument provided' do
            expect { args.build('val1') }.to raise_error(ArgumentError, /is required/)
          end
        end

        # Pattern: def foo(*args)
        context 'variadic only' do
          let(:args) do
            described_class.define do
              positional :paths, variadic: true
            end
          end

          it 'accepts no arguments' do
            expect(args.build).to eq([])
          end

          it 'accepts one argument' do
            expect(args.build('file1')).to eq(['file1'])
          end

          it 'accepts many arguments' do
            expect(args.build('f1', 'f2', 'f3', 'f4')).to eq(%w[f1 f2 f3 f4])
          end
        end

        # Pattern: def foo(arg1, *rest)
        context 'required followed by variadic' do
          let(:args) do
            described_class.define do
              positional :command, required: true
              positional :args, variadic: true
            end
          end

          it 'maps first to required, rest to variadic' do
            expect(args.build('cmd', 'arg1', 'arg2')).to eq(%w[cmd arg1 arg2])
          end

          it 'maps only required when variadic is empty' do
            expect(args.build('cmd')).to eq(['cmd'])
          end

          it 'raises when required is missing' do
            expect { args.build }.to raise_error(ArgumentError, /command is required/)
          end
        end

        # Pattern: def foo(*sources, destination) - the git mv pattern!
        context 'variadic followed by required (git mv pattern)' do
          let(:args) do
            described_class.define do
              positional :sources, variadic: true, required: true
              positional :destination, required: true
            end
          end

          it 'maps last to destination, rest to sources' do
            expect(args.build('src1', 'src2', 'dest')).to eq(%w[src1 src2 dest])
          end

          it 'handles single source and destination' do
            expect(args.build('src', 'dest')).to eq(%w[src dest])
          end

          it 'handles many sources' do
            expect(args.build('s1', 's2', 's3', 's4', 'dest')).to eq(%w[s1 s2 s3 s4 dest])
          end

          it 'raises when only destination provided (sources required)' do
            expect { args.build('dest') }.to raise_error(
              ArgumentError,
              /at least one value is required for sources/
            )
          end

          it 'raises when nothing provided' do
            expect { args.build }.to raise_error(ArgumentError)
          end
        end

        # Pattern: def foo(first, *middle, last)
        context 'required, variadic, required' do
          let(:args) do
            described_class.define do
              positional :first, required: true
              positional :middle, variadic: true
              positional :last, required: true
            end
          end

          it 'maps first and last, middle gets the rest' do
            expect(args.build('a', 'b', 'c', 'd', 'e')).to eq(%w[a b c d e])
          end

          it 'handles empty middle' do
            expect(args.build('first', 'last')).to eq(%w[first last])
          end

          it 'handles single middle value' do
            expect(args.build('first', 'mid', 'last')).to eq(%w[first mid last])
          end

          it 'raises when only one argument (need at least 2)' do
            # With Ruby-like allocation, post-variadic required are reserved first,
            # so pre-variadic required fails when not enough values remain
            expect { args.build('only') }.to raise_error(ArgumentError, /first is required/)
          end
        end

        # Pattern: def foo(a, b, *middle, c, d)
        context 'two required, variadic, two required' do
          let(:args) do
            described_class.define do
              positional :a, required: true
              positional :b, required: true
              positional :middle, variadic: true
              positional :c, required: true
              positional :d, required: true
            end
          end

          it 'maps with empty middle' do
            expect(args.build('1', '2', '3', '4')).to eq(%w[1 2 3 4])
          end

          it 'maps with one middle value' do
            expect(args.build('1', '2', 'm1', '3', '4')).to eq(%w[1 2 m1 3 4])
          end

          it 'maps with multiple middle values' do
            expect(args.build('1', '2', 'm1', 'm2', 'm3', '3', '4')).to eq(%w[1 2 m1 m2 m3 3 4])
          end

          it 'raises when not enough arguments' do
            # With Ruby-like allocation, post-variadic required are reserved first,
            # so pre-variadic required fails when not enough values remain
            expect { args.build('1', '2', '3') }.to raise_error(ArgumentError, /b is required/)
          end
        end

        # Pattern: def foo(a, *middle, c = 'default')
        context 'required, variadic, optional' do
          let(:args) do
            described_class.define do
              positional :a, required: true
              positional :middle, variadic: true
              positional :c, default: 'default_c'
            end
          end

          it 'uses default for c when only a provided' do
            expect(args.build('val_a')).to eq(%w[val_a default_c])
          end

          it 'maps a and c, middle empty' do
            expect(args.build('val_a', 'val_c')).to eq(%w[val_a val_c])
          end

          it 'maps all three parts' do
            expect(args.build('val_a', 'm1', 'm2', 'val_c')).to eq(%w[val_a m1 m2 val_c])
          end
        end

        # Pattern: def foo(a = 'default', *middle, b)
        # Now follows Ruby semantics: optional before variadic with required after
        context 'optional, variadic, required (Ruby semantics)' do
          let(:args) do
            described_class.define do
              positional :a, default: 'default_a'
              positional :middle, variadic: true
              positional :b, required: true
            end
          end

          # Ruby: foo('x') => a='default_a', middle=[], b='x'
          it 'follows Ruby semantics - optional gets default when only required is provided' do
            expect(args.build('only_one')).to eq(%w[default_a only_one])
          end

          it 'fills optional when enough arguments provided' do
            expect(args.build('val_a', 'val_b')).to eq(%w[val_a val_b])
          end

          it 'fills variadic with middle values' do
            expect(args.build('val_a', 'm1', 'm2', 'val_b')).to eq(%w[val_a m1 m2 val_b])
          end
        end

        # Pattern: def foo(a = 'default', *rest)
        context 'optional followed by variadic (no post)' do
          let(:args) do
            described_class.define do
              positional :a, default: 'default_a'
              positional :rest, variadic: true
            end
          end

          it 'uses default when no arguments' do
            expect(args.build).to eq(['default_a'])
          end

          it 'fills optional first, then variadic' do
            expect(args.build('val_a')).to eq(['val_a'])
          end

          it 'fills variadic with remaining arguments' do
            expect(args.build('val_a', 'r1', 'r2')).to eq(%w[val_a r1 r2])
          end
        end

        # Pattern: def foo(a, b = 'default', *rest)
        context 'required, optional, variadic (no post)' do
          let(:args) do
            described_class.define do
              positional :a, required: true
              positional :b, default: 'default_b'
              positional :rest, variadic: true
            end
          end

          it 'uses default for optional when only required provided' do
            expect(args.build('val_a')).to eq(%w[val_a default_b])
          end

          it 'fills optional when enough arguments' do
            expect(args.build('val_a', 'val_b')).to eq(%w[val_a val_b])
          end

          it 'fills variadic with remaining arguments' do
            expect(args.build('val_a', 'val_b', 'r1', 'r2')).to eq(%w[val_a val_b r1 r2])
          end

          it 'raises when required is missing' do
            expect { args.build }.to raise_error(ArgumentError, /a is required/)
          end
        end

        # Pattern: def foo(a, b = 'default', *middle, c)
        context 'required, optional, variadic, required' do
          let(:args) do
            described_class.define do
              positional :a, required: true
              positional :b, default: 'default_b'
              positional :middle, variadic: true
              positional :c, required: true
            end
          end

          it 'uses default for optional when minimum arguments provided' do
            # 2 args: a and c get values, b gets default, middle is empty
            expect(args.build('val_a', 'val_c')).to eq(%w[val_a default_b val_c])
          end

          it 'fills optional when enough arguments' do
            # 3 args: a, b, c all get values, middle is empty
            expect(args.build('val_a', 'val_b', 'val_c')).to eq(%w[val_a val_b val_c])
          end

          it 'fills variadic with middle arguments' do
            # 4+ args: middle gets the extras
            expect(args.build('val_a', 'val_b', 'm1', 'val_c')).to eq(%w[val_a val_b m1 val_c])
          end

          it 'fills variadic with multiple middle arguments' do
            expect(args.build('val_a', 'val_b', 'm1', 'm2', 'val_c')).to eq(%w[val_a val_b m1 m2 val_c])
          end

          it 'raises when not enough arguments for required params' do
            expect { args.build('only_one') }.to raise_error(ArgumentError, /a is required/)
          end
        end
      end

      # =======================================================================
      # Nil Handling for Positional Arguments
      # =======================================================================
      #
      # Nil has a special meaning: "this positional argument was not provided"
      # This is separate from the mapping rules above.
      #
      # =======================================================================

      context 'nil handling for positionals' do
        context 'with non-variadic positionals' do
          let(:args) do
            described_class.define do
              positional :arg1
              positional :arg2
            end
          end

          it 'nil means not provided - skipped in output' do
            expect(args.build(nil, 'value2')).to eq(['value2'])
          end

          it 'skips nil at end' do
            expect(args.build('value1', nil)).to eq(['value1'])
          end

          it 'skips all nils' do
            expect(args.build(nil, nil)).to eq([])
          end
        end

        context 'with variadic positional at end' do
          let(:args) do
            described_class.define do
              positional :first
              positional :rest, variadic: true
            end
          end

          it 'nil for first means not provided' do
            expect(args.build(nil, 'a', 'b')).to eq(%w[a b])
          end

          it 'rejects nil mixed within variadic values' do
            expect { args.build('first', 'a', nil, 'b') }.to raise_error(
              ArgumentError,
              /nil values are not allowed in variadic positional argument: rest/
            )
          end
        end

        context 'with variadic followed by required' do
          let(:args) do
            described_class.define do
              positional :sources, variadic: true, required: true
              positional :destination, required: true
            end
          end

          it 'rejects nil within variadic' do
            expect { args.build('s1', nil, 's2', 'dest') }.to raise_error(
              ArgumentError,
              /nil values are not allowed in variadic positional argument: sources/
            )
          end
        end
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

    context 'with allow_nil positional arguments' do
      context 'when required with allow_nil' do
        let(:args) do
          described_class.define do
            positional :tree_ish, required: true, allow_nil: true
            positional :paths, variadic: true, separator: '--'
          end
        end

        it 'accepts non-nil value and outputs it' do
          expect(args.build('HEAD', 'file.txt')).to eq(['HEAD', '--', 'file.txt'])
        end

        it 'accepts nil and omits it from output' do
          expect(args.build(nil, 'file.txt')).to eq(['--', 'file.txt'])
        end

        it 'consumes nil as the positional slot' do
          # nil takes the tree_ish slot, 'file.txt' goes to paths
          expect(args.build(nil, 'file.txt', 'file2.txt')).to eq(['--', 'file.txt', 'file2.txt'])
        end

        it 'works when only nil is provided with no paths' do
          expect(args.build(nil)).to eq([])
        end

        it 'works when tree_ish is provided with no paths' do
          expect(args.build('HEAD')).to eq(['HEAD'])
        end
      end

      context 'when not required with allow_nil (optional positional)' do
        let(:args) do
          described_class.define do
            positional :tree_ish, allow_nil: true
            positional :paths, variadic: true, separator: '--'
          end
        end

        it 'accepts non-nil value and outputs it' do
          expect(args.build('HEAD', 'file.txt')).to eq(['HEAD', '--', 'file.txt'])
        end

        it 'accepts nil and omits it from output' do
          expect(args.build(nil, 'file.txt')).to eq(['--', 'file.txt'])
        end

        it 'works with no arguments' do
          expect(args.build).to eq([])
        end
      end

      context 'allow_nil defaults to false for required positional' do
        let(:args) do
          described_class.define do
            positional :tree_ish, required: true
          end
        end

        it 'raises error when nil is passed' do
          expect { args.build(nil) }.to raise_error(ArgumentError, /tree_ish is required/)
        end
      end
    end

    context 'with required keyword options' do
      context 'with required: true on flag' do
        let(:args) do
          described_class.define do
            flag :force, required: true
          end
        end

        it 'raises ArgumentError when required option is not provided' do
          expect { args.build }.to raise_error(ArgumentError, /Required options not provided: :force/)
        end

        it 'accepts true value' do
          expect(args.build(force: true)).to eq(['--force'])
        end

        it 'accepts false value (key present but falsy)' do
          expect(args.build(force: false)).to eq([])
        end

        it 'accepts nil value (key present but nil)' do
          expect(args.build(force: nil)).to eq([])
        end
      end

      context 'with required: true on value' do
        let(:args) do
          described_class.define do
            value :message, required: true
          end
        end

        it 'raises ArgumentError when required option is not provided' do
          expect { args.build }.to raise_error(ArgumentError, /Required options not provided: :message/)
        end

        it 'accepts string value' do
          expect(args.build(message: 'hello')).to eq(['--message', 'hello'])
        end

        it 'accepts nil value (key present but nil)' do
          expect(args.build(message: nil)).to eq([])
        end
      end

      context 'with required: true on inline_value' do
        let(:args) do
          described_class.define do
            inline_value :upstream, required: true
          end
        end

        it 'raises ArgumentError when required option is not provided' do
          expect { args.build }.to raise_error(ArgumentError, /Required options not provided: :upstream/)
        end

        it 'accepts string value' do
          expect(args.build(upstream: 'origin/main')).to eq(['--upstream=origin/main'])
        end

        it 'accepts nil value (key present but nil)' do
          expect(args.build(upstream: nil)).to eq([])
        end
      end

      context 'with required: true on negatable_flag' do
        let(:args) do
          described_class.define do
            negatable_flag :verify, required: true
          end
        end

        it 'raises ArgumentError when required option is not provided' do
          expect { args.build }.to raise_error(ArgumentError, /Required options not provided: :verify/)
        end

        it 'accepts true value' do
          expect(args.build(verify: true)).to eq(['--verify'])
        end

        it 'accepts false value' do
          expect(args.build(verify: false)).to eq(['--no-verify'])
        end
      end

      context 'with required: true on flag_or_inline_value' do
        let(:args) do
          described_class.define do
            flag_or_inline_value :gpg_sign, required: true
          end
        end

        it 'raises ArgumentError when required option is not provided' do
          expect { args.build }.to raise_error(ArgumentError, /Required options not provided: :gpg_sign/)
        end

        it 'accepts true value' do
          expect(args.build(gpg_sign: true)).to eq(['--gpg-sign'])
        end

        it 'accepts string value' do
          expect(args.build(gpg_sign: 'KEYID')).to eq(['--gpg-sign=KEYID'])
        end
      end

      context 'with required: true on negatable_flag_or_inline_value' do
        let(:args) do
          described_class.define do
            negatable_flag_or_inline_value :gpg_sign, required: true
          end
        end

        it 'raises ArgumentError when required option is not provided' do
          expect { args.build }.to raise_error(ArgumentError, /Required options not provided: :gpg_sign/)
        end

        it 'accepts true value' do
          expect(args.build(gpg_sign: true)).to eq(['--gpg-sign'])
        end

        it 'accepts false value' do
          expect(args.build(gpg_sign: false)).to eq(['--no-gpg-sign'])
        end

        it 'accepts string value' do
          expect(args.build(gpg_sign: 'KEYID')).to eq(['--gpg-sign=KEYID'])
        end
      end

      context 'with required: true on custom' do
        let(:args) do
          described_class.define do
            custom :special, required: true do |value|
              value ? "--special=#{value}" : nil
            end
          end
        end

        it 'raises ArgumentError when required option is not provided' do
          expect { args.build }.to raise_error(ArgumentError, /Required options not provided: :special/)
        end

        it 'accepts value' do
          expect(args.build(special: 'foo')).to eq(['--special=foo'])
        end
      end

      context 'with multiple required options' do
        let(:args) do
          described_class.define do
            inline_value :upstream, required: true
            value :message, required: true
          end
        end

        it 'raises ArgumentError listing all missing required options' do
          expect { args.build }.to raise_error(ArgumentError, /Required options not provided: :upstream, :message/)
        end

        it 'raises ArgumentError when only some required options provided' do
          expect do
            args.build(upstream: 'origin/main')
          end.to raise_error(ArgumentError, /Required options not provided: :message/)
        end

        it 'succeeds when all required options provided' do
          expect(args.build(upstream: 'origin/main',
                            message: 'hello')).to eq(['--upstream=origin/main',
                                                      '--message', 'hello'])
        end
      end

      context 'with required option and aliases' do
        let(:args) do
          described_class.define do
            flag %i[force f], required: true
          end
        end

        it 'raises ArgumentError when required option is not provided' do
          expect { args.build }.to raise_error(ArgumentError, /Required options not provided: :force/)
        end

        it 'accepts primary name' do
          expect(args.build(force: true)).to eq(['--force'])
        end

        it 'accepts alias name' do
          expect(args.build(f: true)).to eq(['--force'])
        end
      end

      context 'with required: true and allow_nil: false on value' do
        let(:args) do
          described_class.define do
            value :message, required: true, allow_nil: false
          end
        end

        it 'raises ArgumentError when option is not provided' do
          expect { args.build }.to raise_error(ArgumentError, /Required options not provided: :message/)
        end

        it 'raises ArgumentError when value is nil' do
          expect { args.build(message: nil) }.to raise_error(ArgumentError, /Required options cannot be nil: :message/)
        end

        it 'accepts non-nil value' do
          expect(args.build(message: 'hello')).to eq(['--message', 'hello'])
        end
      end

      context 'with required: true and allow_nil: false on inline_value' do
        let(:args) do
          described_class.define do
            inline_value :upstream, required: true, allow_nil: false
          end
        end

        it 'raises ArgumentError when option is not provided' do
          expect { args.build }.to raise_error(ArgumentError, /Required options not provided: :upstream/)
        end

        it 'raises ArgumentError when value is nil' do
          expect do
            args.build(upstream: nil)
          end.to raise_error(ArgumentError, /Required options cannot be nil: :upstream/)
        end

        it 'accepts non-nil value' do
          expect(args.build(upstream: 'origin/main')).to eq(['--upstream=origin/main'])
        end
      end

      context 'with multiple required options and allow_nil: false' do
        let(:args) do
          described_class.define do
            inline_value :upstream, required: true, allow_nil: false
            value :message, required: true, allow_nil: false
          end
        end

        it 'raises ArgumentError listing all nil values' do
          expect { args.build(upstream: nil, message: nil) }.to raise_error(
            ArgumentError, /Required options cannot be nil: :upstream, :message/
          )
        end

        it 'raises ArgumentError for single nil value' do
          expect { args.build(upstream: 'origin/main', message: nil) }.to raise_error(
            ArgumentError, /Required options cannot be nil: :message/
          )
        end

        it 'succeeds when all values are non-nil' do
          expect(args.build(upstream: 'origin/main', message: 'hello')).to eq(
            ['--upstream=origin/main', '--message', 'hello']
          )
        end
      end

      context 'with required: true and default allow_nil (true)' do
        let(:args) do
          described_class.define do
            value :message, required: true
          end
        end

        it 'allows nil value when allow_nil defaults to true' do
          expect(args.build(message: nil)).to eq([])
        end
      end

      context 'with required: true and allow_nil: false on flag' do
        let(:args) do
          described_class.define do
            flag :force, required: true, allow_nil: false
          end
        end

        it 'raises ArgumentError when option is not provided' do
          expect { args.build }.to raise_error(ArgumentError, /Required options not provided: :force/)
        end

        it 'raises ArgumentError when value is nil' do
          expect { args.build(force: nil) }.to raise_error(ArgumentError, /Required options cannot be nil: :force/)
        end

        it 'accepts true value' do
          expect(args.build(force: true)).to eq(['--force'])
        end

        it 'accepts false value' do
          expect(args.build(force: false)).to eq([])
        end
      end

      context 'with required: true and allow_nil: false on negatable_flag' do
        let(:args) do
          described_class.define do
            negatable_flag :verify, required: true, allow_nil: false
          end
        end

        it 'raises ArgumentError when option is not provided' do
          expect { args.build }.to raise_error(ArgumentError, /Required options not provided: :verify/)
        end

        it 'raises ArgumentError when value is nil' do
          expect { args.build(verify: nil) }.to raise_error(ArgumentError, /Required options cannot be nil: :verify/)
        end

        it 'accepts true value' do
          expect(args.build(verify: true)).to eq(['--verify'])
        end

        it 'accepts false value' do
          expect(args.build(verify: false)).to eq(['--no-verify'])
        end
      end

      context 'with required: true and allow_nil: false on flag_or_inline_value' do
        let(:args) do
          described_class.define do
            flag_or_inline_value :gpg_sign, required: true, allow_nil: false
          end
        end

        it 'raises ArgumentError when option is not provided' do
          expect { args.build }.to raise_error(ArgumentError, /Required options not provided: :gpg_sign/)
        end

        it 'raises ArgumentError when value is nil' do
          expect do
            args.build(gpg_sign: nil)
          end.to raise_error(ArgumentError, /Required options cannot be nil: :gpg_sign/)
        end

        it 'accepts true value' do
          expect(args.build(gpg_sign: true)).to eq(['--gpg-sign'])
        end

        it 'accepts false value' do
          expect(args.build(gpg_sign: false)).to eq([])
        end

        it 'accepts string value' do
          expect(args.build(gpg_sign: 'KEYID')).to eq(['--gpg-sign=KEYID'])
        end
      end

      context 'with required: true and allow_nil: false on negatable_flag_or_inline_value' do
        let(:args) do
          described_class.define do
            negatable_flag_or_inline_value :gpg_sign, required: true, allow_nil: false
          end
        end

        it 'raises ArgumentError when option is not provided' do
          expect { args.build }.to raise_error(ArgumentError, /Required options not provided: :gpg_sign/)
        end

        it 'raises ArgumentError when value is nil' do
          expect do
            args.build(gpg_sign: nil)
          end.to raise_error(ArgumentError, /Required options cannot be nil: :gpg_sign/)
        end

        it 'accepts true value' do
          expect(args.build(gpg_sign: true)).to eq(['--gpg-sign'])
        end

        it 'accepts false value' do
          expect(args.build(gpg_sign: false)).to eq(['--no-gpg-sign'])
        end

        it 'accepts string value' do
          expect(args.build(gpg_sign: 'KEYID')).to eq(['--gpg-sign=KEYID'])
        end
      end

      context 'with required: true and allow_nil: false on custom' do
        let(:args) do
          described_class.define do
            custom :special, required: true, allow_nil: false do |value|
              value ? "--special=#{value}" : nil
            end
          end
        end

        it 'raises ArgumentError when option is not provided' do
          expect { args.build }.to raise_error(ArgumentError, /Required options not provided: :special/)
        end

        it 'raises ArgumentError when value is nil' do
          expect { args.build(special: nil) }.to raise_error(ArgumentError, /Required options cannot be nil: :special/)
        end

        it 'accepts non-nil value' do
          expect(args.build(special: 'foo')).to eq(['--special=foo'])
        end
      end
    end
  end
end
