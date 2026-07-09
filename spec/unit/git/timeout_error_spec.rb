# frozen_string_literal: true

require 'spec_helper'
require 'git/errors'

RSpec.describe Git::TimeoutError do
  # A minimal stand-in for ProcessExecuter::Result whose only contract here is
  # responding to #to_s. Using a small anonymous class keeps the test isolated
  # from ProcessExecuter and Process::Status semantics.
  let(:status) do
    Class.new do
      def to_s = 'pid 65628 SIGKILL (signal 9)'
    end.new
  end

  let(:result) do
    Git::CommandLine::Result.new(%w[git status], status, 'stdout', 'Waiting...')
  end

  let(:timeout_duration) { 10 }
  let(:described_instance) { described_class.new(result, timeout_duration) }

  describe '#initialize' do
    subject(:instance) { described_instance }

    it 'stores the result and timeout_duration' do
      expect(instance).to have_attributes(result: result, timeout_duration: timeout_duration)
    end
  end

  describe '#to_s' do
    subject(:message) { described_instance.to_s }

    it 'appends the timeout duration to the inherited error format' do
      expect(message).to eq(
        '["git", "status"], status: pid 65628 SIGKILL (signal 9), stderr: "Waiting...", timed out after 10s'
      )
    end
  end
end
