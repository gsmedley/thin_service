require_relative '../tools/freebasic'

# global options shared by all the project in this Rakefile
options = {
  :debug => false,
  :profile => false,
  :errorchecking => :ex,
  :mt => true,
  :pedantic => true
}

options[:debug] = true          if ENV['DEBUG']
options[:profile] = true        if ENV['PROFILE']
options[:errorchecking] = :exx  if ENV['EXX']
options[:pedantic] = false      if ENV['NOPEDANTIC']

project_task :mock_process do
  executable  :mock_process
  build_to    'tests'

  main        'tests/fixtures/mock_process.bas'

  option      options
end 

task "all_tests:build" => ["lib:build"]

project_task :all_tests do
  executable  :all_tests
  build_to    'tests'

  search_path 'src/mongrel_service'
  lib_path    'builds'

  main        'tests/all_tests.bas'

  # this temporally fix the inverse namespace ctors of FB
  source      Dir.glob("tests/test_*.bas").reverse

  library     'testly'

  source      'src/mongrel_service/console_process.bas'

  option      options
end

desc "Run all the internal tests for the library"
task "all_tests:run" => ["mock_process:build", "all_tests:build"] do
  Dir.chdir('tests') do
    sh %{all_tests}
  end
end

desc "Run all the test for this project"
task :test => "all_tests:run"
