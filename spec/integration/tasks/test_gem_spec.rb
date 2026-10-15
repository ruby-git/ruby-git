# frozen_string_literal: true

require 'spec_helper'
require 'digest'
require 'open3'
require 'rbconfig'

RSpec.describe 'rake test:gem' do
  let(:project_root) { File.expand_path('../../..', __dir__) }

  subject(:run_gem_test) do
    Open3.capture3(
      RbConfig.ruby,
      Gem.bin_path('bundler', 'bundle'),
      'exec', 'rake', 'test:gem',
      chdir: project_root
    )
  end

  it 'loads the installed gem from a temporary home without modifying existing gem homes' do
    installed_git_artifacts_before = installed_git_artifacts

    stdout, stderr, status = run_gem_test

    expect(status).to be_success, "#{stdout}\n#{stderr}"

    loaded_gem_path = stdout.each_line.map(&:chomp).find do |line|
      line.start_with?('Gem Test Succeeded: ')
    end&.delete_prefix('Gem Test Succeeded: ')

    expect(loaded_gem_path).to be_a(String)
    if loaded_gem_path
      temporary_root = File.expand_path(Dir.tmpdir).tr('\\', '/').downcase
      normalized_gem_path = File.expand_path(loaded_gem_path).tr('\\', '/').downcase

      expect(normalized_gem_path).to start_with("#{temporary_root}/")
      expect(normalized_gem_path).to match(%r{/gems/git-[^/]+\z})
      expect(File.exist?(loaded_gem_path)).to be(false)
    end

    expect(installed_git_artifacts).to eq(installed_git_artifacts_before)
  end

  def installed_git_artifacts
    installed_git_gem_homes.flat_map do |gem_home|
      %w[cache doc extensions gems specifications].flat_map do |directory|
        git_artifact_digests(gem_home, directory)
      end
    end
  end

  def installed_git_gem_homes
    (Gem.path + [Gem.user_dir]).uniq
  end

  def git_artifact_digests(gem_home, directory)
    Dir.glob(File.join(gem_home, directory, 'git-*')).flat_map do |artifact|
      artifact_files(artifact).map { |path| [path, Digest::SHA256.file(path).hexdigest] }
    end
  end

  def artifact_files(artifact)
    return [artifact] if File.file?(artifact)

    Dir.glob(File.join(artifact, '**', '*')).select { |path| File.file?(path) }
  end
end
