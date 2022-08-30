require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "fileutils"

RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = "--exclude-pattern \'spec/**/*suite_spec.rb\'"
end

task default: :spec

desc "Pull TBD Measure"
task :measure do
  puts "Pulling TBD Measure"
  pth = $:.select { |l_pth| l_pth.include?("tbd-") }
  raise "Missing TBD gem - run 'bundle update'\n"         unless pth.size == 1
  pth = File.join(pth, "measures/tbd")
  tbd = File.join(__dir__, "spec/files/measures/tbd")
  FileUtils.copy_entry(pth, tbd)                          unless Dir.exist?(tbd)
  raise "TBD Measure from TBD gem?\n"                     unless Dir.exist?(tbd)
end

desc "Pull 'OpenStudio Results' Measure"
task :results do
  puts "Pulling 'OpenStudio Results' Measure"
  gem = "openstudio-common-measures"
  pth = $:.select { |l_pth| l_pth.include?(gem) }
  raise "Missing '#{gem}' - run 'bundle update'\n"        unless pth.size == 1
  pth = File.join(pth, "measures/openstudio_results")
  osm = File.join(__dir__, "spec/files/measures/openstudio_results")
  FileUtils.copy_entry(pth, osm)                          unless Dir.exist?(osm)
  raise "'OpenStudio Results' Measure (#{gem})?\n"        unless Dir.exist?(osm)
end

desc "Pull 'Create DOE Prototype Building' Measure"
task :prototype do
  puts "Pulling 'Create DOE Prototype Building' Measure"
  gem = "openstudio-model-articulation"
  pth = $:.select { |l_pth| l_pth.include?(gem) }
  raise "Missing '#{gem}' - run 'bundle update'\n"        unless pth.size == 1
  pth = File.join(pth, "measures/create_DOE_prototype_building")
  pro = File.join(__dir__, "spec/files/measures/create_DOE_prototype_building")
  FileUtils.copy_entry(pth, pro)                          unless Dir.exist?(pro)
  raise "'Create DOE Prototype Building' (#{gem})?\n"     unless Dir.exist?(pro)
end

namespace "osm_suite" do
  desc "Clean TBD OSM Test Suite"
  task :clean do
    puts "Cleaning TBD OSM Test Suite"
    osm = File.join(__dir__, "spec/osm_suite_runs")
    FileUtils.rmtree(osm)                                     if Dir.exist?(osm)
  end

  desc "Run TBD OSM Test Suite"
  RSpec::Core::RakeTask.new(:run) do |t|
    t.rspec_opts = "--pattern \'spec/tbd_osm_suite_spec.rb\'"
  end
  task run: [:measure, :results]
end

namespace "prototype_suite" do
  desc "Clean TBD Prototype Test Suite"
  task :clean do
    puts "Cleaning Prototype Test Suite"
    pro = File.join(__dir__, "spec/prototype_suite_runs")
    FileUtils.rmtree(pro)                                     if Dir.exist?(pro)
  end

  desc "Run TBD Prototype Test Suite"
  RSpec::Core::RakeTask.new(:run) do |t|
    t.rspec_opts = "--pattern \'spec/tbd_prototype_suite_spec.rb\'"
  end
  task run: [:measure, :results, :prototype]
end

desc "Clean All Test Suites"
task suites_clean: ["osm_suite:clean", "prototype_suite:clean"] do
end

desc "Run All Test Suites"
task suites_run: ["osm_suite:run", "prototype_suite:run"] do
end

task spec: [:measure]         # default spec test depends on pulling TBD measure
