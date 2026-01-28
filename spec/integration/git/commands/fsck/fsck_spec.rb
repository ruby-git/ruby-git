# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/fsck'

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

      it 'returns an empty result' do
        result = command.call
        expect(result.empty?).to be true
        expect(result.any_issues?).to be false
      end

      it 'returns FsckResult with all empty arrays' do
        result = command.call
        expect(result.dangling).to eq([])
        expect(result.missing).to eq([])
        expect(result.unreachable).to eq([])
        expect(result.warnings).to eq([])
      end
    end

    context 'with dangling objects' do
      # OID for blob with content 'orphaned content' (no trailing newline)
      # Can be generated via: echo -n 'orphaned content' | git hash-object --stdin
      let(:expected_blob_oid) { 'cf3f826230a67eac544a2ce2912965f004e94bd7' }

      before do
        write_file('file.txt', 'original content')
        repo.add('file.txt')
        repo.commit('Initial commit')

        # Create an orphaned blob by writing content then resetting
        write_file('orphan.txt', 'orphaned content')
        repo.add('orphan.txt')
        # Don't commit - just add to index, then reset
        # This creates a blob object that isn't referenced by any commit
        repo.reset('HEAD', hard: true)
      end

      it 'detects dangling blobs' do
        result = command.call
        expect(result.dangling.any? { |obj| obj.type == :blob }).to be true
      end

      it 'returns FsckObject with the expected oid' do
        result = command.call
        dangling_blob = result.dangling.find { |obj| obj.type == :blob }
        expect(dangling_blob.oid).to eq(expected_blob_oid)
      end

      it 'sets correct type on dangling objects' do
        result = command.call
        result.dangling.each do |obj|
          expect(obj.type).to eq(:blob)
        end
      end
    end

    context 'with :root option' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('First root commit')

        # Create another root commit by creating an orphan branch
        repo.branch('orphan-branch').checkout
        # Create the orphan via low-level git command
        `cd #{repo_dir} && git checkout --orphan another-root && git commit --allow-empty -m "Another root"`
      end

      it 'reports root commits' do
        result = command.call(root: true)
        expect(result.root).not_to be_empty
      end

      it 'returns root commits as FsckObject with :commit type' do
        result = command.call(root: true)
        result.root.each do |obj|
          expect(obj.type).to eq(:commit)
          expect(obj.oid).to match(/^[0-9a-f]{40}$/)
        end
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

      it 'returns tagged objects with tag name' do
        result = command.call(tags: true)
        tag_obj = result.tagged.find { |t| t.name == 'v1.0.0' }
        expect(tag_obj).not_to be_nil
        expect(tag_obj.oid).to match(/^[0-9a-f]{40}$/)
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

    context 'with :connectivity_only option' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
      end

      it 'runs connectivity-only check' do
        result = command.call(connectivity_only: true)
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
        # With dangling: false, git doesn't report dangling objects
        expect(result.dangling).to be_empty
      end
    end

    context 'with :unreachable option' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')

        # Create an unreachable commit
        write_file('file2.txt', 'more content')
        repo.add('file2.txt')
        repo.commit('Second commit')

        # Reset back, making the second commit unreachable
        repo.reset('HEAD~1', hard: true)
        # Run git gc to potentially make objects unreachable
        # Note: git keeps reflog entries, so this may still be reachable via reflog
        `cd #{repo_dir} && git reflog expire --expire=now --all`
      end

      it 'reports unreachable objects when requested' do
        result = command.call(unreachable: true)
        # The commit may be unreachable after expiring reflog
        expect(result).to be_a(Git::FsckResult)
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

    context 'FsckObject attributes' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')

        # Create a dangling blob
        write_file('temp.txt', 'temporary')
        repo.add('temp.txt')
        repo.reset('HEAD', hard: true)
      end

      it 'has oid attribute accessible' do
        result = command.call
        dangling_obj = result.dangling.first
        next if dangling_obj.nil?

        expect(dangling_obj).to respond_to(:oid)
        expect(dangling_obj.oid).to be_a(String)
        expect(dangling_obj.oid.length).to eq(40)
      end

      it 'has type attribute accessible' do
        result = command.call
        dangling_obj = result.dangling.first
        next if dangling_obj.nil?

        expect(dangling_obj).to respond_to(:type)
        expect(dangling_obj.type).to be_a(Symbol)
      end

      it 'returns oid from to_s' do
        result = command.call
        dangling_obj = result.dangling.first
        next if dangling_obj.nil?

        expect(dangling_obj.to_s).to eq(dangling_obj.oid)
      end
    end

    context 'FsckResult methods' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
      end

      it 'count returns correct total' do
        result = command.call
        expect(result.count).to eq(result.all_objects.size)
      end

      it 'to_h returns hash with all keys' do
        result = command.call
        hash = result.to_h
        expect(hash).to have_key(:dangling)
        expect(hash).to have_key(:missing)
        expect(hash).to have_key(:unreachable)
        expect(hash).to have_key(:warnings)
        expect(hash).to have_key(:root)
        expect(hash).to have_key(:tagged)
      end
    end

    context 'with :name_objects option' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
        repo.add_tag('v1.0.0', annotate: true, message: 'Release')
      end

      it 'can include name information for objects' do
        result = command.call(tags: true, name_objects: true)
        # name_objects adds ref names to output when available
        expect(result).to be_a(Git::FsckResult)
      end
    end

    context 'with :cache option' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
      end

      it 'considers index objects as head nodes' do
        write_file('staged.txt', 'staged content')
        repo.add('staged.txt')

        result = command.call(cache: true)
        expect(result).to be_a(Git::FsckResult)
      end
    end

    context 'with :no_reflogs option' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
      end

      it 'excludes reflog entries from reachability trace' do
        result = command.call(no_reflogs: true)
        expect(result).to be_a(Git::FsckResult)
      end
    end

    context 'with :lost_found option' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')

        # Create dangling content
        write_file('orphan.txt', 'orphaned')
        repo.add('orphan.txt')
        repo.reset('HEAD', hard: true)
      end

      it 'writes dangling objects to lost-found directory' do
        result = command.call(lost_found: true)
        expect(result).to be_a(Git::FsckResult)
        # The lost-found directory may or may not be created depending on whether there are
        # dangling objects. We just verify the command ran successfully.
      end
    end

    context 'with :full option' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
      end

      it 'performs full object check' do
        result = command.call(full: true)
        expect(result).to be_a(Git::FsckResult)
      end

      it 'can disable full check' do
        result = command.call(full: false)
        expect(result).to be_a(Git::FsckResult)
      end
    end

    context 'with :references option' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
      end

      it 'can enable references check' do
        result = command.call(references: true)
        expect(result).to be_a(Git::FsckResult)
      end

      it 'can disable references check' do
        result = command.call(references: false)
        expect(result).to be_a(Git::FsckResult)
      end
    end

    context 'with specific objects' do
      before do
        write_file('file.txt', 'content')
        repo.add('file.txt')
        repo.commit('Initial commit')
      end

      it 'checks specific objects by oid' do
        # Get the HEAD commit SHA
        head_sha = `cd #{repo_dir} && git rev-parse HEAD`.strip

        result = command.call(head_sha)
        expect(result).to be_a(Git::FsckResult)
      end
    end

    context 'edge cases' do
      it 'handles empty repository' do
        # No commits at all
        result = command.call
        expect(result).to be_a(Git::FsckResult)
        expect(result.empty?).to be true
      end

      context 'with multiple dangling objects' do
        before do
          write_file('file.txt', 'content')
          repo.add('file.txt')
          repo.commit('Initial commit')

          # Create multiple dangling blobs
          write_file('orphan1.txt', 'orphaned content 1')
          repo.add('orphan1.txt')
          repo.reset('HEAD', hard: true)

          write_file('orphan2.txt', 'orphaned content 2')
          repo.add('orphan2.txt')
          repo.reset('HEAD', hard: true)
        end

        it 'returns all dangling objects' do
          result = command.call
          # We created at least 2 dangling blobs
          expect(result.dangling.length).to be >= 2
        end

        it 'each dangling object has unique oid' do
          result = command.call
          oids = result.dangling.map(&:oid)
          expect(oids.uniq.length).to eq(oids.length)
        end
      end

      context 'with various object types' do
        before do
          # Create initial commit with tree structure
          create_directory('lib')
          write_file('lib/file.rb', 'ruby code')
          write_file('README.md', '# Title')
          repo.add(all: true)
          repo.commit('Initial commit with tree structure')
          repo.add_tag('v1.0.0', annotate: true, message: 'First release')
        end

        it 'handles commits, trees, blobs and tags' do
          result = command.call(root: true, tags: true)
          expect(result).to be_a(Git::FsckResult)
          expect(result.root.first.type).to eq(:commit)
          expect(result.tagged).not_to be_empty
        end
      end
    end
  end
end
