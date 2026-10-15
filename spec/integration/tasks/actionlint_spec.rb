# frozen_string_literal: true

require 'spec_helper'
require 'bundler'
require 'fileutils'
require 'open3'
require 'rbconfig'
require 'tmpdir'

# Runs `rake lint:actions` in a child Ruby whose PATH holds only a directory of fakes,
# so each example decides whether actionlint and shellcheck are on PATH and what
# actionlint reports. The child starts from Bundler.unbundled_env, the environment from
# before `bundle exec`, because Bundler's setup would load git.gemspec and run git,
# which is not on that PATH; rake ships with Ruby, so the child needs no bundle.
#
# The fakes are /bin/sh scripts that use only shell builtins, so they need nothing else
# on PATH, and the examples skip on Windows. They also run only on MRI: its `ruby` is a
# native executable that starts with nothing else on PATH, while JRuby's `jruby` is a
# shell launcher that looks for `java` on PATH when JAVA_HOME is unset, and
# TruffleRuby's launcher is not verified here. The task is plain Ruby and rake, so MRI
# covers it.
#
# Each example spawns one child process, so the examples that share a scenario check
# everything about it in one example.
skip_reason =
  if Gem.win_platform?
    'the fakes are /bin/sh scripts'
  elsif RUBY_ENGINE != 'ruby'
    "the child Ruby runs with a PATH of only the fakes, which #{RUBY_ENGINE}'s launcher may not start under"
  end

RSpec.describe 'tasks/actionlint.rake', skip: skip_reason do
  subject(:result) do
    stdout, stderr, status = Open3.capture3(
      Bundler.unbundled_env.merge('PATH' => bin_dir, 'MARKER' => marker),
      RbConfig.ruby, '-e', "require 'rake'; load 'tasks/actionlint.rake'; Rake::Task['lint:actions'].invoke",
      chdir: project_root, unsetenv_others: true
    )
    { stdout: stdout, stderr: stderr, success: status.success? }
  end

  let(:project_root) { File.expand_path('../../..', __dir__) }
  let(:bin_dir) { Dir.mktmpdir('lint-actions-bin') }
  let(:marker) { File.join(bin_dir, 'actionlint-ran') }

  after { FileUtils.rm_rf(bin_dir) }

  def install_fake(name, body)
    path = File.join(bin_dir, name)
    File.write(path, "#!/bin/sh\n#{body}\n")
    File.chmod(0o755, path)
  end

  # A fake actionlint that records that it ran, prints a finding, and exits with the
  # given status.
  def install_actionlint(exit_status)
    install_fake('actionlint', ": > \"$MARKER\"\necho 'workflow.yml:1:1: a finding'\nexit #{exit_status}")
  end

  context 'when actionlint is not on PATH' do
    before { install_fake('shellcheck', 'exit 0') }

    it 'fails with instructions for installing it' do
      expect(result).to include(
        success: false,
        stderr: a_string_matching(/Could not start actionlint \(.*actionlint\).*brew install actionlint/m)
      )
    end
  end

  context 'when actionlint finds no problems' do
    before { install_actionlint(0) }

    context 'with shellcheck on PATH' do
      before { install_fake('shellcheck', 'exit 0') }

      it 'succeeds after running actionlint, passing on its output and not mentioning shellcheck' do
        expect(result).to include(success: true, stdout: a_string_including('workflow.yml:1:1: a finding'))
        expect(result[:stderr]).not_to include('shellcheck')
        expect(File).to exist(marker)
      end
    end

    context 'without shellcheck on PATH' do
      it 'succeeds and warns that run: steps went unchecked' do
        expect(result).to include(
          success: true,
          stderr: a_string_matching(/shellcheck is not on PATH, so the shell in `run:` steps went unchecked/)
        )
      end
    end
  end

  context 'when actionlint reports problems' do
    before { install_actionlint(1) }

    context 'with shellcheck on PATH' do
      before { install_fake('shellcheck', 'exit 0') }

      it 'fails naming the task' do
        expect(result).to include(success: false, stderr: a_string_matching(/rake lint:actions failed/))
      end
    end

    context 'without shellcheck on PATH' do
      it 'warns that run: steps went unchecked before failing' do
        expect(result).to include(
          success: false,
          stderr: a_string_matching(/shellcheck is not on PATH.*rake lint:actions failed/m)
        )
      end
    end
  end
end
