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

  describe '#rev_parse' do
    context 'with HEAD' do
      it 'returns a 40-character lowercase hex SHA' do
        result = described_instance.rev_parse('HEAD')
        expect(result).to match(/\A[0-9a-f]{40}\z/)
      end

      it 'returns a String' do
        expect(described_instance.rev_parse('HEAD')).to be_a(String)
      end
    end

    context 'with an abbreviated SHA' do
      it 'expands the abbreviated SHA to the full 40-character SHA' do
        full_sha = repo.lib.rev_parse('HEAD')
        abbreviated = full_sha[0, 7]
        expect(described_instance.rev_parse(abbreviated)).to eq(full_sha)
      end
    end

    context 'with a tree object via rev-parse syntax' do
      it 'resolves the tree SHA' do
        result = described_instance.rev_parse('HEAD^{tree}')
        expect(result).to match(/\A[0-9a-f]{40}\z/)
      end
    end

    context 'when the revision is unknown' do
      it 'raises Git::FailedError' do
        expect { described_instance.rev_parse('NOTFOUND') }
          .to raise_error(Git::FailedError)
      end
    end
  end

  describe '#grep' do
    before do
      write_file('src/foo.rb', "# TODO: fix this\nsome other line\n")
      write_file('src/bar.rb', "# NOTE: nothing here\n# TODO: also here\n")
      repo.add('.')
      repo.commit('Add files')
    end

    context 'with a pattern that matches files' do
      it 'returns a Hash with treeish:filename keys' do
        result = described_instance.grep('TODO')
        expect(result).to be_a(Hash)
        expect(result.keys).to all(match(%r{\AHEAD:src/}))
      end

      it 'maps each key to an array of [line_number, text] pairs' do
        result = described_instance.grep('TODO')
        result.each_value do |matches|
          expect(matches).to all(match([be_a(Integer), be_a(String)]))
        end
      end

      it 'includes the correct line number and text for each match' do
        result = described_instance.grep('TODO')
        foo_matches = result['HEAD:src/foo.rb']
        expect(foo_matches).to include([1, '# TODO: fix this'])
      end
    end

    context 'with a path_limiter String that restricts results' do
      it 'returns only matches under the given path' do
        result = described_instance.grep('TODO', 'src/foo.rb')
        expect(result.keys).to eq(['HEAD:src/foo.rb'])
      end
    end

    context 'with a path_limiter Array' do
      it 'returns matches from all paths in the array' do
        result = described_instance.grep('TODO', ['src/foo.rb', 'src/bar.rb'])
        expect(result.keys).to contain_exactly('HEAD:src/foo.rb', 'HEAD:src/bar.rb')
      end
    end

    context 'with :ignore_case option' do
      it 'returns matches regardless of case' do
        result = described_instance.grep('todo', nil, ignore_case: true)
        expect(result).not_to be_empty
      end

      it 'returns no matches without ignore_case when pattern case differs' do
        result = described_instance.grep('todo')
        expect(result).to be_empty
      end
    end

    context 'with :invert_match option' do
      it 'returns lines that do not match the pattern' do
        result = described_instance.grep('TODO', 'src/foo.rb', invert_match: true)
        expect(result['HEAD:src/foo.rb']).to include([2, 'some other line'])
        expect(result['HEAD:src/foo.rb'].map(&:last)).not_to include(match(/TODO/))
      end
    end

    context 'with :extended_regexp option' do
      it 'matches using POSIX extended regular expressions' do
        result = described_instance.grep('TODO|NOTE', nil, extended_regexp: true)
        expect(result.keys).to contain_exactly('HEAD:src/foo.rb', 'HEAD:src/bar.rb')
      end
    end

    context 'with :object option pointing to a specific commit' do
      it 'searches in that commit instead of HEAD' do
        sha = repo.lib.rev_parse('HEAD')
        result = described_instance.grep('TODO', nil, object: sha)
        expect(result).not_to be_empty
      end
    end

    context 'when no lines match' do
      it 'returns an empty hash' do
        result = described_instance.grep('NOMATCH_UNIQUE_XYZ')
        expect(result).to eq({})
      end
    end

    context 'with an unknown option' do
      it 'raises ArgumentError without calling git' do
        expect { described_instance.grep('TODO', nil, line_number: true) }
          .to raise_error(ArgumentError, 'Unknown options: line_number')
      end
    end

    context 'with an invalid object reference' do
      it 'raises Git::FailedError' do
        expect { described_instance.grep('TODO', nil, object: 'nonexistent_ref') }
          .to raise_error(Git::FailedError)
      end
    end
  end
end
