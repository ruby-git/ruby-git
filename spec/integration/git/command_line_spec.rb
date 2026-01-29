# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'CommandLine#run raise_on_failure integration' do
  include_context 'in an empty repository'

  let(:command_line) do
    Git::CommandLine.new({}, 'git', [], Logger.new(nil))
  end

  describe 'raise_on_failure: false' do
    it 'returns CommandLineResult without raising on non-zero exit' do
      result = command_line.run('rev-parse', 'nonexistent-ref', chdir: repo_dir, raise_on_failure: false)

      expect(result).to be_a(Git::CommandLineResult)
      expect(result.status.success?).to be false
      expect(result.stderr).to include('unknown revision')
    end
  end

  describe 'raise_on_failure: true (default)' do
    it 'raises FailedError on non-zero exit' do
      expect do
        command_line.run('rev-parse', 'nonexistent-ref', chdir: repo_dir)
      end.to raise_error(Git::FailedError)
    end
  end
end
