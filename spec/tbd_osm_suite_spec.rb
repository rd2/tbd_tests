require "open3"
require "json"
require "openstudio"
require "parallel"
require "fileutils"

def clean
  new_env                         = {}
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
  it "compares results for OpenStudio models" do
    tbd_ = File.join(__dir__, "files/measures/tbd"               )
    res_ = File.join(__dir__, "files/measures/openstudio_results")
    osw_ = File.join(__dir__, "files/osws/osm_suite.osw"         )
    runs = File.join(__dir__, "osm_suite_runs"                   )

    expect( Dir.exist?(tbd_)).to be true
    expect( Dir.exist?(res_)).to be true
    expect(File.exist?(osw_)).to be true

    FileUtils.mkdir_p(runs)
    nproc    = [1, Parallel.processor_count - 2].max # nb processors to use
    template = nil

    File.open(osw_, "r") do |f|
      template = JSON.parse(f.read, { symbolize_names: true })
    end

    expect(template).to_not be_nil
    expect(template).to_not be_empty

    osms   = []
    epws   = {}
    opts   = []
    combos = []

    osms << "seb.osm"
    # osms << "secondaryschool.osm"
    # osms << "smalloffice.osm"
    osms << "warehouse.osm"

    epws["seb.osm"            ] = "srrl_2013_amy.epw"
    # epws["secondaryschool.osm"] = "CAN_PQ_Quebec.717140_CWEC.epw"
    # epws["smalloffice.osm"    ] = "CAN_PQ_Quebec.717140_CWEC.epw"
    epws["warehouse.osm"      ] = "CAN_PQ_Quebec.717140_CWEC.epw"

    opts << "skip"
    # opts << "poor (BETBG)"
    # opts << "regular (BETBG)"
    # opts << "efficient (BETBG)"
    # opts << "spandrel (BETBG)"
    # opts << "spandrel HP (BETBG)"
    # opts << "code (Quebec)"
    # opts << "uncompliant (Quebec)"
    # opts << "90.1.22|steel.m|default"
    opts << "90.1.22|steel.m|unmitigated"
    # opts << "90.1.22|mass.ex|default"
    # opts << "90.1.22|mass.ex|unmitigated"
    # opts << "90.1.22|mass.in|default"
    # opts << "90.1.22|mass.in|unmitigated"
    # opts << "90.1.22|wood.fr|default"
    opts << "90.1.22|wood.fr|unmitigated"
    opts << "(non thermal bridging)"

    osms.each do |osm|
      opts.each { |opt| combos << [osm, opt] }
    end

    Parallel.each(combos, in_threads: nproc) do |combo| # run E+ simulations
      osm   = combo[0]
      opt   = combo[1]
      id    = "#{osm}_#{opt}".gsub(/[|\s\.]/, '-')
      dir   = File.join(runs, id)
      next if File.exist?(dir) && File.exist?(File.join(dir, "out.osw"))

      FileUtils.mkdir_p(dir)
      osw   = Marshal.load( Marshal.dump(template) )

      osw[:seed_file   ]                    = osm
      osw[:weather_file]                    = epws[osm]

      osw[:steps][1][:arguments][:__SKIP__] = true    if opt == "skip"
      osw[:steps][1][:arguments][:option  ] = opt unless opt == "skip"

      file    = File.join(dir, "in.osw")
      File.open(file, "w") { |f| f << JSON.pretty_generate(osw) }

      # use classic command in 3.7.0 for off by one error in OSW results:
      # https://github.com/NREL/OpenStudio/issues/5140
      classic = ''
      if OpenStudio::openStudioVersion == '3.7.0'
        classic = 'classic'
      end

      command = "'#{OpenStudio::getOpenStudioCLI}' #{classic} run -w '#{file}'"
      puts "... running CASE #{osm} | #{opt}"
      stdout, stderr, status = Open3.capture3(clean, command)
    end

    puts

    osms.each do |osm| # fetch & compare E+ simulation results
      results = {}

      opts.each do |opt|
        id           = "#{osm}_#{opt}".gsub(/[|\s\.]/, '-')
        file         = File.join(runs, id, "out.osw")
        results[opt] = {}

        File.open(file, "r") do |f|
          results[opt] = JSON.parse(f.read, { symbolize_names: true })
        end
      end

      opts.each do |opt|
        puts opt
        expect(results[opt][:completed_status]).to eq("Success")
        res  = results[opt][:steps][1][:result]
        os   = results[opt][:steps][2][:result]
        gj   = os[:step_values].select{ |v| v[:name] == "total_site_energy" }
        puts " ------       CASE  : #{osm}"
        puts "        TBD option  : #{opt}"
        puts "        TBD success = #{res[:step_result]}"
        puts "         OS success = #{os[:step_result]}"
        puts "  Total Site Energy = #{gj[0][:value].to_i}"
      end
    end
  end
end
