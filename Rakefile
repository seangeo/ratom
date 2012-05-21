#!/usr/bin/env rake
require "bundler/gem_tasks"
Bundler.setup(:default, :test)

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new do |t|
  t.rspec_opts = ['--options', "spec/spec.opts"]
end

task :default => :spec
