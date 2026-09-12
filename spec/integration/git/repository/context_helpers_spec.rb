# frozen_string_literal: true

require 'spec_helper'
require 'git/repository'
require 'git/repository/context_helpers'

# Integration tests for Git::Repository::ContextHelpers.
#
# #with_temp_index and #with_temp_working are exercised end-to-end because the
# facade owns the behavior under test: it builds a second repository bound to a
# temporary index or working tree, yields it, and leaves the receiver bound to
# the original. Only real git can show that the yielded repository reads and
# writes the temporary location while the receiver does not.
#
# The temporary path shape and the removal of the temporary directory need no
# git and are covered by the unit specs. #chdir, #with_index, #with_working,
# #set_index, and #set_working are pure path/context manipulations with no
# git-command delegation of their own; the unit specs cover them, and the temp
# variants above cover the derived repository they share.

RSpec.describe Git::Repository::ContextHelpers, :integration do
  include_context 'in an empty repository'

  let(:described_instance) { Git::Repository.new(execution_context: execution_context) }

  before do
    write_file('tracked.txt', "tracked\n")
    repo.add('tracked.txt')
    repo.commit('Initial commit')
  end

  describe '#with_temp_index' do
    before { write_file('extra.txt', "extra\n") }

    it 'reads and writes the temporary index through the yielded repository' do
      staged = nil
      described_instance.with_temp_index do |temp_repo|
        temp_repo.read_tree('HEAD')
        temp_repo.add('extra.txt')
        staged = temp_repo.ls_files.keys
      end
      expect(staged).to contain_exactly('tracked.txt', 'extra.txt')
    end

    it 'leaves the receiver index untouched inside and after the block' do
      original_index = described_instance.index
      receiver_index = nil
      receiver_staged = nil
      described_instance.with_temp_index do |temp_repo|
        temp_repo.add('extra.txt')
        receiver_index = described_instance.index
        receiver_staged = described_instance.ls_files.keys
      end
      expect(receiver_index).to eq(original_index)
      expect(receiver_staged).to contain_exactly('tracked.txt')
      expect(described_instance.index).to eq(original_index)
      expect(described_instance.ls_files.keys).to contain_exactly('tracked.txt')
    end

    it 'leaves an escaped repository bound to the removed index' do
      escaped = described_instance.with_temp_index do |temp_repo|
        temp_repo.read_tree('HEAD')
        temp_repo
      end
      expect(escaped.ls_files).to be_empty
      expect { escaped.add('extra.txt') }.to raise_error(Git::Error)
      expect(escaped.object('HEAD:tracked.txt').contents).to eq('tracked')
    end
  end

  describe '#with_temp_working' do
    it 'changes the process directory to the temporary working directory during the block' do
      pwd_in_block = nil
      yielded_dir = nil
      described_instance.with_temp_working do |temp_repo|
        pwd_in_block = File.realpath(Dir.pwd)
        yielded_dir = File.realpath(temp_repo.dir.to_s)
      end
      expect(pwd_in_block).to eq(yielded_dir)
    end

    it 'changes the process directory back after the block returns' do
      original_pwd = File.realpath(Dir.pwd)
      described_instance.with_temp_working { |_repo| nil }
      expect(File.realpath(Dir.pwd)).to eq(original_pwd)
    end

    it 'changes the process directory back even when the block raises' do
      original_pwd = File.realpath(Dir.pwd)
      expect { described_instance.with_temp_working { |_repo| raise 'block error' } }.to raise_error('block error')
      expect(File.realpath(Dir.pwd)).to eq(original_pwd)
    end

    it 'reads and writes the temporary working tree through the yielded repository' do
      checked_out = nil
      untracked = nil
      described_instance.with_temp_working do |temp_repo|
        temp_repo.checkout_index(all: true)
        checked_out = File.read(File.join(temp_repo.dir, 'tracked.txt'))
        File.write('scratch.txt', "scratch\n")
        untracked = temp_repo.untracked_files
      end
      expect(checked_out).to eq("tracked\n")
      expect(untracked).to contain_exactly('scratch.txt')
    end

    it 'keeps files written in the temporary directory out of the receiver working tree' do
      original_dir = described_instance.dir
      receiver_dir = nil
      receiver_untracked = nil
      described_instance.with_temp_working do |_repo|
        File.write('scratch.txt', "scratch\n")
        receiver_dir = described_instance.dir
        receiver_untracked = described_instance.untracked_files
      end
      expect(receiver_dir).to eq(original_dir)
      expect(receiver_untracked).to be_empty
      expect(described_instance.dir).to eq(original_dir)
      expect(file_exist?('scratch.txt')).to be(false)
    end

    it 'shares the receiver index with the yielded repository' do
      described_instance.with_temp_working do |temp_repo|
        File.write('scratch.txt', "scratch\n")
        temp_repo.add('scratch.txt')
      end
      expect(described_instance.ls_files.keys).to contain_exactly('tracked.txt', 'scratch.txt')
    end

    it 'leaves an escaped repository bound to the removed working directory' do
      escaped = described_instance.with_temp_working { |temp_repo| temp_repo }
      expect { escaped.untracked_files }.to raise_error(Git::Error)
      expect(escaped.object('HEAD:tracked.txt').contents).to eq('tracked')
    end
  end
end
