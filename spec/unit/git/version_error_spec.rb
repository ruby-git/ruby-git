# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::VersionError do
  describe 'class hierarchy' do
    it 'inherits from Git::Error' do
      expect(described_class).to be < Git::Error
    end
  end

  describe '#subject' do
    it 'returns the subject passed to the constructor' do
      error = described_class.new(
        subject: 'The git gem',
        constraint: Git::VersionConstraint.new(min: Git::Version.parse('2.28.0')),
        actual_version: Git::Version.parse('2.27.0')
      )
      expect(error.subject).to eq('The git gem')
    end
  end

  describe '#constraint' do
    it 'returns the constraint passed to the constructor' do
      constraint = Git::VersionConstraint.new(min: Git::Version.parse('2.28.0'))
      error = described_class.new(
        subject: 'The git gem',
        constraint: constraint,
        actual_version: Git::Version.parse('2.27.0')
      )
      expect(error.constraint).to eq(constraint)
    end
  end

  describe '#actual_version' do
    it 'returns the actual_version passed to the constructor' do
      actual = Git::Version.parse('2.27.0')
      error = described_class.new(
        subject: 'The git gem',
        constraint: Git::VersionConstraint.new(min: Git::Version.parse('2.28.0')),
        actual_version: actual
      )
      expect(error.actual_version).to eq(actual)
    end
  end

  describe '#message' do
    context 'with floor violation (string subject)' do
      it 'formats message for floor check failure' do
        error = described_class.new(
          subject: 'The git gem',
          constraint: Git::VersionConstraint.new(min: Git::Version.parse('2.28.0')),
          actual_version: Git::Version.parse('2.27.0')
        )
        expect(error.message).to eq('The git gem requires git >= 2.28.0 (found 2.27.0)')
      end
    end

    context 'with class too-old violation (min bound only)' do
      let(:test_command_class) do
        stub_const('Git::Commands::TestCommand', Class.new)
      end

      it 'formats message for class-level minimum version failure' do
        error = described_class.new(
          subject: test_command_class,
          constraint: Git::VersionConstraint.new(min: Git::Version.parse('2.30.0')),
          actual_version: Git::Version.parse('2.28.0')
        )
        expect(error.message).to eq('Git::Commands::TestCommand requires git >= 2.30.0 (found 2.28.0)')
      end
    end

    context 'with class too-new violation (upper bound only)' do
      let(:test_command_class) do
        stub_const('Git::Commands::TestCommand', Class.new)
      end

      it 'formats message for class-level upper bound failure' do
        error = described_class.new(
          subject: test_command_class,
          constraint: Git::VersionConstraint.new(before: Git::Version.parse('2.50.0')),
          actual_version: Git::Version.parse('2.51.0')
        )
        expect(error.message).to eq('Git::Commands::TestCommand requires git < 2.50.0 (found 2.51.0)')
      end
    end

    context 'with class range violation (both bounds)' do
      let(:test_command_class) do
        stub_const('Git::Commands::TestCommand', Class.new)
      end

      it 'formats message for too-old when below lower bound' do
        error = described_class.new(
          subject: test_command_class,
          constraint: Git::VersionConstraint.new(
            min: Git::Version.parse('2.30.0'),
            before: Git::Version.parse('2.50.0')
          ),
          actual_version: Git::Version.parse('2.28.0')
        )
        expect(error.message).to eq('Git::Commands::TestCommand requires git >= 2.30.0 (found 2.28.0)')
      end

      it 'formats message for too-new when at or above upper bound' do
        error = described_class.new(
          subject: test_command_class,
          constraint: Git::VersionConstraint.new(
            min: Git::Version.parse('2.30.0'),
            before: Git::Version.parse('2.50.0')
          ),
          actual_version: Git::Version.parse('2.50.0')
        )
        expect(error.message).to eq('Git::Commands::TestCommand requires git < 2.50.0 (found 2.50.0)')
      end
    end
  end
end
