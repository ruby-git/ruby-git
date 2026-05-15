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

  describe '#cat_file_type' do
    context 'with a commit reference' do
      it 'returns "commit"' do
        expect(described_instance.cat_file_type('HEAD')).to eq('commit')
      end
    end

    context 'with a tree reference' do
      it 'returns "tree"' do
        tree_sha = repo.lib.rev_parse('HEAD^{tree}')
        expect(described_instance.cat_file_type(tree_sha)).to eq('tree')
      end
    end

    context 'with a blob via treeish path' do
      it 'returns "blob"' do
        expect(described_instance.cat_file_type('HEAD:README.md')).to eq('blob')
      end
    end

    context 'when object starts with a hyphen' do
      it 'raises ArgumentError without calling git' do
        expect { described_instance.cat_file_type('--batch') }
          .to raise_error(ArgumentError, "Invalid object: '--batch'")
      end
    end

    context 'when the object does not exist' do
      it 'raises Git::FailedError' do
        expect { described_instance.cat_file_type('0000000000000000000000000000000000000000') }
          .to raise_error(Git::FailedError)
      end
    end
  end

  describe '#cat_file_commit' do
    context 'with HEAD' do
      subject(:result) { described_instance.cat_file_commit('HEAD') }

      it 'returns a Hash' do
        expect(result).to be_a(Hash)
      end

      it 'sets sha to the requested object name' do
        expect(result['sha']).to eq('HEAD')
      end

      it 'includes tree, parent, author, committer, and message keys' do
        expect(result).to include('tree', 'parent', 'author', 'committer', 'message')
      end

      it 'sets parent to an Array' do
        expect(result['parent']).to be_a(Array)
      end

      it 'sets message with a trailing newline' do
        expect(result['message']).to end_with("\n")
      end

      it 'sets message to the commit message used when the commit was created' do
        expect(result['message']).to eq("Initial commit\n")
      end
    end

    context 'when called with a commit SHA' do
      it 'sets sha to the given SHA string' do
        sha = repo.lib.rev_parse('HEAD')
        result = described_instance.cat_file_commit(sha)
        expect(result['sha']).to eq(sha)
      end
    end

    context 'when the object does not exist' do
      it 'raises Git::FailedError' do
        expect { described_instance.cat_file_commit('0000000000000000000000000000000000000000') }
          .to raise_error(Git::FailedError)
      end
    end
  end

  describe '#cat_file_tag' do
    before do
      repo.add_tag('v1.0', annotate: true, message: 'Release v1.0')
    end

    context 'with a valid annotated tag' do
      subject(:result) { described_instance.cat_file_tag('v1.0') }

      it 'returns a Hash' do
        expect(result).to be_a(Hash)
      end

      it 'sets name to the tag name passed by the caller' do
        expect(result['name']).to eq('v1.0')
      end

      it 'includes the expected keys' do
        expect(result).to include('name', 'object', 'type', 'tag', 'tagger', 'message')
      end

      it 'sets type to "commit"' do
        expect(result['type']).to eq('commit')
      end

      it 'sets tag to the tag name' do
        expect(result['tag']).to eq('v1.0')
      end

      it 'sets message to the tag message with a trailing newline' do
        expect(result['message']).to eq("Release v1.0\n")
      end

      it 'sets object to a 40-character SHA' do
        expect(result['object']).to match(/\A[0-9a-f]{40}\z/)
      end
    end

    context 'when object starts with a hyphen' do
      it 'raises ArgumentError without calling git' do
        expect { described_instance.cat_file_tag('--all') }
          .to raise_error(ArgumentError, "Invalid object: '--all'")
      end
    end

    context 'when the object does not exist' do
      it 'raises Git::FailedError' do
        expect { described_instance.cat_file_tag('nonexistent_tag') }
          .to raise_error(Git::FailedError)
      end
    end

    context 'with an annotated tag whose message is empty' do
      before do
        repo.add_tag('v2.0', annotate: true, message: '')
      end

      it 'returns a Hash without raising NoMethodError' do
        expect { described_instance.cat_file_tag('v2.0') }.not_to raise_error
      end

      it 'sets message to a single newline' do
        result = described_instance.cat_file_tag('v2.0')
        expect(result['message']).to eq("\n")
      end
    end
  end
end
