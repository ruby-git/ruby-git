# frozen_string_literal: true

# GitHub Actions workflow linting with actionlint.
#
# actionlint is a Go binary rather than a gem, so `bundle install` cannot supply it. It is
# a required prerequisite all the same -- bin/setup verifies it, and this task fails
# rather than skipping when it is missing, for the reason tasks/markdown.rake gives for
# lychee: `lint:actions` runs as part of the default task, and a check that silently
# no-ops would make a successful `bundle exec rake` mean less than it says.
#
# CI installs the newest actionlint release on every run, and a local copy may be older,
# so a successful run here does not guarantee a successful CI job. The same is true of
# shellcheck, which actionlint uses to lint the shell in `run:` steps when it is on PATH:
# the CI runner has it, and without it those steps go unchecked here. This task says so
# rather than letting the two disagree quietly.
#
# The workflow files are passed by absolute path, so the command says what it lints
# instead of relying on actionlint's search from the working directory.
#
# The shellcheck note goes through $stderr.puts, not Kernel#warn, which prints nothing
# when warnings are disabled (RUBYOPT=-W0 or $VERBOSE = nil) and would let the note
# vanish on exactly the machines it is for.

# Runs actionlint on the given files and returns whether it found no problems, or aborts
# with install instructions when actionlint cannot be started.
#
# With `exception: true`, `system` raises Errno::ENOENT when it cannot find actionlint and
# RuntimeError when actionlint runs and fails, so no separate probe for the tool is
# needed. ENOENT also covers an actionlint on PATH whose interpreter is missing (a broken
# shim), so the message reports the error rather than asserting actionlint is absent. Any
# other failure to start actionlint propagates with its own error. A failed check returns
# false rather than aborting, so the task can print the shellcheck note first.
def run_actionlint(files)
  system('actionlint', *files, exception: true)
rescue Errno::ENOENT => e
  abort "Could not start actionlint (#{e.message}), and `rake lint:actions` requires it.\n" \
        "#{ACTIONLINT_INSTALL_HELP}"
rescue RuntimeError
  false
end

ACTIONLINT_INSTALL_HELP = <<~MESSAGE
  Either actionlint is not installed or not on PATH, or the actionlint found on PATH
  cannot run. Install with one of:
    macOS, Linux  brew install actionlint
    Windows       winget install --id rhysd.actionlint (or scoop / choco install actionlint)
    mise          mise use -g actionlint
    Go            go install github.com/rhysd/actionlint/cmd/actionlint@latest
  Others: https://github.com/rhysd/actionlint/blob/main/docs/install.md
  Then re-run `bin/setup` to confirm, or `rake lint:actions` directly.
MESSAGE

namespace :lint do
  desc 'Lint the GitHub Actions workflows with actionlint'
  task :actions do
    workflows = Dir.glob(File.expand_path('../.github/workflows/*.{yml,yaml}', __dir__))
    passed = run_actionlint(workflows)

    if system('shellcheck', '--version', out: File::NULL, err: File::NULL).nil?
      $stderr.puts <<~MESSAGE # rubocop:disable Style/StderrPuts
        note: shellcheck is not on PATH, so the shell in `run:` steps went unchecked.
              CI has it and will lint more than this run did. Packages for every
              platform: https://github.com/koalaman/shellcheck#installing
      MESSAGE
    end

    abort 'rake lint:actions failed' unless passed
  end
end
