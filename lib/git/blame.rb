module Git
  
  class Blame
    include Enumerable
    
    def initialize(base, file = '', start = '', fin = '')
      @base = base

      construct_blame(file, start, fin)
    end

    # Todo - factor this in to BlameLine instead, and have this loop?    
    def pretty
      out = ''

      self.each do |line|
        out << line.line + ' : ' + line.commit + "\n"
          out << ' ' + line.summary + "\n"
          out << " author:\n"
            out << '  ' + line.author + "\n"
            out << '  ' + line.author_email + "\n"
            out << '  @ ' + line.author_timestamp + "\n"
            out << '  ' + line.author_timezone + "\n"
            out << "\n"
          out << " committer:\n"
            out << '  ' + line.committer + "\n"
            out << '  ' + line.committer_email + "\n"
            out << '  @ ' + line.committer_timestamp + "\n"
            out << '  ' + line.committer_timezone + "\n"
            out << "\n"
      end

      out
    end

    
    def [](line)
      @lines[line]
    end
    
    # enumerable method
    
    def each(&block)
      @lines.values.each(&block)
    end

    
    class BlameLine
      attr_accessor :line, :commit
      attr_accessor :author, :author_email, :author_timestamp, :author_timezone
      attr_accessor :committer, :committer_email, :committer_timestamp, :committer_timezone
      attr_accessor :summary


      def initialize(line, hash)
        @line = line

        @commit = hash[:commit]

        @author           = hash[:author]
        @author_email     = hash[:author_email]
        @author_timestamp = hash[:author_timestamp]
        @author_timezone  = hash[:author_timezone]

        @committer           = hash[:committer]
        @committer_email     = hash[:committer_email]
        @committer_timestamp = hash[:committer_timestamp]
        @committer_timezone  = hash[:committer_timezone]

        @summary = hash[:summary]
      end

    end

    
    private

      @lines


      # This will run the blame (via our lib.rb), and parse the porcelain-formatted blame output into BlameLine objects
      def construct_blame(file = '', start = '', fin = '')
        @lines = {}

        lines = @base.lib.blame({:file => file, :start => start, :fin => fin})

        parsed_lines = {}
        commits = {}

        commit = nil

        lines.each do |line|
          new_commit = line.match(/^[a-fA-F0-9]{40}/)

          if ! new_commit.nil?
            commit = new_commit[0]

            line_num = line.sub(/^[a-f0-9]{40} [0-9]+ /, '')
            line_num = line_num.sub(/\s[0-9]+.*$/, '') if line_num.match(/\s/)

            # this looks odd, but it's correct... we're initializing this commit's hash, which
            # should contain a :hash -> <sha hash> element, among other things, and the hash
            # OF commit hashes is indexed on the sha hash, so... yeah :)
            #
            commits[commit] = {:commit => commit} if ! commits[commit]

            parsed_lines[line_num] = commit
          end

          if /^author\s/.match(line)
            commits[commit][:author] = line.sub(/^author\s/, '')
          elsif /^author-mail\s/.match(line)
            commits[commit][:author_email] = line.sub(/^author-mail\s/, '')
          elsif /^author-time\s/.match(line)
            commits[commit][:author_timestamp] = line.sub(/^author-time\s/, '')
          elsif /^author-tz\s/.match(line)
            commits[commit][:author_timezone] = line.sub(/^author-tz\s/, '')
          elsif /^committer\s/.match(line)
            commits[commit][:committer] = line.sub(/^committer\s/, '')
          elsif /^committer-mail\s/.match(line)
            commits[commit][:committer_email] = line.sub(/^committer-mail\s/, '')
          elsif /^committer-time\s/.match(line)
            commits[commit][:committer_timestamp] = line.sub(/^committer-time\s/, '')
          elsif /^committer-tz\s/.match(line)
            commits[commit][:committer_timezone] = line.sub(/^committer-tz\s/, '')
          elsif /^summary\s/.match(line)
            commits[commit][:summary] = line.sub(/^summary\s/, '')
          end
        end

        parsed_lines.each do |line, commit|
          commits[commit][:line] = line

          @lines[line] = BlameLine.new(line, commits[commit])
        end
      end

  end
  
end
