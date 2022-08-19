Dir.chdir(File.dirname(__FILE__)) do
  Dir.glob('**/test_*.rb') do |test_case|
    require "#{File.expand_path(File.dirname(__FILE__))}/#{test_case}"
  end
end

# To run a single test:
# require_relative 'units/test_lib_meets_required_version'
