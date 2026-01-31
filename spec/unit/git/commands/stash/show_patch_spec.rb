# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/stash/show_patch'

RSpec.describe Git::Commands::Stash::ShowPatch do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  # Combined --numstat, --shortstat, and --patch output (numstat first, then shortstat, then patches)
  let(:patch_output) do
    <<~PATCH
      3\t1\tlib/foo.rb
      1\t0\tlib/bar.rb
       2 files changed, 4 insertions(+), 1 deletion(-)
      diff --git a/lib/foo.rb b/lib/foo.rb
      index abc1234..def5678 100644
      --- a/lib/foo.rb
      +++ b/lib/foo.rb
      @@ -1,3 +1,5 @@
      +# New comment
       def foo
      -  old_code
      +  new_code
      +  more_code
       end
      diff --git a/lib/bar.rb b/lib/bar.rb
      index 1111111..2222222 100644
      --- a/lib/bar.rb
      +++ b/lib/bar.rb
      @@ -1 +1,2 @@
       def bar
      +  code
       end
    PATCH
  end

  describe '#call' do
    context 'with no arguments (latest stash)' do
      it 'calls git stash show --patch --numstat --shortstat' do
        expect(execution_context).to receive(:command)
          .with('stash', 'show', '--patch', '--numstat', '--shortstat')
          .and_return(command_result(patch_output))

        command.call
      end

      it 'returns DiffResult' do
        allow(execution_context).to receive(:command)
          .with('stash', 'show', '--patch', '--numstat', '--shortstat')
          .and_return(command_result(patch_output))

        result = command.call

        expect(result).to be_a(Git::DiffResult)
        expect(result.files.size).to eq(2)
        expect(result.files_changed).to eq(2)
        expect(result.total_insertions).to eq(4)
        expect(result.total_deletions).to eq(1)
        expect(result.dirstat).to be_nil
      end

      it 'parses DiffFilePatchInfo correctly' do
        allow(execution_context).to receive(:command)
          .with('stash', 'show', '--patch', '--numstat', '--shortstat')
          .and_return(command_result(patch_output))

        result = command.call

        foo_patch = result.files.find { |f| f.path == 'lib/foo.rb' }
        expect(foo_patch).to be_a(Git::DiffFilePatchInfo)
        expect(foo_patch.path).to eq('lib/foo.rb')
        expect(foo_patch.src).to be_a(Git::FileRef)
        expect(foo_patch.src.sha).to eq('abc1234')
        expect(foo_patch.src.mode).to eq('100644')
        expect(foo_patch.src.path).to eq('lib/foo.rb')
        expect(foo_patch.dst).to be_a(Git::FileRef)
        expect(foo_patch.dst.sha).to eq('def5678')
        expect(foo_patch.dst.mode).to eq('100644')
        expect(foo_patch.dst.path).to eq('lib/foo.rb')
        expect(foo_patch.status).to eq(:modified)
        expect(foo_patch.binary?).to be false
        expect(foo_patch.insertions).to eq(3)
        expect(foo_patch.deletions).to eq(1)
      end
    end

    context 'with specific stash reference' do
      it 'passes stash reference to command' do
        expect(execution_context).to receive(:command)
          .with('stash', 'show', '--patch', '--numstat', '--shortstat', 'stash@{2}')
          .and_return(command_result(patch_output))

        command.call('stash@{2}')
      end
    end

    context 'with :include_untracked option' do
      it 'adds --include-untracked flag when true' do
        expect(execution_context).to receive(:command)
          .with('stash', 'show', '--patch', '--numstat', '--shortstat', '--include-untracked')
          .and_return(command_result(patch_output))

        command.call(include_untracked: true)
      end

      it 'adds --no-include-untracked flag when false' do
        expect(execution_context).to receive(:command)
          .with('stash', 'show', '--patch', '--numstat', '--shortstat', '--no-include-untracked')
          .and_return(command_result(patch_output))

        command.call(include_untracked: false)
      end

      it 'accepts :u alias' do
        expect(execution_context).to receive(:command)
          .with('stash', 'show', '--patch', '--numstat', '--shortstat', '--include-untracked')
          .and_return(command_result(patch_output))

        command.call(u: true)
      end
    end

    context 'with :only_untracked option' do
      it 'adds --only-untracked flag' do
        expect(execution_context).to receive(:command)
          .with('stash', 'show', '--patch', '--numstat', '--shortstat', '--only-untracked')
          .and_return(command_result(patch_output))

        command.call(only_untracked: true)
      end
    end

    context 'with empty stash diff' do
      it 'returns DiffResult with no files' do
        allow(execution_context).to receive(:command)
          .with('stash', 'show', '--patch', '--numstat', '--shortstat')
          .and_return(command_result(''))

        result = command.call

        expect(result.files).to be_empty
        expect(result.files_changed).to eq(0)
      end
    end

    context 'patch parsing' do
      let(:new_file_patch) do
        <<~PATCH
          1\t0\tnew_file.rb
           1 file changed, 1 insertion(+)
          diff --git a/new_file.rb b/new_file.rb
          new file mode 100644
          index 0000000..abc1234
          --- /dev/null
          +++ b/new_file.rb
          @@ -0,0 +1 @@
          +content
        PATCH
      end

      let(:deleted_file_patch) do
        <<~PATCH
          0\t1\tdeleted.rb
           1 file changed, 1 deletion(-)
          diff --git a/deleted.rb b/deleted.rb
          deleted file mode 100644
          index abc1234..0000000
          --- a/deleted.rb
          +++ /dev/null
          @@ -1 +0,0 @@
          -content
        PATCH
      end

      let(:binary_patch) do
        <<~PATCH
          -\t-\timage.png
           1 file changed, 0 insertions(+), 0 deletions(-)
          diff --git a/image.png b/image.png
          index abc1234..def5678 100644
          Binary files a/image.png and b/image.png differ
        PATCH
      end

      let(:renamed_file_patch) do
        <<~PATCH
          0\t0\tnew_name.rb
           1 file changed
          diff --git a/old_name.rb b/new_name.rb
          similarity index 95%
          rename from old_name.rb
          rename to new_name.rb
          index abc1234..def5678 100644
        PATCH
      end

      it 'parses new file as added status with dst only' do
        allow(execution_context).to receive(:command)
          .with('stash', 'show', '--patch', '--numstat', '--shortstat')
          .and_return(command_result(new_file_patch))

        result = command.call
        patch = result.files.find { |f| f.path == 'new_file.rb' }

        expect(patch.status).to eq(:added)
        expect(patch.added?).to be true
        expect(patch.src).to be_nil
        expect(patch.dst).to be_a(Git::FileRef)
        expect(patch.dst.mode).to eq('100644')
        expect(patch.insertions).to eq(1)
        expect(patch.deletions).to eq(0)
      end

      it 'parses deleted file as deleted status with src only' do
        allow(execution_context).to receive(:command)
          .with('stash', 'show', '--patch', '--numstat', '--shortstat')
          .and_return(command_result(deleted_file_patch))

        result = command.call
        patch = result.files.find { |f| f.path == 'deleted.rb' }

        expect(patch.status).to eq(:deleted)
        expect(patch.deleted?).to be true
        expect(patch.src).to be_a(Git::FileRef)
        expect(patch.src.mode).to eq('100644')
        expect(patch.dst).to be_nil
        expect(patch.insertions).to eq(0)
        expect(patch.deletions).to eq(1)
      end

      it 'parses binary file indicator' do
        allow(execution_context).to receive(:command)
          .with('stash', 'show', '--patch', '--numstat', '--shortstat')
          .and_return(command_result(binary_patch))

        result = command.call
        patch = result.files.find { |f| f.path == 'image.png' }

        expect(patch.binary?).to be true
        expect(patch.insertions).to eq(0)
        expect(patch.deletions).to eq(0)
      end

      it 'parses renamed file with similarity index' do
        allow(execution_context).to receive(:command)
          .with('stash', 'show', '--patch', '--numstat', '--shortstat')
          .and_return(command_result(renamed_file_patch))

        result = command.call
        patch = result.files.find { |f| f.path == 'new_name.rb' }

        expect(patch.status).to eq(:renamed)
        expect(patch.renamed?).to be true
        expect(patch.similarity).to eq(95)
        expect(patch.src).to be_a(Git::FileRef)
        expect(patch.src.path).to eq('old_name.rb')
        expect(patch.dst).to be_a(Git::FileRef)
        expect(patch.dst.path).to eq('new_name.rb')
      end
    end

    context 'result totals from shortstat' do
      it 'gets total_insertions from shortstat' do
        allow(execution_context).to receive(:command)
          .with('stash', 'show', '--patch', '--numstat', '--shortstat')
          .and_return(command_result(patch_output))

        result = command.call

        expect(result.total_insertions).to eq(4)
      end

      it 'gets total_deletions from shortstat' do
        allow(execution_context).to receive(:command)
          .with('stash', 'show', '--patch', '--numstat', '--shortstat')
          .and_return(command_result(patch_output))

        result = command.call

        expect(result.total_deletions).to eq(1)
      end
    end

    context 'with :dirstat option' do
      let(:dirstat_output) do
        <<~PATCH
          3\t1\tlib/foo.rb
          1\t0\tlib/bar.rb
           2 files changed, 4 insertions(+), 1 deletion(-)
           100.0% lib/
          diff --git a/lib/foo.rb b/lib/foo.rb
          index abc1234..def5678 100644
          --- a/lib/foo.rb
          +++ b/lib/foo.rb
          @@ -1 +1,2 @@
          +code
        PATCH
      end

      it 'adds --dirstat flag when true' do
        expect(execution_context).to receive(:command)
          .with('stash', 'show', '--patch', '--numstat', '--shortstat', '--dirstat')
          .and_return(command_result(dirstat_output))

        command.call(dirstat: true)
      end

      it 'passes dirstat options when string' do
        expect(execution_context).to receive(:command)
          .with('stash', 'show', '--patch', '--numstat', '--shortstat', '--dirstat=lines,cumulative')
          .and_return(command_result(dirstat_output))

        command.call(dirstat: 'lines,cumulative')
      end

      it 'parses dirstat output into DirstatInfo' do
        allow(execution_context).to receive(:command)
          .with('stash', 'show', '--patch', '--numstat', '--shortstat', '--dirstat')
          .and_return(command_result(dirstat_output))

        result = command.call(dirstat: true)

        expect(result.dirstat).to be_a(Git::DirstatInfo)
        expect(result.dirstat['lib/']).to eq(100.0)
      end
    end
  end
end
