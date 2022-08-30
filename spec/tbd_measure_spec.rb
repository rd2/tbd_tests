require "open3"
require "json"
require "openstudio"
require "parallel"
require "fileutils"

def get_clean_env
  new_env = {}

  new_env["BUNDLER_ORIG_MANPATH"] = nil
  new_env["BUNDLER_ORIG_PATH"   ] = nil
  new_env["BUNDLER_VERSION"     ] = nil
  new_env["BUNDLE_BIN_PATH"     ] = nil
  new_env["RUBYLIB"             ] = nil
  new_env["RUBYOPT"             ] = nil
  new_env["GEM_PATH"            ] = nil
  new_env["GEM_HOME"            ] = nil
  new_env["BUNDLE_GEMFILE"      ] = nil
  new_env["BUNDLE_PATH"         ] = nil
  new_env["BUNDLE_WITHOUT"      ] = nil

  return new_env
end

RSpec.describe TBD_Tests do
  nproc = [1, Parallel.processor_count - 2].max # nb processors to use

  tbd = File.join(__dir__, "files/measures/tbd")
  raise "Missing TBD Measure - run 'bundle update'" unless Dir.exist?(tbd)
end
