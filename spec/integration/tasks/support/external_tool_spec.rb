# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../../tasks/support/external_tool'

RSpec.describe ExternalTool do
  describe '.run' do
    subject(:run) { described_class.run([tool, *args], task: 'probe:tool', install_hint: install_hint) }

    let(:args) { [] }
    let(:install_hint) { "Install it from the probe docs\n" }

    context 'when the tool runs and exits successfully' do
      let(:tool) { RbConfig.ruby }
      let(:args) { ['-e', 'exit 0'] }

      it 'returns true' do
        expect(run).to be true
      end
    end

    context 'when the tool runs and fails' do
      let(:tool) { RbConfig.ruby }
      let(:args) { ['-e', 'exit 1'] }

      it 'aborts naming the task' do
        expect { run }.to raise_error(SystemExit).and output("rake probe:tool failed\n").to_stderr
      end
    end

    context 'when the tool cannot start' do
      let(:tool) { 'external-tool-spec-no-such-tool' }

      it 'aborts with the error, the task, and the install hint' do
        expect { run }.to raise_error(SystemExit).and output(<<~MESSAGE).to_stderr
          Could not start #{tool} (No such file or directory - #{tool}), and `rake probe:tool` requires it.
          Either #{tool} is not installed or not on PATH, or the #{tool} found on PATH cannot run.
          Install it from the probe docs
        MESSAGE
      end
    end
  end
end
