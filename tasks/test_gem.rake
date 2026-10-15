# frozen_string_literal: true

require 'open3'
require 'rbconfig'
require 'rubygems/installer'
require 'tmpdir'

# Runs the built gem outside the active Bundler environment.
module RubyGitTestGem
  SCRIPT = <<~'RUBY'
    require 'git'

    spec = Gem.loaded_specs.fetch('git')
    expected_path = File.join(File.realpath(ENV.fetch('GEM_HOME')), 'gems', spec.full_name)
    loaded_path = File.realpath(spec.full_gem_path)
    abort "Expected git from #{expected_path}, loaded from #{loaded_path}" unless loaded_path == expected_path

    puts "#{spec.full_gem_path}\t#{Git.open('.').log.execute.size}"
  RUBY

  module_function

  def run(gem_file, gem_home)
    Gem::Installer.at(gem_file, install_dir: gem_home, ignore_dependencies: true, wrappers: true).install
    output, error, status = Bundler.with_unbundled_env do
      Open3.capture3(environment(gem_home), RbConfig.ruby, '-e', SCRIPT)
    end
    raise "Gem test failed:\n#{output}#{error}" unless status.success?

    loaded_gem_path, history_size = output.chomp.split("\t", 2)
    raise 'Expected gem test to return an integer' unless history_size&.match?(/\A\d+\z/)

    loaded_gem_path
  end

  def environment(gem_home)
    ENV.keys.grep(/\ABUNDLE_/).to_h { |key| [key, nil] }.merge(
      'GEM_HOME' => gem_home,
      'GEM_PATH' => ([gem_home] + Gem.path).uniq.join(File::PATH_SEPARATOR),
      'RUBYLIB' => nil,
      'RUBYOPT' => nil
    )
  end
end

desc 'Build and install the git gem in a temporary home and run a sanity check'
task 'test:gem': :build do
  gemspec = Gem::Specification.load('git.gemspec')
  gem_file = File.join('pkg', gemspec.file_name)
  loaded_gem_path = Dir.mktmpdir('ruby-git-test-gem') do |gem_home|
    RubyGitTestGem.run(gem_file, gem_home)
  end

  puts "Gem Test Succeeded: #{loaded_gem_path}"
end
