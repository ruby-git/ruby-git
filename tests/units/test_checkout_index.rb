# frozen_string_literal: true

require 'test_helper'

class TestCheckoutIndex < Test::Unit::TestCase
  test 'checkout_index with no args' do
    expected_command_line = ['checkout-index', {}]
    assert_command_line_eq(expected_command_line, &:checkout_index)
  end

  test 'checkout_index with :all option' do
    expected_command_line = ['checkout-index', '--all', {}]
    assert_command_line_eq(expected_command_line) { |git| git.checkout_index(all: true) }
  end

  test 'checkout_index with :force option' do
    expected_command_line = ['checkout-index', '--force', {}]
    assert_command_line_eq(expected_command_line) { |git| git.checkout_index(force: true) }
  end

  test 'checkout_index with :prefix option' do
    expected_command_line = ['checkout-index', '--prefix=output/', {}]
    assert_command_line_eq(expected_command_line) { |git| git.checkout_index(prefix: 'output/') }
  end

  test 'checkout_index with all options combined' do
    expected_command_line = ['checkout-index', '--all', '--force', '--prefix=output/', {}]
    assert_command_line_eq(expected_command_line) do |git|
      git.checkout_index(prefix: 'output/', force: true, all: true)
    end
  end

  test 'checkout_index with :path_limiter as a string' do
    expected_command_line = ['checkout-index', '--', 'file.txt', {}]
    assert_command_line_eq(expected_command_line) { |git| git.checkout_index(path_limiter: 'file.txt') }
  end

  test 'checkout_index with :path_limiter as an array' do
    expected_command_line = ['checkout-index', '--', 'file1.txt', 'file2.txt', {}]
    assert_command_line_eq(expected_command_line) do |git|
      git.checkout_index(path_limiter: ['file1.txt', 'file2.txt'])
    end
  end

  test 'checkout_index with :path_limiter and :force' do
    expected_command_line = ['checkout-index', '--force', '--', 'file.txt', {}]
    assert_command_line_eq(expected_command_line) do |git|
      git.checkout_index(force: true, path_limiter: 'file.txt')
    end
  end
end
