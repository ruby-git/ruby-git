# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/diff/numstat'

RSpec.describe Git::Commands::Diff::Numstat, :integration do
  include_context 'in a diff test repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    # Tests focusing on numstat-specific output format and parsing
    # (Basic diff scenarios are covered by Patch spec)

    describe 'numstat output format' do
      it 'returns DiffFileNumstatInfo objects' do
        result = command.call('initial', 'after_modify')

        expect(result.files.first).to be_a(Git::DiffFileNumstatInfo)
      end

      it 'provides insertions and deletions counts' do
        result = command.call('initial', 'after_modify')

        file = result.files.first
        expect(file.insertions).to be > 0
        expect(file.deletions).to eq(0)
        expect(file.path).to eq('README.md')
      end
    end

    describe 'rename detection with brace syntax' do
      it 'detects renamed files and provides src_path' do
        result = command.call('after_modify', 'after_rename')

        file = result.files.first
        expect(file.renamed?).to be true
        expect(file.src_path).to eq('README.md')
        expect(file.path).to eq('docs.md')
      end
    end

    describe 'binary file handling' do
      it 'reports dash (-) for binary files as zero' do
        result = command.call('after_add', 'after_binary')

        file = result.files.first
        expect(file.path).to eq('image.png')
        # Binary files show "-" which should be parsed as 0
        expect(file.insertions).to eq(0)
        expect(file.deletions).to eq(0)
      end
    end

    describe 'multiple files' do
      # Use after_utf8_rename on Windows since tab filename is skipped
      let(:multi_base_tag) { Gem.win_platform? ? 'after_utf8_rename' : 'after_tab_filename' }

      it 'returns stats for all changed files' do
        result = command.call(multi_base_tag, 'after_multi')

        expect(result.files.size).to eq(3)
        paths = result.files.map(&:path)
        expect(paths).to include('lib/main.rb')
        expect(paths).to include('lib/helper.rb')
        expect(paths).to include('CHANGELOG.md')
      end

      it 'calculates total insertions/deletions correctly' do
        result = command.call(multi_base_tag, 'after_multi')

        total_insertions = result.files.sum(&:insertions)
        total_deletions = result.files.sum(&:deletions)

        expect(result.total_insertions).to eq(total_insertions)
        expect(result.total_deletions).to eq(total_deletions)
      end
    end

    describe 'files with spaces in paths' do
      it 'correctly parses quoted paths with spaces' do
        result = command.call('after_mode_change', 'after_spaces')

        file = result.files.first
        expect(file.path).to eq('path with spaces/file name.txt')
      end
    end

    describe 'dirstat option' do
      it 'includes directory statistics when requested' do
        result = command.call('initial', 'after_multi', dirstat: true)

        expect(result.dirstat).not_to be_nil
        expect(result.dirstat.entries).not_to be_empty
      end
    end

    describe 'pathspec filtering' do
      it 'limits results to matching pathspecs' do
        result = command.call('after_spaces', 'after_multi', pathspecs: ['lib/'])

        paths = result.files.map(&:path)
        expect(paths).to all(start_with('lib/'))
      end
    end

    describe 'exit code handling' do
      it 'succeeds with no differences (exit code 0)' do
        result = command.call('initial', 'initial')

        expect(result.files).to be_empty
      end

      it 'succeeds with differences found (exit code 1)' do
        result = command.call('initial', 'after_modify')

        expect(result.files).not_to be_empty
      end

      it 'raises FailedError for invalid revision (exit code 128)' do
        expect { command.call('nonexistent-ref') }.to raise_error(Git::FailedError)
      end
    end
  end
end
