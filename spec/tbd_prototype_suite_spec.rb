require "open3"
require "json"
require "openstudio"
require "parallel"
require "openstudio-model-articulation"

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
  it "compares results for DOE Prototypes" do
    tbd_ = File.join(__dir__, "files/measures/tbd"                          )
    res_ = File.join(__dir__, "files/measures/openstudio_results"           )
    pro_ = File.join(__dir__, "files/measures/create_DOE_prototype_building")
    osw_ = File.join(__dir__, "files/osws/prototype_suite.osw"              )
    runs = File.join(__dir__, "prototype_suite_runs"                        )

    expect( Dir.exist?(tbd_)).to be true
    expect( Dir.exist?(res_)).to be true
    expect( Dir.exist?(pro_)).to be true
    expect(File.exist?(osw_)).to be true

    FileUtils.mkdir_p(runs)
    nproc    = [1, Parallel.processor_count - 2].max # nb processors to use
    #nproc = 1
    template = nil

    File.open(osw_, "r") do |f|
      template = JSON.parse(f.read, { symbolize_names: true })
    end

    expect(template).to_not be_nil
    expect(template).to_not be_empty

    types  = []
    opts   = []
    combos = []

    # types << "SecondarySchool"
    # types << "PrimarySchool"
    types << "SmallOffice"
    # types << "MediumOffice"
    # types << "LargeOffice"
    # types << "SmallHotel"
    # types << "LargeHotel"
    types << "Warehouse"
    # types << "RetailStandalone"
    # types << "RetailStripmall"
    # types << "QuickServiceRestaurant"
    # types << "FullServiceRestaurant"
    # types << "MidriseApartment"
    # types << "HighriseApartment"
    # types << "Hospital"
    # types << "Outpatient"

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

    types.each do |type|
      opts.each { |opt| combos << [type, opt] }
    end

    Parallel.each(combos, in_threads: nproc) do |combo| # run E+ simulations
      type  = combo[0]
      opt   = combo[1]
      id    = "#{type}_#{opt.gsub(/[|\s\.]/, '-')}"
      dir   = File.join(runs, id)
      next if File.exist?(dir) && File.exist?(File.join(dir, "out.osw"))

      FileUtils.mkdir_p(dir)
      osw = Marshal.load( Marshal.dump(template) )

      osw[:steps][1][:arguments][:building_type] = type
      osw[:steps][2][:arguments][:__SKIP__     ] = true    if opt == "skip"
      osw[:steps][2][:arguments][:option       ] = opt unless opt == "skip"

      # use classic command in 3.7.0 for off by one error in OSW results:
      # https://github.com/NREL/OpenStudio/issues/5140
      classic = ''
      if OpenStudio::openStudioVersion == '3.7.0'
        classic = 'classic'
      end

      file    = File.join(dir, "in.osw")
      File.open(file, "w") { |f| f << JSON.pretty_generate(osw) }
      command = "'#{OpenStudio::getOpenStudioCLI}' #{classic} run -w '#{file}'"
      puts "... running CASE #{type} | #{opt}"
      stdout, stderr, status = Open3.capture3(clean, command)
      if !status.success?
        puts "Error running #{file}:"
        puts stdout
        puts stderr
      end
    end

    puts

    types.each do |type| # fetch & compare E+ simulation results
      results = {}

      opts.each do |opt|
        id   = "#{type}_#{opt.gsub(/[|\s\.]/, '-')}"
        file = File.join(runs, id, "out.osw")

        results[opt] = {}

        File.open(file, "r") do |f|
          results[opt] = JSON.parse(f.read, { symbolize_names: true })
        end
      end

      opts.each do |opt|
        expect(results[opt][:completed_status]).to eq("Success")
        res  = results[opt][:steps][2][:result]
        os   = results[opt][:steps][3][:result]
        gj   = os[:step_values].select{ |v| v[:name] == "total_site_energy" }
        puts " ------       CASE  : #{type}"
        puts "        TBD option  : #{opt}"
        puts "        TBD success = #{res[:step_result]}"
        puts "         OS success = #{os[:step_result]}"
        puts "  Total Site Energy = #{gj[0][:value].to_i}"
      end
    end
  end
end
