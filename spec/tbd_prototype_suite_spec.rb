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

    expect( Dir.exist?(tbd_)).to be(true)
    expect( Dir.exist?(res_)).to be(true)
    expect( Dir.exist?(pro_)).to be(true)
    expect(File.exist?(osw_)).to be(true)

    FileUtils.mkdir_p(runs)
    nproc    = [1, Parallel.processor_count - 2].max      # nb processors to use
    template = nil

    File.open(osw_, "r") do |f|
      template = JSON.parse(f.read, { symbolize_names: true })
    end

    expect(template.nil?  ).to be(false)
    expect(template.empty?).to be(false)

    types  = []
    opts   = []
    combos = []

    # types << "SecondarySchool"
    # types << "PrimarySchool"
    # types << "SmallOffice"
    # types << "MediumOffice"
    # types << "LargeOffice"
    # types << "SmallHotel"
    # types << "LargeHotel"
    types << "Warehouse"
    # types << "RetailStandalone"
    # types << "RetailStripmall"
    # types << "QuickServiceRestaurant"
    types << "FullServiceRestaurant"
    types << "MidriseApartment"
    # types << "HighriseApartment"
    # types << "Hospital"
    # types << "Outpatient"

    opts << "skip"
    # opts << "poor (BETBG)"
    # opts << "regular (BETBG)"
    # opts << "efficient (BETBG)"
    # opts << "spandrel (BETBG)"
    # opts << "spandrel HP (BETBG)"
    opts << "code (Quebec)"
    opts << "uncompliant (Quebec)"
    opts << "(non thermal bridging)"

    types.each do |type|
      opts.each { |opt| combos << [type, opt] }
    end

    Parallel.each(combos, in_threads: nproc) do |combo|     # run E+ simulations
      type  = combo[0]
      opt   = combo[1]
      id    = "#{type}_#{opt}"
      dir   = File.join(runs, id)
      next if File.exist?(dir) && File.exist?(File.join(dir, "out.osw"))

      FileUtils.mkdir_p(dir)
      osw   = Marshal.load( Marshal.dump(template) )

      osw[:steps][0][:arguments][:building_type] = type
      osw[:steps][1][:arguments][:__SKIP__     ] = true         if opt == "skip"
      osw[:steps][1][:arguments][:option       ] = opt      unless opt == "skip"

      file    = File.join(dir, "in.osw")
      File.open(file, "w") { |f| f << JSON.pretty_generate(osw) }
      command = "'#{OpenStudio::getOpenStudioCLI}' run -w '#{file}'"
      puts "... running CASE #{type} | #{opt}"
      stdout, stderr, status = Open3.capture3(clean, command)
    end

    puts

    types.each do |type|                 # fetch & compare E+ simulation results
      results = {}

      opts.each do |opt|
        id           = "#{type}_#{opt}"
        file         = File.join(runs, id, "out.osw")
        results[opt] = {}

        File.open(file, "r") do |f|
          results[opt] = JSON.parse(f.read, { symbolize_names: true })
        end
      end

      opts.each do |opt|
        expect(results[opt][:completed_status]).to eq("Success")
        res  = results[opt][:steps][1][:result]
        os   = results[opt][:steps][2][:result]
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
