# frozen_string_literal: true

require 'spec_helper'
require 'git/repository'
require 'git/repository/object_operations'
require 'git/execution_context/repository'

RSpec.describe Git::Repository::ObjectOperations, :integration do
  include_context 'in an empty repository'

  let(:execution_context) { Git::ExecutionContext::Repository.from_base(repo) }
  let(:described_instance) { Git::Repository.new(execution_context: execution_context) }

  before do
    write_file('README.md', "# Hello World\n")
    repo.add('README.md')
    repo.commit('Initial commit')
  end

  describe '#cat_file_contents' do
    context 'with a blob via treeish path' do
      it 'returns the raw content of the blob as a String' do
        result = described_instance.cat_file_contents('HEAD:README.md')
        expect(result).to be_a(String)
        expect(result).to include('# Hello World')
      end
    end

    context 'with a commit object' do
      it 'returns the raw content of the commit as a String' do
        result = described_instance.cat_file_contents('HEAD')
        expect(result).to be_a(String)
        expect(result).to include('tree ')
        expect(result).to include('author ')
      end
    end

    context 'with a block' do
      it 'yields a File positioned at the start of the content' do
        yielded_content = nil
        described_instance.cat_file_contents('HEAD:README.md') do |f|
          yielded_content = f.read
        end
        expect(yielded_content).to eq("# Hello World\n")
      end

      it 'returns the value returned by the block' do
        result = described_instance.cat_file_contents('HEAD:README.md') { |_f| :my_value }
        expect(result).to eq(:my_value)
      end
    end

    context 'when object starts with a hyphen' do
      it 'raises ArgumentError without calling git' do
        expect { described_instance.cat_file_contents('--batch') }
          .to raise_error(ArgumentError, "Invalid object: '--batch'")
      end
    end

    context 'when the object does not exist' do
      it 'raises Git::FailedError' do
        expect { described_instance.cat_file_contents('0000000000000000000000000000000000000000') }
          .to raise_error(Git::FailedError)
      end
    end
  end

  describe '#cat_file_size' do
    context 'with a commit object' do
      it 'returns the size of the commit as an Integer' do
        result = described_instance.cat_file_size('HEAD')
        expect(result).to be_a(Integer)
        expect(result).to be_positive
      end
    end

    context 'with a blob via treeish path' do
      it 'returns the size of the blob' do
        result = described_instance.cat_file_size('HEAD:README.md')
        expect(result).to eq(File.read(File.join(repo.dir.to_s, 'README.md')).bytesize)
      end
    end

    context 'with a tree object' do
      it 'returns the size of the tree object as an Integer' do
        tree_sha = repo.lib.rev_parse('HEAD^{tree}')
        result = described_instance.cat_file_size(tree_sha)
        expect(result).to be_a(Integer)
        expect(result).to be_positive
      end
    end

    context 'when object starts with a hyphen' do
      it 'raises ArgumentError without calling git' do
        expect { described_instance.cat_file_size('--batch') }
          .to raise_error(ArgumentError, "Invalid object: '--batch'")
      end
    end

    context 'when the object does not exist' do
      it 'raises Git::FailedError' do
        expect { described_instance.cat_file_size('0000000000000000000000000000000000000000') }
          .to raise_error(Git::FailedError)
      end
    end
  end
end
