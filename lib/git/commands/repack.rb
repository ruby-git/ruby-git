# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    # Wrapper for the `git repack` command
    #
    # Packs unpacked objects in a repository into pack files, and can reorganize
    # existing packs into a single, more efficient pack. Running `git repack -a -d`
    # is the most common usage: pack all objects and delete redundant packs.
    #
    # @example Pack all objects and delete redundant packs
    #   repack = Git::Commands::Repack.new(execution_context)
    #   repack.call(a: true, d: true)
    #
    # @example Pack all objects with bitmap index
    #   repack = Git::Commands::Repack.new(execution_context)
    #   repack.call(a: true, d: true, write_bitmap_index: true)
    #
    # @example Control delta compression performance
    #   repack = Git::Commands::Repack.new(execution_context)
    #   repack.call(a: true, d: true, window: 250, depth: 50)
    #
    # @note `arguments` block audited against
    #   https://git-scm.com/docs/git-repack/2.53.0
    #
    # @see https://git-scm.com/docs/git-repack git-repack
    #
    # @see Git::Commands
    #
    # @api private
    #
    class Repack < Git::Commands::Base
      arguments do
        literal 'repack'

        # Pack selection
        flag_option :a
        flag_option :A
        flag_option :d
        flag_option :cruft
        value_option :cruft_expiration, inline: true
        value_option :max_cruft_size, inline: true
        value_option :combine_cruft_below_size, inline: true
        value_option :expire_to, inline: true

        # Object transfer
        flag_option :l
        flag_option :f
        flag_option :F

        # Output control
        flag_option %i[quiet q]
        flag_option :n

        # Delta compression
        value_option :window, inline: true
        value_option :depth, inline: true
        value_option :threads, inline: true
        value_option :window_memory, inline: true
        value_option :max_pack_size, inline: true

        # Object filtering
        value_option :filter, inline: true
        value_option :filter_to, inline: true

        # Bitmaps and multi-pack index
        flag_option %i[write_bitmap_index b]
        flag_option :pack_kept_objects
        value_option :keep_pack, inline: true, repeatable: true
        flag_option %i[write_midx m]

        # Unreachable objects
        value_option :unpack_unreachable, inline: true
        flag_option %i[keep_unreachable k]

        # Delta and geometry
        flag_option %i[delta_islands i]
        value_option %i[geometric g], inline: true

        # Pack-objects pass-through
        value_option :name_hash_version, inline: true
        flag_option :path_walk
      end

      # @!method call(*, **)
      #
      #   @overload call(**options)
      #
      #     Execute the `git repack` command
      #
      #     @param options [Hash] command options
      #
      #     @option options [Boolean] :a (false) pack all objects into a single pack
      #
      #       When `true`, passes `-a`. Especially useful when packing a repository
      #       used for private development. Use with `:d` to clean up objects.
      #
      #     @option options [Boolean] :A (false) pack all objects, loosening unreachable
      #       objects when combined with `:d`
      #
      #       When `true`, passes `-A`. Like `:a`, but any unreachable objects in a
      #       previous pack become loose unpacked objects instead of being removed. The
      #       loose unreachable objects are pruned by the next `git gc` invocation.
      #
      #     @option options [Boolean] :d (false) delete redundant packs after repacking
      #
      #       When `true`, passes `-d`. After packing, removes any existing packs that
      #       are made redundant by the newly created pack. Also runs `git prune-packed`.
      #
      #     @option options [Boolean] :cruft (false) pack unreachable objects into a
      #       separate cruft pack when combined with `:d`
      #
      #       When `true`, passes `--cruft`. Like `:a`, but any unreachable objects are
      #       packed into a separate cruft pack instead of being removed. Incompatible
      #       with `:keep_unreachable`.
      #
      #     @option options [String] :cruft_expiration (nil) expire cruft objects older
      #       than the given date immediately
      #
      #       Passed as `--cruft-expiration=<approxidate>`. Only useful with
      #       `--cruft -d`.
      #
      #     @option options [Integer, String] :max_cruft_size (nil) override
      #       `--max-pack-size` for cruft packs
      #
      #       Passed as `--max-cruft-size=<n>`. Accepts size suffixes (`k`, `m`, `g`).
      #       Inherits the value of `:max_pack_size` by default.
      #
      #     @option options [Integer, String] :combine_cruft_below_size (nil) only
      #       repack cruft packs strictly smaller than this size
      #
      #       Passed as `--combine-cruft-below-size=<n>`. Accepts size suffixes
      #       (`k`, `m`, `g`). Useful to avoid repacking large cruft packs.
      #
      #     @option options [String] :expire_to (nil) write pruned cruft objects to
      #       a directory
      #
      #       Passed as `--expire-to=<dir>`. Only useful with `--cruft -d`.
      #
      #     @option options [Boolean] :l (false) pass `--local` to `git pack-objects`
      #
      #       When `true`, passes `-l`. Ignores objects that come from an alternates
      #       object store.
      #
      #     @option options [Boolean] :f (false) pass `--no-reuse-delta` to
      #       `git pack-objects`
      #
      #       When `true`, passes `-f`. Forces reconstruction of all pack deltas.
      #
      #     @option options [Boolean] :F (false) pass `--no-reuse-object` to
      #       `git pack-objects`
      #
      #       When `true`, passes `-F`. Forces reconstruction of all object data, not
      #       just deltas.
      #
      #     @option options [Boolean] :quiet (false) suppress progress reporting
      #
      #       When `true`, passes `--quiet`.
      #
      #       Alias: `:q`
      #
      #     @option options [Boolean] :n (false) do not update server information
      #
      #       When `true`, passes `-n`. Skips running `git update-server-info`, which
      #       updates local catalog files needed to publish the repository
      #       over HTTP or FTP.
      #
      #     @option options [Integer, String] :window (nil) number of previous objects
      #       used to generate delta compressions
      #
      #       Passed as `--window=<n>` to `git pack-objects`.
      #
      #     @option options [Integer, String] :depth (nil) maximum delta depth
      #
      #       Passed as `--depth=<n>` to `git pack-objects`.
      #
      #     @option options [Integer, String] :threads (nil) number of threads for
      #       delta search
      #
      #       Passed as `--threads=<n>` to `git pack-objects`.
      #
      #     @option options [Integer, String] :window_memory (nil) maximum memory usage
      #       for delta window
      #
      #       Passed as `--window-memory=<n>` to `git pack-objects`. Accepts size
      #       suffixes (`k`, `m`, `g`).
      #
      #     @option options [Integer, String] :max_pack_size (nil) maximum size of each
      #       output pack file
      #
      #       Passed as `--max-pack-size=<n>`. Accepts size suffixes (`k`, `m`, `g`).
      #
      #     @option options [String] :filter (nil) remove objects matching the filter
      #       specification from the resulting packfile
      #
      #       Passed as `--filter=<filter-spec>`. Filtered objects are placed in a
      #       separate packfile. Best used with `-a -d` and in a bare repository.
      #
      #     @option options [String] :filter_to (nil) write the pack containing filtered
      #       objects to a directory
      #
      #       Passed as `--filter-to=<dir>`. Only useful with `:filter`.
      #
      #     @option options [Boolean] :write_bitmap_index (false) write a reachability
      #       bitmap index as part of the repack
      #
      #       When `true`, passes `--write-bitmap-index`. Only meaningful when used with
      #       `:a`, `:A`, or `:write_midx`. Overrides `repack.writeBitmaps`.
      #
      #       Alias: `:b`
      #
      #     @option options [Boolean] :pack_kept_objects (false) include objects in
      #       `.keep` files when repacking
      #
      #       When `true`, passes `--pack-kept-objects`. Generally only useful when
      #       writing bitmaps with `:write_bitmap_index`.
      #
      #     @option options [String, Array<String>] :keep_pack (nil) exclude named
      #       pack(s) from repacking
      #
      #       Pass a pack file name (without leading directory, e.g. `'pack-abc123.pack'`)
      #       or an array of pack file names. Each value is passed as a separate
      #       `--keep-pack=<name>` argument.
      #
      #     @option options [Boolean] :write_midx (false) write a multi-pack index
      #       containing the non-redundant packs
      #
      #       When `true`, passes `--write-midx`.
      #
      #       Alias: `:m`
      #
      #     @option options [String] :unpack_unreachable (nil) do not loosen unreachable
      #       objects older than the given date
      #
      #       Passed as `--unpack-unreachable=<when>`. Objects older than the given date
      #       are not loosened, since they would be immediately pruned by a follow-up
      #       `git prune`.
      #
      #     @option options [Boolean] :keep_unreachable (false) keep unreachable objects
      #       in the new packfile rather than removing them
      #
      #       When `true`, passes `--keep-unreachable`. Appends unreachable objects from
      #       existing packs to the end of the new packfile. For use with `-ad`.
      #
      #       Alias: `:k`
      #
      #     @option options [Boolean] :delta_islands (false) pass `--delta-islands` to
      #       `git pack-objects`
      #
      #       When `true`, passes `--delta-islands`.
      #
      #       Alias: `:i`
      #
      #     @option options [Integer, String] :geometric (nil) arrange pack structure so
      #       each successive pack contains at least this many times the objects of the
      #       next-largest pack
      #
      #       Passed as `--geometric=<factor>`.
      #
      #       Alias: `:g`
      #
      #     @option options [Integer, String] :name_hash_version (nil) pass
      #       `--name-hash-version=<n>` to `git pack-objects`
      #
      #     @option options [Boolean] :path_walk (false) pass `--path-walk` to
      #       `git pack-objects`
      #
      #     @return [Git::CommandLineResult] the result of calling `git repack`
      #
      #     @raise [ArgumentError] if unsupported options are provided
      #
      #     @raise [Git::FailedError] if git exits with a non-zero exit status
    end
  end
end
