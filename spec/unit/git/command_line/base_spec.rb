# frozen_string_literal: true

require 'spec_helper'
require 'git/command_line/base'

RSpec.describe Git::CommandLine::Base do
  let(:env) { {} }
  let(:binary_path) { '/usr/bin/git' }
  let(:global_opts) { [] }
  let(:logger) { Logger.new(nil) }
  let(:described_instance) { described_class.new(env, binary_path, global_opts, logger) }

  describe '#initialize' do
    subject(:instance) { described_instance }

    it 'stores all constructor arguments' do
      expect(instance).to have_attributes(
        env: env,
        binary_path: binary_path,
        global_opts: global_opts,
        logger: logger
      )
    end
  end

  describe '#run' do
    subject(:result) { described_instance.run('version') }

    it 'raises NotImplementedError with a descriptive message' do
      expect { result }.to raise_error(NotImplementedError, /is not implemented/)
    end
  end
end
