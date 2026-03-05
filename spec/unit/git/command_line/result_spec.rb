# frozen_string_literal: true

require 'spec_helper'
require 'git/command_line/result'

RSpec.describe Git::CommandLine::Result do
  # Plain double: ProcessExecuter result classes delegate to Process::Status via
  # SimpleDelegator/method_missing, so instance_double cannot verify the delegated
  # interface (signaled?, exitstatus, etc.).
  let(:status_double) { double('ProcessExecuter::Result') }
  let(:git_cmd) { %w[git version] }
  let(:stdout) { "git version 2.39.1\n" }
  let(:stderr) { '' }
  let(:described_instance) { described_class.new(git_cmd, status_double, stdout, stderr) }

  describe '#initialize' do
    subject(:instance) { described_instance }

    it 'stores all constructor arguments' do
      expect(instance).to have_attributes(
        git_cmd: git_cmd,
        status: status_double,
        stdout: stdout,
        stderr: stderr
      )
    end
  end
end
