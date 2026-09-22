# frozen_string_literal: true

require 'spec_helper'

# Guards the contents of `spec.files` in git.gemspec.
#
# `spec.files` is an allowlist, which trades one failure mode for another: it can no
# longer admit development-only files by accident, but it can silently omit files the
# gem needs. These examples cover both sides.
RSpec.describe 'git.gemspec' do
  subject(:gemspec) { Gem::Specification.load(File.join(project_root, 'git.gemspec')) }

  let(:project_root) { File.expand_path('../..', __dir__) }

  # Pass the path as an argv element rather than interpolating it into a shell
  # string, so a checkout under a path with spaces still works.
  def git_ls_files(*args)
    IO.popen(['git', '-C', project_root, 'ls-files', '-z', *args], &:read).split("\x0")
  end

  it 'ships no symlinks' do
    # Extracting a symlink requires a privilege Windows withholds outside Developer
    # Mode or an elevated shell, so a symlink in the gem breaks `gem install` there.
    #
    # Read the index rather than the working tree: Git for Windows checks symlinks out
    # as plain text files unless core.symlinks is enabled, so a File.symlink? test
    # would pass vacuously on the very platform this protects. Each `git ls-files -s`
    # record is "<mode> <sha> <stage>\t<path>".
    symlinks = git_ls_files('-s').filter_map do |record|
      fields, path = record.split("\t", 2)
      path if fields.split.first == '120000'
    end

    expect(symlinks).not_to be_empty, 'expected the repository to contain a symlink to test against'
    expect(gemspec.files & symlinks).to be_empty
  end

  it 'ships every tracked file under lib/' do
    lib_files = git_ls_files('--', 'lib')

    expect(lib_files).not_to be_empty
    expect(gemspec.files).to include(*lib_files)
  end

  it 'ships every extra file named in .yardopts' do
    # rubydoc.info renders these from the installed gem, so one missing here is a
    # broken link in the published documentation. In .yardopts a lone "-" separates
    # the YARD options from the list of extra files.
    extra_files = File.readlines(File.join(project_root, '.yardopts'), chomp: true)
                      .drop_while { |line| line != '-' }
                      .drop(1)
                      .reject(&:empty?)

    expect(extra_files).not_to be_empty
    expect(gemspec.files).to include(*extra_files)
  end

  it 'ships nothing outside lib/ and the project root' do
    expect(gemspec.files.reject { |f| f.start_with?('lib/') }).to all(satisfy { |f| !f.include?('/') })
  end
end
