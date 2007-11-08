Dir.chdir(File.dirname(__FILE__)) do
  Dir.glob('**/test_*.rb') { |test_case| require test_case }
end
