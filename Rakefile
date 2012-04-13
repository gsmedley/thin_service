#!/usr/bin/env rake
require "bundler/gem_tasks"
require "rake/clean"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new

task :default => :spec
task :test => :spec
task :package => [:compile]
task :build => [:compile]

CLOBBER.include('pkg')

load 'tasks/native_lib.rake'
load 'tasks/native_service.rake'

