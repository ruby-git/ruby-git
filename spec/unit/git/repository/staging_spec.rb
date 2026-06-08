# frozen_string_literal: true

require 'spec_helper'
require 'git/repository'
require 'git/repository/staging'

# Integration-level coverage for Git::Repository::Staging is provided by the
# underlying command integration tests:
#   spec/integration/git/commands/add_spec.rb
#   spec/integration/git/commands/reset_spec.rb
# Both #add and #reset delegate to a single Git::Commands::* class with no
# multi-command orchestration or facade-owned post-processing of git output.
# The unit specs below cover the facade's own behavior (option whitelisting);
# the command integration specs cover end-to-end
# git execution. No facade integration spec is needed.

RSpec.describe Git::Repository::Staging do
  let(:execution_context) { instance_double(Git::ExecutionContext::Repository) }
  let(:described_instance) { Git::Repository.new(execution_context: execution_context) }

  describe '#add' do
    subject(:result) { described_instance.add }

    let(:add_command) { instance_double(Git::Commands::Add) }
    let(:add_result) { command_result('add output') }

    before do
      allow(Git::Commands::Add).to receive(:new).with(execution_context).and_return(add_command)
    end

    context 'with default arguments' do
      it 'delegates to Git::Commands::Add#call with the default path' do
        expect(add_command).to receive(:call).with('.').and_return(add_result)
        result
      end

      it 'returns the command stdout' do
        allow(add_command).to receive(:call).with('.').and_return(add_result)
        expect(result).to eq('add output')
      end
    end

    context 'with a single file path' do
      subject(:result) { described_instance.add('path/to/file.rb') }

      it 'delegates to Git::Commands::Add#call with the given path' do
        expect(add_command).to receive(:call).with('path/to/file.rb').and_return(add_result)
        result
      end
    end

    context 'with an array of paths' do
      subject(:result) { described_instance.add(['a.rb', 'b.rb']) }

      it 'splatted paths are forwarded as separate arguments' do
        expect(add_command).to receive(:call).with('a.rb', 'b.rb').and_return(add_result)
        result
      end
    end

    context 'with force: true' do
      subject(:result) { described_instance.add('file.rb', force: true) }

      it 'forwards force: true to Git::Commands::Add#call' do
        expect(add_command).to receive(:call).with('file.rb', force: true).and_return(add_result)
        result
      end
    end

    context 'with all: true' do
      subject(:result) { described_instance.add('file.rb', all: true) }

      it 'forwards all: true to Git::Commands::Add#call' do
        expect(add_command).to receive(:call).with('file.rb', all: true).and_return(add_result)
        result
      end
    end

    context 'with an unknown option' do
      subject(:result) { described_instance.add('file.rb', bogus: true) }

      it 'raises ArgumentError' do
        expect { result }.to raise_error(ArgumentError, /Unknown options: bogus/)
      end

      it 'does not call Git::Commands::Add' do
        expect(add_command).not_to receive(:call)
        begin
          result
        rescue ArgumentError
          # expected
        end
      end
    end
  end

  describe '#reset' do
    subject(:result) { described_instance.reset }

    let(:reset_command) { instance_double(Git::Commands::Reset) }
    let(:reset_result) { command_result('reset output') }

    before do
      allow(Git::Commands::Reset).to receive(:new).with(execution_context).and_return(reset_command)
    end

    context 'with no arguments' do
      it 'delegates to Git::Commands::Reset#call with nil commit' do
        expect(reset_command).to receive(:call).with(nil).and_return(reset_result)
        result
      end

      it 'returns the command stdout' do
        allow(reset_command).to receive(:call).with(nil).and_return(reset_result)
        expect(result).to eq('reset output')
      end
    end

    context 'with a commitish' do
      subject(:result) { described_instance.reset('HEAD~1') }

      it 'delegates to Git::Commands::Reset#call with the given commitish' do
        expect(reset_command).to receive(:call).with('HEAD~1').and_return(reset_result)
        result
      end
    end

    context 'with options' do
      subject(:result) { described_instance.reset('HEAD~1', hard: true) }

      it 'forwards options to Git::Commands::Reset#call' do
        expect(reset_command).to receive(:call).with('HEAD~1', hard: true).and_return(reset_result)
        result
      end
    end

    context 'with an unknown option' do
      subject(:result) { described_instance.reset('HEAD~1', bogus: true) }

      it 'raises ArgumentError' do
        expect { result }.to raise_error(ArgumentError, /Unknown options: bogus/)
      end
    end
  end

  describe '#rm' do
    subject(:result) { described_instance.rm }

    let(:rm_command) { instance_double(Git::Commands::Rm) }
    let(:rm_result) { command_result('rm output') }

    before do
      allow(Git::Commands::Rm).to receive(:new).with(execution_context).and_return(rm_command)
    end

    context 'with default arguments' do
      it 'delegates to Git::Commands::Rm#call with the default pathspec' do
        expect(rm_command).to receive(:call).with('.').and_return(rm_result)
        result
      end

      it 'returns the command stdout' do
        allow(rm_command).to receive(:call).with('.').and_return(rm_result)
        expect(result).to eq('rm output')
      end
    end

    context 'with a single pathspec' do
      subject(:result) { described_instance.rm('file.rb') }

      it 'delegates to Git::Commands::Rm#call with the given pathspec' do
        expect(rm_command).to receive(:call).with('file.rb').and_return(rm_result)
        result
      end
    end

    context 'with an array of pathspecs' do
      subject(:result) { described_instance.rm(['a.rb', 'b.rb']) }

      it 'splatted pathspecs are forwarded as separate arguments' do
        expect(rm_command).to receive(:call).with('a.rb', 'b.rb').and_return(rm_result)
        result
      end
    end

    context 'with the force option' do
      subject(:result) { described_instance.rm('file.rb', force: true) }

      it 'forwards force: true to Git::Commands::Rm#call' do
        expect(rm_command).to receive(:call).with('file.rb', force: true).and_return(rm_result)
        result
      end
    end

    context 'with the cached option' do
      subject(:result) { described_instance.rm('file.rb', cached: true) }

      it 'forwards cached: true to Git::Commands::Rm#call' do
        expect(rm_command).to receive(:call).with('file.rb', cached: true).and_return(rm_result)
        result
      end
    end

    context 'with an unknown option' do
      subject(:result) { described_instance.rm('file.rb', bogus: true) }

      it 'raises ArgumentError' do
        expect { result }.to raise_error(ArgumentError, /Unknown options: bogus/)
      end

      it 'does not call Git::Commands::Rm' do
        expect(rm_command).not_to receive(:call)
        begin
          result
        rescue ArgumentError
          # expected
        end
      end
    end

    context 'signature compatibility' do
      subject(:result) { described_instance.rm('file.rb', { force: true }) }

      it 'accepts the legacy positional options hash' do
        expect(rm_command).to receive(:call).with('file.rb', force: true).and_return(rm_result)
        result
      end
    end
  end

  describe '#remove' do
    it 'is an alias for #rm' do
      expect(described_instance.method(:remove)).to eq(described_instance.method(:rm))
    end
  end

  describe '#clean' do
    subject(:result) { described_instance.clean }

    let(:clean_command) { instance_double(Git::Commands::Clean) }
    let(:clean_result) { command_result('clean output') }

    before do
      allow(Git::Commands::Clean).to receive(:new).with(execution_context).and_return(clean_command)
    end

    context 'with no options' do
      it 'delegates to Git::Commands::Clean#call with no arguments' do
        expect(clean_command).to receive(:call).with(no_args).and_return(clean_result)
        result
      end

      it 'returns the command stdout' do
        allow(clean_command).to receive(:call).with(no_args).and_return(clean_result)
        expect(result).to eq('clean output')
      end
    end

    context 'with force: true' do
      subject(:result) { described_instance.clean(force: true) }

      it 'forwards force: true to Git::Commands::Clean#call' do
        expect(clean_command).to receive(:call).with(force: true).and_return(clean_result)
        result
      end
    end

    context 'with force and d options' do
      subject(:result) { described_instance.clean(force: true, d: true) }

      it 'forwards force and d to Git::Commands::Clean#call' do
        expect(clean_command).to receive(:call).with(force: true, d: true).and_return(clean_result)
        result
      end
    end

    context 'with an unknown option' do
      subject(:result) { described_instance.clean(bogus: true) }

      it 'raises ArgumentError' do
        expect { result }.to raise_error(ArgumentError, /Unknown options: bogus/)
      end

      it 'does not call Git::Commands::Clean' do
        expect(clean_command).not_to receive(:call)
        begin
          result
        rescue ArgumentError
          # expected
        end
      end
    end

    context 'with the deprecated :ff option set to true' do
      subject(:result) { described_instance.clean(ff: true) }

      it 'warns about the deprecation' do
        allow(clean_command).to receive(:call).and_return(clean_result)
        expect(Git::Deprecation).to receive(:warn).with(/:ff option is deprecated/)
        result
      end

      it 'translates :ff to force: 2' do
        allow(Git::Deprecation).to receive(:warn)
        expect(clean_command).to receive(:call).with(force: 2).and_return(clean_result)
        result
      end
    end

    context 'with the deprecated :ff option set to false' do
      subject(:result) { described_instance.clean(ff: false) }

      it 'warns about the deprecation' do
        allow(clean_command).to receive(:call).and_return(clean_result)
        expect(Git::Deprecation).to receive(:warn).with(/:ff option is deprecated/)
        result
      end

      it 'does not pass force to Git::Commands::Clean#call' do
        allow(Git::Deprecation).to receive(:warn)
        expect(clean_command).to receive(:call).with(no_args).and_return(clean_result)
        result
      end
    end

    context 'with the deprecated :force_force option set to true' do
      subject(:result) { described_instance.clean(force_force: true) }

      it 'warns about the deprecation' do
        allow(clean_command).to receive(:call).and_return(clean_result)
        expect(Git::Deprecation).to receive(:warn).with(/:force_force option is deprecated/)
        result
      end

      it 'translates :force_force to force: 2' do
        allow(Git::Deprecation).to receive(:warn)
        expect(clean_command).to receive(:call).with(force: 2).and_return(clean_result)
        result
      end
    end

    context 'with the deprecated :ff option set to a non-boolean value' do
      subject(:result) { described_instance.clean(ff: 0) }

      it 'raises ArgumentError' do
        expect { result }.to raise_error(ArgumentError, /ff option only accepts true, false, or nil/)
      end

      it 'does not call Git::Commands::Clean' do
        expect(clean_command).not_to receive(:call)
        begin
          result
        rescue ArgumentError
          # expected
        end
      end
    end

    context 'with the deprecated :ff option combined with an explicit force: true' do
      subject(:result) { described_instance.clean(ff: true, force: true) }

      before { allow(Git::Deprecation).to receive(:warn) }

      it 'normalizes force: true to 1 then raises it to force: 2' do
        expect(clean_command).to receive(:call).with(force: 2).and_return(clean_result)
        result
      end
    end

    context 'with the deprecated :ff option combined with an explicit force: false' do
      subject(:result) { described_instance.clean(ff: true, force: false) }

      before { allow(Git::Deprecation).to receive(:warn) }

      it 'translates the explicit false force to force: 2' do
        expect(clean_command).to receive(:call).with(force: 2).and_return(clean_result)
        result
      end
    end

    context 'with the deprecated :ff option combined with an explicit integer force >= 1' do
      subject(:result) { described_instance.clean(ff: true, force: 3) }

      before { allow(Git::Deprecation).to receive(:warn) }

      it 'keeps the larger of the explicit force and 2' do
        expect(clean_command).to receive(:call).with(force: 3).and_return(clean_result)
        result
      end
    end

    context 'with the deprecated :ff option combined with an explicit force: 0' do
      subject(:result) { described_instance.clean(ff: true, force: 0) }

      before { allow(Git::Deprecation).to receive(:warn) }

      it 'forwards the below-one integer force value unchanged' do
        expect(clean_command).to receive(:call).with(force: 0).and_return(clean_result)
        result
      end
    end

    context 'with the deprecated :ff option combined with a non-integer force value' do
      subject(:result) { described_instance.clean(ff: true, force: 1.5) }

      before { allow(Git::Deprecation).to receive(:warn) }

      it 'forwards the non-integer force value unchanged' do
        expect(clean_command).to receive(:call).with(force: 1.5).and_return(clean_result)
        result
      end
    end

    context 'signature compatibility' do
      subject(:result) { described_instance.clean({ force: true }) }

      it 'accepts the legacy positional options hash' do
        expect(clean_command).to receive(:call).with(force: true).and_return(clean_result)
        result
      end
    end
  end

  describe '#reset_hard' do
    subject(:result) { described_instance.reset_hard }

    let(:reset_command) { instance_double(Git::Commands::Reset) }
    let(:reset_result) { command_result('reset output') }

    before do
      allow(Git::Commands::Reset).to receive(:new).with(execution_context).and_return(reset_command)
      allow(Git::Deprecation).to receive(:warn)
    end

    it 'emits a deprecation warning' do
      allow(reset_command).to receive(:call).and_return(reset_result)
      expect(Git::Deprecation).to receive(:warn).with(/reset_hard is deprecated/)
      result
    end

    it 'delegates to reset with hard: true' do
      expect(reset_command).to receive(:call).with(nil, hard: true).and_return(reset_result)
      result
    end

    context 'with a commitish' do
      subject(:result) { described_instance.reset_hard('HEAD~1') }

      it 'passes the commitish to reset' do
        expect(reset_command).to receive(:call).with('HEAD~1', hard: true).and_return(reset_result)
        result
      end
    end

    context 'when hard: false is passed in opts' do
      subject(:result) { described_instance.reset_hard(nil, hard: false) }

      it 'enforces hard: true regardless of opts' do
        expect(reset_command).to receive(:call).with(nil, hard: true).and_return(reset_result)
        result
      end
    end
  end

  describe '#apply' do
    subject(:result) { described_instance.apply(patch_file) }

    let(:apply_command) { instance_double(Git::Commands::Apply) }
    let(:apply_result) { command_result('') }
    let(:patch_file) { '/tmp/fix.patch' }
    let(:work_dir) { '/path/to/work/tree' }

    before do
      allow(Git::Commands::Apply).to receive(:new).with(execution_context).and_return(apply_command)
      allow(execution_context).to receive(:git_work_dir).and_return(work_dir)
    end

    context 'when the file exists' do
      before do
        allow(File).to receive(:exist?).with(patch_file).and_return(true)
      end

      it 'delegates to Git::Commands::Apply#call with the file and chdir' do
        expect(apply_command).to receive(:call).with(patch_file, chdir: work_dir).and_return(apply_result)
        result
      end

      it 'returns the command stdout' do
        allow(apply_command).to receive(:call).with(patch_file, chdir: work_dir).and_return(command_result('applied'))
        expect(result).to eq('applied')
      end
    end

    context 'when the file does not exist' do
      before do
        allow(File).to receive(:exist?).with(patch_file).and_return(false)
      end

      it 'returns nil without calling git' do
        expect(apply_command).not_to receive(:call)
        expect(result).to be_nil
      end
    end

    context 'signature compatibility' do
      before do
        allow(File).to receive(:exist?).with(patch_file).and_return(true)
        allow(apply_command).to receive(:call).with(patch_file, chdir: work_dir).and_return(apply_result)
      end

      it 'accepts a positional file argument' do
        expect(described_instance.apply(patch_file)).to eq('')
      end
    end
  end

  describe '#apply_mail' do
    subject(:result) { described_instance.apply_mail(mbox_file) }

    let(:am_apply_command) { instance_double(Git::Commands::Am::Apply) }
    let(:am_apply_result) { command_result('') }
    let(:mbox_file) { '/tmp/patches.mbox' }
    let(:work_dir) { '/path/to/work/tree' }

    before do
      allow(Git::Commands::Am::Apply).to receive(:new).with(execution_context).and_return(am_apply_command)
      allow(execution_context).to receive(:git_work_dir).and_return(work_dir)
    end

    context 'when the file exists' do
      before do
        allow(File).to receive(:exist?).with(mbox_file).and_return(true)
      end

      it 'delegates to Git::Commands::Am::Apply#call with the file and chdir' do
        expect(am_apply_command).to receive(:call).with(mbox_file, chdir: work_dir).and_return(am_apply_result)
        result
      end

      it 'returns the command stdout' do
        allow(am_apply_command).to receive(:call)
          .with(mbox_file, chdir: work_dir).and_return(command_result('applied mail'))
        expect(result).to eq('applied mail')
      end
    end

    context 'when the file does not exist' do
      before do
        allow(File).to receive(:exist?).with(mbox_file).and_return(false)
      end

      it 'returns nil without calling git' do
        expect(am_apply_command).not_to receive(:call)
        expect(result).to be_nil
      end
    end

    context 'signature compatibility' do
      before do
        allow(File).to receive(:exist?).with(mbox_file).and_return(true)
        allow(am_apply_command).to receive(:call).with(mbox_file, chdir: work_dir).and_return(am_apply_result)
      end

      it 'accepts a positional file argument' do
        expect(described_instance.apply_mail(mbox_file)).to eq('')
      end
    end
  end

  describe '#read_tree' do
    subject(:result) { described_instance.read_tree('HEAD') }

    let(:read_tree_command) { instance_double(Git::Commands::ReadTree) }
    let(:read_tree_result) { command_result('') }

    before do
      allow(Git::Commands::ReadTree).to receive(:new).with(execution_context).and_return(read_tree_command)
    end

    context 'with a treeish and no options' do
      it 'delegates to Git::Commands::ReadTree#call with the treeish' do
        expect(read_tree_command).to receive(:call).with('HEAD').and_return(read_tree_result)
        result
      end

      it 'returns the command stdout' do
        allow(read_tree_command).to receive(:call).with('HEAD').and_return(command_result('output'))
        expect(result).to eq('output')
      end
    end

    context 'with the prefix option' do
      subject(:result) { described_instance.read_tree('HEAD', { prefix: 'sub/' }) }

      it 'forwards the prefix option to Git::Commands::ReadTree#call' do
        expect(read_tree_command).to receive(:call).with('HEAD', prefix: 'sub/').and_return(read_tree_result)
        result
      end
    end

    context 'with an unknown option' do
      subject(:result) { described_instance.read_tree('HEAD', { bogus: true }) }

      it 'raises ArgumentError' do
        expect { result }.to raise_error(ArgumentError, /Unknown options: bogus/)
      end

      it 'does not call Git::Commands::ReadTree' do
        expect(read_tree_command).not_to receive(:call)
        begin
          result
        rescue ArgumentError
          # expected
        end
      end
    end

    context 'signature compatibility' do
      subject(:result) { described_instance.read_tree('HEAD', { prefix: 'sub/' }) }

      it 'accepts the legacy positional options hash' do
        expect(read_tree_command).to receive(:call).with('HEAD', prefix: 'sub/').and_return(read_tree_result)
        result
      end
    end
  end

  describe '#ignored_files' do
    subject(:result) { described_instance.ignored_files }

    let(:ls_files_command) { instance_double(Git::Commands::LsFiles) }

    before do
      allow(Git::Commands::LsFiles).to receive(:new).with(execution_context).and_return(ls_files_command)
    end

    it 'lists ignored, non-tracked files via git ls-files' do
      expect(ls_files_command).to(
        receive(:call).with(others: true, ignored: true, exclude_standard: true)
                      .and_return(command_result("a.log\nb.log\n"))
      )
      result
    end

    it 'returns the ignored files as an array of paths' do
      allow(ls_files_command).to receive(:call).and_return(command_result("a.log\ntmp/b.log\n"))
      expect(result).to eq(['a.log', 'tmp/b.log'])
    end

    it 'returns an empty array when there are no ignored files' do
      allow(ls_files_command).to receive(:call).and_return(command_result(''))
      expect(result).to eq([])
    end

    it 'unescapes git-quoted paths' do
      allow(ls_files_command).to receive(:call).and_return(command_result("\"qu\\303\\251.log\"\n"))
      expect(result).to eq(['qué.log'])
    end
  end
end
