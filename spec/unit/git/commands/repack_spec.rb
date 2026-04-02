# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/repack'

RSpec.describe Git::Commands::Repack do
  # Duck-type collaborator: command specs depend on the #command_capturing
  # interface, not a single concrete ExecutionContext class.
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with no options' do
      it 'runs git repack with no extra arguments' do
        expected_result = command_result
        expect_command_capturing('repack').and_return(expected_result)

        result = command.call

        expect(result).to eq(expected_result)
      end
    end

    context 'with the :a option' do
      it 'passes -a when true' do
        expect_command_capturing('repack', '-a').and_return(command_result)

        command.call(a: true)
      end
    end

    context 'with the :A option' do
      it 'passes -A when true' do
        expect_command_capturing('repack', '-A').and_return(command_result)

        command.call(A: true)
      end
    end

    context 'with the :d option' do
      it 'passes -d when true' do
        expect_command_capturing('repack', '-d').and_return(command_result)

        command.call(d: true)
      end
    end

    context 'with the :l option' do
      it 'passes -l when true' do
        expect_command_capturing('repack', '-l').and_return(command_result)

        command.call(l: true)
      end
    end

    context 'with the :f option' do
      it 'passes -f when true' do
        expect_command_capturing('repack', '-f').and_return(command_result)

        command.call(f: true)
      end
    end

    context 'with the :F option' do
      it 'passes -F when true' do
        expect_command_capturing('repack', '-F').and_return(command_result)

        command.call(F: true)
      end
    end

    context 'with the :q option' do
      it 'passes -q when true' do
        expect_command_capturing('repack', '-q').and_return(command_result)

        command.call(q: true)
      end
    end

    context 'with the :n option' do
      it 'passes -n when true' do
        expect_command_capturing('repack', '-n').and_return(command_result)

        command.call(n: true)
      end
    end

    context 'with the :write_bitmap_index option' do
      it 'passes --write-bitmap-index when true' do
        expect_command_capturing('repack', '--write-bitmap-index').and_return(command_result)

        command.call(write_bitmap_index: true)
      end
    end

    context 'with the :b alias for :write_bitmap_index' do
      it 'passes --write-bitmap-index' do
        expect_command_capturing('repack', '--write-bitmap-index').and_return(command_result)

        command.call(b: true)
      end
    end

    context 'with the :pack_kept_objects option' do
      it 'passes --pack-kept-objects when true' do
        expect_command_capturing('repack', '--pack-kept-objects').and_return(command_result)

        command.call(pack_kept_objects: true)
      end
    end

    context 'with the :keep_pack option as a single pack name' do
      it 'passes --keep-pack=<name>' do
        expect_command_capturing('repack', '--keep-pack=pack-abc123.pack').and_return(command_result)

        command.call(keep_pack: 'pack-abc123.pack')
      end
    end

    context 'with the :keep_pack option as multiple pack names' do
      it 'repeats --keep-pack for each pack name' do
        expect_command_capturing(
          'repack', '--keep-pack=pack-abc123.pack', '--keep-pack=pack-def456.pack'
        ).and_return(command_result)

        command.call(keep_pack: %w[pack-abc123.pack pack-def456.pack])
      end
    end

    context 'with the :unpack_unreachable option' do
      it 'passes --unpack-unreachable=<date>' do
        expect_command_capturing('repack', '--unpack-unreachable=2.weeks.ago').and_return(command_result)

        command.call(unpack_unreachable: '2.weeks.ago')
      end
    end

    context 'with the :keep_unreachable option' do
      it 'passes --keep-unreachable when true' do
        expect_command_capturing('repack', '--keep-unreachable').and_return(command_result)

        command.call(keep_unreachable: true)
      end
    end

    context 'with the :k alias for :keep_unreachable' do
      it 'passes --keep-unreachable' do
        expect_command_capturing('repack', '--keep-unreachable').and_return(command_result)

        command.call(k: true)
      end
    end

    context 'with the :delta_islands option' do
      it 'passes --delta-islands when true' do
        expect_command_capturing('repack', '--delta-islands').and_return(command_result)

        command.call(delta_islands: true)
      end
    end

    context 'with the :i alias for :delta_islands' do
      it 'passes --delta-islands' do
        expect_command_capturing('repack', '--delta-islands').and_return(command_result)

        command.call(i: true)
      end
    end

    context 'with the :window option' do
      it 'passes --window=<n>' do
        expect_command_capturing('repack', '--window=250').and_return(command_result)

        command.call(window: 250)
      end
    end

    context 'with the :window_memory option' do
      it 'passes --window-memory=<value>' do
        expect_command_capturing('repack', '--window-memory=1g').and_return(command_result)

        command.call(window_memory: '1g')
      end
    end

    context 'with the :max_pack_size option' do
      it 'passes --max-pack-size=<value>' do
        expect_command_capturing('repack', '--max-pack-size=2g').and_return(command_result)

        command.call(max_pack_size: '2g')
      end
    end

    context 'with the :depth option' do
      it 'passes --depth=<n>' do
        expect_command_capturing('repack', '--depth=50').and_return(command_result)

        command.call(depth: 50)
      end
    end

    context 'with the :threads option' do
      it 'passes --threads=<n>' do
        expect_command_capturing('repack', '--threads=4').and_return(command_result)

        command.call(threads: 4)
      end
    end

    context 'with :a, :d, and :q combined' do
      it 'passes all flags in DSL-defined order' do
        expect_command_capturing('repack', '-a', '-d', '-q').and_return(command_result)

        command.call(a: true, d: true, q: true)
      end
    end

    context 'with :a and :write_bitmap_index combined' do
      it 'passes both flags in DSL-defined order' do
        expect_command_capturing('repack', '-a', '--write-bitmap-index').and_return(command_result)

        command.call(a: true, write_bitmap_index: true)
      end
    end

    context 'input validation' do
      it 'raises ArgumentError for unsupported options' do
        expect { command.call(unknown: true) }
          .to raise_error(ArgumentError, /Unsupported options/)
      end
    end
  end
end
