require_relative '../tools/freebasic'

# ServiceFB namespace (lib)
namespace :lib do
  lib_options = {
    :debug => false,
    :profile => false,
    :errorchecking => :ex,
    :mt => true,
    :pedantic => true
  }

  lib_options[:debug] = true          if ENV['DEBUG']
  lib_options[:profile] = true        if ENV['PROFILE']
  lib_options[:errorchecking] = :exx  if ENV['EXX']
  lib_options[:pedantic] = false      if ENV['NOPEDANTIC']

  project_task 'servicefb' do
    lib       'ServiceFB'
    build_to  'builds'

    define    'SERVICEFB_DEBUG_LOG' if ENV['LOG']
    source    'src/ServiceFB/ServiceFB.bas'

    option    lib_options
  end

  project_task 'servicefb_utils' do
    lib       'ServiceFB_Utils'
    build_to  'builds'

    define    'SERVICEFB_DEBUG_LOG' if ENV['LOG']
    source    'src/ServiceFB/ServiceFB_Utils.bas'

    option    lib_options
  end
end

task :native_lib => ["lib:build"]
task :clean => ["lib:clobber"]
