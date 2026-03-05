# frozen_string_literal: true

module Git
  # Namespace module for git command-line execution strategies
  #
  # This module groups the classes responsible for invoking git subprocesses
  # and handling their output. Choose a concrete class based on your buffering
  # needs:
  #
  # * {Git::CommandLine::Capturing} — buffers stdout and stderr in memory.
  #   Use this for the vast majority of git commands whose output fits in memory.
  #
  # * {Git::CommandLine::Streaming} — streams stdout to a caller-supplied IO.
  #   Use this for commands (e.g. `cat-file -p <blob>`) whose output may be
  #   too large to buffer.
  #
  # Both classes inherit from {Git::CommandLine::Base} and are instantiated
  # via factory helpers in {Git::Lib}: {Git::Lib#command_capturing} and
  # {Git::Lib#command_streaming}.
  #
  # Results are returned as {Git::CommandLine::Result} objects (also accessible
  # as {Git::CommandLineResult} for backward compatibility).
  #
  # @api public
  #
  # @example Buffered command via Git::CommandLine::Capturing
  #   cli = Git::CommandLine::Capturing.new(
  #     {}, '/usr/bin/git', [], Logger.new(nil)
  #   )
  #   result = cli.run('version')
  #   result.stdout #=> "git version 2.39.1\n"
  #
  # @example Streaming command via Git::CommandLine::Streaming
  #   cli = Git::CommandLine::Streaming.new(
  #     {}, '/usr/bin/git', [], Logger.new(nil)
  #   )
  #   File.open('/tmp/blob', 'wb') do |f|
  #     cli.run('cat-file', 'blob', sha, out: f)
  #   end
  #
  # @see Git::CommandLine::Base
  # @see Git::CommandLine::Result
  #
  module CommandLine
  end
end

require 'git/command_line/result'
require 'git/command_line/base'
require 'git/command_line/capturing'
require 'git/command_line/streaming'
