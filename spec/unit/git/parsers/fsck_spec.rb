# frozen_string_literal: true

require 'spec_helper'
require 'git/parsers/fsck'

RSpec.describe Git::Parsers::Fsck do
  # Use exactly 40-character SHAs as git requires
  let(:sha1) { 'abc123def456789012345678901234567890abcd' } # 40 chars
  let(:sha2) { 'def456789012345678901234567890abcdef0123' } # 40 chars
  let(:sha3) { '111222333444555666777888999000aaabbbcccd' } # 40 chars
  let(:sha4) { 'fedcba0987654321fedcba0987654321fedcba09' } # 40 chars
  let(:sha5) { 'aabbccdd00112233445566778899aabbccddeeff' } # 40 chars
  let(:sha6) { '00112233445566778899aabbccddeeff00112233' } # 40 chars

  describe '.parse' do
    it 'parses dangling objects' do
      stdout = <<~OUTPUT
        dangling commit #{sha1}
        dangling blob #{sha2}
      OUTPUT

      result = described_class.parse(stdout)

      expect(result).to be_a(Git::FsckResult)
      expect(result.dangling.size).to eq(2)
      expect(result.dangling[0].type).to eq(:commit)
      expect(result.dangling[0].oid).to eq(sha1)
      expect(result.dangling[1].type).to eq(:blob)
      expect(result.dangling[1].oid).to eq(sha2)
    end

    it 'parses missing objects' do
      stdout = "missing tree #{sha1}\n"

      result = described_class.parse(stdout)

      expect(result.missing.size).to eq(1)
      expect(result.missing[0].type).to eq(:tree)
      expect(result.missing[0].oid).to eq(sha1)
    end

    it 'parses unreachable objects' do
      stdout = "unreachable commit #{sha1}\n"

      result = described_class.parse(stdout)

      expect(result.unreachable.size).to eq(1)
      expect(result.unreachable[0].type).to eq(:commit)
    end

    it 'parses unreachable objects with names' do
      stdout = "unreachable commit #{sha1} (HEAD~2^2:src/)\n"

      result = described_class.parse(stdout)

      expect(result.unreachable.size).to eq(1)
      expect(result.unreachable[0].name).to eq('HEAD~2^2:src/')
    end

    it 'parses warning lines' do
      stdout = "warning in commit #{sha1}: badTimezone: invalid author/committer line\n"

      result = described_class.parse(stdout)

      expect(result.warnings.size).to eq(1)
      expect(result.warnings[0].type).to eq(:commit)
      expect(result.warnings[0].oid).to eq(sha1)
      expect(result.warnings[0].message).to eq('badTimezone: invalid author/committer line')
    end

    it 'parses root lines' do
      stdout = "root #{sha1}\n"

      result = described_class.parse(stdout)

      expect(result.root.size).to eq(1)
      expect(result.root[0].type).to eq(:commit)
      expect(result.root[0].oid).to eq(sha1)
    end

    it 'parses tagged lines' do
      stdout = "tagged commit #{sha1} (v1.0.0) in #{sha2}\n"

      result = described_class.parse(stdout)

      expect(result.tagged.size).to eq(1)
      expect(result.tagged[0].type).to eq(:commit)
      expect(result.tagged[0].oid).to eq(sha1)
      expect(result.tagged[0].name).to eq('v1.0.0')
    end

    it 'parses mixed output' do
      stdout = <<~OUTPUT
        dangling commit #{sha1}
        missing blob #{sha2}
        warning in tree #{sha3}: gitmodulesName: contains a '/'
        root #{sha4}
        tagged blob #{sha5} (release-notes) in #{sha6}
      OUTPUT

      result = described_class.parse(stdout)

      expect(result.dangling.size).to eq(1)
      expect(result.missing.size).to eq(1)
      expect(result.warnings.size).to eq(1)
      expect(result.root.size).to eq(1)
      expect(result.tagged.size).to eq(1)
    end

    it 'returns empty result for empty output' do
      result = described_class.parse('')

      expect(result.dangling).to be_empty
      expect(result.missing).to be_empty
      expect(result.unreachable).to be_empty
      expect(result.warnings).to be_empty
      expect(result.root).to be_empty
      expect(result.tagged).to be_empty
    end

    it 'ignores unrecognized lines' do
      stdout = <<~OUTPUT
        Checking connectivity... done.
        dangling commit #{sha1}
        Some other output
      OUTPUT

      result = described_class.parse(stdout)

      expect(result.dangling.size).to eq(1)
    end
  end

  describe '.parse_line' do
    it 'returns truthy for recognized lines' do
      result = { dangling: [], missing: [], unreachable: [], warnings: [], root: [], tagged: [] }
      described_class.parse_line("dangling commit #{sha1}", result)

      expect(result[:dangling]).not_to be_empty
    end

    it 'returns truthy for warning lines' do
      result = { dangling: [], missing: [], unreachable: [], warnings: [], root: [], tagged: [] }
      ret = described_class.parse_line("warning in commit #{sha1}: message", result)

      expect(ret).to be_truthy
    end
  end

  describe '.parse_object_line' do
    it 'parses dangling object' do
      result = { dangling: [] }
      described_class.parse_object_line("dangling commit #{sha1}", result)

      expect(result[:dangling].size).to eq(1)
      expect(result[:dangling][0]).to be_a(Git::FsckObject)
    end

    it 'parses missing object' do
      result = { missing: [] }
      described_class.parse_object_line("missing blob #{sha1}", result)

      expect(result[:missing].size).to eq(1)
    end

    it 'parses unreachable object' do
      result = { unreachable: [] }
      described_class.parse_object_line("unreachable tree #{sha1}", result)

      expect(result[:unreachable].size).to eq(1)
    end

    it 'parses object with name' do
      result = { dangling: [] }
      described_class.parse_object_line("dangling commit #{sha1} (refs/heads/old)", result)

      expect(result[:dangling][0].name).to eq('refs/heads/old')
    end

    it 'returns nil for non-matching lines' do
      result = { dangling: [] }
      ret = described_class.parse_object_line('some other line', result)

      expect(ret).to be_nil
      expect(result[:dangling]).to be_empty
    end
  end

  describe '.parse_warning_line' do
    it 'parses warning line' do
      result = { warnings: [] }
      described_class.parse_warning_line("warning in commit #{sha1}: bad date", result)

      expect(result[:warnings].size).to eq(1)
      expect(result[:warnings][0].type).to eq(:commit)
      expect(result[:warnings][0].message).to eq('bad date')
    end

    it 'returns nil for non-matching lines' do
      result = { warnings: [] }
      ret = described_class.parse_warning_line('some other line', result)

      expect(ret).to be_nil
    end
  end

  describe '.parse_root_line' do
    it 'parses root line' do
      result = { root: [] }
      described_class.parse_root_line("root #{sha1}", result)

      expect(result[:root].size).to eq(1)
      expect(result[:root][0].type).to eq(:commit)
      expect(result[:root][0].oid).to eq(sha1)
    end

    it 'returns nil for non-matching lines' do
      result = { root: [] }
      ret = described_class.parse_root_line('some other line', result)

      expect(ret).to be_nil
    end
  end

  describe '.parse_tagged_line' do
    it 'parses tagged line' do
      result = { tagged: [] }
      described_class.parse_tagged_line(
        "tagged commit #{sha1} (v1.0.0) in #{sha2}",
        result
      )

      expect(result[:tagged].size).to eq(1)
      expect(result[:tagged][0].type).to eq(:commit)
      expect(result[:tagged][0].oid).to eq(sha1)
      expect(result[:tagged][0].name).to eq('v1.0.0')
    end

    it 'returns nil for non-matching lines' do
      result = { tagged: [] }
      ret = described_class.parse_tagged_line('some other line', result)

      expect(ret).to be_nil
    end
  end
end
