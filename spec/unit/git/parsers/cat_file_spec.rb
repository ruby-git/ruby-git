# frozen_string_literal: true

require 'spec_helper'
require 'git/parsers/cat_file'

RSpec.describe Git::Parsers::CatFile do
  describe '.parse_commit' do
    context 'with a single-parent commit' do
      subject(:result) do
        lines = [
          'tree abc123',
          'parent def456',
          'author A <a@example.com> 1 +0000',
          'committer A <a@example.com> 1 +0000',
          '',
          'Initial commit'
        ]
        described_class.parse_commit(lines, 'HEAD')
      end

      it 'includes sha set to the passed object name' do
        expect(result['sha']).to eq('HEAD')
      end

      it 'includes the tree SHA' do
        expect(result['tree']).to eq('abc123')
      end

      it 'includes the parent SHA as a single-element Array' do
        expect(result['parent']).to eq(['def456'])
      end

      it 'includes the author string' do
        expect(result['author']).to eq('A <a@example.com> 1 +0000')
      end

      it 'includes the committer string' do
        expect(result['committer']).to eq('A <a@example.com> 1 +0000')
      end

      it 'includes the commit message with a trailing newline' do
        expect(result['message']).to eq("Initial commit\n")
      end
    end

    context 'with a root commit (no parent lines)' do
      subject(:result) do
        lines = [
          'tree def456',
          'author A <a@example.com> 1 +0000',
          'committer A <a@example.com> 1 +0000',
          '',
          'Root commit'
        ]
        described_class.parse_commit(lines, 'abc123')
      end

      it 'returns an empty parent Array' do
        expect(result['parent']).to eq([])
      end

      it 'includes the commit message' do
        expect(result['message']).to eq("Root commit\n")
      end
    end

    context 'with a merge commit (multiple parents)' do
      subject(:result) do
        lines = [
          'tree abc123',
          'parent def456',
          'parent ghi789',
          'author A <a@example.com> 1 +0000',
          'committer A <a@example.com> 1 +0000',
          '',
          "Merge branch 'feature'"
        ]
        described_class.parse_commit(lines, 'HEAD')
      end

      it 'returns all parent SHAs in the parent Array' do
        expect(result['parent']).to eq(%w[def456 ghi789])
      end
    end

    context 'with a signed commit (gpgsig header with continuation lines)' do
      subject(:result) do
        lines = [
          'tree abc123',
          'parent def456',
          'author A <a@example.com> 1 +0000',
          'committer A <a@example.com> 1 +0000',
          'gpgsig -----BEGIN PGP SIGNATURE-----',
          ' iQEzBAABCAAdFiEE...',
          ' -----END PGP SIGNATURE-----',
          '',
          'Signed commit message'
        ]
        described_class.parse_commit(lines, 'HEAD')
      end

      it 'folds the multi-line gpgsig header into a single value with embedded newlines' do
        expect(result['gpgsig']).to eq(
          "-----BEGIN PGP SIGNATURE-----\niQEzBAABCAAdFiEE...\n-----END PGP SIGNATURE-----"
        )
      end

      it 'does not include the signature text in the commit message' do
        expect(result['message']).to eq("Signed commit message\n")
      end
    end
  end

  describe '.parse_tag' do
    context 'with a standard annotated tag' do
      subject(:result) do
        lines = [
          'object deadbeef',
          'type commit',
          'tag v1.0',
          'tagger A <a@example.com> 1 +0000',
          '',
          'Release v1.0'
        ]
        described_class.parse_tag(lines, 'v1.0')
      end

      it 'includes name set to the passed tag name' do
        expect(result['name']).to eq('v1.0')
      end

      it 'includes the object SHA' do
        expect(result['object']).to eq('deadbeef')
      end

      it 'includes the object type' do
        expect(result['type']).to eq('commit')
      end

      it 'includes the tag name header' do
        expect(result['tag']).to eq('v1.0')
      end

      it 'includes the tagger string' do
        expect(result['tagger']).to eq('A <a@example.com> 1 +0000')
      end

      it 'includes the message with a trailing newline' do
        expect(result['message']).to eq("Release v1.0\n")
      end
    end

    context 'with a multi-line tag message' do
      subject(:result) do
        lines = [
          'object deadbeef',
          'type commit',
          'tag v2.0',
          'tagger A <a@example.com> 1 +0000',
          '',
          'First line',
          '',
          'Second paragraph'
        ]
        described_class.parse_tag(lines, 'v2.0')
      end

      it 'includes the full message with all lines and a trailing newline' do
        expect(result['message']).to eq("First line\n\nSecond paragraph\n")
      end
    end
  end
end
