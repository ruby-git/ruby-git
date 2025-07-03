# frozen_string_literal: true

require_relative 'diff_path_status'
require_relative 'diff_stats'

module Git
  # object that holds the diff between two commits
  class Diff
    include Enumerable

    def initialize(base, from = nil, to = nil)
      @base = base
      @from = from&.to_s
      @to = to&.to_s

      @path = nil
      @full_diff_files = nil
    end
    attr_reader :from, :to

    def path(path)
      @path = path
      self
    end

    def patch
      @base.lib.diff_full(@from, @to, { path_limiter: @path })
    end
    alias to_s patch

    def [](key)
      process_full
      @full_diff_files.assoc(key)[1]
    end

    def each(&)
      process_full
      @full_diff_files.map { |file| file[1] }.each(&)
    end

    #
    # DEPRECATED METHODS
    #

    def name_status
      Git::Deprecation.warn('Git::Diff#name_status is deprecated. Use Git::Base#diff_path_status instead.')
      path_status_provider.to_h
    end

    def size
      Git::Deprecation.warn('Git::Diff#size is deprecated. Use Git::Base#diff_stats(...).total[:files] instead.')
      stats_provider.total[:files]
    end

    def lines
      Git::Deprecation.warn('Git::Diff#lines is deprecated. Use Git::Base#diff_stats(...).lines instead.')
      stats_provider.lines
    end

    def deletions
      Git::Deprecation.warn('Git::Diff#deletions is deprecated. Use Git::Base#diff_stats(...).deletions instead.')
      stats_provider.deletions
    end

    def insertions
      Git::Deprecation.warn('Git::Diff#insertions is deprecated. Use Git::Base#diff_stats(...).insertions instead.')
      stats_provider.insertions
    end

    def stats
      Git::Deprecation.warn('Git::Diff#stats is deprecated. Use Git::Base#diff_stats instead.')
      # CORRECTED: Re-create the original hash structure for backward compatibility
      {
        files: stats_provider.files,
        total: stats_provider.total
      }
    end

    class DiffFile
      attr_accessor :patch, :path, :mode, :src, :dst, :type

      @base = nil
      NIL_BLOB_REGEXP = /\A0{4,40}\z/

      def initialize(base, hash)
        @base = base
        @patch = hash[:patch]
        @path = hash[:path]
        @mode = hash[:mode]
        @src = hash[:src]
        @dst = hash[:dst]
        @type = hash[:type]
        @binary = hash[:binary]
      end

      def binary?
        !!@binary
      end

      def blob(type = :dst)
        if type == :src && !NIL_BLOB_REGEXP.match(@src)
          @base.object(@src)
        elsif !NIL_BLOB_REGEXP.match(@dst)
          @base.object(@dst)
        end
      end
    end

    private

    def process_full
      return if @full_diff_files

      @full_diff_files = process_full_diff
    end

    # CORRECTED: Pass the @path variable to the new objects
    def path_status_provider
      @path_status_provider ||= Git::DiffPathStatus.new(@base, @from, @to, @path)
    end

    # CORRECTED: Pass the @path variable to the new objects
    def stats_provider
      @stats_provider ||= Git::DiffStats.new(@base, @from, @to, @path)
    end

    def process_full_diff
      defaults = {
        mode: '', src: '', dst: '', type: 'modified'
      }
      final = {}
      current_file = nil
      patch.split("\n").each do |line|
        if (m = %r{\Adiff --git ("?)a/(.+?)\1 ("?)b/(.+?)\3\z}.match(line))
          current_file = Git::EscapedPath.new(m[2]).unescape
          final[current_file] = defaults.merge({ patch: line, path: current_file })
        else
          if (m = /^index ([0-9a-f]{4,40})\.\.([0-9a-f]{4,40})( ......)*/.match(line))
            final[current_file][:src] = m[1]
            final[current_file][:dst] = m[2]
            final[current_file][:mode] = m[3].strip if m[3]
          end
          if (m = /^([[:alpha:]]*?) file mode (......)/.match(line))
            final[current_file][:type] = m[1]
            final[current_file][:mode] = m[2]
          end
          final[current_file][:binary] = true if /^Binary files /.match(line)
          final[current_file][:patch] << "\n#{line}"
        end
      end
      final.map { |e| [e[0], DiffFile.new(@base, e[1])] }
    end
  end
end
