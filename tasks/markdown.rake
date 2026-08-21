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
    unless system('command -v lychee > /dev/null 2>&1')
      abort <<~MESSAGE
        lychee is not installed or not on PATH, and `rake markdown:links` requires it.
        Install with one of:
          macOS    brew install lychee
          Ubuntu   snap install lychee
          Arch     pacman -S lychee
          Windows  winget install --id lycheeverse.lychee
        Others: https://github.com/lycheeverse/lychee#installation
        Then re-run `bin/setup` to confirm the version, or `rake markdown:links` directly.
      MESSAGE
    end

    abort 'rake markdown:links failed' unless system('lychee', '--config', '.lychee.toml', '.')
  end
end
