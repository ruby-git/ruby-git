# frozen_string_literal: true

require 'spec_helper'
require 'yaml'

# Guards the workflow files under .github/workflows.
#
# GitHub Actions ignores top-level keys it does not recognize, so a typo or a stray
# key never breaks a workflow run. actionlint rejects them, and these files are copied
# into other repositories that run actionlint, so this catches them in the existing
# suite instead of in someone else's CI.
RSpec.describe '.github/workflows' do
  # The top-level keys actionlint accepts for a workflow, as listed in its
  # "unexpected key ... for \"workflow\" section" error message.
  supported_keys = %w[concurrency defaults env jobs name on permissions run-name].freeze

  workflow_files = Dir.glob(File.join(File.expand_path('../..', __dir__), '.github', 'workflows', '*.yml'))

  it 'has at least one workflow file to check' do
    expect(workflow_files).not_to be_empty
  end

  workflow_files.each do |workflow_file|
    it "uses only supported top-level keys in #{File.basename(workflow_file)}" do
      # YAML 1.1 treats bare `on`, `yes`, and `true` (in any case) as the same boolean,
      # so loading the file would collapse all of them into a single `true` key and
      # hide an unsupported spelling. Read the keys from the syntax tree, which keeps
      # each scalar as written.
      mapping = YAML.parse_file(workflow_file).root
      keys = mapping.children.each_slice(2).map { |key, _value| key.value }

      expect(keys - supported_keys).to be_empty
    end
  end
end
