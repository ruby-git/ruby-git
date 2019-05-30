# frozen_string_literal: true

Dir.chdir(File.dirname(__FILE__)) do
  Dir.glob('**/test_*.rb') do |test_case|
    require "#{__dir__}/#{test_case}"
  end
end
