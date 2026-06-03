# frozen_string_literal: true

require 'spec_helper'
require 'git/repository'
require 'git/repository/staging'
require 'git/execution_context/repository'

# Integration tests for Git::Repository::Staging.
#
# Only #ignored_files is exercised end-to-end here because it performs
# facade-owned post-processing of real git output (splitting `git ls-files`
# stdout into paths and unescaping git-quoted paths). A real git invocation
# proves that post-processing handles actual output.
#
# The other facade methods are single-command delegators whose only
# facade-owned behavior is pure-Ruby argument pre-processing (option
# whitelisting for #add/#reset/#rm/#clean and deprecated-option migration for
# #clean). Real git adds no signal for those transforms, and their end-to-end
# git behavior is already covered by the underlying command integration specs:
#   spec/integration/git/commands/add_spec.rb
#   spec/integration/git/commands/reset_spec.rb
#   spec/integration/git/commands/rm_spec.rb
#   spec/integration/git/commands/clean_spec.rb

RSpec.describe Git::Repository::Staging, :integration do
  include_context 'in an empty repository'

  let(:execution_context) { Git::ExecutionContext::Repository.from_base(repo) }
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
end
