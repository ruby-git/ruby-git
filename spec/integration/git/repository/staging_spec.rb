# frozen_string_literal: true

require 'spec_helper'
require 'git/repository'
require 'git/repository/staging'

# Integration tests for Git::Repository::Staging.
#
# #ignored_files, #apply, #apply_mail, and #read_tree are exercised end-to-end
# because they each perform facade-owned logic beyond simple delegation:
#   - #ignored_files post-processes git output (splitting + path unescaping)
#   - #apply and #apply_mail guard on File.exist? before calling git
#   - #read_tree owns option whitelisting and maps opts={} to command kwargs
#
# Single-command delegators whose only facade behavior is option whitelisting
# (#add, #reset, #rm, #clean) are covered by underlying command integration specs:
#   spec/integration/git/commands/add_spec.rb
#   spec/integration/git/commands/reset_spec.rb
#   spec/integration/git/commands/rm_spec.rb
#   spec/integration/git/commands/clean_spec.rb
#
# #mv is also a single-command delegator and is covered by:
#   spec/integration/git/commands/mv_spec.rb
# Unlike the methods above, #mv adds two input pre-processing behaviors beyond
# option whitelisting: Array source normalization (*Array(source)) and injecting
# verbose: true. These are pure-Ruby transforms with no git involvement; the unit
# specs cover them fully and real git adds no additional signal.

RSpec.describe Git::Repository::Staging, :integration do
  include_context 'in an empty repository'

  let(:described_instance) { Git::Repository.new(execution_context: execution_context) }

  describe '#ignored_files' do
    before do
      write_file('.gitignore', "*.log\n")
      repo.add(all: true)
      repo.commit('Add gitignore')
    end

    context 'when there are no ignored files' do
      it 'returns an empty array' do
        expect(described_instance.ignored_files).to eq([])
      end
    end

    context 'when ignored files exist' do
      before do
        write_file('debug.log', 'log')
        write_file('tmp/trace.log', 'log')
      end

      it 'returns the ignored file paths relative to the repository root' do
        expect(described_instance.ignored_files).to contain_exactly('debug.log', 'tmp/trace.log')
      end

      it 'does not include tracked or untracked non-ignored files' do
        write_file('keep.txt', 'content')
        expect(described_instance.ignored_files).not_to include('keep.txt', '.gitignore')
      end
    end
  end

  describe '#apply' do
    let(:patch_file) { File.join(repo_dir, 'changes.patch') }

    before do
      write_file('hello.txt', "hello\n")
      repo.add(all: true)
      repo.commit('Initial commit')
      write_file('hello.txt', "hello world\n")
      patch_content = execution_context.command_capturing('diff', 'HEAD', chomp: false, chdir: repo_dir).stdout
      File.write(patch_file, patch_content)
      write_file('hello.txt', "hello\n") # restore original content
    end

    context 'when the patch file exists' do
      it 'applies the patch to the working tree' do
        described_instance.apply(patch_file)
        expect(read_file('hello.txt')).to eq("hello world\n")
      end

      it 'returns a String' do
        expect(described_instance.apply(patch_file)).to be_a(String)
      end
    end

    context 'when the patch file does not exist' do
      it 'returns nil without raising' do
        expect(described_instance.apply('/nonexistent/fix.patch')).to be_nil
      end

      it 'leaves the working tree unchanged' do
        described_instance.apply('/nonexistent/fix.patch')
        expect(read_file('hello.txt')).to eq("hello\n")
      end
    end
  end

  describe '#apply_mail' do
    let(:mbox_file) { File.join(repo_dir, 'patch.mbox') }

    before do
      write_file('hello.txt', "hello\n")
      repo.add(all: true)
      repo.commit('Initial commit')
      write_file('hello.txt', "hello world\n")
      repo.add(all: true)
      repo.commit('add world')
      mbox_content = execution_context.command_capturing(
        'format-patch', '-1', 'HEAD', '--stdout', chomp: false, chdir: repo_dir
      ).stdout
      File.write(mbox_file, mbox_content)
      repo.reset('HEAD~1', hard: true)
    end

    context 'when the mbox file exists' do
      it 'applies the patch to the current branch' do
        described_instance.apply_mail(mbox_file)
        expect(read_file('hello.txt')).to eq("hello world\n")
      end

      it 'returns a String' do
        expect(described_instance.apply_mail(mbox_file)).to be_a(String)
      end
    end

    context 'when the mbox file does not exist' do
      it 'returns nil without raising' do
        expect(described_instance.apply_mail('/nonexistent/patch.mbox')).to be_nil
      end

      it 'leaves the working tree unchanged' do
        described_instance.apply_mail('/nonexistent/patch.mbox')
        expect(read_file('hello.txt')).to eq("hello\n")
      end
    end
  end

  describe '#read_tree' do
    before do
      write_file('hello.txt', "hello\n")
      repo.add(all: true)
      repo.commit('Initial commit')
    end

    it 'reads the tree into the index without error' do
      expect { described_instance.read_tree('HEAD') }.not_to raise_error
    end

    it 'returns a String' do
      expect(described_instance.read_tree('HEAD')).to be_a(String)
    end

    context 'with prefix option' do
      it 'reads the tree under the given prefix without error' do
        expect { described_instance.read_tree('HEAD', { prefix: 'sub/' }) }.not_to raise_error
      end
    end

    context 'with an unknown option' do
      it 'raises ArgumentError before calling git' do
        expect { described_instance.read_tree('HEAD', { bogus: true }) }
          .to raise_error(ArgumentError, /Unknown options: bogus/)
      end
    end

    context 'legacy positional hash signature' do
      it 'accepts opts as a positional hash' do
        expect { described_instance.read_tree('HEAD', { prefix: 'sub/' }) }.not_to raise_error
      end
    end
  end
end
