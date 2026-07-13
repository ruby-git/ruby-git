# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::Base do
  describe '.new' do
    subject { described_class.new }

    it 'raises NoMethodError directing callers to Git.open, Git.clone, or Git.init' do
      expect { subject }.to raise_error(
        NoMethodError,
        'Git::Base.new is not supported. Use Git.open, Git.clone, or Git.init instead.'
      )
    end
  end

  describe '.method_added' do
    let(:test_method_name) { :git_base_spec_method_added_test }

    after do
      described_class.remove_method(test_method_name) if described_class.method_defined?(test_method_name)
    end

    context 'when a method is defined in Git::Base' do
      it 'emits a deprecation warning naming the method and pointing to Git::Repository' do
        expect(Git::Deprecation).to receive(:warn).with(
          'Monkeypatching Git::Base is deprecated and will be removed in v6.0.0. ' \
          "Define #{test_method_name} in Git::Repository instead."
        )
        described_class.define_method(test_method_name) { nil }
      end

      it 'makes the added method available on Git::Repository instances' do
        allow(Git::Deprecation).to receive(:warn)
        described_class.define_method(test_method_name) { nil }
        expect(Git::Repository.method_defined?(test_method_name)).to be(true)
      end
    end
  end
end
