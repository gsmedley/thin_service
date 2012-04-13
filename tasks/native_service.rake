require_relative '../tools/freebasic'
require_relative '../lib/thin_service/version'

# thin_service (native)
namespace :native do
  exe_options = {
    :debug => false,
    :profile => false,
    :errorchecking => :ex,
    :mt => true,
    :pedantic => true
  }

  exe_options[:debug] = true          if ENV['DEBUG']
  exe_options[:profile] = true        if ENV['PROFILE']
  exe_options[:errorchecking] = :exx  if ENV['EXX']
  exe_options[:pedantic] = false      if ENV['NOPEDANTIC']

  project_task  'thin_service' do
    executable  'thin_service_wrapper'
    build_to    'resource'

    define      'DEBUG_LOG' if ENV['LOG']
    define      "GEM_VERSION=\"#{ThinService::VERSION}\""

    main        'src/thin_service/thin_service.bas'
    source      'src/thin_service/console_process.bas'

    search_path 'src/ServiceFB'

    lib_path    'builds'
    library     'ServiceFB', 'ServiceFB_Utils'
    library     'user32', 'advapi32', 'psapi'

    option      exe_options
  end
end

task :clean => ['native:clobber']
task :native_service => [:native_lib, 'native:build']

desc "Compile native code"
task :compile => [:native_service]
