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
          flag_option :force
        end
      end

      it 'outputs --flag when value is true' do
        expect(args.bind(force: true).to_ary).to eq(['--force'])
      end

      it 'outputs nothing when value is false' do
        expect(args.bind(force: false).to_ary).to eq([])
      end

      it 'outputs nothing when option is not provided' do
        expect(args.bind.to_ary).to eq([])
      end
    end

    context 'with value options' do
      let(:args) do
        described_class.define do
          value_option :branch
        end
      end

      it 'outputs --flag value as separate arguments' do
        expect(args.bind(branch: 'main').to_ary).to eq(['--branch', 'main'])
      end

      it 'outputs nothing when value is nil' do
        expect(args.bind(branch: nil).to_ary).to eq([])
      end

      it 'outputs nothing when option is not provided' do
        expect(args.bind.to_ary).to eq([])
      end
    end

    context 'with value repeatable: true' do
      let(:args) do
        described_class.define do
          value_option :config, repeatable: true
        end
      end

      it 'outputs --flag value for each array element' do
        expect(args.bind(config: %w[a b]).to_ary).to eq(['--config', 'a', '--config', 'b'])
      end

      it 'outputs --flag value for single value' do
        expect(args.bind(config: 'single').to_ary).to eq(['--config', 'single'])
      end

      it 'outputs nothing when value is nil' do
        expect(args.bind(config: nil).to_ary).to eq([])
      end

      it 'outputs nothing when value is empty array' do
        expect(args.bind(config: []).to_ary).to eq([])
      end

      it 'includes empty strings in array even with allow_empty: false (default)' do
        expect(args.bind(config: ['', 'value']).to_ary).to eq(['--config', '', '--config', 'value'])
      end

      it 'outputs nothing for single empty string with allow_empty: false (default)' do
        expect(args.bind(config: '').to_ary).to eq([])
      end

      context 'with allow_empty: true' do
        let(:args) do
          described_class.define do
            value_option :config, repeatable: true, allow_empty: true
          end
        end

        it 'includes empty strings in the array' do
          expect(args.bind(config: ['', 'value']).to_ary).to eq(['--config', '', '--config', 'value'])
        end

        it 'outputs flag with empty value for single empty string' do
          expect(args.bind(config: '').to_ary).to eq(['--config', ''])
        end
      end
    end

    context 'with static options' do
      let(:args) do
        described_class.define do
          literal '--no-progress'
        end
      end

      it 'always outputs the static flag' do
        expect(args.bind.to_ary).to eq(['--no-progress'])
      end

      it 'outputs static flag even with other options' do
        args_with_flag = described_class.define do
          literal '-p'
          flag_option :force
        end
        expect(args_with_flag.bind(force: true).to_ary).to eq(['-p', '--force'])
      end
    end

    context 'with custom options' do
      let(:args) do
        described_class.define do
          custom_option :dirty do |value|
            if value == true
              '--dirty'
            elsif value.is_a?(String)
              "--dirty=#{value}"
            end
          end
        end
      end

      it 'uses custom builder when value is true' do
        expect(args.bind(dirty: true).to_ary).to eq(['--dirty'])
      end

      it 'uses custom builder when value is a string' do
        expect(args.bind(dirty: '*').to_ary).to eq(['--dirty=*'])
      end

      it 'outputs nothing when custom builder returns nil' do
        expect(args.bind(dirty: false).to_ary).to eq([])
      end

      it 'outputs nothing when option is not provided' do
        expect(args.bind.to_ary).to eq([])
      end
    end

    context 'with execution_option options' do
      let(:args) do
        described_class.define do
          execution_option :object
          execution_option :path_limiter
        end
      end

      it 'does not output anything for execution_option options' do
        expect(args.bind(object: 'HEAD', path_limiter: 'src/').to_ary).to eq([])
      end

      it 'allows validation of execution_option presence' do
        # execution_option options are just for validation, not command building
        expect(args.bind.to_ary).to eq([])
      end
    end

    context 'with required positional arguments' do
      let(:args) do
        described_class.define do
          operand :repository, required: true
        end
      end

      it 'includes positional argument in output' do
        expect(args.bind('https://github.com/user/repo').to_ary).to eq(['https://github.com/user/repo'])
      end

      it 'raises error when required positional is missing' do
        expect { args.bind }.to raise_error(ArgumentError, /repository is required/)
      end

      it 'accepts empty string as valid value for required positional' do
        expect(args.bind('').to_ary).to eq([''])
      end
    end

    context 'with optional positional arguments' do
      let(:args) do
        described_class.define do
          operand :repository, required: true
          operand :directory
        end
      end

      it 'includes optional positional when provided' do
        expect(args.bind('https://example.com', 'my-dir').to_ary).to eq(%w[https://example.com my-dir])
      end

      it 'excludes optional positional when not provided' do
        expect(args.bind('https://example.com').to_ary).to eq(['https://example.com'])
      end
    end

    context 'with variadic positional arguments' do
      let(:args) do
        described_class.define do
          operand :paths, repeatable: true
        end
      end

      it 'accepts multiple positional arguments' do
        expect(args.bind('file1.rb', 'file2.rb').to_ary).to eq(%w[file1.rb file2.rb])
      end

      it 'accepts array of arguments' do
        expect(args.bind(%w[file1.rb file2.rb]).to_ary).to eq(%w[file1.rb file2.rb])
      end

      it 'outputs nothing when no paths provided' do
        expect(args.bind.to_ary).to eq([])
      end
    end

    context 'with required variadic positional arguments' do
      let(:args) do
        described_class.define do
          operand :paths, repeatable: true, required: true
        end
      end

      it 'accepts multiple positional arguments' do
        expect(args.bind('file1.rb', 'file2.rb').to_ary).to eq(%w[file1.rb file2.rb])
      end

      it 'accepts single positional argument' do
        expect(args.bind('file.rb').to_ary).to eq(['file.rb'])
      end

      it 'raises ArgumentError when no paths provided' do
        expect { args.bind }.to raise_error(ArgumentError, /at least one value is required for paths/)
      end

      it 'raises ArgumentError when empty array provided' do
        expect { args.bind([]) }.to raise_error(ArgumentError, /at least one value is required for paths/)
      end

      it 'accepts empty string as valid value in variadic positional' do
        expect(args.bind('', 'file.rb').to_ary).to eq(['', 'file.rb'])
      end
    end

    context 'with positional arguments with default values' do
      let(:args) do
        described_class.define do
          operand :paths, repeatable: true, default: ['.']
        end
      end

      it 'uses default when no value provided' do
        expect(args.bind.to_ary).to eq(['.'])
      end

      it 'overrides default when value provided' do
        expect(args.bind('src/').to_ary).to eq(['src/'])
      end
    end

    context 'with positional arguments with separator' do
      let(:args) do
        described_class.define do
          flag_option :force
          operand :paths, repeatable: true, separator: '--'
        end
      end

      it 'includes separator before positional arguments' do
        expect(args.bind('file.rb', force: true).to_ary).to eq(['--force', '--', 'file.rb'])
      end

      it 'omits separator when no positional arguments' do
        expect(args.bind(force: true).to_ary).to eq(['--force'])
      end
    end

    context 'with mixed positionals and keyword options' do
      let(:args) do
        described_class.define do
          flag_option :bare
          value_option :branch
          operand :repository, required: true
          operand :directory
        end
      end

      it 'outputs options before positionals' do
        result = args.bind('https://example.com', 'my-dir', bare: true, branch: 'main').to_ary
        expect(result).to eq(['--bare', '--branch', 'main', 'https://example.com', 'my-dir'])
      end
    end

    context 'with unexpected positional arguments' do
      context 'when no positionals are defined' do
        let(:args) do
          described_class.define do
            flag_option :force
          end
        end

        it 'raises ArgumentError for single unexpected positional' do
          expect { args.bind('unexpected') }.to raise_error(
            ArgumentError,
            /Unexpected positional arguments: unexpected/
          )
        end

        it 'raises ArgumentError for multiple unexpected positionals' do
          expect { args.bind('arg1', 'arg2', 'arg3') }.to raise_error(
            ArgumentError,
            /Unexpected positional arguments: arg1, arg2, arg3/
          )
        end

        it 'does not raise for nil positional arguments' do
          expect(args.bind(nil).to_ary).to eq([])
        end

        it 'does not raise for multiple nil positional arguments' do
          expect(args.bind(nil, nil).to_ary).to eq([])
        end
      end

      context 'when optional positional is defined' do
        let(:args) do
          described_class.define do
            operand :commit, required: false
          end
        end

        it 'accepts expected positional' do
          expect(args.bind('HEAD~1').to_ary).to eq(['HEAD~1'])
        end

        it 'accepts nil as the positional (treated as not provided)' do
          expect(args.bind(nil).to_ary).to eq([])
        end

        it 'raises ArgumentError for extra positional beyond defined ones' do
          expect { args.bind('HEAD~1', 'unexpected') }.to raise_error(
            ArgumentError,
            /Unexpected positional arguments: unexpected/
          )
        end

        it 'raises ArgumentError for multiple extra positionals' do
          expect { args.bind('HEAD~1', 'extra1', 'extra2') }.to raise_error(
            ArgumentError,
            /Unexpected positional arguments: extra1, extra2/
          )
        end

        it 'does not count trailing nils as unexpected' do
          expect(args.bind('HEAD~1', nil, nil).to_ary).to eq(['HEAD~1'])
        end

        it 'raises for non-nil unexpected arguments even with trailing nils' do
          expect { args.bind('HEAD~1', 'unexpected', nil) }.to raise_error(
            ArgumentError,
            /Unexpected positional arguments: unexpected/
          )
        end
      end

      context 'when required positional is defined' do
        let(:args) do
          described_class.define do
            operand :repository, required: true
          end
        end

        it 'accepts the required positional' do
          expect(args.bind('https://example.com').to_ary).to eq(['https://example.com'])
        end

        it 'raises ArgumentError for extra positional beyond required one' do
          expect { args.bind('https://example.com', 'unexpected') }.to raise_error(
            ArgumentError,
            /Unexpected positional arguments: unexpected/
          )
        end
      end

      context 'when multiple positionals are defined' do
        let(:args) do
          described_class.define do
            operand :repository, required: true
            operand :directory, required: false
          end
        end

        it 'accepts both defined positionals' do
          expect(args.bind('https://example.com', 'my-dir').to_ary).to eq(['https://example.com', 'my-dir'])
        end

        it 'accepts only the required positional' do
          expect(args.bind('https://example.com').to_ary).to eq(['https://example.com'])
        end

        it 'raises ArgumentError for extra positionals beyond defined ones' do
          expect { args.bind('https://example.com', 'my-dir', 'unexpected') }.to raise_error(
            ArgumentError,
            /Unexpected positional arguments: unexpected/
          )
        end

        it 'raises ArgumentError for multiple extra positionals' do
          expect { args.bind('repo', 'dir', 'extra1', 'extra2', 'extra3') }.to raise_error(
            ArgumentError,
            /Unexpected positional arguments: extra1, extra2, extra3/
          )
        end
      end

      context 'when variadic positional is defined' do
        let(:args) do
          described_class.define do
            operand :paths, repeatable: true
          end
        end

        it 'accepts any number of positionals (no unexpected arguments)' do
          expect(args.bind('file1.rb', 'file2.rb', 'file3.rb').to_ary).to eq(['file1.rb', 'file2.rb', 'file3.rb'])
        end

        it 'accepts many positionals without raising' do
          many_files = (1..10).map { |i| "file#{i}.rb" }
          expect(args.bind(*many_files).to_ary).to eq(many_files)
        end
      end

      context 'when variadic positional comes after regular positional' do
        let(:args) do
          described_class.define do
            operand :command, required: true
            operand :args, repeatable: true, separator: '--'
          end
        end

        it 'accepts command with variadic args (no unexpected arguments)' do
          expect(args.bind('run', '--verbose', '--debug').to_ary).to eq(['run', '--', '--verbose', '--debug'])
        end

        it 'accepts just the required command' do
          expect(args.bind('run').to_ary).to eq(['run'])
        end
      end

      context 'edge case: empty strings vs nil for positionals' do
        let(:args) do
          described_class.define do
            operand :commit, required: false
          end
        end

        it 'passes through empty string as a valid positional value' do
          expect(args.bind('').to_ary).to eq([''])
        end

        it 'treats nil as not provided' do
          expect(args.bind(nil).to_ary).to eq([])
        end

        it 'raises for unexpected positional after empty string' do
          expect { args.bind('', 'unexpected') }.to raise_error(
            ArgumentError,
            /Unexpected positional arguments: unexpected/
          )
        end

        it 'does not count nil as unexpected' do
          expect { args.bind('valid', nil) }.to_not raise_error
          expect(args.bind('valid', nil).to_ary).to eq(['valid'])
        end
      end

      context 'edge case: empty arrays for variadic positionals' do
        let(:args) do
          described_class.define do
            operand :paths, repeatable: true
          end
        end

        it 'treats empty array as not provided (equivalent to nil)' do
          expect(args.bind([]).to_ary).to eq([])
        end

        it 'treats nil as not provided' do
          expect(args.bind(nil).to_ary).to eq([])
        end

        it 'accepts non-empty array' do
          expect(args.bind(['file1.rb', 'file2.rb']).to_ary).to eq(['file1.rb', 'file2.rb'])
        end

        context 'with separator' do
          let(:args) do
            described_class.define do
              flag_option :force
              operand :paths, repeatable: true, separator: '--'
            end
          end

          it 'omits separator when empty array provided' do
            expect(args.bind([], force: true).to_ary).to eq(['--force'])
          end

          it 'omits separator when nil provided' do
            expect(args.bind(nil, force: true).to_ary).to eq(['--force'])
          end

          it 'includes separator when non-empty array provided' do
            expect(args.bind(['file.rb'], force: true).to_ary).to eq(['--force', '--', 'file.rb'])
          end
        end

        context 'with default value' do
          let(:args) do
            described_class.define do
              operand :paths, repeatable: true, default: ['.']
            end
          end

          it 'uses default when empty array provided' do
            expect(args.bind([]).to_ary).to eq(['.'])
          end

          it 'uses default when nil provided' do
            expect(args.bind(nil).to_ary).to eq(['.'])
          end

          it 'overrides default when non-empty array provided' do
            expect(args.bind(['src/']).to_ary).to eq(['src/'])
          end

          it 'accepts value identical to the default (no false positive unexpected)' do
            # This is a regression test: passing a value that equals the default
            # should not be treated as unexpected
            expect(args.bind(['.']).to_ary).to eq(['.'])
            expect(args.bind('.').to_ary).to eq(['.'])
          end
        end
      end

      context 'multiple variadic positionals (rejected at definition time)' do
        it 'raises ArgumentError when defining a second variadic positional' do
          expect do
            described_class.define do
              operand :sources, repeatable: true
              operand :middle
              operand :paths, repeatable: true
            end
          end.to raise_error(
            ArgumentError,
            /only one repeatable operand is allowed.*:sources is already repeatable.*cannot add :paths/
          )
        end
      end

      context 'with mixed options and unexpected positionals' do
        let(:args) do
          described_class.define do
            flag_option :force
            operand :path, required: false
          end
        end

        it 'raises for unexpected positional even when options are present' do
          expect { args.bind('expected', 'unexpected', force: true) }.to raise_error(
            ArgumentError,
            /Unexpected positional arguments: unexpected/
          )
        end

        it 'allows expected positional with options' do
          expect(args.bind('expected', force: true).to_ary).to eq(['--force', 'expected'])
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
              operand :arg1, required: true
            end
          end

          it 'maps the argument correctly' do
            expect(args.bind('value1').to_ary).to eq(['value1'])
          end

          it 'raises when not provided' do
            expect { args.bind }.to raise_error(ArgumentError, /arg1 is required/)
          end
        end

        # Pattern: def foo(arg1 = 'default')
        context 'single optional positional with default' do
          let(:args) do
            described_class.define do
              operand :arg1, default: 'default_value'
            end
          end

          it 'uses provided value' do
            expect(args.bind('provided').to_ary).to eq(['provided'])
          end

          it 'uses default when not provided' do
            expect(args.bind.to_ary).to eq(['default_value'])
          end
        end

        # Pattern: def foo(arg1, arg2)
        context 'two required positionals' do
          let(:args) do
            described_class.define do
              operand :arg1, required: true
              operand :arg2, required: true
            end
          end

          it 'maps arguments in order' do
            expect(args.bind('value1', 'value2').to_ary).to eq(%w[value1 value2])
          end

          it 'raises when second is missing' do
            expect { args.bind('value1') }.to raise_error(ArgumentError, /arg2 is required/)
          end
        end

        # Pattern: def foo(arg1, arg2 = 'default')
        context 'required followed by optional' do
          let(:args) do
            described_class.define do
              operand :arg1, required: true
              operand :arg2, default: 'default2'
            end
          end

          it 'maps both when both provided' do
            expect(args.bind('val1', 'val2').to_ary).to eq(%w[val1 val2])
          end

          it 'uses default for second when only first provided' do
            expect(args.bind('val1').to_ary).to eq(%w[val1 default2])
          end
        end

        # Pattern: def foo(arg1 = 'default', arg2)
        # Ruby fills required args first (from the end), then optional from remaining
        context 'optional followed by required' do
          let(:args) do
            described_class.define do
              operand :arg1, default: 'default1'
              operand :arg2, required: true
            end
          end

          it 'maps both when both provided' do
            expect(args.bind('val1', 'val2').to_ary).to eq(%w[val1 val2])
          end

          it 'uses default for first when only one arg provided (Ruby semantics)' do
            # Ruby: def foo(a = 1, b); foo(2) => a=1, b=2
            expect(args.bind('val2').to_ary).to eq(%w[default1 val2])
          end

          it 'raises when no arguments provided' do
            expect { args.bind }.to raise_error(ArgumentError, /arg2 is required/)
          end
        end

        # Pattern: def foo(arg1 = 'default1', arg2 = 'default2', arg3)
        context 'two optionals followed by required' do
          let(:args) do
            described_class.define do
              operand :arg1, default: 'default1'
              operand :arg2, default: 'default2'
              operand :arg3, required: true
            end
          end

          it 'maps all when all provided' do
            expect(args.bind('val1', 'val2', 'val3').to_ary).to eq(%w[val1 val2 val3])
          end

          it 'uses both defaults when only required provided' do
            expect(args.bind('val3').to_ary).to eq(%w[default1 default2 val3])
          end

          it 'fills first optional when two args provided' do
            # Ruby: def foo(a = 1, b = 2, c); foo('x', 'y') => a='x', b=2, c='y'
            expect(args.bind('val1', 'val3').to_ary).to eq(%w[val1 default2 val3])
          end
        end

        # Pattern: def foo(arg1, arg2 = 'default2', arg3)
        context 'required, optional, required' do
          let(:args) do
            described_class.define do
              operand :arg1, required: true
              operand :arg2, default: 'default2'
              operand :arg3, required: true
            end
          end

          it 'maps all when all provided' do
            expect(args.bind('val1', 'val2', 'val3').to_ary).to eq(%w[val1 val2 val3])
          end

          it 'uses default for middle when only two args provided' do
            # Ruby: def foo(a, b = 2, c); foo('x', 'y') => a='x', b=2, c='y'
            expect(args.bind('val1', 'val3').to_ary).to eq(%w[val1 default2 val3])
          end

          it 'raises when only one argument provided' do
            expect { args.bind('val1') }.to raise_error(ArgumentError, /is required/)
          end
        end

        # Pattern: def foo(*args)
        context 'variadic only' do
          let(:args) do
            described_class.define do
              operand :paths, repeatable: true
            end
          end

          it 'accepts no arguments' do
            expect(args.bind.to_ary).to eq([])
          end

          it 'accepts one argument' do
            expect(args.bind('file1').to_ary).to eq(['file1'])
          end

          it 'accepts many arguments' do
            expect(args.bind('f1', 'f2', 'f3', 'f4').to_ary).to eq(%w[f1 f2 f3 f4])
          end
        end

        # Pattern: def foo(arg1, *rest)
        context 'required followed by variadic' do
          let(:args) do
            described_class.define do
              operand :command, required: true
              operand :args, repeatable: true
            end
          end

          it 'maps first to required, rest to variadic' do
            expect(args.bind('cmd', 'arg1', 'arg2').to_ary).to eq(%w[cmd arg1 arg2])
          end

          it 'maps only required when variadic is empty' do
            expect(args.bind('cmd').to_ary).to eq(['cmd'])
          end

          it 'raises when required is missing' do
            expect { args.bind }.to raise_error(ArgumentError, /command is required/)
          end
        end

        # Pattern: def foo(*sources, destination) - the git mv pattern!
        context 'variadic followed by required (git mv pattern)' do
          let(:args) do
            described_class.define do
              operand :sources, repeatable: true, required: true
              operand :destination, required: true
            end
          end

          it 'maps last to destination, rest to sources' do
            expect(args.bind('src1', 'src2', 'dest').to_ary).to eq(%w[src1 src2 dest])
          end

          it 'handles single source and destination' do
            expect(args.bind('src', 'dest').to_ary).to eq(%w[src dest])
          end

          it 'handles many sources' do
            expect(args.bind('s1', 's2', 's3', 's4', 'dest').to_ary).to eq(%w[s1 s2 s3 s4 dest])
          end

          it 'raises when only destination provided (sources required)' do
            expect { args.bind('dest') }.to raise_error(
              ArgumentError,
              /at least one value is required for sources/
            )
          end

          it 'raises when nothing provided' do
            expect { args.bind }.to raise_error(ArgumentError)
          end
        end

        # Pattern: def foo(first, *middle, last)
        context 'required, variadic, required' do
          let(:args) do
            described_class.define do
              operand :first, required: true
              operand :middle, repeatable: true
              operand :last, required: true
            end
          end

          it 'maps first and last, middle gets the rest' do
            expect(args.bind('a', 'b', 'c', 'd', 'e').to_ary).to eq(%w[a b c d e])
          end

          it 'handles empty middle' do
            expect(args.bind('first', 'last').to_ary).to eq(%w[first last])
          end

          it 'handles single middle value' do
            expect(args.bind('first', 'mid', 'last').to_ary).to eq(%w[first mid last])
          end

          it 'raises when only one argument (need at least 2)' do
            # With Ruby-like allocation, post-variadic required are reserved first,
            # so pre-variadic required fails when not enough values remain
            expect { args.bind('only') }.to raise_error(ArgumentError, /first is required/)
          end
        end

        # Pattern: def foo(a, b, *middle, c, d)
        context 'two required, variadic, two required' do
          let(:args) do
            described_class.define do
              operand :a, required: true
              operand :b, required: true
              operand :middle, repeatable: true
              operand :c, required: true
              operand :d, required: true
            end
          end

          it 'maps with empty middle' do
            expect(args.bind('1', '2', '3', '4').to_ary).to eq(%w[1 2 3 4])
          end

          it 'maps with one middle value' do
            expect(args.bind('1', '2', 'm1', '3', '4').to_ary).to eq(%w[1 2 m1 3 4])
          end

          it 'maps with multiple middle values' do
            expect(args.bind('1', '2', 'm1', 'm2', 'm3', '3', '4').to_ary).to eq(%w[1 2 m1 m2 m3 3 4])
          end

          it 'raises when not enough arguments' do
            # With Ruby-like allocation, post-variadic required are reserved first,
            # so pre-variadic required fails when not enough values remain
            expect { args.bind('1', '2', '3') }.to raise_error(ArgumentError, /b is required/)
          end
        end

        # Pattern: def foo(a, *middle, c = 'default')
        context 'required, variadic, optional' do
          let(:args) do
            described_class.define do
              operand :a, required: true
              operand :middle, repeatable: true
              operand :c, default: 'default_c'
            end
          end

          it 'uses default for c when only a provided' do
            expect(args.bind('val_a').to_ary).to eq(%w[val_a default_c])
          end

          it 'maps a and c, middle empty' do
            expect(args.bind('val_a', 'val_c').to_ary).to eq(%w[val_a val_c])
          end

          it 'maps all three parts' do
            expect(args.bind('val_a', 'm1', 'm2', 'val_c').to_ary).to eq(%w[val_a m1 m2 val_c])
          end
        end

        # Pattern: def foo(a = 'default', *middle, b)
        # Now follows Ruby semantics: optional before variadic with required after
        context 'optional, variadic, required (Ruby semantics)' do
          let(:args) do
            described_class.define do
              operand :a, default: 'default_a'
              operand :middle, repeatable: true
              operand :b, required: true
            end
          end

          # Ruby: foo('x') => a='default_a', middle=[], b='x'
          it 'follows Ruby semantics - optional gets default when only required is provided' do
            expect(args.bind('only_one').to_ary).to eq(%w[default_a only_one])
          end

          it 'fills optional when enough arguments provided' do
            expect(args.bind('val_a', 'val_b').to_ary).to eq(%w[val_a val_b])
          end

          it 'fills variadic with middle values' do
            expect(args.bind('val_a', 'm1', 'm2', 'val_b').to_ary).to eq(%w[val_a m1 m2 val_b])
          end
        end

        # Pattern: def foo(a = 'default', *rest)
        context 'optional followed by variadic (no post)' do
          let(:args) do
            described_class.define do
              operand :a, default: 'default_a'
              operand :rest, repeatable: true
            end
          end

          it 'uses default when no arguments' do
            expect(args.bind.to_ary).to eq(['default_a'])
          end

          it 'fills optional first, then variadic' do
            expect(args.bind('val_a').to_ary).to eq(['val_a'])
          end

          it 'fills variadic with remaining arguments' do
            expect(args.bind('val_a', 'r1', 'r2').to_ary).to eq(%w[val_a r1 r2])
          end
        end

        # Pattern: def foo(a, b = 'default', *rest)
        context 'required, optional, variadic (no post)' do
          let(:args) do
            described_class.define do
              operand :a, required: true
              operand :b, default: 'default_b'
              operand :rest, repeatable: true
            end
          end

          it 'uses default for optional when only required provided' do
            expect(args.bind('val_a').to_ary).to eq(%w[val_a default_b])
          end

          it 'fills optional when enough arguments' do
            expect(args.bind('val_a', 'val_b').to_ary).to eq(%w[val_a val_b])
          end

          it 'fills variadic with remaining arguments' do
            expect(args.bind('val_a', 'val_b', 'r1', 'r2').to_ary).to eq(%w[val_a val_b r1 r2])
          end

          it 'raises when required is missing' do
            expect { args.bind }.to raise_error(ArgumentError, /a is required/)
          end
        end

        # Pattern: def foo(a, b = 'default', *middle, c)
        context 'required, optional, variadic, required' do
          let(:args) do
            described_class.define do
              operand :a, required: true
              operand :b, default: 'default_b'
              operand :middle, repeatable: true
              operand :c, required: true
            end
          end

          it 'uses default for optional when minimum arguments provided' do
            # 2 args: a and c get values, b gets default, middle is empty
            expect(args.bind('val_a', 'val_c').to_ary).to eq(%w[val_a default_b val_c])
          end

          it 'fills optional when enough arguments' do
            # 3 args: a, b, c all get values, middle is empty
            expect(args.bind('val_a', 'val_b', 'val_c').to_ary).to eq(%w[val_a val_b val_c])
          end

          it 'fills variadic with middle arguments' do
            # 4+ args: middle gets the extras
            expect(args.bind('val_a', 'val_b', 'm1', 'val_c').to_ary).to eq(%w[val_a val_b m1 val_c])
          end

          it 'fills variadic with multiple middle arguments' do
            expect(args.bind('val_a', 'val_b', 'm1', 'm2', 'val_c').to_ary).to eq(%w[val_a val_b m1 m2 val_c])
          end

          it 'raises when not enough arguments for required params' do
            expect { args.bind('only_one') }.to raise_error(ArgumentError, /a is required/)
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
              operand :arg1
              operand :arg2
            end
          end

          it 'nil means not provided - skipped in output' do
            expect(args.bind(nil, 'value2').to_ary).to eq(['value2'])
          end

          it 'skips nil at end' do
            expect(args.bind('value1', nil).to_ary).to eq(['value1'])
          end

          it 'skips all nils' do
            expect(args.bind(nil, nil).to_ary).to eq([])
          end
        end

        context 'with variadic positional at end' do
          let(:args) do
            described_class.define do
              operand :first
              operand :rest, repeatable: true
            end
          end

          it 'nil for first means not provided' do
            expect(args.bind(nil, 'a', 'b').to_ary).to eq(%w[a b])
          end

          it 'rejects nil mixed within variadic values' do
            expect { args.bind('first', 'a', nil, 'b') }.to raise_error(
              ArgumentError,
              /nil values are not allowed in repeatable positional argument: rest/
            )
          end
        end

        context 'with variadic followed by required' do
          let(:args) do
            described_class.define do
              operand :sources, repeatable: true, required: true
              operand :destination, required: true
            end
          end

          it 'rejects nil within variadic' do
            expect { args.bind('s1', nil, 's2', 'dest') }.to raise_error(
              ArgumentError,
              /nil values are not allowed in repeatable positional argument: sources/
            )
          end
        end
      end
    end

    context 'with custom flag names' do
      let(:args) do
        described_class.define do
          flag_option :recursive, as: '-r'
          value_option :skip, as: '--skip-worktree'
        end
      end

      it 'uses custom flag name for flags' do
        expect(args.bind(recursive: true).to_ary).to eq(['-r'])
      end

      it 'uses custom flag name for valued options' do
        expect(args.bind(skip: 'file.txt').to_ary).to eq(['--skip-worktree', 'file.txt'])
      end
    end

    context 'with unsupported options' do
      let(:args) do
        described_class.define do
          flag_option :force
        end
      end

      it 'raises ArgumentError for unknown options' do
        expect { args.bind(invalid: true) }.to(
          raise_error(ArgumentError, /Unsupported options: :invalid/)
        )
      end

      it 'raises ArgumentError listing all unknown options' do
        expect { args.bind(foo: true, bar: true) }.to(
          raise_error(ArgumentError, /Unsupported options: :foo, :bar/)
        )
      end
    end

    context 'with custom options returning arrays' do
      let(:args) do
        described_class.define do
          custom_option(:depth) { |v| ['--depth', v.to_i] }
        end
      end

      it 'concatenates array results' do
        expect(args.bind(depth: 5).to_ary).to eq(['--depth', 5])
      end

      it 'handles string values converted to integers' do
        expect(args.bind(depth: '10').to_ary).to eq(['--depth', 10])
      end
    end

    context 'with validator on flag' do
      let(:args) do
        described_class.define do
          flag_option :force, validator: ->(v) { [true, false].include?(v) }
        end
      end

      it 'allows valid true value' do
        expect(args.bind(force: true).to_ary).to eq(['--force'])
      end

      it 'allows valid false value' do
        expect(args.bind(force: false).to_ary).to eq([])
      end

      it 'raises ArgumentError for invalid values' do
        expect { args.bind(force: 'yes') }.to(
          raise_error(ArgumentError, /Invalid value for option: force/)
        )
      end
    end

    context 'with option aliases' do
      let(:args) do
        described_class.define do
          value_option %i[origin remote]
        end
      end

      it 'accepts the primary key' do
        expect(args.bind(origin: 'upstream').to_ary).to eq(['--origin', 'upstream'])
      end

      it 'accepts the alias key' do
        expect(args.bind(remote: 'upstream').to_ary).to eq(['--origin', 'upstream'])
      end

      it 'uses first key for flag name by default' do
        args = described_class.define { flag_option %i[verbose v] }
        expect(args.bind(verbose: true).to_ary).to eq(['--verbose'])
        expect(args.bind(v: true).to_ary).to eq(['--verbose'])
      end

      it 'allows custom flag with aliases' do
        args = described_class.define { flag_option %i[recursive r], as: '-R' }
        expect(args.bind(recursive: true).to_ary).to eq(['-R'])
        expect(args.bind(r: true).to_ary).to eq(['-R'])
      end

      it 'raises error if both alias and primary provided' do
        expect { args.bind(origin: 'one', remote: 'two') }.to(
          raise_error(ArgumentError, /Conflicting options.*origin.*remote/)
        )
      end
    end

    context 'with variadic positional arguments containing nil values' do
      let(:args) do
        described_class.define do
          operand :paths, repeatable: true
        end
      end

      it 'rejects nil values with clear ArgumentError' do
        expect { args.bind('file1.rb', nil, 'file2.rb') }.to(
          raise_error(ArgumentError, /nil values are not allowed in repeatable positional argument: paths/)
        )
      end

      it 'rejects array containing nil values' do
        expect { args.bind(['file1.rb', nil, 'file2.rb']) }.to(
          raise_error(ArgumentError, /nil values are not allowed in repeatable positional argument: paths/)
        )
      end

      it 'accepts all valid values' do
        expect(args.bind('file1.rb', 'file2.rb').to_ary).to eq(%w[file1.rb file2.rb])
      end
    end

    context 'with as: parameter arrays' do
      it 'supports arrays for flag type' do
        args = described_class.define do
          flag_option :amend, as: ['--amend', '--no-edit']
        end
        expect(args.bind(amend: true).to_ary).to eq(['--amend', '--no-edit'])
      end

      it 'rejects arrays for flag negatable: true type' do
        expect do
          described_class.define do
            flag_option :verbose, negatable: true, as: ['--verbose', '--all']
          end
        end.to raise_error(ArgumentError, /arrays for as: parameter cannot be combined with negatable: true/)
      end

      it 'rejects arrays for value type' do
        expect do
          described_class.define do
            value_option :branch, as: ['--branch', '--set-upstream']
          end
        end.to raise_error(ArgumentError, /arrays for as: parameter are only supported for flag types/)
      end

      it 'rejects arrays for value inline: true type' do
        expect do
          described_class.define do
            value_option :message, inline: true, as: ['--message', '--edit']
          end
        end.to raise_error(ArgumentError, /arrays for as: parameter are only supported for flag types/)
      end

      it 'rejects arrays for flag_or_value inline: true type' do
        expect do
          described_class.define do
            flag_or_value_option :gpg_sign, inline: true, as: ['--gpg-sign', '--verify']
          end
        end.to raise_error(ArgumentError, /arrays for as: parameter are only supported for flag types/)
      end

      it 'rejects arrays for flag_or_value negatable: true, inline: true type' do
        expect do
          described_class.define do
            flag_or_value_option :sign, negatable: true, inline: true, as: ['--sign', '--verify']
          end
        end.to raise_error(ArgumentError, /arrays for as: parameter are only supported for flag types/)
      end
    end

    context 'with allow_empty parameter' do
      context 'for value types' do
        let(:args_without_allow_empty) do
          described_class.define do
            value_option :message
          end
        end

        let(:args_with_allow_empty) do
          described_class.define do
            value_option :message, allow_empty: true
          end
        end

        it 'skips empty string by default' do
          expect(args_without_allow_empty.bind(message: '').to_ary).to eq([])
        end

        it 'includes empty string when allow_empty is true' do
          expect(args_with_allow_empty.bind(message: '').to_ary).to eq(['--message', ''])
        end

        it 'includes non-empty string regardless of allow_empty' do
          expect(args_without_allow_empty.bind(message: 'hello').to_ary).to eq(['--message', 'hello'])
          expect(args_with_allow_empty.bind(message: 'hello').to_ary).to eq(['--message', 'hello'])
        end
      end

      context 'for value inline: true types' do
        let(:args_without_allow_empty) do
          described_class.define do
            value_option :abbrev, inline: true
          end
        end

        let(:args_with_allow_empty) do
          described_class.define do
            value_option :abbrev, inline: true, allow_empty: true
          end
        end

        it 'skips empty string by default' do
          expect(args_without_allow_empty.bind(abbrev: '').to_ary).to eq([])
        end

        it 'includes empty string when allow_empty is true' do
          expect(args_with_allow_empty.bind(abbrev: '').to_ary).to eq(['--abbrev='])
        end

        it 'includes non-empty string regardless of allow_empty' do
          expect(args_without_allow_empty.bind(abbrev: '7').to_ary).to eq(['--abbrev=7'])
          expect(args_with_allow_empty.bind(abbrev: '7').to_ary).to eq(['--abbrev=7'])
        end
      end
    end

    context 'with type: parameter for validation' do
      context 'with String type' do
        let(:args) do
          described_class.define do
            value_option :message, type: String
          end
        end

        it 'accepts String values' do
          expect(args.bind(message: 'hello').to_ary).to eq(['--message', 'hello'])
        end

        it 'accepts nil values (skips validation and output)' do
          expect(args.bind(message: nil).to_ary).to eq([])
        end

        it 'raises descriptive error for non-String values' do
          expect { args.bind(message: 123) }.to raise_error(
            ArgumentError,
            /The :message option must be a String, but was a Integer/
          )
        end
      end

      context 'with Integer type' do
        let(:args) do
          described_class.define do
            value_option :depth, type: Integer
          end
        end

        it 'accepts Integer values' do
          expect(args.bind(depth: 42).to_ary).to eq(['--depth', '42'])
        end

        it 'accepts nil values (skips validation and output)' do
          expect(args.bind(depth: nil).to_ary).to eq([])
        end

        it 'raises descriptive error for non-Integer values' do
          expect { args.bind(depth: 'not a number') }.to raise_error(
            ArgumentError,
            /The :depth option must be a Integer, but was a String/
          )
        end
      end

      context 'with multiple options having type validation' do
        let(:args) do
          described_class.define do
            value_option :message, type: String
            value_option :depth, type: Integer
          end
        end

        it 'validates all typed options independently' do
          expect(args.bind(message: 'hello', depth: 5).to_ary).to eq(['--message', 'hello', '--depth', '5'])
        end

        it 'raises error for first invalid option encountered' do
          expect { args.bind(message: 123, depth: 'invalid') }.to raise_error(
            ArgumentError,
            /The :message option must be a String, but was a Integer/
          )
        end
      end

      context 'with multiple allowed types' do
        let(:args) do
          described_class.define do
            value_option :timeout, type: [Integer, Float]
          end
        end

        it 'accepts first type' do
          expect(args.bind(timeout: 30).to_ary).to eq(['--timeout', '30'])
        end

        it 'accepts second type' do
          expect(args.bind(timeout: 30.5).to_ary).to eq(['--timeout', '30.5'])
        end

        it 'raises descriptive error for invalid type' do
          expect { args.bind(timeout: 'thirty') }.to raise_error(
            ArgumentError,
            /The :timeout option must be a Integer or Float, but was a String/
          )
        end
      end

      context 'when type: and validator: are both specified' do
        it 'raises an error at definition time' do
          expect do
            described_class.define do
              flag_option :single_branch, negatable: true, type: String, validator: ->(v) { [true, false].include?(v) }
            end
          end.to raise_error(ArgumentError, /cannot specify both type: and validator: for :single_branch/)
        end
      end
    end

    context 'with conflicts method' do
      context 'with two conflicting options' do
        let(:args) do
          described_class.define do
            flag_option :patch
            flag_option :stat
            conflicts :patch, :stat
          end
        end

        it 'allows using neither option' do
          expect(args.bind.to_ary).to eq([])
        end

        it 'allows using only first option' do
          expect(args.bind(patch: true).to_ary).to eq(['--patch'])
        end

        it 'allows using only second option' do
          expect(args.bind(stat: true).to_ary).to eq(['--stat'])
        end

        it 'raises error when both options are provided' do
          expect { args.bind(patch: true, stat: true) }.to raise_error(
            ArgumentError,
            /cannot specify :patch and :stat/
          )
        end

        it 'allows false values (does not trigger conflict)' do
          expect(args.bind(patch: true, stat: false).to_ary).to eq(['--patch'])
          expect(args.bind(patch: false, stat: true).to_ary).to eq(['--stat'])
        end

        it 'allows nil values (does not trigger conflict)' do
          expect(args.bind(patch: true, stat: nil).to_ary).to eq(['--patch'])
        end
      end

      context 'with multiple conflicting options' do
        let(:args) do
          described_class.define do
            flag_option :patch
            flag_option :stat
            flag_option :summary
            conflicts :patch, :stat, :summary
          end
        end

        it 'raises error when any two options are provided' do
          expect { args.bind(patch: true, stat: true) }.to raise_error(
            ArgumentError,
            /cannot specify :patch and :stat/
          )
          expect { args.bind(patch: true, summary: true) }.to raise_error(
            ArgumentError,
            /cannot specify :patch and :summary/
          )
          expect { args.bind(stat: true, summary: true) }.to raise_error(
            ArgumentError,
            /cannot specify :stat and :summary/
          )
        end

        it 'raises error when all three options are provided' do
          expect { args.bind(patch: true, stat: true, summary: true) }.to raise_error(
            ArgumentError,
            /cannot specify :patch and :stat/
          )
        end
      end

      context 'with multiple conflict groups' do
        let(:args) do
          described_class.define do
            flag_option :patch
            flag_option :stat
            flag_option :quiet
            flag_option :verbose
            conflicts :patch, :stat
            conflicts :quiet, :verbose
          end
        end

        it 'validates each conflict group independently' do
          # Allowed: patch with verbose
          expect(args.bind(patch: true, verbose: true).to_ary).to eq(['--patch', '--verbose'])
          # Allowed: stat with quiet
          expect(args.bind(stat: true, quiet: true).to_ary).to eq(['--stat', '--quiet'])
        end

        it 'raises error when first conflict group violated' do
          expect { args.bind(patch: true, stat: true, verbose: true) }.to raise_error(
            ArgumentError,
            /cannot specify :patch and :stat/
          )
        end

        it 'raises error when second conflict group violated' do
          expect { args.bind(patch: true, quiet: true, verbose: true) }.to raise_error(
            ArgumentError,
            /cannot specify :quiet and :verbose/
          )
        end
      end

      context 'with conflicts on valued options' do
        let(:args) do
          described_class.define do
            value_option :branch
            value_option :tag
            conflicts :branch, :tag
          end
        end

        it 'raises error when both valued options provided' do
          expect { args.bind(branch: 'main', tag: 'v1.0') }.to raise_error(
            ArgumentError,
            /cannot specify :branch and :tag/
          )
        end

        it 'allows one valued option' do
          expect(args.bind(branch: 'main').to_ary).to eq(['--branch', 'main'])
          expect(args.bind(tag: 'v1.0').to_ary).to eq(['--tag', 'v1.0'])
        end
      end

      context 'with conflicts on mixed option types' do
        let(:args) do
          described_class.define do
            flag_option :all
            value_option :since
            conflicts :all, :since
          end
        end

        it 'raises error when flag and value both provided' do
          expect { args.bind(all: true, since: '2020-01-01') }.to raise_error(
            ArgumentError,
            /cannot specify :all and :since/
          )
        end

        it 'allows either option alone' do
          expect(args.bind(all: true).to_ary).to eq(['--all'])
          expect(args.bind(since: '2020-01-01').to_ary).to eq(['--since', '2020-01-01'])
        end
      end
    end

    context 'with allow_nil positional arguments' do
      context 'when required with allow_nil' do
        let(:args) do
          described_class.define do
            operand :tree_ish, required: true, allow_nil: true
            operand :paths, repeatable: true, separator: '--'
          end
        end

        it 'accepts non-nil value and outputs it' do
          expect(args.bind('HEAD', 'file.txt').to_ary).to eq(['HEAD', '--', 'file.txt'])
        end

        it 'accepts nil and omits it from output' do
          expect(args.bind(nil, 'file.txt').to_ary).to eq(['--', 'file.txt'])
        end

        it 'consumes nil as the positional slot' do
          # nil takes the tree_ish slot, 'file.txt' goes to paths
          expect(args.bind(nil, 'file.txt', 'file2.txt').to_ary).to eq(['--', 'file.txt', 'file2.txt'])
        end

        it 'works when only nil is provided with no paths' do
          expect(args.bind(nil).to_ary).to eq([])
        end

        it 'works when tree_ish is provided with no paths' do
          expect(args.bind('HEAD').to_ary).to eq(['HEAD'])
        end
      end

      context 'when not required with allow_nil (optional positional)' do
        let(:args) do
          described_class.define do
            operand :tree_ish, allow_nil: true
            operand :paths, repeatable: true, separator: '--'
          end
        end

        it 'accepts non-nil value and outputs it' do
          expect(args.bind('HEAD', 'file.txt').to_ary).to eq(['HEAD', '--', 'file.txt'])
        end

        it 'accepts nil and omits it from output' do
          expect(args.bind(nil, 'file.txt').to_ary).to eq(['--', 'file.txt'])
        end

        it 'works with no arguments' do
          expect(args.bind.to_ary).to eq([])
        end
      end

      context 'allow_nil defaults to false for required positional' do
        let(:args) do
          described_class.define do
            operand :tree_ish, required: true
          end
        end

        it 'raises error when nil is passed' do
          expect { args.bind(nil) }.to raise_error(ArgumentError, /tree_ish is required/)
        end
      end
    end

    context 'with required keyword options' do
      context 'with required: true on flag' do
        let(:args) do
          described_class.define do
            flag_option :force, required: true
          end
        end

        it 'raises ArgumentError when required option is not provided' do
          expect { args.bind }.to raise_error(ArgumentError, /Required options not provided: :force/)
        end

        it 'accepts true value' do
          expect(args.bind(force: true).to_ary).to eq(['--force'])
        end

        it 'accepts false value (key present but falsy)' do
          expect(args.bind(force: false).to_ary).to eq([])
        end

        it 'accepts nil value (key present but nil)' do
          expect(args.bind(force: nil).to_ary).to eq([])
        end
      end

      context 'with required: true on value' do
        let(:args) do
          described_class.define do
            value_option :message, required: true
          end
        end

        it 'raises ArgumentError when required option is not provided' do
          expect { args.bind }.to raise_error(ArgumentError, /Required options not provided: :message/)
        end

        it 'accepts string value' do
          expect(args.bind(message: 'hello').to_ary).to eq(['--message', 'hello'])
        end

        it 'accepts nil value (key present but nil)' do
          expect(args.bind(message: nil).to_ary).to eq([])
        end
      end

      context 'with required: true on value inline: true' do
        let(:args) do
          described_class.define do
            value_option :upstream, inline: true, required: true
          end
        end

        it 'raises ArgumentError when required option is not provided' do
          expect { args.bind }.to raise_error(ArgumentError, /Required options not provided: :upstream/)
        end

        it 'accepts string value' do
          expect(args.bind(upstream: 'origin/main').to_ary).to eq(['--upstream=origin/main'])
        end

        it 'accepts nil value (key present but nil)' do
          expect(args.bind(upstream: nil).to_ary).to eq([])
        end
      end

      context 'with required: true on flag negatable: true' do
        let(:args) do
          described_class.define do
            flag_option :verify, negatable: true, required: true
          end
        end

        it 'raises ArgumentError when required option is not provided' do
          expect { args.bind }.to raise_error(ArgumentError, /Required options not provided: :verify/)
        end

        it 'accepts true value' do
          expect(args.bind(verify: true).to_ary).to eq(['--verify'])
        end

        it 'accepts false value' do
          expect(args.bind(verify: false).to_ary).to eq(['--no-verify'])
        end
      end

      context 'with required: true on flag_or_value inline: true' do
        let(:args) do
          described_class.define do
            flag_or_value_option :gpg_sign, inline: true, required: true
          end
        end

        it 'raises ArgumentError when required option is not provided' do
          expect { args.bind }.to raise_error(ArgumentError, /Required options not provided: :gpg_sign/)
        end

        it 'accepts true value' do
          expect(args.bind(gpg_sign: true).to_ary).to eq(['--gpg-sign'])
        end

        it 'accepts string value' do
          expect(args.bind(gpg_sign: 'KEYID').to_ary).to eq(['--gpg-sign=KEYID'])
        end
      end

      context 'with required: true on flag_or_value negatable: true, inline: true' do
        let(:args) do
          described_class.define do
            flag_or_value_option :gpg_sign, negatable: true, inline: true, required: true
          end
        end

        it 'raises ArgumentError when required option is not provided' do
          expect { args.bind }.to raise_error(ArgumentError, /Required options not provided: :gpg_sign/)
        end

        it 'accepts true value' do
          expect(args.bind(gpg_sign: true).to_ary).to eq(['--gpg-sign'])
        end

        it 'accepts false value' do
          expect(args.bind(gpg_sign: false).to_ary).to eq(['--no-gpg-sign'])
        end

        it 'accepts string value' do
          expect(args.bind(gpg_sign: 'KEYID').to_ary).to eq(['--gpg-sign=KEYID'])
        end
      end

      context 'with required: true on custom' do
        let(:args) do
          described_class.define do
            custom_option :special, required: true do |value|
              value ? "--special=#{value}" : nil
            end
          end
        end

        it 'raises ArgumentError when required option is not provided' do
          expect { args.bind }.to raise_error(ArgumentError, /Required options not provided: :special/)
        end

        it 'accepts value' do
          expect(args.bind(special: 'foo').to_ary).to eq(['--special=foo'])
        end
      end

      context 'with multiple required options' do
        let(:args) do
          described_class.define do
            value_option :upstream, inline: true, required: true
            value_option :message, required: true
          end
        end

        it 'raises ArgumentError listing all missing required options' do
          expect { args.bind }.to raise_error(ArgumentError, /Required options not provided: :upstream, :message/)
        end

        it 'raises ArgumentError when only some required options provided' do
          expect do
            args.bind(upstream: 'origin/main')
          end.to raise_error(ArgumentError, /Required options not provided: :message/)
        end

        it 'succeeds when all required options provided' do
          expect(args.bind(upstream: 'origin/main',
                           message: 'hello').to_ary).to eq(['--upstream=origin/main',
                                                            '--message', 'hello'])
        end
      end

      context 'with required option and aliases' do
        let(:args) do
          described_class.define do
            flag_option %i[force f], required: true
          end
        end

        it 'raises ArgumentError when required option is not provided' do
          expect { args.bind }.to raise_error(ArgumentError, /Required options not provided: :force/)
        end

        it 'accepts primary name' do
          expect(args.bind(force: true).to_ary).to eq(['--force'])
        end

        it 'accepts alias name' do
          expect(args.bind(f: true).to_ary).to eq(['--force'])
        end
      end

      context 'with required: true and allow_nil: false on value' do
        let(:args) do
          described_class.define do
            value_option :message, required: true, allow_nil: false
          end
        end

        it 'raises ArgumentError when option is not provided' do
          expect { args.bind }.to raise_error(ArgumentError, /Required options not provided: :message/)
        end

        it 'raises ArgumentError when value is nil' do
          expect { args.bind(message: nil) }.to raise_error(ArgumentError, /Required options cannot be nil: :message/)
        end

        it 'accepts non-nil value' do
          expect(args.bind(message: 'hello').to_ary).to eq(['--message', 'hello'])
        end
      end

      context 'with required: true and allow_nil: false on value inline: true' do
        let(:args) do
          described_class.define do
            value_option :upstream, inline: true, required: true, allow_nil: false
          end
        end

        it 'raises ArgumentError when option is not provided' do
          expect { args.bind }.to raise_error(ArgumentError, /Required options not provided: :upstream/)
        end

        it 'raises ArgumentError when value is nil' do
          expect do
            args.bind(upstream: nil)
          end.to raise_error(ArgumentError, /Required options cannot be nil: :upstream/)
        end

        it 'accepts non-nil value' do
          expect(args.bind(upstream: 'origin/main').to_ary).to eq(['--upstream=origin/main'])
        end
      end

      context 'with multiple required options and allow_nil: false' do
        let(:args) do
          described_class.define do
            value_option :upstream, inline: true, required: true, allow_nil: false
            value_option :message, required: true, allow_nil: false
          end
        end

        it 'raises ArgumentError listing all nil values' do
          expect { args.bind(upstream: nil, message: nil) }.to raise_error(
            ArgumentError, /Required options cannot be nil: :upstream, :message/
          )
        end

        it 'raises ArgumentError for single nil value' do
          expect { args.bind(upstream: 'origin/main', message: nil) }.to raise_error(
            ArgumentError, /Required options cannot be nil: :message/
          )
        end

        it 'succeeds when all values are non-nil' do
          expect(args.bind(upstream: 'origin/main', message: 'hello').to_ary).to eq(
            ['--upstream=origin/main', '--message', 'hello']
          )
        end
      end

      context 'with required: true and default allow_nil (true)' do
        let(:args) do
          described_class.define do
            value_option :message, required: true
          end
        end

        it 'allows nil value when allow_nil defaults to true' do
          expect(args.bind(message: nil).to_ary).to eq([])
        end
      end

      context 'with required: true and allow_nil: false on flag' do
        let(:args) do
          described_class.define do
            flag_option :force, required: true, allow_nil: false
          end
        end

        it 'raises ArgumentError when option is not provided' do
          expect { args.bind }.to raise_error(ArgumentError, /Required options not provided: :force/)
        end

        it 'raises ArgumentError when value is nil' do
          expect { args.bind(force: nil) }.to raise_error(ArgumentError, /Required options cannot be nil: :force/)
        end

        it 'accepts true value' do
          expect(args.bind(force: true).to_ary).to eq(['--force'])
        end

        it 'accepts false value' do
          expect(args.bind(force: false).to_ary).to eq([])
        end
      end

      context 'with required: true and allow_nil: false on flag negatable: true' do
        let(:args) do
          described_class.define do
            flag_option :verify, negatable: true, required: true, allow_nil: false
          end
        end

        it 'raises ArgumentError when option is not provided' do
          expect { args.bind }.to raise_error(ArgumentError, /Required options not provided: :verify/)
        end

        it 'raises ArgumentError when value is nil' do
          expect { args.bind(verify: nil) }.to raise_error(ArgumentError, /Required options cannot be nil: :verify/)
        end

        it 'accepts true value' do
          expect(args.bind(verify: true).to_ary).to eq(['--verify'])
        end

        it 'accepts false value' do
          expect(args.bind(verify: false).to_ary).to eq(['--no-verify'])
        end
      end

      context 'with required: true and allow_nil: false on flag_or_value inline: true' do
        let(:args) do
          described_class.define do
            flag_or_value_option :gpg_sign, inline: true, required: true, allow_nil: false
          end
        end

        it 'raises ArgumentError when option is not provided' do
          expect { args.bind }.to raise_error(ArgumentError, /Required options not provided: :gpg_sign/)
        end

        it 'raises ArgumentError when value is nil' do
          expect do
            args.bind(gpg_sign: nil)
          end.to raise_error(ArgumentError, /Required options cannot be nil: :gpg_sign/)
        end

        it 'accepts true value' do
          expect(args.bind(gpg_sign: true).to_ary).to eq(['--gpg-sign'])
        end

        it 'accepts false value' do
          expect(args.bind(gpg_sign: false).to_ary).to eq([])
        end

        it 'accepts string value' do
          expect(args.bind(gpg_sign: 'KEYID').to_ary).to eq(['--gpg-sign=KEYID'])
        end
      end

      context 'with required: true and allow_nil: false on flag_or_value negatable: true, inline: true' do
        let(:args) do
          described_class.define do
            flag_or_value_option :gpg_sign, negatable: true, inline: true, required: true, allow_nil: false
          end
        end

        it 'raises ArgumentError when option is not provided' do
          expect { args.bind }.to raise_error(ArgumentError, /Required options not provided: :gpg_sign/)
        end

        it 'raises ArgumentError when value is nil' do
          expect do
            args.bind(gpg_sign: nil)
          end.to raise_error(ArgumentError, /Required options cannot be nil: :gpg_sign/)
        end

        it 'accepts true value' do
          expect(args.bind(gpg_sign: true).to_ary).to eq(['--gpg-sign'])
        end

        it 'accepts false value' do
          expect(args.bind(gpg_sign: false).to_ary).to eq(['--no-gpg-sign'])
        end

        it 'accepts string value' do
          expect(args.bind(gpg_sign: 'KEYID').to_ary).to eq(['--gpg-sign=KEYID'])
        end
      end

      context 'with required: true and allow_nil: false on custom' do
        let(:args) do
          described_class.define do
            custom_option :special, required: true, allow_nil: false do |value|
              value ? "--special=#{value}" : nil
            end
          end
        end

        it 'raises ArgumentError when option is not provided' do
          expect { args.bind }.to raise_error(ArgumentError, /Required options not provided: :special/)
        end

        it 'raises ArgumentError when value is nil' do
          expect { args.bind(special: nil) }.to raise_error(ArgumentError, /Required options cannot be nil: :special/)
        end

        it 'accepts non-nil value' do
          expect(args.bind(special: 'foo').to_ary).to eq(['--special=foo'])
        end
      end
    end

    describe 'argument ordering' do
      context 'when arguments are rendered in definition order across types' do
        it 'renders arguments in definition order for flag, positional, static pattern' do
          args = described_class.define do
            flag_option :verbose
            operand :command, required: true
            literal '--'
            operand :paths, repeatable: true
          end

          result = args.bind('status', 'file1.txt', 'file2.txt', verbose: true).to_ary
          expect(result).to eq(['--verbose', 'status', '--', 'file1.txt', 'file2.txt'])
        end

        it 'renders static flags in definition position (not first)' do
          args = described_class.define do
            operand :ref, required: true
            literal '--'
            operand :path, required: true
          end

          result = args.bind('HEAD', 'file.txt').to_ary
          expect(result).to eq(['HEAD', '--', 'file.txt'])
        end

        it 'renders positional before flag when positional is defined first' do
          args = described_class.define do
            operand :file, required: true
            flag_option :force
            literal '--'
          end

          result = args.bind('file.txt', force: true).to_ary
          expect(result).to eq(['file.txt', '--force', '--'])
        end

        it 'renders interleaved options and positionals in definition order' do
          args = described_class.define do
            flag_option :verbose
            operand :source, required: true
            flag_option :force
            operand :dest, required: true
            literal '--'
            operand :extra
          end

          result = args.bind('src.txt', 'dst.txt', 'extra.txt', verbose: true, force: true).to_ary
          expect(result).to eq(['--verbose', 'src.txt', '--force', 'dst.txt', '--', 'extra.txt'])
        end

        it 'skips omitted options while preserving order' do
          args = described_class.define do
            flag_option :verbose
            operand :source, required: true
            flag_option :force
            operand :dest, required: true
          end

          result = args.bind('src.txt', 'dst.txt', force: true).to_ary
          expect(result).to eq(['src.txt', '--force', 'dst.txt'])
        end

        it 'handles multiple static flags in definition order' do
          args = described_class.define do
            literal '-a'
            flag_option :force
            literal '-b'
            operand :file, required: true
            literal '-c'
          end

          result = args.bind('file.txt', force: true).to_ary
          expect(result).to eq(['-a', '--force', '-b', 'file.txt', '-c'])
        end

        it 'handles complex git checkout pattern: [tree-ish] -- paths' do
          args = described_class.define do
            flag_option :force
            flag_option :quiet
            operand :tree_ish
            literal '--'
            operand :paths, repeatable: true
          end

          # git checkout HEAD -- file1 file2
          result = args.bind('HEAD', 'file1.txt', 'file2.txt', force: true).to_ary
          expect(result).to eq(['--force', 'HEAD', '--', 'file1.txt', 'file2.txt'])

          # git checkout -- file1 (no tree-ish)
          result_no_treeish = args.bind(nil, 'file1.txt').to_ary
          expect(result_no_treeish).to eq(['--', 'file1.txt'])
        end

        it 'handles git diff pattern: commit1 commit2 -- paths' do
          args = described_class.define do
            flag_option :stat
            operand :commit1
            operand :commit2
            literal '--'
            operand :paths, repeatable: true
          end

          # git diff --stat HEAD~1 HEAD -- file.rb
          result = args.bind('HEAD~1', 'HEAD', 'file.rb', stat: true).to_ary
          expect(result).to eq(['--stat', 'HEAD~1', 'HEAD', '--', 'file.rb'])

          # git diff HEAD~1 -- (no commit2 or paths)
          result_single = args.bind('HEAD~1', nil).to_ary
          expect(result_single).to eq(['HEAD~1', '--'])
        end
      end

      context 'when static flags are defined first (matching common git patterns)' do
        it 'renders static before options when static is defined first' do
          args = described_class.define do
            literal '--delete'
            flag_option :force
            flag_option :remotes
            operand :branch_names, repeatable: true, required: true
          end

          result = args.bind('feature', 'bugfix', force: true, remotes: true).to_ary
          expect(result).to eq(['--delete', '--force', '--remotes', 'feature', 'bugfix'])
        end
      end
    end

    # =======================================================================
    # Issue #982: Consolidated DSL with orthogonal modifiers
    # =======================================================================

    describe 'orthogonal modifiers' do
      context 'with flag negatable: true' do
        let(:args) do
          described_class.define do
            flag_option :full, negatable: true
          end
        end

        it 'outputs --flag when value is true' do
          expect(args.bind(full: true).to_ary).to eq(['--full'])
        end

        it 'outputs --no-flag when value is false' do
          expect(args.bind(full: false).to_ary).to eq(['--no-full'])
        end

        it 'outputs nothing when option is not provided' do
          expect(args.bind.to_ary).to eq([])
        end

        it 'raises an error when value is not a boolean' do
          expect { args.bind(full: 'true') }.to raise_error(
            ArgumentError,
            /negatable_flag expects a boolean value, got "true"/
          )
        end
      end

      context 'with value inline: true' do
        let(:args) do
          described_class.define do
            value_option :abbrev, inline: true
          end
        end

        it 'outputs --flag=value as single argument' do
          expect(args.bind(abbrev: '7').to_ary).to eq(['--abbrev=7'])
        end

        it 'outputs nothing when value is nil' do
          expect(args.bind(abbrev: nil).to_ary).to eq([])
        end

        it 'outputs nothing when option is not provided' do
          expect(args.bind.to_ary).to eq([])
        end
      end

      context 'with value inline: true and repeatable: true' do
        let(:args) do
          described_class.define do
            value_option :sort, inline: true, repeatable: true
          end
        end

        it 'outputs --flag=value for each array element' do
          expect(args.bind(sort: %w[refname -committerdate]).to_ary).to eq(['--sort=refname', '--sort=-committerdate'])
        end

        it 'outputs --flag=value for single value' do
          expect(args.bind(sort: 'refname').to_ary).to eq(['--sort=refname'])
        end
      end

      context 'with value inline: true and allow_empty: true' do
        let(:args) do
          described_class.define do
            value_option :message, inline: true, allow_empty: true
          end
        end

        it 'outputs --flag= when value is empty string' do
          expect(args.bind(message: '').to_ary).to eq(['--message='])
        end
      end

      context 'with value as_operand: true' do
        let(:args) do
          described_class.define do
            value_option :path, as_operand: true
          end
        end

        it 'outputs the value as a positional argument' do
          expect(args.bind(path: 'file.txt').to_ary).to eq(['file.txt'])
        end

        it 'outputs nothing when value is nil' do
          expect(args.bind(path: nil).to_ary).to eq([])
        end

        it 'outputs nothing when option is not provided' do
          expect(args.bind.to_ary).to eq([])
        end

        it 'raises an error when value is an array without repeatable' do
          expect { args.bind(path: %w[file1.txt file2.txt]) }.to raise_error(
            ArgumentError,
            /value_as_operand :path requires repeatable: true to accept an array/
          )
        end
      end

      context 'with value as_operand: true and repeatable: true' do
        let(:args) do
          described_class.define do
            value_option :paths, as_operand: true, repeatable: true
          end
        end

        it 'outputs each array element as a positional argument' do
          expect(args.bind(paths: %w[file1.txt file2.txt]).to_ary).to eq(%w[file1.txt file2.txt])
        end

        it 'outputs a single value as a positional argument' do
          expect(args.bind(paths: 'file.txt').to_ary).to eq(['file.txt'])
        end

        it 'outputs nothing when value is nil' do
          expect(args.bind(paths: nil).to_ary).to eq([])
        end

        it 'outputs nothing when value is empty array' do
          expect(args.bind(paths: []).to_ary).to eq([])
        end

        it 'raises an error when array contains nil' do
          expect { args.bind(paths: ['file1.txt', nil, 'file2.txt']) }.to raise_error(
            ArgumentError,
            /nil values are not allowed in value_as_operand :paths/
          )
        end
      end

      context 'with value as_operand: true and separator:' do
        let(:args) do
          described_class.define do
            flag_option :force
            value_option :paths, as_operand: true, repeatable: true, separator: '--'
          end
        end

        it 'outputs separator before positional values' do
          expect(args.bind(paths: %w[file1.txt file2.txt], force: true).to_ary).to eq(
            ['--force', '--', 'file1.txt', 'file2.txt']
          )
        end

        it 'omits separator when value is nil' do
          expect(args.bind(paths: nil, force: true).to_ary).to eq(['--force'])
        end
      end

      context 'with invalid value modifier combinations' do
        it 'raises when inline: and as_operand: are both true' do
          expect do
            described_class.define do
              value_option :path, inline: true, as_operand: true
            end
          end.to raise_error(ArgumentError, /inline: and as_operand: cannot both be true for :path/)
        end

        it 'raises when separator: is provided without as_operand: true' do
          expect do
            described_class.define do
              value_option :path, separator: '--'
            end
          end.to raise_error(ArgumentError, /separator: is only valid with as_operand: true for :path/)
        end
      end

      # =====================================================================
      # flag_or_value - new base type that enables previously impossible
      # combinations (flag OR separated value)
      # =====================================================================

      context 'with flag_or_value' do
        let(:args) do
          described_class.define do
            flag_or_value_option :contains
          end
        end

        it 'outputs --flag when value is true' do
          expect(args.bind(contains: true).to_ary).to eq(['--contains'])
        end

        it 'outputs nothing when value is false' do
          expect(args.bind(contains: false).to_ary).to eq([])
        end

        it 'outputs --flag value as separate arguments when value is a string' do
          expect(args.bind(contains: 'abc123').to_ary).to eq(['--contains', 'abc123'])
        end

        it 'outputs nothing when option is not provided' do
          expect(args.bind.to_ary).to eq([])
        end

        it 'raises an error when value is not true, false, or a String' do
          expect { args.bind(contains: 1) }.to raise_error(
            ArgumentError,
            /Invalid value for flag_or_value: 1 \(Integer\); expected true, false, or a String/
          )
        end
      end

      context 'with flag_or_value inline: true' do
        let(:args) do
          described_class.define do
            flag_or_value_option :gpg_sign, inline: true
          end
        end

        it 'outputs --flag when value is true' do
          expect(args.bind(gpg_sign: true).to_ary).to eq(['--gpg-sign'])
        end

        it 'outputs nothing when value is false' do
          expect(args.bind(gpg_sign: false).to_ary).to eq([])
        end

        it 'outputs --flag=value when value is a string' do
          expect(args.bind(gpg_sign: 'key-id').to_ary).to eq(['--gpg-sign=key-id'])
        end

        it 'raises an error when value is not true, false, or a String' do
          expect { args.bind(gpg_sign: 1) }.to raise_error(
            ArgumentError,
            /Invalid value for flag_or_inline_value: 1 \(Integer\); expected true, false, or a String/
          )
        end
      end

      context 'with flag_or_value negatable: true' do
        let(:args) do
          described_class.define do
            flag_or_value_option :verify, negatable: true
          end
        end

        it 'outputs --flag when value is true' do
          expect(args.bind(verify: true).to_ary).to eq(['--verify'])
        end

        it 'outputs --no-flag when value is false' do
          expect(args.bind(verify: false).to_ary).to eq(['--no-verify'])
        end

        it 'outputs --flag value as separate arguments when value is a string' do
          expect(args.bind(verify: 'KEYID').to_ary).to eq(['--verify', 'KEYID'])
        end

        it 'raises an error when value is not true, false, or a String' do
          expect { args.bind(verify: 1) }.to raise_error(
            ArgumentError,
            /Invalid value for negatable_flag_or_value: 1 \(Integer\); expected true, false, or a String/
          )
        end
      end

      context 'with flag_or_value negatable: true and inline: true' do
        let(:args) do
          described_class.define do
            flag_or_value_option :sign, negatable: true, inline: true
          end
        end

        it 'outputs --flag when value is true' do
          expect(args.bind(sign: true).to_ary).to eq(['--sign'])
        end

        it 'outputs --no-flag when value is false' do
          expect(args.bind(sign: false).to_ary).to eq(['--no-sign'])
        end

        it 'outputs --flag=value when value is a string' do
          expect(args.bind(sign: 'key-id').to_ary).to eq(['--sign=key-id'])
        end

        it 'raises an error when value is not true, false, or a String' do
          expect { args.bind(sign: 1) }.to raise_error(
            ArgumentError,
            /Invalid value for negatable_flag_or_inline_value: 1 \(Integer\); expected true, false, or a String/
          )
        end
      end
    end

    # =======================================================================
    # key_value options
    # =======================================================================

    context 'with key_value options' do
      context 'basic Hash input' do
        let(:args) do
          described_class.define do
            key_value_option :trailers, as: '--trailer'
          end
        end

        it 'outputs --flag key=value for single hash entry' do
          expect(args.bind(trailers: { 'Signed-off-by' => 'John Doe' }).to_ary).to eq(
            ['--trailer', 'Signed-off-by=John Doe']
          )
        end

        it 'outputs multiple --flag key=value for multiple hash entries' do
          expect(args.bind(trailers: { 'Signed-off-by' => 'John', 'Acked-by' => 'Jane' }).to_ary).to eq(
            ['--trailer', 'Signed-off-by=John', '--trailer', 'Acked-by=Jane']
          )
        end
      end

      context 'Hash with array values' do
        let(:args) do
          described_class.define do
            key_value_option :trailers, as: '--trailer'
          end
        end

        it 'outputs multiple entries for same key when value is array' do
          expect(args.bind(trailers: { 'Signed-off-by' => %w[John Jane] }).to_ary).to eq(
            ['--trailer', 'Signed-off-by=John', '--trailer', 'Signed-off-by=Jane']
          )
        end

        it 'handles mixed single and array values' do
          expect(args.bind(trailers: { 'Signed-off-by' => %w[John Jane], 'Acked-by' => 'Bob' }).to_ary).to eq(
            ['--trailer', 'Signed-off-by=John', '--trailer', 'Signed-off-by=Jane', '--trailer', 'Acked-by=Bob']
          )
        end
      end

      context 'Array of arrays input' do
        let(:args) do
          described_class.define do
            key_value_option :trailers, as: '--trailer'
          end
        end

        it 'outputs entries in order for array of arrays' do
          expect(args.bind(trailers: [%w[Signed-off-by John], %w[Acked-by Bob]]).to_ary).to eq(
            ['--trailer', 'Signed-off-by=John', '--trailer', 'Acked-by=Bob']
          )
        end

        it 'allows duplicate keys with array of arrays' do
          expect(args.bind(trailers: [%w[Signed-off-by John], %w[Signed-off-by Jane]]).to_ary).to eq(
            ['--trailer', 'Signed-off-by=John', '--trailer', 'Signed-off-by=Jane']
          )
        end

        it 'handles single [key, value] pair' do
          expect(args.bind(trailers: %w[Signed-off-by John]).to_ary).to eq(
            ['--trailer', 'Signed-off-by=John']
          )
        end
      end

      context 'nil and empty value handling' do
        let(:args) do
          described_class.define do
            key_value_option :trailers, as: '--trailer'
          end
        end

        it 'outputs nothing when option is nil' do
          expect(args.bind(trailers: nil).to_ary).to eq([])
        end

        it 'outputs nothing when option is empty hash' do
          expect(args.bind(trailers: {}).to_ary).to eq([])
        end

        it 'outputs nothing when option is empty array' do
          expect(args.bind(trailers: []).to_ary).to eq([])
        end

        it 'outputs nothing when option is not provided' do
          expect(args.bind.to_ary).to eq([])
        end

        it 'outputs key only when value is nil (no separator)' do
          expect(args.bind(trailers: [['Acked-by', nil]]).to_ary).to eq(
            ['--trailer', 'Acked-by']
          )
        end

        it 'outputs key with separator when value is empty string' do
          expect(args.bind(trailers: [['Acked-by', '']]).to_ary).to eq(
            ['--trailer', 'Acked-by=']
          )
        end

        it 'handles Hash with nil value' do
          expect(args.bind(trailers: { 'Acked-by' => nil }).to_ary).to eq(
            ['--trailer', 'Acked-by']
          )
        end

        it 'handles Hash with array value containing nil (key-only entry)' do
          expect(args.bind(trailers: { 'Key' => ['Value1', nil, 'Value2'] }).to_ary).to eq(
            ['--trailer', 'Key=Value1', '--trailer', 'Key', '--trailer', 'Key=Value2']
          )
        end
      end

      context 'with inline: true' do
        let(:args) do
          described_class.define do
            key_value_option :trailers, as: '--trailer', inline: true
          end
        end

        it 'outputs --flag=key=value format' do
          expect(args.bind(trailers: { 'Signed-off-by' => 'John' }).to_ary).to eq(
            ['--trailer=Signed-off-by=John']
          )
        end

        it 'handles multiple entries' do
          expect(args.bind(trailers: { 'Signed-off-by' => %w[John Jane] }).to_ary).to eq(
            ['--trailer=Signed-off-by=John', '--trailer=Signed-off-by=Jane']
          )
        end

        it 'handles nil value (key only)' do
          expect(args.bind(trailers: [['Acked-by', nil]]).to_ary).to eq(
            ['--trailer=Acked-by']
          )
        end
      end

      context 'key validation' do
        let(:args) do
          described_class.define do
            key_value_option :trailers, as: '--trailer'
          end
        end

        it 'raises ArgumentError when key is nil' do
          expect { args.bind(trailers: [[nil, 'value']]) }.to raise_error(
            ArgumentError, /key_value :trailers requires a non-empty key/
          )
        end

        it 'raises ArgumentError when key is empty string' do
          expect { args.bind(trailers: [['', 'value']]) }.to raise_error(
            ArgumentError, /key_value :trailers requires a non-empty key/
          )
        end

        it 'raises ArgumentError when key contains the separator' do
          expect { args.bind(trailers: { 'Signed=off' => 'John' }) }.to raise_error(
            ArgumentError, /key_value :trailers key "Signed=off" cannot contain the separator "="/
          )
        end

        context 'with custom separator' do
          let(:args) do
            described_class.define do
              key_value_option :trailers, as: '--trailer', key_separator: ': '
            end
          end

          it 'raises ArgumentError when key contains the custom separator' do
            expect { args.bind(trailers: { 'Signed: off' => 'John' }) }.to raise_error(
              ArgumentError, /key_value :trailers key "Signed: off" cannot contain the separator ": "/
            )
          end

          it 'allows key with default separator when using custom separator' do
            expect(args.bind(trailers: { 'Signed=off' => 'John' }).to_ary).to eq(
              ['--trailer', 'Signed=off: John']
            )
          end
        end

        context 'with malformed array input' do
          it 'raises ArgumentError for flat array with 3+ elements' do
            expect { args.bind(trailers: %w[a b c]) }.to raise_error(
              ArgumentError, /key_value array input must be a \[key, value\] pair or array of pairs/
            )
          end

          it 'raises ArgumentError for sub-array with 3+ elements' do
            expect { args.bind(trailers: [%w[a b c]]) }.to raise_error(
              ArgumentError, /key_value :trailers pair \["a", "b", "c"\] has too many elements/
            )
          end

          it 'raises ArgumentError for mixed valid and invalid sub-arrays' do
            expect { args.bind(trailers: [%w[k1 v1], %w[a b c]]) }.to raise_error(
              ArgumentError, /key_value :trailers pair \["a", "b", "c"\] has too many elements/
            )
          end
        end

        context 'with invalid input type' do
          it 'raises ArgumentError for String input' do
            expect { args.bind(trailers: 'some-string') }.to raise_error(
              ArgumentError, /key_value option must be a Hash or Array, got String/
            )
          end

          it 'raises ArgumentError for Integer input' do
            expect { args.bind(trailers: 123) }.to raise_error(
              ArgumentError, /key_value option must be a Hash or Array, got Integer/
            )
          end

          it 'raises ArgumentError for Symbol input' do
            expect { args.bind(trailers: :some_symbol) }.to raise_error(
              ArgumentError, /key_value option must be a Hash or Array, got Symbol/
            )
          end
        end

        context 'with non-scalar value in pair' do
          it 'raises ArgumentError for Hash value' do
            expect { args.bind(trailers: { 'Key' => { nested: true } }) }.to raise_error(
              ArgumentError, /key_value :trailers value must be a scalar.*got Hash/
            )
          end

          it 'raises ArgumentError for Array value' do
            expect { args.bind(trailers: [['Key', %w[nested array]]]) }.to raise_error(
              ArgumentError, /key_value :trailers value must be a scalar.*got Array/
            )
          end

          it 'raises ArgumentError for Hash value in array of values' do
            expect { args.bind(trailers: { 'Key' => ['valid', { nested: true }] }) }.to raise_error(
              ArgumentError, /key_value :trailers value must be a scalar.*got Hash/
            )
          end
        end
      end

      context 'with custom key_separator' do
        let(:args) do
          described_class.define do
            key_value_option :trailers, as: '--trailer', key_separator: ': '
          end
        end

        it 'uses the custom separator' do
          expect(args.bind(trailers: { 'Signed-off-by' => 'John' }).to_ary).to eq(
            ['--trailer', 'Signed-off-by: John']
          )
        end
      end

      context 'with required: true' do
        let(:args) do
          described_class.define do
            key_value_option :trailers, as: '--trailer', required: true
          end
        end

        it 'raises ArgumentError when option is not provided' do
          expect { args.bind }.to raise_error(
            ArgumentError, /Required options not provided: :trailers/
          )
        end

        it 'does not raise when option is provided' do
          expect(args.bind(trailers: { 'A' => 'B' }).to_ary).to eq(['--trailer', 'A=B'])
        end

        it 'does not raise when option is nil (key present)' do
          expect(args.bind(trailers: nil).to_ary).to eq([])
        end

        it 'does not raise when option is empty hash (key present, produces no output)' do
          expect(args.bind(trailers: {}).to_ary).to eq([])
        end

        it 'does not raise when option is empty array (key present, produces no output)' do
          expect(args.bind(trailers: []).to_ary).to eq([])
        end
      end

      context 'with required: true and allow_nil: false' do
        let(:args) do
          described_class.define do
            key_value_option :trailers, as: '--trailer', required: true, allow_nil: false
          end
        end

        it 'raises ArgumentError when option is nil' do
          expect { args.bind(trailers: nil) }.to raise_error(
            ArgumentError, /Required options cannot be nil: :trailers/
          )
        end

        it 'does not raise when option is provided with value' do
          expect(args.bind(trailers: { 'A' => 'B' }).to_ary).to eq(['--trailer', 'A=B'])
        end
      end

      context 'with symbol keys and values' do
        let(:args) do
          described_class.define do
            key_value_option :trailers, as: '--trailer'
          end
        end

        it 'converts symbol keys to strings' do
          expect(args.bind(trailers: { signed_off_by: 'John' }).to_ary).to eq(
            ['--trailer', 'signed_off_by=John']
          )
        end

        it 'converts symbol values to strings' do
          expect(args.bind(trailers: { 'Type' => :feature }).to_ary).to eq(
            ['--trailer', 'Type=feature']
          )
        end
      end
    end

    describe 'short option detection' do
      context 'with single-character flag' do
        subject(:args) { described_class.define { flag_option :f } }

        it 'uses single-dash prefix' do
          expect(args.bind(f: true).to_ary).to eq(['-f'])
        end
      end

      context 'with multi-character flag' do
        subject(:args) { described_class.define { flag_option :force } }

        it 'uses double-dash prefix' do
          expect(args.bind(force: true).to_ary).to eq(['--force'])
        end
      end

      context 'with single-character negatable flag' do
        subject(:args) { described_class.define { flag_option :f, negatable: true } }

        it 'uses single-dash prefix when true' do
          expect(args.bind(f: true).to_ary).to eq(['-f'])
        end

        it 'uses double-dash --no- prefix when false' do
          expect(args.bind(f: false).to_ary).to eq(['--no-f'])
        end
      end

      context 'with single-character value' do
        subject(:args) { described_class.define { value_option :n } }

        it 'uses single-dash prefix with separate value' do
          expect(args.bind(n: '3').to_ary).to eq(['-n', '3'])
        end
      end

      context 'with multi-character value' do
        subject(:args) { described_class.define { value_option :name } }

        it 'uses double-dash prefix with separate value' do
          expect(args.bind(name: 'test').to_ary).to eq(['--name', 'test'])
        end
      end

      context 'with single-character inline value' do
        subject(:args) { described_class.define { value_option :n, inline: true } }

        it 'uses no separator' do
          expect(args.bind(n: 3).to_ary).to eq(['-n3'])
        end
      end

      context 'with multi-character inline value' do
        subject(:args) { described_class.define { value_option :name, inline: true } }

        it 'uses = separator' do
          expect(args.bind(name: 'test').to_ary).to eq(['--name=test'])
        end
      end

      context 'with single-character inline value repeatable: true' do
        subject(:args) { described_class.define { value_option :n, inline: true, repeatable: true } }

        it 'uses no separator for each value' do
          expect(args.bind(n: [3, 5]).to_ary).to eq(['-n3', '-n5'])
        end
      end

      context 'with single-character flag_or_value' do
        subject(:args) { described_class.define { flag_or_value_option :n } }

        it 'outputs flag only when true' do
          expect(args.bind(n: true).to_ary).to eq(['-n'])
        end

        it 'outputs nothing when false' do
          expect(args.bind(n: false).to_ary).to eq([])
        end

        it 'outputs value as separate argument when given a string' do
          expect(args.bind(n: '5').to_ary).to eq(['-n', '5'])
        end
      end

      context 'with single-character flag_or_value inline: true' do
        subject(:args) { described_class.define { flag_or_value_option :n, inline: true } }

        it 'outputs flag only when true' do
          expect(args.bind(n: true).to_ary).to eq(['-n'])
        end

        it 'outputs nothing when false' do
          expect(args.bind(n: false).to_ary).to eq([])
        end

        it 'outputs value with no separator when given a string' do
          expect(args.bind(n: '5').to_ary).to eq(['-n5'])
        end
      end

      context 'with single-character negatable flag_or_value inline: true' do
        subject(:args) { described_class.define { flag_or_value_option :n, negatable: true, inline: true } }

        it 'outputs flag only when true' do
          expect(args.bind(n: true).to_ary).to eq(['-n'])
        end

        it 'outputs --no-n when false' do
          expect(args.bind(n: false).to_ary).to eq(['--no-n'])
        end

        it 'outputs value with no separator when given a string' do
          expect(args.bind(n: '5').to_ary).to eq(['-n5'])
        end
      end

      context 'with single-character negatable flag_or_value (non-inline)' do
        subject(:args) { described_class.define { flag_or_value_option :n, negatable: true } }

        it 'outputs flag only when true' do
          expect(args.bind(n: true).to_ary).to eq(['-n'])
        end

        it 'outputs --no-n when false' do
          expect(args.bind(n: false).to_ary).to eq(['--no-n'])
        end

        it 'outputs value as separate argument when given a string' do
          expect(args.bind(n: '5').to_ary).to eq(['-n', '5'])
        end
      end

      context 'with multi-character negatable flag_or_value inline: true' do
        subject(:args) { described_class.define { flag_or_value_option :name, negatable: true, inline: true } }

        it 'outputs flag only when true' do
          expect(args.bind(name: true).to_ary).to eq(['--name'])
        end

        it 'outputs --no-name when false' do
          expect(args.bind(name: false).to_ary).to eq(['--no-name'])
        end

        it 'outputs value with = separator when given a string' do
          expect(args.bind(name: 'test').to_ary).to eq(['--name=test'])
        end
      end

      context 'with multi-character negatable flag_or_value (non-inline)' do
        subject(:args) { described_class.define { flag_or_value_option :name, negatable: true } }

        it 'outputs flag only when true' do
          expect(args.bind(name: true).to_ary).to eq(['--name'])
        end

        it 'outputs --no-name when false' do
          expect(args.bind(name: false).to_ary).to eq(['--no-name'])
        end

        it 'outputs value as separate argument when given a string' do
          expect(args.bind(name: 'test').to_ary).to eq(['--name', 'test'])
        end
      end

      context 'with underscore in multi-character option name' do
        subject(:args) { described_class.define { flag_option :dry_run } }

        it 'converts underscores to dashes' do
          expect(args.bind(dry_run: true).to_ary).to eq(['--dry-run'])
        end
      end

      context 'with explicit as: override' do
        subject(:args) { described_class.define { flag_option :f, as: '--force' } }

        it 'uses the explicit args even for single-character name' do
          expect(args.bind(f: true).to_ary).to eq(['--force'])
        end
      end

      context 'with multi-character name and explicit short as: override' do
        subject(:args) { described_class.define { flag_option :all, as: '-a' } }

        it 'uses the explicit short args instead of deriving from name' do
          expect(args.bind(all: true).to_ary).to eq(['-a'])
        end
      end

      context 'with multi-character name and explicit short as: for inline value' do
        subject(:args) { described_class.define { value_option :number, inline: true, as: '-n' } }

        it 'uses no separator for explicitly short args' do
          expect(args.bind(number: 5).to_ary).to eq(['-n5'])
        end
      end
    end
  end

  describe '#bind' do
    context 'with flag options' do
      let(:args) do
        described_class.define do
          flag_option :force
        end
      end

      it 'returns an Arguments::Bound object' do
        bound = args.bind(force: true)
        expect(bound).to be_a(Git::Commands::Arguments::Bound)
      end

      it 'provides accessor for the option' do
        bound = args.bind(force: true)
        expect(bound.force).to be true
      end

      it 'returns false when flag is not provided' do
        bound = args.bind
        expect(bound.force).to be false
      end
    end

    context 'with option aliases' do
      let(:args) do
        described_class.define do
          flag_option %i[remotes r]
          flag_option %i[force f]
        end
      end

      it 'normalizes aliases to canonical names' do
        bound = args.bind(r: true, f: true)
        expect(bound.remotes).to be true
        expect(bound.force).to be true
      end

      it 'provides accessor only for canonical name' do
        bound = args.bind(r: true)
        expect(bound.remotes).to be true
        expect { bound.r }.to raise_error(NoMethodError)
      end

      it 'allows hash-style access with alias key' do
        bound = args.bind(r: true)
        expect(bound[:remotes]).to be true
        # NOTE: accessing via alias key returns nil because the internal hash
        # only stores canonical names
      end
    end

    context 'with positional arguments' do
      let(:args) do
        described_class.define do
          operand :branch_names, repeatable: true, required: true
        end
      end

      it 'provides accessor for positional arguments' do
        bound = args.bind('branch1', 'branch2')
        expect(bound.branch_names).to eq(%w[branch1 branch2])
      end
    end

    context 'with mixed options and positionals' do
      let(:args) do
        described_class.define do
          flag_option %i[force f]
          flag_option %i[remotes r]
          operand :branch_names, repeatable: true, required: true
        end
      end

      it 'provides accessors for all options and positionals' do
        bound = args.bind('feature', 'bugfix', force: true, r: true)
        expect(bound.force).to be true
        expect(bound.remotes).to be true
        expect(bound.branch_names).to eq(%w[feature bugfix])
      end
    end

    context 'with to_ary for splatting' do
      let(:args) do
        described_class.define do
          flag_option :force
          operand :branch_names, repeatable: true
        end
      end

      it 'returns the CLI args array via to_ary' do
        bound = args.bind('branch1', force: true)
        expect(bound.to_ary).to eq(['--force', 'branch1'])
      end

      it 'enables direct splatting' do
        bound = args.bind('branch1', force: true)
        result = ['git', 'branch', *bound]
        expect(result).to eq(['git', 'branch', '--force', 'branch1'])
      end
    end

    context 'with hash-style access via []' do
      let(:args) do
        described_class.define do
          flag_option :force
          operand :path
        end
      end

      it 'allows hash-style access to options' do
        bound = args.bind('file.txt', force: true)
        expect(bound[:force]).to be true
      end

      it 'allows hash-style access to positionals' do
        bound = args.bind('file.txt', force: true)
        expect(bound[:path]).to eq('file.txt')
      end

      it 'returns nil for undefined keys' do
        bound = args.bind('file.txt')
        expect(bound[:undefined_key]).to be_nil
      end
    end

    context 'with reserved names' do
      let(:args) do
        described_class.define do
          flag_option :hash
          flag_option :class
          flag_option :freeze
          flag_option :force # not reserved
        end
      end

      it 'does not create accessor methods for reserved names' do
        bound = args.bind(hash: true, class: true, freeze: true, force: true)
        # Reserved names should not have accessors
        expect { bound.hash }.not_to raise_error # hash is an Object method, but returns object hash
        expect(bound.hash).to be_a(Integer) # Object#hash returns an integer
      end

      it 'allows hash-style access for reserved names' do
        bound = args.bind(hash: true, class: true)
        expect(bound[:hash]).to be true
        expect(bound[:class]).to be true
      end

      it 'creates accessor for non-reserved names' do
        bound = args.bind(force: true)
        expect(bound.force).to be true
      end
    end

    context 'with ? predicate accessors for flag options' do
      context 'with a simple flag_option' do
        let(:args) do
          described_class.define do
            flag_option :force
          end
        end

        it 'generates a ? accessor for flag_option' do
          bound = args.bind(force: true)
          expect(bound.force?).to be true
        end

        it 'generates a ? accessor returning false when flag is not set' do
          bound = args.bind
          expect(bound.force?).to be false
        end

        it '? accessor returns same value as plain accessor' do
          bound = args.bind(force: true)
          expect(bound.force?).to eq(bound.force)
        end

        it 'keeps the plain accessor for backward compatibility' do
          bound = args.bind(force: true)
          expect(bound.force).to be true
        end
      end

      context 'with aliased flag options' do
        let(:args) do
          described_class.define do
            flag_option %i[remotes r]
          end
        end

        it 'generates ? accessor on canonical name' do
          bound = args.bind(r: true)
          expect(bound.remotes?).to be true
        end

        it 'does not generate ? accessor for alias name' do
          bound = args.bind(r: true)
          expect { bound.r? }.to raise_error(NoMethodError)
        end
      end

      context 'with negatable flag_option' do
        let(:args) do
          described_class.define do
            flag_option :verbose, negatable: true
          end
        end

        it 'generates a ? accessor for negatable flag_option' do
          bound = args.bind(verbose: true)
          expect(bound.verbose?).to be true
        end

        it '? accessor returns false when negatable flag is false' do
          bound = args.bind(verbose: false)
          expect(bound.verbose?).to be false
        end
      end

      context 'with value_option' do
        let(:args) do
          described_class.define do
            value_option :branch
          end
        end

        it 'does not generate a ? accessor for value_option' do
          bound = args.bind(branch: 'main')
          expect { bound.branch? }.to raise_error(NoMethodError)
        end
      end

      context 'when ? name is a reserved name' do
        it 'does not override nil? from Object' do
          args = described_class.define do
            flag_option :nil
          end
          bound = args.bind(nil: true)
          # nil? is a reserved Object method — must not be overridden
          expect(bound.nil?).to be false
        end
      end
    end

    context 'with immutability' do
      let(:args) do
        described_class.define do
          flag_option :force
        end
      end

      it 'freezes the bound object' do
        bound = args.bind(force: true)
        expect(bound).to be_frozen
      end
    end

    context 'with undefined accessor calls' do
      let(:args) do
        described_class.define do
          flag_option :force
        end
      end

      it 'raises NoMethodError for undefined names' do
        bound = args.bind(force: true)
        expect { bound.undefined_option }.to raise_error(NoMethodError)
      end
    end

    context 'with value options' do
      let(:args) do
        described_class.define do
          value_option :branch
          value_option :message, inline: true
        end
      end

      it 'provides accessor for value options' do
        bound = args.bind(branch: 'main', message: 'test')
        expect(bound.branch).to eq('main')
        expect(bound.message).to eq('test')
      end

      it 'returns nil for unprovided value options' do
        bound = args.bind
        expect(bound.branch).to be_nil
        expect(bound.message).to be_nil
      end
    end

    context 'with execution options' do
      context 'when execution option is bound' do
        let(:args) do
          described_class.define do
            execution_option :timeout
          end
        end

        it 'returns execution option values' do
          bound = args.bind(timeout: 30)
          expect(bound.execution_options).to eq({ timeout: 30 })
        end
      end

      context 'when no execution options are defined' do
        let(:args) do
          described_class.define do
            flag_option :force
          end
        end

        it 'returns an empty hash' do
          bound = args.bind(force: true)
          expect(bound.execution_options).to eq({})
        end
      end

      context 'when execution options are defined but nil' do
        let(:args) do
          described_class.define do
            execution_option :timeout
            execution_option :retries
          end
        end

        it 'returns an empty hash when all values are nil' do
          bound = args.bind
          expect(bound.execution_options).to eq({})
        end

        it 'excludes nil-valued execution options' do
          bound = args.bind(timeout: 15, retries: nil)
          expect(bound.execution_options).to eq({ timeout: 15 })
        end
      end

      it 'returns a frozen hash' do
        args = described_class.define do
          execution_option :timeout
        end

        bound = args.bind(timeout: 30)
        expect(bound.execution_options).to be_frozen
      end
    end

    context 'with default values for positionals' do
      let(:args) do
        described_class.define do
          operand :commit, default: 'HEAD'
        end
      end

      it 'uses default when not provided' do
        bound = args.bind
        expect(bound.commit).to eq('HEAD')
      end

      it 'uses provided value over default' do
        bound = args.bind('main')
        expect(bound.commit).to eq('main')
      end
    end

    context 'with same validation as build' do
      let(:args) do
        described_class.define do
          flag_option :force
          operand :path, required: true
        end
      end

      it 'raises ArgumentError for missing required positional' do
        expect { args.bind(force: true) }.to raise_error(ArgumentError, /path is required/)
      end

      it 'raises ArgumentError for unsupported options' do
        expect { args.bind('file.txt', invalid: true) }.to raise_error(ArgumentError, /Unsupported options/)
      end
    end
  end

  describe 'option-like operand validation' do
    context 'when operand is before a separator: \"--\" boundary' do
      let(:args) do
        described_class.define do
          operand :commit1
          operand :commit2
          operand :paths, repeatable: true, separator: '--'
        end
      end

      it 'rejects a single-dash value' do
        expect { args.bind('-s') }.to raise_error(
          ArgumentError, "operand :commit1 value '-s' looks like a command-line option"
        )
      end

      it 'rejects a double-dash value' do
        expect { args.bind('--stat') }.to raise_error(
          ArgumentError, "operand :commit1 value '--stat' looks like a command-line option"
        )
      end

      it 'validates each operand independently' do
        expect { args.bind('HEAD', '-s') }.to raise_error(
          ArgumentError, "operand :commit2 value '-s' looks like a command-line option"
        )
      end

      it 'does not validate operands after the separator' do
        expect(args.bind('HEAD', 'HEAD~1', '-file.txt').to_a).to eq(
          ['HEAD', 'HEAD~1', '--', '-file.txt']
        )
      end

      it 'allows valid commit values' do
        expect(args.bind('HEAD', 'main').to_a).to eq(%w[HEAD main])
      end
    end

    context 'when operand is before a literal \"--\" boundary' do
      let(:args) do
        described_class.define do
          operand :tree_ish
          literal '--'
          operand :paths, repeatable: true
        end
      end

      it 'validates the operand before literal \"--\"' do
        expect { args.bind('-s') }.to raise_error(
          ArgumentError, "operand :tree_ish value '-s' looks like a command-line option"
        )
      end

      it 'does not validate the operand after literal \"--\"' do
        expect(args.bind('HEAD', '-file.txt').to_a).to eq(['HEAD', '--', '-file.txt'])
      end
    end

    context 'when operand is before a value_option with separator: \"--\"' do
      let(:args) do
        described_class.define do
          operand :commit1
          value_option :pathspecs, as_operand: true, separator: '--', repeatable: true
        end
      end

      it 'validates the operand before the value_option separator' do
        expect { args.bind('-s') }.to raise_error(
          ArgumentError, "operand :commit1 value '-s' looks like a command-line option"
        )
      end

      it 'allows -prefixed values in the value_option after separator' do
        expect(args.bind('HEAD', pathspecs: ['-file.txt']).to_a).to eq(
          ['HEAD', '--', '-file.txt']
        )
      end
    end

    context 'when no \"--\" boundary exists in definition' do
      let(:args) do
        described_class.define do
          operand :path1, required: true
          operand :path2, required: true
        end
      end

      it 'validates all operands' do
        expect { args.bind('-s', 'file.txt') }.to raise_error(
          ArgumentError, "operand :path1 value '-s' looks like a command-line option"
        )
      end

      it 'validates the second operand' do
        expect { args.bind('file.txt', '-s') }.to raise_error(
          ArgumentError, "operand :path2 value '-s' looks like a command-line option"
        )
      end
    end

    context 'when operand value is nil' do
      let(:args) do
        described_class.define do
          operand :tree_ish, allow_nil: true
          operand :paths, repeatable: true, separator: '--'
        end
      end

      it 'skips validation for nil operand values' do
        expect(args.bind(nil, 'file.txt').to_a).to eq(['--', 'file.txt'])
      end
    end

    context 'when operand value is non-String' do
      let(:args) do
        described_class.define do
          operand :count
        end
      end

      it 'skips validation for non-String values' do
        expect(args.bind(42).to_a).to eq(['42'])
      end
    end

    context 'with repeatable operand containing option-like values' do
      let(:args) do
        described_class.define do
          operand :refs, repeatable: true, required: true
        end
      end

      it 'reports all offending values' do
        expect { args.bind('-a', '-b') }.to raise_error(
          ArgumentError, "operand :refs contains option-like values: '-a', '-b'"
        )
      end

      it 'reports only the offending values from a mix' do
        expect { args.bind('HEAD', '-a', 'main') }.to raise_error(
          ArgumentError, "operand :refs contains option-like values: '-a'"
        )
      end
    end

    context 'with error messages' do
      let(:args) do
        described_class.define do
          operand :commit
        end
      end

      it 'includes the operand name in the error' do
        expect { args.bind('-s') }.to raise_error(ArgumentError, /operand :commit/)
      end

      it 'includes the offending value in the error' do
        expect { args.bind('-s') }.to raise_error(ArgumentError, /'-s'/)
      end
    end

    context 'with diff-style ARGS pattern' do
      let(:args) do
        described_class.define do
          literal 'diff'
          literal '--raw'
          operand :commit1
          operand :commit2
          value_option :pathspecs, as_operand: true, separator: '--', repeatable: true
        end
      end

      it 'validates commit operands' do
        expect { args.bind('-s') }.to raise_error(
          ArgumentError, /operand :commit1/
        )
      end

      it 'does not validate pathspecs' do
        expect(args.bind('HEAD', 'HEAD~1', pathspecs: ['-file.txt']).to_a).to eq(
          ['diff', '--raw', 'HEAD', 'HEAD~1', '--', '-file.txt']
        )
      end

      it 'allows valid commit values' do
        expect(args.bind('HEAD', 'HEAD~1').to_a).to eq(
          ['diff', '--raw', 'HEAD', 'HEAD~1']
        )
      end
    end

    context 'with no-index style ARGS pattern (no separator)' do
      let(:args) do
        described_class.define do
          literal 'diff'
          literal '--no-index'
          operand :path1, required: true
          operand :path2, required: true
        end
      end

      it 'validates both operands' do
        expect { args.bind('-bad', 'good') }.to raise_error(
          ArgumentError, /operand :path1/
        )
        expect { args.bind('good', '-bad') }.to raise_error(
          ArgumentError, /operand :path2/
        )
      end

      it 'allows valid paths' do
        expect(args.bind('/tmp/a', '/tmp/b').to_a).to eq(
          ['diff', '--no-index', '/tmp/a', '/tmp/b']
        )
      end
    end

    context 'when separator boundary is inactive due to nil/empty value' do
      let(:args) do
        described_class.define do
          operand :commit
          operand :paths, repeatable: true, separator: '--'
        end
      end

      it 'validates operand after inactive separator when paths are empty' do
        # When paths are not provided, the separator won't be emitted,
        # so :commit has no '--' protection and should still be validated
        expect { args.bind('-s') }.to raise_error(
          ArgumentError, /operand :commit/
        )
      end

      it 'does not validate paths when separator is active' do
        expect(args.bind('HEAD', '-file.txt').to_a).to eq(
          ['HEAD', '--', '-file.txt']
        )
      end
    end

    context 'when value_option separator is inactive due to nil value' do
      let(:args) do
        described_class.define do
          operand :commit1
          operand :commit2
          value_option :pathspecs, as_operand: true, separator: '--', repeatable: true
        end
      end

      it 'validates all operands when pathspecs is nil' do
        expect { args.bind('-s') }.to raise_error(
          ArgumentError, /operand :commit1/
        )
      end

      it 'validates all operands when pathspecs is empty array' do
        expect { args.bind('-s', pathspecs: []) }.to raise_error(
          ArgumentError, /operand :commit1/
        )
      end

      it 'stops validating at active separator when pathspecs present' do
        expect(args.bind('HEAD', 'HEAD~1', pathspecs: ['-file.txt']).to_a).to eq(
          ['HEAD', 'HEAD~1', '--', '-file.txt']
        )
      end
    end

    context 'with checkout-style ARGS pattern (literal --)' do
      let(:args) do
        described_class.define do
          literal 'checkout'
          operand :tree_ish
          literal '--'
          operand :paths, repeatable: true
        end
      end

      it 'validates tree_ish operand' do
        expect { args.bind('-s') }.to raise_error(
          ArgumentError, /operand :tree_ish/
        )
      end

      it 'does not validate paths after literal \"--\"' do
        expect(args.bind('HEAD', '-file.txt').to_a).to eq(
          ['checkout', 'HEAD', '--', '-file.txt']
        )
      end
    end
  end

  describe 'options after separator validation' do
    context 'with literal \'--\'' do
      it 'rejects flag_option after literal \'--\'' do
        expect do
          described_class.define do
            literal '--'
            flag_option :verbose
          end
        end.to raise_error(ArgumentError, /option :verbose cannot be defined after a '--' separator boundary/)
      end

      it 'rejects value_option after literal \'--\'' do
        expect do
          described_class.define do
            literal '--'
            value_option :branch
          end
        end.to raise_error(ArgumentError, /option :branch cannot be defined after/)
      end

      it 'rejects flag_or_value_option after literal \'--\'' do
        expect do
          described_class.define do
            literal '--'
            flag_or_value_option :contains
          end
        end.to raise_error(ArgumentError, /option :contains cannot be defined after/)
      end

      it 'rejects key_value_option after literal \'--\'' do
        expect do
          described_class.define do
            literal '--'
            key_value_option :trailers
          end
        end.to raise_error(ArgumentError, /option :trailers cannot be defined after/)
      end

      it 'rejects custom_option after literal \'--\'' do
        expect do
          described_class.define do
            literal '--'
            custom_option(:extra, &:to_s)
          end
        end.to raise_error(ArgumentError, /option :extra cannot be defined after/)
      end

      it 'rejects negatable flag_option after literal \'--\'' do
        expect do
          described_class.define do
            literal '--'
            flag_option :full, negatable: true
          end
        end.to raise_error(ArgumentError, /option :full cannot be defined after/)
      end

      it 'rejects inline value_option after literal \'--\'' do
        expect do
          described_class.define do
            literal '--'
            value_option :format, inline: true
          end
        end.to raise_error(ArgumentError, /option :format cannot be defined after/)
      end

      it 'allows value_option with as_operand: true after literal \'--\'' do
        expect do
          described_class.define do
            literal '--'
            value_option :paths, as_operand: true, repeatable: true
          end
        end.not_to raise_error
      end

      it 'allows execution_option after literal \'--\'' do
        expect do
          described_class.define do
            literal '--'
            execution_option :internal
          end
        end.not_to raise_error
      end

      it 'allows operand after literal \'--\'' do
        expect do
          described_class.define do
            literal '--'
            operand :paths, repeatable: true
          end
        end.not_to raise_error
      end
    end

    context 'with operand separator \'--\'' do
      it 'rejects flag_option after operand with separator \'--\'' do
        expect do
          described_class.define do
            operand :paths, repeatable: true, separator: '--'
            flag_option :verbose
          end
        end.to raise_error(ArgumentError, /option :verbose cannot be defined after/)
      end

      it 'allows value_option as_operand after operand with separator \'--\'' do
        expect do
          described_class.define do
            operand :paths, repeatable: true, separator: '--'
            value_option :extra, as_operand: true
          end
        end.not_to raise_error
      end
    end

    context 'with value_option as_operand separator \'--\'' do
      it 'rejects flag_option after value_option with as_operand separator \'--\'' do
        expect do
          described_class.define do
            value_option :pathspecs, as_operand: true, separator: '--', repeatable: true
            flag_option :verbose
          end
        end.to raise_error(ArgumentError, /option :verbose cannot be defined after/)
      end

      it 'allows execution_option after value_option with as_operand separator \'--\'' do
        expect do
          described_class.define do
            value_option :pathspecs, as_operand: true, separator: '--', repeatable: true
            execution_option :internal
          end
        end.not_to raise_error
      end
    end

    context 'without \'--\' boundary' do
      it 'allows flag_option without any separator' do
        expect do
          described_class.define do
            operand :path
            flag_option :verbose
          end
        end.not_to raise_error
      end

      it 'allows options before literal \'--\'' do
        expect do
          described_class.define do
            flag_option :force
            value_option :branch
            literal '--'
            operand :paths, repeatable: true
          end
        end.not_to raise_error
      end
    end

    context 'with non-separator literal' do
      it 'allows flag_option after non-separator literal' do
        expect do
          described_class.define do
            literal 'branch'
            flag_option :verbose
          end
        end.not_to raise_error
      end
    end

    it 'includes helpful error message about git treating post-separator as operands' do
      expect do
        described_class.define do
          literal '--'
          flag_option :verbose
        end
      end.to raise_error(
        ArgumentError,
        /its flags would be treated as operands by git/
      )
    end
  end

  describe Git::Commands::Arguments::Bound do
    describe 'RESERVED_NAMES' do
      it 'includes Object instance methods' do
        expect(Git::Commands::Arguments::Bound::RESERVED_NAMES).to include(:hash)
        expect(Git::Commands::Arguments::Bound::RESERVED_NAMES).to include(:class)
        expect(Git::Commands::Arguments::Bound::RESERVED_NAMES).to include(:freeze)
        expect(Git::Commands::Arguments::Bound::RESERVED_NAMES).to include(:object_id)
      end

      it 'includes :to_ary' do
        expect(Git::Commands::Arguments::Bound::RESERVED_NAMES).to include(:to_ary)
      end

      it 'is frozen' do
        expect(Git::Commands::Arguments::Bound::RESERVED_NAMES).to be_frozen
      end
    end
  end
end
