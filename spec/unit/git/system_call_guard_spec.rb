# frozen_string_literal: true

require 'spec_helper'
require 'git/system_call_guard'

RSpec.describe Git::SystemCallGuard do
  describe '.call' do
    context 'when the block completes without error' do
      it 'returns the value returned by the block' do
        expect(described_class.call('Failed to read') { 42 }).to eq(42)
      end
    end

    context 'when the block raises a SystemCallError' do
      subject(:call) do
        described_class.call('Failed to read pointer') { raise Errno::EACCES, '/repo/.git' }
      end

      it 'raises Git::Error with the message prefix and the system error message' do
        expect { call }.to raise_error(Git::Error, 'Failed to read pointer: Permission denied - /repo/.git')
      end

      it 'sets the SystemCallError as the cause of the Git::Error' do
        expect { call }.to raise_error(Git::Error) do |error|
          expect(error.cause).to be_a(Errno::EACCES)
        end
      end
    end

    context 'when the block raises an error that is not a SystemCallError' do
      it 'lets the error propagate unchanged' do
        expect { described_class.call('Failed') { raise ArgumentError, 'bad' } }
          .to raise_error(ArgumentError, 'bad')
      end
    end

    context 'when a SystemCallError is raised inside an unguarded region' do
      it 'lets the SystemCallError propagate unchanged' do
        expect do
          described_class.call('Failed') { |guard| guard.unguarded { raise Errno::ENOENT, 'caller.txt' } }
        end.to raise_error(Errno::ENOENT, 'No such file or directory - caller.txt')
      end
    end

    context 'when a SystemCallError is raised after an unguarded region completes' do
      it 'raises Git::Error' do
        expect do
          described_class.call('Failed to clean up') do |guard|
            guard.unguarded { :ok }
            raise Errno::ENOENT, 'tmpdir'
          end
        end.to raise_error(Git::Error, 'Failed to clean up: No such file or directory - tmpdir')
      end
    end

    context 'when a SystemCallError is raised while unwinding from an unguarded region that raised' do
      it 'raises Git::Error for the second error' do
        expect do
          described_class.call('Failed to restore directory') do |guard|
            guard.unguarded { raise Errno::ENOENT, 'caller.txt' }
          ensure
            raise Errno::ENOENT, 'original-dir'
          end
        end.to raise_error(Git::Error, 'Failed to restore directory: No such file or directory - original-dir')
      end
    end

    context 'when an unguarded SystemCallError passes through a nested guard' do
      it 'lets the SystemCallError propagate unchanged through both guards' do
        expect do
          described_class.call('Outer') do |outer|
            outer.unguarded do
              described_class.call('Inner') { |inner| inner.unguarded { raise Errno::ENOENT, 'caller.txt' } }
            end
          end
        end.to raise_error(Errno::ENOENT, 'No such file or directory - caller.txt')
      end
    end

    context 'when the unguarded region completes without error' do
      it 'returns the value returned by the unguarded block' do
        result = described_class.call('Failed') { |guard| guard.unguarded { :inner } }
        expect(result).to eq(:inner)
      end
    end
  end
end
