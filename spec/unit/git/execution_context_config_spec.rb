# frozen_string_literal: true

require 'spec_helper'

# These specs verify that ExecutionContext resolves config through Git::Config.instance
# (not Git::Base.config) — Step C1b of the architectural redesign.
#
RSpec.describe Git::ExecutionContext do
  describe '#binary_path' do
    context 'when using global config (default, no explicit binary_path)' do
      let(:context) { Git::ExecutionContext::Global.new }

      it 'reads from Git::Config.instance (not Git::Base.config)' do
        allow(Git::Config.instance).to receive(:binary_path).and_return('/from/config/instance/git')
        expect(Git::Base).not_to receive(:config)
        expect(context.binary_path).to eq('/from/config/instance/git')
      end
    end
  end

  describe '#git_ssh' do
    context 'when using global config (default, no explicit git_ssh)' do
      let(:context) { Git::ExecutionContext::Global.new }

      it 'reads from Git::Config.instance (not Git::Base.config)' do
        allow(Git::Config.instance).to receive(:git_ssh).and_return('/from/config/instance/ssh')
        expect(Git::Base).not_to receive(:config)
        expect(context.git_ssh).to eq('/from/config/instance/ssh')
      end
    end
  end
end
