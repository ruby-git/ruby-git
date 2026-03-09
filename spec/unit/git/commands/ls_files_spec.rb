# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/ls_files'

RSpec.describe Git::Commands::LsFiles do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with no arguments' do
      it 'runs git ls-files with no extra arguments and returns the result' do
        expected_result = command_result("100644 abc123 0\tfile.txt")
        expect_command_capturing('ls-files').and_return(expected_result)

        result = command.call

        expect(result).to eq(expected_result)
      end
    end

    context 'with a path operand' do
      it 'passes the path as a positional argument' do
        expected_result = command_result("100644 abc123 0\tlib/foo.rb")
        expect_command_capturing('ls-files', 'lib/').and_return(expected_result)

        result = command.call('lib/')

        expect(result).to eq(expected_result)
      end
    end

    context 'with multiple path operands' do
      it 'passes all paths as positional arguments' do
        expect_command_capturing('ls-files', 'lib/', 'spec/').and_return(command_result(''))

        command.call('lib/', 'spec/')
      end
    end

    # Output format flags

    context 'with :z option' do
      it 'includes -z flag' do
        expect_command_capturing('ls-files', '-z').and_return(command_result(''))

        command.call(z: true)
      end
    end

    context 'with :t option' do
      it 'includes -t flag' do
        expect_command_capturing('ls-files', '-t').and_return(command_result(''))

        command.call(t: true)
      end
    end

    context 'with :v option' do
      it 'includes -v flag' do
        expect_command_capturing('ls-files', '-v').and_return(command_result(''))

        command.call(v: true)
      end
    end

    context 'with :f option' do
      it 'includes -f flag' do
        expect_command_capturing('ls-files', '-f').and_return(command_result(''))

        command.call(f: true)
      end
    end

    # Mode options

    context 'with :cached option' do
      it 'includes --cached flag' do
        expect_command_capturing('ls-files', '--cached').and_return(command_result("file.txt\n"))

        command.call(cached: true)
      end

      it 'accepts :c as alias for :cached' do
        expect_command_capturing('ls-files', '--cached').and_return(command_result(''))

        command.call(c: true)
      end
    end

    context 'with :deleted option' do
      it 'includes --deleted flag' do
        expect_command_capturing('ls-files', '--deleted').and_return(command_result(''))

        command.call(deleted: true)
      end

      it 'accepts :d as alias for :deleted' do
        expect_command_capturing('ls-files', '--deleted').and_return(command_result(''))

        command.call(d: true)
      end
    end

    context 'with :others option' do
      it 'includes --others flag' do
        expect_command_capturing('ls-files', '--others').and_return(command_result(''))

        command.call(others: true)
      end

      it 'accepts :o as alias for :others' do
        expect_command_capturing('ls-files', '--others').and_return(command_result(''))

        command.call(o: true)
      end
    end

    context 'with :ignored option' do
      it 'includes --ignored flag' do
        expect_command_capturing('ls-files', '--ignored').and_return(command_result(''))

        command.call(ignored: true)
      end

      it 'accepts :i as alias for :ignored' do
        expect_command_capturing('ls-files', '--ignored').and_return(command_result(''))

        command.call(i: true)
      end
    end

    context 'with :stage option' do
      it 'includes --stage flag' do
        expect_command_capturing('ls-files', '--stage').and_return(command_result("100644 abc123 0\tfile.txt"))

        command.call(stage: true)
      end

      it 'accepts :s as alias for :stage' do
        expect_command_capturing('ls-files', '--stage').and_return(command_result(''))

        command.call(s: true)
      end
    end

    context 'with :stage option and a path' do
      it 'includes --stage flag and path operand' do
        staged_output = "100644 abc123 0\tlib/foo.rb"
        expect_command_capturing('ls-files', '--stage', 'lib/').and_return(command_result(staged_output))

        command.call('lib/', stage: true)
      end
    end

    context 'with :directory option' do
      it 'includes --directory flag' do
        expect_command_capturing('ls-files', '--directory').and_return(command_result(''))

        command.call(directory: true)
      end
    end

    context 'with :no_empty_directory option' do
      it 'includes --no-empty-directory flag' do
        expect_command_capturing('ls-files', '--directory', '--no-empty-directory')
          .and_return(command_result(''))

        command.call(directory: true, no_empty_directory: true)
      end
    end

    context 'with :unmerged option' do
      it 'includes --unmerged flag' do
        expect_command_capturing('ls-files', '--unmerged').and_return(command_result(''))

        command.call(unmerged: true)
      end

      it 'accepts :u as alias for :unmerged' do
        expect_command_capturing('ls-files', '--unmerged').and_return(command_result(''))

        command.call(u: true)
      end
    end

    context 'with :killed option' do
      it 'includes --killed flag' do
        expect_command_capturing('ls-files', '--killed').and_return(command_result(''))

        command.call(killed: true)
      end

      it 'accepts :k as alias for :killed' do
        expect_command_capturing('ls-files', '--killed').and_return(command_result(''))

        command.call(k: true)
      end
    end

    context 'with :modified option' do
      it 'includes --modified flag' do
        expect_command_capturing('ls-files', '--modified').and_return(command_result(''))

        command.call(modified: true)
      end

      it 'accepts :m as alias for :modified' do
        expect_command_capturing('ls-files', '--modified').and_return(command_result(''))

        command.call(m: true)
      end
    end

    context 'with :resolve_undo option' do
      it 'includes --resolve-undo flag' do
        expect_command_capturing('ls-files', '--resolve-undo').and_return(command_result(''))

        command.call(resolve_undo: true)
      end
    end

    context 'with :deduplicate option' do
      it 'includes --deduplicate flag' do
        expect_command_capturing('ls-files', '--deduplicate').and_return(command_result(''))

        command.call(deduplicate: true)
      end
    end

    context 'with :eol option' do
      it 'includes --eol flag' do
        expect_command_capturing('ls-files', '--eol').and_return(command_result(''))

        command.call(eol: true)
      end
    end

    # Exclude patterns

    context 'with :exclude option' do
      it 'includes --exclude=<pattern> with the given value' do
        expect_command_capturing('ls-files', '--exclude=*.log').and_return(command_result(''))

        command.call(exclude: '*.log')
      end

      it 'accepts :x as alias for :exclude' do
        expect_command_capturing('ls-files', '--exclude=*.tmp').and_return(command_result(''))

        command.call(x: '*.tmp')
      end

      it 'includes multiple --exclude flags when given an array' do
        expect_command_capturing('ls-files', '--exclude=*.log', '--exclude=*.tmp')
          .and_return(command_result(''))

        command.call(exclude: ['*.log', '*.tmp'])
      end
    end

    context 'with :exclude_from option' do
      it 'includes --exclude-from=<file> with the given value' do
        expect_command_capturing('ls-files', '--exclude-from=.gitignore')
          .and_return(command_result(''))

        command.call(exclude_from: '.gitignore')
      end

      it 'accepts :X as alias for :exclude_from' do
        expect_command_capturing('ls-files', '--exclude-from=.gitignore')
          .and_return(command_result(''))

        command.call(X: '.gitignore')
      end
    end

    context 'with :exclude_per_directory option' do
      it 'includes --exclude-per-directory=<file> with the given value' do
        expect_command_capturing('ls-files', '--exclude-per-directory=.gitignore')
          .and_return(command_result(''))

        command.call(exclude_per_directory: '.gitignore')
      end
    end

    context 'with :exclude_standard option' do
      it 'includes --exclude-standard flag' do
        expect_command_capturing('ls-files', '--exclude-standard').and_return(command_result(''))

        command.call(exclude_standard: true)
      end
    end

    context 'with :error_unmatch option' do
      it 'includes --error-unmatch flag' do
        expect_command_capturing('ls-files', '--error-unmatch').and_return(command_result(''))

        command.call(error_unmatch: true)
      end
    end

    context 'with :with_tree option' do
      it 'includes --with-tree=<tree-ish> with the given value' do
        expect_command_capturing('ls-files', '--error-unmatch', '--with-tree=HEAD')
          .and_return(command_result(''))

        command.call(error_unmatch: true, with_tree: 'HEAD')
      end
    end

    # Output customisation

    context 'with :full_name option' do
      it 'includes --full-name flag' do
        expect_command_capturing('ls-files', '--full-name').and_return(command_result(''))

        command.call(full_name: true)
      end
    end

    context 'with :recurse_submodules option' do
      it 'includes --recurse-submodules flag' do
        expect_command_capturing('ls-files', '--recurse-submodules').and_return(command_result(''))

        command.call(recurse_submodules: true)
      end
    end

    context 'with :abbrev option' do
      it 'includes --abbrev flag when given true' do
        expect_command_capturing('ls-files', '--abbrev').and_return(command_result(''))

        command.call(abbrev: true)
      end

      it 'includes --abbrev=<n> flag when given a string' do
        expect_command_capturing('ls-files', '--abbrev=8').and_return(command_result(''))

        command.call(abbrev: '8')
      end
    end

    context 'with :format option' do
      it 'includes --format=<format> with the given value' do
        expect_command_capturing('ls-files', '--format=%(objectname) %(path)')
          .and_return(command_result(''))

        command.call(format: '%(objectname) %(path)')
      end
    end

    context 'with :sparse option' do
      it 'includes --sparse flag' do
        expect_command_capturing('ls-files', '--sparse').and_return(command_result(''))

        command.call(sparse: true)
      end
    end

    context 'with :debug option' do
      it 'includes --debug flag' do
        expect_command_capturing('ls-files', '--debug').and_return(command_result(''))

        command.call(debug: true)
      end
    end

    context 'with combined options and path' do
      it 'combines stage flag and path correctly' do
        expect_command_capturing('ls-files', '--stage', '--full-name', 'src/')
          .and_return(command_result(''))

        command.call('src/', stage: true, full_name: true)
      end
    end
  end
end
