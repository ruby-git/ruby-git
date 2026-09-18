# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'

# Point `HOME` at a temporary directory for the duration of each example
#
# Use this in any example that asserts on where `~` expands to, so the
# assertion never depends on the developer's real home directory. `home_dir`
# is the real path of the temporary directory, so paths built from it compare
# equal to the paths git and `File.realpath` report.
#
# git started inside the example sees the same `HOME`, so it reads no global
# git config (`~/.gitconfig`). That isolation is intended: an example under this
# context must pin any git config it depends on in the repository it creates,
# as the integration specs already do for the committer identity.
#
# @example
#   context 'with a ~-prefixed directory' do
#     include_context 'with a temporary home directory'
#
#     it 'expands ~ to the temporary home' do
#       expect(File.expand_path('~/scratch')).to eq(File.join(home_dir, 'scratch'))
#     end
#   end
#
RSpec.shared_context 'with a temporary home directory' do
  let(:home_dir) { File.realpath(Dir.mktmpdir('home')) }

  around do |example|
    # Dir.home falls back to other sources when HOME is unset, so it cannot
    # tell an unset HOME apart from a set one. Read the variable itself so the
    # original state, set or unset, is restored exactly.
    original_home = ENV.fetch('HOME', nil) # rubocop:disable Style/EnvHome
    ENV['HOME'] = home_dir
    example.run
  ensure
    ENV['HOME'] = original_home
    FileUtils.rm_rf(home_dir)
  end
end
