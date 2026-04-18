# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/repack'

RSpec.describe Git::Commands::Repack do
  # Duck-type collaborator: command specs depend on the #command_capturing interface,
  # not a single concrete ExecutionContext class.
  let(:execution_context) { execution_context_double }
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
      it 'adds -a when true' do
        expect_command_capturing('repack', '-a').and_return(command_result)

        command.call(a: true)
      end
    end

    context 'with the :A option' do
      it 'adds -A when true' do
        expect_command_capturing('repack', '-A').and_return(command_result)

        command.call(A: true)
      end
    end

    context 'with the :d option' do
      it 'adds -d when true' do
        expect_command_capturing('repack', '-d').and_return(command_result)

        command.call(d: true)
      end
    end

    context 'with the :cruft option' do
      it 'adds --cruft when true' do
        expect_command_capturing('repack', '--cruft').and_return(command_result)

        command.call(cruft: true)
      end
    end

    context 'with the :cruft_expiration option' do
      it 'passes --cruft-expiration=<date>' do
        expect_command_capturing('repack', '--cruft-expiration=2.weeks.ago').and_return(command_result)

        command.call(cruft_expiration: '2.weeks.ago')
      end
    end

    context 'with the :max_cruft_size option' do
      it 'passes --max-cruft-size=<n>' do
        expect_command_capturing('repack', '--max-cruft-size=1g').and_return(command_result)

        command.call(max_cruft_size: '1g')
      end
    end

    context 'with the :combine_cruft_below_size option' do
      it 'passes --combine-cruft-below-size=<n>' do
        expect_command_capturing('repack', '--combine-cruft-below-size=100m').and_return(command_result)

        command.call(combine_cruft_below_size: '100m')
      end
    end

    context 'with the :expire_to option' do
      it 'passes --expire-to=<dir>' do
        expect_command_capturing('repack', '--expire-to=/tmp/pruned').and_return(command_result)

        command.call(expire_to: '/tmp/pruned')
      end
    end

    context 'with the :l option' do
      it 'adds -l when true' do
        expect_command_capturing('repack', '-l').and_return(command_result)

        command.call(l: true)
      end
    end

    context 'with the :f option' do
      it 'adds -f when true' do
        expect_command_capturing('repack', '-f').and_return(command_result)

        command.call(f: true)
      end
    end

    context 'with the :F option' do
      it 'adds -F when true' do
        expect_command_capturing('repack', '-F').and_return(command_result)

        command.call(F: true)
      end
    end

    context 'with the :quiet option' do
      it 'adds --quiet when true' do
        expect_command_capturing('repack', '--quiet').and_return(command_result)

        command.call(quiet: true)
      end

      it 'supports the :q alias' do
        expect_command_capturing('repack', '--quiet').and_return(command_result)

        command.call(q: true)
      end
    end

    context 'with the :n option' do
      it 'adds -n when true' do
        expect_command_capturing('repack', '-n').and_return(command_result)

        command.call(n: true)
      end
    end

    context 'with the :window option' do
      it 'passes --window=<n>' do
        expect_command_capturing('repack', '--window=250').and_return(command_result)

        command.call(window: 250)
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

    context 'with the :window_memory option' do
      it 'passes --window-memory=<n>' do
        expect_command_capturing('repack', '--window-memory=256m').and_return(command_result)

        command.call(window_memory: '256m')
      end
    end

    context 'with the :max_pack_size option' do
      it 'passes --max-pack-size=<n>' do
        expect_command_capturing('repack', '--max-pack-size=2g').and_return(command_result)

        command.call(max_pack_size: '2g')
      end
    end

    context 'with the :filter option' do
      it 'passes --filter=<filter-spec>' do
        expect_command_capturing('repack', '--filter=blob:none').and_return(command_result)

        command.call(filter: 'blob:none')
      end
    end

    context 'with the :filter_to option' do
      it 'passes --filter-to=<dir>' do
        expect_command_capturing('repack', '--filter-to=/tmp/filter').and_return(command_result)

        command.call(filter_to: '/tmp/filter')
      end
    end

    context 'with the :write_bitmap_index option' do
      it 'adds --write-bitmap-index when true' do
        expect_command_capturing('repack', '--write-bitmap-index').and_return(command_result)

        command.call(write_bitmap_index: true)
      end

      it 'supports the :b alias' do
        expect_command_capturing('repack', '--write-bitmap-index').and_return(command_result)

        command.call(b: true)
      end
    end

    context 'with the :pack_kept_objects option' do
      it 'adds --pack-kept-objects when true' do
        expect_command_capturing('repack', '--pack-kept-objects').and_return(command_result)

        command.call(pack_kept_objects: true)
      end
    end

    context 'with the :keep_pack option' do
      it 'passes a single --keep-pack=<name>' do
        expect_command_capturing('repack', '--keep-pack=pack-abc123.pack').and_return(command_result)

        command.call(keep_pack: 'pack-abc123.pack')
      end

      it 'passes multiple --keep-pack=<name> arguments when given an array' do
        expect_command_capturing(
          'repack', '--keep-pack=pack-abc123.pack', '--keep-pack=pack-def456.pack'
        ).and_return(command_result)

        command.call(keep_pack: %w[pack-abc123.pack pack-def456.pack])
      end
    end

    context 'with the :write_midx option' do
      it 'adds --write-midx when true' do
        expect_command_capturing('repack', '--write-midx').and_return(command_result)

        command.call(write_midx: true)
      end

      it 'supports the :m alias' do
        expect_command_capturing('repack', '--write-midx').and_return(command_result)

        command.call(m: true)
      end
    end

    context 'with the :unpack_unreachable option' do
      it 'passes --unpack-unreachable=<when>' do
        expect_command_capturing('repack', '--unpack-unreachable=2.weeks.ago').and_return(command_result)

        command.call(unpack_unreachable: '2.weeks.ago')
      end
    end

    context 'with the :keep_unreachable option' do
      it 'adds --keep-unreachable when true' do
        expect_command_capturing('repack', '--keep-unreachable').and_return(command_result)

        command.call(keep_unreachable: true)
      end

      it 'supports the :k alias' do
        expect_command_capturing('repack', '--keep-unreachable').and_return(command_result)

        command.call(k: true)
      end
    end

    context 'with the :delta_islands option' do
      it 'adds --delta-islands when true' do
        expect_command_capturing('repack', '--delta-islands').and_return(command_result)

        command.call(delta_islands: true)
      end

      it 'supports the :i alias' do
        expect_command_capturing('repack', '--delta-islands').and_return(command_result)

        command.call(i: true)
      end
    end

    context 'with the :geometric option' do
      it 'passes --geometric=<factor>' do
        expect_command_capturing('repack', '--geometric=2').and_return(command_result)

        command.call(geometric: 2)
      end

      it 'supports the :g alias' do
        expect_command_capturing('repack', '--geometric=2').and_return(command_result)

        command.call(g: 2)
      end
    end

    context 'with the :name_hash_version option' do
      it 'passes --name-hash-version=<n>' do
        expect_command_capturing('repack', '--name-hash-version=2').and_return(command_result)

        command.call(name_hash_version: 2)
      end
    end

    context 'with the :path_walk option' do
      it 'adds --path-walk when true' do
        expect_command_capturing('repack', '--path-walk').and_return(command_result)

        command.call(path_walk: true)
      end
    end

    context 'with multiple options combined' do
      it 'passes all flags in DSL-defined order' do
        expect_command_capturing('repack', '-a', '-d', '--quiet').and_return(command_result)

        command.call(a: true, d: true, quiet: true)
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
