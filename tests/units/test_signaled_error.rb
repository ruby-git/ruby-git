# frozen_string_literal: true

require 'test_helper'

class TestSignaledError < Test::Unit::TestCase
  def test_initializer
    status = Struct.new(:to_s).new('pid 65628 SIGKILL (signal 9)') # `kill -9 $$`
    result = Git::CommandLineResult.new(%w[git status], status, '', 'uncaught signal')

    error = Git::SignaledError.new(result)

    assert(error.is_a?(Git::Error))
  end

  def test_to_s
    status = Struct.new(:to_s).new('pid 65628 SIGKILL (signal 9)') # `kill -9 $$`
    result = Git::CommandLineResult.new(%w[git status], status, '', 'uncaught signal')

    error = Git::SignaledError.new(result)

    expected_message = '["git", "status"], status: pid 65628 SIGKILL (signal 9), stderr: "uncaught signal"'
    assert_equal(expected_message, error.to_s)
  end
end
