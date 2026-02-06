# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/fsck'

# Integration tests for Git::Commands::Fsck
#
# These tests verify the command's execution behavior. Parsing logic is
# tested separately in spec/integration/git/fsck_parser_spec.rb.
#
RSpec.describe Git::Commands::Fsck, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'when repository is clean' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
      end

      it 'returns a FsckResult' do
        result = command.call
        expect(result).to be_a(Git::FsckResult)
        expect(result.empty?).to be true
      end
    end

    context 'with dangling objects' do
      before do
        write_file('file.txt', 'original content')
        repo.add('file.txt')
        repo.commit('Initial commit')

        write_file('orphan.txt', 'orphaned content')
        repo.add('orphan.txt')
        repo.reset('HEAD', hard: true)
      end

      it 'detects dangling blobs' do
        result = command.call
        expect(result.dangling.any? { |obj| obj.type == :blob }).to be true
      end
    end

    context 'with :root option' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('First root commit')
      end

      it 'reports root commits' do
        result = command.call(root: true)
        expect(result.root).not_to be_empty
        expect(result.root.first.type).to eq(:commit)
      end
    end

    context 'with :tags option' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
        repo.add_tag('v1.0.0', annotate: true, message: 'Version 1.0.0')
      end

      it 'reports tagged objects' do
        result = command.call(tags: true)
        expect(result.tagged).not_to be_empty
      end
    end

    context 'with :strict option' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
      end

      it 'runs with strict checking enabled' do
        result = command.call(strict: true)
        expect(result).to be_a(Git::FsckResult)
      end
    end

    context 'with :dangling option set to false' do
      before do
        write_file('file.txt', 'original content')
        repo.add('file.txt')
        repo.commit('Initial commit')
        write_file('orphan.txt', 'orphaned content')
        repo.add('orphan.txt')
        repo.reset('HEAD', hard: true)
      end

      it 'suppresses dangling object output' do
        result = command.call(dangling: false)
        expect(result.dangling).to be_empty
      end
    end

    context 'with combined options' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
        repo.add_tag('v1.0.0', annotate: true, message: 'Release')
      end

      it 'accepts multiple options' do
        result = command.call(root: true, tags: true, strict: true)
        expect(result).to be_a(Git::FsckResult)
        expect(result.root).not_to be_empty
        expect(result.tagged).not_to be_empty
      end
    end

    context 'with specific objects' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
      end

      it 'checks specific objects by oid' do
        head_sha = `cd #{repo_dir} && git rev-parse HEAD`.strip
        result = command.call(head_sha)
        expect(result).to be_a(Git::FsckResult)
      end
    end
  end
end
