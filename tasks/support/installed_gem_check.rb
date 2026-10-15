# frozen_string_literal: true

require 'bundler'
require 'open3'
require 'rbconfig'
require 'tmpdir'

# Checks that a gem loads and runs from its built package, not only from the source checkout
#
# Builds the gem from its gemspec, installs it with its runtime dependencies into an
# empty gem home, and runs a Ruby script that can see only that gem home and Ruby's
# default gems. The script cannot load the checkout's lib/ or the bundle, so a file the
# package leaves out makes it fail. A required gem the gemspec does not declare makes it
# fail only when it is not a default gem and no installed dependency declares it either.
module InstalledGemCheck
  # Raised when building the gem, installing it, or running the script fails
  class Failed < StandardError; end

  module_function

  # Build, install, and run script against the installed gem
  #
  # Installing fetches the gem's runtime dependencies from its sources, usually
  # rubygems.org. The build and install read the user's gem configuration (~/.gemrc
  # or GEMRC) as any `gem` command does. Every step writes its output as it runs: the
  # build and install to out and err, the script to err. Only the script's standard
  # output is captured, to be returned.
  #
  # @param gemspec_path [String] the gemspec to build
  # @param script [String] Ruby code to run in the gemspec's directory
  # @param out [Symbol, String, IO, Array] where the build and install write standard
  #   output, as a Process.spawn redirect target; by default, this process's standard
  #   output
  # @param err [Symbol, String, IO, Array] where every step writes standard error, as a
  #   Process.spawn redirect target; by default, this process's standard error
  # @param base_env [Hash{String => String}] the environment the steps start from; by
  #   default, the one this process started with before Bundler changed it
  # @return [String] the script's standard output
  # @raise [Failed] if a step fails
  def run(gemspec_path, script, out: :out, err: :err, base_env: Bundler.unbundled_env)
    gemspec_path = File.expand_path(gemspec_path)
    Dir.mktmpdir('installed-gem-check') do |tmp_dir|
      gem_home = File.join(tmp_dir, 'gem_home')
      gem_file = File.join(tmp_dir, "#{File.basename(gemspec_path, '.gemspec')}.gem")
      options = { chdir: File.dirname(gemspec_path), unsetenv_others: true, out: out, err: err }
      env = environment(base_env, gem_home)

      run_gem(env, options, 'build', gemspec_path, '--output', gem_file)
      run_gem(env, options, 'install', '--no-document', '--install-dir', gem_home, gem_file)
      run_script(env, options.except(:out), script)
    end
  end

  # base_env without RUBYLIB and RUBYOPT, and with the empty gem home as the only gem
  # location
  #
  # base_env defaults to the environment the parent process started with, before
  # Bundler changed it. The child gets only these variables (run passes
  # unsetenv_others), so nothing Bundler added, such as BUNDLE_GEMFILE, reaches it.
  # RUBYLIB and RUBYOPT are dropped because a developer's RUBYLIB=lib or RUBYOPT=-Ilib
  # would let the script load the checkout's lib/. Their names are matched without
  # regard to case because Windows reads RubyOpt as RUBYOPT. ENV itself is not changed.
  def environment(base_env, gem_home)
    base_env.reject { |name, _| %w[RUBYLIB RUBYOPT].include?(name.upcase) }
            .merge('GEM_HOME' => gem_home, 'GEM_PATH' => gem_home)
  end

  # Run RubyGems in the running Ruby the way its gem script does, without running the
  # script. `ruby -S gem` would search PATH, where a version manager's shim (asdf,
  # rbenv) may be a shell script or belong to a different Ruby, and the script's name in
  # bindir changes with the Ruby's --program-suffix.
  def gem_command
    [RbConfig.ruby, '-e', 'require "rubygems/gem_runner"; Gem::GemRunner.new.run(ARGV)', '--']
  end

  # Run a gem command with env as its whole environment and the given spawn options
  #
  # @raise [Failed] if the command fails; its output has already been written
  def run_gem(env, options, *args)
    return if system(env, *gem_command, *args, exception: false, **options)

    raise Failed, "gem #{args.first} failed; see its output above"
  end

  # Run script with env as its whole environment and return its standard output
  #
  # @raise [Failed] if the script fails; its standard error has already been written,
  #   and the message includes its standard output
  def run_script(env, options, script)
    output, status = Open3.capture2(env, RbConfig.ruby, '-e', script, **options)
    return output if status.success?

    raise Failed, "script failed; see its standard error above. Its standard output:\n#{output}"
  end
  private_class_method :environment, :gem_command, :run_gem, :run_script
end
