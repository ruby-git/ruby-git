# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/ls_files'

RSpec.describe Git::Commands::LsFiles do
  # Duck-type collaborator: command specs depend on the #command_capturing interface,
  # not a single concrete ExecutionContext class.
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with no arguments' do
      it 'runs git ls-files with no flags' do
        expected_result = command_result
        expect_command_capturing('ls-files').and_return(expected_result)

        result = command.call

        expect(result).to eq(expected_result)
      end
    end

    context 'with the :z option' do
      it 'adds -z to the command line' do
        expect_command_capturing('ls-files', '-z').and_return(command_result)

        command.call(z: true)
      end
    end

    context 'with the :t option' do
      it 'adds -t to the command line' do
        expect_command_capturing('ls-files', '-t').and_return(command_result)

        command.call(t: true)
      end
    end

    context 'with the :v option' do
      it 'adds -v to the command line' do
        expect_command_capturing('ls-files', '-v').and_return(command_result)

        command.call(v: true)
      end
    end

    context 'with the :f option' do
      it 'adds -f to the command line' do
        expect_command_capturing('ls-files', '-f').and_return(command_result)

        command.call(f: true)
      end
    end

    context 'with the :cached option' do
      it 'adds --cached to the command line' do
        expect_command_capturing('ls-files', '--cached').and_return(command_result)

        command.call(cached: true)
      end

      it 'supports the :c alias' do
        expect_command_capturing('ls-files', '--cached').and_return(command_result)

        command.call(c: true)
      end
    end

    context 'with the :deleted option' do
      it 'adds --deleted to the command line' do
        expect_command_capturing('ls-files', '--deleted').and_return(command_result)

        command.call(deleted: true)
      end

      it 'supports the :d alias' do
        expect_command_capturing('ls-files', '--deleted').and_return(command_result)

        command.call(d: true)
      end
    end

    context 'with the :others option' do
      it 'adds --others to the command line' do
        expect_command_capturing('ls-files', '--others').and_return(command_result)

        command.call(others: true)
      end

      it 'supports the :o alias' do
        expect_command_capturing('ls-files', '--others').and_return(command_result)

        command.call(o: true)
      end
    end

    context 'with the :ignored option' do
      it 'adds --ignored to the command line' do
        expect_command_capturing('ls-files', '--ignored').and_return(command_result)

        command.call(ignored: true)
      end

      it 'supports the :i alias' do
        expect_command_capturing('ls-files', '--ignored').and_return(command_result)

        command.call(i: true)
      end
    end

    context 'with the :stage option' do
      it 'adds --stage to the command line' do
        expect_command_capturing('ls-files', '--stage').and_return(command_result)

        command.call(stage: true)
      end

      it 'supports the :s alias' do
        expect_command_capturing('ls-files', '--stage').and_return(command_result)

        command.call(s: true)
      end
    end

    context 'with the :unmerged option' do
      it 'adds --unmerged to the command line' do
        expect_command_capturing('ls-files', '--unmerged').and_return(command_result)

        command.call(unmerged: true)
      end

      it 'supports the :u alias' do
        expect_command_capturing('ls-files', '--unmerged').and_return(command_result)

        command.call(u: true)
      end
    end

    context 'with the :killed option' do
      it 'adds --killed to the command line' do
        expect_command_capturing('ls-files', '--killed').and_return(command_result)

        command.call(killed: true)
      end

      it 'supports the :k alias' do
        expect_command_capturing('ls-files', '--killed').and_return(command_result)

        command.call(k: true)
      end
    end

    context 'with the :modified option' do
      it 'adds --modified to the command line' do
        expect_command_capturing('ls-files', '--modified').and_return(command_result)

        command.call(modified: true)
      end

      it 'supports the :m alias' do
        expect_command_capturing('ls-files', '--modified').and_return(command_result)

        command.call(m: true)
      end
    end

    context 'with the :resolve_undo option' do
      it 'adds --resolve-undo to the command line' do
        expect_command_capturing('ls-files', '--resolve-undo').and_return(command_result)

        command.call(resolve_undo: true)
      end
    end

    context 'with the :directory option' do
      it 'adds --directory to the command line' do
        expect_command_capturing('ls-files', '--directory').and_return(command_result)

        command.call(directory: true)
      end
    end

    context 'with the :no_empty_directory option' do
      it 'adds --no-empty-directory to the command line' do
        expect_command_capturing('ls-files', '--no-empty-directory').and_return(command_result)

        command.call(no_empty_directory: true)
      end
    end

    context 'with the :eol option' do
      it 'adds --eol to the command line' do
        expect_command_capturing('ls-files', '--eol').and_return(command_result)

        command.call(eol: true)
      end
    end

    context 'with the :deduplicate option' do
      it 'adds --deduplicate to the command line' do
        expect_command_capturing('ls-files', '--deduplicate').and_return(command_result)

        command.call(deduplicate: true)
      end
    end

    context 'with the :sparse option' do
      it 'adds --sparse to the command line' do
        expect_command_capturing('ls-files', '--sparse').and_return(command_result)

        command.call(sparse: true)
      end
    end

    context 'with the :debug option' do
      it 'adds --debug to the command line' do
        expect_command_capturing('ls-files', '--debug').and_return(command_result)

        command.call(debug: true)
      end
    end

    context 'with the :exclude option' do
      it 'adds --exclude=<pattern> to the command line' do
        expect_command_capturing('ls-files', '--exclude=*.log').and_return(command_result)

        command.call(exclude: '*.log')
      end

      it 'supports the :x alias' do
        expect_command_capturing('ls-files', '--exclude=*.log').and_return(command_result)

        command.call(x: '*.log')
      end
    end

    context 'with the :exclude_from option' do
      it 'adds --exclude-from=<file> to the command line' do
        expect_command_capturing('ls-files', '--exclude-from=.gitignore').and_return(command_result)

        command.call(exclude_from: '.gitignore')
      end

      it 'supports the :X alias' do
        expect_command_capturing('ls-files', '--exclude-from=.gitignore').and_return(command_result)

        command.call(X: '.gitignore')
      end
    end

    context 'with the :exclude_per_directory option' do
      it 'adds --exclude-per-directory=<name> to the command line' do
        expect_command_capturing('ls-files', '--exclude-per-directory=.ignore').and_return(command_result)

        command.call(exclude_per_directory: '.ignore')
      end
    end

    context 'with the :exclude_standard option' do
      it 'adds --exclude-standard to the command line' do
        expect_command_capturing('ls-files', '--exclude-standard').and_return(command_result)

        command.call(exclude_standard: true)
      end
    end

    context 'with the :error_unmatch option' do
      it 'adds --error-unmatch to the command line' do
        expect_command_capturing('ls-files', '--error-unmatch').and_return(command_result)

        command.call(error_unmatch: true)
      end
    end

    context 'with the :with_tree option' do
      it 'adds --with-tree=<tree-ish> to the command line' do
        expect_command_capturing('ls-files', '--with-tree=HEAD~1').and_return(command_result)

        command.call(with_tree: 'HEAD~1')
      end
    end

    context 'with the :full_name option' do
      it 'adds --full-name to the command line' do
        expect_command_capturing('ls-files', '--full-name').and_return(command_result)

        command.call(full_name: true)
      end
    end

    context 'with the :recurse_submodules option' do
      it 'adds --recurse-submodules to the command line' do
        expect_command_capturing('ls-files', '--recurse-submodules').and_return(command_result)

        command.call(recurse_submodules: true)
      end
    end

    context 'with the :abbrev option' do
      it 'adds --abbrev when true' do
        expect_command_capturing('ls-files', '--abbrev').and_return(command_result)

        command.call(abbrev: true)
      end

      it 'adds --abbrev=<n> when a string is given' do
        expect_command_capturing('ls-files', '--abbrev=8').and_return(command_result)

        command.call(abbrev: '8')
      end
    end

    context 'with the :format option' do
      it 'adds --format=<format> to the command line' do
        expect_command_capturing('ls-files', '--format=%(path)').and_return(command_result)

        command.call(format: '%(path)')
      end
    end

    context 'with the :chdir execution option' do
      it 'passes chdir to the execution context, not to the git CLI' do
        expect_command_capturing('ls-files', '--others', '--exclude-standard',
                                 chdir: '/some/work/dir').and_return(command_result)

        command.call(others: true, exclude_standard: true, chdir: '/some/work/dir')
      end
    end

    context 'with a file operand' do
      it 'appends -- and the file after options' do
        expect_command_capturing('ls-files', '--stage', '--', '.').and_return(command_result)

        command.call('.', stage: true)
      end
    end

    context 'with multiple file operands' do
      it 'appends -- and all files' do
        expect_command_capturing('ls-files', '--', 'lib/', 'spec/').and_return(command_result)

        command.call('lib/', 'spec/')
      end
    end

    context 'with :others, :ignored, and :exclude_standard combined' do
      it 'builds --others --ignored --exclude-standard' do
        expect_command_capturing('ls-files', '--others', '--ignored',
                                 '--exclude-standard').and_return(command_result)

        command.call(others: true, ignored: true, exclude_standard: true)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError for unsupported options' do
        expect { command.call(unknown_flag: true) }.to(
          raise_error(ArgumentError, /Unsupported options/)
        )
      end
    end
  end
end
