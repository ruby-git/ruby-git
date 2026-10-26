# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::Deprecation do
  describe '#deprecation_horizon' do
    it 'is the ADR-0007 wording "in a future major release"' do
      expect(described_class.deprecation_horizon).to eq('in a future major release')
    end
  end

  describe '#gem_name' do
    it 'answers underscore itself, without the String inflections being loaded' do
      expect(described_class.gem_name.underscore).to eq('git')
      expect(String).not_to be_method_defined(:underscore)
    end
  end

  describe '#warn' do
    subject(:warn) { described_class.warn('Something is deprecated') }

    # The behavior is the global state the spec helper sets to :raise for the
    # whole suite, and there is no seam to inject it through: these examples
    # exist to prove that lib/git.rb loads what each built-in behavior needs.
    # Each context sets its own behavior and the hook restores the original
    # even when the example fails.
    around do |example|
      original = described_class.behavior
      described_class.behavior = behavior
      example.run
    ensure
      described_class.behavior = original
    end

    context 'when the behavior is :raise' do
      let(:behavior) { :raise }

      it 'raises ActiveSupport::DeprecationException with the message' do
        expect { warn }.to raise_error(ActiveSupport::DeprecationException, /Something is deprecated/)
      end
    end

    context 'when the behavior is :stderr' do
      let(:behavior) { :stderr }

      it 'writes the message to stderr' do
        expect { warn }.to output(/Something is deprecated/).to_stderr
      end
    end

    context 'when the behavior is :log' do
      let(:behavior) { :log }

      it 'logs the message to stderr when there is no Rails logger' do
        expect { warn }.to output(/Something is deprecated/).to_stderr
      end
    end

    context 'when the behavior is :notify' do
      let(:behavior) { :notify }
      let(:payloads) { [] }
      let(:callback) { ->(_name, _start, _finish, _id, payload) { payloads << payload } }

      it 'publishes a deprecation.git notification carrying the message' do
        ActiveSupport::Notifications.subscribed(callback, 'deprecation.git') { warn }
        expect(payloads).to contain_exactly(a_hash_including(message: /Something is deprecated/))
      end
    end

    context 'when the behavior is :report', skip: (
      'activesupport 7.1 added :report' unless ActiveSupport::Deprecation::DEFAULT_BEHAVIORS.key?(:report)
    ) do
      let(:behavior) { :report }
      let(:error_reporter) { instance_double(ActiveSupport::ErrorReporter) }

      before { allow(ActiveSupport).to receive(:error_reporter).and_return(error_reporter) }

      it 'reports an ActiveSupport::DeprecationException carrying the message' do
        expect(error_reporter).to receive(:report).with(
          an_instance_of(ActiveSupport::DeprecationException).and(having_attributes(message: /Something is deprecated/))
        )
        warn
      end
    end

    context 'when the behavior is :silence' do
      let(:behavior) { :silence }

      it 'writes nothing to stderr' do
        expect { warn }.not_to output.to_stderr
      end
    end
  end
end
