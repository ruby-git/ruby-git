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
    # @see https://git-scm.com/docs/git-repack git-repack documentation
    #
    # @see Git::Commands
    #
    # @api private
    #
    class Repack < Git::Commands::Base
      arguments do
        literal 'repack'

        # SYNOPSIS order: [-a] [-A] [-d] [-f] [-F] [-l] [-n] [-q] [-b]
        #   [--window=<n>] [--depth=<n>] [--threads=<n>] [--keep-pack=<pack-name>]
        flag_option :a
        flag_option :A
        flag_option :d
        flag_option :f
        flag_option :F
        flag_option :l
        flag_option :n
        flag_option :q
        flag_option %i[write_bitmap_index b]
        value_option :window, inline: true
        value_option :depth, inline: true
        value_option :threads, inline: true
        value_option :keep_pack, inline: true, repeatable: true

        # Non-SYNOPSIS options (OPTIONS section order)
        value_option :window_memory, inline: true
        value_option :max_pack_size, inline: true
        flag_option :pack_kept_objects
        value_option :unpack_unreachable, inline: true
        flag_option %i[keep_unreachable k]
        flag_option %i[delta_islands i]
      end

      # @!method call(*, **)
      #
      #   @overload call(**options)
      #
      #     Execute the `git repack` command
      #
      #     @param options [Hash] command options
      #
      #     @option options [Boolean] :a (nil) pack all objects into a single pack
      #
      #       When `true`, passes `-a`. Especially useful when packing a repository
      #       used for private development. Use with `:d` to clean up objects.
      #
      #     @option options [Boolean] :A (nil) pack all objects, loosening unreachable
      #       objects when combined with `:d`
      #
      #       When `true`, passes `-A`. Like `:a`, but any unreachable objects in a
      #       previous pack become loose unpacked objects instead of being removed. The
      #       loose unreachable objects are pruned by the next `git gc` invocation.
      #
      #     @option options [Boolean] :d (nil) delete redundant packs after repacking
      #
      #       When `true`, passes `-d`. After packing, removes any existing packs that
      #       are made redundant by the newly created pack. Also runs `git prune-packed`.
      #
      #     @option options [Boolean] :f (nil) pass `--no-reuse-delta` to
      #       `git pack-objects`
      #
      #       When `true`, passes `-f`. Forces reconstruction of all pack deltas.
      #
      #     @option options [Boolean] :F (nil) pass `--no-reuse-object` to
      #       `git pack-objects`
      #
      #       When `true`, passes `-F`. Forces reconstruction of all object data, not
      #       just deltas.
      #
      #     @option options [Boolean] :l (nil) pass `--local` to `git pack-objects`
      #
      #       When `true`, passes `-l`. Ignores objects that come from an alternates
      #       object store.
      #
      #     @option options [Boolean] :n (nil) do not update server information
      #
      #       When `true`, passes `-n`. Skips running `git update-server-info`, which
      #       updates local catalog files needed to publish the repository
      #       over HTTP or FTP.
      #
      #     @option options [Boolean] :q (nil) suppress progress reporting
      #
      #       When `true`, passes `-q`.
      #
      #     @option options [Boolean] :write_bitmap_index (nil) write a reachability
      #       bitmap index as part of the repack
      #
      #       When `true`, passes `--write-bitmap-index`. Only meaningful when used with
      #       `:a`, `:A`. This option overrides the setting of `repack.writeBitmaps`.
      #
      #       Alias: `:b`
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
      #     @option options [String, Array<String>] :keep_pack (nil) exclude named pack(s)
      #       from repacking
      #
      #       Pass a pack file name (without leading directory, e.g. `'pack-abc123.pack'`)
      #       or an array of pack file names. Each value is passed as a separate
      #       `--keep-pack=<name>` argument.
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
      #     @option options [Boolean] :pack_kept_objects (nil) include objects in `.keep`
      #       files when repacking
      #
      #       When `true`, passes `--pack-kept-objects`. Note that `.keep` packs are not
      #       deleted after repacking. Generally only useful when also writing bitmaps
      #       with `:write_bitmap_index`.
      #
      #     @option options [String] :unpack_unreachable (nil) control loosening of
      #       unreachable objects by age
      #
      #       Passed as `--unpack-unreachable=<date>`. Objects older than the given date
      #       are not loosened, since they would be immediately pruned by a follow-up
      #       `git prune`.
      #
      #     @option options [Boolean] :keep_unreachable (nil) keep unreachable objects in
      #       the new packfile rather than removing them
      #
      #       When `true`, passes `--keep-unreachable`. For use with `-ad`.
      #
      #       Alias: `:k`
      #
      #     @option options [Boolean] :delta_islands (nil) pass `--delta-islands` to
      #       `git pack-objects`
      #
      #       Alias: `:i`
      #
      #     @return [Git::CommandLineResult] the result of calling `git repack`
      #
      #     @raise [Git::FailedError] if git exits with a non-zero exit status
    end
  end
end
