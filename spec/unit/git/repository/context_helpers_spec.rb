# frozen_string_literal: true

require 'spec_helper'
require 'git/repository'
require 'git/repository/context_helpers'

# The with_temp_index and with_temp_working integration specs in
# spec/integration/git/repository/context_helpers_spec.rb show the yielded
# repository reading and writing the temporary location against real git. The
# remaining helpers are pure path/context manipulations with no git-command
# delegation and are covered here only.

RSpec.describe Git::Repository::ContextHelpers do
  let(:git_dir) { '/repo/.git' }
  let(:work_dir) { '/repo' }
  let(:index_file) { '/repo/.git/index' }

  # A real context rather than a double: it is a value object with no disk
  # access, and its dup_with is what carries the outer override into a helper
  # nested inside another.
  let(:execution_context) do
    Git::ExecutionContext::Repository.new(
      git_dir: git_dir,
      git_work_dir: work_dir,
      git_index_file: index_file,
      binary_path: '/usr/bin/git',
      git_ssh: nil
    )
  end

  let(:described_instance) { Git::Repository.new(execution_context: execution_context) }

  # All four with_* helpers route through one private block guard. This group
  # pins its contract once; each helper runs it through `call_helper`, a lambda
  # that forwards the given block to the helper under test.
  shared_examples 'a helper that requires a repository block' do
    it 'raises ArgumentError when no block is given' do
      expect { call_helper.call }
        .to raise_error(ArgumentError, /block that accepts the yielded repository/)
    end

    it 'raises ArgumentError when the block declares no parameter' do
      expect { call_helper.call { nil } }
        .to raise_error(ArgumentError, /block that accepts the yielded repository/)
    end

    it 'raises ArgumentError when the block declares only a keyword parameter' do
      expect { call_helper.call { |**_opts| nil } }
        .to raise_error(ArgumentError, /block that accepts the yielded repository/)
    end

    it 'accepts a block that declares an unused parameter' do
      expect { call_helper.call { |_| nil } }.not_to raise_error
    end

    it 'accepts a block that declares an optional parameter' do
      expect { call_helper.call { |_repo = nil| nil } }.not_to raise_error
    end

    it 'accepts a block that takes a splat' do
      expect { call_helper.call { |*| nil } }.not_to raise_error
    end
  end

  # ---------------------------------------------------------------------------
  # #chdir
  # ---------------------------------------------------------------------------

  describe '#chdir' do
    before do
      allow(Dir).to receive(:chdir).with(work_dir).and_yield
    end

    it 'yields the dir Pathname' do
      expect { |b| described_instance.chdir(&b) }.to yield_with_args(Pathname.new(work_dir))
    end

    it 'changes the process directory to the repository working directory' do
      expect(Dir).to receive(:chdir).with(work_dir).and_yield
      described_instance.chdir { nil }
    end

    it 'returns the value returned by the block' do
      result = described_instance.chdir { 42 }
      expect(result).to eq(42)
    end

    context 'when the working directory cannot be entered' do
      before do
        allow(Dir).to receive(:chdir).with(work_dir).and_raise(Errno::ENOENT, work_dir)
      end

      it 'raises Git::Error with the system error as cause' do
        expect { described_instance.chdir { nil } }
          .to raise_error(Git::Error, /Failed to change directory.*No such file or directory/) do |error|
            expect(error.cause).to be_a(Errno::ENOENT)
          end
      end
    end

    context 'when the block raises a SystemCallError' do
      it 'lets the SystemCallError propagate unchanged' do
        expect { described_instance.chdir { raise Errno::ENOENT, 'caller.txt' } }
          .to raise_error(Errno::ENOENT, /caller\.txt/)
      end
    end

    context 'when the previous directory cannot be restored' do
      before do
        # Dir.chdir's block form also fails on the way out, after the block has
        # run. The reported directory must be the one that failed, not the one
        # that was entered successfully.
        allow(Dir).to receive(:chdir).with(work_dir) do |_path, &block|
          block.call
          raise Errno::ENOENT, '/deleted/previous/dir'
        end
      end

      it 'raises Git::Error naming the directory that could not be restored' do
        expect { described_instance.chdir { nil } }
          .to raise_error(Git::Error, %r{Failed to change directory.*/deleted/previous/dir}) do |error|
            expect(error.cause).to be_a(Errno::ENOENT)
          end
      end

      it 'does not name the successfully entered directory' do
        expect { described_instance.chdir { nil } }.to raise_error(Git::Error) do |error|
          expect(error.message).not_to include(work_dir)
        end
      end
    end

    context 'when the repository is bare (no working directory)' do
      let(:execution_context) do
        instance_double(
          Git::ExecutionContext::Repository,
          git_dir: git_dir,
          git_work_dir: nil,
          git_index_file: index_file
        )
      end

      it 'raises ArgumentError with a clear message' do
        expect { described_instance.chdir { nil } }
          .to raise_error(ArgumentError, /bare repository/)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #set_index
  # ---------------------------------------------------------------------------

  describe '#set_index' do
    let(:new_context) { instance_double(Git::ExecutionContext::Repository) }

    before do
      allow(execution_context).to receive(:dup_with).and_return(new_context)
    end

    it 'rebuilds the execution context via dup_with with the new index file' do
      expect(execution_context).to receive(:dup_with).with(
        git_index_file: File.expand_path('/repo/.git/new-index')
      ).and_return(new_context)
      described_instance.set_index('/repo/.git/new-index', must_exist: false)
    end

    it 'raises ArgumentError if must_exist: true and path does not exist' do
      expect do
        described_instance.set_index('/nonexistent/index', must_exist: true)
      end.to raise_error(ArgumentError, /path does not exist/)
    end

    it 'does not raise when must_exist: false and path does not exist' do
      expect do
        described_instance.set_index('/nonexistent/index', must_exist: false)
      end.not_to raise_error
    end

    it 'raises ArgumentError when path does not exist and must_exist is not given' do
      expect do
        described_instance.set_index('/nonexistent/index')
      end.to raise_error(ArgumentError, /path does not exist/)
    end

    it 'returns nil (void)' do
      expect(described_instance.set_index('/repo/.git/new-index', must_exist: false)).to be_nil
    end

    context 'when must_exist: true and the index file exists' do
      let(:existing_index_path) { '/repo/.git/existing-index' }
      let(:expanded_index_path) { File.expand_path(existing_index_path) }
      let(:existing_pathname) { instance_double(Pathname, exist?: true, to_s: expanded_index_path) }

      before do
        allow(Pathname).to receive(:new).and_call_original
        allow(Pathname).to receive(:new).with(expanded_index_path).and_return(existing_pathname)
      end

      it 'rebuilds the execution context with the existing index path without raising' do
        expect(execution_context).to receive(:dup_with)
          .with(git_index_file: expanded_index_path)
          .and_return(new_context)
        expect { described_instance.set_index(existing_index_path, must_exist: true) }
          .not_to raise_error
      end
    end

    context 'signature compatibility (legacy-contract)' do
      it 'accepts a positional check argument with a deprecation warning' do
        expect(Git::Deprecation).to receive(:warn).once
        expect { described_instance.set_index('/nonexistent/index', false) }.not_to raise_error
      end

      it 'warns with the documented "check" argument deprecation message' do
        expect(Git::Deprecation).to receive(:warn).with(
          'The "check" argument is deprecated and will be removed in v6.0.0. ' \
          'Use "must_exist:" instead.'
        )
        described_instance.set_index('/nonexistent/index', false)
      end

      it 'performs existence check when both check=true and must_exist: false are given (more restrictive wins)' do
        expect(Git::Deprecation).to receive(:warn).once
        expect { described_instance.set_index('/nonexistent/index', true, must_exist: false) }
          .to raise_error(ArgumentError, /path does not exist/)
      end

      it 'raises when both check=false and must_exist: true are given (more restrictive wins)' do
        # must_exist: true | check: false → true → raises
        expect(Git::Deprecation).to receive(:warn).once
        expect { described_instance.set_index('/nonexistent/index', false, must_exist: true) }
          .to raise_error(ArgumentError, /path does not exist/)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #with_index
  # ---------------------------------------------------------------------------

  describe '#with_index' do
    # A directory the spec owns, so the index file inside it is known not to
    # exist rather than assumed absent from a shared location such as /tmp.
    let(:temp_dir) { Dir.mktmpdir('context-helpers-') }
    let(:new_index) { File.join(temp_dir, 'idx') }
    let(:expanded_index) { File.expand_path(new_index) }

    after { FileUtils.remove_entry(temp_dir, true) }

    it_behaves_like 'a helper that requires a repository block' do
      let(:call_helper) { ->(&block) { described_instance.with_index(new_index, &block) } }
    end

    it 'yields a repository other than the receiver bound to the new index' do
      yielded = nil
      described_instance.with_index(new_index) { |repo| yielded = repo }
      expect(yielded).to be_a(Git::Repository)
      expect(yielded).not_to be(described_instance)
      expect(yielded.index).to eq(Pathname.new(expanded_index))
    end

    it 'yields an instance of the receiver class' do
      subclass_instance = Class.new(Git::Repository).new(execution_context: execution_context)
      yielded = nil
      subclass_instance.with_index(new_index) { |repo| yielded = repo }
      expect(yielded).to be_an_instance_of(subclass_instance.class)
    end

    it 'leaves a set_index made on the receiver inside the block in place after the block' do
      other_index = '/repo/.git/other.index'
      described_instance.with_index(new_index) do |_repo|
        described_instance.set_index(other_index, must_exist: false)
      end
      expect(described_instance.index).to eq(Pathname.new(File.expand_path(other_index)))
    end

    it 'returns the value returned by the block' do
      result = described_instance.with_index(new_index) { |_repo| 'hello' }
      expect(result).to eq('hello')
    end

    it 'leaves the receiver execution context unchanged inside and after the block' do
      original_context = described_instance.execution_context
      context_in_block = nil
      described_instance.with_index(new_index) { |_repo| context_in_block = described_instance.execution_context }
      expect(context_in_block).to be(original_context)
      expect(described_instance.execution_context).to be(original_context)
    end

    it 'leaves the receiver execution context unchanged when the block raises' do
      original_context = described_instance.execution_context
      expect { described_instance.with_index(new_index) { |_repo| raise 'block error' } }
        .to raise_error('block error')
      expect(described_instance.execution_context).to be(original_context)
    end

    it 'does not require the index file to exist' do
      expect(File.exist?(expanded_index)).to be(false)
      expect { described_instance.with_index(new_index) { |_repo| nil } }.not_to raise_error
    end

    context 'when the path cannot be expanded' do
      before do
        # File.expand_path consults Dir.pwd for a relative path, so it fails
        # when the process working directory has been removed. Other callers
        # (Dir.mktmpdir, the temp-dir cleanup) must still expand normally.
        allow(File).to receive(:expand_path).and_call_original
        allow(File).to receive(:expand_path).with('relative/index').and_raise(Errno::ENOENT, 'getcwd')
      end

      it 'raises Git::Error with the system error as cause' do
        expect { described_instance.with_index('relative/index') { |_repo| nil } }
          .to raise_error(Git::Error, /Failed to expand the path/) do |error|
            expect(error.cause).to be_a(Errno::ENOENT)
          end
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #with_temp_index
  # ---------------------------------------------------------------------------

  describe '#with_temp_index' do
    it_behaves_like 'a helper that requires a repository block' do
      let(:call_helper) { ->(&block) { described_instance.with_temp_index(&block) } }
    end

    context 'when the block cannot receive the repository' do
      it 'does not create a temporary directory before rejecting the block' do
        allow(Dir).to receive(:mktmpdir).and_call_original
        expect { described_instance.with_temp_index { nil } }
          .to raise_error(ArgumentError, /block that accepts the yielded repository/)
        expect(Dir).not_to have_received(:mktmpdir)
      end
    end

    context 'when the temporary directory cannot be created' do
      before do
        allow(Dir).to receive(:mktmpdir).and_raise(Errno::EACCES, '/tmp')
      end

      it 'raises Git::Error with the system error as cause' do
        expect { described_instance.with_temp_index { |_repo| nil } }
          .to raise_error(Git::Error, /Failed to create a temporary directory.*Permission denied/) do |error|
            expect(error.cause).to be_a(Errno::EACCES)
          end
      end
    end

    context 'when the block raises a SystemCallError' do
      it 'lets the SystemCallError propagate unchanged' do
        expect { described_instance.with_temp_index { |_repo| raise Errno::ENOENT, 'caller.txt' } }
          .to raise_error(Errno::ENOENT, /caller\.txt/)
      end
    end

    it 'yields a repository other than the receiver' do
      yielded = nil
      described_instance.with_temp_index { |repo| yielded = repo }
      expect(yielded).to be_a(Git::Repository)
      expect(yielded).not_to be(described_instance)
    end

    it 'yields a repository bound to an index inside a new temporary directory' do
      yielded_index = nil
      described_instance.with_temp_index { |repo| yielded_index = repo.index }
      expect(yielded_index).not_to eq(Pathname.new(index_file))
      expect(yielded_index.basename.to_s).to eq('index')
    end

    it 'leaves the receiver execution context unchanged inside and after the block' do
      original_context = described_instance.execution_context
      context_in_block = nil
      described_instance.with_temp_index { |_repo| context_in_block = described_instance.execution_context }
      expect(context_in_block).to be(original_context)
      expect(described_instance.execution_context).to be(original_context)
    end

    it 'cleans up the temporary directory after the block succeeds' do
      temp_dir = nil
      described_instance.with_temp_index do |repo|
        temp_dir = File.dirname(repo.index.to_s)
        FileUtils.touch(repo.index.to_s)
      end
      expect(temp_dir).not_to be_nil
      expect(Dir.exist?(temp_dir)).to be(false)
    end

    it 'cleans up the temporary directory even when the block raises' do
      temp_dir = nil
      expect do
        described_instance.with_temp_index do |repo|
          temp_dir = File.dirname(repo.index.to_s)
          FileUtils.touch(repo.index.to_s)
          raise 'block error'
        end
      end.to raise_error('block error')
      expect(temp_dir).not_to be_nil
      expect(Dir.exist?(temp_dir)).to be(false)
    end
  end

  # ---------------------------------------------------------------------------
  # #set_working
  # ---------------------------------------------------------------------------

  describe '#set_working' do
    let(:new_context) { instance_double(Git::ExecutionContext::Repository) }

    before do
      allow(execution_context).to receive(:dup_with).and_return(new_context)
    end

    it 'rebuilds the execution context via dup_with with the new working directory' do
      expect(execution_context).to receive(:dup_with).with(
        git_work_dir: File.expand_path('/other/dir')
      ).and_return(new_context)
      described_instance.set_working('/other/dir', must_exist: false)
    end

    it 'raises ArgumentError if must_exist: true and path does not exist' do
      expect do
        described_instance.set_working('/nonexistent/dir', must_exist: true)
      end.to raise_error(ArgumentError, /path does not exist/)
    end

    it 'does not raise when must_exist: false and path does not exist' do
      expect do
        described_instance.set_working('/nonexistent/dir', must_exist: false)
      end.not_to raise_error
    end

    it 'raises ArgumentError when path does not exist and must_exist is not given' do
      expect do
        described_instance.set_working('/nonexistent/dir')
      end.to raise_error(ArgumentError, /path does not exist/)
    end

    it 'returns nil (void)' do
      expect(described_instance.set_working('/other/dir', must_exist: false)).to be_nil
    end

    context 'when the path cannot be expanded' do
      before do
        # File.expand_path consults Dir.pwd for a relative path, so it fails
        # when the process working directory has been removed.
        allow(File).to receive(:expand_path).with('relative/dir').and_raise(Errno::ENOENT, 'getcwd')
      end

      it 'raises Git::Error with the system error as cause' do
        expect { described_instance.set_working('relative/dir', must_exist: false) }
          .to raise_error(Git::Error, /Failed to expand the path/) do |error|
            expect(error.cause).to be_a(Errno::ENOENT)
          end
      end
    end

    context 'when must_exist: true and the directory exists' do
      let(:existing_work_dir) { '/repo/existing-workdir' }
      let(:expanded_work_dir) { File.expand_path(existing_work_dir) }
      let(:existing_pathname) { instance_double(Pathname, exist?: true, to_s: expanded_work_dir) }

      before do
        allow(Pathname).to receive(:new).and_call_original
        allow(Pathname).to receive(:new).with(expanded_work_dir).and_return(existing_pathname)
      end

      it 'rebuilds the execution context with the existing working directory without raising' do
        expect(execution_context).to receive(:dup_with)
          .with(git_work_dir: expanded_work_dir)
          .and_return(new_context)
        expect { described_instance.set_working(existing_work_dir, must_exist: true) }
          .not_to raise_error
      end
    end

    context 'signature compatibility (legacy-contract)' do
      it 'accepts a positional check argument with a deprecation warning' do
        expect(Git::Deprecation).to receive(:warn).once
        expect { described_instance.set_working('/nonexistent/dir', false) }.not_to raise_error
      end

      it 'warns with the documented "check" argument deprecation message' do
        expect(Git::Deprecation).to receive(:warn).with(
          'The "check" argument is deprecated and will be removed in v6.0.0. ' \
          'Use "must_exist:" instead.'
        )
        described_instance.set_working('/nonexistent/dir', false)
      end

      it 'performs existence check when both check=true and must_exist: false are given (more restrictive wins)' do
        expect(Git::Deprecation).to receive(:warn).once
        expect { described_instance.set_working('/nonexistent/dir', true, must_exist: false) }
          .to raise_error(ArgumentError, /path does not exist/)
      end

      it 'raises when both check=false and must_exist: true are given (more restrictive wins)' do
        expect(Git::Deprecation).to receive(:warn).once
        expect { described_instance.set_working('/nonexistent/dir', false, must_exist: true) }
          .to raise_error(ArgumentError, /path does not exist/)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #with_working
  # ---------------------------------------------------------------------------

  describe '#with_working' do
    let(:real_work_dir) { Dir.mktmpdir('context-helpers-') }
    let(:expanded_work_dir) { File.expand_path(real_work_dir) }

    after { FileUtils.remove_entry(real_work_dir, true) }

    before do
      allow(Dir).to receive(:chdir).with(expanded_work_dir).and_yield
    end

    it_behaves_like 'a helper that requires a repository block' do
      let(:call_helper) { ->(&block) { described_instance.with_working(real_work_dir, &block) } }
    end

    it 'yields a repository other than the receiver bound to the new working directory' do
      yielded = nil
      described_instance.with_working(real_work_dir) { |repo| yielded = repo }
      expect(yielded).to be_a(Git::Repository)
      expect(yielded).not_to be(described_instance)
      expect(yielded.dir).to eq(Pathname.new(expanded_work_dir))
    end

    it 'yields an instance of the receiver class' do
      subclass_instance = Class.new(Git::Repository).new(execution_context: execution_context)
      yielded = nil
      subclass_instance.with_working(real_work_dir) { |repo| yielded = repo }
      expect(yielded).to be_an_instance_of(subclass_instance.class)
    end

    it 'returns the value returned by the block' do
      result = described_instance.with_working(real_work_dir) { |_repo| 'result' }
      expect(result).to eq('result')
    end

    it 'changes the process directory to the expanded working directory during the block' do
      expect(Dir).to receive(:chdir).with(expanded_work_dir).and_yield
      described_instance.with_working(real_work_dir) { |_repo| nil }
    end

    it 'leaves the receiver execution context unchanged inside and after the block' do
      original_context = described_instance.execution_context
      context_in_block = nil
      described_instance.with_working(real_work_dir) { |_repo| context_in_block = described_instance.execution_context }
      expect(context_in_block).to be(original_context)
      expect(described_instance.execution_context).to be(original_context)
    end

    it 'leaves the receiver execution context unchanged when the block raises' do
      original_context = described_instance.execution_context
      expect { described_instance.with_working(real_work_dir) { |_repo| raise 'block error' } }
        .to raise_error('block error')
      expect(described_instance.execution_context).to be(original_context)
    end

    context 'when the working directory cannot be entered' do
      before do
        allow(Dir).to receive(:chdir).with(expanded_work_dir).and_raise(Errno::ENOENT, expanded_work_dir)
      end

      it 'raises Git::Error with the system error as cause' do
        expect { described_instance.with_working(real_work_dir) { |_repo| nil } }
          .to raise_error(Git::Error, /Failed to change directory.*No such file or directory/) do |error|
            expect(error.cause).to be_a(Errno::ENOENT)
          end
      end

      it 'leaves the receiver execution context unchanged' do
        original_context = described_instance.execution_context
        expect { described_instance.with_working(real_work_dir) { |_repo| nil } }
          .to raise_error(Git::Error, /Failed to change directory/)
        expect(described_instance.execution_context).to be(original_context)
      end
    end

    context 'when the block raises a SystemCallError' do
      it 'lets the SystemCallError propagate unchanged' do
        expect { described_instance.with_working(real_work_dir) { |_repo| raise Errno::ENOENT, 'caller.txt' } }
          .to raise_error(Errno::ENOENT, /caller\.txt/)
      end
    end

    it 'raises ArgumentError when work_dir does not exist' do
      expect do
        described_instance.with_working('/nonexistent/path/for/test') { |_| nil }
      end.to raise_error(ArgumentError, /path does not exist/)
    end
  end

  # ---------------------------------------------------------------------------
  # #with_temp_working
  # ---------------------------------------------------------------------------

  describe '#with_temp_working' do
    before do
      allow(Dir).to receive(:chdir).and_yield
    end

    it_behaves_like 'a helper that requires a repository block' do
      let(:call_helper) { ->(&block) { described_instance.with_temp_working(&block) } }
    end

    context 'when the block cannot receive the repository' do
      it 'does not create a temporary directory before rejecting the block' do
        allow(Dir).to receive(:mktmpdir).and_call_original
        expect { described_instance.with_temp_working { nil } }
          .to raise_error(ArgumentError, /block that accepts the yielded repository/)
        expect(Dir).not_to have_received(:mktmpdir)
      end
    end

    context 'when the temporary directory cannot be created' do
      before do
        allow(Dir).to receive(:mktmpdir).and_raise(Errno::EACCES, '/tmp')
      end

      it 'raises Git::Error with the system error as cause' do
        expect { described_instance.with_temp_working { |_repo| nil } }
          .to raise_error(Git::Error, /Failed to create or remove a temporary directory.*Permission denied/) do |error|
            expect(error.cause).to be_a(Errno::EACCES)
          end
      end
    end

    context 'when the temporary directory cannot be removed' do
      before do
        allow(FileUtils).to receive(:remove_entry).and_raise(Errno::EACCES, '/tmp/temp-workdir')
      end

      it 'raises Git::Error with the system error as cause' do
        expect { described_instance.with_temp_working { |_repo| nil } }
          .to raise_error(Git::Error, /Failed to create or remove a temporary directory.*Permission denied/) do |error|
            expect(error.cause).to be_a(Errno::EACCES)
          end
      end
    end

    context 'when the block raises a SystemCallError' do
      it 'lets the SystemCallError propagate unchanged' do
        expect { described_instance.with_temp_working { |_repo| raise Errno::ENOENT, 'caller.txt' } }
          .to raise_error(Errno::ENOENT, /caller\.txt/)
      end
    end

    it 'yields a repository other than the receiver' do
      yielded = nil
      described_instance.with_temp_working { |repo| yielded = repo }
      expect(yielded).to be_a(Git::Repository)
      expect(yielded).not_to be(described_instance)
    end

    it 'yields a repository bound to a new temporary working directory' do
      yielded_dir = nil
      described_instance.with_temp_working { |repo| yielded_dir = repo.dir }
      expect(yielded_dir).not_to eq(Pathname.new(work_dir))
      expect(yielded_dir.basename.to_s).to start_with('temp-workdir')
    end

    it 'leaves the receiver execution context unchanged inside and after the block' do
      original_context = described_instance.execution_context
      context_in_block = nil
      described_instance.with_temp_working { |_repo| context_in_block = described_instance.execution_context }
      expect(context_in_block).to be(original_context)
      expect(described_instance.execution_context).to be(original_context)
    end

    it 'cleans up the temporary directory after the block succeeds' do
      temp_dir = nil
      described_instance.with_temp_working { |repo| temp_dir = repo.dir.to_s }
      expect(temp_dir).not_to be_nil
      expect(Dir.exist?(temp_dir)).to be(false)
    end

    it 'cleans up the temporary directory even when the block raises' do
      temp_dir = nil
      expect do
        described_instance.with_temp_working do |repo|
          temp_dir = repo.dir.to_s
          raise 'block error'
        end
      end.to raise_error('block error')
      expect(temp_dir).not_to be_nil
      expect(Dir.exist?(temp_dir)).to be(false)
    end
  end

  # ---------------------------------------------------------------------------
  # Nesting: with_index inside with_working
  # ---------------------------------------------------------------------------

  describe 'nested context helpers' do
    before { allow(Dir).to receive(:chdir).and_yield }

    it 'yields a repository carrying both the working directory and index overrides' do
      inner = nil
      Dir.mktmpdir do |outer_work|
        described_instance.with_working(outer_work) do |working_repo|
          working_repo.with_index('/tmp/inner_idx') { |repo| inner = repo }
        end
        expect(inner.dir).to eq(Pathname.new(File.expand_path(outer_work)))
      end
      expect(inner.index).to eq(Pathname.new(File.expand_path('/tmp/inner_idx')))
    end

    it 'derives a nested call on the outer repository from the outer repository, not the outer block' do
      inner = nil
      Dir.mktmpdir do |outer_work|
        described_instance.with_working(outer_work) do |_working_repo|
          described_instance.with_index('/tmp/inner_idx') { |repo| inner = repo }
        end
      end
      expect(inner.dir).to eq(Pathname.new(work_dir))
    end

    it 'leaves the receiver execution context unchanged after nested with_index inside with_working' do
      original_context = described_instance.execution_context

      Dir.mktmpdir do |outer_work|
        described_instance.with_working(outer_work) do |working_repo|
          working_repo.with_index('/tmp/inner_idx') { |_repo| nil }
        end
      end

      expect(described_instance.execution_context).to be(original_context)
    end
  end
end
