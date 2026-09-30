# frozen_string_literal: true

require_relative 'support/external_tool'

# GitHub Actions workflow linting with actionlint.
#
# This task is not part of the default task and bin/setup does not check for actionlint,
# so it is an opt-in shortcut for the loop that would otherwise run through CI: the
# Workflow Lint job in .github/workflows/continuous_integration.yml runs the same check
# on every pull request and is the check that counts. CI runs the newest actionlint
# release with the runner's shellcheck, so a local run can pass a workflow that CI
# rejects, or the reverse, when the two versions differ.
#
# Install with `brew install actionlint` or see
# https://github.com/rhysd/actionlint/blob/main/docs/install.md. shellcheck is optional;
# without it, actionlint skips the shell in `run:` steps and says so only under
# `-verbose`, so the task warns when shellcheck cannot run rather than letting a green
# run mean more than it says.

namespace :lint do
  desc 'Lint the GitHub Actions workflows with actionlint (requires actionlint on PATH)'
  task :actions do
    workflows = Dir.glob(File.expand_path('../.github/workflows/*.{yml,yaml}', __dir__))
    # Without file arguments actionlint looks for a workflows directory above the
    # current directory, so an empty glob would lint whatever it finds there instead of
    # reporting that nothing matched here.
    abort 'rake lint:actions found no workflow files under .github/workflows' if workflows.empty?

    install_hint = <<~HINT
      Install with one of:
        macOS    brew install actionlint
        Arch     pacman -S actionlint
        Windows  winget install actionlint
        Go       go install github.com/rhysd/actionlint/cmd/actionlint@latest
      Others: https://github.com/rhysd/actionlint/blob/main/docs/install.md
    HINT
    # `-pyflakes ''` disables the pyflakes integration, as the CI job does, so the local
    # run and the job check the same things.
    ExternalTool.run(['actionlint', '-pyflakes', '', *workflows], task: 'lint:actions', install_hint: install_hint)

    # Probed after actionlint succeeds so that a machine with neither tool sees only the
    # abort for the one it has to install. actionlint fails outright when a shellcheck on
    # PATH cannot run, so by this point shellcheck is either working or absent; the
    # warning still reports the error the probe saw rather than asserting which.
    begin
      system('shellcheck', '--version', out: File::NULL, err: File::NULL, exception: true)
    rescue Errno::ENOENT, RuntimeError => e
      warn "Could not run shellcheck (#{e.message}), so the shell in `run:` steps was not checked (CI checks it)"
    end
  end
end
