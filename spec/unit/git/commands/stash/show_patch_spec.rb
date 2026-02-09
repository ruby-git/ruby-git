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

      it 'returns CommandLineResult' do
        allow(execution_context).to receive(:command)
          .with('stash', 'show', '--patch', '--numstat', '--shortstat')
          .and_return(command_result(patch_output))

        result = command.call

        expect(result).to be_a(Git::CommandLineResult)
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

    context 'with :dirstat option' do
      it 'adds --dirstat flag when true' do
        expect(execution_context).to receive(:command)
          .with('stash', 'show', '--patch', '--numstat', '--shortstat', '--dirstat')
          .and_return(command_result(patch_output))

        command.call(dirstat: true)
      end

      it 'passes dirstat options when string' do
        expect(execution_context).to receive(:command)
          .with('stash', 'show', '--patch', '--numstat', '--shortstat', '--dirstat=lines,cumulative')
          .and_return(command_result(patch_output))

        command.call(dirstat: 'lines,cumulative')
      end
    end
  end
end
