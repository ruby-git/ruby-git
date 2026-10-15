# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'
require 'tempfile'
require_relative '../../../../tasks/support/installed_gem_check'

RSpec.describe InstalledGemCheck do
  include Git::IntegrationTestHelpers

  describe '.run' do
    subject(:result) { described_class.run(gemspec_path, script, out: out_log, err: err_log, base_env: base_env) }

    let(:project_dir) { Dir.mktmpdir }
    let(:repo_dir) { project_dir }
    let(:gemspec_path) { File.join(project_dir, 'probe_gem.gemspec') }
    let(:script) { "require 'probe_gem'\nputs Gem.loaded_specs.fetch('probe_gem').full_name\n" }
    let(:packaged_files) { ['lib/probe_gem.rb'] }
    let(:entry_point) { "module ProbeGem\nend\n" }
    let(:out_log) { Tempfile.new('installed-gem-check-out') }
    let(:err_log) { Tempfile.new('installed-gem-check-err') }
    let(:base_env) { Bundler.unbundled_env }

    # homepage and required_ruby_version keep gem build from printing warnings, so a
    # successful run writes nothing to err_log
    before do
      write_file('lib/probe_gem.rb', entry_point)
      write_file('probe_gem.gemspec', <<~GEMSPEC)
        Gem::Specification.new do |spec|
          spec.name = 'probe_gem'
          spec.version = '1.0.0'
          spec.summary = 'A gem built by the InstalledGemCheck spec'
          spec.authors = ['ruby-git']
          spec.license = 'MIT'
          spec.homepage = 'https://github.com/ruby-git/ruby-git'
          spec.required_ruby_version = '>= 3.3.0'
          spec.files = #{packaged_files.inspect}
        end
      GEMSPEC
    end

    after do
      out_log.close!
      err_log.close!
      FileUtils.remove_entry(project_dir)
    end

    # The LoadError message for a missing feature. Older JRuby releases, such as the
    # 10.0.0.1 that CI runs, say "no such file to load" where MRI says "cannot load such
    # file".
    def load_error_for(feature)
      /(?:cannot load such file|no such file to load) -- #{Regexp.escape(feature)}/
    end

    context 'when the installed gem loads' do
      it 'returns the output of the script run against the installed gem' do
        expect(result).to eq("probe_gem-1.0.0\n")
      end

      it 'writes the gem install output to out' do
        result
        expect(File.read(out_log.path)).to include('probe_gem-1.0.0')
      end
    end

    context 'when the script succeeds and writes to standard error' do
      let(:script) { "require 'probe_gem'\nwarn 'probe warning'\n" }

      it 'writes its standard error to err' do
        result
        expect(File.read(err_log.path)).to include('probe warning')
      end
    end

    context 'when the gemspec lists a file that does not exist' do
      let(:packaged_files) { ['lib/probe_gem.rb', 'lib/probe_gem/absent.rb'] }

      it 'raises Failed after gem build reports the file it could not package to err' do
        expect { result }.to raise_error(InstalledGemCheck::Failed, /gem build failed/)
        expect(File.read(err_log.path)).to include('lib/probe_gem/absent.rb')
      end
    end

    context 'when the gem requires a file its gemspec does not package' do
      let(:entry_point) { "require 'probe_gem/unpackaged'\n" }

      before { write_file('lib/probe_gem/unpackaged.rb', "module ProbeGem\nend\n") }

      it 'raises Failed after the script reports the missing file to err' do
        expect { result }.to raise_error(InstalledGemCheck::Failed, /script failed/)
        expect(File.read(err_log.path)).to match(load_error_for('probe_gem/unpackaged'))
      end
    end

    # rchardet is a runtime dependency of the git gem, so it is installed in the bundle
    # running this spec. The installed gem fails to load only if the script cannot see
    # the bundle's gems.
    context 'when the gem requires a gem its gemspec does not declare' do
      let(:entry_point) { "require 'rchardet'\n" }

      it 'raises Failed after the script reports the undeclared gem to err' do
        expect { result }.to raise_error(InstalledGemCheck::Failed, /script failed/)
        expect(File.read(err_log.path)).to match(load_error_for('rchardet'))
      end
    end

    # A developer's RUBYLIB=lib would otherwise let the script load the checkout's lib/
    # in place of the installed gem.
    context 'with RUBYLIB in base_env pointing at a directory that has the unpackaged file' do
      let(:entry_point) { "require 'probe_gem/unpackaged'\n" }
      let(:base_env) { Bundler.unbundled_env.merge('RUBYLIB' => File.join(project_dir, 'lib')) }

      before { write_file('lib/probe_gem/unpackaged.rb', "module ProbeGem\nend\n") }

      it 'raises Failed because the script does not load from RUBYLIB' do
        expect { result }.to raise_error(InstalledGemCheck::Failed, /script failed/)
        expect(File.read(err_log.path)).to match(load_error_for('probe_gem/unpackaged'))
      end
    end

    # The script runs in the gemspec's directory, so a developer's RUBYOPT=-Ilib would
    # otherwise put the checkout's lib/ on the load path.
    context 'with RUBYOPT in base_env adding lib to the load path' do
      let(:entry_point) { "require 'probe_gem/unpackaged'\n" }
      let(:base_env) { Bundler.unbundled_env.merge('RUBYOPT' => '-Ilib') }

      before { write_file('lib/probe_gem/unpackaged.rb', "module ProbeGem\nend\n") }

      it 'raises Failed because the script does not load from RUBYOPT' do
        expect { result }.to raise_error(InstalledGemCheck::Failed, /script failed/)
        expect(File.read(err_log.path)).to match(load_error_for('probe_gem/unpackaged'))
      end
    end

    # Windows reads environment names without regard to case, so RubyOpt there acts as
    # RUBYOPT. The script reports the names it sees, which works on every platform.
    context 'with RUBYLIB and RUBYOPT in base_env under mixed-case names' do
      let(:base_env) { Bundler.unbundled_env.merge('RubyLib' => 'lib', 'RubyOpt' => '-Ilib') }
      let(:script) { "puts ENV.keys.grep(/\\A(?:rubylib|rubyopt)\\z/i).inspect\n" }

      it 'leaves them out of the environment the script runs with' do
        expect(result).to eq("[]\n")
      end
    end
  end
end
