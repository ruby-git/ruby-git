# frozen_string_literal: true

# Markdown link checking with lychee.
#
# lychee is a Rust binary rather than a gem, so `bundle install` cannot supply it. It is
# a required prerequisite all the same -- bin/setup verifies it, and this task fails
# rather than skipping when it is missing, because `markdown:links` runs as part of the
# default task and a check that silently no-ops would make a successful
# `bundle exec rake` mean less than it says. Every platform this project supports has a
# packaged lychee; see the prerequisites table in CONTRIBUTING.md.
#
# A successful run here still does not guarantee a successful CI job, and the gap is
# the environment rather than the tool:
#
#   * Case-sensitive filenames. macOS is case-insensitive by default, Linux is not, so
#     `](docs/README.MD)` against a file named README.md resolves here and 404s in CI.
#     Nothing lychee does can close this; the filesystem answers before lychee sees it.
#     It is also invisible in review, because the link looks correct.
#   * Empty results. The action sets failIfEmpty, so a .lychee.toml broken badly enough
#     to match no files fails the job. lychee itself exits 0 in that case, so this task
#     reports success.
#   * Untracked files. lychee honors .gitignore, but a file that is merely untracked is
#     still scanned here, while CI only ever sees what is committed. This is the one
#     difference that errs toward noise rather than a missed failure.

namespace :markdown do
  desc 'Check markdown links and heading anchors with lychee'
  task :links do
    # With `exception: true`, `system` raises Errno::ENOENT when it cannot find lychee
    # and RuntimeError when lychee runs and fails, so no separate probe for the tool is
    # needed. ENOENT also covers a lychee on PATH whose interpreter is missing (a broken
    # shim), so the message reports the error rather than asserting lychee is absent.
    # Any other failure to start lychee propagates with its own error.
    system('lychee', '--config', '.lychee.toml', '.', exception: true)
  rescue Errno::ENOENT => e
    abort <<~MESSAGE
      Could not start lychee (#{e.message}), and `rake markdown:links` requires it.
      Either lychee is not installed or not on PATH, or the lychee found on PATH cannot
      run. Install with one of:
        macOS    brew install lychee
        Ubuntu   snap install lychee
        Arch     pacman -S lychee
        Windows  winget install --id lycheeverse.lychee
      Others: https://github.com/lycheeverse/lychee#installation
      Then re-run `bin/setup` to confirm the version, or `rake markdown:links` directly.
    MESSAGE
  rescue RuntimeError
    abort 'rake markdown:links failed'
  end
end
