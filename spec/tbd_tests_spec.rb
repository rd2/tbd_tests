require "tbd"

RSpec.describe TBD_Tests do
  TOL  = TBD::TOL
  TOL2 = TBD::TOL2
  DBG  = TBD::DBG
  INF  = TBD::INF
  WRN  = TBD::WRN
  ERR  = TBD::ERR
  FTL  = TBD::FTL

  it "can process thermal bridging and derating : LoScrigno" do
    # The following populates both OpenStudio and Topolys models of "Lo scrigno"
    # (or Jewel Box), by Renzo Piano (Lingotto Factory, Turin); a cantilevered,
    # single space art gallery (space #1), above a slanted plenum (space #2),
    # and resting on four main pillars. For the purposes of the spec, vertical
    # access (elevator and stairs, fully glazed) are modelled as extensions
    # of either space.

    # Apart from populating the OpenStudio model, the bulk of the next few
    # hundred is copy of the processTBD method. It is repeated step-by-step
    # here for detailed testing purposes.
    argh = {}
    os_model = OpenStudio::Model::Model.new
    os_g = OpenStudio::Model::Space.new(os_model) # gallery "g" & elevator "e"
    expect(os_g.setName("scrigno_gallery").to_s).to eq("scrigno_gallery")
    os_p = OpenStudio::Model::Space.new(os_model) # plenum "p" & stairwell "s"
    expect(os_p.setName("scrigno_plenum").to_s).to eq("scrigno_plenum")
    os_s = OpenStudio::Model::ShadingSurfaceGroup.new(os_model)

    os_building = os_model.getBuilding

    # For the purposes of the spec, all opaque envelope assemblies are built up
    # from a single, 3-layered construction.
    construction = OpenStudio::Model::Construction.new(os_model)
    expect(construction.handle.to_s.empty?).to be(false)
    expect(construction.nameString.empty?).to be(false)
    expect(construction.nameString).to eq("Construction 1")
    construction.setName("scrigno_construction")
    expect(construction.nameString).to eq("scrigno_construction")
    expect(construction.layers.size).to eq(0)

    # All subsurfaces are Simple Glazing constructions.
    fenestration = OpenStudio::Model::Construction.new(os_model)
    expect(fenestration.handle.to_s.empty?).to be(false)
    expect(fenestration.nameString.empty?).to be(false)
    expect(fenestration.nameString).to eq("Construction 1")
    fenestration.setName("scrigno_fenestration")
    expect(fenestration.nameString).to eq("scrigno_fenestration")
    expect(fenestration.layers.size).to eq(0)

    glazing = OpenStudio::Model::SimpleGlazing.new(os_model)
    expect(glazing.handle.to_s.empty?).to be(false)
    expect(glazing.nameString.empty?).to be(false)
    expect(glazing.nameString).to eq("Window Material Simple Glazing System 1")
    glazing.setName("scrigno_glazing")
    expect(glazing.nameString).to eq("scrigno_glazing")
    expect(glazing.setUFactor(2.0)).to be(true)
    expect(glazing.setSolarHeatGainCoefficient(0.50)).to be(true)
    expect(glazing.setVisibleTransmittance(0.70)).to be(true)

    layers = OpenStudio::Model::MaterialVector.new
    layers << glazing
    expect(fenestration.setLayers(layers)).to be(true)
    expect(fenestration.layers.size).to eq(1)
    expect(fenestration.layers[0].handle.to_s).to eq(glazing.handle.to_s)
    expect(fenestration.uFactor.empty?).to be(false)
    expect(fenestration.uFactor.get).to be_within(0.1).of(2.0)

    exterior = OpenStudio::Model::MasslessOpaqueMaterial.new(os_model)
    expect(exterior.handle.to_s.empty?).to be(false)
    expect(exterior.nameString.empty?).to be(false)
    expect(exterior.nameString).to eq("Material No Mass 1")
    exterior.setName("scrigno_exterior")
    expect(exterior.nameString).to eq("scrigno_exterior")
    expect(exterior.setRoughness("Rough")).to be(true)
    expect(exterior.setThermalResistance(0.3626)).to be(true)
    expect(exterior.setThermalAbsorptance(0.9)).to be(true)
    expect(exterior.setSolarAbsorptance(0.7)).to be(true)
    expect(exterior.setVisibleAbsorptance(0.7)).to be(true)
    expect(exterior.roughness).to eq("Rough")
    expect(exterior.thermalResistance).to be_within(0.0001).of(0.3626)
    expect(exterior.thermalAbsorptance.empty?).to be(false)
    expect(exterior.thermalAbsorptance.get).to be_within(0.0001).of(0.9)
    expect(exterior.solarAbsorptance.empty?).to be(false)
    expect(exterior.solarAbsorptance.get).to be_within(0.0001).of(0.7)
    expect(exterior.visibleAbsorptance.empty?).to be(false)
    expect(exterior.visibleAbsorptance.get).to be_within(0.0001).of(0.7)

    insulation = OpenStudio::Model::StandardOpaqueMaterial.new(os_model)
    expect(insulation.handle.to_s.empty?).to be(false)
    expect(insulation.nameString.empty?).to be(false)
    expect(insulation.nameString).to eq("Material 1")
    insulation.setName("scrigno_insulation")
    expect(insulation.nameString).to eq("scrigno_insulation")
    expect(insulation.setRoughness("MediumRough")).to be(true)
    expect(insulation.setThickness(0.1184)).to be(true)
    expect(insulation.setConductivity(0.045)).to be(true)
    expect(insulation.setDensity(265)).to be(true)
    expect(insulation.setSpecificHeat(836.8)).to be(true)
    expect(insulation.setThermalAbsorptance(0.9)).to be(true)
    expect(insulation.setSolarAbsorptance(0.7)).to be(true)
    expect(insulation.setVisibleAbsorptance(0.7)).to be(true)
    expect(insulation.roughness.empty?).to be(false)
    expect(insulation.roughness).to eq("MediumRough")
    expect(insulation.thickness).to be_within(0.0001).of(0.1184)
    expect(insulation.conductivity).to be_within(0.0001).of(0.045)
    expect(insulation.density).to be_within(0.0001 ).of(265)
    expect(insulation.specificHeat).to be_within(0.0001).of(836.8)
    expect(insulation.thermalAbsorptance).to be_within(0.0001).of(0.9)
    expect(insulation.solarAbsorptance).to be_within(0.0001).of(0.7)
    expect(insulation.visibleAbsorptance).to be_within(0.0001).of(0.7)

    interior = OpenStudio::Model::StandardOpaqueMaterial.new(os_model)
    expect(interior.handle.to_s.empty?).to be(false)
    expect(interior.nameString.empty?).to be(false)
    expect(interior.nameString.downcase).to eq("material 1")
    interior.setName("scrigno_interior")
    expect(interior.nameString).to eq("scrigno_interior")
    expect(interior.setRoughness("MediumRough")).to be(true)
    expect(interior.setThickness(0.0126)).to be(true)
    expect(interior.setConductivity(0.16)).to be(true)
    expect(interior.setDensity(784.9)).to be(true)
    expect(interior.setSpecificHeat(830)).to be(true)
    expect(interior.setThermalAbsorptance(0.9)).to be(true)
    expect(interior.setSolarAbsorptance(0.9)).to be(true)
    expect(interior.setVisibleAbsorptance(0.9)).to be(true)
    expect(interior.roughness.downcase).to eq("mediumrough")
    expect(interior.thickness).to be_within(0.0001).of(0.0126)
    expect(interior.conductivity).to be_within(0.0001).of( 0.16)
    expect(interior.density).to be_within(0.0001).of(784.9)
    expect(interior.specificHeat).to be_within(0.0001).of(830)
    expect(interior.thermalAbsorptance).to be_within(0.0001).of( 0.9)
    expect(interior.solarAbsorptance).to be_within(0.0001).of( 0.9)
    expect(interior.visibleAbsorptance).to be_within(0.0001).of( 0.9)

    layers = OpenStudio::Model::MaterialVector.new
    layers << exterior
    layers << insulation
    layers << interior
    expect(construction.setLayers(layers)).to be(true)
    expect(construction.layers.size).to eq(3)
    expect(construction.layers[0].handle.to_s).to eq(exterior.handle.to_s)
    expect(construction.layers[1].handle.to_s).to eq(insulation.handle.to_s)
    expect(construction.layers[2].handle.to_s).to eq(interior.handle.to_s)

    defaults = OpenStudio::Model::DefaultSurfaceConstructions.new(os_model)
    expect(defaults.setWallConstruction(construction)).to be(true)
    expect(defaults.setRoofCeilingConstruction(construction)).to be(true)
    expect(defaults.setFloorConstruction(construction)).to be(true)

    subs = OpenStudio::Model::DefaultSubSurfaceConstructions.new(os_model)
    expect(subs.setFixedWindowConstruction(fenestration)).to be(true)
    expect(subs.setOperableWindowConstruction(fenestration)).to be(true)
    expect(subs.setDoorConstruction(fenestration)).to be(true)
    expect(subs.setGlassDoorConstruction(fenestration)).to be(true)
    expect(subs.setOverheadDoorConstruction(fenestration)).to be(true)
    expect(subs.setSkylightConstruction(fenestration)).to be(true)
    expect(subs.setTubularDaylightDomeConstruction(fenestration)).to be(true)
    expect(subs.setTubularDaylightDiffuserConstruction(fenestration)).to be(true)

    set = OpenStudio::Model::DefaultConstructionSet.new(os_model)
    expect(set.setDefaultExteriorSurfaceConstructions(defaults)).to be(true)
    expect(set.setDefaultExteriorSubSurfaceConstructions(subs)).to be(true)

    # if one comments out the following, then one can no longer rely on a
    # building-specific, default construction set. If missing, fall back to
    # to model default construction set @index 0.
    expect(os_building.setDefaultConstructionSet(set)).to be(true)

    # 8" XPS massless variant, specific for elevator floor (not defaulted)
    xps8x25mm = OpenStudio::Model::MasslessOpaqueMaterial.new(os_model)
    expect(xps8x25mm.handle.to_s.empty?).to be(false)
    expect(xps8x25mm.nameString.empty?).to be(false)
    expect(xps8x25mm.nameString).to eq("Material No Mass 1")
    xps8x25mm.setName("xps8x25mm")
    expect(xps8x25mm.nameString).to eq("xps8x25mm")
    expect(xps8x25mm.setRoughness("Rough")).to be(true)
    expect(xps8x25mm.setThermalResistance(8 * 0.88)).to be(true)
    expect(xps8x25mm.setThermalAbsorptance(0.9)).to be(true)
    expect(xps8x25mm.setSolarAbsorptance(0.7)).to be(true)
    expect(xps8x25mm.setVisibleAbsorptance(0.7)).to be(true)
    expect(xps8x25mm.roughness).to eq("Rough")
    expect(xps8x25mm.thermalResistance).to be_within(0.0001).of(7.0400)
    expect(xps8x25mm.thermalAbsorptance.empty?).to be(false)
    expect(xps8x25mm.thermalAbsorptance.get).to be_within(0.0001).of(0.9)
    expect(xps8x25mm.solarAbsorptance.empty?).to be(false)
    expect(xps8x25mm.solarAbsorptance.get).to be_within(0.0001).of(0.7)
    expect(xps8x25mm.visibleAbsorptance.empty?).to be(false)
    expect(xps8x25mm.visibleAbsorptance.get).to be_within(0.0001).of(0.7)

    elevator_floor_c = OpenStudio::Model::Construction.new(os_model)
    expect(elevator_floor_c.handle.to_s.empty?).to be(false)
    expect(elevator_floor_c.nameString.empty?).to be(false)
    expect(elevator_floor_c.nameString).to eq("Construction 1")
    elevator_floor_c.setName("elevator_floor_c")
    expect(elevator_floor_c.nameString).to eq("elevator_floor_c")
    expect(elevator_floor_c.layers.size).to eq(0)

    mats = OpenStudio::Model::MaterialVector.new
    mats << exterior
    mats << xps8x25mm
    mats << interior
    expect(elevator_floor_c.setLayers(mats)).to be(true)
    expect(elevator_floor_c.layers.size).to eq(3)
    expect(elevator_floor_c.layers[0].handle.to_s).to eq(exterior.handle.to_s)
    expect(elevator_floor_c.layers[1].handle.to_s).to eq(xps8x25mm.handle.to_s)
    expect(elevator_floor_c.layers[2].handle.to_s).to eq(interior.handle.to_s)

    # Set building shading surfaces:
    # (4x above gallery roof + 2x North/South balconies)
    os_v = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 12.4, 45.0, 50.0)
    os_v << OpenStudio::Point3d.new( 12.4, 25.0, 50.0)
    os_v << OpenStudio::Point3d.new( 22.7, 25.0, 50.0)
    os_v << OpenStudio::Point3d.new( 22.7, 45.0, 50.0)
    os_r1_shade = OpenStudio::Model::ShadingSurface.new(os_v, os_model)
    os_r1_shade.setName("r1_shade")
    expect(os_r1_shade.setShadingSurfaceGroup(os_s)).to be(true)

    os_v = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 22.7, 45.0, 50.0)
    os_v << OpenStudio::Point3d.new( 22.7, 37.5, 50.0)
    os_v << OpenStudio::Point3d.new( 48.7, 37.5, 50.0)
    os_v << OpenStudio::Point3d.new( 48.7, 45.0, 50.0)
    os_r2_shade = OpenStudio::Model::ShadingSurface.new(os_v, os_model)
    os_r2_shade.setName("r2_shade")
    expect(os_r2_shade.setShadingSurfaceGroup(os_s)).to be(true)

    os_v = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 22.7, 32.5, 50.0)
    os_v << OpenStudio::Point3d.new( 22.7, 25.0, 50.0)
    os_v << OpenStudio::Point3d.new( 48.7, 25.0, 50.0)
    os_v << OpenStudio::Point3d.new( 48.7, 32.5, 50.0)
    os_r3_shade = OpenStudio::Model::ShadingSurface.new(os_v, os_model)
    os_r3_shade.setName("r3_shade")
    expect(os_r3_shade.setShadingSurfaceGroup(os_s)).to be(true)

    os_v = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 48.7, 45.0, 50.0)
    os_v << OpenStudio::Point3d.new( 48.7, 25.0, 50.0)
    os_v << OpenStudio::Point3d.new( 59.0, 25.0, 50.0)
    os_v << OpenStudio::Point3d.new( 59.0, 45.0, 50.0)
    os_r4_shade = OpenStudio::Model::ShadingSurface.new(os_v, os_model)
    os_r4_shade.setName("r4_shade")
    expect(os_r4_shade.setShadingSurfaceGroup(os_s)).to be(true)

    os_v = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 47.4, 40.2, 44.0)
    os_v << OpenStudio::Point3d.new( 47.4, 41.7, 44.0)
    os_v << OpenStudio::Point3d.new( 45.7, 41.7, 44.0)
    os_v << OpenStudio::Point3d.new( 45.7, 40.2, 44.0)
    os_N_balcony = OpenStudio::Model::ShadingSurface.new(os_v, os_model)
    os_N_balcony.setName("N_balcony") # 1.70m as thermal bridge
    expect(os_N_balcony.setShadingSurfaceGroup(os_s)).to be(true)

    os_v = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 28.1, 29.8, 44.0)
    os_v << OpenStudio::Point3d.new( 28.1, 28.3, 44.0)
    os_v << OpenStudio::Point3d.new( 47.4, 28.3, 44.0)
    os_v << OpenStudio::Point3d.new( 47.4, 29.8, 44.0)
    os_S_balcony = OpenStudio::Model::ShadingSurface.new(os_v, os_model)
    os_S_balcony.setName("S_balcony") # 19.3m as thermal bridge
    expect(os_S_balcony.setShadingSurfaceGroup(os_s)).to be(true)

    # 1st space: gallery (g) with elevator (e) surfaces
    os_v = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 17.4, 40.2, 49.5) #  5.5m
    os_v << OpenStudio::Point3d.new( 17.4, 40.2, 44.0) # 10.4m
    os_v << OpenStudio::Point3d.new( 17.4, 29.8, 44.0) #  5.5m
    os_v << OpenStudio::Point3d.new( 17.4, 29.8, 49.5) # 10.4m
    os_g_W_wall = OpenStudio::Model::Surface.new(os_v, os_model)
    os_g_W_wall.setName("g_W_wall")
    expect(os_g_W_wall.setSpace(os_g)).to be(true)                     #  57.2m2

    expect(os_g_W_wall.surfaceType.downcase).to eq("wall")
    expect(os_g_W_wall.isConstructionDefaulted).to be(true)
    c = set.getDefaultConstruction(os_g_W_wall).get.to_LayeredConstruction.get
    expect(c.numLayers).to eq(3)
    expect(c.isOpaque).to be(true)
    expect(c.nameString).to eq("scrigno_construction")

    os_v = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 54.0, 40.2, 49.5) #  5.5m
    os_v << OpenStudio::Point3d.new( 54.0, 40.2, 44.0) # 36.6m
    os_v << OpenStudio::Point3d.new( 17.4, 40.2, 44.0) #  5.5m
    os_v << OpenStudio::Point3d.new( 17.4, 40.2, 49.5) # 36.6m
    os_g_N_wall = OpenStudio::Model::Surface.new(os_v, os_model)
    os_g_N_wall.setName("g_N_wall")
    expect(os_g_N_wall.setSpace(os_g)).to be(true)                     # 201.3m2
    expect(os_g_N_wall.uFactor.empty?).to be(false)
    expect(os_g_N_wall.uFactor.get).to be_within(0.001).of(0.310)

    os_v = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 47.4, 40.2, 46.0) #   2.0m
    os_v << OpenStudio::Point3d.new( 47.4, 40.2, 44.0) #   1.0m
    os_v << OpenStudio::Point3d.new( 46.4, 40.2, 44.0) #   2.0m
    os_v << OpenStudio::Point3d.new( 46.4, 40.2, 46.0) #   1.0m
    os_g_N_door = OpenStudio::Model::SubSurface.new(os_v, os_model)
    os_g_N_door.setName("g_N_door")
    expect(os_g_N_door.setSubSurfaceType("GlassDoor")).to be(true)
    expect(os_g_N_door.setSurface(os_g_N_wall)).to be(true)            #   2.0m2
    expect(os_g_N_door.uFactor.empty?).to be(false)
    expect(os_g_N_door.uFactor.get).to be_within(0.1).of(2.0)

    os_v = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 54.0, 29.8, 49.5) #  5.5m
    os_v << OpenStudio::Point3d.new( 54.0, 29.8, 44.0) # 10.4m
    os_v << OpenStudio::Point3d.new( 54.0, 40.2, 44.0) #  5.5m
    os_v << OpenStudio::Point3d.new( 54.0, 40.2, 49.5) # 10.4m
    os_g_E_wall = OpenStudio::Model::Surface.new(os_v, os_model)
    os_g_E_wall.setName("g_E_wall")
    expect(os_g_E_wall.setSpace(os_g)).to be(true)                      # 57.2m2

    os_v = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 17.4, 29.8, 49.5) #  5.5m
    os_v << OpenStudio::Point3d.new( 17.4, 29.8, 44.0) #  6.6m
    os_v << OpenStudio::Point3d.new( 24.0, 29.8, 44.0) #  2.7m
    os_v << OpenStudio::Point3d.new( 24.0, 29.8, 46.7) #  4.0m
    os_v << OpenStudio::Point3d.new( 28.0, 29.8, 46.7) #  2.7m
    os_v << OpenStudio::Point3d.new( 28.0, 29.8, 44.0) # 26.0m
    os_v << OpenStudio::Point3d.new( 54.0, 29.8, 44.0) #  5.5m
    os_v << OpenStudio::Point3d.new( 54.0, 29.8, 49.5) # 36.6m
    os_g_S_wall = OpenStudio::Model::Surface.new(os_v, os_model)
    os_g_S_wall.setName("g_S_wall")
    expect(os_g_S_wall.setSpace(os_g)).to be(true)                    # 190.48m2
    expect(os_g_S_wall.uFactor.empty?).to be(false)
    expect(os_g_S_wall.uFactor.get).to be_within(0.001).of(0.310)

    os_v = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 46.4, 29.8, 46.0) #  2.0m
    os_v << OpenStudio::Point3d.new( 46.4, 29.8, 44.0) #  1.0m
    os_v << OpenStudio::Point3d.new( 47.4, 29.8, 44.0) #  2.0m
    os_v << OpenStudio::Point3d.new( 47.4, 29.8, 46.0) #  1.0m
    os_g_S_door = OpenStudio::Model::SubSurface.new(os_v, os_model)
    os_g_S_door.setName("g_S_door")
    expect(os_g_S_door.setSubSurfaceType("GlassDoor")).to be(true)
    expect(os_g_S_door.setSurface(os_g_S_wall)).to be(true)            #   2.0m2
    expect(os_g_S_door.uFactor.empty?).to be(false)
    expect(os_g_S_door.uFactor.get).to be_within(0.1).of(2.0)

    os_v = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 17.4, 40.2, 49.5) # 10.4m
    os_v << OpenStudio::Point3d.new( 17.4, 29.8, 49.5) # 36.6m
    os_v << OpenStudio::Point3d.new( 54.0, 29.8, 49.5) # 10.4m
    os_v << OpenStudio::Point3d.new( 54.0, 40.2, 49.5) # 36.6m
    os_g_top = OpenStudio::Model::Surface.new(os_v, os_model)
    os_g_top.setName("g_top")
    expect(os_g_top.setSpace(os_g)).to be(true)                       # 380.64m2
    expect(os_g_S_wall.uFactor.empty?).to be(false)
    expect(os_g_S_wall.uFactor.get).to be_within(0.001).of(0.310)

    expect(os_g_top.surfaceType.downcase).to eq("roofceiling")
    expect(os_g_top.isConstructionDefaulted).to be(true)
    c = set.getDefaultConstruction(os_g_top).get.to_LayeredConstruction.get
    expect(c.numLayers).to eq(3)
    expect(c.isOpaque).to be(true)
    expect(c.nameString).to eq("scrigno_construction")

    os_v = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 17.4, 40.2, 49.5) # 10.4m
    os_v << OpenStudio::Point3d.new( 17.4, 29.8, 49.5) # 36.6m
    os_v << OpenStudio::Point3d.new( 54.0, 29.8, 49.5) # 10.4m
    os_v << OpenStudio::Point3d.new( 54.0, 40.2, 49.5) # 36.6m
    os_g_sky = OpenStudio::Model::SubSurface.new(os_v, os_model)
    os_g_sky.setName("g_sky")
    expect(os_g_sky.setSurface(os_g_top)).to be(true)                 # 380.64m2

    os_v = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 24.0, 29.8, 46.7) #  1.5m
    os_v << OpenStudio::Point3d.new( 24.0, 28.3, 46.7) #  4.0m
    os_v << OpenStudio::Point3d.new( 28.0, 28.3, 46.7) #  1.5m
    os_v << OpenStudio::Point3d.new( 28.0, 29.8, 46.7) #  4.0m
    os_e_top = OpenStudio::Model::Surface.new(os_v, os_model)
    os_e_top.setName("e_top")
    expect(os_e_top.setSpace(os_g)).to be(true)                        #   6.0m2

    os_v = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 24.0, 28.3, 40.8) #  1.5m
    os_v << OpenStudio::Point3d.new( 24.0, 29.8, 40.8) #  4.0m
    os_v << OpenStudio::Point3d.new( 28.0, 29.8, 40.8) #  1.5m
    os_v << OpenStudio::Point3d.new( 28.0, 28.3, 40.8) #  4.0m
    os_e_floor = OpenStudio::Model::Surface.new(os_v, os_model)
    os_e_floor.setName("e_floor")
    expect(os_e_floor.setSpace(os_g)).to be(true)                      #   6.0m2
    expect(os_e_floor.setOutsideBoundaryCondition("Outdoors")).to be(true)

    # initially, elevator floor is defaulted ...
    expect(os_e_floor.surfaceType.downcase).to eq("floor")
    expect(os_e_floor.isConstructionDefaulted).to be(true)
    c = set.getDefaultConstruction(os_e_floor).get.to_LayeredConstruction.get
    expect(c.numLayers).to eq(3)
    expect(c.isOpaque).to be(true)
    expect(c.nameString).to eq("scrigno_construction")

    # ... now overriding default construction
    expect(os_e_floor.setConstruction(elevator_floor_c)).to be(true)
    expect(os_e_floor.isConstructionDefaulted).to be(false)
    c = os_e_floor.construction.get.to_LayeredConstruction.get
    expect(c.numLayers).to eq(3)
    expect(c.isOpaque).to be(true)
    expect(c.nameString).to eq("elevator_floor_c")

    os_v = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 24.0, 29.8, 46.7) #  5.9m
    os_v << OpenStudio::Point3d.new( 24.0, 29.8, 40.8) #  1.5m
    os_v << OpenStudio::Point3d.new( 24.0, 28.3, 40.8) #  5.9m
    os_v << OpenStudio::Point3d.new( 24.0, 28.3, 46.7) #  1.5m
    os_e_W_wall = OpenStudio::Model::Surface.new(os_v, os_model)
    os_e_W_wall.setName("e_W_wall")
    expect(os_e_W_wall.setSpace(os_g)).to be(true)                    #   8.85m2

    os_v = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 24.0, 28.3, 46.7) #  5.9m
    os_v << OpenStudio::Point3d.new( 24.0, 28.3, 40.8) #  4.0m
    os_v << OpenStudio::Point3d.new( 28.0, 28.3, 40.8) #  5.5m
    os_v << OpenStudio::Point3d.new( 28.0, 28.3, 46.7) #  4.0m
    os_e_S_wall = OpenStudio::Model::Surface.new(os_v, os_model)
    os_e_S_wall.setName("e_S_wall")
    expect(os_e_S_wall.setSpace(os_g)).to be(true)                     #  23.6m2

    os_v = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 28.0, 28.3, 46.7) #  5.9m
    os_v << OpenStudio::Point3d.new( 28.0, 28.3, 40.8) #  1.5m
    os_v << OpenStudio::Point3d.new( 28.0, 29.8, 40.8) #  5.9m
    os_v << OpenStudio::Point3d.new( 28.0, 29.8, 46.7) #  1.5m
    os_e_E_wall = OpenStudio::Model::Surface.new(os_v, os_model)
    os_e_E_wall.setName("e_E_wall")
    expect(os_e_E_wall.setSpace(os_g)).to be(true)                    #   8.85m2

    os_v = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 28.0, 29.8, 42.4) #  1.60m
    os_v << OpenStudio::Point3d.new( 28.0, 29.8, 40.8) #  4.00m
    os_v << OpenStudio::Point3d.new( 24.0, 29.8, 40.8) #  2.20m
    os_v << OpenStudio::Point3d.new( 24.0, 29.8, 43.0) #  4.04m
    os_e_N_wall = OpenStudio::Model::Surface.new(os_v, os_model)
    os_e_N_wall.setName("e_N_wall")
    expect(os_e_N_wall.setSpace(os_g)).to be(true)                    #  ~7.63m2

    os_v = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 28.0, 29.8, 44.0) #  1.60m
    os_v << OpenStudio::Point3d.new( 28.0, 29.8, 42.4) #  4.04m
    os_v << OpenStudio::Point3d.new( 24.0, 29.8, 43.0) #  1.00m
    os_v << OpenStudio::Point3d.new( 24.0, 29.8, 44.0) #  4.00m
    os_e_p_wall = OpenStudio::Model::Surface.new(os_v, os_model)
    os_e_p_wall.setName("e_p_wall")
    expect(os_e_p_wall.setSpace(os_g)).to be(true)                    #   ~5.2m2

    os_v = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 17.4, 29.8, 44.0) # 10.4m
    os_v << OpenStudio::Point3d.new( 17.4, 40.2, 44.0) # 36.6m
    os_v << OpenStudio::Point3d.new( 54.0, 40.2, 44.0) # 10.4m
    os_v << OpenStudio::Point3d.new( 54.0, 29.8, 44.0) # 36.6m
    os_g_floor = OpenStudio::Model::Surface.new(os_v, os_model)
    os_g_floor.setName("g_floor")
    expect(os_g_floor.setSpace(os_g) ).to be(true)                    # 380.64m2

    # 2nd space: plenum (p) with stairwell (s) surfaces
    os_v = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 17.4, 40.2, 44.0) # 10.4m
    os_v << OpenStudio::Point3d.new( 17.4, 29.8, 44.0) # 36.6m
    os_v << OpenStudio::Point3d.new( 54.0, 29.8, 44.0) # 10.4m
    os_v << OpenStudio::Point3d.new( 54.0, 40.2, 44.0) # 36.6m
    os_p_top = OpenStudio::Model::Surface.new(os_v, os_model)
    os_p_top.setName("p_top")
    expect(os_p_top.setSpace(os_p)).to be(true)                       # 380.64m2

    expect(os_p_top.setAdjacentSurface(os_g_floor)).to be(true)
    expect(os_g_floor.setAdjacentSurface(os_p_top)).to be(true)
    expect(os_p_top.setOutsideBoundaryCondition("Surface")).to be(true)
    expect(os_g_floor.setOutsideBoundaryCondition("Surface")).to be(true)

    os_v = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 24.0, 29.8, 44.0) #  1.00m
    os_v << OpenStudio::Point3d.new( 24.0, 29.8, 43.0) #  4.04m
    os_v << OpenStudio::Point3d.new( 28.0, 29.8, 42.4) #  1.60m
    os_v << OpenStudio::Point3d.new( 28.0, 29.8, 44.0) #  4.00m
    os_p_e_wall = OpenStudio::Model::Surface.new(os_v, os_model)
    os_p_e_wall.setName("p_e_wall")
    expect(os_p_e_wall.setSpace(os_p)).to be(true)                     #  ~5.2m2

    expect(os_e_p_wall.setAdjacentSurface(os_p_e_wall)).to be(true)
    expect(os_p_e_wall.setAdjacentSurface(os_e_p_wall)).to be(true)
    expect(os_p_e_wall.setOutsideBoundaryCondition("Surface")).to be(true)
    expect(os_e_p_wall.setOutsideBoundaryCondition("Surface")).to be(true)

    os_v = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 17.4, 29.8, 44.0) #   6.67m
    os_v << OpenStudio::Point3d.new( 24.0, 29.8, 43.0) #   1.00m
    os_v << OpenStudio::Point3d.new( 24.0, 29.8, 44.0) #   6.60m
    os_p_S1_wall = OpenStudio::Model::Surface.new(os_v, os_model)
    os_p_S1_wall.setName("p_S1_wall")
    expect(os_p_S1_wall.setSpace(os_p)).to be(true)                    #  ~3.3m2

    os_v = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 28.0, 29.8, 44.0) #   1.60m
    os_v << OpenStudio::Point3d.new( 28.0, 29.8, 42.4) #   2.73m
    os_v << OpenStudio::Point3d.new( 30.7, 29.8, 42.0) #  10.00m
    os_v << OpenStudio::Point3d.new( 40.7, 29.8, 42.0) #  13.45m
    os_v << OpenStudio::Point3d.new( 54.0, 29.8, 44.0) #  25.00m
    os_p_S2_wall = OpenStudio::Model::Surface.new(os_v, os_model)
    os_p_S2_wall.setName("p_S2_wall")
    expect(os_p_S2_wall.setSpace(os_p)).to be(true)                   #  38.15m2

    os_v = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 54.0, 40.2, 44.0) #  13.45m
    os_v << OpenStudio::Point3d.new( 40.7, 40.2, 42.0) #  10.00m
    os_v << OpenStudio::Point3d.new( 30.7, 40.2, 42.0) #  13.45m
    os_v << OpenStudio::Point3d.new( 17.4, 40.2, 44.0) #  36.60m
    os_p_N_wall = OpenStudio::Model::Surface.new(os_v, os_model)
    os_p_N_wall.setName("p_N_wall")
    expect(os_p_N_wall.setSpace(os_p)).to be(true)                    #  46.61m2

    os_v = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 30.7, 29.8, 42.0) # 10.4m
    os_v << OpenStudio::Point3d.new( 30.7, 40.2, 42.0) # 10.0m
    os_v << OpenStudio::Point3d.new( 40.7, 40.2, 42.0) # 10.4m
    os_v << OpenStudio::Point3d.new( 40.7, 29.8, 42.0) # 10.0m
    os_p_floor = OpenStudio::Model::Surface.new(os_v, os_model)
    os_p_floor.setName("p_floor")
    expect(os_p_floor.setSpace(os_p)).to be(true)                     # 104.00m2
    expect(os_p_floor.setOutsideBoundaryCondition("Outdoors")).to be(true)

    os_v = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 40.7, 29.8, 42.0) # 10.40m
    os_v << OpenStudio::Point3d.new( 40.7, 40.2, 42.0) # 13.45m
    os_v << OpenStudio::Point3d.new( 54.0, 40.2, 44.0) # 10.40m
    os_v << OpenStudio::Point3d.new( 54.0, 29.8, 44.0) # 13.45m
    os_p_E_floor = OpenStudio::Model::Surface.new(os_v, os_model)
    os_p_E_floor.setName("p_E_floor")
    expect(os_p_E_floor.setSpace(os_p)).to be(true)                   # 139.88m2
    expect(os_p_E_floor.setSurfaceType("Floor")).to be(true)  # walls by default

    os_v = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 17.4, 29.8, 44.0) # 10.40m
    os_v << OpenStudio::Point3d.new( 17.4, 40.2, 44.0) # ~6.68m
    os_v << OpenStudio::Point3d.new( 24.0, 40.2, 43.0) # 10.40m
    os_v << OpenStudio::Point3d.new( 24.0, 29.8, 43.0) # ~6.68m
    os_p_W1_floor = OpenStudio::Model::Surface.new(os_v, os_model)
    os_p_W1_floor.setName("p_W1_floor")
    expect(os_p_W1_floor.setSpace(os_p)).to be(true)                  #  69.44m2
    expect(os_p_W1_floor.setSurfaceType("Floor")).to be(true) # walls by default

    os_v = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 24.0, 29.8, 43.00) #  3.30m D
    os_v << OpenStudio::Point3d.new( 24.0, 33.1, 43.00) #  5.06m C
    os_v << OpenStudio::Point3d.new( 29.0, 33.1, 42.26) #  3.80m I
    os_v << OpenStudio::Point3d.new( 29.0, 36.9, 42.26) #  5.06m H
    os_v << OpenStudio::Point3d.new( 24.0, 36.9, 43.00) #  3.30m B
    os_v << OpenStudio::Point3d.new( 24.0, 40.2, 43.00) #  6.77m A
    os_v << OpenStudio::Point3d.new( 30.7, 40.2, 42.00) # 10.40m E
    os_v << OpenStudio::Point3d.new( 30.7, 29.8, 42.00) #  6.77m F
    os_p_W2_floor = OpenStudio::Model::Surface.new(os_v, os_model)
    os_p_W2_floor.setName("p_W2_floor")
    expect(os_p_W2_floor.setSpace(os_p)).to be(true)                  #  51.23m2
    expect(os_p_W2_floor.setSurfaceType("Floor")).to be(true) # walls by default

    os_v = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 24.0, 36.9, 43.0) #  2.2m
    os_v << OpenStudio::Point3d.new( 24.0, 36.9, 40.8) #  3.8m
    os_v << OpenStudio::Point3d.new( 24.0, 33.1, 40.8) #  2.2m
    os_v << OpenStudio::Point3d.new( 24.0, 33.1, 43.0) #  3.8m
    os_s_W_wall = OpenStudio::Model::Surface.new(os_v, os_model)
    os_s_W_wall.setName("s_W_wall")
    expect(os_s_W_wall.setSpace(os_p)).to be(true)                    #   8.39m2

    os_v = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 29.0, 36.9, 42.26) #  1.46m
    os_v << OpenStudio::Point3d.new( 29.0, 36.9, 40.80) #  5.00m
    os_v << OpenStudio::Point3d.new( 24.0, 36.9, 40.80) #  2.20m
    os_v << OpenStudio::Point3d.new( 24.0, 36.9, 43.00) #  5.06m
    os_s_N_wall = OpenStudio::Model::Surface.new(os_v, os_model)
    os_s_N_wall.setName("s_N_wall")
    expect(os_s_N_wall.setSpace(os_p)).to be(true)                    #   9.15m2

    os_v = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 29.0, 33.1, 42.26) #  1.46m
    os_v << OpenStudio::Point3d.new( 29.0, 33.1, 40.80) #  3.80m
    os_v << OpenStudio::Point3d.new( 29.0, 36.9, 40.80) #  1.46m
    os_v << OpenStudio::Point3d.new( 29.0, 36.9, 42.26) #  3.80m
    os_s_E_wall = OpenStudio::Model::Surface.new(os_v, os_model)
    os_s_E_wall.setName("s_E_wall")
    expect(os_s_E_wall.setSpace(os_p)).to be(true)                    #   5.55m2

    os_v = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 24.0, 33.1, 43.00) #  2.20m
    os_v << OpenStudio::Point3d.new( 24.0, 33.1, 40.80) #  5.00m
    os_v << OpenStudio::Point3d.new( 29.0, 33.1, 40.80) #  1.46m
    os_v << OpenStudio::Point3d.new( 29.0, 33.1, 42.26) #  5.06m
    os_s_S_wall = OpenStudio::Model::Surface.new(os_v, os_model)
    os_s_S_wall.setName("s_S_wall")
    expect(os_s_S_wall.setSpace(os_p)).to be(true)                    #   9.15m2

    os_v = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 24.0, 33.1, 40.8) #  3.8m
    os_v << OpenStudio::Point3d.new( 24.0, 36.9, 40.8) #  5.0m
    os_v << OpenStudio::Point3d.new( 29.0, 36.9, 40.8) #  3.8m
    os_v << OpenStudio::Point3d.new( 29.0, 33.1, 40.8) #  5.0m
    os_s_floor = OpenStudio::Model::Surface.new(os_v, os_model)
    os_s_floor.setName("s_floor")
    expect(os_s_floor.setSpace(os_p)).to be(true)                      #  19.0m2
    expect(os_s_floor.setSurfaceType("Floor")).to be(true)
    expect(os_s_floor.setOutsideBoundaryCondition("Outdoors")).to be(true)

    pth = File.join(__dir__, "files/osms/out/os_model_test.osm")
    os_model.save(pth, true)

    # Create the Topolys Model.
    t_model = Topolys::Model.new

    # "true" if any OSM space/zone holds DD setpoint temperatures.
    setpoints = TBD.heatingTemperatureSetpoints?(os_model)
    setpoints = TBD.coolingTemperatureSetpoints?(os_model) || setpoints

    # "true" if any OSM space/zone is part of an HVAC air loop.
    airloops = TBD.airLoopsHVAC?(os_model)

    # Fetch OpenStudio (opaque) surfaces & key attributes.
    surfaces = {}

    os_model.getSurfaces.each do |s|
      surface  = TBD.properties(os_model, s)
      next if    surface.nil?
      expect(surface.is_a?(Hash)).to be(true)
      expect(surface.key?(:space)).to be(true)
      surfaces[s.nameString] = surface
    end                                            # (opaque) surfaces populated

    expect(surfaces.empty?).to be(false)

    surfaces.each do |id, surface|
      expect(surface[:conditioned]).to be(true)
      expect(surface.key?(:heating)).to be(false)
      expect(surface.key?(:cooling)).to be(false)
    end

    surfaces.each do |id, surface|
      surface[:deratable] = false

      next unless surface[:conditioned]
      next     if surface[:ground]

      unless surface[:boundary].downcase == "outdoors"
        next if surfaces[surface[:boundary]][:conditioned]
      end

      expect(surface.key?(:index)).to be(true)
      surface[:deratable] = true
    end

    [:windows, :doors, :skylights].each do |holes|                   # sort kids
      surfaces.values.each do |surface|
        ok = surface.key?(holes)
        surface[holes] = surface[holes].sort_by { |_, s| s[:minz] }.to_h   if ok
      end
    end

    expect(surfaces["g_top"   ].key?(:windows  )).to be(false)
    expect(surfaces["g_top"   ].key?(:doors    )).to be(false)
    expect(surfaces["g_top"   ].key?(:skylights)).to be(true)

    expect(surfaces["g_top"   ][:skylights].size).to eq(1)
    expect(surfaces["g_S_wall"][:doors    ].size).to eq(1)
    expect(surfaces["g_N_wall"][:doors    ].size).to eq(1)

    expect(surfaces["g_top"   ][:skylights].key?("g_sky"   )).to be(true)
    expect(surfaces["g_S_wall"][:doors    ].key?("g_S_door")).to be(true)
    expect(surfaces["g_N_wall"][:doors    ].key?("g_N_door")).to be(true)

    expect(surfaces["g_top"   ].key?(:type)).to be(true)

    # Split "surfaces" hash into "floors", "ceilings" and "walls" hashes.
    floors   = surfaces.select  { |_, s| s[:type] == :floor    }
    ceilings = surfaces.select  { |_, s| s[:type] == :ceiling  }
    walls    = surfaces.select  { |_, s| s[:type] == :wall     }
    floors   = floors.sort_by   { |_, s| [s[:minz], s[:space]] }.to_h
    ceilings = ceilings.sort_by { |_, s| [s[:minz], s[:space]] }.to_h
    walls    = walls.sort_by    { |_, s| [s[:minz], s[:space]] }.to_h

    expect(floors.size).to eq(7)
    expect(ceilings.size).to eq(3)
    expect(walls.size).to eq(17)

    # Fetch OpenStudio shading surfaces & key attributes.
    shades = {}

    os_model.getShadingSurfaces.each do |s|
      next if s.shadingSurfaceGroup.empty?

      id      = s.nameString
      group   = s.shadingSurfaceGroup.get
      shading = group.to_ShadingSurfaceGroup
      tr      = TBD.transforms(os_model, group)
      expect(tr.is_a?(Hash)).to be(true)
      expect(tr.key?(:t)).to be(true)
      expect(tr.key?(:r)).to be(true)
      expect(tr[:t].nil?).to be(false)
      expect(tr[:r].nil?).to be(false)
      t       = tr[:t]
      r       = tr[:r]

      unless shading.empty?
        empty = shading.get.space.empty?
        r += shading.get.space.get.directionofRelativeNorth         unless empty
      end

      n = TBD.trueNormal(s, r)
      expect(n.nil?).to be(false)

      points = (t * s.vertices).map{ |v| Topolys::Point3D.new(v.x, v.y, v.z) }
      minz = (points.map{ |p| p.z }).min
      shades[id] = { group: group, points: points, minz: minz, n: n }
    end

    expect(shades.size).to eq(6)

    # Mutually populate TBD & Topolys surfaces. Keep track of created "holes".
    holes         = {}
    floor_holes   = TBD.dads(t_model, floors  )
    ceiling_holes = TBD.dads(t_model, ceilings)
    wall_holes    = TBD.dads(t_model, walls   )

    holes.merge!(floor_holes  )
    holes.merge!(ceiling_holes)
    holes.merge!(wall_holes   )

    expect(floor_holes.size).to eq(0)
    expect(ceiling_holes.size).to eq(1)
    expect(wall_holes.size).to eq(2)
    expect(holes.size).to eq(3)

    floors.values.each do |props|                              # testing normals
      t_x = props[:face].outer.plane.normal.x
      t_y = props[:face].outer.plane.normal.y
      t_z = props[:face].outer.plane.normal.z

      expect(props[:n].x).to be_within(0.001).of(t_x)
      expect(props[:n].y).to be_within(0.001).of(t_y)
      expect(props[:n].z).to be_within(0.001).of(t_z)
    end

    # OpenStudio (opaque) surfaces VS number of Topolys (opaque) faces
    expect(surfaces.size).to eq(27)
    expect(t_model.faces.size).to eq(27)

    TBD.dads(t_model, shades)
    expect(t_model.faces.size).to eq(33)

    # Loop through Topolys edges and populate TBD edge hash. Initially, there
    # should be a one-to-one correspondence between Topolys and TBD edge
    # objects. Use Topolys-generated identifiers as unique edge hash keys.
    edges = {}

    holes.each do |id, wire|                             # start with hole edges
      wire.edges.each do |e|
        i = e.id
        l = e.length
        ok = edges.key?(i)
        edges[i] = { length: l, v0: e.v0, v1: e.v1, surfaces: {} }     unless ok
        ok = edges[i][:surfaces].key?(wire.attributes[:id])
        edges[i][:surfaces][wire.attributes[:id]] = { wire: wire.id }  unless ok
      end
    end

    expect(edges.size).to eq(12)

    # Next, floors, ceilings & walls; then shades.
    TBD.faces(floors, edges)
    expect(edges.size).to eq(47)

    TBD.faces(ceilings, edges)
    expect(edges.size).to eq(51)

    TBD.faces(walls, edges)
    expect(edges.size).to eq(67)

    TBD.faces(shades, edges)
    expect(edges.size).to eq(89)
    expect(t_model.edges.size).to eq(89)

    # the following surfaces should all share an edge
    p_S2_wall_face = walls["p_S2_wall"][:face]
    e_p_wall_face  = walls["e_p_wall"][:face]
    p_e_wall_face  = walls["p_e_wall"][:face]
    e_E_wall_face  = walls["e_E_wall"][:face]

    p_S2_wall_edge_ids = Set.new(p_S2_wall_face.outer.edges.map{|oe| oe.id})
    e_p_wall_edges_ids = Set.new(e_p_wall_face.outer.edges.map{|oe| oe.id})
    p_e_wall_edges_ids = Set.new(p_e_wall_face.outer.edges.map{|oe| oe.id})
    e_E_wall_edges_ids = Set.new(e_E_wall_face.outer.edges.map{|oe| oe.id})

    intersection = p_S2_wall_edge_ids & e_p_wall_edges_ids & p_e_wall_edges_ids
    expect(intersection.size).to eq(1)

    intersection = p_S2_wall_edge_ids & e_p_wall_edges_ids &
                   p_e_wall_edges_ids & e_E_wall_edges_ids
    expect(intersection.size).to eq(1)

    shared_edges = p_S2_wall_face.shared_outer_edges(e_p_wall_face)
    expect(shared_edges.size).to eq(1)
    expect(shared_edges.first.id).to eq(intersection.to_a.first)

    shared_edges = p_S2_wall_face.shared_outer_edges(p_e_wall_face)
    expect(shared_edges.size).to eq(1)
    expect(shared_edges.first.id).to eq(intersection.to_a.first)

    shared_edges = p_S2_wall_face.shared_outer_edges(e_E_wall_face)
    expect(shared_edges.size).to eq(1)
    expect(shared_edges.first.id).to eq(intersection.to_a.first)

    # g_floor and p_top should be connected with all edges shared
    g_floor_face  = floors["g_floor"][:face]
    g_floor_wire  = g_floor_face.outer
    g_floor_edges = g_floor_wire.edges
    p_top_face    = ceilings["p_top"][:face]
    p_top_wire    = p_top_face.outer
    p_top_edges   = p_top_wire.edges
    shared_edges  = p_top_face.shared_outer_edges(g_floor_face)

    expect(g_floor_edges.size).to be > 4
    expect(g_floor_edges.size).to eq(p_top_edges.size)
    expect(shared_edges.size).to eq(p_top_edges.size)

    g_floor_edges.each do |g_floor_edge|
      p_top_edge = p_top_edges.find{|e| e.id == g_floor_edge.id}
      expect(p_top_edge).to be_truthy
    end

    expect(floors.size  ).to eq(7 )
    expect(ceilings.size).to eq(3 )
    expect(walls.size   ).to eq(17)
    expect(shades.size  ).to eq(6 )

    zenith = Topolys::Vector3D.new(0, 0, 1).freeze
    north  = Topolys::Vector3D.new(0, 1, 0).freeze
    east   = Topolys::Vector3D.new(1, 0, 0).freeze

    edges.values.each do |edge|
      origin      = edge[:v0].point
      terminal    = edge[:v1].point
      dx          = (origin.x - terminal.x).abs
      dy          = (origin.y - terminal.y).abs
      dz          = (origin.z - terminal.z).abs
      horizontal  = dz.abs < TOL
      vertical    = dx < TOL && dy < TOL
      edge_V      = terminal - origin
      edge_plane  = Topolys::Plane3D.new(origin, edge_V)

      if vertical
        reference_V = north.dup
      elsif horizontal
        reference_V = zenith.dup
      else
        reference = edge_plane.project(origin + zenith)
        reference_V = reference - origin
      end

      edge[:surfaces].each do |id, surface|
        t_model.wires.each do |wire|
          if surface[:wire] == wire.id
            normal     = surfaces[id][:n]         if surfaces.key?(id)
            normal     = holes[id].attributes[:n] if holes.key?(id)
            normal     = shades[id][:n]           if shades.key?(id)
            farthest   = Topolys::Point3D.new(origin.x, origin.y, origin.z)
            farthest_V = farthest - origin
            inverted   = false
            i_origin   = wire.points.index(origin)
            i_terminal = wire.points.index(terminal)
            i_last     = wire.points.size - 1

            if i_terminal == 0
              inverted = true unless i_origin == i_last
            elsif i_origin == i_last
              inverted = true unless i_terminal == 0
            else
              inverted = true unless i_terminal - i_origin == 1
            end

            wire.points.each do |point|
              next if point == origin
              next if point == terminal
              point_on_plane = edge_plane.project(point)
              origin_point_V = point_on_plane - origin
              point_V_magnitude = origin_point_V.magnitude
              next unless point_V_magnitude > 0.01

              if inverted
                plane = Topolys::Plane3D.from_points(terminal, origin, point)
              else
                plane = Topolys::Plane3D.from_points(origin, terminal, point)
              end

              next unless (normal.x - plane.normal.x).abs < 0.01 &&
                          (normal.y - plane.normal.y).abs < 0.01 &&
                          (normal.z - plane.normal.z).abs < 0.01

              farther    = point_V_magnitude > farthest_V.magnitude
              farthest   = point          if farther
              farthest_V = origin_point_V if farther
            end

            angle = edge_V.angle(farthest_V)
            expect(angle).to be_within(0.01).of(Math::PI / 2)

            angle = reference_V.angle(farthest_V)
            adjust = false

            if vertical
              adjust = true if east.dot(farthest_V) < -TOL
            else
              if north.dot(farthest_V).abs < TOL            ||
                (north.dot(farthest_V).abs - 1).abs < TOL
                  adjust = true if east.dot(farthest_V) < -TOL
              else
                adjust = true if north.dot(farthest_V) < -TOL
              end
            end

            angle = 2 * Math::PI - angle if adjust
            angle -= 2 * Math::PI if (angle - 2 * Math::PI).abs < TOL
            surface[:angle] = angle
            farthest_V.normalize!
            surface[:polar] = farthest_V
            surface[:normal] = normal
          end
        end                           # end of edge-linked, surface-to-wire loop
      end                                      # end of edge-linked surface loop

      edge[:horizontal] = horizontal
      edge[:vertical  ] = vertical
      edge[:surfaces  ] = edge[:surfaces].sort_by{ |i, p| p[:angle] }.to_h
    end                                                       # end of edge loop

    expect(edges.size).to eq(89)
    expect(t_model.edges.size).to eq(89)

    argh[:option] = "poor (BETBG)"
    json = TBD.inputs(surfaces, edges, argh)
    expect(TBD.status).to eq(0)
    expect(TBD.logs.empty?).to be(true)
    expect(json[:io].nil?).to be(false)
    expect(json[:io].empty?).to be(false)
    expect(json[:io].key?(:building)).to be(true)
    expect(json[:io][:building].key?(:psi)).to be(true)
    psi = json[:io][:building][:psi]
    shorts = json[:psi].shorthands(psi)
    expect(shorts[:has].empty?).to be(false)
    expect(shorts[:val].empty?).to be(false)

    edges.values.each do |edge|
      next unless edge.key?(:surfaces)
      deratables = []

      edge[:surfaces].keys.each do |id|
        # puts "edge linked to g_N_door" if id == "g_N_door" && edge[:surfaces].include?("g_N_wall")
        next unless surfaces.key?(id)
        deratables << id if surfaces[id][:deratable]
      end

      next if deratables.empty?
      set = {}

      edge[:surfaces].keys.each do |id|
        next unless surfaces.key?(id)
        next unless deratables.include?(id)

        # Evaluate current set content before processing a new linked surface.
        is            = {}
        is[:head    ] = set.keys.to_s.include?("head"    )
        is[:sill    ] = set.keys.to_s.include?("sill"    )
        is[:jamb    ] = set.keys.to_s.include?("jamb"    )
        is[:corner  ] = set.keys.to_s.include?("corner"  )
        is[:parapet ] = set.keys.to_s.include?("parapet" )
        is[:party   ] = set.keys.to_s.include?("party"   )
        is[:grade   ] = set.keys.to_s.include?("grade"   )
        is[:balcony ] = set.keys.to_s.include?("balcony" )
        is[:rimjoist] = set.keys.to_s.include?("rimjoist")

        # Label edge as :head, :sill or :jamb if linked to:
        #   1x subsurface
        edge[:surfaces].keys.each do |i|
          break    if is[:head] || is[:sill] || is[:jamb]
          next     if i == id
          next     if deratables.include?(i)
          next unless holes.key?(i)

          gardian = ""
          gardian = id if deratables.size == 1                        # just dad

          if gardian.empty?                                         # seek uncle
            pops   = {}                                             # daughters?
            uncles = {}                                             #    nieces?
            girls  = []                                             #  daughters
            nieces = []                                             #     nieces
            uncle  = deratables.first unless deratables.first == id # uncle 1st?
            uncle  = deratables.last  unless deratables.last  == id # uncle 2nd?

            pops[:w  ] = surfaces[id   ].key?(:windows  )
            pops[:d  ] = surfaces[id   ].key?(:doors    )
            pops[:s  ] = surfaces[id   ].key?(:skylights)
            uncles[:w] = surfaces[uncle].key?(:windows  )
            uncles[:d] = surfaces[uncle].key?(:doors    )
            uncles[:s] = surfaces[uncle].key?(:skylights)

            girls  += surfaces[id   ][:windows  ].keys if   pops[:w]
            girls  += surfaces[id   ][:doors    ].keys if   pops[:d]
            girls  += surfaces[id   ][:skylights].keys if   pops[:s]
            nieces += surfaces[uncle][:windows  ].keys if uncles[:w]
            nieces += surfaces[uncle][:doors    ].keys if uncles[:d]
            nieces += surfaces[uncle][:skylights].keys if uncles[:s]

            gardian = uncle if  girls.include?(i)
            gardian = id    if nieces.include?(i)
          end

          # puts "gardian: #{gardian} "if i == "g_N_door"

          next if gardian.empty?
          s1      = edge[:surfaces][gardian]
          s2      = edge[:surfaces][i]
          concave = TBD.concave?(s1, s2)
          convex  = TBD.convex?(s1, s2)
          flat    = !concave && !convex

          # puts "#{i}: #{concave} | #{convex} | #{flat}" if id == "g_N_door"

          # Subsurface edges are tagged as :head, :sill or :jamb, regardless
          # of building PSI set subsurface tags. If the latter is simply
          # :fenestration, then its (single) PSI value is systematically
          # attributed to subsurface :head, :sill & :jamb edges. If absent,
          # concave or convex variants also inherit from base type.
          #
          # TBD tags a subsurface edge as :jamb if the subsurface is "flat".
          # If not flat, TBD tags a horizontal edge as either :head or :sill
          # based on the polar angle of the subsurface around the edge vs sky
          # zenith. Otherwise, all other subsurface edges are tagged as :jamb.
          if ((s2[:normal].dot(zenith)).abs - 1).abs < TOL
            set[:jamb       ] = shorts[:val][:jamb       ] if flat
            set[:jambconcave] = shorts[:val][:jambconcave] if concave
            set[:jambconvex ] = shorts[:val][:jambconvex ] if convex
             is[:jamb       ] = true
          else
            if edge[:horizontal]
              if s2[:polar].dot(zenith) < 0
                set[:head       ] = shorts[:val][:head       ] if flat
                set[:headconcave] = shorts[:val][:headconcave] if concave
                set[:headconvex ] = shorts[:val][:headconvex ] if convex
                 is[:head       ] = true
              else
                set[:sill       ] = shorts[:val][:sill       ] if flat
                set[:sillconcave] = shorts[:val][:sillconcave] if concave
                set[:sillconvex ] = shorts[:val][:sillconvex ] if convex
                 is[:sill       ] = true
              end
            else
              set[:jamb       ] = shorts[:val][:jamb       ] if flat
              set[:jambconcave] = shorts[:val][:jambconcave] if concave
              set[:jambconvex ] = shorts[:val][:jambconvex ] if convex
               is[:jamb       ] = true
            end
          end
        end

        # Label edge as :cornerconcave or :cornerconvex if linked to:
        #   2x deratable walls & f(relative polar wall vectors around edge)
        edge[:surfaces].keys.each do |i|
          break     if is[:corner]
          break unless deratables.size == 2
          break unless walls.key?(id)
          next      if i == id
          next unless deratables.include?(i)
          next unless walls.key?(i)

          s1      = edge[:surfaces][id]
          s2      = edge[:surfaces][i]
          concave = TBD.concave?(s1, s2)
          convex  = TBD.convex?(s1, s2)

          set[:cornerconcave] = shorts[:val][:cornerconcave] if concave
          set[:cornerconvex ] = shorts[:val][:cornerconvex ] if convex
           is[:corner       ] = true
        end

        # Label edge as :parapet if linked to:
        #   1x deratable wall
        #   1x deratable ceiling
        edge[:surfaces].keys.each do |i|
          break     if is[:parapet]
          break unless deratables.size == 2
          break unless ceilings.key?(id)
          next      if i == id
          next  unless deratables.include?(i)
          next  unless walls.key?(i)

          s1      = edge[:surfaces][id]
          s2      = edge[:surfaces][i]
          concave = TBD.concave?(s1, s2)
          convex  = TBD.convex?(s1, s2)
          flat    = !concave && !convex

          set[:parapet       ] = shorts[:val][:parapet       ] if flat
          set[:parapetconcave] = shorts[:val][:parapetconcave] if concave
          set[:parapetconvex ] = shorts[:val][:parapetconvex ] if convex
           is[:parapet       ] = true
        end

        # Label edge as :grade if linked to:
        #   1x surface (e.g. slab or wall) facing ground
        #   1x surface (i.e. wall) facing outdoors
        edge[:surfaces].keys.each do |i|
          break     if is[:grade]
          break unless deratables.size == 1
          next      if i == id
          next  unless surfaces.key?(i)
          next  unless surfaces[i].key?(:ground)
          next  unless surfaces[i][:ground]

          s1      = edge[:surfaces][id]
          s2      = edge[:surfaces][i]
          concave = TBD.concave?(s1, s2)
          convex  = TBD.convex?(s1, s2)
          flat    = !concave && !convex

          set[:grade       ] = shorts[:val][:grade       ] if flat
          set[:gradeconcave] = shorts[:val][:gradeconcave] if concave
          set[:gradeconvex ] = shorts[:val][:gradeconvex ] if convex
           is[:grade       ] = true
        end

        # Label edge as :grade if linked to:
        #   1x surface (e.g. slab or wall) facing ground
        #   1x surface (i.e. wall) facing outdoors
        unless is[:grade]
          edge[:surfaces].keys.each do |i|
            next if is[:grade]
            next if i == id
            next unless deratables.size == 1
            next unless surfaces.key?(i)
            next unless surfaces[i].key?(:ground)
            next unless surfaces[i][:ground]

            s1      = edge[:surfaces][id]
            s2      = edge[:surfaces][i]
            concave = TBD.concave?(s1, s2)
            convex  = TBD.convex?(s1, s2)
            flat    = !concave && !convex

            psi[:grade]        = val[:grade]        if flat
            psi[:gradeconcave] = val[:gradeconcave] if concave
            psi[:gradeconvex]  = val[:gradeconvex]  if convex
             is[:grade]        = true
          end
        end

        # Label edge as :rimjoist (or :balcony) if linked to:
        #   1x deratable surface
        #   1x CONDITIONED floor
        #   1x shade (optional)
        balcony = false

        edge[:surfaces].keys.each do |i|
          break          if balcony
          next           if i == id
          balcony = true if shades.key?(i)
        end

        edge[:surfaces].keys.each do |i|
          break     if is[:rimjoist] || is[:balcony]
          break unless deratables.size == 2
          break     if floors.key?(id)
          next      if i == id
          next  unless floors.key?(i)
          next  unless floors[i].key?(:conditioned)
          next  unless floors[i][:conditioned]
          next      if floors[i][:ground]

          other = deratables.first unless deratables.first == id
          other = deratables.last  unless deratables.last  == id

          s1      = edge[:surfaces][id]
          s2      = edge[:surfaces][other]
          concave = TBD.concave?(s1, s2)
          convex  = TBD.convex?(s1, s2)
          flat    = !concave && !convex

          if balcony
            set[:balcony        ] = shorts[:val][:balcony        ] if flat
            set[:balconyconcave ] = shorts[:val][:balconyconcave ] if concave
            set[:balconyconvex  ] = shorts[:val][:balconyconvex  ] if convex
             is[:balcony        ] = true
          else
            set[:rimjoist       ] = shorts[:val][:rimjoist       ] if flat
            set[:rimjoistconcave] = shorts[:val][:rimjoistconcave] if concave
            set[:rimjoistconvex ] = shorts[:val][:rimjoistconvex ] if convex
             is[:rimjoist       ] = true
          end
        end                                               # edge's surfaces loop
      end

      edge[:psi] = set unless set.empty?
      edge[:set] = psi unless set.empty?
    end                                                              # edge loop

    # Tracking (mild) transitions.
    transitions = {}

    edges.each do |tag, edge|
      trnz      = []
      next     if edge.key?(:psi)
      next unless edge.key?(:surfaces)
      deratable = false

      edge[:surfaces].keys.each do |id|
        next unless surfaces.key?(id)
        next unless surfaces[id][:deratable]
        deratable = surfaces[id][:deratable]
        trnz << id
      end

      next unless deratable
      edge[:psi] = { transition: 0.0 }
      edge[:set] = json[:io][:building][:psi]
      transitions[tag] = trnz unless trnz.empty?
    end

    # Lo Scrigno: such transitions occur between plenum floor plates.
    expect(transitions.empty?).to be(false)
    expect(transitions.size).to eq(4)
    w1_count = 0

    transitions.values.each do |trnz|
      expect(trnz.size).to eq(2)

      if trnz.include?("p_W1_floor")
        w1_count += 1
        expect(trnz.include?("p_W2_floor")).to be(true)
      else
        expect(trnz.include?("p_floor")).to be(true)
        valid1 = trnz.include?("p_W2_floor")
        valid2 = trnz.include?("p_E_floor")
        valid  = valid1 || valid2
        expect(valid).to be(true)
      end
    end

    expect(w1_count).to eq(2)

    n_deratables                 = 0
    n_edges_at_grade             = 0
    n_edges_as_balconies         = 0
    n_edges_as_parapets          = 0
    n_edges_as_rimjoists         = 0
    n_edges_as_concave_rimjoists = 0
    n_edges_as_convex_rimjoists  = 0
    n_edges_as_fenestrations     = 0
    n_edges_as_heads             = 0
    n_edges_as_sills             = 0
    n_edges_as_jambs             = 0
    n_edges_as_concave_jambs     = 0
    n_edges_as_convex_jambs      = 0
    n_edges_as_corners           = 0
    n_edges_as_concave_corners   = 0
    n_edges_as_convex_corners    = 0
    n_edges_as_transitions       = 0

    edges.values.each do |edge|
      next unless edge.key?(:psi)
      n_deratables                 += 1
      n_edges_at_grade             += 1 if edge[:psi].key?(:grade          )
      n_edges_at_grade             += 1 if edge[:psi].key?(:gradeconcave   )
      n_edges_at_grade             += 1 if edge[:psi].key?(:gradeconvex    )
      n_edges_as_balconies         += 1 if edge[:psi].key?(:balcony        )
      n_edges_as_parapets          += 1 if edge[:psi].key?(:parapetconcave )
      n_edges_as_parapets          += 1 if edge[:psi].key?(:parapetconvex  )
      n_edges_as_rimjoists         += 1 if edge[:psi].key?(:rimjoist       )
      n_edges_as_concave_rimjoists += 1 if edge[:psi].key?(:rimjoistconcave)
      n_edges_as_convex_rimjoists  += 1 if edge[:psi].key?(:rimjoistconvex )
      n_edges_as_fenestrations     += 1 if edge[:psi].key?(:fenestration   )
      n_edges_as_heads             += 1 if edge[:psi].key?(:head           )
      n_edges_as_sills             += 1 if edge[:psi].key?(:sill           )
      n_edges_as_jambs             += 1 if edge[:psi].key?(:jamb           )
      n_edges_as_concave_jambs     += 1 if edge[:psi].key?(:jambconcave    )
      n_edges_as_convex_jambs      += 1 if edge[:psi].key?(:jambconvex     )
      n_edges_as_corners           += 1 if edge[:psi].key?(:corner         )
      n_edges_as_concave_corners   += 1 if edge[:psi].key?(:cornerconcave  )
      n_edges_as_convex_corners    += 1 if edge[:psi].key?(:cornerconvex   )
      n_edges_as_transitions       += 1 if edge[:psi].key?(:transition     )
    end

    expect(n_deratables).to                 eq(66)
    expect(n_edges_at_grade).to             eq( 0)
    expect(n_edges_as_balconies).to         eq( 4)
    expect(n_edges_as_parapets).to          eq( 8)
    expect(n_edges_as_rimjoists).to         eq( 5)
    expect(n_edges_as_concave_rimjoists).to eq( 5)
    expect(n_edges_as_convex_rimjoists).to  eq(18)
    expect(n_edges_as_fenestrations).to     eq( 0)
    expect(n_edges_as_heads).to             eq( 2)
    expect(n_edges_as_sills).to             eq( 2)
    expect(n_edges_as_jambs).to             eq( 4)
    expect(n_edges_as_concave_jambs).to     eq( 0)
    expect(n_edges_as_convex_jambs).to      eq( 4)
    expect(n_edges_as_corners).to           eq( 0)
    expect(n_edges_as_concave_corners).to   eq( 4)
    expect(n_edges_as_convex_corners).to    eq(12)
    expect(n_edges_as_transitions).to       eq( 4)

    # Loop through each edge and assign heat loss to linked surfaces.
    edges.each do |identifier, edge|
      next unless  edge.key?(:psi)
      rsi        = 0
      max        = edge[:psi].values.max
      type       = edge[:psi].key(max)
      length     = edge[:length]
      bridge     = { psi: max, type: type, length: length }
      deratables = {}
      apertures  = {}

      if edge.key?(:sets) && edge[:sets].key?(type)
        edge[:set] = edge[:sets][type]
      end

      # Retrieve valid linked surfaces as deratables.
      edge[:surfaces].each do |id, s|
        next unless surfaces.key?(id)
        next unless surfaces[id][:deratable]
        deratables[id] = s
      end

      edge[:surfaces].each { |id, s| apertures[id] = s if holes.key?(id) }
      next if apertures.size > 1                        # edge links 2x openings

      # Prune dad if edge links an opening, its dad and an uncle.
      if deratables.size > 1 && apertures.size > 0
        deratables.each do |id, deratable|
          [:windows, :doors, :skylights].each do |types|
            next unless surfaces[id].key?(types)
            surfaces[id][types].keys.each do |sub|
              deratables.delete(id) if apertures.key?(sub)
            end
          end
        end
      end

      next if deratables.empty?

      # Sum RSI of targeted insulating layer from each deratable surface.
      deratables.each do |id, deratable|
        expect(surfaces[id].key?(:r)).to be(true)
        rsi += surfaces[id][:r]
      end

      # Assign heat loss from thermal bridges to surfaces, in proportion to
      # insulating layer thermal resistance
      deratables.each do |id, deratable|
        ratio = 0
        ratio = surfaces[id][:r] / rsi if rsi > 0.001
        loss  = bridge[:psi] * ratio
        b     = { psi: loss, type: bridge[:type], length: length, ratio: ratio }
        surfaces[id][:edges] = {} unless surfaces[id].key?(:edges)
        surfaces[id][:edges][identifier] = b
      end
    end

    # Assign thermal bridging heat loss [in W/K] to each deratable surface.
    n_surfaces_to_derate = 0

    surfaces.each do |id, surface|
      next unless surface.key?(:edges)
      surface[:heatloss] = 0
      e = surface[:edges].values
      e.each { |edge| surface[:heatloss] += edge[:psi] * edge[:length] }
      n_surfaces_to_derate += 1
    end

    #expect(n_surfaces_to_derate).to eq(0) # if "(non thermal bridging)"
    expect(n_surfaces_to_derate).to eq(22) # if "poor (BETBG)"

    # if "poor (BETBG)"
    expect(surfaces["s_floor"   ][:heatloss]).to be_within(0.01).of( 8.800)
    expect(surfaces["s_E_wall"  ][:heatloss]).to be_within(0.01).of( 5.041)
    expect(surfaces["p_E_floor" ][:heatloss]).to be_within(0.01).of(18.650)
    expect(surfaces["s_S_wall"  ][:heatloss]).to be_within(0.01).of( 6.583)
    expect(surfaces["e_W_wall"  ][:heatloss]).to be_within(0.01).of( 6.023)
    expect(surfaces["p_N_wall"  ][:heatloss]).to be_within(0.01).of(37.250)
    expect(surfaces["p_S2_wall" ][:heatloss]).to be_within(0.01).of(27.268)
    expect(surfaces["p_S1_wall" ][:heatloss]).to be_within(0.01).of( 7.063)
    expect(surfaces["g_S_wall"  ][:heatloss]).to be_within(0.01).of(56.150)
    expect(surfaces["p_floor"   ][:heatloss]).to be_within(0.01).of(10.000)
    expect(surfaces["p_W1_floor"][:heatloss]).to be_within(0.01).of(13.775)
    expect(surfaces["e_N_wall"  ][:heatloss]).to be_within(0.01).of( 4.727)
    expect(surfaces["s_N_wall"  ][:heatloss]).to be_within(0.01).of( 6.583)
    expect(surfaces["g_E_wall"  ][:heatloss]).to be_within(0.01).of(18.195)
    expect(surfaces["e_S_wall"  ][:heatloss]).to be_within(0.01).of( 7.703)
    expect(surfaces["e_top"     ][:heatloss]).to be_within(0.01).of( 4.400)
    expect(surfaces["s_W_wall"  ][:heatloss]).to be_within(0.01).of( 5.670)
    expect(surfaces["e_E_wall"  ][:heatloss]).to be_within(0.01).of( 6.023)
    expect(surfaces["e_floor"   ][:heatloss]).to be_within(0.01).of( 8.007)
    expect(surfaces["g_W_wall"  ][:heatloss]).to be_within(0.01).of(18.195)
    expect(surfaces["g_N_wall"  ][:heatloss]).to be_within(0.01).of(54.255)
    expect(surfaces["p_W2_floor"][:heatloss]).to be_within(0.01).of(13.729)

    surfaces.each do |id, surface|
      next unless surface.key?(:construction)
      next unless surface.key?(:index       )
      next unless surface.key?(:ltype       )
      next unless surface.key?(:r           )
      next unless surface.key?(:edges       )
      next unless surface.key?(:heatloss    )
      next unless surface[:heatloss].abs > TOL

      os_model.getSurfaces.each do |s|
        next unless id == s.nameString
        index           = surface[:index       ]
        current_c       = surface[:construction]
        c               = current_c.clone(os_model).to_LayeredConstruction.get
        m               = nil
        m               = TBD.derate(os_model, id, surface, c)          if index

        if m
          c.setLayer(index, m)
          c.setName("#{id} c tbd")
          s.setConstruction(c)

          if s.outsideBoundaryCondition.downcase == "surface"
            unless s.adjacentSurface.empty?
              adjacent = s.adjacentSurface.get
              nom      = adjacent.nameString
              default  = adjacent.isConstructionDefaulted == false

              if default && surfaces.key?(nom)
                current_cc = surfaces[nom][:construction]
                cc = current_cc.clone(os_model).to_LayeredConstruction.get

                cc.setLayer(surfaces[nom][:index], m)
                cc.setName("#{nom} c tbd")
                adjacent.setConstruction(cc)
              end
            end
          end
        end
      end
    end

    # testing
    floors.each do |id, floor|
      next unless floor.key?(:edges)

      os_model.getSurfaces.each do |s|
        next unless id == s.nameString
        expect(s.isConstructionDefaulted).to be(false)
        expect(/ tbd/i.match(s.construction.get.nameString)).to_not eq(nil)
      end
    end

    # testing
    ceilings.each do |id, ceiling|
      next unless ceiling.key?(:edges)

      os_model.getSurfaces.each do |s|
        next unless id == s.nameString
        expect(s.isConstructionDefaulted).to be(false)
        expect(/ tbd/i.match(s.construction.get.nameString)).to_not eq(nil)
      end
    end

    # testing
    walls.each do |id, wall|
      next unless wall.key?(:edges)

      os_model.getSurfaces.each do |s|
        next unless id == s.nameString
        expect(s.isConstructionDefaulted).to be(false)
        expect(/ tbd/i.match(s.construction.get.nameString)).to_not eq(nil)
      end
    end
  end # can process thermal bridging and derating : LoScrigno

  it "can process DOE Prototype smalloffice.osm" do
    TBD.clean!
    argh = {}

    translator = OpenStudio::OSVersion::VersionTranslator.new
    file = File.join(__dir__, "files/osms/in/smalloffice.osm")
    path = OpenStudio::Path.new(file)
    os_model = translator.loadModel(path)
    expect(os_model.empty?).to be(false)
    os_model = os_model.get

    # Testing min/max cooling/heating setpoints
    setpoints = TBD.heatingTemperatureSetpoints?(os_model)
    setpoints = TBD.coolingTemperatureSetpoints?(os_model) || setpoints
    expect(setpoints).to be(true)
    airloops = TBD.airLoopsHVAC?(os_model)
    expect(airloops).to be(true)

    os_model.getSpaces.each do |space|
      expect(space.thermalZone.empty?).to be(false)
      zone = space.thermalZone.get
      heat_spt = TBD.maxHeatScheduledSetpoint(zone)
      cool_spt = TBD.minCoolScheduledSetpoint(zone)
      expect(heat_spt.key?(:spt)).to be(true)
      expect(cool_spt.key?(:spt)).to be(true)
      heating = heat_spt[:spt]
      cooling = cool_spt[:spt]

      if zone.nameString == "Attic ZN"
        expect(heating.nil?).to be(true)
        expect(cooling.nil?).to be(true)
        expect(zone.isPlenum).to be(false)
        expect(TBD.plenum?(space, airloops, setpoints)).to be(false)
        next
      end

      expect(TBD.plenum?(space, airloops, setpoints)).to be(false)
      expect(heating).to be_within(0.1).of(21.1)
      expect(cooling).to be_within(0.1).of(23.9)
    end

    # Tracking insulated ceiling surfaces below attic.
    os_model.getSurfaces.each do |s|
      next unless s.surfaceType == "RoofCeiling"
      next unless s.isConstructionDefaulted

      c = s.construction
      expect(c.empty?).to be(false)
      c = c.get.to_LayeredConstruction
      expect(c.empty?).to be(false)
      c = c.get
      id = c.nameString
      expect(id).to eq("Typical Wood Joist Attic Floor R-37.04 1")
      expect(c.layers.size).to eq(2)
      expect(c.layers[0].nameString).to eq("5/8 in. Gypsum Board")
      expect(c.layers[1].nameString).to eq("Typical Insulation R-35.4 1")
      # "5/8 in. Gypsum Board"        : RSi = 0,0994 m2.K/W
      # "Typical Insulation R-35.4 1" : RSi = 6,2348 m2.K/W
    end

    # Tracking outdoor-facing office walls.
    os_model.getSurfaces.each do |s|
      next unless s.surfaceType == "Wall"
      next unless s.outsideBoundaryCondition == "Outdoors"

      id = s.construction.get.nameString
      str = "Typical Insulated Wood Framed Exterior Wall R-11.24"
      expect(id.include?(str)).to be(true)
      c = s.construction
      expect(c.empty?).to be(false)
      c = c.get.to_LayeredConstruction
      expect(c.empty?).to be(false)
      c = c.get
      expect(c.layers.size).to eq(4)
      expect(c.layers[0].nameString).to eq("25mm Stucco")
      expect(c.layers[1].nameString).to eq("5/8 in. Gypsum Board")
      str2 = "Typical Insulation R-9.06 1"
      expect(c.layers[2].nameString.include?(str2)).to be(true)
      expect(c.layers[3].nameString).to eq("5/8 in. Gypsum Board")
      # "25mm Stucco"                 : RSi = 0,0353 m2.K/W
      # "5/8 in. Gypsum Board"        : RSi = 0,0994 m2.K/W
      # "Perimeter_ZN_1_wall_south Typical Insulation R-9.06 1"
      #                               : RSi = 0,5947 m2.K/W
      # "Perimeter_ZN_2_wall_east Typical Insulation R-9.06 1"
      #                               : RSi = 0,6270 m2.K/W
      # "Perimeter_ZN_3_wall_north Typical Insulation R-9.06 1"
      #                               : RSi = 0,6346 m2.K/W
      # "Perimeter_ZN_4_wall_west Typical Insulation R-9.06 1"
      #                               : RSi = 0,6270 m2.K/W
    end

    argh[:option] = "poor (BETBG)"
    json = TBD.process(os_model, argh)
    expect(json.is_a?(Hash)).to be(true)
    expect(json.key?(:io)).to be(true)
    expect(json.key?(:surfaces)).to be(true)
    io       = json[:io]
    surfaces = json[:surfaces]
    expect(TBD.status).to eq(0)
    expect(TBD.logs.empty?).to be(true)
    expect(io.nil?).to be(false)
    expect(io.is_a?(Hash)).to be(true)
    expect(io.empty?).to be(false)
    expect(surfaces.nil?).to be(false)
    expect(surfaces.is_a?(Hash)).to be(true)
    expect(surfaces.size).to eq(43)
    expect(io[:edges].size).to eq(105)

    surfaces.each do |id, surface|
      expect(surface.key?(:conditioned)).to be(true)
      next unless surface[:conditioned]

      expect(surface.key?(:heating)).to be(true)
      expect(surface.key?(:cooling)).to be(true)

      # Testing glass door detection
      if surface.key?(:doors)
        surface[:doors].each do |i, door|
          expect(door.key?(:glazed)).to be(true)
          expect(door[:glazed]).to be(true)
          expect(door.key?(:u)).to be(true)
          expect(door[:u]).to be_a(Numeric)
          expect(door[:u]).to be_within(0.01).of(6.40)
        end
      end
    end

    # Testing attic surfaces.
    surfaces.each do |id, surface|
      expect(surface.key?(:space)).to be(true)
      next unless surface[:space].nameString == "Attic"

      # Attic is an UNENCLOSED zone - outdoor-facing surfaces are not derated.
      expect(surface.key?(:conditioned)).to be(true)
      expect(surface[:conditioned]).to be(false)
      expect(surface.key?(:heatloss)).to be(false)
      expect(surface.key?(:ratio)).to be(false)

      # Attic floor surfaces adjacent to ceiling surfaces below (CONDITIONED
      # office spaces) share derated constructions (although inverted).
      expect(surface.key?(:boundary)).to be(true)
      b = surface[:boundary]
      next if b.downcase == "outdoors"

      # TBD/Topolys should be tracking the adjacent CONDITIONED surface.
      expect(surfaces.key?(b)).to be(true)
      expect(surfaces[b].key?(:conditioned)).to be(true)
      expect(surfaces[b][:conditioned]).to be(true)

      if id == "Attic_floor_core"
        expect(surfaces[b].key?(:heatloss)).to be(true)
        expect(surfaces[b][:heatloss]).to be_within(0.01).of(0.00)
        expect(surfaces[b].key?(:ratio)).to be(false)
      end

      next if id == "Attic_floor_core"

      expect(surfaces[b].key?(:heatloss)).to be(true)
      expect(surfaces[b].key?(:ratio)).to be(true)
      h = surfaces[b][:heatloss]
      expect(h).to be_within(0.01).of(20.11) if id.include?("north")
      expect(h).to be_within(0.01).of(20.22) if id.include?("south")
      expect(h).to be_within(0.01).of(13.42) if id.include?("west")
      expect(h).to be_within(0.01).of(13.42) if id.include?("east")

      # Derated constructions?
      s = os_model.getSurfaceByName(id)
      expect(s.empty?).to be(false)
      s = s.get
      expect(s.nameString).to eq(id)
      expect(s.surfaceType).to eq("Floor")

      # In the small office OSM, attic floor constructions are not set by
      # the attic default construction set. They are instead set for the
      # adjacent ceilings below (building default construction set). So
      # attic floor surfaces automatically inherit derated constructions.
      expect(s.isConstructionDefaulted).to be(true)
      c = s.construction.get.to_LayeredConstruction
      expect(c.empty?).to be(false)
      c = c.get
      expect(c.nameString.include?("c tbd")).to be(true)
      expect(c.layers.size).to eq(2)
      expect(c.layers[0].nameString).to eq("5/8 in. Gypsum Board")
      expect(c.layers[1].nameString.include?("m tbd")).to be(true)

      # Comparing derating ratios of constructions.
      expect(c.layers[1].to_MasslessOpaqueMaterial.empty?).to be(false)
      m = c.layers[1].to_MasslessOpaqueMaterial.get

      # Before derating.
      initial_R = s.filmResistance
      initial_R += 0.0994
      initial_R += 6.2348

      # After derating.
      derated_R = s.filmResistance
      derated_R += 0.0994
      derated_R += m.thermalResistance

      ratio = -(initial_R - derated_R) * 100 / initial_R
      expect(ratio).to be_within(1).of(surfaces[b][:ratio])
      # "5/8 in. Gypsum Board"        : RSi = 0,0994 m2.K/W
      # "Typical Insulation R-35.4 1" : RSi = 6,2348 m2.K/W
    end

    surfaces.each do |id, surface|
      next unless surface.key?(:edges)

      expect(surface.key?(:heatloss)).to be(true)

      if id == "Core_ZN_ceiling"
        expect(surface[:heatloss]).to be_within(0.001).of(0)
        expect(surface.key?(:ratio)).to be(false)
        expect(surface.key?(:u)).to be(true)
        expect(surface[:u]).to be_within(0.001).of(0.153)
        next
      end

      expect(surface.key?(:ratio)).to be(true)
      h = surface[:heatloss]

      s = os_model.getSurfaceByName(id)
      expect(s.empty?).to be(false)
      s = s.get
      expect(s.nameString).to eq(id)
      expect(s.isConstructionDefaulted).to be(false)
      expect(/ tbd/i.match(s.construction.get.nameString)).to_not eq(nil)

      # Testing outdoor-facing walls.
      next unless s.surfaceType == "Wall"

      expect(h).to be_within(0.01).of(51.17) if id.include?("_1_") # South
      expect(h).to be_within(0.01).of(33.08) if id.include?("_2_") # East
      expect(h).to be_within(0.01).of(48.32) if id.include?("_3_") # North
      expect(h).to be_within(0.01).of(33.08) if id.include?("_4_") # West

      c = s.construction
      expect(c.empty?).to be(false)
      c = c.get.to_LayeredConstruction
      expect(c.empty?).to be(false)
      c = c.get
      expect(c.layers.size).to eq(4)
      expect(c.layers[2].nameString.include?("m tbd")).to be(true)

      next unless id.include?("_1_") # South

      l_fenestration = 0
      l_head         = 0
      l_sill         = 0
      l_jamb         = 0
      l_grade        = 0
      l_parapet      = 0
      l_corner       = 0

      surface[:edges].values.each do |edge|
        l_fenestration += edge[:length] if edge[:type] == :fenestration
        l_head         += edge[:length] if edge[:type] == :head
        l_sill         += edge[:length] if edge[:type] == :sill
        l_jamb         += edge[:length] if edge[:type] == :jamb
        l_grade        += edge[:length] if edge[:type] == :grade
        l_grade        += edge[:length] if edge[:type] == :gradeconcave
        l_grade        += edge[:length] if edge[:type] == :gradeconvex
        l_parapet      += edge[:length] if edge[:type] == :parapet
        l_parapet      += edge[:length] if edge[:type] == :parapetconcave
        l_parapet      += edge[:length] if edge[:type] == :parapetconvex
        l_corner       += edge[:length] if edge[:type] == :cornerconcave
        l_corner       += edge[:length] if edge[:type] == :cornerconvex
      end

      expect(l_fenestration).to be_within(0.01).of(0)
      expect(l_head).to         be_within(0.01).of(12.81)
      expect(l_sill).to         be_within(0.01).of(10.98)
      expect(l_jamb).to         be_within(0.01).of(22.56)
      expect(l_grade).to        be_within(0.01).of(27.69)
      expect(l_parapet).to      be_within(0.01).of(27.69)
      expect(l_corner).to       be_within(0.01).of(6.1)
    end
  end

  it "can process DOE prototype smalloffice.osm (hardset)" do
    TBD.clean!
    argh = {}

    translator = OpenStudio::OSVersion::VersionTranslator.new
    file = File.join(__dir__, "files/osms/in/smalloffice.osm")
    path = OpenStudio::Path.new(file)
    os_model = translator.loadModel(path)
    expect(os_model.empty?).to be(false)
    os_model = os_model.get

    # In the preceding test, attic floor surfaces inherit constructions from
    # adjacent office ceiling surfaces below. In this variant, attic floors
    # adjacent to NSEW perimeter office ceilings have hardset constructions
    # assigned to them (inverted). Results should remain the same as above.
    os_model.getSurfaces.each do |s|
      expect(s.space.empty?).to be(false)
      next unless s.space.get.nameString == "Attic"
      next unless s.nameString.include?("_perimeter")
      expect(s.surfaceType).to eq("Floor")
      expect(s.isConstructionDefaulted).to be(true)
      c = s.construction.get.to_LayeredConstruction
      expect(c.empty?).to be(false)
      c = c.get
      expect(c.layers.size).to eq(2)
      # layer[0]: "5/8 in. Gypsum Board"
      # layer[1]: "Typical Insulation R-35.4 1"

      construction = c.clone(os_model).to_LayeredConstruction.get
      expect(construction.handle.to_s.empty?).to be(false)
      expect(construction.nameString.empty?).to be(false)
      str = "Typical Wood Joist Attic Floor R-37.04 2"
      expect(construction.nameString).to eq(str)
      construction.setName("#{s.nameString} floor")
      expect(construction.layers.size).to eq(2)
      expect(s.setConstruction(construction)).to be(true)
      expect(s.isConstructionDefaulted).to be(false)
    end

    argh[:option] = "poor (BETBG)"
    json = TBD.process(os_model, argh)
    expect(json.is_a?(Hash)).to be(true)
    expect(json.key?(:io)).to be(true)
    expect(json.key?(:surfaces)).to be(true)
    io       = json[:io]
    surfaces = json[:surfaces]
    expect(TBD.status).to eq(0)
    expect(TBD.logs.empty?).to be(true)
    expect(io.nil?).to be(false)
    expect(io.is_a?(Hash)).to be(true)
    expect(io.empty?).to be(false)
    expect(surfaces.nil?).to be(false)
    expect(surfaces.is_a?(Hash)).to be(true)
    expect(surfaces.size).to eq(43)
    expect(io[:edges].size).to eq(105)

    # Testing attic surfaces.
    surfaces.each do |id, surface|
      expect(surface.key?(:space)).to be(true)
      next unless surface[:space].nameString == "Attic"

      # Attic is an UNENCLOSED zone - outdoor-facing surfaces are not derated.
      expect(surface.key?(:conditioned)).to be(true)
      expect(surface[:conditioned]).to be(false)
      expect(surface.key?(:heatloss)).to be(false)
      expect(surface.key?(:ratio)).to be(false)

      expect(surface.key?(:boundary)).to be(true)
      b = surface[:boundary]
      next if b == "Outdoors"
      expect(surfaces.key?(b)).to be(true)
      expect(surfaces[b].key?(:conditioned)).to be(true)
      expect(surfaces[b][:conditioned]).to be(true)

      next if id == "Attic_floor_core"
      expect(surfaces[b].key?(:heatloss)).to be(true)
      expect(surfaces[b].key?(:ratio)).to be(true)
      h = surfaces[b][:heatloss]

      # Derated constructions?
      s = os_model.getSurfaceByName(id)
      expect(s.empty?).to be(false)
      s = s.get
      expect(s.nameString).to eq(id)
      expect(s.surfaceType).to eq("Floor")
      expect(s.isConstructionDefaulted).to be(false)
      c = s.construction.get.to_LayeredConstruction
      expect(c.empty?).to be(false)
      c = c.get
      next unless c.nameString == "Attic_floor_perimeter_south floor"
      expect(c.nameString.include?("c tbd")).to be(true)
      expect(c.layers.size).to eq(2)
      expect(c.layers[0].nameString).to eq("5/8 in. Gypsum Board")
      expect(c.layers[1].nameString.include?("m tbd")).to be(true)

      expect(c.layers[1].to_MasslessOpaqueMaterial.empty?).to be(false)
      m = c.layers[1].to_MasslessOpaqueMaterial.get

      # Before derating.
      initial_R = s.filmResistance
      initial_R += 0.0994
      initial_R += 6.2348

      # After derating.
      derated_R = s.filmResistance
      derated_R += 0.0994
      derated_R += m.thermalResistance

      ratio = -(initial_R - derated_R) * 100 / initial_R
      expect(ratio).to be_within(1).of(surfaces[b][:ratio])
      # "5/8 in. Gypsum Board"        : RSi = 0,0994 m2.K/W
      # "Typical Insulation R-35.4 1" : RSi = 6,2348 m2.K/W

      surfaces.each do |id, surface|
        next unless surface.key?(:edges)
        expect(surface.key?(:heatloss)).to be(true)
        expect(surface.key?(:ratio)).to be(true)
        h = surface[:heatloss]

        s = os_model.getSurfaceByName(id)
        expect(s.empty?).to be(false)
        s = s.get
        expect(s.nameString).to eq(id)
        expect(s.isConstructionDefaulted).to be(false)
        expect(/ tbd/i.match(s.construction.get.nameString)).to_not eq(nil)

        # Testing outdoor-facing walls.
        next unless s.surfaceType == "Wall"
        expect(h).to be_within(0.01).of(51.17) if id.include?("_1_") # South
        expect(h).to be_within(0.01).of(33.08) if id.include?("_2_") # East
        expect(h).to be_within(0.01).of(48.32) if id.include?("_3_") # North
        expect(h).to be_within(0.01).of(33.08) if id.include?("_4_") # West

        c = s.construction
        expect(c.empty?).to be(false)
        c = c.get.to_LayeredConstruction
        expect(c.empty?).to be(false)
        c = c.get
        expect(c.layers.size).to eq(4)
        expect(c.layers[2].nameString.include?("m tbd")).to be(true)

        next unless id.include?("_1_") # South
        l_fenestration = 0
        l_head         = 0
        l_sill         = 0
        l_jamb         = 0
        l_grade        = 0
        l_parapet      = 0
        l_corner       = 0

        surface[:edges].values.each do |edge|
          l_fenestration += edge[:length] if edge[:type] == :fenestration
          l_head         += edge[:length] if edge[:type] == :head
          l_sill         += edge[:length] if edge[:type] == :sill
          l_jamb         += edge[:length] if edge[:type] == :jamb
          l_grade        += edge[:length] if edge[:type] == :grade
          l_grade        += edge[:length] if edge[:type] == :gradeconcave
          l_grade        += edge[:length] if edge[:type] == :gradeconvex
          l_parapet      += edge[:length] if edge[:type] == :parapet
          l_parapet      += edge[:length] if edge[:type] == :parapetconcave
          l_parapet      += edge[:length] if edge[:type] == :parapetconvex
          l_corner       += edge[:length] if edge[:type] == :cornerconcave
          l_corner       += edge[:length] if edge[:type] == :cornerconvex
        end

        expect(l_fenestration).to be_within(0.01).of(0)
        expect(l_head).to         be_within(0.01).of(46.35)
        expect(l_sill).to         be_within(0.01).of(46.35)
        expect(l_jamb).to         be_within(0.01).of(46.35)
        expect(l_grade).to        be_within(0.01).of(27.69)
        expect(l_parapet).to      be_within(0.01).of(27.69)
        expect(l_corner).to       be_within(0.01).of(6.1)
      end
    end
  end

  it "can process cases with low temperature radiant heating" do
    TBD.clean!
    argh = {}

    model = OpenStudio::Model::Model.new
    version = model.getVersion.versionIdentifier.split('.').map(&:to_i)
    v = version.join.to_i

    unless v < 330
      translator = OpenStudio::OSVersion::VersionTranslator.new
      file = File.join(__dir__, "files/osms/in/smalloffice_IHS.osm")
      path = OpenStudio::Path.new(file)
      os_model = translator.loadModel(path)
      expect(os_model.empty?).to be(false)
      os_model = os_model.get

      setpoints = TBD.heatingTemperatureSetpoints?(os_model)
      setpoints = TBD.coolingTemperatureSetpoints?(os_model) || setpoints
      expect(setpoints).to be(true)
      airloops = TBD.airLoopsHVAC?(os_model)
      expect(airloops).to be(true)

      os_model.getSpaces.each do |space|
        expect(space.thermalZone.empty?).to be(false)
        zone = space.thermalZone.get
        heat_spt = TBD.maxHeatScheduledSetpoint(zone)
        cool_spt = TBD.minCoolScheduledSetpoint(zone)
        expect(heat_spt.key?(:spt)).to be(true)
        expect(cool_spt.key?(:spt)).to be(true)
        heating = heat_spt[:spt]
        cooling = cool_spt[:spt]

        if zone.nameString == "Attic ZN"
          expect(TBD.plenum?(space, airloops, setpoints)).to be(false)
          expect(heating.nil?).to be(true)
          expect(cooling.nil?).to be(true)
        else
          expect(TBD.plenum?(space, airloops, setpoints)).to be(false)
          # TBD will rely on scheduled setpoint temperatures of radiant systems
          # IN ABSENCE of valid thermal zone thermostat scheduled setpoints.
          expect(heating).to be_within(0.1).of(21.1)    # overrides 22.5 lowTrad
          expect(cooling).to be_within(0.1).of(23.9)
        end
      end

      argh[:option] = "(non thermal bridging)"
      json = TBD.process(os_model, argh)
      expect(json.is_a?(Hash)).to be(true)
      expect(json.key?(:io)).to be(true)
      expect(json.key?(:surfaces)).to be(true)
      io       = json[:io]
      surfaces = json[:surfaces]
      expect(TBD.status).to eq(0)
      expect(TBD.logs.empty?).to be(true)
      expect(io.nil?).to be(false)
      expect(io.is_a?(Hash)).to be(true)
      expect(io.empty?).to be(false)
      expect(surfaces.nil?).to be(false)
      expect(surfaces.is_a?(Hash)).to be(true)
      expect(surfaces.size).to eq(43)
      expect(io[:edges].size).to eq(105)

      # Again, yet with a OS:Schedule:FixedInterval.
      TBD.clean!
      argh = {}

      translator = OpenStudio::OSVersion::VersionTranslator.new
      file = File.join(__dir__, "files/osms/in/warehouse_IHS_pks.osm")
      path = OpenStudio::Path.new(file)
      os_model = translator.loadModel(path)
      expect(os_model.empty?).to be(false)
      os_model = os_model.get

      setpoints = TBD.heatingTemperatureSetpoints?(os_model)
      setpoints = TBD.coolingTemperatureSetpoints?(os_model) || setpoints
      expect(setpoints).to be(true)
      airloops = TBD.airLoopsHVAC?(os_model)
      expect(airloops).to be(true)

      os_model.getSpaces.each do |space|
        expect(space.thermalZone.empty?).to be(false)
        zone = space.thermalZone.get
        heat_spt = TBD.maxHeatScheduledSetpoint(zone)
        cool_spt = TBD.minCoolScheduledSetpoint(zone)
        expect(heat_spt.key?(:spt)).to be(true)
        expect(cool_spt.key?(:spt)).to be(true)
        heating = heat_spt[:spt]
        cooling = cool_spt[:spt]
        office = zone.nameString.include?("Office")
        fine   = zone.nameString.include?("Fine")
        bulk   = zone.nameString.include?("Bulk")
        expect(TBD.plenum?(space, airloops, setpoints)).to be(false)
        expect(heating).to be_within(0.1).of(21.1) if office
        expect(heating).to be_within(0.1).of(15.6) if fine
        expect(heating).to be_within(0.1).of(10.0) if bulk
        expect(cooling).to be_within(0.1).of(23.9) if office
        expect(cooling).to be_within(0.1).of(26.7) if fine
        expect(cooling).to be_within(0.1).of(50.0) if bulk
      end

      argh[:option] = "(non thermal bridging)"
      json = TBD.process(os_model, argh)
      expect(json.is_a?(Hash)).to be(true)
      expect(json.key?(:io)).to be(true)
      expect(json.key?(:surfaces)).to be(true)
      io       = json[:io]
      surfaces = json[:surfaces]
      expect(TBD.status).to eq(0)
      expect(TBD.logs.empty?).to be(true)
      expect(io.nil?).to be(false)
      expect(io.is_a?(Hash)).to be(true)
      expect(io.empty?).to be(false)
      expect(surfaces.nil?).to be(false)
      expect(surfaces.is_a?(Hash)).to be(true)
      expect(surfaces.size).to eq(23)
      expect(io.key?(:edges))
      expect(io[:edges].size).to eq(300)
    end
  end

  it "can process DOE Prototype warehouse.osm" do
    TBD.clean!
    argh = {}

    translator = OpenStudio::OSVersion::VersionTranslator.new
    file = File.join(__dir__, "files/osms/in/warehouse.osm")
    path = OpenStudio::Path.new(file)
    os_model = translator.loadModel(path)
    expect(os_model.empty?).to be(false)
    os_model = os_model.get

    os_model.getSurfaces.each do |s|
      next unless s.outsideBoundaryCondition == "Outdoors"
      expect(s.space.empty?).to be(false)
      expect(s.isConstructionDefaulted).to be(true)
      c = s.construction
      expect(c.empty?).to be(false)
      c = c.get.to_LayeredConstruction
      expect(c.empty?).to be(false)
      c = c.get
      id = c.nameString
      name = s.nameString
      expect(c.layers[1].to_MasslessOpaqueMaterial.empty?).to be(false)
      m = c.layers[1].to_MasslessOpaqueMaterial.get
      r = m.thermalResistance
      if name.include?("Bulk")
        expect(r).to be_within(0.01).of(1.33) if id.include?("Wall")
        expect(r).to be_within(0.01).of(1.68) if id.include?("Roof")
      else
        expect(r).to be_within(0.01).of(1.87) if id.include?("Wall")
        expect(r).to be_within(0.01).of(3.06) if id.include?("Roof")
      end
    end

    argh[:option] = "poor (BETBG)"
    json = TBD.process(os_model, argh)
    expect(json.is_a?(Hash)).to be(true)
    expect(json.key?(:io)).to be(true)
    expect(json.key?(:surfaces)).to be(true)
    io       = json[:io]
    surfaces = json[:surfaces]
    expect(TBD.status).to eq(0)
    expect(TBD.logs.empty?).to be(true)
    expect(io.nil?).to be(false)
    expect(io.is_a?(Hash)).to be(true)
    expect(io.empty?).to be(false)
    expect(surfaces.nil?).to be(false)
    expect(surfaces.is_a?(Hash)).to be(true)
    expect(surfaces.size).to eq(23)
    expect(io.key?(:edges))
    expect(io[:edges].size).to eq(300)

    ids = { a: "Office Front Wall",
            b: "Office Left Wall",
            c: "Fine Storage Roof",
            d: "Fine Storage Office Front Wall",
            e: "Fine Storage Office Left Wall",
            f: "Fine Storage Front Wall",
            g: "Fine Storage Left Wall",
            h: "Fine Storage Right Wall",
            i: "Bulk Storage Roof",
            j: "Bulk Storage Rear Wall",
            k: "Bulk Storage Left Wall",
            l: "Bulk Storage Right Wall" }.freeze

    # Testing.
    surfaces.each do |id, surface|
      next if surface.key?(:edges)
      expect(ids.has_value?(id)).to be(false)
    end

    surfaces.each do |id, surface|
      next unless surface.key?(:edges)
      expect(ids.has_value?(id)).to be(true)
      expect(surface.key?(:heatloss)).to be(true)
      expect(surface.key?(:ratio)).to be(true)
      h = surface[:heatloss]

      s = os_model.getSurfaceByName(id)
      expect(s.empty?).to be(false)
      s = s.get
      expect(s.nameString).to eq(id)
      expect(s.isConstructionDefaulted).to be(false)
      expect(/ tbd/i.match(s.construction.get.nameString)).to_not eq(nil)
      expect(h).to be_within(0.01).of( 50.20) if id == ids[:a]
      expect(h).to be_within(0.01).of( 24.06) if id == ids[:b]
      expect(h).to be_within(0.01).of( 87.16) if id == ids[:c]
      expect(h).to be_within(0.01).of( 22.61) if id == ids[:d]
      expect(h).to be_within(0.01).of(  9.15) if id == ids[:e]
      expect(h).to be_within(0.01).of( 26.47) if id == ids[:f]
      expect(h).to be_within(0.01).of( 27.19) if id == ids[:g]
      expect(h).to be_within(0.01).of( 41.36) if id == ids[:h]
      expect(h).to be_within(0.01).of(161.02) if id == ids[:i]
      expect(h).to be_within(0.01).of( 62.28) if id == ids[:j]
      expect(h).to be_within(0.01).of(117.87) if id == ids[:k]
      expect(h).to be_within(0.01).of( 95.77) if id == ids[:l]

      c = s.construction
      expect(c.empty?).to be(false)
      c = c.get.to_LayeredConstruction
      expect(c.empty?).to be(false)
      c = c.get
      expect(c.layers[1].nameString.include?("m tbd")).to be(true)
    end

    surfaces.each do |id, surface|
      if surface.key?(:ratio)
        # ratio  = format "%3.1f", surface[:ratio]
        # name   = id.rjust(15, " ")
        # puts "#{name} RSi derated by #{ratio}%"
        expect(surface[:ratio]).to be_within(0.2).of(-53.0) if id == ids[:b]
        expect(surface[:ratio]).to be_within(0.2).of(-15.6) if id == ids[:c]
        expect(surface[:ratio]).to be_within(0.2).of(- 7.3) if id == ids[:i]
      else
        expect(surface[:boundary].downcase).to_not eq("outdoors")
      end
    end
  end

  it "can process DOE Prototype warehouse.osm + JSON I/O" do
    TBD.clean!
    argh = {}

    translator = OpenStudio::OSVersion::VersionTranslator.new
    file = File.join(__dir__, "files/osms/in/warehouse.osm")
    path = OpenStudio::Path.new(file)
    os_model = translator.loadModel(path)
    expect(os_model.empty?).to be(false)
    os_model = os_model.get

    # 1. run the measure with a basic TBD JSON input file, e.g. :
    #    - a custom PSI set, e.g. "compliant" set
    #    - (4x) custom edges, e.g. "bad" :fenestration perimeters between
    #      - "Office Left Wall Window1" & "Office Left Wall"

    # The TBD JSON input file should hold the following:
    # "edges": [
    #  {
    #    "psi": "bad",
    #    "type": "fenestration",
    #    "surfaces": [
    #      "Office Left Wall Window1",
    #      "Office Left Wall"
    #    ]
    #  }
    # ],

    # Despite defining the PSI set as having no thermal bridges, the "compliant"
    # PSI set on file will be considered as the building-wide default set.
    argh[:option] = "(non thermal bridging)"
    argh[:io_path] = File.join(__dir__, "../json/tbd_warehouse.json")
    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")
    json = TBD.process(os_model, argh)
    expect(json.is_a?(Hash)).to be(true)
    expect(json.key?(:io)).to be(true)
    expect(json.key?(:surfaces)).to be(true)
    io       = json[:io]
    surfaces = json[:surfaces]
    expect(TBD.status).to eq(0)
    expect(TBD.logs.empty?).to be(true)
    expect(io.nil?).to be(false)
    expect(io.is_a?(Hash)).to be(true)
    expect(io.empty?).to be(false)
    expect(surfaces.nil?).to be(false)
    expect(surfaces.is_a?(Hash)).to be(true)
    expect(surfaces.size).to eq(23)

    ids = { a: "Office Front Wall",
            b: "Office Left Wall",
            c: "Fine Storage Roof",
            d: "Fine Storage Office Front Wall",
            e: "Fine Storage Office Left Wall",
            f: "Fine Storage Front Wall",
            g: "Fine Storage Left Wall",
            h: "Fine Storage Right Wall",
            i: "Bulk Storage Roof",
            j: "Bulk Storage Rear Wall",
            k: "Bulk Storage Left Wall",
            l: "Bulk Storage Right Wall" }.freeze

    # Testing.
    surfaces.each do |id, surface|
      next if surface.key?(:edges)
      expect(ids.has_value?(id)).to be(false)
    end

    surfaces.each do |id, surface|
      next unless surface.key?(:edges)
      expect(ids.has_value?(id)).to be(true)
      expect(surface.key?(:heatloss)).to be(true)
      expect(surface.key?(:ratio)).to be(true)
      h = surface[:heatloss]

      s = os_model.getSurfaceByName(id)
      expect(s.empty?).to be(false)
      s = s.get
      expect(s.nameString).to eq(id)
      expect(s.isConstructionDefaulted).to be(false)
      expect(/ tbd/i.match(s.construction.get.nameString)).to_not eq(nil)
      expect(h).to be_within(0.01).of( 25.90) if id == ids[:a]
      expect(h).to be_within(0.01).of( 17.41) if id == ids[:b] # 13.38 compliant
      expect(h).to be_within(0.01).of( 45.44) if id == ids[:c]
      expect(h).to be_within(0.01).of(  8.04) if id == ids[:d]
      expect(h).to be_within(0.01).of(  3.46) if id == ids[:e]
      expect(h).to be_within(0.01).of( 13.27) if id == ids[:f]
      expect(h).to be_within(0.01).of( 14.04) if id == ids[:g]
      expect(h).to be_within(0.01).of( 21.20) if id == ids[:h]
      expect(h).to be_within(0.01).of( 88.34) if id == ids[:i]
      expect(h).to be_within(0.01).of( 30.98) if id == ids[:j]
      expect(h).to be_within(0.01).of( 64.44) if id == ids[:k]
      expect(h).to be_within(0.01).of( 48.97) if id == ids[:l]

      c = s.construction
      expect(c.empty?).to be(false)
      c = c.get.to_LayeredConstruction
      expect(c.empty?).to be(false)
      c = c.get
      expect(c.layers[1].nameString.include?("m tbd")).to be(true)
    end

    surfaces.each do |id, surface|
      if surface.key?(:ratio)
        # ratio  = format "%3.1f", surface[:ratio]
        # name   = id.rjust(15, " ")
        # puts "#{name} RSi derated by #{ratio}%"
        expect(surface[:ratio]).to be_within(0.2).of(-46.0) if id == ids[:b]
      else
        expect(surface[:boundary].downcase).to_not eq("outdoors")
      end
    end

    # Now mimic the export functionality of the measure.
    out = JSON.pretty_generate(io)
    outP = File.join(__dir__, "../json/tbd_warehouse.out.json")
    File.open(outP, "w") { |outP| outP.puts out }

    # 2. Re-use the exported file as input for another warehouse.
    os_model2 = translator.loadModel(path)
    expect(os_model2.empty?).to be(false)
    os_model2 = os_model2.get

    argh[:io_path] = File.join(__dir__, "../json/tbd_warehouse.out.json")
    json2 = TBD.process(os_model2, argh)
    expect(json2.is_a?(Hash)).to be(true)
    expect(json2.key?(:io)).to be(true)
    expect(json2.key?(:surfaces)).to be(true)
    io2      = json2[:io]
    surfaces = json2[:surfaces]
    expect(TBD.status).to eq(0)
    expect(TBD.logs.empty?).to be(true)
    expect(io.nil?).to be(false)
    expect(io.is_a?(Hash)).to be(true)
    expect(io.empty?).to be(false)
    expect(surfaces.nil?).to be(false)
    expect(surfaces.is_a?(Hash)).to be(true)
    expect(surfaces.size).to eq(23)

    # Testing (again).
    surfaces.each do |id, surface|
      next unless surface.key?(:edges)
      expect(surface.key?(:heatloss)).to be(true)
      expect(surface.key?(:ratio)).to be(true)
      h = surface[:heatloss]

      s = os_model.getSurfaceByName(id)
      expect(s.empty?).to be(false)
      s = s.get
      expect(s.nameString).to eq(id)
      expect(s.isConstructionDefaulted).to be(false)
      expect(/ tbd/i.match(s.construction.get.nameString)).to_not eq(nil)
      expect(h).to be_within(0.01).of( 25.90) if id == ids[:a]
      expect(h).to be_within(0.01).of( 17.41) if id == ids[:b]
      expect(h).to be_within(0.01).of( 45.44) if id == ids[:c]
      expect(h).to be_within(0.01).of(  8.04) if id == ids[:d]
      expect(h).to be_within(0.01).of(  3.46) if id == ids[:e]
      expect(h).to be_within(0.01).of( 13.27) if id == ids[:f]
      expect(h).to be_within(0.01).of( 14.04) if id == ids[:g]
      expect(h).to be_within(0.01).of( 21.20) if id == ids[:h]
      expect(h).to be_within(0.01).of( 88.34) if id == ids[:i]
      expect(h).to be_within(0.01).of( 30.98) if id == ids[:j]
      expect(h).to be_within(0.01).of( 64.44) if id == ids[:k]
      expect(h).to be_within(0.01).of( 48.97) if id == ids[:l]

      c = s.construction
      expect(c.empty?).to be(false)
      c = c.get.to_LayeredConstruction
      expect(c.empty?).to be(false)
      c = c.get
      expect(c.layers[1].nameString.include?("m tbd")).to be(true)
    end

    surfaces.each do |id, surface|
      if surface.key?(:ratio)
        # ratio  = format "%3.1f", surface[:ratio]
        # name   = id.rjust(15, " ")
        # puts "#{name} RSi derated by #{ratio}%"
        expect(surface[:ratio]).to be_within(0.2).of(-46.0) if id == ids[:b]
      else
        expect(surface[:boundary].downcase).to_not eq("outdoors")
      end
    end

    # Now mimic (again) the export functionality of the measure
    out2 = JSON.pretty_generate(io2)
    outP2 = File.join(__dir__, "../json/tbd_warehouse2.out.json")
    File.open(outP2, "w") { |outP2| outP2.puts out2 }

    # Both output files should be the same ...
    # cmd = "diff #{outP} #{outP2}"
    # expect(system( cmd )).to be(true)
    # expect(FileUtils).to be_identical(outP, outP2)
    expect(FileUtils.identical?(outP, outP2)).to be(true)
  end

  it "can process DOE Prototype warehouse.osm + JSON I/O (2)" do
    TBD.clean!
    argh = {}

    translator = OpenStudio::OSVersion::VersionTranslator.new
    file = File.join(__dir__, "files/osms/in/warehouse.osm")
    path = OpenStudio::Path.new(file)
    os_model = translator.loadModel(path)
    expect(os_model.empty?).to be(false)
    os_model = os_model.get

    # 1. run the measure with a basic TBD JSON input file, e.g. :
    #    - a custom PSI set, e.g. "compliant" set
    #    - (1x) custom edges, e.g. "bad" :fenestration perimeters between
    #      - "Office Left Wall Window1" & "Office Left Wall"
    #      - 1x? this time, with explicit 3D coordinates for shared edge.

    # The TBD JSON input file should hold the following:
    # "edges": [
    #  {
    #    "psi": "bad",
    #    "type": "fenestration",
    #    "surfaces": [
    #      "Office Left Wall Window1",
    #      "Office Left Wall"
    #    ],
    #    "v0x": 0.0,
    #    "v0y": 7.51904930207155,
    #    "v0z": 0.914355407629293,
    #    "v1x": 0.0,
    #    "v1y": 5.38555335093654,
    #    "v1z": 0.914355407629293
    #   }
    # ],

    # Despite defining the PSI set as having no thermal bridges, the "compliant"
    # PSI set on file will be considered as the building-wide default set.
    argh[:option] = "(non thermal bridging)"
    argh[:io_path] = File.join(__dir__, "../json/tbd_warehouse1.json")
    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")
    json = TBD.process(os_model, argh)
    expect(json.is_a?(Hash)).to be(true)
    expect(json.key?(:io)).to be(true)
    expect(json.key?(:surfaces)).to be(true)
    io       = json[:io]
    surfaces = json[:surfaces]
    expect(TBD.status).to eq(0)
    expect(TBD.logs.empty?).to be(true)
    expect(io.nil?).to be(false)
    expect(io.is_a?(Hash)).to be(true)
    expect(io.empty?).to be(false)
    expect(surfaces.nil?).to be(false)
    expect(surfaces.is_a?(Hash)).to be(true)
    expect(surfaces.size).to eq(23)

    ids = { a: "Office Front Wall",
            b: "Office Left Wall",
            c: "Fine Storage Roof",
            d: "Fine Storage Office Front Wall",
            e: "Fine Storage Office Left Wall",
            f: "Fine Storage Front Wall",
            g: "Fine Storage Left Wall",
            h: "Fine Storage Right Wall",
            i: "Bulk Storage Roof",
            j: "Bulk Storage Rear Wall",
            k: "Bulk Storage Left Wall",
            l: "Bulk Storage Right Wall" }.freeze

    # Testing.
    surfaces.each do |id, surface|
      next if surface.key?(:edges)
      expect(ids.has_value?(id)).to be(false)
    end

    surfaces.each do |id, surface|
      next unless surface.key?(:edges)
      expect(ids.has_value?(id)).to be(true)
      expect(surface.key?(:heatloss)).to be(true)
      expect(surface.key?(:ratio)).to be(true)
      h = surface[:heatloss]

      s = os_model.getSurfaceByName(id)
      expect(s.empty?).to be(false)
      s = s.get
      expect(s.nameString).to eq(id)
      expect(s.isConstructionDefaulted).to be(false)
      expect(/ tbd/i.match(s.construction.get.nameString)).to_not eq(nil)
      expect(h).to be_within(0.01).of( 25.90) if id == ids[:a]
      expect(h).to be_within(0.01).of( 14.55) if id == ids[:b] # 13.38 compliant
      expect(h).to be_within(0.01).of( 45.44) if id == ids[:c]
      expect(h).to be_within(0.01).of(  8.04) if id == ids[:d]
      expect(h).to be_within(0.01).of(  3.46) if id == ids[:e]
      expect(h).to be_within(0.01).of( 13.27) if id == ids[:f]
      expect(h).to be_within(0.01).of( 14.04) if id == ids[:g]
      expect(h).to be_within(0.01).of( 21.20) if id == ids[:h]
      expect(h).to be_within(0.01).of( 88.34) if id == ids[:i]
      expect(h).to be_within(0.01).of( 30.98) if id == ids[:j]
      expect(h).to be_within(0.01).of( 64.44) if id == ids[:k]
      expect(h).to be_within(0.01).of( 48.97) if id == ids[:l]

      c = s.construction
      expect(c.empty?).to be(false)
      c = c.get.to_LayeredConstruction
      expect(c.empty?).to be(false)
      c = c.get
      expect(c.layers[1].nameString.include?("m tbd")).to be(true)
    end

    surfaces.each do |id, surface|
      if surface.key?(:ratio)
        # ratio  = format "%3.1f", surface[:ratio]
        # name   = id.rjust(15, " ")
        # puts "#{name} RSi derated by #{ratio}%"
        expect(surface[:ratio]).to be_within(0.2).of(-41.9) if id == ids[:b]
      else
        expect(surface[:boundary].downcase).to_not eq("outdoors")
      end
    end

    # Now mimic the export functionality of the measure
    out = JSON.pretty_generate(io)
    outP = File.join(__dir__, "../json/tbd_warehouse1.out.json")
    File.open(outP, "w") { |outP| outP.puts out }

    # 2. Re-use the exported file as input for another warehouse
    os_model2 = translator.loadModel(path)
    expect(os_model2.empty?).to be(false)
    os_model2 = os_model2.get

    argh[:io_path] = File.join(__dir__, "../json/tbd_warehouse1.out.json")
    json2 = TBD.process(os_model2, argh)
    expect(json2.is_a?(Hash)).to be(true)
    expect(json2.key?(:io)).to be(true)
    expect(json2.key?(:surfaces)).to be(true)
    io2      = json2[:io]
    surfaces = json2[:surfaces]
    expect(TBD.status).to eq(0)
    expect(TBD.logs.empty?).to be(true)
    expect(io.nil?).to be(false)
    expect(io.is_a?(Hash)).to be(true)
    expect(io.empty?).to be(false)
    expect(surfaces.nil?).to be(false)
    expect(surfaces.is_a?(Hash)).to be(true)
    expect(surfaces.size).to eq(23)

    surfaces.each do |id, surface|
      if surface.key?(:ratio)
        # ratio  = format "%3.1f", surface[:ratio]
        # name   = id.rjust(15, " ")
        # puts "#{name} RSi derated by #{ratio}%"
        expect(surface[:ratio]).to be_within(0.2).of(-41.9) if id == ids[:b]
      else
        expect(surface[:boundary].downcase).to_not eq("outdoors")
      end
    end

    # Now mimic (again) the export functionality of the measure
    out2 = JSON.pretty_generate(io2)
    outP2 = File.join(__dir__, "../json/tbd_warehouse3.out.json")
    File.open(outP2, "w") { |outP2| outP2.puts out2 }

    # Both output files should be the same ...
    # cmd = "diff #{outP} #{outP2}"
    # expect(system( cmd )).to be(true)
    # expect(FileUtils).to be_identical(outP, outP2)
    expect(FileUtils.identical?(outP, outP2)).to be(true)
  end

  it "can factor in spacetype-specific PSI sets (JSON input)" do
    TBD.clean!
    argh = {}

    translator = OpenStudio::OSVersion::VersionTranslator.new
    file = File.join(__dir__, "files/osms/in/warehouse.osm")
    path = OpenStudio::Path.new(file)
    os_model = translator.loadModel(path)
    expect(os_model.empty?).to be(false)
    os_model = os_model.get

    argh[:option] = "compliant"        # superseded by :building PSI set on file
    argh[:io_path] = File.join(__dir__, "../json/tbd_warehouse5.json")
    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")
    json = TBD.process(os_model, argh)
    expect(json.is_a?(Hash)).to be(true)
    expect(json.key?(:io)).to be(true)
    expect(json.key?(:surfaces)).to be(true)
    io       = json[:io]
    surfaces = json[:surfaces]
    puts TBD.logs
    expect(TBD.status).to eq(0)
    expect(TBD.logs.empty?).to be(true)
    expect(io.nil?).to be(false)
    expect(io.is_a?(Hash)).to be(true)
    expect(io.empty?).to be(false)
    expect(surfaces.nil?).to be(false)
    expect(surfaces.is_a?(Hash)).to be(true)
    expect(surfaces.size).to eq(23)

    sTyp1 = "Warehouse Office"
    sTyp2 = "Warehouse Fine"

    expect(io.key?(:spacetypes)).to be(true)
    io[:spacetypes].each do |spacetype|
      expect(spacetype.key?(:id)).to be(true)
      expect(spacetype[:id]).to eq(sTyp1).or eq(sTyp2)
      expect(spacetype.key?(:psi)).to be(true)
    end

    surfaces.each do |id, surface|
      next unless surface[:boundary].downcase == "outdoors"
      next unless surface.key?(:ratio)
      expect(surface.key?(:heatloss)).to be(true)
      heatloss = surface[:heatloss]
      expect(heatloss.abs).to be > 0
      expect(surface.key?(:space)).to be(true)
      next unless surface[:space].nameString == "Zone1 Office"

      # All applicable thermal bridges/edges derating the office walls inherit
      # the "Warehouse Office" spacetype PSI values (JSON file), except for the
      # shared :rimjoist with the Fine Storage space above. The "Warehouse Fine"
      # spacetype set has a higher :rimjoist PSI value of 0.5 W/K per metre,
      # which overrides the "Warehouse Office" value of 0.3 W/K per metre.
      name = "Office Left Wall"
      expect(heatloss).to be_within(0.01).of(11.61) if id == name
      name = "Office Front Wall"
      expect(heatloss).to be_within(0.01).of(22.94) if id == name
    end
  end

  it "can sort multiple story-specific PSI sets (JSON input)" do
    TBD.clean!
    argh = {}

    translator = OpenStudio::OSVersion::VersionTranslator.new
    file = File.join(__dir__, "files/osms/in/midrise_KIVA.osm")
    path = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model.empty?).to be(false)
    model = model.get

    # Testing min/max cooling/heating setpoints.
    setpoints = TBD.heatingTemperatureSetpoints?(model)
    setpoints = TBD.coolingTemperatureSetpoints?(model) || setpoints
    expect(setpoints).to be(true)
    airloops = TBD.airLoopsHVAC?(model)
    expect(airloops).to be(true)

    model.getSpaces.each do |space|
      expect(space.thermalZone.empty?).to be(false)
      zone = space.thermalZone.get
      heat_spt = TBD.maxHeatScheduledSetpoint(zone)
      cool_spt = TBD.minCoolScheduledSetpoint(zone)
      expect(heat_spt.key?(:spt)).to be(true)
      expect(cool_spt.key?(:spt)).to be(true)
      heating = heat_spt[:spt]
      cooling = cool_spt[:spt]
      expect(TBD.plenum?(space, airloops, setpoints)).to be(false)

      if zone.nameString == "Office ZN"
        expect(heating).to be_within(0.1).of(21.1)
        expect(cooling).to be_within(0.1).of(23.9)
      else
        expect(heating).to be_within(0.1).of(21.7)
        expect(cooling).to be_within(0.1).of(24.4)
      end
    end

    argh[:option     ] = "(non thermal bridging)"                   # overridden
    argh[:io_path    ] = File.join(__dir__, "../json/midrise.json")
    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")
    json = TBD.process(model, argh)
    expect(json.is_a?(Hash)).to be(true)
    expect(json.key?(:io)).to be(true)
    expect(json.key?(:surfaces)).to be(true)
    io       = json[:io]
    surfaces = json[:surfaces]
    expect(TBD.status).to eq(0)
    expect(TBD.logs.empty?).to be(true)
    expect(io.nil?).to be(false)
    expect(io.is_a?(Hash)).to be(true)
    expect(io.empty?).to be(false)
    expect(surfaces.nil?).to be(false)
    expect(surfaces.is_a?(Hash)).to be(true)
    expect(surfaces.size).to eq(180)

    surfaces.each do |id, surface|
      expect(surface.key?(:conditioned)).to be(true)
      next unless surface[:conditioned]

      expect(surface.key?(:heating)).to be(true)
      expect(surface.key?(:cooling)).to be(true)
    end

    # A side test. Validating that TBD doesn't tag shared edge between exterior
    # wall and interior ceiling (adiabatic conditions) as 'party' for
    # 'multiplied' mid-level spaces. In fact, there shouldn't be a single
    # instance of a 'party' edge in the TBD model.
    surfaces.each do |id, surface|
      # next unless id.include?("m ")
      # next unless id.include?("Wall ")
      next unless surface.key?(:ratio)
      expect(surface.key?(:edges)).to be(true)

      surface[:edges].values.each do |edge|
        expect(edge.key?(:type)).to be(true)
        expect(edge[:type]).to_not eq(:party)
      end
    end

    st1 = "Building Story 1"
    st2 = "Building Story 2"
    st3 = "Building Story 3"

    expect(io.key?(:stories)).to be(true)
    expect(io[:stories].size).to eq(3)

    io[:stories].each do |story|
      expect(story.key?(:id)).to be(true)
      expect(story[:id]).to eq(st1).or eq(st2).or eq(st3)
      expect(story.key?(:psi)).to be(true)
    end

    counter = 0

    surfaces.each do |id, surface|
      next unless surface.key?(:ratio)
      expect(surface.key?(:boundary)).to be(true)
      expect(surface[:boundary]).to eq("Outdoors")
      expect(surface.key?(:story)).to be(true)
      nom = surface[:story].nameString
      expect(nom).to eq(st1).or eq(st2).or eq(st3)
      expect(nom).to eq(st1) if id.include?("g ")
      expect(nom).to eq(st2) if id.include?("m ")
      expect(nom).to eq(st3) if id.include?("t ")
      expect(surface.key?(:edges)).to be(true)
      counter += 1

      # Illustrating that story-specific PSI set is used when only 1x story.
      surface[:edges].values.each do |edge|
        expect(edge.key?(:type)).to be(true)
        expect(edge.key?(:psi)).to be(true)
        next unless id.include?("Roof")
        expect(edge[:type]).to eq(:parapetconvex).or eq(:transition)
        next unless edge[:type] == :parapetconvex
        next if id == "t Roof C"
        expect(edge[:psi]).to be_within(0.01).of(0.178) # 57.3% of 0.311
      end

      # Illustrating that story-specific PSI set is used when only 1x story.
      surface[:edges].values.each do |edge|
        next unless id.include?("t ")
        next unless id.include?("Wall ")
        next unless edge[:type] == :parapetconvex
        next if id.include?(" C")
        expect(edge[:psi]).to be_within(0.01).of(0.133) # 42.7% of 0.311
      end

      # The shared :rimjoist between middle story and ground floor units could
      # either inherit the "Building Story 1" or "Building Story 2" :rimjoist
      # PSI values. TBD retains the most conductive PSI values in such cases.
      surface[:edges].values.each do |edge|
        next unless id.include?("m ")
        next unless id.include?("Wall ")
        next if id.include?(" C")
        next unless edge[:type] == :rimjoist

        # Inheriting "Building Story 1" :rimjoist PSI of 0.501 W/K per metre.
        # The SEA unit is above an office space below, which has curtain wall.
        # RSi of insulation layers (to derate):
        #   - office walls   : 0.740 m2.K/W (26.1%)
        #   - SEA walls      : 2.100 m2.K/W (73.9%)
        #
        #   - SEA walls      : 26.1% of 0.501 = 0.3702 W/K per metre
        #   - other walls    : 50.0% of 0.501 = 0.2505 W/K per metre
        if id == "m SWall SEA" || id == "m EWall SEA"
          expect(edge[:psi]).to be_within(0.002).of(0.3702)
        else
          expect(edge[:psi]).to be_within(0.002).of(0.2505)
        end
      end
    end
    expect(counter).to eq(51)
  end

  it "can process seb.osm" do
    TBD.clean!
    argh = {}

    translator = OpenStudio::OSVersion::VersionTranslator.new
    file = File.join(__dir__, "files/osms/in/seb.osm")
    path = OpenStudio::Path.new(file)
    os_model = translator.loadModel(path)
    expect(os_model.empty?).to be(false)
    os_model = os_model.get

    # Testing min/max cooling/heating setpoints (a tad redundant).
    setpoints = TBD.heatingTemperatureSetpoints?(os_model)
    setpoints = TBD.coolingTemperatureSetpoints?(os_model) || setpoints
    expect(setpoints).to be(true)
    airloops = TBD.airLoopsHVAC?(os_model)
    expect(airloops).to be(true)

    os_model.getSpaces.each do |space|
      expect(space.thermalZone.empty?).to be(false)
      zone = space.thermalZone.get
      heat_spt = TBD.maxHeatScheduledSetpoint(zone)
      cool_spt = TBD.minCoolScheduledSetpoint(zone)
      expect(heat_spt.key?(:spt)).to be(true)
      expect(cool_spt.key?(:spt)).to be(true)
      heating = heat_spt[:spt]
      cooling = cool_spt[:spt]

      if zone.nameString == "Level 0 Ceiling Plenum Zone"
        expect(TBD.plenum?(space, airloops, setpoints)).to be(false)
        expect(heating.nil?).to be(true)
        expect(cooling.nil?).to be(true)
        next
      end

      expect(TBD.plenum?(space, airloops, setpoints)).to be(false)
      expect(heating).to be_within(0.1).of(22.1)
      expect(cooling).to be_within(0.1).of(22.8)
    end

    os_model.getSurfaces.each do |s|
      expect(s.space.empty?).to be(false)
      expect(s.isConstructionDefaulted).to be(false)
      c = s.construction
      expect(c.empty?).to be(false)
      c = c.get.to_LayeredConstruction
      expect(c.empty?).to be(false)
      c = c.get
      id = c.nameString
      name = s.nameString

      if s.outsideBoundaryCondition == "Outdoors"
        expect(c.layers.size).to be(4)
        expect(c.layers[2].to_StandardOpaqueMaterial.empty?).to be(false)
        m = c.layers[2].to_StandardOpaqueMaterial.get
        r = m.thickness / m.thermalConductivity
        expect(r).to be_within(0.01).of(1.47) if s.surfaceType == "Wall"
        expect(r).to be_within(0.01).of(5.08) if s.surfaceType == "RoofCeiling"
      elsif s.outsideBoundaryCondition == "Surface"
        next unless s.surfaceType == "RoofCeiling"
        expect(c.layers.size).to be(1)
        expect(c.layers[0].to_StandardOpaqueMaterial.empty?).to be(false)
        m = c.layers[0].to_StandardOpaqueMaterial.get
        r = m.thickness / m.thermalConductivity
        expect(r).to be_within(0.01).of(0.12)
      end

      expect(s.space.empty?).to be(false)
      space = s.space.get
      nom = space.nameString
      expect(space.thermalZone.empty?).to be(false)
      zone = space.thermalZone.get
      heating_spt = TBD.maxHeatScheduledSetpoint(zone)
      expect(heating_spt.key?(:spt)).to be(true)
      t = heating_spt[:spt]
      expect(t).to be_within(0.1).of(22.1) unless nom.include?("Plenum")
      next unless nom.include?("Plenum")
      expect(t).to be(nil)
      expect(zone.isPlenum).to be(false)
      expect(zone.canBePlenum).to be(true)
      expect(s.surfaceType).to_not eq("Floor")                     # no floors !
      expect(s.surfaceType).to eq("Wall").or eq("RoofCeiling")
    end

    argh[:option] = "poor (BETBG)"
    json = TBD.process(os_model, argh)
    expect(json.is_a?(Hash)).to be(true)
    expect(json.key?(:io)).to be(true)
    expect(json.key?(:surfaces)).to be(true)
    io       = json[:io]
    surfaces = json[:surfaces]
    expect(TBD.status).to eq(0)
    expect(TBD.logs.empty?).to be(true)
    expect(io.nil?).to be(false)
    expect(io.is_a?(Hash)).to be(true)
    expect(io.empty?).to be(false)
    expect(surfaces.nil?).to be(false)
    expect(surfaces.is_a?(Hash)).to be(true)
    expect(surfaces.size).to eq(56)

    surfaces.each do |id, surface|
      expect(surface.key?(:conditioned)).to be(true)
      next unless surface[:conditioned]
      expect(surface.key?(:heating)).to be(true)
      expect(surface.key?(:cooling)).to be(true)
    end

    ids = { a: "Entryway  Wall 4",
            b: "Entryway  Wall 5",
            c: "Entryway  Wall 6",
            d: "Entry way  DroppedCeiling",
            e: "Utility1 Wall 1",
            f: "Utility1 Wall 5",
            g: "Utility 1 DroppedCeiling",
            h: "Smalloffice 1 Wall 1",
            i: "Smalloffice 1 Wall 2",
            j: "Smalloffice 1 Wall 6",
            k: "Small office 1 DroppedCeiling",
            l: "Openarea 1 Wall 3",
            m: "Openarea 1 Wall 4",
            n: "Openarea 1 Wall 5",
            o: "Openarea 1 Wall 6",
            p: "Openarea 1 Wall 7",
            q: "Open area 1 DroppedCeiling" }.freeze

    # If one simulates the seb.osm, EnergyPlus reports the plenum as an
    # UNCONDITIONED zone, so it's more akin (at least initially) to an attic:
    # it's vented (infiltration) and there's necessarily heat conduction with
    # the outdoors and with the zone below. But otherwise, it's a dead zone
    # (no heating/cooling, no setpoints, not detailed in the eplusout.bnd
    # file), etc. The zone is linked to a "Plenum" zonelist (in the IDF), relied
    # on only to set infiltration. What leads to some confusion is that the
    # outdoor-facing surfaces (roof & walls) of the "plenum" are insulated,
    # while the dropped ceiling separating the occupied zone below is simply
    # that, lightweight uninsulated ceiling tiles (a situation more evocative
    # of a true plenum). It may be indeed OK to model the plenum this way -
    # there will be plenty of heat transfer between the plenum and the zone
    # below due to the poor thermal resistance of the ceiling tiles. And if the
    # infiltration rates are low enough (unlike an attic), then simulation
    # results may end up being quite consistent with a true plenum. TBD will
    # nonethless end up tagging the SEB plenum as an UNCONDITIONED space, and
    # as a consequence will (partially) derate the uninsulated ceiling tiles.
    # Fortunately, TBD relies on a proportionate derating solution whereby the
    # insulated wall will be the main focus of the derating step.
    surfaces.each do |id, surface|
      next if surface.key?(:edges)
      expect(ids.has_value?(id)).to be(false)
    end

    surfaces.each do |id, surface|
      next unless surface.key?(:edges)
      expect(ids.has_value?(id)).to be(true)
      expect(surface.key?(:heatloss)).to be(true)
      expect(surface.key?(:ratio)).to be(true)
      h = surface[:heatloss]

      s = os_model.getSurfaceByName(id)
      expect(s.empty?).to be(false)
      s = s.get
      expect(s.nameString).to eq(id)
      expect(s.isConstructionDefaulted).to be(false)
      expect(/ tbd/i.match(s.construction.get.nameString)).to_not eq(nil)
      expect(h).to be_within(0.01).of( 6.43) if id == ids[:a]
      expect(h).to be_within(0.01).of(11.18) if id == ids[:b]
      expect(h).to be_within(0.01).of( 4.56) if id == ids[:c]
      expect(h).to be_within(0.01).of( 0.42) if id == ids[:d]
      expect(h).to be_within(0.01).of(12.66) if id == ids[:e]
      expect(h).to be_within(0.01).of(12.59) if id == ids[:f]
      expect(h).to be_within(0.01).of( 0.50) if id == ids[:g]
      expect(h).to be_within(0.01).of(14.06) if id == ids[:h]
      expect(h).to be_within(0.01).of( 9.04) if id == ids[:i]
      expect(h).to be_within(0.01).of( 8.75) if id == ids[:j]
      expect(h).to be_within(0.01).of( 0.53) if id == ids[:k]
      expect(h).to be_within(0.01).of( 5.06) if id == ids[:l]
      expect(h).to be_within(0.01).of( 6.25) if id == ids[:m]
      expect(h).to be_within(0.01).of( 9.04) if id == ids[:n]
      expect(h).to be_within(0.01).of( 6.74) if id == ids[:o]
      expect(h).to be_within(0.01).of( 4.32) if id == ids[:p]
      expect(h).to be_within(0.01).of( 0.76) if id == ids[:q]

      c = s.construction
      expect(c.empty?).to be(false)
      c = c.get.to_LayeredConstruction
      expect(c.empty?).to be(false)
      c = c.get
      i = 0
      i = 2 if s.outsideBoundaryCondition == "Outdoors"
      expect(c.layers[i].nameString.include?("m tbd")).to be(true)
    end

    surfaces.each do |id, surface|
      if surface.key?(:ratio)
        # ratio  = format "%3.1f", surface[:ratio]
        # name   = id.rjust(15, " ")
        # puts "#{name} RSi derated by #{ratio}%"
        expect(surface[:ratio]).to be_within(0.1).of(-36.74) if id == ids[:a]
        expect(surface[:ratio]).to be_within(0.1).of(-34.61) if id == ids[:b]
        expect(surface[:ratio]).to be_within(0.1).of(-33.57) if id == ids[:c]
        expect(surface[:ratio]).to be_within(0.1).of( -0.14) if id == ids[:d]
        expect(surface[:ratio]).to be_within(0.1).of(-35.09) if id == ids[:e]
        expect(surface[:ratio]).to be_within(0.1).of(-35.12) if id == ids[:f]
        expect(surface[:ratio]).to be_within(0.1).of( -0.13) if id == ids[:g]
        expect(surface[:ratio]).to be_within(0.1).of(-39.75) if id == ids[:h]
        expect(surface[:ratio]).to be_within(0.1).of(-39.74) if id == ids[:i]
        expect(surface[:ratio]).to be_within(0.1).of(-39.90) if id == ids[:j]
        expect(surface[:ratio]).to be_within(0.1).of( -0.13) if id == ids[:k]
        expect(surface[:ratio]).to be_within(0.1).of(-27.78) if id == ids[:l]
        expect(surface[:ratio]).to be_within(0.1).of(-31.66) if id == ids[:m]
        expect(surface[:ratio]).to be_within(0.1).of(-28.44) if id == ids[:n]
        expect(surface[:ratio]).to be_within(0.1).of(-30.85) if id == ids[:o]
        expect(surface[:ratio]).to be_within(0.1).of(-28.78) if id == ids[:p]
        expect(surface[:ratio]).to be_within(0.1).of( -0.09) if id == ids[:q]

        next unless id == ids[:a]
        s = os_model.getSurfaceByName(id)
        expect(s.empty?).to be(false)
        s = s.get
        expect(s.nameString).to eq(id)
        expect(s.surfaceType).to eq("Wall")
        expect(s.isConstructionDefaulted).to be(false)
        c = s.construction.get.to_LayeredConstruction
        expect(c.empty?).to be(false)
        c = c.get
        expect(c.nameString.include?("c tbd")).to be(true)
        expect(c.layers.size).to eq(4)
        expect(c.layers[2].nameString.include?("m tbd")).to be(true)
        expect(c.layers[2].to_StandardOpaqueMaterial.empty?).to be(false)
        m = c.layers[2].to_StandardOpaqueMaterial.get

        initial_R = s.filmResistance + 2.4674
        derated_R = s.filmResistance + 0.9931
        derated_R += m.thickness / m.thermalConductivity

        ratio = -(initial_R - derated_R) * 100 / initial_R
        expect(ratio).to be_within(1).of(surfaces[id][:ratio])
      else
        if surface[:boundary].downcase == "outdoors"
          expect(surface[:conditioned]).to be(false)
        end
      end
    end
  end

  it "can take in custom (expansion) joints as thermal bridges" do
    TBD.clean!
    argh = {}

    translator = OpenStudio::OSVersion::VersionTranslator.new
    file = File.join(__dir__, "files/osms/in/warehouse.osm")
    path = OpenStudio::Path.new(file)
    os_model = translator.loadModel(path)
    expect(os_model.empty?).to be(false)
    os_model = os_model.get

    # TBD will automatically tag as a (mild) "transition" any shared edge
    # between 2x linked walls that more or less share the same 3D plane. An
    # edge shared between 2x roof surfaces will equally be tagged as a
    # "transition" edge. By default, transition edges are set @0 W/K.m i.e., no
    # derating occurs. Although structural expansion joints or roof curbs are
    # not as commonly encountered as mild transitions, they do constitute
    # significant thermal bridges (to consider). As such "joints" remain
    # undistinguishable from transition edges when parsing OSM geometry, the
    # solution tested here illustrates how users can override default
    # "transition" tags via JSON input files.
    #
    # The "tbd_warehouse6.json" file identifies 2x edges in the US DOE
    # warehouse prototype building that TBD tags as (mild) transitions by
    # default. Both edges concern the "Fine Storage" space (likely as a means
    # to ensure surface convexity in the EnergyPlus model). The "ok" PSI set
    # holds a single "joint" PSI value of 0.9 W/K per metre (let's assume both
    # edges are significant expansion joints, rather than modelling artifacts).
    # Each "expansion joint" here represents 4.27 m x 0.9 W/K per m = 3.84 W/K.
    # As wall constructions are the same for all 4x walls concerned, each wall
    # inherits 1/2 of the extra heat loss from each joint i.e., 1.92 W/K.
    #
    #   "psis": [
    #     {
    #       "id": "ok",
    #       "joint": 0.9
    #     }
    #   ],
    #   "edges": [
    #     {
    #       "psi": "ok",
    #       "type": "joint",
    #       "surfaces": [
    #         "Fine Storage Front Wall",
    #         "Fine Storage Office Front Wall"
    #       ]
    #     },
    #     {
    #       "psi": "ok",
    #       "type": "joint",
    #       "surfaces": [
    #         "Fine Storage Left Wall",
    #         "Fine Storage Office Left Wall"
    #       ]
    #     }
    #   ]
    # }

    argh[:option] = "poor (BETBG)"
    argh[:io_path] = File.join(__dir__, "../json/tbd_warehouse6.json")
    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")
    json = TBD.process(os_model, argh)
    expect(json.is_a?(Hash)).to be(true)
    expect(json.key?(:io)).to be(true)
    expect(json.key?(:surfaces)).to be(true)
    io       = json[:io]
    surfaces = json[:surfaces]
    expect(TBD.status).to eq(0)
    expect(TBD.logs.empty?).to be(true)
    expect(io.nil?).to be(false)
    expect(io.is_a?(Hash)).to be(true)
    expect(io.empty?).to be(false)
    expect(surfaces.nil?).to be(false)
    expect(surfaces.is_a?(Hash)).to be(true)
    expect(surfaces.size).to eq(23)

    ids = { a: "Office Front Wall",
            b: "Office Left Wall",
            c: "Fine Storage Roof",
            d: "Fine Storage Office Front Wall",
            e: "Fine Storage Office Left Wall",
            f: "Fine Storage Front Wall",
            g: "Fine Storage Left Wall",
            h: "Fine Storage Right Wall",
            i: "Bulk Storage Roof",
            j: "Bulk Storage Rear Wall",
            k: "Bulk Storage Left Wall",
            l: "Bulk Storage Right Wall" }.freeze

    # Testing.
    surfaces.each do |id, surface|
      next if surface.key?(:edges)
      expect(ids.has_value?(id)).to be(false)
    end

    surfaces.each do |id, surface|
      next unless surface.key?(:edges)
      expect(ids.has_value?(id)).to be(true)
      expect(surface.key?(:heatloss)).to be(true)
      expect(surface.key?(:ratio)).to be(true)
      h = surface[:heatloss]

      s = os_model.getSurfaceByName(id)
      expect(s.empty?).to be(false)
      s = s.get
      expect(s.nameString).to eq(id)
      expect(s.isConstructionDefaulted).to be(false)
      expect(/ tbd/i.match(s.construction.get.nameString)).to_not eq(nil)
      expect(h).to be_within(0.01).of( 50.20) if id == ids[:a]
      expect(h).to be_within(0.01).of( 24.06) if id == ids[:b]
      expect(h).to be_within(0.01).of( 87.16) if id == ids[:c]
      expect(h).to be_within(0.01).of( 24.53) if id == ids[:d] # 22.61 + 1.92
      expect(h).to be_within(0.01).of( 11.07) if id == ids[:e] #  9.15 + 1.92
      expect(h).to be_within(0.01).of( 28.39) if id == ids[:f] # 26.47 + 1.92
      expect(h).to be_within(0.01).of( 29.11) if id == ids[:g] # 27.19 + 1.92
      expect(h).to be_within(0.01).of( 41.36) if id == ids[:h]
      expect(h).to be_within(0.01).of(161.02) if id == ids[:i]
      expect(h).to be_within(0.01).of( 62.28) if id == ids[:j]
      expect(h).to be_within(0.01).of(117.87) if id == ids[:k]
      expect(h).to be_within(0.01).of( 95.77) if id == ids[:l]

      c = s.construction
      expect(c.empty?).to be(false)
      c = c.get.to_LayeredConstruction
      expect(c.empty?).to be(false)
      c = c.get
      expect(c.layers[1].nameString.include?("m tbd")).to be(true)
    end

    surfaces.each do |id, surface|
      if surface.key?(:ratio)
        # ratio  = format "%3.1f", surface[:ratio]
        # name   = id.rjust(15, " ")
        # puts "#{name} RSi derated by #{ratio}%"
        expect(surface[:ratio]).to be_within(0.2).of(-44.13) if id == ids[:a]
        expect(surface[:ratio]).to be_within(0.2).of(-53.02) if id == ids[:b]
        expect(surface[:ratio]).to be_within(0.2).of(-15.60) if id == ids[:c]
        expect(surface[:ratio]).to be_within(0.2).of(-26.10) if id == ids[:d]
        expect(surface[:ratio]).to be_within(0.2).of(-30.86) if id == ids[:e]
        expect(surface[:ratio]).to be_within(0.2).of(-21.26) if id == ids[:f]
        expect(surface[:ratio]).to be_within(0.2).of(-20.65) if id == ids[:g]
        expect(surface[:ratio]).to be_within(0.2).of(-20.51) if id == ids[:h]
        expect(surface[:ratio]).to be_within(0.2).of( -7.29) if id == ids[:i]
        expect(surface[:ratio]).to be_within(0.2).of(-14.93) if id == ids[:j]
        expect(surface[:ratio]).to be_within(0.2).of(-19.02) if id == ids[:k]
        expect(surface[:ratio]).to be_within(0.2).of(-15.09) if id == ids[:l]
      else
        expect(surface[:boundary].downcase).to_not eq("outdoors")
      end
    end
  end

  it "can process seb.osm (0 W/K per m)" do
    TBD.clean!
    argh = {}

    translator = OpenStudio::OSVersion::VersionTranslator.new
    file = File.join(__dir__, "files/osms/in/seb.osm")
    path = OpenStudio::Path.new(file)
    os_model = translator.loadModel(path)
    expect(os_model.empty?).to be(false)
    os_model = os_model.get

    argh[:option] = "(non thermal bridging)"
    json = TBD.process(os_model, argh)
    expect(json.is_a?(Hash)).to be(true)
    expect(json.key?(:io)).to be(true)
    expect(json.key?(:surfaces)).to be(true)
    io       = json[:io]
    surfaces = json[:surfaces]
    expect(TBD.status).to eq(0)
    expect(TBD.logs.empty?).to be(true)
    expect(io.nil?).to be(false)
    expect(io.is_a?(Hash)).to be(true)
    expect(io.empty?).to be(false)
    expect(surfaces.nil?).to be(false)
    expect(surfaces.is_a?(Hash)).to be(true)
    expect(surfaces.size).to eq(56)

    surfaces.each do |id, surface|
      expect(surface.key?(:conditioned)).to be(true)
      next unless surface[:conditioned]
      expect(surface.key?(:heating)).to be(true)
      expect(surface.key?(:cooling)).to be(true)
    end

    # Since all PSI values = 0, we're not expecting any derated surfaces
    surfaces.values.each do |surface|
      expect(surface.key?(:ratio)).to be(false)
    end
  end

  it "can process seb.osm (0 W/K per m) with JSON" do
    TBD.clean!
    argh = {}

    translator = OpenStudio::OSVersion::VersionTranslator.new
    file = File.join(__dir__, "files/osms/in/seb.osm")
    path = OpenStudio::Path.new(file)
    os_model = translator.loadModel(path)
    expect(os_model.empty?).to be(false)
    os_model = os_model.get

    argh[:option] = "(non thermal bridging)"
    argh[:io_path] = File.join(__dir__, "../json/tbd_seb.json")
    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")
    json = TBD.process(os_model, argh)
    expect(json.is_a?(Hash)).to be(true)
    expect(json.key?(:io)).to be(true)
    expect(json.key?(:surfaces)).to be(true)
    io       = json[:io]
    surfaces = json[:surfaces]
    expect(TBD.status).to eq(0)
    expect(TBD.logs.empty?).to be(true)
    expect(io.nil?).to be(false)
    expect(io.is_a?(Hash)).to be(true)
    expect(io.empty?).to be(false)
    expect(surfaces.nil?).to be(false)
    expect(surfaces.is_a?(Hash)).to be(true)
    expect(surfaces.size).to eq(56)

    # As the :building PSI set on file remains "(non thermal bridging)", one
    # should not expect differences in results, i.e. derating shouldn't occur.
    surfaces.values.each do |surface|
      expect(surface.key?(:ratio)).to be(false)
    end
  end

  it "can process seb.osm (0 W/K per m) with JSON (non-0)" do
    TBD.clean!
    argh = {}

    translator = OpenStudio::OSVersion::VersionTranslator.new
    file = File.join(__dir__, "files/osms/in/seb.osm")
    path = OpenStudio::Path.new(file)
    os_model = translator.loadModel(path)
    expect(os_model.empty?).to be(false)
    os_model = os_model.get

    argh[:option] = "(non thermal bridging)"
    argh[:io_path] = File.join(__dir__, "../json/tbd_seb_n0.json")
    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")
    json = TBD.process(os_model, argh)
    expect(json.is_a?(Hash)).to be(true)
    expect(json.key?(:io)).to be(true)
    expect(json.key?(:surfaces)).to be(true)
    io       = json[:io]
    surfaces = json[:surfaces]
    expect(TBD.status).to eq(0)
    expect(TBD.logs.empty?).to be(true)
    expect(io.nil?).to be(false)
    expect(io.is_a?(Hash)).to be(true)
    expect(io.empty?).to be(false)
    expect(surfaces.nil?).to be(false)
    expect(surfaces.is_a?(Hash)).to be(true)
    expect(surfaces.size).to eq(56)

    ids = { a: "Entryway  Wall 4",
            b: "Entryway  Wall 5",
            c: "Entryway  Wall 6",
            d: "Entry way  DroppedCeiling",
            e: "Utility1 Wall 1",
            f: "Utility1 Wall 5",
            g: "Utility 1 DroppedCeiling",
            h: "Smalloffice 1 Wall 1",
            i: "Smalloffice 1 Wall 2",
            j: "Smalloffice 1 Wall 6",
            k: "Small office 1 DroppedCeiling",
            l: "Openarea 1 Wall 3",
            m: "Openarea 1 Wall 4",
            n: "Openarea 1 Wall 5",
            o: "Openarea 1 Wall 6",
            p: "Openarea 1 Wall 7",
            q: "Open area 1 DroppedCeiling" }.freeze

    # The :building PSI set on file "compliant" supersedes the argh[:option]
    # "(non thermal bridging)", so one should expect differences in results,
    # i.e. derating should occur. The next 2 tests:
    #   1. setting both argh[:option] & file :building to "compliant"
    #   2. setting argh[:option] to "compliant" + removing :building from file
    # ... all 3x cases should yield the same results.
    surfaces.each do |id, surface|
      next if surface.key?(:edges)
      expect(ids.has_value?(id)).to be(false)
    end

    surfaces.each do |id, surface|
      next unless surface.key?(:edges)
      expect(ids.has_value?(id)).to be(true)
      expect(surface.key?(:heatloss)).to be(true)
      expect(surface.key?(:ratio)).to be(true)
      h = surface[:heatloss]

      s = os_model.getSurfaceByName(id)
      expect(s.empty?).to be(false)
      s = s.get
      expect(s.nameString).to eq(id)
      expect(s.isConstructionDefaulted).to be(false)
      expect(/ tbd/i.match(s.construction.get.nameString)).to_not eq(nil)
      expect(h).to be_within(0.01).of( 3.62) if id == ids[:a]
      expect(h).to be_within(0.01).of( 6.28) if id == ids[:b]
      expect(h).to be_within(0.01).of( 2.62) if id == ids[:c]
      expect(h).to be_within(0.01).of( 0.17) if id == ids[:d]
      expect(h).to be_within(0.01).of( 7.13) if id == ids[:e]
      expect(h).to be_within(0.01).of( 7.09) if id == ids[:f]
      expect(h).to be_within(0.01).of( 0.20) if id == ids[:g]
      expect(h).to be_within(0.01).of( 7.94) if id == ids[:h]
      expect(h).to be_within(0.01).of( 5.17) if id == ids[:i]
      expect(h).to be_within(0.01).of( 5.01) if id == ids[:j]
      expect(h).to be_within(0.01).of( 0.22) if id == ids[:k]
      expect(h).to be_within(0.01).of( 2.47) if id == ids[:l]
      expect(h).to be_within(0.01).of( 3.11) if id == ids[:m]
      expect(h).to be_within(0.01).of( 4.43) if id == ids[:n]
      expect(h).to be_within(0.01).of( 3.35) if id == ids[:o]
      expect(h).to be_within(0.01).of( 2.12) if id == ids[:p]
      expect(h).to be_within(0.01).of( 0.31) if id == ids[:q]

      c = s.construction
      expect(c.empty?).to be(false)
      c = c.get.to_LayeredConstruction
      expect(c.empty?).to be(false)
      c = c.get
      i = 0
      i = 2 if s.outsideBoundaryCondition == "Outdoors"
      expect(c.layers[i].nameString.include?("m tbd")).to be(true)
    end

    surfaces.each do |id, surface|
      if surface.key?(:ratio)
        # ratio  = format "%3.1f", surface[:ratio]
        # name   = id.rjust(15, " ")
        # puts "#{name} RSi derated by #{ratio}%"
        expect(surface[:ratio]).to be_within(0.1).of(-28.93) if id == ids[:a]
        expect(surface[:ratio]).to be_within(0.1).of(-26.61) if id == ids[:b]
        expect(surface[:ratio]).to be_within(0.1).of(-25.82) if id == ids[:c]
        expect(surface[:ratio]).to be_within(0.1).of( -0.06) if id == ids[:d]
        expect(surface[:ratio]).to be_within(0.1).of(-27.14) if id == ids[:e]
        expect(surface[:ratio]).to be_within(0.1).of(-27.18) if id == ids[:f]
        expect(surface[:ratio]).to be_within(0.1).of( -0.05) if id == ids[:g]
        expect(surface[:ratio]).to be_within(0.1).of(-32.40) if id == ids[:h]
        expect(surface[:ratio]).to be_within(0.1).of(-32.58) if id == ids[:i]
        expect(surface[:ratio]).to be_within(0.1).of(-32.77) if id == ids[:j]
        expect(surface[:ratio]).to be_within(0.1).of( -0.05) if id == ids[:k]
        expect(surface[:ratio]).to be_within(0.1).of(-18.14) if id == ids[:l]
        expect(surface[:ratio]).to be_within(0.1).of(-21.97) if id == ids[:m]
        expect(surface[:ratio]).to be_within(0.1).of(-18.77) if id == ids[:n]
        expect(surface[:ratio]).to be_within(0.1).of(-21.14) if id == ids[:o]
        expect(surface[:ratio]).to be_within(0.1).of(-19.10) if id == ids[:p]
        expect(surface[:ratio]).to be_within(0.1).of( -0.04) if id == ids[:q]

        next unless id == ids[:a]
        s = os_model.getSurfaceByName(id)
        expect(s.empty?).to be(false)
        s = s.get
        expect(s.nameString).to eq(id)
        expect(s.surfaceType).to eq("Wall")
        expect(s.isConstructionDefaulted).to be(false)
        c = s.construction.get.to_LayeredConstruction
        expect(c.empty?).to be(false)
        c = c.get
        expect(c.nameString.include?("c tbd")).to be(true)
        expect(c.layers.size).to eq(4)
        expect(c.layers[2].nameString.include?("m tbd")).to be(true)
        expect(c.layers[2].to_StandardOpaqueMaterial.empty?).to be(false)
        m = c.layers[2].to_StandardOpaqueMaterial.get

        initial_R = s.filmResistance + 2.4674
        derated_R = s.filmResistance + 0.9931
        derated_R += m.thickness / m.thermalConductivity

        ratio = -(initial_R - derated_R) * 100 / initial_R
        expect(ratio).to be_within(1).of(surfaces[id][:ratio])
      else
        if surface[:boundary].downcase == "outdoors"
          expect(surface[:conditioned]).to be(false)
        end
      end
    end
  end

  it "can process seb.osm (0 W/K per m) with JSON (non-0) 2" do
    TBD.clean!
    argh = {}

    translator = OpenStudio::OSVersion::VersionTranslator.new
    file = File.join(__dir__, "files/osms/in/seb.osm")
    path = OpenStudio::Path.new(file)
    os_model = translator.loadModel(path)
    expect(os_model.empty?).to be(false)
    os_model = os_model.get

    # 1. setting both PSI option & file :building to "compliant"
    argh[:option] = "compliant" # instead of "(non thermal bridging)"
    argh[:io_path] = File.join(__dir__, "../json/tbd_seb_n0.json")
    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")
    json = TBD.process(os_model, argh)
    expect(json.is_a?(Hash)).to be(true)
    expect(json.key?(:io)).to be(true)
    expect(json.key?(:surfaces)).to be(true)
    io       = json[:io]
    surfaces = json[:surfaces]
    expect(TBD.status).to eq(0)
    expect(TBD.logs.empty?).to be(true)
    expect(io.nil?).to be(false)
    expect(io.is_a?(Hash)).to be(true)
    expect(io.empty?).to be(false)
    expect(surfaces.nil?).to be(false)
    expect(surfaces.is_a?(Hash)).to be(true)
    expect(surfaces.size).to eq(56)

    ids = { a: "Entryway  Wall 4",
            b: "Entryway  Wall 5",
            c: "Entryway  Wall 6",
            d: "Entry way  DroppedCeiling",
            e: "Utility1 Wall 1",
            f: "Utility1 Wall 5",
            g: "Utility 1 DroppedCeiling",
            h: "Smalloffice 1 Wall 1",
            i: "Smalloffice 1 Wall 2",
            j: "Smalloffice 1 Wall 6",
            k: "Small office 1 DroppedCeiling",
            l: "Openarea 1 Wall 3",
            m: "Openarea 1 Wall 4",
            n: "Openarea 1 Wall 5",
            o: "Openarea 1 Wall 6",
            p: "Openarea 1 Wall 7",
            q: "Open area 1 DroppedCeiling" }.freeze

    surfaces.each do |id, surface|
      next if surface.key?(:edges)
      expect(ids.has_value?(id)).to be(false)
    end

    surfaces.each do |id, surface|
      next unless surface.key?(:edges)
      expect(ids.has_value?(id)).to be(true)
      expect(surface.key?(:heatloss)).to be(true)
      expect(surface.key?(:ratio)).to be(true)
      h = surface[:heatloss]

      s = os_model.getSurfaceByName(id)
      expect(s.empty?).to be(false)
      s = s.get
      expect(s.nameString).to eq(id)
      expect(s.isConstructionDefaulted).to be(false)
      expect(/ tbd/i.match(s.construction.get.nameString)).to_not eq(nil)
      expect(h).to be_within(0.01).of( 3.62) if id == ids[:a]
      expect(h).to be_within(0.01).of( 6.28) if id == ids[:b]
      expect(h).to be_within(0.01).of( 2.62) if id == ids[:c]
      expect(h).to be_within(0.01).of( 0.17) if id == ids[:d]
      expect(h).to be_within(0.01).of( 7.13) if id == ids[:e]
      expect(h).to be_within(0.01).of( 7.09) if id == ids[:f]
      expect(h).to be_within(0.01).of( 0.20) if id == ids[:g]
      expect(h).to be_within(0.01).of( 7.94) if id == ids[:h]
      expect(h).to be_within(0.01).of( 5.17) if id == ids[:i]
      expect(h).to be_within(0.01).of( 5.01) if id == ids[:j]
      expect(h).to be_within(0.01).of( 0.22) if id == ids[:k]
      expect(h).to be_within(0.01).of( 2.47) if id == ids[:l]
      expect(h).to be_within(0.01).of( 3.11) if id == ids[:m]
      expect(h).to be_within(0.01).of( 4.43) if id == ids[:n]
      expect(h).to be_within(0.01).of( 3.35) if id == ids[:o]
      expect(h).to be_within(0.01).of( 2.12) if id == ids[:p]
      expect(h).to be_within(0.01).of( 0.31) if id == ids[:q]

      c = s.construction
      expect(c.empty?).to be(false)
      c = c.get.to_LayeredConstruction
      expect(c.empty?).to be(false)
      c = c.get
      i = 0
      i = 2 if s.outsideBoundaryCondition == "Outdoors"
      expect(c.layers[i].nameString.include?("m tbd")).to be(true)
    end

    surfaces.each do |id, surface|
      if surface.key?(:ratio)
        # ratio  = format "%3.1f", surface[:ratio]
        # name   = id.rjust(15, " ")
        # puts "#{name} RSi derated by #{ratio}%"
        expect(surface[:ratio]).to be_within(0.1).of(-28.93) if id == ids[:a]
        expect(surface[:ratio]).to be_within(0.1).of(-26.61) if id == ids[:b]
        expect(surface[:ratio]).to be_within(0.1).of(-25.82) if id == ids[:c]
        expect(surface[:ratio]).to be_within(0.1).of( -0.06) if id == ids[:d]
        expect(surface[:ratio]).to be_within(0.1).of(-27.14) if id == ids[:e]
        expect(surface[:ratio]).to be_within(0.1).of(-27.18) if id == ids[:f]
        expect(surface[:ratio]).to be_within(0.1).of( -0.05) if id == ids[:g]
        expect(surface[:ratio]).to be_within(0.1).of(-32.40) if id == ids[:h]
        expect(surface[:ratio]).to be_within(0.1).of(-32.58) if id == ids[:i]
        expect(surface[:ratio]).to be_within(0.1).of(-32.77) if id == ids[:j]
        expect(surface[:ratio]).to be_within(0.1).of( -0.05) if id == ids[:k]
        expect(surface[:ratio]).to be_within(0.1).of(-18.14) if id == ids[:l]
        expect(surface[:ratio]).to be_within(0.1).of(-21.97) if id == ids[:m]
        expect(surface[:ratio]).to be_within(0.1).of(-18.77) if id == ids[:n]
        expect(surface[:ratio]).to be_within(0.1).of(-21.14) if id == ids[:o]
        expect(surface[:ratio]).to be_within(0.1).of(-19.10) if id == ids[:p]
        expect(surface[:ratio]).to be_within(0.1).of( -0.04) if id == ids[:q]

        next unless id == ids[:a]
        s = os_model.getSurfaceByName(id)
        expect(s.empty?).to be(false)
        s = s.get
        expect(s.nameString).to eq(id)
        expect(s.surfaceType).to eq("Wall")
        expect(s.isConstructionDefaulted).to be(false)
        c = s.construction.get.to_LayeredConstruction
        expect(c.empty?).to be(false)
        c = c.get
        expect(c.nameString.include?("c tbd")).to be(true)
        expect(c.layers.size).to eq(4)
        expect(c.layers[2].nameString.include?("m tbd")).to be(true)
        expect(c.layers[2].to_StandardOpaqueMaterial.empty?).to be(false)
        m = c.layers[2].to_StandardOpaqueMaterial.get

        initial_R = s.filmResistance + 2.4674
        derated_R = s.filmResistance + 0.9931
        derated_R += m.thickness / m.thermalConductivity

        ratio = -(initial_R - derated_R) * 100 / initial_R
        expect(ratio).to be_within(1).of(surfaces[id][:ratio])
      else
        if surface[:boundary].downcase == "outdoors"
          expect(surface[:conditioned]).to be(false)
        end
      end
    end
  end

  it "can process seb.osm (0 W/K per m) with JSON (non-0) 3" do
    TBD.clean!
    argh = {}

    translator = OpenStudio::OSVersion::VersionTranslator.new
    file = File.join(__dir__, "files/osms/in/seb.osm")
    path = OpenStudio::Path.new(file)
    os_model = translator.loadModel(path)
    expect(os_model.empty?).to be(false)
    os_model = os_model.get

    # 2. setting PSI set to "compliant" while removing the :building from file
    argh[:option] = "compliant" # instead of "(non thermal bridging)"
    argh[:io_path] = File.join(__dir__, "../json/tbd_seb_n1.json")
    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")
    json = TBD.process(os_model, argh)
    expect(json.is_a?(Hash)).to be(true)
    expect(json.key?(:io)).to be(true)
    expect(json.key?(:surfaces)).to be(true)
    io       = json[:io]
    surfaces = json[:surfaces]
    expect(TBD.status).to eq(0)
    expect(TBD.logs.empty?).to be(true)
    expect(io.nil?).to be(false)
    expect(io.is_a?(Hash)).to be(true)
    expect(io.empty?).to be(false)
    expect(surfaces.nil?).to be(false)
    expect(surfaces.is_a?(Hash)).to be(true)
    expect(surfaces.size).to eq(56)

    ids = { a: "Entryway  Wall 4",
            b: "Entryway  Wall 5",
            c: "Entryway  Wall 6",
            d: "Entry way  DroppedCeiling",
            e: "Utility1 Wall 1",
            f: "Utility1 Wall 5",
            g: "Utility 1 DroppedCeiling",
            h: "Smalloffice 1 Wall 1",
            i: "Smalloffice 1 Wall 2",
            j: "Smalloffice 1 Wall 6",
            k: "Small office 1 DroppedCeiling",
            l: "Openarea 1 Wall 3",
            m: "Openarea 1 Wall 4",
            n: "Openarea 1 Wall 5",
            o: "Openarea 1 Wall 6",
            p: "Openarea 1 Wall 7",
            q: "Open area 1 DroppedCeiling" }.freeze

    surfaces.each do |id, surface|
      next if surface.key?(:edges)
      expect(ids.has_value?(id)).to be(false)
    end

    surfaces.each do |id, surface|
      next unless surface.key?(:edges)
      expect(ids.has_value?(id)).to be(true)
      expect(surface.key?(:heatloss)).to be(true)
      expect(surface.key?(:ratio)).to be(true)
      h = surface[:heatloss]

      s = os_model.getSurfaceByName(id)
      expect(s.empty?).to be(false)
      s = s.get
      expect(s.nameString).to eq(id)
      expect(s.isConstructionDefaulted).to be(false)
      expect(/ tbd/i.match(s.construction.get.nameString)).to_not eq(nil)
      expect(h).to be_within(0.01).of( 3.62) if id == ids[:a]
      expect(h).to be_within(0.01).of( 6.28) if id == ids[:b]
      expect(h).to be_within(0.01).of( 2.62) if id == ids[:c]
      expect(h).to be_within(0.01).of( 0.17) if id == ids[:d]
      expect(h).to be_within(0.01).of( 7.13) if id == ids[:e]
      expect(h).to be_within(0.01).of( 7.09) if id == ids[:f]
      expect(h).to be_within(0.01).of( 0.20) if id == ids[:g]
      expect(h).to be_within(0.01).of( 7.94) if id == ids[:h]
      expect(h).to be_within(0.01).of( 5.17) if id == ids[:i]
      expect(h).to be_within(0.01).of( 5.01) if id == ids[:j]
      expect(h).to be_within(0.01).of( 0.22) if id == ids[:k]
      expect(h).to be_within(0.01).of( 2.47) if id == ids[:l]
      expect(h).to be_within(0.01).of( 3.11) if id == ids[:m]
      expect(h).to be_within(0.01).of( 4.43) if id == ids[:n]
      expect(h).to be_within(0.01).of( 3.35) if id == ids[:o]
      expect(h).to be_within(0.01).of( 2.12) if id == ids[:p]
      expect(h).to be_within(0.01).of( 0.31) if id == ids[:q]

      c = s.construction
      expect(c.empty?).to be(false)
      c = c.get.to_LayeredConstruction
      expect(c.empty?).to be(false)
      c = c.get
      i = 0
      i = 2 if s.outsideBoundaryCondition == "Outdoors"
      expect(c.layers[i].nameString.include?("m tbd")).to be(true)
    end

    surfaces.each do |id, surface|
      if surface.key?(:ratio)
        # ratio  = format "%3.1f", surface[:ratio]
        # name   = id.rjust(15, " ")
        # puts "#{name} RSi derated by #{ratio}%"
        expect(surface[:ratio]).to be_within(0.1).of(-28.93) if id == ids[:a]
        expect(surface[:ratio]).to be_within(0.1).of(-26.61) if id == ids[:b]
        expect(surface[:ratio]).to be_within(0.1).of(-25.82) if id == ids[:c]
        expect(surface[:ratio]).to be_within(0.1).of( -0.06) if id == ids[:d]
        expect(surface[:ratio]).to be_within(0.1).of(-27.14) if id == ids[:e]
        expect(surface[:ratio]).to be_within(0.1).of(-27.18) if id == ids[:f]
        expect(surface[:ratio]).to be_within(0.1).of( -0.05) if id == ids[:g]
        expect(surface[:ratio]).to be_within(0.1).of(-32.40) if id == ids[:h]
        expect(surface[:ratio]).to be_within(0.1).of(-32.58) if id == ids[:i]
        expect(surface[:ratio]).to be_within(0.1).of(-32.77) if id == ids[:j]
        expect(surface[:ratio]).to be_within(0.1).of( -0.05) if id == ids[:k]
        expect(surface[:ratio]).to be_within(0.1).of(-18.14) if id == ids[:l]
        expect(surface[:ratio]).to be_within(0.1).of(-21.97) if id == ids[:m]
        expect(surface[:ratio]).to be_within(0.1).of(-18.77) if id == ids[:n]
        expect(surface[:ratio]).to be_within(0.1).of(-21.14) if id == ids[:o]
        expect(surface[:ratio]).to be_within(0.1).of(-19.10) if id == ids[:p]
        expect(surface[:ratio]).to be_within(0.1).of( -0.04) if id == ids[:q]

        next unless id == ids[:a]
        s = os_model.getSurfaceByName(id)
        expect(s.empty?).to be(false)
        s = s.get
        expect(s.nameString).to eq(id)
        expect(s.surfaceType).to eq("Wall")
        expect(s.isConstructionDefaulted).to be(false)
        c = s.construction.get.to_LayeredConstruction
        expect(c.empty?).to be(false)
        c = c.get
        expect(c.nameString.include?("c tbd")).to be(true)
        expect(c.layers.size).to eq(4)
        expect(c.layers[2].nameString.include?("m tbd")).to be(true)
        expect(c.layers[2].to_StandardOpaqueMaterial.empty?).to be(false)
        m = c.layers[2].to_StandardOpaqueMaterial.get

        initial_R = s.filmResistance + 2.4674
        derated_R = s.filmResistance + 0.9931
        derated_R += m.thickness / m.thermalConductivity

        ratio = -(initial_R - derated_R) * 100 / initial_R
        expect(ratio).to be_within(1).of(surfaces[id][:ratio])
      else
        if surface[:boundary].downcase == "outdoors"
          expect(surface[:conditioned]).to be(false)
        end
      end
    end
  end

  it "can process testing JSON surface KHI entries" do
    TBD.clean!
    argh = {}

    translator = OpenStudio::OSVersion::VersionTranslator.new
    file = File.join(__dir__, "files/osms/in/seb.osm")
    path = OpenStudio::Path.new(file)
    os_model = translator.loadModel(path)
    expect(os_model.empty?).to be(false)
    os_model = os_model.get

    argh[:option] = "(non thermal bridging)"
    argh[:io_path] = File.join(__dir__, "../json/tbd_seb_n2.json")
    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")
    json = TBD.process(os_model, argh)
    expect(json.is_a?(Hash)).to be(true)
    expect(json.key?(:io)).to be(true)
    expect(json.key?(:surfaces)).to be(true)
    io       = json[:io]
    surfaces = json[:surfaces]
    expect(TBD.status).to eq(0)
    expect(TBD.logs.empty?).to be(true)
    expect(io.nil?).to be(false)
    expect(io.is_a?(Hash)).to be(true)
    expect(io.empty?).to be(false)
    expect(surfaces.nil?).to be(false)
    expect(surfaces.is_a?(Hash)).to be(true)
    expect(surfaces.size).to eq(56)

    # As the :building PSI set on file remains "(non thermal bridging)", one
    # should not expect differences in results, i.e. derating shouldn't occur.
    # However, the JSON file holds KHI entries for "Entryway  Wall 2" :
    # 3x "columns" @0.5 W/K + 4x supports @0.5W/K = 3.5 W/K
    surfaces.values.each do |surface|
      next unless surface.key?(:ratio)
      expect(surface[:heatloss]).to be_within(0.01).of(3.5)
    end
  end

  it "can process JSON surface KHI & PSI entries" do
    TBD.clean!
    argh = {}

    translator = OpenStudio::OSVersion::VersionTranslator.new
    file = File.join(__dir__, "files/osms/in/seb.osm")
    path = OpenStudio::Path.new(file)
    os_model = translator.loadModel(path)
    expect(os_model.empty?).to be(false)
    os_model = os_model.get

    argh[:option] = "(non thermal bridging)"      # no :building PSI set on file
    argh[:io_path] = File.join(__dir__, "../json/tbd_seb_n3.json")
    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")
    json = TBD.process(os_model, argh)
    expect(json.is_a?(Hash)).to be(true)
    expect(json.key?(:io)).to be(true)
    expect(json.key?(:surfaces)).to be(true)
    io       = json[:io]
    surfaces = json[:surfaces]
    expect(TBD.status).to eq(0)
    expect(TBD.logs.empty?).to be(true)
    expect(io.nil?).to be(false)
    expect(io.is_a?(Hash)).to be(true)
    expect(io.empty?).to be(false)
    expect(surfaces.nil?).to be(false)
    expect(surfaces.is_a?(Hash)).to be(true)
    expect(surfaces.size).to eq(56)
    expect(io.key?(:building)).to be(true) # despite no being on file - good
    expect(io[:building].key?(:psi)).to be(true)
    expect(io[:building][:psi]).to eq("(non thermal bridging)")

    # As the :building PSI set on file remains "(non thermal bridging)", one
    # should not expect differences in results, i.e. derating shouldn't occur
    # for most surfaces. However, the JSON file holds KHI entries for
    # "Entryway  Wall 5":
    # 3x "columns" @0.5 W/K + 4x supports @0.5W/K = 3.5 W/K (as in case above),
    # and a "good" PSI set (:parapet, of 0.5 W/K per m).
    nom1 = "Entryway  Wall 5"
    nom2 = "Entry way  DroppedCeiling"

    surfaces.each do |id, surface|
      next unless surface.key?(:ratio)
      expect(id).to eq(nom1).or eq(nom2)
      expect(surface[:heatloss]).to be_within(0.01).of(5.17) if id == nom1
      expect(surface[:heatloss]).to be_within(0.01).of(0.13) if id == nom2
      expect(surface.key?(:edges)).to be(true)
      expect(surface[:edges].size).to eq(10) if id == nom1
      expect(surface[:edges].size).to eq(6) if id == nom2
    end

    expect(io.key?(:edges)).to be(true)
    expect(io[:edges].size).to eq(80)

    # The JSON input file (tbd_seb_n3.json) holds 2x PSI sets:
    #   - "good" for "Entryway  Wall 5"
    #   - "compliant" (ignored)
    #
    # The PSI set "good" only holds non-zero PSI values for:
    #   - :rimjoist (there are none for "Entryway  Wall 5")
    #   - :parapet (a single edge shared with "Entry way  DroppedCeiling")
    #
    # Only those 2x surfaces will be derated. The following counters track the
    # total number of edges delineating either derated surfaces that contribute
    # in derating their insulation materials i.e. found in the "good" PSI set.
    nb_rimjoist_edges     = 0
    nb_parapet_edges      = 0
    nb_fenestration_edges = 0
    nb_head_edges         = 0
    nb_sill_edges         = 0
    nb_jamb_edges         = 0
    nb_corners            = 0
    nb_concave_edges      = 0
    nb_convex_edges       = 0
    nb_balcony_edges      = 0
    nb_party_edges        = 0
    nb_grade_edges        = 0
    nb_transition_edges   = 0

    io[:edges].each do |edge|
      expect(edge.key?(:psi)).to be(true)
      expect(edge.key?(:type)).to be(true)
      expect(edge.key?(:length)).to be(true)
      expect(edge.key?(:surfaces)).to be(true)
      valid = edge[:surfaces].include?(nom1) || edge[:surfaces].include?(nom2)
      next unless valid
      s = {}
      io[:psis].each { |set| s = set if set[:id] == edge[:psi] }
      next if s.empty?
      expect(s.is_a?(Hash)).to be(true)

      t = edge[:type]
      nb_rimjoist_edges     += 1 if t == :rimjoist
      nb_rimjoist_edges     += 1 if t == :rimjoistconcave
      nb_rimjoist_edges     += 1 if t == :rimjoistconvex
      nb_parapet_edges      += 1 if t == :parapet
      nb_parapet_edges      += 1 if t == :parapetconcave
      nb_parapet_edges      += 1 if t == :parapetconvex
      nb_fenestration_edges += 1 if t == :fenestration
      nb_head_edges         += 1 if t == :head
      nb_sill_edges         += 1 if t == :sill
      nb_jamb_edges         += 1 if t == :jamb
      nb_corners            += 1 if t == :corner
      nb_concave_edges      += 1 if t == :cornerconcave
      nb_convex_edges       += 1 if t == :cornerconvex
      nb_balcony_edges      += 1 if t == :balcony
      nb_party_edges        += 1 if t == :party
      nb_grade_edges        += 1 if t == :grade
      nb_grade_edges        += 1 if t == :gradeconcave
      nb_grade_edges        += 1 if t == :gradeconvex
      nb_transition_edges   += 1 if t == :transition
      expect(t).to eq(:parapetconvex).or eq(:transition)
      next unless t == :parapetconvex
      expect(edge[:length]).to be_within(0.01).of(3.6)
    end

    expect(nb_rimjoist_edges).to     eq(0)
    expect(nb_parapet_edges).to      eq(1)    # parapet linked to "good" PSI set
    expect(nb_fenestration_edges).to eq(0)
    expect(nb_head_edges).to         eq(0)
    expect(nb_sill_edges).to         eq(0)
    expect(nb_jamb_edges).to         eq(0)
    expect(nb_corners).to            eq(0)
    expect(nb_concave_edges).to      eq(0)
    expect(nb_convex_edges).to       eq(0)
    expect(nb_balcony_edges).to      eq(0)
    expect(nb_party_edges).to        eq(0)
    expect(nb_grade_edges).to        eq(0)
    expect(nb_transition_edges).to   eq(2)  # all PSI sets inherit :transitions

    # Reset counters to track the total number of edges delineating either
    # derated surfaces that DO NOT contribute in derating their insulation
    # materials i.e. not found in the "good" PSI set.
    nb_rimjoist_edges     = 0
    nb_parapet_edges      = 0
    nb_fenestration_edges = 0
    nb_head_edges         = 0
    nb_sill_edges         = 0
    nb_jamb_edges         = 0
    nb_corners            = 0
    nb_concave_edges      = 0
    nb_convex_edges       = 0
    nb_balcony_edges      = 0
    nb_party_edges        = 0
    nb_grade_edges        = 0
    nb_transition_edges   = 0

    io[:edges].each do |edge|
      valid = edge[:surfaces].include?(nom1) || edge[:surfaces].include?(nom2)
      next unless valid
      s = {}
      io[:psis].each { |set| s = set if set[:id] == edge[:psi] }
      next unless s.empty?
      expect(edge[:psi] == argh[:option]).to be(true)

      t = edge[:type]
      nb_rimjoist_edges     += 1 if t == :rimjoist
      nb_rimjoist_edges     += 1 if t == :rimjoistconcave
      nb_rimjoist_edges     += 1 if t == :rimjoistconvex
      nb_parapet_edges      += 1 if t == :parapet
      nb_parapet_edges      += 1 if t == :parapetconcave
      nb_parapet_edges      += 1 if t == :parapetconvex
      nb_fenestration_edges += 1 if t == :fenestration
      nb_head_edges         += 1 if t == :head
      nb_sill_edges         += 1 if t == :sill
      nb_jamb_edges         += 1 if t == :jamb
      nb_corners            += 1 if t == :corner
      nb_concave_edges      += 1 if t == :cornerconcave
      nb_convex_edges       += 1 if t == :cornerconvex
      nb_balcony_edges      += 1 if t == :balcony
      nb_party_edges        += 1 if t == :party
      nb_grade_edges        += 1 if t == :grade
      nb_grade_edges        += 1 if t == :gradeconcave
      nb_grade_edges        += 1 if t == :gradeconvex
      nb_transition_edges   += 1 if t == :transition
    end

    expect(nb_rimjoist_edges).to     eq(0)
    expect(nb_parapet_edges).to      eq(2)        # not linked to "good" PSI set
    expect(nb_fenestration_edges).to eq(0)
    expect(nb_head_edges).to         eq(1)
    expect(nb_sill_edges).to         eq(1)
    expect(nb_jamb_edges).to         eq(2)
    expect(nb_corners).to            eq(0)
    expect(nb_concave_edges).to      eq(0)
    expect(nb_convex_edges).to       eq(2)           # edges between walls 5 & 4
    expect(nb_balcony_edges).to      eq(0)
    expect(nb_party_edges).to        eq(0)
    expect(nb_grade_edges).to        eq(1)
    expect(nb_transition_edges).to   eq(3)                   # shared roof edges

    # Reset counters again to track the total number of edges delineating either
    # derated surfaces that DO NOT contribute in derating their insulation
    # materials i.e., automatically set as :transitions in "good" PSI set.
    nb_rimjoist_edges     = 0
    nb_parapet_edges      = 0
    nb_fenestration_edges = 0
    nb_head_edges         = 0
    nb_sill_edges         = 0
    nb_jamb_edges         = 0
    nb_corners            = 0
    nb_concave_edges      = 0
    nb_convex_edges       = 0
    nb_balcony_edges      = 0
    nb_party_edges        = 0
    nb_grade_edges        = 0
    nb_transition_edges   = 0

    io[:edges].each do |edge|
      valid = edge[:surfaces].include?(nom1) || edge[:surfaces].include?(nom2)
      next unless valid
      s = {}
      io[:psis].each { |set| s = set if set[:id] == edge[:psi] }
      next if s.empty?
      expect(s.is_a?(Hash)).to be(true)

      t = edge[:type]
      next if t.to_s.include?("parapet")
      nb_rimjoist_edges     += 1 if t == :rimjoist
      nb_rimjoist_edges     += 1 if t == :rimjoistconcave
      nb_rimjoist_edges     += 1 if t == :rimjoistconvex
      nb_parapet_edges      += 1 if t == :parapet
      nb_parapet_edges      += 1 if t == :parapetconcave
      nb_parapet_edges      += 1 if t == :parapetconvex
      nb_fenestration_edges += 1 if t == :fenestration
      nb_head_edges         += 1 if t == :head
      nb_sill_edges         += 1 if t == :sill
      nb_jamb_edges         += 1 if t == :jamb
      nb_corners            += 1 if t == :corner
      nb_concave_edges      += 1 if t == :cornerconcave
      nb_convex_edges       += 1 if t == :cornerconvex
      nb_balcony_edges      += 1 if t == :balcony
      nb_party_edges        += 1 if t == :party
      nb_grade_edges        += 1 if t == :grade
      nb_grade_edges        += 1 if t == :gradeconcave
      nb_grade_edges        += 1 if t == :gradeconvex
      nb_transition_edges   += 1 if t == :transition
    end

    expect(nb_rimjoist_edges).to     eq(0)
    expect(nb_parapet_edges).to      eq(0)
    expect(nb_fenestration_edges).to eq(0)
    expect(nb_head_edges).to         eq(0)
    expect(nb_jamb_edges).to         eq(0)
    expect(nb_sill_edges).to         eq(0)
    expect(nb_corners).to            eq(0)
    expect(nb_concave_edges).to      eq(0)
    expect(nb_convex_edges).to       eq(0)
    expect(nb_balcony_edges).to      eq(0)
    expect(nb_party_edges).to        eq(0)
    expect(nb_grade_edges).to        eq(0)
    expect(nb_transition_edges).to   eq(2)           # edges between walls 5 & 6
  end

  it "can process JSON surface KHI & PSI entries + building & edge" do
    TBD.clean!
    argh = {}

    translator = OpenStudio::OSVersion::VersionTranslator.new
    file = File.join(__dir__, "files/osms/in/seb.osm")
    path = OpenStudio::Path.new(file)
    os_model = translator.loadModel(path)
    expect(os_model.empty?).to be(false)
    os_model = os_model.get

    argh[:option] = "(non thermal bridging)"
    argh[:io_path] = File.join(__dir__, "../json/tbd_seb_n4.json")
    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")
    json = TBD.process(os_model, argh)
    expect(json.is_a?(Hash)).to be(true)
    expect(json.key?(:io)).to be(true)
    expect(json.key?(:surfaces)).to be(true)
    io       = json[:io]
    surfaces = json[:surfaces]
    expect(TBD.status).to eq(0)
    expect(TBD.logs.empty?).to be(true)
    expect(io.nil?).to be(false)
    expect(io.is_a?(Hash)).to be(true)
    expect(io.empty?).to be(false)
    expect(surfaces.nil?).to be(false)
    expect(surfaces.is_a?(Hash)).to be(true)
    expect(surfaces.size).to eq(56)

    # As the :building PSI set on file == "(non thermal bridgin)", derating
    # shouldn't occur at large. However, the JSON file holds a custom edge
    # entry for "Entryway  Wall 5" : "bad" fenestration permieters, which
    # only derates the host wall itself
    surfaces.each do |id, surface|
      next unless surface[:boundary].downcase == "outdoors"
      name = "Entryway  Wall 5"
      expect(surface.key?(:ratio)).to be(false) unless id == name
      next unless id == "Entryway  Wall 5"
      expect(surface[:heatloss]).to be_within(0.01).of(8.89)
    end
  end

  it "can process JSON surface KHI & PSI + building & edge (2)" do
    TBD.clean!
    argh = {}

    translator = OpenStudio::OSVersion::VersionTranslator.new
    file = File.join(__dir__, "files/osms/in/seb.osm")
    path = OpenStudio::Path.new(file)
    os_model = translator.loadModel(path)
    expect(os_model.empty?).to be(false)
    os_model = os_model.get

    argh[:option] = "(non thermal bridging)"
    argh[:io_path] = File.join(__dir__, "../json/tbd_seb_n5.json")
    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")
    json = TBD.process(os_model, argh)
    expect(json.is_a?(Hash)).to be(true)
    expect(json.key?(:io)).to be(true)
    expect(json.key?(:surfaces)).to be(true)
    io       = json[:io]
    surfaces = json[:surfaces]
    expect(TBD.status).to eq(0)
    expect(TBD.logs.empty?).to be(true)
    expect(io.nil?).to be(false)
    expect(io.is_a?(Hash)).to be(true)
    expect(io.empty?).to be(false)
    expect(surfaces.nil?).to be(false)
    expect(surfaces.is_a?(Hash)).to be(true)
    expect(surfaces.size).to eq(56)

    # As above, yet the KHI points are now set @0.5 W/K per m (instead of 0)
    surfaces.each do |id, surface|
      next unless surface[:boundary].downcase == "outdoors"
      name = "Entryway  Wall 5"
      expect(surface.key?(:ratio)).to be(false) unless id == name
      next unless id == "Entryway  Wall 5"
      expect(surface[:heatloss]).to be_within(0.01).of(12.39)
    end
  end

  it "can process JSON surface KHI & PSI + building & edge (3)" do
    TBD.clean!
    argh = {}

    translator = OpenStudio::OSVersion::VersionTranslator.new
    file = File.join(__dir__, "files/osms/in/seb.osm")
    path = OpenStudio::Path.new(file)
    os_model = translator.loadModel(path)
    expect(os_model.empty?).to be(false)
    os_model = os_model.get

    argh[:option] = "(non thermal bridging)"
    argh[:io_path] = File.join(__dir__, "../json/tbd_seb_n6.json")
    argh[:schama_path] = File.join(__dir__, "../tbd.schema.json")
    json = TBD.process(os_model, argh)
    expect(json.is_a?(Hash)).to be(true)
    expect(json.key?(:io)).to be(true)
    expect(json.key?(:surfaces)).to be(true)
    io       = json[:io]
    surfaces = json[:surfaces]
    expect(TBD.status).to eq(0)
    expect(TBD.logs.empty?).to be(true)
    expect(io.nil?).to be(false)
    expect(io.is_a?(Hash)).to be(true)
    expect(io.empty?).to be(false)
    expect(surfaces.nil?).to be(false)
    expect(surfaces.is_a?(Hash)).to be(true)
    expect(surfaces.size).to eq(56)

    # As above, with a "good" surface PSI set
    surfaces.each do |id, surface|
      next unless surface[:boundary].downcase == "outdoors"
      name = "Entryway  Wall 5"
      expect(surface.key?(:ratio)).to be(false) unless id == name
      next unless id == "Entryway  Wall 5"
      expect(surface[:heatloss]).to be_within(0.01).of(14.05)
    end
  end

  it "can process JSON surface KHI & PSI + building & edge (4)" do
    TBD.clean!
    argh = {}

    translator = OpenStudio::OSVersion::VersionTranslator.new
    file = File.join(__dir__, "files/osms/in/seb.osm")
    path = OpenStudio::Path.new(file)
    os_model = translator.loadModel(path)
    expect(os_model.empty?).to be(false)
    os_model = os_model.get

    argh[:option] = "compliant"        # superseded by :building PSI set on file
    argh[:io_path] = File.join(__dir__, "../json/tbd_seb_n7.json")
    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")
    json = TBD.process(os_model, argh)
    expect(json.is_a?(Hash)).to be(true)
    expect(json.key?(:io)).to be(true)
    expect(json.key?(:surfaces)).to be(true)
    io       = json[:io]
    surfaces = json[:surfaces]
    expect(TBD.status).to eq(0)
    expect(TBD.logs.empty?).to be(true)
    expect(io.nil?).to be(false)
    expect(io.is_a?(Hash)).to be(true)
    expect(io.empty?).to be(false)
    expect(surfaces.nil?).to be(false)
    expect(surfaces.is_a?(Hash)).to be(true)
    expect(surfaces.size).to eq(56)

    # In the JSON file, the "Entry way 1" space "compliant" PSI set supersedes
    # the default :building PSI set "(non thermal bridging)". The 3x walls below
    # (4, 5 & 6) - part of "Entry way 1" - will inherit the "compliant" PSI set
    # and hence their constructions will be derated. Exceptionally, Wall 5 has
    # - in addition to a handful of point conductances - derating edges based on
    # the "good" PSI set. Finally, edges between Wall 5 and its  "Sub Surface 8"
    # have their types overwritten (from :fenestration to :balcony), i.e.
    # 0.8 W/K per m instead of 0.35 W/K per m. The latter is a weird one, but
    # illustrates basic JSON functionality. A more realistic override: a switch
    # between :corner to :fenestration (or vice versa) for corner windows.
    surfaces.each do |id, surface|
      next unless surface[:boundary].downcase == "outdoors"

      if id == "Entryway  Wall 5" ||
         id == "Entryway  Wall 6" || # ??
         id == "Entryway  Wall 4"
        expect(surface.key?(:ratio)).to be(true)
      else
        expect(surface.key?(:ratio)).to be(false)
      end

      next unless id == "Entryway  Wall 5"
      expect(surface[:heatloss]).to be_within(0.01).of(15.62)
    end
  end

  it "can factor in negative PSI values (JSON input)" do
    TBD.clean!
    argh = {}

    translator = OpenStudio::OSVersion::VersionTranslator.new
    file = File.join(__dir__, "files/osms/in/warehouse.osm")
    path = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model.empty?).to be(false)
    model = model.get

    argh[:option     ] = "compliant"   # superseded by :building PSI set on file
    argh[:io_path    ] = File.join(__dir__, "../json/tbd_warehouse4.json")
    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")
    json = TBD.process(model, argh)
    expect(json.is_a?(Hash)).to be(true)
    expect(json.key?(:io)).to be(true)
    expect(json.key?(:surfaces)).to be(true)
    io       = json[:io]
    surfaces = json[:surfaces]
    expect(TBD.status).to eq(0)
    expect(TBD.logs.empty?).to be(true)
    expect(io.nil?).to be(false)
    expect(io.is_a?(Hash)).to be(true)
    expect(io.empty?).to be(false)
    expect(surfaces.nil?).to be(false)
    expect(surfaces.is_a?(Hash)).to be(true)
    expect(surfaces.size).to eq(23)

    ids = { a: "Office Front Wall",
            b: "Office Left Wall",
            c: "Fine Storage Roof",
            d: "Fine Storage Office Front Wall",
            e: "Fine Storage Office Left Wall",
            f: "Fine Storage Front Wall",
            g: "Fine Storage Left Wall",
            h: "Fine Storage Right Wall",
            i: "Bulk Storage Roof",
            j: "Bulk Storage Rear Wall",
            k: "Bulk Storage Left Wall",
            l: "Bulk Storage Right Wall" }.freeze

    surfaces.each do |id, surface|
      next if surface.key?(:edges)
      expect(ids.has_value?(id)).to be(false)
    end

    surfaces.each do |id, surface|
      next unless surface[:boundary].downcase == "outdoors"
      next unless surface.key?(:ratio)
      expect(ids.has_value?(id)).to be(true)
      expect surface.key?(:heatloss)

      # Ratios are typically negative e.g., a steel corner column decreasing
      # linked surface RSi values. In some cases, a corner PSI can be positive
      # (and thus increasing linked surface RSi values). This happens when
      # estimating PSI values for convex corners while relying on an interior
      # dimensioning convention e.g., BETBG Detail 7.6.2, ISO 14683.
      expect(surface[:ratio]).to be_within(0.01).of(0.18) if id == ids[:a]
      expect(surface[:ratio]).to be_within(0.01).of(0.55) if id == ids[:b]
      expect(surface[:ratio]).to be_within(0.01).of(0.15) if id == ids[:d]
      expect(surface[:ratio]).to be_within(0.01).of(0.43) if id == ids[:e]
      expect(surface[:ratio]).to be_within(0.01).of(0.20) if id == ids[:f]
      expect(surface[:ratio]).to be_within(0.01).of(0.13) if id == ids[:h]
      expect(surface[:ratio]).to be_within(0.01).of(0.12) if id == ids[:j]
      expect(surface[:ratio]).to be_within(0.01).of(0.04) if id == ids[:k]
      expect(surface[:ratio]).to be_within(0.01).of(0.04) if id == ids[:l]

      # In such cases, negative heatloss means heat gained.
      expect(surface[:heatloss]).to be_within(0.01).of(-0.10) if id == ids[:a]
      expect(surface[:heatloss]).to be_within(0.01).of(-0.10) if id == ids[:b]
      expect(surface[:heatloss]).to be_within(0.01).of(-0.10) if id == ids[:d]
      expect(surface[:heatloss]).to be_within(0.01).of(-0.10) if id == ids[:e]
      expect(surface[:heatloss]).to be_within(0.01).of(-0.20) if id == ids[:f]
      expect(surface[:heatloss]).to be_within(0.01).of(-0.20) if id == ids[:h]
      expect(surface[:heatloss]).to be_within(0.01).of(-0.40) if id == ids[:j]
      expect(surface[:heatloss]).to be_within(0.01).of(-0.20) if id == ids[:k]
      expect(surface[:heatloss]).to be_within(0.01).of(-0.20) if id == ids[:l]
    end
  end

  it "can process JSON file read/validate" do
    TBD.clean!
    argh = {}

    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")
    expect(File.exist?(argh[:schema_path])).to be(true)
    schema = File.read(argh[:schema_path])
    schema = JSON.parse(schema, symbolize_names: true)

    argh[:io_path] = File.join(__dir__, "../json/tbd_json_test.json")
    io = File.read(argh[:io_path])
    io = JSON.parse(io, symbolize_names: true)

    expect(JSON::Validator.validate(schema, io)).to be(true)
    expect(io.key?(:description)).to be(true)
    expect(io.key?(:schema)).to be(true)
    expect(io.key?(:edges)).to be(true)
    expect(io.key?(:surfaces)).to be(true)
    expect(io.key?(:spaces)).to be(false)
    expect(io.key?(:spacetypes)).to be(false)
    expect(io.key?(:stories)).to be(false)
    expect(io.key?(:building)).to be(true)
    expect(io.key?(:logs)).to be(false)
    expect(io[:edges].size).to eq(1)
    expect(io[:surfaces].size).to eq(1)

    # Loop through input psis to ensure uniqueness vs PSI defaults
    psi = TBD::PSI.new
    expect(io.key?(:psis)).to be(true)
    io[:psis].each { |p| expect(psi.append(p)).to be(true) }
    expect(psi.set.size).to eq(10)
    expect(psi.set.key?("poor (BETBG)")).to be(true)
    expect(psi.set.key?("regular (BETBG)")).to be(true)
    expect(psi.set.key?("efficient (BETBG)")).to be(true)
    expect(psi.set.key?("spandrel (BETBG)")).to be(true)
    expect(psi.set.key?("spandrel HP (BETBG)")).to be(true)
    expect(psi.set.key?("code (Quebec)")).to be(true)
    expect(psi.set.key?("uncompliant (Quebec)")).to be(true)
    expect(psi.set.key?("(non thermal bridging)")).to be(true)
    expect(psi.set.key?("good")).to be(true)
    expect(psi.set.key?("compliant")).to be(true)

    # Similar treatment for khis
    khi = TBD::KHI.new
    expect(io.key?(:khis)).to be(true)
    io[:khis].each { |k| expect(khi.append(k)).to be(true) }
    expect(khi.point.size).to eq(8)
    expect(khi.point.key?("poor (BETBG)")).to be(true)
    expect(khi.point.key?("regular (BETBG)")).to be(true)
    expect(khi.point.key?("efficient (BETBG)")).to be(true)
    expect(psi.set.key?("spandrel (BETBG)")).to be(true)
    expect(psi.set.key?("spandrel HP (BETBG)")).to be(true)
    expect(khi.point.key?("code (Quebec)")).to be(true)
    expect(khi.point.key?("uncompliant (Quebec)")).to be(true)
    expect(khi.point.key?("(non thermal bridging)")).to be(true)
    expect(khi.point.key?("column")).to be(true)
    expect(khi.point.key?("support")).to be(true)
    expect(khi.point["column"]).to eq(0.5)
    expect(khi.point["support"]).to eq(0.5)

    expect(io.key?(:building)).to be(true)
    expect(io[:building].key?(:psi)).to be(true)
    expect(io[:building][:psi]).to eq("compliant")
    expect(psi.set.key?(io[:building][:psi])).to be(true)

    expect(io.key?(:surfaces)).to be(true)
    io[:surfaces].each do |surface|
      expect(surface.key?(:id)).to be(true)
      expect(surface[:id]).to eq("front wall")
      expect(surface.key?(:psi)).to be(true)
      expect(surface[:psi]).to eq("good")
      expect(psi.set.key?(surface[:psi])).to be(true)

      expect(surface.key?(:khis)).to be(true)
      expect(surface[:khis].size).to eq(2)
      surface[:khis].each do |k|
        expect(k.key?(:id)).to be(true)
        expect(khi.point.key?(k[:id])).to be(true)
        expect(k[:count]).to eq(3) if k[:id] == "column"
        expect(k[:count]).to eq(4) if k[:id] == "support"
      end
    end

    expect(io.key?(:edges)).to be(true)
    io[:edges].each do |edge|
      expect(edge.key?(:psi)).to be(true)
      expect(edge[:psi]).to eq("compliant")
      expect(psi.set.key?(edge[:psi])).to be(true)
      expect(edge.key?(:surfaces)).to be(true)
      edge[:surfaces].each do |surface|
        expect(surface).to eq("front wall")
      end
    end

    # A reminder that built-in KHIs are not frozen ...
    khi.point["code (Quebec)"] = 2.0
    expect(khi.point["code (Quebec)"]).to eq(2.0)

    # Load PSI combo JSON example - likely the most expected or common use.
    argh[:io_path] = File.join(__dir__, "../json/tbd_PSI_combo.json")
    io = File.read(argh[:io_path])
    io = JSON.parse(io, symbolize_names: true)
    expect(JSON::Validator.validate(schema, io)).to be(true)
    expect(io.key?(:description)).to be(true)
    expect(io.key?(:schema)).to be(true)
    expect(io.key?(:edges)).to be(false)
    expect(io.key?(:surfaces)).to be(false)
    expect(io.key?(:spaces)).to be(true)
    expect(io.key?(:spacetypes)).to be(false)
    expect(io.key?(:stories)).to be(false)
    expect(io.key?(:building)).to be(true)
    expect(io.key?(:logs)).to be(false)
    expect(io[:spaces].size).to eq(1)

    # Loop through input psis to ensure uniqueness vs PSI defaults.
    psi = TBD::PSI.new
    expect(io.key?(:psis)).to be(true)
    io[:psis].each { |p| expect(psi.append(p)).to be(true) }
    expect(psi.set.size).to eq(10)
    expect(psi.set.key?("poor (BETBG)")).to be(true)
    expect(psi.set.key?("regular (BETBG)")).to be(true)
    expect(psi.set.key?("efficient (BETBG)")).to be(true)
    expect(psi.set.key?("spandrel (BETBG)")).to be(true)
    expect(psi.set.key?("spandrel HP (BETBG)")).to be(true)
    expect(psi.set.key?("code (Quebec)")).to be(true)
    expect(psi.set.key?("uncompliant (Quebec)")).to be(true)
    expect(psi.set.key?("(non thermal bridging)")).to be(true)
    expect(psi.set.key?("OK")).to be(true)
    expect(psi.set.key?("Awesome")).to be(true)
    expect(psi.set["Awesome"][:rimjoist]).to eq(0.2)

    expect(io.key?(:building)).to be (true)
    expect(io[:building].key?(:psi)).to be(true)
    expect(io[:building][:psi]).to eq("Awesome")
    expect(psi.set.key?(io[:building][:psi])).to be(true)

    expect(io.key?(:spaces)).to be(true)
    io[:spaces].each do |space|
      expect(space.key?(:psi)).to be(true)
      expect(space[:id]).to eq("ground-floor restaurant")
      expect(space[:psi]).to eq("OK")
      expect(psi.set.key?(space[:psi])).to be(true)
    end

    # Load PSI combo2 JSON example - a more elaborate example, yet common.
    # Post-JSON validation required to handle case sensitive keys & value
    # strings (e.g. "ok" vs "OK" in the file).
    argh[:io_path] = File.join(__dir__, "../json/tbd_PSI_combo2.json")
    io = File.read(argh[:io_path])
    io = JSON.parse(io, symbolize_names: true)
    expect(JSON::Validator.validate(schema, io)).to be(true)
    expect(io.key?(:description)).to be(true)
    expect(io.key?(:schema)).to be(true)
    expect(io.key?(:edges)).to be(true)
    expect(io.key?(:surfaces)).to be(true)
    expect(io.key?(:spaces)).to be(false)
    expect(io.key?(:spacetypes)).to be(false)
    expect(io.key?(:stories)).to be(false)
    expect(io.key?(:building)).to be(true)
    expect(io.key?(:logs)).to be(false)
    expect(io[:edges].size).to eq(1)
    expect(io[:surfaces].size).to eq(1)

    # Loop through input psis to ensure uniqueness vs PSI defaults
    psi = TBD::PSI.new
    expect(io.key?(:psis)).to be(true)
    io[:psis].each { |p| expect(psi.append(p)).to be(true) }
    expect(psi.set.size).to eq(11)
    expect(psi.set.key?("poor (BETBG)")).to be(true)
    expect(psi.set.key?("regular (BETBG)")).to be(true)
    expect(psi.set.key?("efficient (BETBG)")).to be(true)
    expect(psi.set.key?("spandrel (BETBG)")).to be(true)
    expect(psi.set.key?("spandrel HP (BETBG)")).to be(true)
    expect(psi.set.key?("code (Quebec)")).to be(true)
    expect(psi.set.key?("uncompliant (Quebec)")).to be(true)
    expect(psi.set.key?("(non thermal bridging)")).to be(true)
    expect(psi.set.key?("OK")).to be(true)
    expect(psi.set.key?("Awesome")).to be(true)
    expect(psi.set.key?("Party wall edge")).to be(true)
    expect(psi.set["Party wall edge"][:party]).to eq(0.4)

    expect(io.key?(:building)).to be(true)
    expect(io[:building].key?(:psi)).to be(true)
    expect(io[:building][:psi]).to eq("Awesome")
    expect(psi.set.key?(io[:building][:psi])).to be(true)

    expect(io.key?(:surfaces)).to be(true)
    io[:surfaces].each do |surface|
      expect(surface.key?(:id)).to be(true)
      expect(surface[:id]).to eq("ground-floor restaurant South-wall")
      expect(surface.key?(:psi)).to be(true)
      expect(surface[:psi]).to eq("ok")
      expect(psi.set.key?(surface[:psi])).to be(false)
    end

    expect(io.key?(:edges)).to be(true)
    io[:edges].each do |edge|
      expect(edge.key?(:psi)).to be(true)
      expect(edge[:psi]).to eq("Party wall edge")
      expect(edge.key?(:type)).to be(true)
      expect(edge[:type].to_s.include?("party")).to be(true)
      expect(psi.set.key?(edge[:psi])).to be(true)
      expect(psi.set[edge[:psi]].key?(:party)).to be(true)
      expect(edge.key?(:surfaces)).to be(true)
      edge[:surfaces].each do |surface|
        answer = false
        answer = true if surface == "ground-floor restaurant West-wall" ||
                         surface == "ground-floor restaurant party wall"
        expect(answer).to be(true)
      end
    end

    # Load full PSI JSON example - with duplicate keys for "party"
    # "JSON Schema Lint" * will recognize the duplicate and - as with duplicate
    # Ruby hash keys - will have the second entry ("party": 0.8) override the
    # first ("party": 0.7). Another reminder of post-JSON validation.
    # * https://jsonschemalint.com/#!/version/draft-04/markup/json
    argh[:io_path] = File.join(__dir__, "../json/tbd_full_PSI.json")
    io = File.read(argh[:io_path])
    io = JSON.parse(io, symbolize_names: true)
    expect(JSON::Validator.validate(schema, io)).to be(true)
    expect(io.key?(:description)).to be(true)
    expect(io.key?(:schema)).to be(true)
    expect(io.key?(:edges)).to be(false)
    expect(io.key?(:surfaces)).to be(false)
    expect(io.key?(:spaces)).to be(false)
    expect(io.key?(:spacetypes)).to be(false)
    expect(io.key?(:stories)).to be(false)
    expect(io.key?(:building)).to be(false)
    expect(io.key?(:logs)).to be(false)

    # Loop through input psis to ensure uniqueness vs PSI defaults
    psi = TBD::PSI.new
    expect(io.key?(:psis)).to be(true)
    io[:psis].each { |p| expect(psi.append(p)).to be(true) }
    expect(psi.set.size).to eq(9)
    expect(psi.set.key?("poor (BETBG)")).to be(true)
    expect(psi.set.key?("regular (BETBG)")).to be(true)
    expect(psi.set.key?("efficient (BETBG)")).to be(true)
    expect(psi.set.key?("spandrel (BETBG)")).to be(true)
    expect(psi.set.key?("spandrel HP (BETBG)")).to be(true)
    expect(psi.set.key?("code (Quebec)")).to be(true)
    expect(psi.set.key?("uncompliant (Quebec)")).to be(true)
    expect(psi.set.key?("(non thermal bridging)")).to be(true)
    expect(psi.set.key?("OK")).to be(true)
    expect(psi.set["OK"][:party]).to eq(0.8)

    # Load minimal PSI JSON example
    argh[:io_path] = File.join(__dir__, "../json/tbd_minimal_PSI.json")
    io = File.read(argh[:io_path])
    io = JSON.parse(io, symbolize_names: true)
    expect(JSON::Validator.validate(schema, io)).to be(true)

    # Load minimal KHI JSON example
    argh[:io_path] = File.join(__dir__, "../json/tbd_minimal_KHI.json")
    io = File.read(argh[:io_path])
    io = JSON.parse(io, symbolize_names: true)
    expect(JSON::Validator.validate(schema, io)).to be(true)
    v = JSON::Validator.validate(argh[:schema_path], argh[:io_path], uri: true)
    expect(v).to be(true)

    # Load complete results (ex. UA') example
    argh[:io_path] = File.join(__dir__, "../json/tbd_warehouse11.json")
    io = File.read(argh[:io_path])
    io = JSON.parse(io, symbolize_names: true)
    expect(JSON::Validator.validate(schema, io)).to be(true)
    v = JSON::Validator.validate(argh[:schema_path], argh[:io_path], uri: true)
    expect(v).to be(true)
  end

  it "can factor in spacetype-specific PSI sets (JSON input)" do
    TBD.clean!
    argh = {}

    translator = OpenStudio::OSVersion::VersionTranslator.new
    file = File.join(__dir__, "files/osms/in/warehouse.osm")
    path = OpenStudio::Path.new(file)
    os_model = translator.loadModel(path)
    expect(os_model.empty?).to be(false)
    os_model = os_model.get

    argh[:option] = "compliant"        # superseded by :building PSI set on file
    argh[:io_path] = File.join(__dir__, "../json/tbd_warehouse5.json")
    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")
    json = TBD.process(os_model, argh)
    expect(json.is_a?(Hash)).to be(true)
    expect(json.key?(:io)).to be(true)
    expect(json.key?(:surfaces)).to be(true)
    io       = json[:io]
    surfaces = json[:surfaces]
    puts TBD.logs
    expect(TBD.status).to eq(0)
    expect(TBD.logs.empty?).to be(true)
    expect(io.nil?).to be(false)
    expect(io.is_a?(Hash)).to be(true)
    expect(io.empty?).to be(false)
    expect(surfaces.nil?).to be(false)
    expect(surfaces.is_a?(Hash)).to be(true)
    expect(surfaces.size).to eq(23)

    sTyp1 = "Warehouse Office"
    sTyp2 = "Warehouse Fine"

    expect(io.key?(:spacetypes)).to be(true)
    io[:spacetypes].each do |spacetype|
      expect(spacetype.key?(:id)).to be(true)
      expect(spacetype[:id]).to eq(sTyp1).or eq(sTyp2)
      expect(spacetype.key?(:psi)).to be(true)
    end

    surfaces.each do |id, surface|
      next unless surface[:boundary].downcase == "outdoors"
      next unless surface.key?(:ratio)
      expect(surface.key?(:heatloss)).to be(true)
      heatloss = surface[:heatloss]
      expect(heatloss.abs).to be > 0
      expect(surface.key?(:space)).to be(true)
      next unless surface[:space].nameString == "Zone1 Office"

      # All applicable thermal bridges/edges derating the office walls inherit
      # the "Warehouse Office" spacetype PSI values (JSON file), except for the
      # shared :rimjoist with the Fine Storage space above. The "Warehouse Fine"
      # spacetype set has a higher :rimjoist PSI value of 0.5 W/K per metre,
      # which overrides the "Warehouse Office" value of 0.3 W/K per metre.
      name = "Office Left Wall"
      expect(heatloss).to be_within(0.01).of(11.61) if id == name
      name = "Office Front Wall"
      expect(heatloss).to be_within(0.01).of(22.94) if id == name
    end
  end

  it "can factor in story-specific PSI sets (JSON input)" do
    TBD.clean!
    argh = {}

    translator = OpenStudio::OSVersion::VersionTranslator.new
    file = File.join(__dir__, "files/osms/in/smalloffice.osm")
    path = OpenStudio::Path.new(file)
    os_model = translator.loadModel(path)
    expect(os_model.empty?).to be(false)
    os_model = os_model.get

    argh[:option] = "compliant"        # superseded by :building PSI set on file
    argh[:io_path] = File.join(__dir__, "../json/tbd_smalloffice.json")
    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")
    json = TBD.process(os_model, argh)
    expect(json.is_a?(Hash)).to be(true)
    expect(json.key?(:io)).to be(true)
    expect(json.key?(:surfaces)).to be(true)
    io       = json[:io]
    surfaces = json[:surfaces]
    expect(TBD.status).to eq(0)
    expect(TBD.logs.empty?).to be(true)
    expect(io.nil?).to be(false)
    expect(io.is_a?(Hash)).to be(true)
    expect(io.empty?).to be(false)
    expect(surfaces.nil?).to be(false)
    expect(surfaces.is_a?(Hash)).to be(true)
    expect(surfaces.size).to eq(43)
    expect(io[:edges].size).to eq(105)

    expect(io.key?(:stories)).to be(true)
    io[:stories].each do |story|
      expect(story.key?(:id)).to be(true)
      expect(story[:id]).to eq("Building Story 1")
      expect(story.key?(:psi)).to be(true)
    end

    surfaces.each do |id, surface|
      next unless surface.key?(:ratio)
      expect(surface.key?(:heatloss)).to be(true)
      heatloss = surface[:heatloss]
      expect(heatloss.abs).to be > 0
      next unless surface.key?(:story)
      expect(surface[:story].nameString).to eq("Building Story 1")
    end
  end

  it "can sort multiple story-specific PSI sets (JSON input)" do
    TBD.clean!
    argh = {}

    translator = OpenStudio::OSVersion::VersionTranslator.new
    file = File.join(__dir__, "files/osms/in/midrise_KIVA.osm")
    path = OpenStudio::Path.new(file)
    os_model = translator.loadModel(path)
    expect(os_model.empty?).to be(false)
    os_model = os_model.get


    # Testing min/max cooling/heating setpoints
    setpoints = TBD.heatingTemperatureSetpoints?(os_model)
    setpoints = TBD.coolingTemperatureSetpoints?(os_model) || setpoints
    expect(setpoints).to be(true)
    airloops = TBD.airLoopsHVAC?(os_model)
    expect(airloops).to be(true)

    os_model.getSpaces.each do |space|
      expect(space.thermalZone.empty?).to be(false)
      zone = space.thermalZone.get
      heat_spt = TBD.maxHeatScheduledSetpoint(zone)
      cool_spt = TBD.minCoolScheduledSetpoint(zone)
      expect(heat_spt.key?(:spt)).to be(true)
      expect(cool_spt.key?(:spt)).to be(true)
      heating = heat_spt[:spt]
      cooling = cool_spt[:spt]
      expect(TBD.plenum?(space, airloops, setpoints)).to be(false)
      if zone.nameString == "Office ZN"
        expect(heating).to be_within(0.1).of(21.1)
        expect(cooling).to be_within(0.1).of(23.9)
      else
        expect(heating).to be_within(0.1).of(21.7)
        expect(cooling).to be_within(0.1).of(24.4)
      end
    end

    argh[:option] = "(non thermal bridging)"                        # overridden
    argh[:io_path] = File.join(__dir__, "../json/midrise.json")
    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")
    json = TBD.process(os_model, argh)
    expect(json.is_a?(Hash)).to be(true)
    expect(json.key?(:io)).to be(true)
    expect(json.key?(:surfaces)).to be(true)
    io       = json[:io]
    surfaces = json[:surfaces]
    expect(TBD.status).to eq(0)
    expect(TBD.logs.empty?).to be(true)
    expect(io.nil?).to be(false)
    expect(io.is_a?(Hash)).to be(true)
    expect(io.empty?).to be(false)
    expect(surfaces.nil?).to be(false)
    expect(surfaces.is_a?(Hash)).to be(true)
    expect(surfaces.size).to eq(180)

    surfaces.each do |id, surface|
      expect(surface.key?(:conditioned)).to be(true)
      next unless surface[:conditioned]
      expect(surface.key?(:heating)).to be(true)
      expect(surface.key?(:cooling)).to be(true)
    end

    st1 = "Building Story 1"
    st2 = "Building Story 2"
    st3 = "Building Story 3"

    expect(io.key?(:stories)).to be(true)
    expect(io[:stories].size).to eq(3)
    io[:stories].each do |story|
      expect(story.key?(:id)).to be(true)
      expect(story[:id]).to eq(st1).or eq(st2).or eq(st3)
      expect(story.key?(:psi)).to be(true)
    end

    counter = 0
    surfaces.each do |id, surface|
      next unless surface.key?(:ratio)
      expect(surface.key?(:boundary)).to be(true)
      expect(surface[:boundary]).to eq("Outdoors")
      expect(surface.key?(:story)).to be(true)
      nom = surface[:story].nameString
      expect(nom).to eq(st1).or eq(st2).or eq(st3)
      expect(nom).to eq(st1) if id.include?("g ")
      expect(nom).to eq(st2) if id.include?("m ")
      expect(nom).to eq(st3) if id.include?("t ")
      expect(surface.key?(:edges)).to be(true)
      counter += 1

      # Illustrating that story-specific PSI set is used when only 1x story.
      surface[:edges].values.each do |edge|
        expect(edge.key?(:type)).to be(true)
        expect(edge.key?(:psi)).to be(true)
        next unless id.include?("Roof")
        expect(edge[:type]).to eq(:parapetconvex).or eq(:transition)
        next unless edge[:type] == :parapetconvex
        next if id == "t Roof C"
        expect(edge[:psi]).to be_within(0.01).of(0.178) # 57.3% of 0.311
      end

      # Illustrating that story-specific PSI set is used when only 1x story.
      surface[:edges].values.each do |edge|
        next unless id.include?("t ")
        next unless id.include?("Wall ")
        next unless edge[:type] == :parapetconvex
        next if id.include?(" C")
        expect(edge[:psi]).to be_within(0.01).of(0.133) # 42.7% of 0.311
      end

      # The shared :rimjoist between middle story and ground floor units could
      # either inherit the "Building Story 1" or "Building Story 2" :rimjoist
      # PSI values. TBD retains the most conductive PSI values in such cases.
      surface[:edges].values.each do |edge|
        next unless id.include?("m ")
        next unless id.include?("Wall ")
        next if id.include?(" C")
        next unless edge[:type] == :rimjoist

        # Inheriting "Building Story 1" :rimjoist PSI of 0.501 W/K per metre.
        # The SEA unit is above an office space below, which has curtain wall.
        # RSi of insulation layers (to derate):
        #   - office walls   : 0.740 m2.K/W (26.1%)
        #   - SEA walls      : 2.100 m2.K/W (73.9%)
        #
        #   - SEA walls      : 26.1% of 0.501 = 0.3702 W/K per metre
        #   - other walls    : 50.0% of 0.501 = 0.2505 W/K per metre
        if id == "m SWall SEA" || id == "m EWall SEA"
          expect(edge[:psi]).to be_within(0.002).of(0.3702)
        else
          expect(edge[:psi]).to be_within(0.002).of(0.2505)
        end
      end
    end
    expect(counter).to eq(51)
  end

  it "can handle parties" do
    TBD.clean!
    argh = {}

    translator = OpenStudio::OSVersion::VersionTranslator.new
    file  = File.join(__dir__, "files/osms/in/seb.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model.empty?).to be(false)
    model = model.get

    # Generate a new SurfacePropertyOtherSideCoefficients object.
    other = OpenStudio::Model::SurfacePropertyOtherSideCoefficients.new(model)
    other.setName("other_side_coefficients")
    expect(other.setZoneAirTemperatureCoefficient(1)).to be(true)

    # Reset outside boundary conditions for "open area wall 5" (and plenum wall
    # above) by assigning an "OtherSideCoefficients" object (no longer relying
    # on "Adiabatic" string).
    id1 = "Openarea 1 Wall 5"
    s1  = model.getSurfaceByName(id1)
    expect(s1.empty?).to be(false)
    s1  = s1.get
    expect(s1.setSurfacePropertyOtherSideCoefficients(other)).to be(true)
    expect(s1.outsideBoundaryCondition).to eq("OtherSideCoefficients")

    id2 = "Level0 Open area 1 Ceiling Plenum AbvClgPlnmWall 5"
    s2  = model.getSurfaceByName(id2)
    expect(s2.empty?).to be(false)
    s2  = s2.get
    expect(s2.setSurfacePropertyOtherSideCoefficients(other)).to be(true)
    expect(s2.outsideBoundaryCondition).to eq("OtherSideCoefficients")

    argh[:option     ] = "compliant"
    argh[:io_path    ] = File.join(__dir__, "../json/tbd_seb_n8.json")
    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")
    json = TBD.process(model, argh)
    expect(json.is_a?(Hash)).to be(true)
    expect(json.key?(:io)).to be(true)
    expect(json.key?(:surfaces)).to be(true)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.status).to eq(0)
    expect(TBD.logs.empty?).to be(true)
    expect(io.nil?).to be(false)
    expect(io.is_a?(Hash)).to be(true)
    expect(io.empty?).to be(false)
    expect(surfaces.nil?).to be(false)
    expect(surfaces.is_a?(Hash)).to be(true)
    expect(surfaces.size).to eq(56)

    ids = { a: "Entryway  Wall 4",
            b: "Entryway  Wall 5",
            c: "Entryway  Wall 6",
            d: "Entry way  DroppedCeiling",
            e: "Utility1 Wall 1",
            f: "Utility1 Wall 5",
            g: "Utility 1 DroppedCeiling",
            h: "Smalloffice 1 Wall 1",
            i: "Smalloffice 1 Wall 2",
            j: "Smalloffice 1 Wall 6",
            k: "Small office 1 DroppedCeiling",
            l: "Openarea 1 Wall 3",
            m: "Openarea 1 Wall 4",             # removed n: "Openarea 1 Wall 5"
            o: "Openarea 1 Wall 6",
            p: "Openarea 1 Wall 7",
            q: "Open area 1 DroppedCeiling" }.freeze

    surfaces.each do |id, surface|
      next if surface.key?(:edges)
      expect(ids.has_value?(id)).to be(false)
    end

    surfaces.each do |id, surface|
      next unless surface.key?(:edges)
      expect(ids.has_value?(id)).to be(true)
      expect(surface.key?(:heatloss)).to be(true)
      expect(surface.key?(:ratio)).to be(true)
      h = surface[:heatloss]

      s = model.getSurfaceByName(id)
      expect(s.empty?).to be(false)
      s = s.get
      expect(s.nameString).to eq(id)
      expect(s.isConstructionDefaulted).to be(false)
      expect(/ tbd/i.match(s.construction.get.nameString)).to_not eq(nil)
      expect(h).to be_within(0.01).of( 3.62) if id == ids[:a]
      expect(h).to be_within(0.01).of( 6.28) if id == ids[:b]
      expect(h).to be_within(0.01).of( 2.62) if id == ids[:c]
      expect(h).to be_within(0.01).of( 0.17) if id == ids[:d]
      expect(h).to be_within(0.01).of( 7.13) if id == ids[:e]
      expect(h).to be_within(0.01).of( 7.09) if id == ids[:f]
      expect(h).to be_within(0.01).of( 0.20) if id == ids[:g]
      expect(h).to be_within(0.01).of( 7.94) if id == ids[:h]
      expect(h).to be_within(0.01).of( 5.17) if id == ids[:i]
      expect(h).to be_within(0.01).of( 5.01) if id == ids[:j]
      expect(h).to be_within(0.01).of( 0.22) if id == ids[:k]
      expect(h).to be_within(0.01).of( 2.47) if id == ids[:l]
      expect(h).to be_within(0.01).of( 4.03) if id == ids[:m] # 3.11
      expect(h).to be_within(0.01).of( 4.43) if id == ids[:n]
      expect(h).to be_within(0.01).of( 4.27) if id == ids[:o] # 3.35
      expect(h).to be_within(0.01).of( 2.12) if id == ids[:p]
      expect(h).to be_within(0.01).of( 2.16) if id == ids[:q] # 0.31

      # The 2x side walls linked to the new party wall "Openarea 1 Wall 5":
      #   - "Openarea 1 Wall 4"
      #   - "Openarea 1 Wall 6"
      # ... have 1x half-corner replaced by 100% of a party wall edge, hence
      # the increase in extra heat loss.
      #
      # The "Open area 1 DroppedCeiling" has almost a 7x increase in extra heat
      # loss. It used to take ~7.6% of the parapet PSI it shared with "Wall 5".
      # As the latter is no longer a deratable surface (i.e., a party wall), the
      # dropped ceiling hence takes on 100% of the party wall edge it still
      # shares with "Wall 5".

      c = s.construction
      expect(c.empty?).to be(false)
      c = c.get.to_LayeredConstruction
      expect(c.empty?).to be(false)
      c = c.get
      i = 0
      i = 2 if s.outsideBoundaryCondition == "Outdoors"
      expect(c.layers[i].nameString.include?("m tbd")).to be(true)
    end
  end

  it "can factor in unenclosed space such as attics" do
    TBD.clean!
    argh = {}

    translator = OpenStudio::OSVersion::VersionTranslator.new
    file = File.join(__dir__, "files/osms/in/smalloffice.osm")
    path = OpenStudio::Path.new(file)
    os_model = translator.loadModel(path)
    expect(os_model.empty?).to be(false)
    os_model = os_model.get

    expect(TBD.airLoopsHVAC?(os_model)).to be(true)
    expect(TBD.heatingTemperatureSetpoints?(os_model)).to be(true)
    expect(TBD.coolingTemperatureSetpoints?(os_model)).to be(true)

    argh[:option] = "compliant"        # superseded by :building PSI set on file
    argh[:io_path] = File.join(__dir__, "../json/tbd_smalloffice.json")
    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")
    json = TBD.process(os_model, argh)
    expect(json.is_a?(Hash)).to be(true)
    expect(json.key?(:io)).to be(true)
    expect(json.key?(:surfaces)).to be(true)
    io       = json[:io]
    surfaces = json[:surfaces]
    expect(TBD.status).to eq(0)
    expect(TBD.logs.empty?).to be(true)
    expect(io.nil?).to be(false)
    expect(io.is_a?(Hash)).to be(true)
    expect(io.empty?).to be(false)
    expect(surfaces.nil?).to be(false)
    expect(surfaces.is_a?(Hash)).to be(true)
    expect(surfaces.size).to eq(43)
    expect(io[:edges].size).to eq(105)

    # Check derating of attic floor (5x surfaces)
    os_model.getSpaces.each do |space|
      next unless space.nameString == "Attic"
      expect(space.thermalZone.empty?).to be(false)
      zone = space.thermalZone.get
      expect(zone.isPlenum).to be(false)
      expect(zone.canBePlenum).to be(true)

      space.surfaces.each do |s|
        id = s.nameString
        expect(surfaces.key?(id)).to be(true)
        expect(surfaces[id].key?(:space)).to be(true)
        next unless surfaces[id][:space].nameString == "Attic"
        expect(surfaces[id][:conditioned]).to be(false)
        next if surfaces[id][:boundary] == "Outdoors"
        expect(s.adjacentSurface.empty?).to be(false)
        adjacent = s.adjacentSurface.get.nameString
        expect(surfaces.key?(adjacent)).to be(true)
        expect(surfaces[id][:boundary]).to eq(adjacent)
        expect(surfaces[adjacent][:conditioned]).to be(true)
      end
    end

    # Check derating of ceilings (below attic).
    surfaces.each do |id, surface|
      next unless surface.key?(:ratio)
      next if surface[:boundary].downcase == "outdoors"
      expect(surface.key?(:heatloss)).to be(true)
      heatloss = surface[:heatloss]
      expect(heatloss.abs).to be > 0
      expect(id.include?("Perimeter_ZN_")).to be(true)
      expect(id.include?("_ceiling")).to be(true)
    end

    # Check derating of outdoor-facing walls
    surfaces.each do |id, surface|
      next unless surface.key?(:ratio)
      next unless surface[:boundary].downcase == "outdoors"
      expect(surface.key?(:heatloss)).to be(true)
      heatloss = surface[:heatloss]
      expect(heatloss.abs).to be > 0
    end
  end

  it "can factor in heads, sills and jambs" do
    TBD.clean!
    argh = {}

    translator = OpenStudio::OSVersion::VersionTranslator.new
    file = File.join(__dir__, "files/osms/in/warehouse.osm")
    path = OpenStudio::Path.new(file)
    os_model = translator.loadModel(path)
    expect(os_model.empty?).to be(false)
    os_model = os_model.get

    argh[:option] = "compliant"        # superseded by :building PSI set on file
    argh[:io_path] = File.join(__dir__, "../json/tbd_warehouse7.json")
    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")
    json = TBD.process(os_model, argh)
    expect(json.is_a?(Hash)).to be(true)
    expect(json.key?(:io)).to be(true)
    expect(json.key?(:surfaces)).to be(true)
    io       = json[:io]
    surfaces = json[:surfaces]
    expect(TBD.status).to eq(0)
    expect(TBD.logs.empty?).to be(true)
    expect(io.nil?).to be(false)
    expect(io.is_a?(Hash)).to be(true)
    expect(io.empty?).to be(false)
    expect(surfaces.nil?).to be(false)
    expect(surfaces.is_a?(Hash)).to be(true)
    expect(surfaces.size).to eq(23)

    nom = "Bulk Storage Roof"
    n_transitions  = 0
    n_parapets     = 0
    n_fen_edges    = 0
    n_heads        = 0
    n_sills        = 0
    n_jambs        = 0

    t1 = :transition
    t2 = :parapetconvex
    t3 = :fenestration
    t4 = :head
    t5 = :sill
    t6 = :jamb

    surfaces.each do |id, surface|
      next unless surface[:boundary].downcase == "outdoors"
      next unless surface.key?(:ratio)
      expect(surface.key?(:heatloss)).to be(true)
      heatloss = surface[:heatloss]
      expect(heatloss.abs).to be > 0
      next unless id == nom
      expect(surfaces[id].key?(:edges)).to be(true)
      expect(surfaces[id][:edges].size).to eq(132)

      surfaces[id][:edges].values.each do |edge|
        expect(edge.key?(:type)).to be(true)
        t = edge[:type]
        expect(t).to eq(t1).or eq(t2).or eq(t3).or eq(t4).or eq(t5).or eq(t6)
        n_transitions += 1 if edge[:type] == t1
        n_parapets    += 1 if edge[:type] == t2
        n_fen_edges   += 1 if edge[:type] == t3
        n_heads       += 1 if edge[:type] == t4
        n_sills       += 1 if edge[:type] == t5
        n_jambs       += 1 if edge[:type] == t6
      end
    end

    expect(n_transitions).to eq(1)
    expect(n_parapets).to eq(3)
    expect(n_fen_edges).to eq(0)
    expect(n_heads).to eq(0)
    expect(n_sills).to eq(0)
    expect(n_jambs).to eq(128)
  end

  it "has a PSI class" do
    TBD.clean!
    argh = {}

    psi = TBD::PSI.new
    expect(psi.set.key?("poor (BETBG)")).to be(true)
    expect(psi.complete?("poor (BETBG)")).to be(true)
    expect(TBD.status).to eq(0)
    expect(TBD.logs.size).to eq(0)

    expect(psi.set.key?("new set")).to be(false)
    expect(psi.complete?("new set")).to be(false)
    expect(TBD.status).to eq(ERR)
    expect(TBD.logs.size).to eq(1)
    TBD.clean!

    new_set =
    {
      id:            "new set",
      rimjoist:      0.000,
      parapet:       0.000,
      fenestration:  0.000,
      cornerconcave: 0.000,
      cornerconvex:  0.000,
      balcony:       0.000,
      party:         0.000,
      grade:         0.000
    }
    expect(psi.append(new_set)).to be(true)
    expect(psi.set.key?("new set")).to be(true)
    expect(psi.complete?("new set")).to be(true)
    expect(TBD.status).to eq(0)
    expect(TBD.logs.size).to eq(0)

    expect(psi.set["new set"][:grade]).to eq(0)
    new_set[:grade] = 1.0
    expect(psi.append(new_set)).to be(false)  # does not override existing value
    expect(TBD.status).to eq(ERR)
    expect(TBD.logs.size).to eq(1)
    expect(psi.set["new set"][:grade]).to eq(0)

    expect(psi.set.key?("incomplete set")).to be(false)
    expect(psi.complete?("incomplete set")).to be(false)

    incomplete_set =
    {
      id:           "incomplete set",
      grade:        0.000  #
    }

    expect(psi.append(incomplete_set)).to be(true)
    expect(psi.set.key?("incomplete set")).to be(true)
    expect(psi.complete?("incomplete set")).to be(false)

    # Fenestration edge variant - complete, partial, empty
    expect(psi.set.key?("all sills")).to be(false)

    all_sills =
    {
      id:            "all sills",
      fenestration:  0.391,
      head:          0.381,
      headconcave:   0.382,
      headconvex:    0.383,
      sill:          0.371,
      sillconcave:   0.372,
      sillconvex:    0.373,
      jamb:          0.361,
      jambconcave:   0.362,
      jambconvex:    0.363,
      rimjoist:      0.001,
      parapet:       0.002,
      corner:        0.003,
      balcony:       0.004,
      party:         0.005,
      grade:         0.006
    }

    expect(psi.append(all_sills)).to be(true)
    expect(psi.set.key?("all sills")).to be(true)
    expect(psi.complete?("all sills")).to be(true)
    shorts = psi.shorthands("all sills")
    expect(shorts[:has].empty?).to be(false)
    expect(shorts[:val].empty?).to be(false)
    holds = shorts[:has]
    vals  = shorts[:val]
    expect(holds[:fenestration]).to be(true)
    expect(vals[:sill]).to be_within(0.001).of(0.371)
    expect(vals[:sillconcave]).to be_within(0.001).of(0.372)
    expect(vals[:sillconvex]).to be_within(0.001).of(0.373)

    expect(psi.set.key?("partial sills")).to be(false)

    partial_sills =
    {
      id:            "partial sills",
      fenestration:  0.391,
      head:          0.381,
      headconcave:   0.382,
      headconvex:    0.383,
      sill:          0.371,
      sillconcave:   0.372,
      # sillconvex:    0.373,                      # dropping the convex variant
      jamb:          0.361,
      jambconcave:   0.362,
      jambconvex:    0.363,
      rimjoist:      0.001,
      parapet:       0.002,
      corner:        0.003,
      balcony:       0.004,
      party:         0.005,
      grade:         0.006
    }
    expect(psi.append(partial_sills)).to be(true)
    expect(psi.set.key?("partial sills")).to be(true)
    expect(psi.complete?("partial sills")).to be(true)   # can be a building set
    shorts = psi.shorthands("partial sills")
    expect(shorts[:has].empty?).to be(false)
    expect(shorts[:val].empty?).to be(false)
    holds = shorts[:has]
    vals  = shorts[:val]
    expect(holds[:sillconvex]).to be(false)                # absent from PSI set
    expect(vals[:sill]).to        be_within(0.001).of(0.371)
    expect(vals[:sillconcave]).to be_within(0.001).of(0.372)
    expect(vals[:sillconvex]).to  be_within(0.001).of(0.371)    # inherits :sill

    expect(psi.set.key?("no sills")).to be(false)
    no_sills =
    {
      id:            "no sills",
      fenestration:  0.391,
      head:          0.381,
      headconcave:   0.382,
      headconvex:    0.383,
      # sill:          0.371,                     # dropping the concave variant
      # sillconcave:   0.372,                     # dropping the concave variant
      # sillconvex:    0.373,                      # dropping the convex variant
      jamb:          0.361,
      jambconcave:   0.362,
      jambconvex:    0.363,
      rimjoist:      0.001,
      parapet:       0.002,
      corner:        0.003,
      balcony:       0.004,
      party:         0.005,
      grade:         0.006
    }

    expect(psi.append(no_sills)).to be(true)
    expect(psi.set.key?("no sills")).to be(true)
    expect(psi.complete?("no sills")).to be(true)        # can be a building set
    shorts = psi.shorthands("no sills")
    expect(shorts[:has].empty?).to be(false)
    expect(shorts[:val].empty?).to be(false)
    holds = shorts[:has]
    vals  = shorts[:val]
    expect(holds[:sill]).to be(false)                      # absent from PSI set
    expect(holds[:sillconcave]).to be(false)               # absent from PSI set
    expect(holds[:sillconvex]).to be(false)                # absent from PSI set
    expect(vals[:sill]).to        be_within(0.001).of(0.391)
    expect(vals[:sillconcave]).to be_within(0.001).of(0.391)
    expect(vals[:sillconvex]).to  be_within(0.001).of(0.391)     # :fenestration
  end

  it "can flag polygon 'fits?' & 'overlaps?' (frame & dividers)" do
    model = OpenStudio::Model::Model.new

    # 10m x 10m parent vertical (wall) surface.
    vec = OpenStudio::Point3dVector.new
    vec << OpenStudio::Point3d.new(  0,  0, 10)
    vec << OpenStudio::Point3d.new(  0,  0,  0)
    vec << OpenStudio::Point3d.new( 10,  0,  0)
    vec << OpenStudio::Point3d.new( 10,  0, 10)
    wall = OpenStudio::Model::Surface.new(vec, model)
    ft = OpenStudio::Transformation::alignFace(wall.vertices).inverse
    ft_wall  = TBD.flatZ( (ft * wall.vertices).reverse )

    # 1m x 2m corner door (with 2x edges along wall edges)
    vec = OpenStudio::Point3dVector.new
    vec << OpenStudio::Point3d.new(  0,  0,  2)
    vec << OpenStudio::Point3d.new(  0,  0,  0)
    vec << OpenStudio::Point3d.new(  1,  0,  0)
    vec << OpenStudio::Point3d.new(  1,  0,  2)
    door1 = OpenStudio::Model::SubSurface.new(vec, model)
    ft_door1 = TBD.flatZ( (ft * door1.vertices).reverse )

    union = OpenStudio::join(ft_wall, ft_door1, TOL2)
    expect(union.empty?).to be(false)
    union = union.get
    area = OpenStudio::getArea(union)
    expect(area.empty?).to be(false)
    area = area.get
    expect(area).to be_within(0.01).of(wall.grossArea)

    # Door1 fits?, overlaps?
    TBD.clean!
    expect(TBD.fits?(door1.vertices, wall.vertices)).to be(true)
    expect(TBD.overlaps?(door1.vertices, wall.vertices)).to be(true)
    expect(TBD.status).to eq(0)

    # Order of arguments matter.
    expect(TBD.fits?(wall.vertices, door1.vertices)).to be(false)
    expect(TBD.overlaps?(wall.vertices, door1.vertices)).to be(true)
    expect(TBD.status).to eq(0)

    # Another 1m x 2m corner door, yet entirely beyond the wall surface.
    vec = OpenStudio::Point3dVector.new
    vec << OpenStudio::Point3d.new( 16,  0,  2)
    vec << OpenStudio::Point3d.new( 16,  0,  0)
    vec << OpenStudio::Point3d.new( 17,  0,  0)
    vec << OpenStudio::Point3d.new( 17,  0,  2)
    door2 = OpenStudio::Model::SubSurface.new(vec, model)
    ft_door2 = TBD.flatZ( (ft * door2.vertices).reverse )
    union = OpenStudio::join(ft_wall, ft_door2, TOL2)
    expect(union.empty?).to be(true)

    # Door2 fits?, overlaps?
    expect(TBD.fits?(door2.vertices, wall.vertices)).to be(false)
    expect(TBD.overlaps?(door2.vertices, wall.vertices)).to be(false)
    expect(TBD.status).to eq(0)

    # # Order of arguments doesn't matter.
    expect(TBD.fits?(wall.vertices, door2.vertices)).to be(false)
    expect(TBD.overlaps?(wall.vertices, door2.vertices)).to be(false)
    expect(TBD.status).to eq(0)

    # Top-right corner 2m x 2m window, overlapping top-right corner of wall.
    vec = OpenStudio::Point3dVector.new
    vec << OpenStudio::Point3d.new(  9,  0, 11)
    vec << OpenStudio::Point3d.new(  9,  0,  9)
    vec << OpenStudio::Point3d.new( 11,  0,  9)
    vec << OpenStudio::Point3d.new( 11,  0, 11)
    window = OpenStudio::Model::SubSurface.new(vec, model)
    ft_window = TBD.flatZ( (ft * window.vertices).reverse )
    union = OpenStudio::join(ft_wall, ft_window, TOL2)
    expect(union.empty?).to be(false)
    union = union.get
    area = OpenStudio::getArea(union)
    expect(area.empty?).to be(false)
    area = area.get
    expect(area).to be_within(0.01).of(103)

    # Window fits?, overlaps?
    expect(TBD.fits?(window.vertices, wall.vertices)).to be(false)
    expect(TBD.overlaps?(window.vertices, wall.vertices)).to be(true)
    expect(TBD.status).to eq(0)

    expect(TBD.fits?(wall.vertices, window.vertices)).to be(false)
    expect(TBD.overlaps?(wall.vertices, window.vertices)).to be(true)
    expect(TBD.status).to eq(0)

    # A glazed surface, entirely encompassing the wall.
    vec = OpenStudio::Point3dVector.new
    vec << OpenStudio::Point3d.new(  0,  0, 10)
    vec << OpenStudio::Point3d.new(  0,  0,  0)
    vec << OpenStudio::Point3d.new( 10,  0,  0)
    vec << OpenStudio::Point3d.new( 10,  0, 10)
    glazing = OpenStudio::Model::SubSurface.new(vec, model)

    # Glazing fits?, overlaps?
    expect(TBD.fits?(glazing.vertices, wall.vertices)).to be(true)
    expect(TBD.overlaps?(glazing.vertices, wall.vertices)).to be(true)
    expect(TBD.status).to eq(0)

    expect(TBD.fits?(wall.vertices, glazing.vertices)).to be(true)
    expect(TBD.overlaps?(wall.vertices, glazing.vertices)).to be(true)
    expect(TBD.status).to eq(0)
  end

  it "can factor-in Frame & Divider (F&D) objects" do
    TBD.clean!

    version = OpenStudio.openStudioVersion.split(".").map(&:to_i).join.to_i

    # Aide-mémoire: attributes/objects subsurfaces are allowed to have/be.
    model = OpenStudio::Model::Model.new
    vec   = OpenStudio::Point3dVector.new
    vec  << OpenStudio::Point3d.new(  2.00,  0.00,  3.00)
    vec  << OpenStudio::Point3d.new(  2.00,  0.00,  1.00)
    vec  << OpenStudio::Point3d.new(  4.00,  0.00,  1.00)
    vec  << OpenStudio::Point3d.new(  4.00,  0.00,  3.00)
    sub   = OpenStudio::Model::SubSurface.new(vec, model)

    OpenStudio::Model::SubSurface.validSubSurfaceTypeValues.each do |type|
      expect(sub.setSubSurfaceType(type)).to be(true)
      # puts sub.subSurfaceType
      # FixedWindow
      # OperableWindow
      # Door
      # GlassDoor
      # OverheadDoor
      # Skylight
      # TubularDaylightDome
      # TubularDaylightDiffuser
      case type
      when "FixedWindow"
        expect(sub.allowWindowPropertyFrameAndDivider   ).to be(true )
        next if version < 330
        expect(sub.allowDaylightingDeviceTubularDiffuser).to be(false)
        expect(sub.allowDaylightingDeviceTubularDome    ).to be(false)
      when "OperableWindow"
        expect(sub.allowWindowPropertyFrameAndDivider   ).to be(true )
        next if version < 330
        expect(sub.allowDaylightingDeviceTubularDiffuser).to be(false)
        expect(sub.allowDaylightingDeviceTubularDome    ).to be(false)
      when "Door"
        expect(sub.allowWindowPropertyFrameAndDivider   ).to be(false)
        next if version < 330
        expect(sub.allowDaylightingDeviceTubularDiffuser).to be(false)
        expect(sub.allowDaylightingDeviceTubularDome    ).to be(false)
      when "GlassDoor"
        expect(sub.allowWindowPropertyFrameAndDivider   ).to be(true )
        next if version < 330
        expect(sub.allowDaylightingDeviceTubularDiffuser).to be(false)
        expect(sub.allowDaylightingDeviceTubularDome    ).to be(false)
      when "OverheadDoor"
        expect(sub.allowWindowPropertyFrameAndDivider   ).to be(false)
        next if version < 330
        expect(sub.allowDaylightingDeviceTubularDiffuser).to be(false)
        expect(sub.allowDaylightingDeviceTubularDome    ).to be(false)
      when "Skylight"
        if version < 321
          expect(sub.allowWindowPropertyFrameAndDivider   ).to be(false)
        else
          expect(sub.allowWindowPropertyFrameAndDivider   ).to be(true )
        end

        next if version < 330
        expect(sub.allowDaylightingDeviceTubularDiffuser).to be(false)
        expect(sub.allowDaylightingDeviceTubularDome    ).to be(false)
      when "TubularDaylightDome"
        expect(sub.allowWindowPropertyFrameAndDivider   ).to be(false)
        next if version < 330
        expect(sub.allowDaylightingDeviceTubularDiffuser).to be(false)
        expect(sub.allowDaylightingDeviceTubularDome    ).to be(true )
      when "TubularDaylightDiffuser"
        expect(sub.allowWindowPropertyFrameAndDivider   ).to be(false)
        next if version < 330
        expect(sub.allowDaylightingDeviceTubularDiffuser).to be(true )
        expect(sub.allowDaylightingDeviceTubularDome    ).to be(false)
      else
        puts "Unknown SubSurfaceType: #{type} !"
        expect(true).to be(false)
      end
    end

    argh = {}

    translator = OpenStudio::OSVersion::VersionTranslator.new
    file = File.join(__dir__, "files/osms/in/warehouse.osm")
    path = OpenStudio::Path.new(file)
    os_model = translator.loadModel(path)
    expect(os_model.empty?).to be(false)
    os_model = os_model.get

    nom = "Office Front Wall"
    name = "Office Front Wall Window 1"

    argh[:option] = "poor (BETBG)"
    argh[:io_path] = File.join(__dir__, "../json/tbd_warehouse8.json")
    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")
    json = TBD.process(os_model, argh)
    expect(json.is_a?(Hash)).to be(true)
    expect(json.key?(:io)).to be(true)
    expect(json.key?(:surfaces)).to be(true)
    io       = json[:io]
    surfaces = json[:surfaces]
    expect(TBD.status).to eq(0)
    expect(TBD.logs.empty?).to be(true)
    expect(io.nil?).to be(false)
    expect(io.is_a?(Hash)).to be(true)
    expect(io.empty?).to be(false)
    expect(surfaces.nil?).to be(false)
    expect(surfaces.is_a?(Hash)).to be(true)
    expect(surfaces.size).to eq(23)

    n_transitions  = 0
    n_fen_edges    = 0
    n_heads        = 0
    n_sills        = 0
    n_jambs        = 0
    n_grades       = 0
    n_corners      = 0
    n_rimjoists    = 0
    fen_length     = 0

    t1 = :transition
    t2 = :fenestration
    t3 = :head
    t4 = :sill
    t5 = :jamb
    t6 = :gradeconvex
    t7 = :cornerconvex
    t8 = :rimjoist

    surfaces.each do |id, surface|
      next unless surface[:boundary].downcase == "outdoors"
      next unless surface.key?(:ratio)
      expect(surface.key?(:heatloss)).to be(true)
      heatloss = surface[:heatloss]
      expect(heatloss.abs).to be > 0
      next unless id == nom
      expect(heatloss).to be_within(0.1).of(50.2)
      expect(surface.key?(:edges)).to be(true)
      expect(surface[:edges].size).to eq(17)

      surface[:edges].values.each do |edge|
        expect(edge.key?(:type)).to be(true)
        t = edge[:type]
        n_transitions += 1 if edge[:type] == t1
        n_fen_edges   += 1 if edge[:type] == t2
        n_heads       += 1 if edge[:type] == t3
        n_sills       += 1 if edge[:type] == t4
        n_jambs       += 1 if edge[:type] == t5
        n_grades      += 1 if edge[:type] == t6
        n_corners     += 1 if edge[:type] == t7
        n_rimjoists   += 1 if edge[:type] == t8
        fen_length    += edge[:length] if edge[:type] == t2
      end
    end

    expect(n_transitions).to eq(1)
    expect(n_fen_edges  ).to eq(4)                  # Office Front Wall Window 1
    expect(n_heads      ).to eq(2)                             # Window 2 & door
    expect(n_sills      ).to eq(1)                                    # Window 2
    expect(n_jambs      ).to eq(4)                             # Window 2 & door
    expect(n_grades     ).to eq(3)                         # including door sill
    expect(n_corners    ).to eq(1)
    expect(n_rimjoists  ).to eq(1)

    expect(fen_length).to be_within(0.01).of(10.36)         # Window 1 perimeter
    front = os_model.getSurfaceByName(nom)
    expect(front.empty?).to be(false)
    front = front.get
    expect(front.netArea).to be_within(0.01).of(95.49)
    expect(front.grossArea).to be_within(0.01).of(110.54)
    # The above net & gross areas reflect cases without frame & divider objects
    # This is also what would be reported by SketchUp, for instance.

    # Open another warehouse model and add/assign a Frame & Divider object.
    translator = OpenStudio::OSVersion::VersionTranslator.new
    file = File.join(__dir__, "files/osms/in/warehouse.osm")
    path = OpenStudio::Path.new(file)
    os_model_FD = translator.loadModel(path)
    expect(os_model_FD.empty?).to be(false)
    os_model_FD = os_model_FD.get

    # Adding/validating Frame & Divider object.
    fd = OpenStudio::Model::WindowPropertyFrameAndDivider.new(os_model_FD)
    width = 0.03
    expect(fd.setFrameWidth(width)).to be(true)   # 30mm (narrow) around glazing
    expect(fd.setFrameConductance(2.500)).to be(true)
    window_FD = os_model_FD.getSubSurfaceByName(name)
    expect(window_FD.empty?).to be(false)
    window_FD = window_FD.get
    expect(window_FD.allowWindowPropertyFrameAndDivider).to be(true)
    expect(window_FD.setWindowPropertyFrameAndDivider(fd)).to be(true)
    width2 = window_FD.windowPropertyFrameAndDivider.get.frameWidth
    expect(width2).to be_within(0.001).of(width)               # good so far ...

    expect(window_FD.netArea).to be_within(0.01).of(5.58)
    expect(window_FD.grossArea).to be_within(0.01).of(5.58)      # not 5.89 (OK)
    front_FD = os_model_FD.getSurfaceByName(nom)
    expect(front_FD.empty?).to be(false)
    front_FD = front_FD.get
    expect(front_FD.grossArea).to be_within(0.01).of(110.54)        # this is OK

    unless version < 340
      # As of v3.4.0, SDK-reported WWR ratio calculations will ignore added
      # frame areas if associated subsurfaces no longer 'fit' within the
      # parent surface polygon, or overlap any of their siblings. For v340 and
      # up, one can only rely on SDK-reported WWR to safely determine TRUE net
      # area for a parent surface.
      #
      # For older SDK versions, TBD/OSut methods are required to do the same.
      #
      #   https://github.com/NREL/OpenStudio/issues/4361
      #
      # Here, the parent wall net area reflects the added (valid) frame areas.
      # However, this net area reports erroneous values when F&D objects
      # 'conflict', e.g. they don't fit in, or they overlap their siblings.
      expect(window_FD.roughOpeningArea).to be_within(0.01).of(5.89)
      expect(front_FD.netArea).to be_within(0.01).of(95.17)           # great !!
      expect(front_FD.windowToWallRatio).to be_within(0.01).of(0.104)       # !!
    else
      expect(front_FD.netArea).to be_within(0.01).of(95.49)             # !95.17
      expect(front_FD.windowToWallRatio).to be_within(0.01).of(0.101)   # !0.104
    end

    # If one runs an OpenStudio +v3.4 simulation with the exported file below
    # ("os_model_FD.osm"), EnergyPlus will correctly report (e.g. eplustbl.htm)
    # a building WWR (gross window-wall ratio) of 72% (vs 71% without F&D), due
    # to the slight increase in area of the "Office Front Wall Window 1" (from
    # 5.58 m2 to 5.89 m2). The report clearly distinguishes between the revised
    # glazing area of 5.58 m2 vs a new framing area of 0.31 m2 for this window.
    # Finally, the parent surface "Office Front Wall" area will also be
    # correctly reported as 95.17 m2 (vs 95.49 m2). So OpenStudio is correctly
    # forward translating the subsurface and linked Frame & Divider objects to
    # EnergyPlus (triangular subsurfaces not tested).
    #
    # For prior versions to v3.4, there are discrepencies between the net area
    # of the "Office Front Wall" reported by the OpenStudio API vs EnergyPlus.
    # This may seem minor when looking at the numbers above, but keep in mind a
    # single glazed subsurface is modified for this comparison. This difference
    # could easily reach 5% to 10% for models with many windows, especially
    # those with narrow aspect ratios (lots of framing).
    #
    # ... subsurface.netArea calculation here could be reconsidered :
    #
    #   https://github.com/NREL/OpenStudio/blob/
    #   70a5549c439eda69d6c514a7275254f71f7e3d2b/src/model/Surface.cpp#L1446
    pth = File.join(__dir__, "files/osms/out/os_model_FD.osm")
    os_model_FD.save(pth, true)

    argh[:option] = "poor (BETBG)"
    argh[:io_path] = File.join(__dir__, "../json/tbd_warehouse8.json")
    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")
    json = TBD.process(os_model_FD, argh)
    expect(json.is_a?(Hash)).to be(true)
    expect(json.key?(:io)).to be(true)
    expect(json.key?(:surfaces)).to be(true)
    io       = json[:io]
    surfaces = json[:surfaces]
    puts TBD.logs
    expect(TBD.status).to eq(0)
    expect(TBD.logs.empty?).to be(true)
    expect(io.nil?).to be(false)
    expect(io.is_a?(Hash)).to be(true)
    expect(io.empty?).to be(false)
    expect(surfaces.nil?).to be(false)
    expect(surfaces.is_a?(Hash)).to be(true)
    expect(surfaces.size).to eq(23)

    # TBD calling on workarounds.
    net_area   = surfaces[nom][:net]
    gross_area = surfaces[nom][:gross]
    expect(net_area).to be_within(0.01).of(95.17)                  # ! API 95.49
    expect(gross_area).to be_within(0.01).of(110.54)                      # same

    expect(surfaces[nom].key?(:windows)).to be(true)
    expect(surfaces[nom][:windows].size).to eq(2)

    surfaces[nom][:windows].each do |i, window|
      expect(window.key?(:points)).to be(true)
      expect(window[:points].size).to eq(4)

      if i == name
        expect(window.key?(:gross)).to be(true)
        expect(window[:gross]).to be_within(0.01).of(5.89)          # ! API 5.58
      end
    end

    # Adding a clerestory window, slightly above "Office Front Wall Window 1",
    # to test/validate overlapping cases. Starting with a safe case.
    cl_v = OpenStudio::Point3dVector.new
    cl_v << OpenStudio::Point3d.new( 3.66, 0.00, 4.00)
    cl_v << OpenStudio::Point3d.new( 3.66, 0.00, 2.47)
    cl_v << OpenStudio::Point3d.new( 7.31, 0.00, 2.47)
    cl_v << OpenStudio::Point3d.new( 7.31, 0.00, 4.00)
    clerestory = OpenStudio::Model::SubSurface.new(cl_v, os_model_FD)
    clerestory.setName("clerestory")
    expect(clerestory.setSurface(front_FD)).to be(true)
    expect(clerestory.setSubSurfaceType("FixedWindow")).to be(true)
    # ... reminder: set subsurface type AFTER setting its parent surface.

    argh[:option] = "poor (BETBG)"
    json = TBD.process(os_model_FD, argh)
    expect(json.is_a?(Hash)).to be(true)
    expect(json.key?(:io)).to be(true)
    expect(json.key?(:surfaces)).to be(true)
    io       = json[:io]
    surfaces = json[:surfaces]
    expect(TBD.status).to eq(WRN)           # surfaces have already been derated
    expect(TBD.logs.size).to eq(12)
    expect(io.nil?).to be(false)
    expect(io.is_a?(Hash)).to be(true)
    expect(io.empty?).to be(false)
    expect(surfaces.nil?).to be(false)
    expect(surfaces.is_a?(Hash)).to be(true)
    expect(surfaces.size).to eq(23)
    expect(surfaces.key?(nom)).to be(true)
    expect(surfaces[nom].key?(:windows)).to be(true)
    wins = surfaces[nom][:windows]
    expect(wins.size).to eq(3)
    expect(wins.key?("clerestory")).to be(true)
    expect(wins.key?(name)).to be(true)
    expect(wins["clerestory"].key?(:points)).to be(true)
    expect(wins[name].key?(:points)).to be(true)

    v1 = window_FD.vertices              # original OSM vertices for window
    f1 = TBD.offset(v1, width, 300)      # offset vertices, forcing v300 version
    expect(f1.is_a?(OpenStudio::Point3dVector)).to be(true)
    expect(f1.size).to eq(4)
    f1.each { |f| expect(f.is_a?(OpenStudio::Point3d)).to be(true) }
    f1area = OpenStudio.getArea(f1)
    expect(f1area.empty?).to be(false)
    f1area = f1area.get
    expect(f1area).to be_within(TOL).of(5.89)
    expect(f1area).to be_within(TOL).of(wins[name][:area])
    expect(f1area).to be_within(TOL).of(wins[name][:gross])

    # For SDK versions prior to v321, the offset vertices are generated in the
    # right order with respect to the original subsurface vertices.
    expect((f1[0].x - v1[0].x).abs).to be_within(0.01).of(width)
    expect((f1[1].x - v1[1].x).abs).to be_within(0.01).of(width)
    expect((f1[2].x - v1[2].x).abs).to be_within(0.01).of(width)
    expect((f1[3].x - v1[3].x).abs).to be_within(0.01).of(width)
    expect((f1[0].y - v1[0].y).abs).to be_within(0.01).of(0)
    expect((f1[1].y - v1[1].y).abs).to be_within(0.01).of(0)
    expect((f1[2].y - v1[2].y).abs).to be_within(0.01).of(0)
    expect((f1[3].y - v1[3].y).abs).to be_within(0.01).of(0)
    expect((f1[0].z - v1[0].z).abs).to be_within(0.01).of(width)
    expect((f1[1].z - v1[1].z).abs).to be_within(0.01).of(width)
    expect((f1[2].z - v1[2].z).abs).to be_within(0.01).of(width)
    expect((f1[3].z - v1[3].z).abs).to be_within(0.01).of(width)

    v2 = clerestory.vertices
    p2 = wins["clerestory"][:points]             # same as original OSM vertices

    expect((p2[0].x - v2[0].x).abs).to be_within(0.01).of(0)
    expect((p2[1].x - v2[1].x).abs).to be_within(0.01).of(0)
    expect((p2[2].x - v2[2].x).abs).to be_within(0.01).of(0)
    expect((p2[3].x - v2[3].x).abs).to be_within(0.01).of(0)
    expect((p2[0].y - v2[0].y).abs).to be_within(0.01).of(0)
    expect((p2[1].y - v2[1].y).abs).to be_within(0.01).of(0)
    expect((p2[2].y - v2[2].y).abs).to be_within(0.01).of(0)
    expect((p2[3].y - v2[3].y).abs).to be_within(0.01).of(0)
    expect((p2[0].z - v2[0].z).abs).to be_within(0.01).of(0)
    expect((p2[1].z - v2[1].z).abs).to be_within(0.01).of(0)
    expect((p2[2].z - v2[2].z).abs).to be_within(0.01).of(0)
    expect((p2[3].z - v2[3].z).abs).to be_within(0.01).of(0)

    # In addition, the top of the "Office Front Wall Window 1" is aligned with
    # the bottom of the clerestory, i.e. no conflicts between siblings.
    expect((f1[0].z - p2[1].z).abs).to be_within(0.01).of(0)
    expect((f1[3].z - p2[2].z).abs).to be_within(0.01).of(0)
    expect(TBD.status).to eq(WRN)

    # Testing both 'fits?' & 'overlaps?' functions.
    TBD.clean!
    vec2 = OpenStudio::Point3dVector.new
    p2.each { |p| vec2 << OpenStudio::Point3d.new(p.x, p.y, p.z) }
    expect(TBD.fits?(f1, vec2)).to be(false)
    expect(TBD.overlaps?(f1, vec2)).to be(false)
    expect(TBD.status).to eq(0)

    # Same exercise, yet provide clerestory with Frame & Divider.
    fd2 = OpenStudio::Model::WindowPropertyFrameAndDivider.new(os_model_FD)
    width2 = 0.03
    expect(fd2.setFrameWidth(width2)).to be(true)
    expect(fd2.setFrameConductance(2.500)).to be(true)
    expect(clerestory.allowWindowPropertyFrameAndDivider).to be(true)
    expect(clerestory.setWindowPropertyFrameAndDivider(fd2)).to be(true)
    width3 = clerestory.windowPropertyFrameAndDivider.get.frameWidth
    expect(width3).to be_within(0.001).of(width2)

    TBD.clean!
    argh[:option] = "poor (BETBG)"
    json = TBD.process(os_model_FD, argh)
    expect(json.is_a?(Hash)).to be(true)
    expect(json.key?(:io)).to be(true)
    expect(json.key?(:surfaces)).to be(true)
    io       = json[:io]
    surfaces = json[:surfaces]

    # There should be a conflict between both windows equipped with F&D.
    expect(TBD.status).to eq(ERR)
    expect(TBD.logs.size).to eq(13)
    expect(io.nil?).to be(false)
    expect(io.is_a?(Hash)).to be(true)
    expect(io.empty?).to be(false)
    expect(surfaces.nil?).to be(false)
    expect(surfaces.is_a?(Hash)).to be(true)
    expect(surfaces.size).to eq(23)
    expect(surfaces.key?(nom)).to be(true)
    expect(surfaces[nom].key?(:windows)).to be(true)
    wins = surfaces[nom][:windows]
    expect(wins.size).to eq(3)
    expect(wins.key?("clerestory")).to be(true)
    expect(wins.key?(name)).to be(true)
    expect(wins["clerestory"].key?(:points)).to be(true)
    expect(wins[name].key?(:points)).to be(true)

    # As there are conflicts between both windows (due to conflicting Frame &
    # Divider parameters), TBD will ignore Frame & Divider coordinates and fall
    # back to original OpenStudio subsurface vertices.
    v1 = window_FD.vertices                   # original OSM vertices for window
    p1 = wins[name][:points]                  # Topolys vertices, as original
    expect((p1[0].x - v1[0].x).abs).to be_within(0.01).of(0)
    expect((p1[1].x - v1[1].x).abs).to be_within(0.01).of(0)
    expect((p1[2].x - v1[2].x).abs).to be_within(0.01).of(0)
    expect((p1[3].x - v1[3].x).abs).to be_within(0.01).of(0)
    expect((p1[0].y - v1[0].y).abs).to be_within(0.01).of(0)
    expect((p1[1].y - v1[1].y).abs).to be_within(0.01).of(0)
    expect((p1[2].y - v1[2].y).abs).to be_within(0.01).of(0)
    expect((p1[3].y - v1[3].y).abs).to be_within(0.01).of(0)
    expect((p1[0].z - v1[0].z).abs).to be_within(0.01).of(0)
    expect((p1[1].z - v1[1].z).abs).to be_within(0.01).of(0)
    expect((p1[2].z - v1[2].z).abs).to be_within(0.01).of(0)
    expect((p1[3].z - v1[3].z).abs).to be_within(0.01).of(0)

    v2 = clerestory.vertices
    p2 = wins["clerestory"][:points]             # same as original OSM vertices
    expect((p2[0].x - v2[0].x).abs).to be_within(0.01).of(0)
    expect((p2[1].x - v2[1].x).abs).to be_within(0.01).of(0)
    expect((p2[2].x - v2[2].x).abs).to be_within(0.01).of(0)
    expect((p2[3].x - v2[3].x).abs).to be_within(0.01).of(0)
    expect((p2[0].y - v2[0].y).abs).to be_within(0.01).of(0)
    expect((p2[1].y - v2[1].y).abs).to be_within(0.01).of(0)
    expect((p2[2].y - v2[2].y).abs).to be_within(0.01).of(0)
    expect((p2[3].y - v2[3].y).abs).to be_within(0.01).of(0)
    expect((p2[0].z - v2[0].z).abs).to be_within(0.01).of(0)
    expect((p2[1].z - v2[1].z).abs).to be_within(0.01).of(0)
    expect((p2[2].z - v2[2].z).abs).to be_within(0.01).of(0)
    expect((p2[3].z - v2[3].z).abs).to be_within(0.01).of(0)

    # In addition, the top of the "Office Front Wall Window 1" is no longer
    # aligned with the bottom of the clerestory.
    expect(((p1[0].z - p2[1].z).abs - width2).abs).to be_within(0.01).of(0)
    expect(((p1[3].z - p2[2].z).abs - width2).abs).to be_within(0.01).of(0)

    TBD.clean!
    vec1 = OpenStudio::Point3dVector.new
    vec2 = OpenStudio::Point3dVector.new
    p1.each { |p| vec1 << OpenStudio::Point3d.new(p.x, p.y, p.z) }
    p2.each { |p| vec2 << OpenStudio::Point3d.new(p.x, p.y, p.z) }
    expect(TBD.fits?(vec1, vec2)).to be(false)
    expect(TBD.overlaps?(vec1, vec2)).to be(false)
    expect(TBD.status).to eq(0)


    # --- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- --- #
    # Testing more complex cases e.g., triangular windows, irregular 4-side
    # windows, rough opening edges overlapping parent surface edges.
    model = OpenStudio::Model::Model.new
    space = OpenStudio::Model::Space.new(model)
    space.setName("Space")

    # All subsurfaces are Simple Glazing constructions.
    fenestration = OpenStudio::Model::Construction.new(model)
    expect(fenestration.handle.to_s.empty?).to be(false)
    expect(fenestration.nameString.empty?).to be(false)
    fenestration.setName("FD fenestration")
    expect(fenestration.nameString).to eq("FD fenestration")
    expect(fenestration.layers.size).to eq(0)

    glazing = OpenStudio::Model::SimpleGlazing.new(model)
    expect(glazing.handle.to_s.empty?).to be(false)
    expect(glazing.nameString.empty?).to be(false)
    glazing.setName("FD glazing")
    expect(glazing.nameString).to eq("FD glazing")
    expect(glazing.setUFactor(2.0)).to be(true)

    layers = OpenStudio::Model::MaterialVector.new
    layers << glazing
    expect(fenestration.setLayers(layers)).to be(true)
    expect(fenestration.layers.size).to eq(1)

    vec  = OpenStudio::Point3dVector.new
    vec << OpenStudio::Point3d.new(  0.00,  0.00, 10.00)
    vec << OpenStudio::Point3d.new(  0.00,  0.00,  0.00)
    vec << OpenStudio::Point3d.new( 10.00,  0.00,  0.00)
    vec << OpenStudio::Point3d.new( 10.00,  0.00, 10.00)
    dad  = OpenStudio::Model::Surface.new(vec, model)
    dad.setName("dad")
    expect(dad.setSpace(space)).to be(true)

    vec  = OpenStudio::Point3dVector.new
    vec << OpenStudio::Point3d.new(  2.00,  0.00,  8.00)
    vec << OpenStudio::Point3d.new(  1.00,  0.00,  6.00)
    vec << OpenStudio::Point3d.new(  4.00,  0.00,  9.00)
    w1   = OpenStudio::Model::SubSurface.new(vec, model)
    w1.setName("w1")
    expect(w1.setSubSurfaceType("FixedWindow")).to be(true)
    expect(w1.setSurface(dad)).to be(true)
    expect(w1.setConstruction(fenestration)).to be(true)
    expect(w1.uFactor.empty?).to be(false)
    expect(w1.uFactor.get).to be_within(0.1).of(2.0)
    expect(w1.netArea).to be_within(TOL).of(1.50)
    expect(w1.grossArea).to be_within(TOL).of(1.50)

    vec  = OpenStudio::Point3dVector.new
    vec << OpenStudio::Point3d.new(  7.00,  0.00,  4.00)
    vec << OpenStudio::Point3d.new(  4.00,  0.00,  1.00)
    vec << OpenStudio::Point3d.new(  8.00,  0.00,  2.00)
    vec << OpenStudio::Point3d.new(  9.00,  0.00,  3.00)
    w2   = OpenStudio::Model::SubSurface.new(vec, model)
    w2.setName("w2")
    expect(w2.setSubSurfaceType("FixedWindow")).to be(true)
    expect(w2.setSurface(dad)).to be(true)
    expect(w2.setConstruction(fenestration)).to be(true)
    expect(w2.uFactor.empty?).to be(false)
    expect(w2.uFactor.get).to be_within(0.1).of(2.0)
    expect(w2.netArea).to be_within(TOL).of(6.00)
    expect(w2.grossArea).to be_within(TOL).of(6.00)

    vec  = OpenStudio::Point3dVector.new
    vec << OpenStudio::Point3d.new(  9.00,  0.00,  9.80)
    vec << OpenStudio::Point3d.new(  9.80,  0.00,  9.00)
    vec << OpenStudio::Point3d.new(  9.80,  0.00,  9.80)
    w3   = OpenStudio::Model::SubSurface.new(vec, model)
    w3.setName("w3")
    expect(w3.setSubSurfaceType("FixedWindow")).to be(true)
    expect(w3.setSurface(dad)).to be(true)
    expect(w3.setConstruction(fenestration)).to be(true)
    expect(w3.uFactor.empty?).to be(false)
    expect(w3.uFactor.get).to be_within(0.1).of(2.0)
    expect(w3.netArea).to be_within(TOL).of(0.32)
    expect(w3.grossArea).to be_within(TOL).of(0.32)

    # Without Frame & Divider objects linked to subsurface.
    surface = TBD.properties(model, dad)
    puts TBD.logs
    expect(surface.nil?).to be(false)
    expect(surface.is_a?(Hash)).to be(true)
    expect(surface.key?(:gross)).to be(true)
    expect(surface[:gross]).to be_a(Numeric)
    expect(surface[:gross]).to be_within(0.1).of(100)
    expect(surface.key?(:net)).to be(true)
    expect(surface.key?(:windows)).to be(true)
    expect(surface[:windows].is_a?(Hash)).to be(true)
    expect(surface[:windows].key?("w1"))
    expect(surface[:windows]["w1"].is_a?(Hash)).to be(true)
    expect(surface[:windows]["w1"].key?(:gross)).to be(true)
    expect(surface[:windows]["w1"][:gross]).to be_within(0.01).of(1.5)
    expect(surface[:windows]["w1"].key?(:points)).to be(true)
    expect(surface[:windows]["w1"][:points].size).to eq(3)

    # Adding a Frame & Divider object ...
    fd = OpenStudio::Model::WindowPropertyFrameAndDivider.new(model)
    expect(fd.setFrameWidth(0.200)).to be(true)   # 200mm (wide!) around glazing
    expect(fd.setFrameConductance(0.500)).to be(true)

    expect(w1.allowWindowPropertyFrameAndDivider).to be(true)
    expect(w1.setWindowPropertyFrameAndDivider(fd)).to be(true)
    width = w1.windowPropertyFrameAndDivider.get.frameWidth
    expect(width).to be_within(0.001).of(0.200)                # ... good so far

    # TBD's 'properties' method relies on OSut's 'offset' solution when dealing
    # with subsurfaces with F&D. It offers 3x options:
    #   1. native, 3D vector-based calculations (only option for SDK < v321)
    #   2. SDK's reliance on Boost's 'buffer' (default for v300 < SDK < v340)
    #   3. SDK's 'rough opening' vertices (default for SDK v340+)
    #
    # Options #2 & #3 both rely on Boost's buffer. But SDK v340+ doesn't
    # correct generated Boost vertices (back to counterclockwise). Option #2
    # ensures counterclockwise sequences, although the first vertex in the array
    # is no longer in sync with the original OpenStudio vertices. Not
    # consequential for fitting and overlapping detection, or net/gross/rough
    # areas tallies. Otherwise, both options generate the same vertices.
    #
    # For triangular subsurfaces, Options #2 & #3 may generate additional
    # vertices near acute angles, e.g. 6 (3 of which would be ~colinear).
    # Calculated areas, as well as fitting & overlapping detection, still work.
    # Yet inaccuracies do creep in with respect to Option #1. To maintain
    # consistency in TBD calculations when switching SDK versions, TBD's use of
    # OSut's offset method is as follows (see 'properties' in geo.rb):
    #
    #    offset(s.vertices, width, 300)
    #
    # There may be slight differences in reported SDK results vs TBD UA reports
    # (e.g. WWR, net areas) with acute triangular windows ... which is fine.
    surface = TBD.properties(model, dad)
    expect(surface.nil?).to be(false)
    expect(surface.is_a?(Hash)).to be(true)
    expect(surface.key?(:windows)).to be(true)
    expect(surface[:windows].is_a?(Hash)).to be(true)
    expect(surface[:windows].key?("w1"))
    expect(surface[:windows]["w1"].is_a?(Hash)).to be(true)
    expect(surface[:windows]["w1"].key?(:gross)).to be(true)
    expect(surface[:windows]["w1"][:gross]).to be_within(0.01).of(3.75)
    expect(surface[:windows]["w1"].key?(:points)).to be(true)
    ptz = surface[:windows]["w1"][:points]
    expect(ptz.size).to eq(3)        # 6 without the '300' offset argument above
    vec = OpenStudio::Point3dVector.new
    ptz.each { |o| vec << OpenStudio::Point3d.new(o.x, o.y, o.z) }
    vec_area = OpenStudio.getArea(vec)
    expect(vec_area.empty?).to be(false)
    expect(vec_area.get).to be_within(TOL).of(surface[:windows]["w1"][:area])
    # The following X & Z coordinates are all offset by 0.200 (frame width),
    # with respect to the original subsurface coordinates. For acute angles,
    # the rough opening edge intersection can be far, far away from the glazing
    # coordinates (+1m).
    expect(vec[0].x).to be_within(0.01).of( 1.85)
    expect(vec[0].y).to be_within(0.01).of( 0.00)
    expect(vec[0].z).to be_within(0.01).of( 8.15)
    expect(vec[1].x).to be_within(0.01).of( 0.27)
    expect(vec[1].y).to be_within(0.01).of( 0.00)
    expect(vec[1].z).to be_within(0.01).of( 4.99)
    expect(vec[2].x).to be_within(0.01).of( 5.01)
    expect(vec[2].y).to be_within(0.01).of( 0.00)
    expect(vec[2].z).to be_within(0.01).of( 9.73)

    # Adding a Frame & Divider object for w2.
    expect(w2.allowWindowPropertyFrameAndDivider).to be(true)
    expect(w2.setWindowPropertyFrameAndDivider(fd)).to be(true)
    width = w2.windowPropertyFrameAndDivider.get.frameWidth
    expect(width).to be_within(0.001).of(0.200)

    surface = TBD.properties(model, dad)
    expect(surface.nil?).to be(false)
    expect(surface.is_a?(Hash)).to be(true)
    expect(surface.key?(:windows)).to be(true)
    expect(surface[:windows].is_a?(Hash)).to be(true)
    expect(surface[:windows].key?("w2"))
    expect(surface[:windows]["w2"].is_a?(Hash)).to be(true)
    expect(surface[:windows]["w2"].key?(:gross)).to be(true)
    expect(surface[:windows]["w2"][:gross]).to be_within(0.01).of(8.64)
    expect(surface[:windows]["w2"].key?(:points)).to be(true)
    ptz = surface[:windows]["w2"][:points]
    expect(ptz.size).to eq(4)
    vec = OpenStudio::Point3dVector.new
    ptz.each { |o| vec << OpenStudio::Point3d.new(o.x, o.y, o.z) }
    expect(vec[0].x).to be_within(0.01).of( 6.96)
    expect(vec[0].y).to be_within(0.01).of( 0.00)
    expect(vec[0].z).to be_within(0.01).of( 4.24)
    expect(vec[1].x).to be_within(0.01).of( 3.35)
    expect(vec[1].y).to be_within(0.01).of( 0.00)
    expect(vec[1].z).to be_within(0.01).of( 0.63)
    expect(vec[2].x).to be_within(0.01).of( 8.10)
    expect(vec[2].y).to be_within(0.01).of( 0.00)
    expect(vec[2].z).to be_within(0.01).of( 1.82)
    expect(vec[3].x).to be_within(0.01).of( 9.34)
    expect(vec[3].y).to be_within(0.01).of( 0.00)
    expect(vec[3].z).to be_within(0.01).of( 3.05)

    # Adding a Frame & Divider object for w3.
    expect(w3.allowWindowPropertyFrameAndDivider).to be(true)
    expect(w3.setWindowPropertyFrameAndDivider(fd)).to be(true)
    width = w3.windowPropertyFrameAndDivider.get.frameWidth
    expect(width).to be_within(0.001).of(0.200)

    surface = TBD.properties(model, dad)
    expect(surface.nil?).to be(false)
    expect(surface.is_a?(Hash)).to be(true)
    expect(surface.key?(:windows)).to be(true)
    expect(surface[:windows].is_a?(Hash)).to be(true)
    expect(surface[:windows].key?("w3"))
    expect(surface[:windows]["w3"].is_a?(Hash)).to be(true)
    expect(surface[:windows]["w3"].key?(:gross)).to be(true)
    expect(surface[:windows]["w3"][:gross]).to be_within(0.01).of(1.1)
    expect(surface[:windows]["w3"].key?(:points)).to be(true)
    ptz = surface[:windows]["w3"][:points]
    expect(ptz.size).to eq(3)
    vec = OpenStudio::Point3dVector.new
    ptz.each { |o| vec << OpenStudio::Point3d.new(o.x, o.y, o.z) }
    # This window would have 2 shared edges (@right angle) with the parent.
    expect(vec[0].x).to be_within(0.01).of( 8.52)
    expect(vec[0].y).to be_within(0.01).of( 0.00)
    expect(vec[0].z).to be_within(0.01).of(10.00)
    expect(vec[1].x).to be_within(0.01).of(10.00)
    expect(vec[1].y).to be_within(0.01).of( 0.00)
    expect(vec[1].z).to be_within(0.01).of( 8.52)
    expect(vec[2].x).to be_within(0.01).of(10.00)
    expect(vec[2].y).to be_within(0.01).of( 0.00)
    expect(vec[2].z).to be_within(0.01).of(10.00)


    # --- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- --- #
    # Repeat exercise, with parent surface & subsurfaces rotated 120 (CW).
    # (i.e., negative coordinates, Y-axis coordinates, etc.)
    model = OpenStudio::Model::Model.new
    space = OpenStudio::Model::Space.new(model)
    space.setName("Space")

    # All subsurfaces are Simple Glazing constructions.
    fenestration = OpenStudio::Model::Construction.new(model)
    expect(fenestration.handle.to_s.empty?).to be(false)
    expect(fenestration.nameString.empty?).to be(false)
    fenestration.setName("FD fenestration")
    expect(fenestration.nameString).to eq("FD fenestration")
    expect(fenestration.layers.size).to eq(0)

    glazing = OpenStudio::Model::SimpleGlazing.new(model)
    expect(glazing.handle.to_s.empty?).to be(false)
    expect(glazing.nameString.empty?).to be(false)
    glazing.setName("FD glazing")
    expect(glazing.nameString).to eq("FD glazing")
    expect(glazing.setUFactor(2.0)).to be(true)

    layers = OpenStudio::Model::MaterialVector.new
    layers << glazing
    expect(fenestration.setLayers(layers)).to be(true)
    expect(fenestration.layers.size).to eq(1)

    vec  = OpenStudio::Point3dVector.new
    vec << OpenStudio::Point3d.new(  0.00,  0.00, 10.00)
    vec << OpenStudio::Point3d.new(  0.00,  0.00,  0.00)
    vec << OpenStudio::Point3d.new( -5.00, -8.66,  0.00)
    vec << OpenStudio::Point3d.new( -5.00, -8.66, 10.00)
    dad  = OpenStudio::Model::Surface.new(vec, model)
    dad.setName("dad")
    expect(dad.setSpace(space)).to be(true)

    vec  = OpenStudio::Point3dVector.new
    vec << OpenStudio::Point3d.new( -1.00, -1.73,  8.00)
    vec << OpenStudio::Point3d.new( -0.50, -0.87,  6.00)
    vec << OpenStudio::Point3d.new( -2.00, -3.46,  9.00)
    w1   = OpenStudio::Model::SubSurface.new(vec, model)
    w1.setName("w1")
    expect(w1.setSubSurfaceType("FixedWindow")).to be(true)
    expect(w1.setSurface(dad)).to be(true)
    expect(w1.setConstruction(fenestration)).to be(true)
    expect(w1.uFactor.empty?).to be(false)
    expect(w1.uFactor.get).to be_within(0.1).of(2.0)
    expect(w1.netArea).to be_within(TOL).of(1.50)
    expect(w1.grossArea).to be_within(TOL).of(1.50)

    vec  = OpenStudio::Point3dVector.new
    vec << OpenStudio::Point3d.new( -3.50, -6.06,  4.00)
    vec << OpenStudio::Point3d.new( -2.00, -3.46,  1.00)
    vec << OpenStudio::Point3d.new( -4.00, -6.93,  2.00)
    vec << OpenStudio::Point3d.new( -4.50, -7.79,  3.00)
    w2   = OpenStudio::Model::SubSurface.new(vec, model)
    w2.setName("w2")
    expect(w2.setSubSurfaceType("FixedWindow")).to be(true)
    expect(w2.setSurface(dad)).to be(true)
    expect(w2.setConstruction(fenestration)).to be(true)
    expect(w2.uFactor.empty?).to be(false)
    expect(w2.uFactor.get).to be_within(0.1).of(2.0)
    expect(w2.netArea).to be_within(TOL).of(6.00)
    expect(w2.grossArea).to be_within(TOL).of(6.00)

    vec  = OpenStudio::Point3dVector.new
    vec << OpenStudio::Point3d.new( -4.50, -7.79,  9.80)
    vec << OpenStudio::Point3d.new( -4.90, -8.49,  9.00)
    vec << OpenStudio::Point3d.new( -4.90, -8.49,  9.80)
    w3   = OpenStudio::Model::SubSurface.new(vec, model)
    w3.setName("w3")
    expect(w3.setSubSurfaceType("FixedWindow")).to be(true)
    expect(w3.setSurface(dad)).to be(true)
    expect(w3.setConstruction(fenestration)).to be(true)
    expect(w3.uFactor.empty?).to be(false)
    expect(w3.uFactor.get).to be_within(0.1).of(2.0)
    expect(w3.netArea).to be_within(TOL).of(0.32)
    expect(w3.grossArea).to be_within(TOL).of(0.32)

    # Without Frame & Divider objects linked to subsurface.
    surface = TBD.properties(model, dad)
    expect(surface.nil?).to be(false)
    expect(surface.is_a?(Hash)).to be(true)
    expect(surface.key?(:gross)).to be(true)
    expect(surface[:gross]).to be_a(Numeric)
    expect(surface[:gross]).to be_within(0.1).of(100)
    expect(surface.key?(:net)).to be(true)
    expect(surface.key?(:windows)).to be(true)
    expect(surface[:windows].is_a?(Hash)).to be(true)
    expect(surface[:windows].key?("w1"))
    expect(surface[:windows]["w1"].is_a?(Hash)).to be(true)
    expect(surface[:windows]["w1"].key?(:gross)).to be(true)
    expect(surface[:windows]["w1"][:gross]).to be_within(0.01).of(1.5)
    expect(surface[:windows]["w1"].key?(:points)).to be(true)
    expect(surface[:windows]["w1"][:points].size).to eq(3)
    expect(surface[:windows].key?("w3"))
    expect(surface[:windows]["w3"].is_a?(Hash)).to be(true)
    expect(surface[:windows]["w3"].key?(:gross)).to be(true)
    expect(surface[:windows]["w3"][:gross]).to be_within(0.01).of(0.32)

    # Adding a Frame & Divider object.
    fd = OpenStudio::Model::WindowPropertyFrameAndDivider.new(model)
    expect(fd.setFrameWidth(0.200)).to be(true)   # 200mm (wide!) around glazing
    expect(fd.setFrameConductance(0.500)).to be(true)

    expect(w1.allowWindowPropertyFrameAndDivider).to be(true)
    expect(w1.setWindowPropertyFrameAndDivider(fd)).to be(true)
    width = w1.windowPropertyFrameAndDivider.get.frameWidth
    expect(width).to be_within(0.001).of(0.200)                # good so far ...

    surface = TBD.properties(model, dad)
    expect(surface.nil?).to be(false)
    expect(surface.is_a?(Hash)).to be(true)
    expect(surface.key?(:windows)).to be(true)
    expect(surface[:windows].is_a?(Hash)).to be(true)
    expect(surface[:windows].key?("w1"))
    expect(surface[:windows]["w1"].is_a?(Hash)).to be(true)
    expect(surface[:windows]["w1"].key?(:gross)).to be(true)
    expect(surface[:windows]["w1"][:gross]).to be_within(0.01).of(3.75)
    expect(surface[:windows]["w1"].key?(:points)).to be(true)
    ptz = surface[:windows]["w1"][:points]
    expect(ptz.is_a?(Array))
    expect(ptz.size).to eq(3)
    vec = OpenStudio::Point3dVector.new
    ptz.each { |o| vec << OpenStudio::Point3d.new(o.x, o.y, o.z) }
    area = OpenStudio.getArea(vec)
    expect(area.empty?).to be(false)
    expect(area.get).to be_within(TOL).of(surface[:windows]["w1"][:area])
    expect(vec[0].x).to be_within(0.01).of(-0.93)
    expect(vec[0].y).to be_within(0.01).of(-1.60)
    expect(vec[0].z).to be_within(0.01).of( 8.15)
    expect(vec[1].x).to be_within(0.01).of(-0.13)
    expect(vec[1].y).to be_within(0.01).of(-0.24)             # SketchUP (-0.23)
    expect(vec[1].z).to be_within(0.01).of( 4.99)
    expect(vec[2].x).to be_within(0.01).of(-2.51)
    expect(vec[2].y).to be_within(0.01).of(-4.34)
    expect(vec[2].z).to be_within(0.01).of( 9.73)

    # Adding a Frame & Divider object for w2.
    expect(w2.allowWindowPropertyFrameAndDivider).to be(true)
    expect(w2.setWindowPropertyFrameAndDivider(fd)).to be(true)
    width = w2.windowPropertyFrameAndDivider.get.frameWidth
    expect(width).to be_within(0.001).of(0.200)

    surface = TBD.properties(model, dad)
    expect(surface.nil?).to be(false)
    expect(surface.is_a?(Hash)).to be(true)
    expect(surface.key?(:windows)).to be(true)
    expect(surface[:windows].is_a?(Hash)).to be(true)
    expect(surface[:windows].key?("w2"))
    expect(surface[:windows]["w2"].is_a?(Hash)).to be(true)
    expect(surface[:windows]["w2"].key?(:gross)).to be(true)
    expect(surface[:windows]["w2"][:gross]).to be_within(0.01).of(8.64)
    expect(surface[:windows]["w2"].key?(:points)).to be(true)
    ptz = surface[:windows]["w2"][:points]
    expect(ptz.size).to eq(4)
    vec = OpenStudio::Point3dVector.new
    ptz.each { |o| vec << OpenStudio::Point3d.new(o.x, o.y, o.z) }
    area = OpenStudio.getArea(vec)
    expect(area.empty?).to be(false)
    expect(area.get).to be_within(TOL).of(surface[:windows]["w2"][:area])
    expect(vec[0].x).to be_within(0.01).of(-3.48)
    expect(vec[0].y).to be_within(0.01).of(-6.03)
    expect(vec[0].z).to be_within(0.01).of( 4.24)
    expect(vec[1].x).to be_within(0.01).of(-1.67)
    expect(vec[1].y).to be_within(0.01).of(-2.90)
    expect(vec[1].z).to be_within(0.01).of( 0.63)
    expect(vec[2].x).to be_within(0.01).of(-4.05)
    expect(vec[2].y).to be_within(0.01).of(-7.02)
    expect(vec[2].z).to be_within(0.01).of( 1.82)
    expect(vec[3].x).to be_within(0.01).of(-4.67)
    expect(vec[3].y).to be_within(0.01).of(-8.09)
    expect(vec[3].z).to be_within(0.01).of( 3.05)

    # Adding a Frame & Divider object for w3.
    expect(w3.allowWindowPropertyFrameAndDivider).to be(true)
    expect(w3.setWindowPropertyFrameAndDivider(fd)).to be(true)
    width = w3.windowPropertyFrameAndDivider.get.frameWidth
    expect(width).to be_within(0.001).of(0.200)

    surface = TBD.properties(model, dad)
    expect(surface.nil?).to be(false)
    expect(surface.is_a?(Hash)).to be(true)
    expect(surface.key?(:windows)).to be(true)
    expect(surface[:windows].is_a?(Hash)).to be(true)
    expect(surface[:windows].key?("w3"))
    expect(surface[:windows]["w3"].is_a?(Hash)).to be(true)
    expect(surface[:windows]["w3"].key?(:gross)).to be(true)
    expect(surface[:windows]["w3"].key?(:points)).to be(true)
    ptz = surface[:windows]["w3"][:points]
    expect(ptz.size).to eq(3)
    vec = OpenStudio::Point3dVector.new
    ptz.each { |o| vec << OpenStudio::Point3d.new(o.x, o.y, o.z) }
    area = OpenStudio.getArea(vec)
    expect(area.empty?).to be(false)
    expect(area.get).to be_within(TOL).of(surface[:windows]["w3"][:area])
    expect(surface[:windows]["w3"][:gross]).to be_within(0.01).of(1.1)
    expect(vec[0].x).to be_within(0.01).of(-4.26)
    expect(vec[0].y).to be_within(0.01).of(-7.37)             # SketchUp (-7.38)
    expect(vec[0].z).to be_within(0.01).of(10.00)
    expect(vec[1].x).to be_within(0.01).of(-5.00)
    expect(vec[1].y).to be_within(0.01).of(-8.66)
    expect(vec[1].z).to be_within(0.01).of( 8.52)
    expect(vec[2].x).to be_within(0.01).of(-5.00)
    expect(vec[2].y).to be_within(0.01).of(-8.66)
    expect(vec[2].z).to be_within(0.01).of(10.00)


    # --- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- --- #
    # Repeat 3rd time - 2x 30° rotations (along the 2 other axes).
    model = OpenStudio::Model::Model.new
    space = OpenStudio::Model::Space.new(model)
    space.setName("Space")

    # All subsurfaces are Simple Glazing constructions.
    fenestration = OpenStudio::Model::Construction.new(model)
    expect(fenestration.handle.to_s.empty?).to be(false)
    expect(fenestration.nameString.empty?).to be(false)
    fenestration.setName("FD3 fenestration")
    expect(fenestration.nameString).to eq("FD3 fenestration")
    expect(fenestration.layers.size).to eq(0)

    glazing = OpenStudio::Model::SimpleGlazing.new(model)
    expect(glazing.handle.to_s.empty?).to be(false)
    expect(glazing.nameString.empty?).to be(false)
    glazing.setName("FD3 glazing")
    expect(glazing.nameString).to eq("FD3 glazing")
    expect(glazing.setUFactor(2.0)).to be(true)

    layers = OpenStudio::Model::MaterialVector.new
    layers << glazing
    expect(fenestration.setLayers(layers)).to be(true)
    expect(fenestration.layers.size).to eq(1)

    vec  = OpenStudio::Point3dVector.new
    vec << OpenStudio::Point3d.new( -1.25,  6.50,  7.50)
    vec << OpenStudio::Point3d.new(  0.00,  0.00,  0.00)
    vec << OpenStudio::Point3d.new( -6.50, -6.25,  4.33)
    vec << OpenStudio::Point3d.new( -7.75,  0.25, 11.83)
    dad  = OpenStudio::Model::Surface.new(vec, model)
    dad.setName("dad")
    expect(dad.setSpace(space)).to be(true)

    vec  = OpenStudio::Point3dVector.new
    vec << OpenStudio::Point3d.new( -2.30,  3.95,  6.87)
    vec << OpenStudio::Point3d.new( -1.40,  3.27,  4.93)
    vec << OpenStudio::Point3d.new( -3.72,  3.35,  8.48)
    w1   = OpenStudio::Model::SubSurface.new(vec, model)
    w1.setName("w1")
    expect(w1.setSubSurfaceType("FixedWindow")).to be(true)
    expect(w1.setSurface(dad)).to be(true)
    expect(w1.setConstruction(fenestration)).to be(true)
    expect(w1.uFactor.empty?).to be(false)
    expect(w1.uFactor.get).to be_within(0.1).of(2.0)
    expect(w1.netArea).to be_within(TOL).of(1.50)
    expect(w1.grossArea).to be_within(TOL).of(1.50)

    vec = OpenStudio::Point3dVector.new
    vec << OpenStudio::Point3d.new( -5.05, -1.78,  6.03)
    vec << OpenStudio::Point3d.new( -2.72, -1.85,  2.48)
    vec << OpenStudio::Point3d.new( -5.45, -3.70,  4.96)
    vec << OpenStudio::Point3d.new( -6.22, -3.68,  6.15)
    w2 = OpenStudio::Model::SubSurface.new(vec, model)
    w2.setName("w2")
    expect(w2.setSubSurfaceType("FixedWindow")).to be(true)
    expect(w2.setSurface(dad)).to be(true)
    expect(w2.setConstruction(fenestration)).to be(true)
    expect(w2.uFactor.empty?).to be(false)
    expect(w2.uFactor.get).to be_within(0.1).of(2.0)
    expect(w2.netArea).to be_within(TOL).of(6.00)
    expect(w2.grossArea).to be_within(TOL).of(6.00)

    vec = OpenStudio::Point3dVector.new
    vec << OpenStudio::Point3d.new( -7.07,  0.74, 11.25)
    vec << OpenStudio::Point3d.new( -7.49, -0.28, 10.99)
    vec << OpenStudio::Point3d.new( -7.59,  0.24, 11.59)
    w3 = OpenStudio::Model::SubSurface.new(vec, model)
    w3.setName("w3")
    expect(w3.setSubSurfaceType("FixedWindow")).to be(true)
    expect(w3.setSurface(dad)).to be(true)
    expect(w3.setConstruction(fenestration)).to be(true)
    expect(w3.uFactor.empty?).to be(false)
    expect(w3.uFactor.get).to be_within(0.1).of(2.0)
    expect(w3.netArea).to be_within(TOL).of(0.32)
    expect(w3.grossArea).to be_within(TOL).of(0.32)

    # Without Frame & Divider objects linked to subsurface.
    surface = TBD.properties(model, dad)
    expect(surface.nil?).to be(false)
    expect(surface.is_a?(Hash)).to be(true)
    expect(surface.key?(:gross)).to be(true)
    expect(surface[:gross]).to be_a(Numeric)
    expect(surface[:gross]).to be_within(0.1).of(100)
    expect(surface.key?(:net)).to be(true)
    expect(surface.key?(:windows)).to be(true)
    expect(surface[:windows].is_a?(Hash)).to be(true)
    expect(surface[:windows].key?("w1"))
    expect(surface[:windows]["w1"].is_a?(Hash)).to be(true)
    expect(surface[:windows]["w1"].key?(:gross)).to be(true)
    expect(surface[:windows]["w1"][:gross]).to be_within(0.02).of(1.5)
    expect(surface[:windows]["w1"].key?(:u)).to be(true)
    expect(surface[:windows]["w1"][:u]).to be_within(0.01).of(2.0)
    expect(surface[:windows]["w1"].key?(:points)).to be(true)
    expect(surface[:windows]["w1"][:points].size).to eq(3)

    # Adding a Frame & Divider object.
    fd = OpenStudio::Model::WindowPropertyFrameAndDivider.new(model)
    expect(fd.setFrameWidth(0.200)).to be(true)
    expect(fd.setFrameConductance(0.500)).to be(true)

    expect(w1.allowWindowPropertyFrameAndDivider).to be(true)
    expect(w1.setWindowPropertyFrameAndDivider(fd)).to be(true)
    width = w1.windowPropertyFrameAndDivider.get.frameWidth
    expect(width).to be_within(0.001).of(0.200)

    surface = TBD.properties(model, dad)
    expect(surface.nil?).to be(false)
    expect(surface.is_a?(Hash)).to be(true)
    expect(surface.key?(:windows)).to be(true)
    expect(surface[:windows].is_a?(Hash)).to be(true)
    expect(surface[:windows].key?("w1"))
    expect(surface[:windows]["w1"].is_a?(Hash)).to be(true)
    expect(surface[:windows]["w1"].key?(:gross)).to be(true)
    expect(surface[:windows]["w1"][:gross]).to be_within(0.02).of(3.75)
    expect(surface[:windows]["w1"].key?(:points)).to be(true)
    ptz = surface[:windows]["w1"][:points]
    expect(ptz.is_a?(Array))
    expect(ptz.size).to eq(3)
    vec = OpenStudio::Point3dVector.new
    ptz.each { |o| vec << OpenStudio::Point3d.new(o.x, o.y, o.z) }
    area = OpenStudio.getArea(vec)
    expect(area.empty?).to be(false)
    expect(area.get).to be_within(TOL).of(surface[:windows]["w1"][:area])
    expect(vec[0].x).to be_within(0.01).of(-2.22)
    expect(vec[0].y).to be_within(0.01).of( 4.14)
    expect(vec[0].z).to be_within(0.01).of( 6.91)
    expect(vec[1].x).to be_within(0.01).of(-0.80)
    expect(vec[1].y).to be_within(0.01).of( 3.07)
    expect(vec[1].z).to be_within(0.01).of( 3.86)
    expect(vec[2].x).to be_within(0.01).of(-4.47)
    expect(vec[2].y).to be_within(0.01).of( 3.19)
    expect(vec[2].z).to be_within(0.01).of( 9.46)             # SketchUp (-9.47)

    # Adding a Frame & Divider object for w2.
    expect(w2.allowWindowPropertyFrameAndDivider).to be(true)
    expect(w2.setWindowPropertyFrameAndDivider(fd)).to be(true)
    width = w2.windowPropertyFrameAndDivider.get.frameWidth
    expect(width).to be_within(0.001).of(0.200)

    surface = TBD.properties(model, dad)
    expect(surface.nil?).to be(false)
    expect(surface.is_a?(Hash)).to be(true)
    expect(surface.key?(:windows)).to be(true)
    expect(surface[:windows].is_a?(Hash)).to be(true)
    expect(surface[:windows].key?("w2"))
    expect(surface[:windows]["w2"].is_a?(Hash)).to be(true)
    expect(surface[:windows]["w2"].key?(:gross)).to be(true)
    expect(surface[:windows]["w2"][:gross]).to be_within(0.01).of(8.64)
    expect(surface[:windows]["w2"].key?(:u)).to be(true)
    expect(surface[:windows]["w2"][:u]).to be_within(0.01).of(2.0)
    expect(surface[:windows]["w2"].key?(:points)).to be(true)
    ptz = surface[:windows]["w2"][:points]
    expect(ptz.size).to eq(4)
    vec = OpenStudio::Point3dVector.new
    ptz.each { |o| vec << OpenStudio::Point3d.new(o.x, o.y, o.z) }
    area = OpenStudio.getArea(vec)
    expect(area.empty?).to be(false)
    expect(area.get).to be_within(TOL).of(surface[:windows]["w2"][:area])
    expect(vec[0].x).to be_within(0.01).of(-5.05)
    expect(vec[0].y).to be_within(0.01).of(-1.59)
    expect(vec[0].z).to be_within(0.01).of( 6.20)
    expect(vec[1].x).to be_within(0.01).of(-2.25)
    expect(vec[1].y).to be_within(0.01).of(-1.68)
    expect(vec[1].z).to be_within(0.01).of( 1.92)
    expect(vec[2].x).to be_within(0.01).of(-5.49)
    expect(vec[2].y).to be_within(0.01).of(-3.88)
    expect(vec[2].z).to be_within(0.01).of( 4.87)
    expect(vec[3].x).to be_within(0.01).of(-6.45)
    expect(vec[3].y).to be_within(0.01).of(-3.85)
    expect(vec[3].z).to be_within(0.01).of( 6.33)

    # Adding a Frame & Divider object for w3.
    expect(w3.allowWindowPropertyFrameAndDivider).to be(true)
    expect(w3.setWindowPropertyFrameAndDivider(fd)).to be(true)
    width = w3.windowPropertyFrameAndDivider.get.frameWidth
    expect(width).to be_within(0.001).of(0.200)
    surface = TBD.properties(model, dad)
    expect(surface.nil?).to be(false)
    expect(surface.is_a?(Hash)).to be(true)
    expect(surface.key?(:windows)).to be(true)
    expect(surface[:windows].is_a?(Hash)).to be(true)
    expect(surface[:windows].key?("w3"))
    expect(surface[:windows]["w3"].is_a?(Hash)).to be(true)
    expect(surface[:windows]["w3"].key?(:gross)).to be(true)
    expect(surface[:windows]["w3"][:gross]).to be_within(0.01).of(1.1)
    expect(surface[:windows]["w3"].key?(:u)).to be(true)
    expect(surface[:windows]["w3"][:u]).to be_within(0.01).of(2.0)
    expect(surface[:windows]["w3"].key?(:points)).to be(true)
    ptz = surface[:windows]["w3"][:points]
    expect(ptz.size).to eq(3)
    vec = OpenStudio::Point3dVector.new
    ptz.each { |o| vec << OpenStudio::Point3d.new(o.x, o.y, o.z) }
    area = OpenStudio.getArea(vec)
    expect(area.empty?).to be(false)
    expect(area.get).to be_within(TOL).of(surface[:windows]["w3"][:area])
    expect(surface[:windows]["w3"][:gross]).to be_within(0.01).of(1.1)
    expect(vec[0].x).to be_within(0.01).of(-6.78)
    expect(vec[0].y).to be_within(0.01).of( 1.17)
    expect(vec[0].z).to be_within(0.01).of(11.19)
    expect(vec[1].x).to be_within(0.01).of(-7.56)
    expect(vec[1].y).to be_within(0.01).of(-0.72)
    expect(vec[1].z).to be_within(0.01).of(10.72)
    expect(vec[2].x).to be_within(0.01).of(-7.75)
    expect(vec[2].y).to be_within(0.01).of( 0.25)
    expect(vec[2].z).to be_within(0.01).of(11.83)
  end

  it "can flag errors and integrate TBD logs in JSON output" do
    TBD.clean!
    argh = {}

    translator = OpenStudio::OSVersion::VersionTranslator.new
    file = File.join(__dir__, "files/osms/in/warehouse.osm")
    path = OpenStudio::Path.new(file)
    os_model = translator.loadModel(path)
    expect(os_model.empty?).to be(false)
    os_model = os_model.get

    office = os_model.getSpaceByName("Zone1 Office")
    expect(office.empty?).to be(false)

    front_office_wall = os_model.getSurfaceByName("Office Front Wall")
    expect(front_office_wall.empty?).to be(false)
    front_office_wall = front_office_wall.get
    expect(front_office_wall.nameString).to eq("Office Front Wall")
    expect(front_office_wall.surfaceType).to eq("Wall")

    left_office_wall = os_model.getSurfaceByName("Office Left Wall")
    expect(left_office_wall.empty?).to be(false)
    left_office_wall = left_office_wall.get
    expect(left_office_wall.nameString).to eq("Office Left Wall")
    expect(left_office_wall.surfaceType).to eq("Wall")

    right_fine_wall = os_model.getSurfaceByName("Fine Storage Right Wall")
    expect(right_fine_wall.empty?).to be(false)
    right_fine_wall = right_fine_wall.get
    expect(right_fine_wall.nameString).to eq("Fine Storage Right Wall")
    expect(right_fine_wall.surfaceType).to eq("Wall")

    # Adding a small, 5-sided window to the "Office Front Wall" (above door).
    os_v = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 12.96, 0.00, 4.00)
    os_v << OpenStudio::Point3d.new( 12.04, 0.00, 3.50)
    os_v << OpenStudio::Point3d.new( 12.04, 0.00, 2.50)
    os_v << OpenStudio::Point3d.new( 13.87, 0.00, 2.50)
    os_v << OpenStudio::Point3d.new( 13.87, 0.00, 3.50)
    clerestory = OpenStudio::Model::SubSurface.new(os_v, os_model)
    clerestory.setName("clerestory")
    expect(clerestory.setSurface(front_office_wall)).to be(true)
    expect(clerestory.setSubSurfaceType("FixedWindow")).to be(true)
    # ... reminder: set subsurface type AFTER setting its parent surface.

    # A new, highly-conductive material (RSi = 0.001 m2.K/W) - the OS min.
    material = OpenStudio::Model::MasslessOpaqueMaterial.new(os_model)
    material.setName("poor material")
    expect(material.nameString).to eq("poor material")
    expect(material.setThermalResistance(0.001)).to be(true)
    expect(material.thermalResistance).to be_within(0.0001).of(0.001)
    mat = OpenStudio::Model::MaterialVector.new
    mat << material

    # A 'standard' variant (also gives RSi = 0.001 m2.K/W)
    material2 = OpenStudio::Model::StandardOpaqueMaterial.new(os_model)
    material2.setName("poor material2")
    expect(material2.nameString).to eq("poor material2")
    expect(material2.setThermalConductivity(3.0)).to be(true)
    expect(material2.thermalConductivity).to be_within(0.01).of(3.0)
    expect(material2.setThickness(0.003)).to be(true)
    expect(material2.thickness).to be_within(0.001).of(0.003)
    mat2 = OpenStudio::Model::MaterialVector.new
    mat2 << material2

    # Another 'massless' material, whose name already includes " tbd".
    material3 = OpenStudio::Model::MasslessOpaqueMaterial.new(os_model)
    material3.setName("poor material m tbd")
    expect(material3.nameString).to eq("poor material m tbd")
    expect(material3.setThermalResistance(1.0)).to be(true)
    expect(material3.thermalResistance).to be_within(0.1).of(1.0)
    mat3 = OpenStudio::Model::MaterialVector.new
    mat3 << material3

    # Assign highly-conductive material to a new construction.
    construction = OpenStudio::Model::Construction.new(os_model)
    construction.setName("poor construction")
    expect(construction.nameString).to eq("poor construction")
    expect(construction.layers.size).to eq(0)
    expect(construction.setLayers(mat2)).to be(true) # or switch with 'mat'
    expect(construction.layers.size).to eq(1)

    # Assign " tbd" massless material to a new construction.
    construction2 = OpenStudio::Model::Construction.new(os_model)
    construction2.setName("poor construction tbd")
    expect(construction2.nameString).to eq("poor construction tbd")
    expect(construction2.layers.size).to eq(0)
    expect(construction2.setLayers(mat3)).to be(true)
    expect(construction2.layers.size).to eq(1)

    # Assign construction to the "Office Left Wall".
    expect(left_office_wall.setConstruction(construction)).to be(true)

    # Assign construction2 to the "Fine Storage Right Wall".
    expect(right_fine_wall.setConstruction(construction2)).to be(true)

    subs = front_office_wall.subSurfaces
    expect(subs.empty?).to be(false)
    expect(subs.size).to eq(4)

    argh[:option] = "poor (BETBG)"
    argh[:io_path] = File.join(__dir__, "../json/tbd_warehouse9.json")
    # {
    #   "schema": "https://github.com/rd2/tbd/blob/master/tbd.schema.json",
    #   "description": "testing error detection",
    #   "psis": [
    #     {
    #       "id": "detailed 2",
    #       "fenestration": 0.600
    #     },
    #     {
    #       "id": "regular (BETBG)",   <<<< ERROR #1 - can't reset built-in sets
    #       "fenestration": 0.700
    #     }
    #   ],
    #   "khis": [
    #     {
    #       "id": "cantilevered beam",
    #       "point": 0.6
    #     }
    #   ],
    #   "surfaces": [
    #     {
    #       "id": "Office Front Wall",
    #       "khis": [
    #         {
    #           "id": "beam",      <<<< ERROR #2 - 'beam' not previously defined
    #           "count": 3
    #         }
    #       ]
    #     },
    #     {
    #       "id": "Office Left Wall",
    #       "khis": [
    #         {
    #           "id": "cantilevered beam",
    #           "count": 300      <<<< WARNING #1 - heat loss too great (for m2)
    #         }
    #       ]
    #     }
    #   ],
    #   "edges": [
    #     {
    #       "psi": "detailed", <<<< ERROR #3 - 'detailed' not previously defined
    #       "type": "fenestration",
    #       "surfaces": [
    #         "Office Front Wall",
    #         "Office Front Wall Window 1"
    #       ]
    #     }
    #   ]
    # }
    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")
    json = TBD.process(os_model, argh)
    expect(json.is_a?(Hash)).to be(true)
    expect(json.key?(:io)).to be(true)
    expect(json.key?(:surfaces)).to be(true)
    io       = json[:io]
    surfaces = json[:surfaces]
    expect(io.nil?).to be(false)
    expect(io.is_a?(Hash)).to be(true)
    expect(io.empty?).to be(false)
    expect(io.key?(:edges))
    expect(surfaces.nil?).to be(false)
    expect(surfaces.is_a?(Hash)).to be(true)
    expect(surfaces.size).to eq(23)
    expect(surfaces.key?("Office Front Wall")).to be(true)
    expect(surfaces["Office Front Wall"].key?(:edges)).to be(true)
    expect(surfaces.key?("Office Left Wall")).to be(true)
    expect(surfaces["Office Left Wall"].key?(:edges)).to be(true)
    expect(surfaces.key?("Fine Storage Right Wall")).to be(true)
    expect(surfaces["Fine Storage Right Wall"].key?(:edges)).to be(true)

    expect(TBD.status).to eq(ERR)
    expect(TBD.logs.size).to eq(6)
    # TBD.logs.each { |log| puts log[:msg] }
    #   'clerestory' vertex count (3 or 4)
    #   Can't override 'regular (BETBG)' PSI set  - skipping
    #   'Office Front Wall' KHI 'beam' mismatch
    #   'Office Front Wall' edge PSI set mismatch - skipping
    #   Can't assign 180.007 W/K to 'Office Left Wall' - too conductive
    #   Can't derate 'Fine Storage Right Wall' - material already derated

    # Despite input file (non-fatal) errors, TBD successfully processes thermal
    # bridges and derates OSM construction materials by falling back on defaults
    # in the case of errors.

    # For the 5-sided window, TBD will simply ignore all edges/bridges linked to
    # the 'clerestory' subsurface.
    io[:edges].each do |edge|
      expect(edge.key?(:surfaces)).to be(true)
      edge[:surfaces].each { |s| expect(s).to_not eq("clerestory") }
    end

    expect(surfaces["Office Front Wall"][:edges].size).to eq(17)
    sills = 0

    surfaces["Office Front Wall"][:edges].values.each do |e|
      expect(e.key?(:type)).to be(true)
      sills += 1 if e[:type] == :sill
    end

    expect(sills).to eq(2)                                               # not 3

    # Fallback to ERROR # 1: not really a fallback, more a demonstration that
    # "regular (BETBG)" isn't referred to by any edge-linked derated surfaces.
    # ... & fallback to ERROR # 3: no edge relying on 'detailed' PSI set.
    io[:edges].each { |edge| expect(edge[:psi]).to eq("poor (BETBG)") }

    # Fallback to ERROR # 2: no KHI for "Office Front Wall".
    expect(io.key?(:khis)).to be(true)
    expect(io[:khis].size).to eq(1)
    expect(surfaces["Office Front Wall"].key?(:khis)).to be(false)

    # ... concerning the "Office Left Wall" (underatable material).
    left_office_wall = os_model.getSurfaceByName("Office Left Wall")
    expect(left_office_wall.empty?).to be(false)
    left_office_wall = left_office_wall.get
    c = left_office_wall.construction.get.to_LayeredConstruction.get
    expect(c.numLayers).to eq(1)
    #layer = c.getLayer(0).to_MasslessOpaqueMaterial
    layer = c.getLayer(0).to_StandardOpaqueMaterial
    expect(layer.empty?).to be(false)
    layer = layer.get
    expect(layer.name.get).to eq("Office Left Wall m tbd")
    #expect(layer.thermalResistance).to be_within(0.001).of(0.001)
    expect(layer.thermalConductivity).to be_within(0.1).of(3.0)
    expect(layer.thickness).to be_within(0.001).of(0.003)
    # Regardless of the targetted material type ('standard' vs 'massless'), TBD
    # will ensure a minimal RSi value of 0.001 m2.K/W, i.e. no derating despite
    # the surface having thermal bridges.
    expect(surfaces["Office Left Wall"].key?(:heatloss)).to be(true)
    expect(surfaces["Office Left Wall"][:heatloss]).to be_within(0.1).of(180)
    expect(surfaces["Office Left Wall"].key?(:r_heatloss)).to be(true)
    expect(surfaces["Office Left Wall"][:r_heatloss]).to be_within(0.1).of(180)

    expect(surfaces["Fine Storage Right Wall"].key?(:heatloss)).to be(true)
    expect(surfaces["Fine Storage Right Wall"].key?(:r_heatloss)).to be(false)
    # ... concerning the new material (with a name already including " tbd").
    # TBD ignores all such materials (a safeguard against iterative TBD
    # runs). Contrary to the previous critical cases of highly conductive
    # materials, TBD doesn't even try to set the :r_heatloss hash value - tough!
    right_fine_wall = os_model.getSurfaceByName("Fine Storage Right Wall")
    expect(right_fine_wall.empty?).to be(false)
    right_fine_wall = right_fine_wall.get
    c = right_fine_wall.construction.get.to_LayeredConstruction.get
    layer = c.getLayer(0).to_MasslessOpaqueMaterial
    expect(layer.empty?).to be(false)
    layer = layer.get
    expect(layer.name.get).to eq("poor material m tbd")
    expect(layer.thermalResistance).to be_within(0.1).of(1.0)

    # Mimics (somewhat) the TBD 'measure.rb' method 'exitTBD()'
    # ... should generate a 'logs' entry at the  of the JSON output file.
    status = TBD.msg(TBD.status)
    status = TBD.msg(INF) if TBD.status.zero?

    tbd_log = { date: Time.now, status: status }

    results = []

    if surfaces
      surfaces.each do |id, surface|
        next if TBD.fatal?
        next unless surface.key?(:ratio)
        ratio  = format "%3.1f", surface[:ratio]
        name   = id.rjust(15, " ")
        output = "#{name} RSi derated by #{ratio}%"
        results << output
      end
    end

    tbd_log[:results] = results unless results.empty?

    tbd_msgs = []

    TBD.logs.each do |l|
      tbd_msgs << { level: TBD.tag(l[:level]), message: l[:message] }
    end

    tbd_log[:messages] = tbd_msgs unless tbd_msgs.empty?

    io[:log] = tbd_log

    # Deterministic sorting
    io[:schema     ] = io.delete(:schema     ) if io.key?(:schema)
    io[:description] = io.delete(:description) if io.key?(:description)
    io[:log        ] = io.delete(:log        ) if io.key?(:log)
    io[:psis       ] = io.delete(:psis       ) if io.key?(:psis)
    io[:khis       ] = io.delete(:khis       ) if io.key?(:khis)
    io[:building   ] = io.delete(:building   ) if io.key?(:building)
    io[:stories    ] = io.delete(:stories    ) if io.key?(:stories)
    io[:spacetypes ] = io.delete(:spacetypes ) if io.key?(:spacetypes)
    io[:spaces     ] = io.delete(:spaces     ) if io.key?(:spaces)
    io[:surfaces   ] = io.delete(:surfaces   ) if io.key?(:surfaces)
    io[:edges      ] = io.delete(:edges      ) if io.key?(:edges)

    out = JSON.pretty_generate(io)
    outP = File.join(__dir__, "../json/tbd_warehouse9.out.json")
    File.open(outP, "w") { |outP| outP.puts out }
    # ... should contain 'log' entries at the start of the JSON output file.
  end

  it "can process an OSM converted from an IDF (with rotation)" do
    TBD.clean!
    argh = {}

    translator = OpenStudio::OSVersion::VersionTranslator.new
    file = File.join(__dir__, "files/osms/in/5Zone_2.osm")
    path = OpenStudio::Path.new(file)
    os_model = translator.loadModel(path)
    expect(os_model.empty?).to be(false)
    os_model = os_model.get

    # Testing min/max cooling/heating setpoints
    setpoints = TBD.heatingTemperatureSetpoints?(os_model)
    setpoints = TBD.coolingTemperatureSetpoints?(os_model) || setpoints
    expect(setpoints).to be(true)
    airloops = TBD.airLoopsHVAC?(os_model)
    expect(airloops).to be(false)

    os_model.getSpaces.each do |space|
      expect(space.thermalZone.empty?).to be(false)
      zone = space.thermalZone.get
      heat_spt = TBD.maxHeatScheduledSetpoint(zone)
      cool_spt = TBD.minCoolScheduledSetpoint(zone)
      expect(heat_spt.key?(:spt)).to be(true)
      expect(cool_spt.key?(:spt)).to be(true)
      heating = heat_spt[:spt]
      cooling = cool_spt[:spt]

      if zone.nameString == "PLENUM-1 Thermal Zone"
        expect(TBD.plenum?(space, airloops, setpoints)).to be(false)
        expect(heating.nil?).to be(true)
        expect(cooling.nil?).to be(true)
        next
      end

      expect(TBD.plenum?(space, airloops, setpoints)).to be(false)
      expect(heating).to be_within(0.1).of(22.2)
      expect(cooling).to be_within(0.1).of(23.9)
    end

    # Tracking insulated ceiling surfaces below PLENUM.
    os_model.getSurfaces.each do |s|
      next unless s.surfaceType == "RoofCeiling"
      next if s.outsideBoundaryCondition == "Outdoors"
      expect(s.isConstructionDefaulted).to be(false)
      c = s.construction
      expect(c.empty?).to be(false)
      c = c.get.to_LayeredConstruction
      expect(c.empty?).to be(false)
      c = c.get
      id = c.nameString
      expect(id).to eq("CLNG-1")
      expect(c.layers.size).to eq(1)
      expect(c.layers[0].nameString).to eq("MAT-CLNG-1") # RSi 0.650
    end

    # Tracking outdoor-facing office walls.
    os_model.getSurfaces.each do |s|
      next unless s.surfaceType == "Wall"
      next unless s.outsideBoundaryCondition == "Outdoors"
      expect(s.isConstructionDefaulted).to be(false)
      c = s.construction
      expect(c.empty?).to be(false)
      c = c.get.to_LayeredConstruction
      expect(c.empty?).to be(false)
      c = c.get
      id = c.nameString
      expect(id).to eq("WALL-1")
      expect(c.layers.size).to eq(4)
      expect(c.layers[0].nameString).to eq("WD01") # RSi 0.165
      expect(c.layers[1].nameString).to eq("PW03") # RSI 0.110
      expect(c.layers[2].nameString).to eq("IN02") # RSi 2.090
      expect(c.layers[3].nameString).to eq("GP01") # RSi 0.079
    end

    argh[:option] = "poor (BETBG)"
    json = TBD.process(os_model, argh)
    expect(json.is_a?(Hash)).to be(true)
    expect(json.key?(:io)).to be(true)
    expect(json.key?(:surfaces)).to be(true)
    io       = json[:io]
    surfaces = json[:surfaces]
    expect(TBD.status).to eq(0)
    expect(TBD.logs.empty?).to be(true)
    expect(io.nil?).to be(false)
    expect(io.is_a?(Hash)).to be(true)
    expect(io.empty?).to be(false)
    expect(surfaces.nil?).to be(false)
    expect(surfaces.is_a?(Hash)).to be(true)
    expect(io.key?(:edges))
    expect(io[:edges].size).to eq(47)
    expect(surfaces.size).to eq(40)

    surfaces.each do |id, surface|
      expect(surface.key?(:conditioned)).to be(true)
      next unless surface[:conditioned]
      expect(surface.key?(:heating)).to be(true)
      expect(surface.key?(:cooling)).to be(true)

      # Testing glass door detection
      if surface.key?(:doors)
        surface[:doors].each do |i, door|
          expect(door.key?(:glazed)).to be(true)
          expect(door[:glazed]).to be(true)
          expect(door.key?(:u)).to be(true)
          expect(door[:u]).to be_a(Numeric)
          expect(door[:u]).to be_within(0.01).of(6.54)
        end
      end
    end

    ids = { a: "LEFT-1",
            b: "RIGHT-1",
            c: "FRONT-1",
            d: "BACK-1",
            e: "C1-1",
            f: "C2-1",
            g: "C3-1",
            h: "C4-1",
            i: "C5-1"  }.freeze

    surfaces.each do |id, surface|
      next if surface.key?(:edges)
      expect(ids.has_value?(id)).to be(false)
    end

    # Testing plenum/attic.
    surfaces.each do |id, surface|
      expect(surface.key?(:space)).to be(true)
      next unless surface[:space].nameString == "PLENUM-1"

      # Outdoor-facing surfaces are not derated.
      expect(surface.key?(:conditioned)).to be(true)
      expect(surface[:conditioned]).to be(false)
      expect(surface.key?(:heatloss)).to be(false)
      expect(surface.key?(:ratio)).to be(false)

      expect(surface.key?(:boundary)).to be(true)
      b = surface[:boundary]
      next if b == "Outdoors"

      # TBD/Topolys track adjacent CONDITIONED surface.
      expect(surfaces.key?(b)).to be(true)
      expect(surfaces[b].key?(:conditioned)).to be(true)
      expect(surfaces[b][:conditioned]).to be(true)

      next if id == "C5-1P"
      expect id == "C1-1P" || id == "C2-1P" || id == "C3-1P" || id == "C4-1P"
      expect(surfaces[b].key?(:heatloss)).to be(true)
      expect(surfaces[b].key?(:ratio)).to be(true)
      h = surfaces[b][:heatloss]
      expect(h).to be_within(0.01).of(5.79) if id == "C1-1P"
      expect(h).to be_within(0.01).of(2.89) if id == "C2-1P"
      expect(h).to be_within(0.01).of(5.79) if id == "C3-1P"
      expect(h).to be_within(0.01).of(2.89) if id == "C4-1P"
    end

    surfaces.each do |id, surface|
      next unless surface.key?(:edges)
      expect(ids.has_value?(id)).to be(true)
      expect(surface.key?(:heatloss)).to be(true)
      expect(surface.key?(:ratio)).to be(true) unless id == "C5-1"
      next if id == ids[:i]
      h = surface[:heatloss]

      s = os_model.getSurfaceByName(id)
      expect(s.empty?).to be(false)
      s = s.get
      expect(s.nameString).to eq(id)
      expect(s.isConstructionDefaulted).to be(false)
      expect(/ tbd/i.match(s.construction.get.nameString)).to_not eq(nil)
      expect(h).to be_within(0.01).of(0) if id == "C5-1"
      expect(h).to be_within(0.01).of(64.92) if id == "FRONT-1"
    end
  end

  it "can handle TDDs" do
    types = OpenStudio::Model::SubSurface.validSubSurfaceTypeValues
    expect(types.is_a?(Array)).to be(true)
    expect(types.include?("TubularDaylightDome")).to be(true)
    expect(types.include?("TubularDaylightDiffuser")).to be(true)

    TBD.clean!
    argh = {}

    translator = OpenStudio::OSVersion::VersionTranslator.new
    file = File.join(__dir__, "files/osms/in/warehouse.osm")
    path = OpenStudio::Path.new(file)
    os_model = translator.loadModel(path)
    expect(os_model.empty?).to be(false)
    os_model = os_model.get

    # As of v3.3.0, OpenStudio SDK (fully) supports Tubular Daylighting Devices:
    #
    #   https://bigladdersoftware.com/epx/docs/9-6/input-output-reference/
    #   group-daylighting.html#daylightingdevicetubular
    #
    #   https://openstudio-sdk-documentation.s3.amazonaws.com/cpp/
    #   OpenStudio-3.3.0-doc/model/html/
    #   classopenstudio_1_1model_1_1_daylighting_device_tubular.html

    methods = OpenStudio::Model::Model.instance_methods.grep(/tubular/i)
    version = os_model.getVersion.versionIdentifier.split('.').map(&:to_i)
    v = version.join.to_i
    expect(v).is_a?(Numeric)

    if v < 330
      expect(methods.empty?).to be(true)
    else
      expect(methods.empty?).to be(false)
    end

    # For SDK versions >= v3.3.0, testing new TDD methods.
    unless v < 330
      # Simple Glazing constructions for both dome & diffuser.
      fenestration = OpenStudio::Model::Construction.new(os_model)
      fenestration.setName("tubular_fenestration")
      expect(fenestration.nameString).to eq("tubular_fenestration")
      expect(fenestration.layers.size).to eq(0)

      glazing = OpenStudio::Model::SimpleGlazing.new(os_model)
      glazing.setName("tubular_glazing")
      expect(glazing.nameString).to eq("tubular_glazing")
      expect(glazing.setUFactor(6.0)).to be(true)
      expect(glazing.setSolarHeatGainCoefficient(0.50)).to be(true)
      expect(glazing.setVisibleTransmittance(0.70)).to be(true)

      layers = OpenStudio::Model::MaterialVector.new
      layers << glazing
      expect(fenestration.setLayers(layers)).to be(true)
      expect(fenestration.layers.size).to eq(1)
      expect(fenestration.layers[0].handle.to_s).to eq(glazing.handle.to_s)
      expect(fenestration.uFactor.empty?).to be(false)
      expect(fenestration.uFactor.get).to be_within(0.1).of(6.0)

      # Tube walls.
      construction = OpenStudio::Model::Construction.new(os_model)
      construction.setName("tube_construction")
      expect(construction.nameString).to eq("tube_construction")
      expect(construction.layers.size).to eq(0)

      interior = OpenStudio::Model::StandardOpaqueMaterial.new(os_model)
      interior.setName("tube_wall")
      expect(interior.nameString).to eq("tube_wall")
      expect(interior.setRoughness("MediumRough")).to be(true)
      expect(interior.setThickness(0.0126)).to be(true)
      expect(interior.setConductivity(0.16)).to be(true)
      expect(interior.setDensity(784.9)).to be(true)
      expect(interior.setSpecificHeat(830)).to be(true)
      expect(interior.setThermalAbsorptance(0.9)).to be(true)
      expect(interior.setSolarAbsorptance(0.9)).to be(true)
      expect(interior.setVisibleAbsorptance(0.9)).to be(true)

      layers = OpenStudio::Model::MaterialVector.new
      layers << interior
      expect(construction.setLayers(layers)).to be(true)
      expect(construction.layers.size).to eq(1)
      expect(construction.layers[0].handle.to_s).to eq(interior.handle.to_s)

      # Host spaces & surfaces.
      sp1 = "Zone1 Office"
      sp2 = "Zone2 Fine Storage"

      z = "Zone2 Fine Storage ZN"

      s1 = "Office Roof"              #  Office surface hosting new TDD diffuser
      s2 = "Office Roof Reversed"     #          FineStorage floor, above office
      s3 = "Fine Storage Roof"        # FineStorage surface hosting new TDD dome

      # Fetch host spaces & surfaces.
      office = os_model.getSpaceByName(sp1)
      expect(office.empty?).to be(false)
      office = office.get

      storage = os_model.getSpaceByName(sp2)
      expect(storage.empty?).to be(false)
      storage = storage.get

      zone = storage.thermalZone
      expect(zone.empty?).to be(false)
      zone = zone.get
      expect(zone.nameString).to eq(z)

      ceiling = os_model.getSurfaceByName(s1)
      expect(ceiling.empty?).to be(false)
      ceiling = ceiling.get
      sp = ceiling.space
      expect(sp.empty?).to be(false)
      sp = sp.get
      expect(sp).to eq(office)

      floor = os_model.getSurfaceByName(s2)
      expect(floor.empty?).to be(false)
      floor = floor.get
      sp = floor.space
      expect(sp.empty?).to be(false)
      sp = sp.get
      expect(sp).to eq(storage)

      adj = ceiling.adjacentSurface
      expect(adj.empty?).to be(false)
      adj = adj.get
      expect(adj).to eq(floor)

      adj = floor.adjacentSurface
      expect(adj.empty?).to be(false)
      adj = adj.get
      expect(adj).to eq(ceiling)

      roof = os_model.getSurfaceByName(s3)
      expect(roof.empty?).to be(false)
      roof = roof.get
      sp = roof.space
      expect(sp.empty?).to be(false)
      sp = sp.get
      expect(sp).to eq(storage)

      # Setting heights & Z-axis coordinates.
      ceiling_Z = ceiling.centroid.z
      roof_Z = roof.centroid.z
      length = roof_Z - ceiling_Z
      totalLength = length + 0.7
      dome_Z = ceiling_Z + totalLength

      # A new, 1mx1m diffuser subsurface in Office.
      os_v = OpenStudio::Point3dVector.new
      os_v << OpenStudio::Point3d.new( 11.0, 4.0, ceiling_Z)
      os_v << OpenStudio::Point3d.new( 11.0, 5.0, ceiling_Z)
      os_v << OpenStudio::Point3d.new( 10.0, 5.0, ceiling_Z)
      os_v << OpenStudio::Point3d.new( 10.0, 4.0, ceiling_Z)
      diffuser = OpenStudio::Model::SubSurface.new(os_v, os_model)
      diffuser.setName("diffuser")
      expect(diffuser.setConstruction(fenestration)).to be(true)
      expect(diffuser.setSubSurfaceType("TubularDaylightDiffuser")).to be(true)
      expect(diffuser.setSurface(ceiling)).to be(true)
      expect(diffuser.uFactor.empty?).to be(false)
      expect(diffuser.uFactor.get).to be_within(0.1).of(6.0)

      # A new, 1mx1m dome subsurface above Fine Storage roof.
      os_v = OpenStudio::Point3dVector.new
      os_v << OpenStudio::Point3d.new( 11.0, 4.0, dome_Z)
      os_v << OpenStudio::Point3d.new( 11.0, 5.0, dome_Z)
      os_v << OpenStudio::Point3d.new( 10.0, 5.0, dome_Z)
      os_v << OpenStudio::Point3d.new( 10.0, 4.0, dome_Z)
      dome = OpenStudio::Model::SubSurface.new(os_v, os_model)
      dome.setName("dome")
      expect(dome.setConstruction(fenestration)).to be(true)
      expect(dome.setSubSurfaceType("TubularDaylightDome")).to be(true)
      expect(dome.setSurface(roof)).to be(true)
      expect(dome.uFactor.empty?).to be(false)
      expect(dome.uFactor.get).to be_within(0.1).of(6.0)

      expect(ceiling.tilt).to be_within(0.01).of(diffuser.tilt)
      expect(dome.tilt).to be_within(0.01).of(roof.tilt)

      rsi = 0.28   # default effective TDD thermal resistance (dome to diffuser)
      diameter = Math.sqrt(dome.grossArea/Math::PI) * 2

      tdd = OpenStudio::Model::DaylightingDeviceTubular.new(
              dome, diffuser, construction)

      expect(tdd.setDiameter(diameter)).to be(true)
      expect(tdd.setTotalLength(totalLength)).to be(true)
      expect(tdd.addTransitionZone(zone, length)).to be(true)
      cl = OpenStudio::Model::TransitionZoneVector
      expect(tdd.transitionZones.class).to eq(cl)
      expect(tdd.numberofTransitionZones).to be(1)
      expect(tdd.totalLength).to be_within(0.001).of(totalLength)

      expect(tdd.subSurfaceDome).to eq(dome)
      expect(tdd.subSurfaceDiffuser).to eq(diffuser)
      c = tdd.construction
      expect(c.to_LayeredConstruction.empty?).to be(false)
      c = c.to_LayeredConstruction.get
      expect(c.nameString).to eq(construction.nameString)
      expect(tdd.diameter).to be_within(0.001).of(diameter)
      expect(tdd.effectiveThermalResistance).to be_within(0.01).of(rsi)

      pth = File.join(__dir__, "files/osms/out/tdd_warehouse.osm")
      os_model.save(pth, true)

      # Testing if TBD recognizes the TDD as a "skylight" (for derating & UA').
      argh[:option] = "poor (BETBG)"
      json = TBD.process(os_model, argh)
      expect(json.is_a?(Hash)).to be(true)
      expect(json.key?(:io)).to be(true)
      expect(json.key?(:surfaces)).to be(true)
      io       = json[:io]
      surfaces = json[:surfaces]
      expect(TBD.status).to eq(0)
      expect(TBD.logs.empty?).to be(true)
      expect(io.nil?).to be(false)
      expect(io.is_a?(Hash)).to be(true)
      expect(io.empty?).to be(false)
      expect(surfaces.nil?).to be(false)
      expect(surfaces.is_a?(Hash)).to be(true)
      expect(surfaces.size).to eq(23)
      expect(io.key?(:edges))

      # Both diffuser and parent (office) ceiling are stored as TBD 'surfaces'.
      expect(surfaces.key?(s1)).to be(true)
      surface = surfaces[s1]
      expect(surface.key?(:skylights)).to be(true)
      expect(surface[:skylights].size).to be(1)
      expect(surface[:skylights].key?("diffuser")).to be(true)
      skylight = surface[:skylights]["diffuser"]
      expect(skylight.is_a?(Hash)).to be(true)
      expect(skylight.key?(:u)).to be(true)
      expect(skylight[:u]).to be_a(Numeric)
      expect(skylight[:u]).to be_within(0.01).of(1/rsi)
      # ... yet TBD only derates constructions of opaque surfaces in CONDITIONED
      # spaces if:
      #
      #   (i) facing outdoors or
      #   (ii) facing UNCONDITIONED spaces like attics (see psi.rb).
      #
      # Here, the ceiling is not tagged by TBD as a deratable surface.
      # Diffuser edges are therefore not logged in TBD's 'edges'.
      expect(surface.key?(:heatloss)).to be(false)
      expect(surface.key?(:ratio)).to be(false)

      # Only edges of the dome (linked to the Fine Storage roof) are stored.
      io[:edges].each do |edge|
        expect(edge.is_a?(Hash)).to be(true)
        expect(edge.key?(:surfaces)).to be(true)
        expect(edge[:surfaces].is_a?(Array)).to be(true)

        edge[:surfaces].each do |id|
          next unless id == "dome" || id == "diffuser"
          expect(id).to eq("dome")
        end
      end

      expect(surfaces.key?(s3)).to be(true)
      surface = surfaces[s3]
      expect(surface.key?(:skylights)).to be(true)
      expect(surface[:skylights].size).to be(15)               # original 14x +1
      expect(surface[:skylights].key?("dome")).to be(true)

      surface[:skylights].each do |i, skylight|
        expect(skylight.key?(:u)).to be(true)
        expect(skylight[:u]).to be_a(Numeric)
        expect(skylight[:u]).to be_within(0.01).of(6.64) unless i == "dome"
        expect(skylight[:u]).to be_within(0.01).of(1/rsi) if i == "dome"
      end

      expect(surface.key?(:heatloss)).to be(true)
      expect(surface[:heatloss]).to be_within(0.01).of(89.16)         # +2.0 W/K
      expect(io[:edges].size).to eq(304)          # 4x extra edges for dome only

      out = JSON.pretty_generate(io)
      outP = File.join(__dir__, "../json/tbd_warehouse15.out.json")
      File.open(outP, "w") { |outP| outP.puts out }

      # Re-use the exported file as input for another warehouse.
      os_model2 = translator.loadModel(pth)
      expect(os_model2.empty?).to be(false)
      os_model2 = os_model2.get

      argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")
      argh[:io_path] = File.join(__dir__, "../json/tbd_warehouse15.out.json")
      json2 = TBD.process(os_model2, argh)
      expect(json2.is_a?(Hash)).to be(true)
      expect(json2.key?(:io)).to be(true)
      expect(json2.key?(:surfaces)).to be(true)
      io2      = json2[:io]
      surfaces = json2[:surfaces]
      expect(TBD.status).to eq(0)
      expect(TBD.logs.empty?).to be(true)
      expect(io.nil?).to be(false)
      expect(io.is_a?(Hash)).to be(true)
      expect(io.empty?).to be(false)
      expect(surfaces.nil?).to be(false)
      expect(surfaces.is_a?(Hash)).to be(true)
      expect(surfaces.size).to eq(23)

      # Now mimic (again) the export functionality of the measure.
      out2 = JSON.pretty_generate(io2)
      outP2 = File.join(__dir__, "../json/tbd_warehouse16.out.json")
      File.open(outP2, "w") { |outP2| outP2.puts out2 }

      # Both output files should be the same ...
      expect(FileUtils.identical?(outP, outP2)).to be(true)
    else
      # SDK pre-v3.3.0 testing on one of the existing skylights, as a tubular
      # TDD dome (without a complete TDD object).
      nom = "FineStorage_skylight_5"
      sky5 = os_model.getSubSurfaceByName(nom)
      expect(sky5.empty?).to be(false)
      sky5 = sky5.get
      expect(sky5.subSurfaceType.downcase).to eq("skylight")
      name = "U 1.17 SHGC 0.39 Simple Glazing Skylight U-1.17 SHGC 0.39 2"
      skylight = sky5.construction
      expect(skylight.empty?).to be(false)
      expect(skylight.get.nameString).to eq(name)

      expect(sky5.setSubSurfaceType("TubularDaylightDome")).to be(true)
      skylight = sky5.construction
      expect(skylight.empty?).to be(false)
      expect(skylight.get.nameString).to eq("Typical Interior Window")
      # Weird to see "Typical Interior Window" as a suitable construction for a
      # tubular skylight dome, but that's the assigned default construction in
      # the DOE prototype warehouse model.

      roof = os_model.getSurfaceByName("Fine Storage Roof")
      expect(roof.empty?).to be(false)
      roof = roof.get

      # Testing if TBD recognizes it as a "skylight" (for derating & UA').
      argh[:option] = "poor (BETBG)"
      json = TBD.process(os_model, argh)
      expect(json.is_a?(Hash)).to be(true)
      expect(json.key?(:io)).to be(true)
      expect(json.key?(:surfaces)).to be(true)
      io       = json[:io]
      surfaces = json[:surfaces]
      expect(TBD.status).to eq(0)
      expect(TBD.logs.empty?).to be(true)
      expect(io.nil?).to be(false)
      expect(io.is_a?(Hash)).to be(true)
      expect(io.empty?).to be(false)
      expect(surfaces.nil?).to be(false)
      expect(surfaces.is_a?(Hash)).to be(true)
      expect(io.key?(:edges))
      expect(io[:edges].size).to eq(300)
      expect(surfaces.size).to eq(23)
      expect(TBD.status).to eq(0)
      expect(TBD.logs.size).to eq(0)

      expect(surfaces.key?("Fine Storage Roof")).to be(true)
      surface = surfaces["Fine Storage Roof"]

      if surface.key?(:skylights)
        expect(surface[:skylights].key?(nom)).to be(true)

        surface[:skylights].each do |i, skylight|
          expect(skylight.key?(:u)).to be(true)
          expect(skylight[:u]).to be_a(Numeric)
          expect(skylight[:u]).to be_within(0.01).of(6.64) unless i == nom
          expect(skylight[:u]).to be_within(0.01).of(7.18) if i == nom
          # So TBD processes any subsurface perimeter, whether skylight, TDD,
          # etc. And it retrieves a calculated U-factor for TBD's UA' trade-off
          # calculations. A follow-up OpenStudio-launched EnergyPlus simulation
          # reveals that, despite having an incomplete TDD setup:
          #
          #   dome > tube > diffuser
          #
          # ... EnergyPlus will proceed without warning(s) for OpenStudio
          # < v3.3.0. Results reflect an expected increase in heating energy
          # (Climate Zone 7), due to the poor(er) performance of the dome.
        end
      end
    end
  end

  it "can handle TDDs in attics (false plenums)" do
    TBD.clean!
    argh = {}

    translator = OpenStudio::OSVersion::VersionTranslator.new
    file = File.join(__dir__, "files/osms/in/5Zone_2.osm")
    path = OpenStudio::Path.new(file)
    os_model = translator.loadModel(path)
    expect(os_model.empty?).to be(false)
    os_model = os_model.get

    version = os_model.getVersion.versionIdentifier.split('.').map(&:to_i)
    v = version.join.to_i
    expect(v).is_a?(Numeric)

    # For SDK versions >= v3.3.0, testing new DaylightingTubularDevice methods.
    unless v < 330
      # Both dome & diffuser: Simple Glazing constructions.
      fenestration = OpenStudio::Model::Construction.new(os_model)
      fenestration.setName("tubular_fenestration")
      expect(fenestration.nameString).to eq("tubular_fenestration")
      expect(fenestration.layers.size).to eq(0)

      glazing = OpenStudio::Model::SimpleGlazing.new(os_model)
      glazing.setName("tubular_glazing")
      expect(glazing.nameString).to eq("tubular_glazing")
      expect(glazing.setUFactor(6.0)).to be(true)
      expect(glazing.setSolarHeatGainCoefficient(0.50)).to be(true)
      expect(glazing.setVisibleTransmittance(0.70)).to be(true)

      layers = OpenStudio::Model::MaterialVector.new
      layers << glazing
      expect(fenestration.setLayers(layers)).to be(true)
      expect(fenestration.layers.size).to eq(1)
      expect(fenestration.layers[0].handle.to_s).to eq(glazing.handle.to_s)
      expect(fenestration.uFactor.empty?).to be(false)
      expect(fenestration.uFactor.get).to be_within(0.1).of(6.0)

      # Tube walls.
      construction = OpenStudio::Model::Construction.new(os_model)
      construction.setName("tube_construction")
      expect(construction.nameString).to eq("tube_construction")
      expect(construction.layers.size).to eq(0)

      interior = OpenStudio::Model::StandardOpaqueMaterial.new(os_model)
      interior.setName("tube_wall")
      expect(interior.nameString).to eq("tube_wall")
      expect(interior.setRoughness("MediumRough")).to be(true)
      expect(interior.setThickness(0.0126)).to be(true)
      expect(interior.setConductivity(0.16)).to be(true)
      expect(interior.setDensity(784.9)).to be(true)
      expect(interior.setSpecificHeat(830)).to be(true)
      expect(interior.setThermalAbsorptance(0.9)).to be(true)
      expect(interior.setSolarAbsorptance(0.9)).to be(true)
      expect(interior.setVisibleAbsorptance(0.9)).to be(true)

      layers = OpenStudio::Model::MaterialVector.new
      layers << interior
      expect(construction.setLayers(layers)).to be(true)
      expect(construction.layers.size).to eq(1)
      expect(construction.layers[0].handle.to_s).to eq(interior.handle.to_s)

      # Host spaces & surfaces.
      sp1 = "SPACE5-1"
      sp2 = "PLENUM-1"

      z = "PLENUM-1 Thermal Zone"

      s1 = "C5-1"  # sp1 surface hosting new TDD diffuser
      s2 = "C5-1P" # plenum surface, above sp1
      s3 = "TOP-1" # plenum surface hosting new TDD dome

      # Fetch host spaces & surfaces.
      space = os_model.getSpaceByName(sp1)
      expect(space.empty?).to be(false)
      space = space.get

      plenum = os_model.getSpaceByName(sp2)
      expect(plenum.empty?).to be(false)
      plenum = plenum.get

      zone = plenum.thermalZone
      expect(zone.empty?).to be(false)
      zone = zone.get
      expect(zone.nameString).to eq(z)

      ceiling = os_model.getSurfaceByName(s1)
      expect(ceiling.empty?).to be(false)
      ceiling = ceiling.get
      sp = ceiling.space
      expect(sp.empty?).to be(false)
      sp = sp.get
      expect(sp).to eq(space)

      floor = os_model.getSurfaceByName(s2)
      expect(floor.empty?).to be(false)
      floor = floor.get
      sp = floor.space
      expect(sp.empty?).to be(false)
      sp = sp.get
      expect(sp).to eq(plenum)

      adj = ceiling.adjacentSurface
      expect(adj.empty?).to be(false)
      adj = adj.get
      expect(adj).to eq(floor)

      adj = floor.adjacentSurface
      expect(adj.empty?).to be(false)
      adj = adj.get
      expect(adj).to eq(ceiling)

      roof = os_model.getSurfaceByName(s3)
      expect(roof.empty?).to be(false)
      roof = roof.get
      sp = roof.space
      expect(sp.empty?).to be(false)
      sp = sp.get
      expect(sp).to eq(plenum)

      # Setting heights & Z-axis coordinates.
      ceiling_Z = ceiling.centroid.z
      roof_Z = roof.centroid.z
      length = roof_Z - ceiling_Z
      totalLength = length + 0.5
      dome_Z = ceiling_Z + totalLength

      # A new, 1mx1m diffuser subsurface in space ceiling.
      os_v = OpenStudio::Point3dVector.new
      os_v << OpenStudio::Point3d.new( 15.75,  7.15, ceiling_Z)
      os_v << OpenStudio::Point3d.new( 15.75,  8.15, ceiling_Z)
      os_v << OpenStudio::Point3d.new( 14.75,  8.15, ceiling_Z)
      os_v << OpenStudio::Point3d.new( 14.75,  7.15, ceiling_Z)
      diffuser = OpenStudio::Model::SubSurface.new(os_v, os_model)
      diffuser.setName("diffuser")
      expect(diffuser.setConstruction(fenestration)).to be(true)
      expect(diffuser.setSubSurfaceType("TubularDaylightDiffuser")).to be(true)
      expect(diffuser.setSurface(ceiling)).to be(true)
      expect(diffuser.uFactor.empty?).to be(false)
      expect(diffuser.uFactor.get).to be_within(0.1).of(6.0)

      # A new, 1mx1m dome subsurface above Plenum roof.
      os_v = OpenStudio::Point3dVector.new
      os_v << OpenStudio::Point3d.new( 15.75,  7.15, dome_Z)
      os_v << OpenStudio::Point3d.new( 15.75,  8.15, dome_Z)
      os_v << OpenStudio::Point3d.new( 14.75,  8.15, dome_Z)
      os_v << OpenStudio::Point3d.new( 14.75,  7.15, dome_Z)
      dome = OpenStudio::Model::SubSurface.new(os_v, os_model)
      dome.setName("dome")
      expect(dome.setConstruction(fenestration)).to be(true)
      expect(dome.setSubSurfaceType("TubularDaylightDome")).to be(true)
      expect(dome.setSurface(roof)).to be(true)
      expect(dome.uFactor.empty?).to be(false)
      expect(dome.uFactor.get).to be_within(0.1).of(6.0)

      expect(ceiling.tilt).to be_within(0.01).of(diffuser.tilt)
      expect(dome.tilt).to be_within(0.01).of(roof.tilt)

      rsi = 0.28
      diameter = Math.sqrt(dome.grossArea/Math::PI) * 2

      tdd = OpenStudio::Model::DaylightingDeviceTubular.new(
              dome, diffuser, construction, diameter, totalLength, rsi)

      expect(tdd.addTransitionZone(zone, length)).to be(true)
      cl = OpenStudio::Model::TransitionZoneVector
      expect(tdd.transitionZones.class).to eq(cl)
      expect(tdd.numberofTransitionZones).to be(1)
      expect(tdd.totalLength).to be_within(0.001).of(totalLength)

      expect(tdd.subSurfaceDome).to eq(dome)
      expect(tdd.subSurfaceDiffuser).to eq(diffuser)
      c = tdd.construction
      expect(c.to_LayeredConstruction.empty?).to be(false)
      c = c.to_LayeredConstruction.get
      expect(c.nameString).to eq(construction.nameString)
      expect(tdd.diameter).to be_within(0.001).of(diameter)
      expect(tdd.effectiveThermalResistance).to be_within(0.01).of(rsi)

      pth = File.join(__dir__, "files/osms/out/tdd_5Z_test.osm")
      os_model.save(pth, true)

      # Testing if TBD recognizes the TDD as a "skylight" (for derating & UA').
      argh[:option] = "poor (BETBG)"
      json = TBD.process(os_model, argh)
      expect(json.is_a?(Hash)).to be(true)
      expect(json.key?(:io)).to be(true)
      expect(json.key?(:surfaces)).to be(true)
      io       = json[:io]
      surfaces = json[:surfaces]
      expect(TBD.status).to eq(0)
      expect(TBD.logs.empty?).to be(true)
      expect(io.nil?).to be(false)
      expect(io.is_a?(Hash)).to be(true)
      expect(io.empty?).to be(false)
      expect(surfaces.nil?).to be(false)
      expect(surfaces.is_a?(Hash)).to be(true)
      expect(surfaces.size).to eq(40)
      expect(io.key?(:edges))

      # Both diffuser and parent ceiling are stored as TBD 'surfaces'.
      expect(surfaces.key?(s1)).to be(true)
      surface = surfaces[s1]
      expect(surface.key?(:skylights)).to be(true)
      expect(surface[:skylights].size).to be(1)
      expect(surface[:skylights].key?("diffuser")).to be(true)
      skylight = surface[:skylights]["diffuser"]
      expect(skylight.key?(:u)).to be(true)
      expect(skylight[:u]).to be_a(Numeric)
      expect(skylight[:u]).to be_within(0.01).of(1/rsi)

      # ... yet TBD only derates constructions of opaque surfaces in CONDITIONED
      # spaces IF (i) facing outdoors or (ii) facing UNCONDITIONED spaces like
      # attics (see psi.rb). Here, the ceiling is tagged by TBD as a deratable
      # surface, and hence the diffuser edges are logged in TBD's 'edges'.
      expect(surface.key?(:heatloss)).to be(true)
      expect(surface.key?(:ratio)).to be(true)
      expect(surface[:heatloss]).to be_within(0.01).of(2.00)      # 4x 0.500 W/K

      # Only edges of the diffuser (linked to the ceiling) are stored.
      io[:edges].each do |edge|
        expect(edge.is_a?(Hash)).to be(true)
        expect(edge.key?(:surfaces)).to be(true)
        expect(edge[:surfaces].is_a?(Array)).to be(true)

        edge[:surfaces].each do |id|
          next unless id == "dome" || id == "diffuser"
          expect(id).to eq("diffuser")
        end
      end

      expect(surfaces.key?(s3)).to be(true)
      surface = surfaces[s3]
      expect(surface.key?(:skylights)).to be(true)
      expect(surface[:skylights].size).to be(1)
      expect(surface[:skylights].key?("dome")).to be(true)
      skylight = surface[:skylights]["dome"]
      expect(skylight.key?(:u)).to be(true)
      expect(skylight[:u]).to be_a(Numeric)
      expect(skylight[:u]).to be_within(0.01).of(1/rsi)
      expect(surface.key?(:heatloss)).to be(false)
      expect(surface.key?(:ratio)).to be(false)

      expect(io[:edges].size).to eq(51) # 4x extra edges for diffuser - not dome

      out = JSON.pretty_generate(io)
      outP = File.join(__dir__, "../json/tbd_5Z.out.json")
      File.open(outP, "w") { |outP| outP.puts out }

      # Re-use the exported file as input for another 5Z test.
      os_model2 = translator.loadModel(pth)
      expect(os_model2.empty?).to be(false)
      os_model2 = os_model2.get

      argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")
      argh[:io_path] = File.join(__dir__, "../json/tbd_5Z.out.json")
      json2 = TBD.process(os_model2, argh)
      expect(json2.is_a?(Hash)).to be(true)
      expect(json2.key?(:io)).to be(true)
      expect(json2.key?(:surfaces)).to be(true)
      io2      = json2[:io]
      surfaces = json2[:surfaces]
      expect(TBD.status).to eq(0)
      expect(TBD.logs.empty?).to be(true)
      expect(io2.nil?).to be(false)
      expect(io2.is_a?(Hash)).to be(true)
      expect(io2.empty?).to be(false)
      expect(surfaces.nil?).to be(false)
      expect(surfaces.is_a?(Hash)).to be(true)
      expect(surfaces.size).to eq(40)

      # Now mimic (again) the export functionality of the measure.
      out2 = JSON.pretty_generate(io2)
      outP2 = File.join(__dir__, "../json/tbd_5Z_2.out.json")
      File.open(outP2, "w") { |outP2| outP2.puts out2 }

      # Both output files should be the same ...
      expect(FileUtils.identical?(outP, outP2)).to be(true)
    end
  end

  it "can handle TDDs in attics" do
    TBD.clean!
    argh = {}

    translator = OpenStudio::OSVersion::VersionTranslator.new
    file = File.join(__dir__, "files/osms/in/smalloffice.osm")
    path = OpenStudio::Path.new(file)
    os_model = translator.loadModel(path)
    expect(os_model.empty?).to be(false)
    os_model = os_model.get

    version = os_model.getVersion.versionIdentifier.split('.').map(&:to_i)
    v = version.join.to_i
    expect(v).is_a?(Numeric)

    # For SDK versions >= v3.3.0, testing new DaylightingTubularDevice methods.
    unless v < 330
      # Both dome & diffuser: Simple Glazing constructions.
      fenestration = OpenStudio::Model::Construction.new(os_model)
      fenestration.setName("tubular_fenestration")
      expect(fenestration.nameString).to eq("tubular_fenestration")
      expect(fenestration.layers.size).to eq(0)

      glazing = OpenStudio::Model::SimpleGlazing.new(os_model)
      glazing.setName("tubular_glazing")
      expect(glazing.nameString).to eq("tubular_glazing")
      expect(glazing.setUFactor(6.0)).to be(true)
      expect(glazing.setSolarHeatGainCoefficient(0.50)).to be(true)
      expect(glazing.setVisibleTransmittance(0.70)).to be(true)

      layers = OpenStudio::Model::MaterialVector.new
      layers << glazing
      expect(fenestration.setLayers(layers)).to be(true)
      expect(fenestration.layers.size).to eq(1)
      expect(fenestration.layers[0].handle.to_s).to eq(glazing.handle.to_s)
      expect(fenestration.uFactor.empty?).to be(false)
      expect(fenestration.uFactor.get).to be_within(0.1).of(6.0)

      # Tube walls.
      construction = OpenStudio::Model::Construction.new(os_model)
      construction.setName("tube_construction")
      expect(construction.nameString).to eq("tube_construction")
      expect(construction.layers.size).to eq(0)

      interior = OpenStudio::Model::StandardOpaqueMaterial.new(os_model)
      interior.setName("tube_wall")
      expect(interior.nameString).to eq("tube_wall")
      expect(interior.setRoughness("MediumRough")).to be(true)
      expect(interior.setThickness(0.0126)).to be(true)
      expect(interior.setConductivity(0.16)).to be(true)
      expect(interior.setDensity(784.9)).to be(true)
      expect(interior.setSpecificHeat(830)).to be(true)
      expect(interior.setThermalAbsorptance(0.9)).to be(true)
      expect(interior.setSolarAbsorptance(0.9)).to be(true)
      expect(interior.setVisibleAbsorptance(0.9)).to be(true)

      layers = OpenStudio::Model::MaterialVector.new
      layers << interior
      expect(construction.setLayers(layers)).to be(true)
      expect(construction.layers.size).to eq(1)
      expect(construction.layers[0].handle.to_s).to eq(interior.handle.to_s)

      # Host spaces & surfaces.
      sp1 = "Core_ZN"
      sp2 = "Attic"
      z = "Attic ZN"
      s1 = "Core_ZN_ceiling"  # sp1 surface hosting new TDD diffuser
      s2 = "Attic_floor_core" # attic surface, above sp1
      s3 = "Attic_roof_north" # attic surface hosting new TDD dome

      # Fetch host spaces & surfaces.
      core = os_model.getSpaceByName(sp1)
      expect(core.empty?).to be(false)
      core = core.get

      attic = os_model.getSpaceByName(sp2)
      expect(attic.empty?).to be(false)
      attic = attic.get

      zone = attic.thermalZone
      expect(zone.empty?).to be(false)
      zone = zone.get
      expect(zone.nameString).to eq(z)

      ceiling = os_model.getSurfaceByName(s1)
      expect(ceiling.empty?).to be(false)
      ceiling = ceiling.get
      sp = ceiling.space
      expect(sp.empty?).to be(false)
      sp = sp.get
      expect(sp).to eq(core)

      floor = os_model.getSurfaceByName(s2)
      expect(floor.empty?).to be(false)
      floor = floor.get
      sp = floor.space
      expect(sp.empty?).to be(false)
      sp = sp.get
      expect(sp).to eq(attic)

      adj = ceiling.adjacentSurface
      expect(adj.empty?).to be(false)
      adj = adj.get
      expect(adj).to eq(floor)

      adj = floor.adjacentSurface
      expect(adj.empty?).to be(false)
      adj = adj.get
      expect(adj).to eq(ceiling)

      roof = os_model.getSurfaceByName(s3)
      expect(roof.empty?).to be(false)
      roof = roof.get
      sp = roof.space
      expect(sp.empty?).to be(false)
      sp = sp.get
      expect(sp).to eq(attic)

      # Setting heights & Z-axis coordinates.
      ceiling_Z = 3.05
      roof_Z = 5.51
      length = roof_Z - ceiling_Z
      totalLength = length + 1.0
      dome_Z = ceiling_Z + totalLength

      # A new, 1mx1m diffuser subsurface in Core ceiling.
      os_v = OpenStudio::Point3dVector.new
      os_v << OpenStudio::Point3d.new( 14.345, 10.845, ceiling_Z)
      os_v << OpenStudio::Point3d.new( 14.345, 11.845, ceiling_Z)
      os_v << OpenStudio::Point3d.new( 13.345, 11.845, ceiling_Z)
      os_v << OpenStudio::Point3d.new( 13.345, 10.845, ceiling_Z)
      diffuser = OpenStudio::Model::SubSurface.new(os_v, os_model)
      diffuser.setName("diffuser")
      expect(diffuser.setConstruction(fenestration)).to be(true)
      expect(diffuser.setSubSurfaceType("TubularDaylightDiffuser")).to be(true)
      expect(diffuser.setSurface(ceiling)).to be(true)
      expect(diffuser.uFactor.empty?).to be(false)
      expect(diffuser.uFactor.get).to be_within(0.1).of(6.0)

      # A new, 1mx1m dome subsurface above Attic roof.
      os_v = OpenStudio::Point3dVector.new
      os_v << OpenStudio::Point3d.new( 14.345, 10.845, dome_Z)
      os_v << OpenStudio::Point3d.new( 14.345, 11.845, dome_Z)
      os_v << OpenStudio::Point3d.new( 13.345, 11.845, dome_Z)
      os_v << OpenStudio::Point3d.new( 13.345, 10.845, dome_Z)
      dome = OpenStudio::Model::SubSurface.new(os_v, os_model)
      dome.setName("dome")
      expect(dome.setConstruction(fenestration)).to be(true)
      expect(dome.setSubSurfaceType("TubularDaylightDome")).to be(true)
      expect(dome.setSurface(roof)).to be(true)
      expect(dome.uFactor.empty?).to be(false)
      expect(dome.uFactor.get).to be_within(0.1).of(6.0)

      expect(ceiling.tilt).to be_within(0.01).of(diffuser.tilt)
      expect(dome.tilt).to be_within(0.01).of(0.0)
      expect(roof.tilt).to be_within(0.01).of(0.32)

      rsi = 0.28
      diameter = Math.sqrt(dome.grossArea/Math::PI) * 2

      tdd = OpenStudio::Model::DaylightingDeviceTubular.new(
              dome, diffuser, construction, diameter, totalLength, rsi)

      expect(tdd.addTransitionZone(zone, length)).to be(true)
      cl = OpenStudio::Model::TransitionZoneVector
      expect(tdd.transitionZones.class).to eq(cl)
      expect(tdd.numberofTransitionZones).to be(1)
      expect(tdd.totalLength).to be_within(0.001).of(totalLength)

      expect(tdd.subSurfaceDome).to eq(dome)
      expect(tdd.subSurfaceDiffuser).to eq(diffuser)
      c = tdd.construction
      expect(c.to_LayeredConstruction.empty?).to be(false)
      c = c.to_LayeredConstruction.get
      expect(c.nameString).to eq(construction.nameString)
      expect(tdd.diameter).to be_within(0.001).of(diameter)
      expect(tdd.effectiveThermalResistance).to be_within(0.01).of(rsi)

      pth = File.join(__dir__, "files/osms/out/tdd_smalloffice_test.osm")
      os_model.save(pth, true)

      # Testing if TBD recognizes the TDD as a "skylight" (for derating & UA').
      argh[:option] = "poor (BETBG)"
      json = TBD.process(os_model, argh)
      expect(json.is_a?(Hash)).to be(true)
      expect(json.key?(:io)).to be(true)
      expect(json.key?(:surfaces)).to be(true)
      io       = json[:io]
      surfaces = json[:surfaces]
      expect(TBD.status).to eq(0)
      expect(TBD.logs.empty?).to be(true)
      expect(io.nil?).to be(false)
      expect(io.is_a?(Hash)).to be(true)
      expect(io.empty?).to be(false)
      expect(surfaces.nil?).to be(false)
      expect(surfaces.is_a?(Hash)).to be(true)
      expect(surfaces.size).to eq(43)
      expect(io.key?(:edges))

      # Both diffuser and parent ceiling are stored as TBD 'surfaces'.
      expect(surfaces.key?(s1)).to be(true)
      surface = surfaces[s1]
      expect(surface.key?(:skylights)).to be(true)
      expect(surface[:skylights].key?("diffuser")).to be(true)
      skylight = surface[:skylights]["diffuser"]
      expect(skylight.key?(:u)).to be(true)
      expect(skylight[:u]).to be_a(Numeric)
      expect(skylight[:u]).to be_within(0.01).of(1/rsi)

      # ... yet TBD only derates constructions of opaque surfaces in CONDITIONED
      # spaces IF (i) facing outdoors or (ii) facing UNCONDITIONED spaces like
      # attics (see psi.rb). Here, the ceiling is tagged by TBD as a deratable
      # surface, and hence the diffuser edges are logged in TBD's 'edges'.
      expect(surface.key?(:heatloss)).to be(true)
      expect(surface.key?(:ratio)).to be(true)
      expect(surface[:heatloss]).to be_within(0.01).of(2.00)      # 4x 0.500 W/K

      # Only edges of the diffuser (linked to the ceiling) are stored.
      io[:edges].each do |edge|
        expect(edge.is_a?(Hash)).to be(true)
        expect(edge.key?(:surfaces)).to be(true)
        expect(edge[:surfaces].is_a?(Array)).to be(true)

        edge[:surfaces].each do |id|
          next unless id == "dome" || id == "diffuser"
          expect(id).to eq("diffuser")
        end
      end

      expect(surfaces.key?(s3)).to be(true)
      surface = surfaces[s3]
      expect(surface.key?(:skylights)).to be(true)
      expect(surface[:skylights].key?("dome")).to be(true)
      skylight = surface[:skylights]["dome"]
      expect(skylight.key?(:u)).to be(true)
      expect(skylight[:u]).to be_a(Numeric)
      expect(skylight[:u]).to be_within(0.01).of(1/rsi)
      expect(surface.key?(:heatloss)).to be(false)
      expect(surface.key?(:ratio)).to be(false)

      expect(io[:edges].size).to eq(109)      # 4x extra edges for diffuser only

      out = JSON.pretty_generate(io)
      outP = File.join(__dir__, "../json/tbd_smalloffice1.out.json")
      File.open(outP, "w") { |outP| outP.puts out }

      # Re-use the exported file as input for another test.
      os_model2 = translator.loadModel(pth)
      expect(os_model2.empty?).to be(false)
      os_model2 = os_model2.get

      argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")
      argh[:io_path] = File.join(__dir__, "../json/tbd_smalloffice1.out.json")
      json2 = TBD.process(os_model2, argh)
      expect(json2.is_a?(Hash)).to be(true)
      expect(json2.key?(:io)).to be(true)
      expect(json2.key?(:surfaces)).to be(true)
      io2      = json2[:io]
      surfaces = json2[:surfaces]
      expect(TBD.status).to eq(0)
      expect(TBD.logs.empty?).to be(true)
      expect(io.nil?).to be(false)
      expect(io.is_a?(Hash)).to be(true)
      expect(io.empty?).to be(false)
      expect(surfaces.nil?).to be(false)
      expect(surfaces.is_a?(Hash)).to be(true)
      expect(surfaces.size).to eq(43)

      # Now mimic (again) the export functionality of the measure.
      out2 = JSON.pretty_generate(io2)
      outP2 = File.join(__dir__, "../json/tbd_smalloffice2.out.json")
      File.open(outP2, "w") { |outP2| outP2.puts out2 }

      # Both output files should be the same ...
      expect(FileUtils.identical?(outP, outP2)).to be(true)
    end
  end

  it "can handle air gaps as materials" do
    TBD.clean!
    argh = {}

    translator = OpenStudio::OSVersion::VersionTranslator.new
    file = File.join(__dir__, "files/osms/in/warehouse.osm")
    path = OpenStudio::Path.new(file)
    os_model = translator.loadModel(path)
    expect(os_model.empty?).to be(false)
    os_model = os_model.get

    id = "Bulk Storage Rear Wall"
    s = os_model.getSurfaceByName(id)
    expect(s.empty?).to be(false)
    s = s.get
    expect(s.nameString).to eq(id)
    expect(s.surfaceType).to eq("Wall")
    expect(s.isConstructionDefaulted).to be(true)
    c = s.construction.get.to_LayeredConstruction
    expect(c.empty?).to be(false)
    c = c.get
    expect(c.numLayers).to eq(3)

    gap = OpenStudio::Model::AirGap.new(os_model)
    expect(gap.handle.to_s.empty?).to be(false)
    expect(gap.nameString.empty?).to be(false)
    expect(gap.nameString).to eq("Material Air Gap 1")
    gap.setName("#{id} air gap")
    expect(gap.nameString).to eq("#{id} air gap")
    expect(gap.setThermalResistance(0.180)).to be(true)
    expect(gap.thermalResistance).to be_within(0.01).of(0.180)
    expect(c.insertLayer(1, gap)).to be(true)
    expect(c.numLayers).to eq(4)

    pth = File.join(__dir__, "files/osms/out/warehouse_airgap.osm")
    os_model.save(pth, true)

    argh[:option] = "poor (BETBG)"
    json = TBD.process(os_model, argh)
    expect(json.is_a?(Hash)).to be(true)
    expect(json.key?(:io)).to be(true)
    expect(json.key?(:surfaces)).to be(true)
    io       = json[:io]
    surfaces = json[:surfaces]
    expect(TBD.status).to eq(0)
  end

  it "can uprate (ALL roof) constructions" do
    TBD.clean!
    argh = {}

    translator = OpenStudio::OSVersion::VersionTranslator.new
    file = File.join(__dir__, "files/osms/in/warehouse.osm")
    path = OpenStudio::Path.new(file)
    os_model = translator.loadModel(path)
    expect(os_model.empty?).to be(false)
    os_model = os_model.get

    # Mimics measure.
    walls = {c: {}, dft: "ALL wall constructions"}
    roofs = {c: {}, dft: "ALL roof constructions"}
    flors = {c: {}, dft: "ALL floor constructions"}
    walls[:c][walls[:dft]] = {a: 100000000000000}
    roofs[:c][roofs[:dft]] = {a: 100000000000000}
    flors[:c][flors[:dft]] = {a: 100000000000000}
    walls[:chx] = OpenStudio::StringVector.new
    roofs[:chx] = OpenStudio::StringVector.new
    flors[:chx] = OpenStudio::StringVector.new

    os_model.getSurfaces.each do |s|
      type = s.surfaceType.downcase
      next unless type == "wall" || type == "roofceiling" || type == "floor"
      next unless s.outsideBoundaryCondition.downcase == "outdoors"
      next if s.construction.empty?
      next if s.construction.get.to_LayeredConstruction.empty?
      lc = s.construction.get.to_LayeredConstruction.get
      id = lc.nameString
      next if walls[:c].key?(id)
      next if roofs[:c].key?(id)
      next if flors[:c].key?(id)
      a = lc.getNetArea

      # One challenge of the uprate approach concerns OpenStudio-reported
      # surface film resistances, which factor-in the slope of the surface and
      # surface emittances. As the uprate approach relies on user-defined Ut
      # factors (inputs, as targets to meet), it also considers surface film
      # resistances. In the schematic cross-section below, let's postulate that
      # each slope has a unique pitch: 50° (s1), 0° (s2), & 60° (s3). All three
      # surfaces reference the same construction.
      #
      #         s2
      #        _____
      #       /     \
      #   s1 /       \ s3
      #     /         \
      #
      # For highly-reflective interior finishes (think of Bruce Lee in Enter
      # the Dragon), the difference here in reported RSi could reach 0.1 m2.K/W
      # or R0.6. That's a 1% to 3% difference for a well-insulated construction.
      # This may seem significant, but the impact on energy simulation results
      # should be barely noticeable. However, these discrepancies could become
      # an irritant when processing an OpenStudio model for code compliance
      # purposes. For clear-field (Uo) calculations, a simple solution is ensure
      # that the (common) layered construction meets minimal code requirements
      # for the surface with the lowest film resistance, here s2. Thus surfaces
      # s1 & s3 will slightly overshoot the Uo target.
      #
      # For Ut calculations (which factor-in major thermal bridging), this is
      # not as straightforward as adjusting the construction layers by hand. Yet
      # conceptually, the approach here remains similar: for a selected
      # construction shared by more than one surface, the considered film
      # resistance will be that of the worst case encountered. The resulting Uo
      # for that uprated construction might be slightly lower (i.e., better
      # performing) than expected in some circumstances.
      f = s.filmResistance

      case type
      when "wall"
        walls[:c][id] = {a: a, lc: lc}
        walls[:c][id][:f] = f unless walls[:c][id].key?(:f)
        walls[:c][id][:f] = f if f < walls[:c][id][:f]
      when "roofceiling"
        roofs[:c][id] = {a: a, lc: lc}
        roofs[:c][id][:f] = f unless roofs[:c][id].key?(:f)
        roofs[:c][id][:f] = f if f < roofs[:c][id][:f]
      else
        flors[:c][id] = {a: a, lc: lc}
        flors[:c][id][:f] = f unless flors[:c][id].key?(:f)
        flors[:c][id][:f] = f if f < flors[:c][id][:f]
      end
    end

    walls[:c] = walls[:c].sort_by{ |k,v| v[:a] }.reverse!.to_h
    walls[:c][walls[:dft]][:a] = 0
    walls[:c].keys.each { |id| walls[:chx] << id }

    roofs[:c] = roofs[:c].sort_by{ |k,v| v[:a] }.reverse!.to_h
    roofs[:c][roofs[:dft]][:a] = 0
    roofs[:c].keys.each { |id| roofs[:chx] << id }

    flors[:c] = flors[:c].sort_by{ |k,v| v[:a] }.reverse!.to_h
    flors[:c][flors[:dft]][:a] = 0
    flors[:c].keys.each { |id| flors[:chx] << id }

    expect(roofs[:c].size).to eq(3)
    rf1 = "Typical Insulated Metal Building Roof R-10.31 1"
    rf2 = "Typical Insulated Metal Building Roof R-18.18"
    expect(roofs[:c].keys[0]).to eq("ALL roof constructions")
    expect(roofs[:c]["ALL roof constructions"][:a]).to be_within(TOL).of(0)
    roof1 = roofs[:c].values[1]
    roof2 = roofs[:c].values[2]
    expect(roof1[:a] > roof2[:a]).to be(true)
    expect(roof1[:f]).to be_within(TOL).of(roof2[:f])
    expect(roof1[:f]).to be_within(TOL).of(0.1360)
    expect(1/TBD.rsi(roof1[:lc], roof1[:f])).to be_within(TOL).of(0.5512) # R10
    expect(1/TBD.rsi(roof2[:lc], roof2[:f])).to be_within(TOL).of(0.3124) # R18

    # Deeper dive into rf1 (more prevalent).
    targeted = os_model.getConstructionByName(rf1)
    expect(targeted.empty?).to be(false)
    targeted = targeted.get
    expect(targeted.to_LayeredConstruction.empty?).to be(false)
    targeted = targeted.to_LayeredConstruction.get
    expect(targeted.is_a?(OpenStudio::Model::LayeredConstruction)).to be(true)
    expect(targeted.layers.size).to eq(2)

    targeted.layers.each do |layer|
      next unless layer.nameString == "Typical Insulation R-9.53 1"
      expect(layer.to_MasslessOpaqueMaterial.empty?).to be(false)
      layer = layer.to_MasslessOpaqueMaterial.get
      expect(layer.thermalResistance).to be_within(TOL).of(1.68) # m2.K/W (R9.5)
    end

    # argh[:roof_option ] = "Typical Insulated Metal Building Roof R-10.31 1"
    argh[:roof_option ] = "ALL roof constructions"
    argh[:option      ] = "poor (BETBG)"
    argh[:uprate_roofs] = true
    argh[:roof_ut     ] = 0.138                     # NECB 2017 (RSi 7.25 / R41)

    json = TBD.process(os_model, argh)
    expect(json.is_a?(Hash)).to be(true)
    expect(json.key?(:io)).to be(true)
    expect(json.key?(:surfaces)).to be(true)
    io       = json[:io]
    surfaces = json[:surfaces]
    puts TBD.logs
    expect(TBD.status).to eq(0)
    expect(TBD.logs.empty?).to be(true)
    expect(io.nil?).to be(false)
    expect(io.is_a?(Hash)).to be(true)
    expect(io.empty?).to be(false)
    expect(surfaces.nil?).to be(false)
    expect(surfaces.is_a?(Hash)).to be(true)
    expect(surfaces.size).to eq(23)
    expect(io.key?(:edges))
    expect(io[:edges].size).to eq(300)

    bulk = "Bulk Storage Roof"
    fine = "Fine Storage Roof"

    # OpenStudio objects.
    bulk_roof = os_model.getSurfaceByName(bulk)
    fine_roof = os_model.getSurfaceByName(fine)
    expect(bulk_roof.empty?).to be(false)
    expect(fine_roof.empty?).to be(false)
    bulk_roof = bulk_roof.get
    fine_roof = fine_roof.get
    bulk_construction = bulk_roof.construction
    fine_construction = fine_roof.construction
    expect(bulk_construction.empty?).to be(false)
    expect(fine_construction.empty?).to be(false)
    bulk_construction = bulk_construction.get.to_LayeredConstruction
    fine_construction = fine_construction.get.to_LayeredConstruction
    expect(bulk_construction.empty?).to be(false)
    expect(fine_construction.empty?).to be(false)
    bulk_construction = bulk_construction.get
    fine_construction = fine_construction.get
    expect(bulk_construction.nameString).to eq("Bulk Storage Roof c tbd")
    expect(fine_construction.nameString).to eq("Fine Storage Roof c tbd")
    expect(bulk_construction.layers.size).to eq(2)
    expect(fine_construction.layers.size).to eq(2)
    bulk_insulation = bulk_construction.layers.at(1).to_MasslessOpaqueMaterial
    fine_insulation = fine_construction.layers.at(1).to_MasslessOpaqueMaterial
    expect(bulk_insulation.empty?).to be(false)
    expect(fine_insulation.empty?).to be(false)
    bulk_insulation = bulk_insulation.get
    fine_insulation = fine_insulation.get
    bulk_insulation_r = bulk_insulation.thermalResistance
    fine_insulation_r = fine_insulation.thermalResistance
    expect(bulk_insulation_r).to be_within(TOL).of(7.307)         # once derated
    expect(fine_insulation_r).to be_within(TOL).of(6.695)         # once derated

    # TBD objects.
    expect(surfaces.key?(bulk)).to be(true)
    expect(surfaces.key?(fine)).to be(true)
    expect(surfaces[bulk].key?(:heatloss)).to be(true)
    expect(surfaces[bulk].key?(:heatloss)).to be(true)
    expect(surfaces[bulk].key?(:net)).to be(true)
    expect(surfaces[fine].key?(:net)).to be(true)
    expect(surfaces[bulk][:heatloss]).to be_within(TOL).of(161.02)
    expect(surfaces[fine][:heatloss]).to be_within(TOL).of(87.16)
    expect(surfaces[bulk][:net]).to be_within(TOL).of(3157.28)
    expect(surfaces[fine][:net]).to be_within(TOL).of(1372.60)
    heatloss = surfaces[bulk][:heatloss] + surfaces[fine][:heatloss]
    area = surfaces[bulk][:net] + surfaces[fine][:net]
    expect(heatloss).to be_within(TOL).of(248.19)
    expect(area).to be_within(TOL).of(4529.88)

    expect(surfaces[bulk].key?(:construction)).to be(true)     # not yet derated
    expect(surfaces[fine].key?(:construction)).to be(true)
    expect(surfaces[bulk][:construction].nameString).to eq(rf1)
    expect(surfaces[fine][:construction].nameString).to eq(rf1)  # no longer rf2

    uprated = os_model.getConstructionByName(rf1)              # not yet derated
    expect(uprated.empty?).to be(false)
    uprated = uprated.get
    expect(uprated.to_LayeredConstruction.empty?).to be(false)
    uprated = uprated.to_LayeredConstruction.get
    expect(uprated.is_a?(OpenStudio::Model::LayeredConstruction)).to be(true)
    expect(uprated.layers.size).to eq(2)
    uprated_layer_r = 0

    uprated.layers.each do |layer|
      next unless layer.nameString.include?(" uprated")
      expect(layer.to_MasslessOpaqueMaterial.empty?).to be(false)
      layer = layer.to_MasslessOpaqueMaterial.get
      uprated_layer_r = layer.thermalResistance
      expect(layer.thermalResistance).to be_within(TOL).of(11.65) # m2.K/W (R66)
    end

    rt = TBD.rsi(uprated, roof1[:f])
    expect(1/rt).to be_within(TOL).of(0.0849)         # R67 (with surface films)

    # Bulk storage roof demonstration.
    u = surfaces[bulk][:heatloss] / surfaces[bulk][:net]
    expect(u).to be_within(TOL).of(0.051)                               # W/m2.K
    de_u = 1 / uprated_layer_r + u
    de_r = 1 / de_u
    bulk_r = de_r + roof1[:f]
    bulk_u = 1 / bulk_r
    expect(de_u).to be_within(TOL).of(0.137)    # bit below required Ut of 0.138
    expect(de_r).to be_within(TOL).of(bulk_insulation_r)      # 7.307, not 11.65
    ratio  = -(uprated_layer_r - de_r) * 100 / (uprated_layer_r + roof1[:f])
    expect(ratio).to be_within(TOL).of(-36.84)
    expect(surfaces[bulk].key?(:ratio)).to be(true)
    expect(surfaces[bulk][:ratio]).to be_within(TOL).of(ratio)

    # Fine storage roof demonstration.
    u = surfaces[fine][:heatloss] / surfaces[fine][:net]
    expect(u).to be_within(TOL).of(0.063)                               # W/m2.K
    de_u = 1 / uprated_layer_r + u
    de_r = 1 / de_u
    fine_r = de_r + roof1[:f]
    fine_u = 1 / fine_r
    expect(de_u).to be_within(TOL).of(0.149)        # above required Ut of 0.138
    expect(de_r).to be_within(TOL).of(fine_insulation_r)      # 6.695, not 11.65
    ratio  = -(uprated_layer_r - de_r) * 100 / (uprated_layer_r + roof1[:f])
    expect(ratio).to be_within(TOL).of(-42.03)
    expect(surfaces[fine].key?(:ratio)).to be(true)
    expect(surfaces[fine][:ratio]).to be_within(TOL).of(ratio)

    ua = bulk_u * surfaces[bulk][:net] + fine_u * surfaces[fine][:net]
    ave_u = ua / area
    expect(ave_u).to be_within(TOL).of(argh[:roof_ut])   # area-weighted average

    file = File.join(__dir__, "files/osms/out/up_warehouse.osm")
    os_model.save(file, true)
  end

  it "can uprate (ALL wall) constructions - poor (BETBG)" do
    TBD.clean!
    argh = {}

    translator = OpenStudio::OSVersion::VersionTranslator.new
    file = File.join(__dir__, "files/osms/in/warehouse.osm")
    path = OpenStudio::Path.new(file)
    os_model = translator.loadModel(path)
    expect(os_model.empty?).to be(false)
    os_model = os_model.get

    # Mimics measure.
    walls = {c: {}, dft: "ALL wall constructions"}
    roofs = {c: {}, dft: "ALL roof constructions"}
    flors = {c: {}, dft: "ALL floor constructions"}
    walls[:c][walls[:dft]] = {a: 100000000000000}
    roofs[:c][roofs[:dft]] = {a: 100000000000000}
    flors[:c][flors[:dft]] = {a: 100000000000000}
    walls[:chx] = OpenStudio::StringVector.new
    roofs[:chx] = OpenStudio::StringVector.new
    flors[:chx] = OpenStudio::StringVector.new

    os_model.getSurfaces.each do |s|
      type = s.surfaceType.downcase
      next unless type == "wall" || type == "roofceiling" || type == "floor"
      next unless s.outsideBoundaryCondition.downcase == "outdoors"
      next if s.construction.empty?
      next if s.construction.get.to_LayeredConstruction.empty?
      lc = s.construction.get.to_LayeredConstruction.get
      id = lc.nameString
      next if walls[:c].key?(id)
      next if roofs[:c].key?(id)
      next if flors[:c].key?(id)
      a = lc.getNetArea
      f = s.filmResistance

      case type
      when "wall"
        walls[:c][id] = {a: a, lc: lc}
        walls[:c][id][:f] = f unless walls[:c][id].key?(:f)
        walls[:c][id][:f] = f if f < walls[:c][id][:f]
      when "roofceiling"
        roofs[:c][id] = {a: a, lc: lc}
        roofs[:c][id][:f] = f unless roofs[:c][id].key?(:f)
        roofs[:c][id][:f] = f if f < roofs[:c][id][:f]
      else
        flors[:c][id] = {a: a, lc: lc}
        flors[:c][id][:f] = f unless flors[:c][id].key?(:f)
        flors[:c][id][:f] = f if f < flors[:c][id][:f]
      end
    end

    walls[:c] = walls[:c].sort_by{ |k,v| v[:a] }.reverse!.to_h
    walls[:c][walls[:dft]][:a] = 0
    walls[:c].keys.each { |id| walls[:chx] << id }

    roofs[:c] = roofs[:c].sort_by{ |k,v| v[:a] }.reverse!.to_h
    roofs[:c][roofs[:dft]][:a] = 0
    roofs[:c].keys.each { |id| roofs[:chx] << id }

    flors[:c] = flors[:c].sort_by{ |k,v| v[:a] }.reverse!.to_h
    flors[:c][flors[:dft]][:a] = 0
    flors[:c].keys.each { |id| flors[:chx] << id }

    expect(walls[:c].size).to eq(4)
    w1 = "Typical Insulated Metal Building Wall R-8.85 1"
    w2 = "Typical Insulated Metal Building Wall R-11.9"
    w3 = "Typical Insulated Metal Building Wall R-11.9 1"
    expect(walls[:c].key?(w1)).to be(true)
    expect(walls[:c].key?(w2)).to be(true)
    expect(walls[:c].key?(w3)).to be(true)
    expect(walls[:c].keys[0]).to eq("ALL wall constructions")
    expect(walls[:c]["ALL wall constructions"][:a]).to be_within(TOL).of(0)

    wall1 = walls[:c][w1]
    wall2 = walls[:c][w2]
    wall3 = walls[:c][w3]
    expect(wall1[:a] > wall2[:a]).to be(true)
    expect(wall2[:a] > wall3[:a]).to be(true)
    expect(wall1[:f]).to be_within(TOL).of(wall2[:f])
    expect(wall3[:f]).to be_within(TOL).of(wall3[:f])
    expect(wall1[:f]).to be_within(TOL).of(0.150)
    expect(wall2[:f]).to be_within(TOL).of(0.150)
    expect(wall3[:f]).to be_within(TOL).of(0.150)
    expect(1/TBD.rsi(wall1[:lc], wall1[:f])).to be_within(TOL).of(0.642) # R08.8
    expect(1/TBD.rsi(wall2[:lc], wall2[:f])).to be_within(TOL).of(0.477) # R11.9

    # Deeper dive into w1 (more prevalent).
    targeted = os_model.getConstructionByName(w1)
    expect(targeted.empty?).to be(false)
    targeted = targeted.get
    expect(targeted.to_LayeredConstruction.empty?).to be(false)
    targeted = targeted.to_LayeredConstruction.get
    expect(targeted.is_a?(OpenStudio::Model::LayeredConstruction)).to be(true)
    expect(targeted.layers.size).to eq(3)

    targeted.layers.each do |layer|
      next unless layer.nameString == "Typical Insulation R-7.55 1"
      expect(layer.to_MasslessOpaqueMaterial.empty?).to be(false)
      layer = layer.to_MasslessOpaqueMaterial.get
      expect(layer.thermalResistance).to be_within(TOL).of(1.33) # m2.K/W (R7.6)
    end

    # Set w1 (a wall construction) as the 'Bulk Storage Roof' construction. This
    # triggers a TBD warning when uprating: a safeguard limiting uprated
    # constructions to single surface type (e.g. can't be referenced by both
    # roof AND wall surfaces).
    bulk = "Bulk Storage Roof"
    bulk_roof = os_model.getSurfaceByName(bulk)
    expect(bulk_roof.empty?).to be(false)
    bulk_roof = bulk_roof.get
    expect(bulk_roof.isConstructionDefaulted).to be(true)

    bulk_construction = bulk_roof.construction
    expect(bulk_construction.empty?).to be(false)
    bulk_construction = bulk_construction.get.to_LayeredConstruction
    expect(bulk_construction.empty?).to be(false)
    bulk_construction = bulk_construction.get
    expect(bulk_construction.numLayers).to eq(2)
    expect(bulk_roof.setConstruction(targeted)).to be(true)
    expect(bulk_roof.isConstructionDefaulted).to be(false)

    argh[:wall_option ] = "ALL wall constructions"
    argh[:option      ] = "poor (BETBG)"
    argh[:uprate_walls] = true
    argh[:wall_ut     ] = 0.210                                          # (R27)

    json = TBD.process(os_model, argh)
    expect(json.is_a?(Hash)).to be(true)
    expect(json.key?(:io)).to be(true)
    expect(json.key?(:surfaces)).to be(true)
    io       = json[:io]
    surfaces = json[:surfaces]
    expect(TBD.status).to eq(WRN)
    expect(TBD.logs.size).to eq(1)
    msg = "Cloning '#{bulk}' construction - not '#{w1}' (TBD::uprate)"
    expect(TBD.logs.first[:message]).to eq(msg)
    expect(io.nil?).to be(false)
    expect(io.is_a?(Hash)).to be(true)
    expect(io.empty?).to be(false)
    expect(surfaces.nil?).to be(false)
    expect(surfaces.is_a?(Hash)).to be(true)
    expect(surfaces.size).to eq(23)
    expect(io.key?(:edges))
    expect(io[:edges].size).to eq(300)

    bulk_roof = os_model.getSurfaceByName(bulk)
    expect(bulk_roof.empty?).to be(false)
    bulk_roof = bulk_roof.get
    bulk_construction = bulk_roof.construction
    expect(bulk_construction.empty?).to be(false)
    bulk_construction = bulk_construction.get.to_LayeredConstruction
    expect(bulk_construction.empty?).to be(false)
    bulk_construction = bulk_construction.get
    expect(bulk_construction.nameString).to eq("#{bulk} c tbd")
    expect(bulk_construction.numLayers).to eq(3)                         # not 2
    layer0 = bulk_construction.layers[0]
    layer1 = bulk_construction.layers[1]
    layer2 = bulk_construction.layers[2]
    expect(layer1.nameString).to eq("#{bulk} m tbd")             # not uprated

    layer = layer0.to_StandardOpaqueMaterial
    expect(layer.empty?).to be(false)
    siding = layer.get.thickness / layer.get.thermalConductivity
    layer = layer2.to_StandardOpaqueMaterial
    expect(layer.empty?).to be(false)
    gypsum = layer.get.thickness / layer.get.thermalConductivity
    extra = siding + gypsum + wall1[:f]
    wall_surfaces = []

    os_model.getSurfaces.each do |s|
      next unless s.surfaceType.downcase == "wall"
      next unless s.outsideBoundaryCondition.downcase == "outdoors"
      next if s.construction.empty?
      next if s.construction.get.to_LayeredConstruction.empty?
      c = s.construction.get.to_LayeredConstruction.get
      expect(c.numLayers).to eq(3)
      expect(c.layers[0]).to eq(layer0)              # same as Bulk Storage Roof
      expect(c.layers[1].nameString.include?(" uprated ")).to be(true)
      expect(c.layers[1].nameString.include?(" m tbd")).to be(true)
      expect(c.layers[2]).to eq(layer2)             # same as Bul;k Storage Roof
      wall_surfaces << s
    end

    expect(wall_surfaces.size).to eq(10)

    # TBD objects.
    expect(surfaces.key?(bulk)).to be(true)
    expect(surfaces[bulk].key?(:heatloss)).to be(true)
    expect(surfaces[bulk].key?(:net)).to be(true)

    # By initially inheriting the wall construction, the bulk roof surface is
    # slightly less derated (152.40 W/K instead of 161.02 W/K), due to TBD's
    # proportionate psi distribution between surface edges.
    expect(surfaces[bulk][:heatloss]).to be_within(TOL).of(152.40)
    expect(surfaces[bulk][:net]).to be_within(TOL).of(3157.28)
    expect(surfaces[bulk].key?(:construction)).to be(true)     # not yet derated
    nom = surfaces[bulk][:construction].nameString
    expect(nom.include?("cloned")).to be(true)

    uprated = os_model.getConstructionByName(w1)      # uprated, not yet derated
    expect(uprated.empty?).to be(false)
    uprated = uprated.get
    expect(uprated.to_LayeredConstruction.empty?).to be(false)
    uprated = uprated.to_LayeredConstruction.get
    expect(uprated.layers.size).to eq(3)
    uprated_layer_r = 0

    uprated.layers.each do |layer|
      next unless layer.nameString.include?("uprated")
      expect(layer.to_MasslessOpaqueMaterial.empty?).to be(false)
      layer = layer.to_MasslessOpaqueMaterial.get
      uprated_layer_r = layer.thermalResistance
      expect(uprated_layer_r).to be_within(TOL).of(51.92)               # m2.K/W
    end

    rt = TBD.rsi(uprated, wall1[:f])
    expect(1/rt).to be_within(TOL).of(0.019)        # 52.63 (with surface films)

    # Loop through all walls, fetch nets areas & heatlosses from psi's.
    net   = 0
    hloss = 0

    surfaces.each do |id, surface|
      next unless surface.key?(:boundary)
      next unless surface[:boundary] == "Outdoors"
      next unless surface.key?(:type)
      next unless surface[:type] == :wall
      next unless surface.key?(:construction)
      next unless surface.key?(:heatloss)
      next unless surface.key?(:net)
      hloss += surface[:heatloss]
      net += surface[:net]
    end

    expect(hloss).to be_within(TOL).of(485.59)
    expect(net).to be_within(TOL).of(2411.7)
    u     = hloss / net
    de_u  = 1 / uprated_layer_r + u
    de_r  = 1 / de_u
    new_r = de_r + extra
    new_u = 1 / new_r
    expect(new_r).to be_within(TOL).of(4.76)                    # R27 (NECB2017)
    expect(new_u).to be_within(TOL).of(argh[:wall_ut])            # 0.210 W/m2.K

    # Bulk storage wall demonstration.
    wll1 = "Bulk Storage Left Wall"
    wll2 = "Bulk Storage Rear Wall"
    wll3 = "Bulk Storage Right Wall"
    rs   = {}

    [wll1, wll2, wll3].each do |i|
      sface = os_model.getSurfaceByName(i)
      expect(sface.empty?).to be(false)
      sface = sface.get
      c = sface.construction
      expect(c.empty?).to be(false)
      c = c.get.to_LayeredConstruction
      expect(c.empty?).to be(false)
      c = c.get
      expect(c.numLayers).to eq(3)

      layer = c.layers[0].to_StandardOpaqueMaterial
      expect(layer.empty?).to be(false)
      d = layer.get.thickness
      k = layer.get.thermalConductivity
      expect(d / k).to be_within(TOL).of(siding)

      layer = c.layers[1].to_MasslessOpaqueMaterial
      expect(layer.empty?).to be(false)
      rsi = layer.get.thermalResistance
      expect(rsi).to be_within(TOL).of(4.1493) if i == wll1
      expect(rsi).to be_within(TOL).of(5.4252) if i == wll2
      expect(rsi).to be_within(TOL).of(5.3642) if i == wll3

      layer = c.layers[2].to_StandardOpaqueMaterial
      expect(layer.empty?).to be(false)
      d = layer.get.thickness
      k = layer.get.thermalConductivity
      expect(d / k).to be_within(TOL).of(gypsum)

      u = c.thermalConductance
      expect(u.empty?).to be(false)
      rs[i] = 1 / u.get
    end

    expect(rs.key?(wll1)).to be(true)
    expect(rs.key?(wll2)).to be(true)
    expect(rs.key?(wll3)).to be(true)
    expect(rs[wll1]).to be_within(TOL).of(4.2287)
    expect(rs[wll2]).to be_within(TOL).of(5.5046)
    expect(rs[wll3]).to be_within(TOL).of(5.4436)

    u     = surfaces[wll1][:heatloss] / surfaces[wll1][:net]
    expect(u).to be_within(TOL).of(0.2217)        # W/m2.K from thermal bridging
    de_u  = 1 / uprated_layer_r + u
    de_r  = 1 / de_u
    new_r = de_r + extra
    new_u = 1 / new_r
    expect(new_r).to be_within(TOL).of(4.3782)          # R24.9 ... lot of doors
    ratio = -(uprated_layer_r - de_r) * 100 / rt
    expect(ratio).to be_within(TOL).of(-91.60)
    expect(surfaces[wll1].key?(:ratio)).to be(true)
    expect(surfaces[wll1][:ratio]).to be_within(TOL).of(ratio)

    u     = surfaces[wll2][:heatloss] / surfaces[wll2][:net]
    expect(u).to be_within(TOL).of(0.1652)        # W/m2.K from thermal bridging
    de_u  = 1 / uprated_layer_r + u
    de_r  = 1 / de_u
    new_r = de_r + extra
    new_u = 1 / new_r
    expect(new_r).to be_within(TOL).of(5.6542)           # R32.1 ... no openings
    ratio = -(uprated_layer_r - de_r) * 100 / rt
    expect(ratio).to be_within(TOL).of(-89.16)
    expect(surfaces[wll2].key?(:ratio)).to be(true)
    expect(surfaces[wll2][:ratio]).to be_within(TOL).of(ratio)

    u     = surfaces[wll3][:heatloss] / surfaces[wll3][:net]
    expect(u).to be_within(TOL).of(0.1671)        # W/m2.K from thermal bridging
    de_u  = 1 / uprated_layer_r + u
    de_r  = 1 / de_u
    new_r = de_r + extra
    new_u = 1 / new_r
    expect(new_r).to be_within(TOL).of(5.5931)           # R31.8 ... a few doors
    ratio = -(uprated_layer_r - de_r) * 100 / rt
    expect(ratio).to be_within(TOL).of(-89.27)
    expect(surfaces[wll3].key?(:ratio)).to be(true)
    expect(surfaces[wll3][:ratio]).to be_within(TOL).of(ratio)

    file = File.join(__dir__, "files/osms/out/up2_warehouse.osm")
    os_model.save(file, true)
  end

  it "can uprate (ALL wall) constructions - efficient (BETBG)" do
    TBD.clean!
    argh = {}

    translator = OpenStudio::OSVersion::VersionTranslator.new
    file = File.join(__dir__, "files/osms/in/warehouse.osm")
    path = OpenStudio::Path.new(file)
    os_model = translator.loadModel(path)
    expect(os_model.empty?).to be(false)
    os_model = os_model.get

    # Mimics measure.
    walls = {c: {}, dft: "ALL wall constructions"}
    roofs = {c: {}, dft: "ALL roof constructions"}
    flors = {c: {}, dft: "ALL floor constructions"}
    walls[:c][walls[:dft]] = {a: 100000000000000}
    roofs[:c][roofs[:dft]] = {a: 100000000000000}
    flors[:c][flors[:dft]] = {a: 100000000000000}
    walls[:chx] = OpenStudio::StringVector.new
    roofs[:chx] = OpenStudio::StringVector.new
    flors[:chx] = OpenStudio::StringVector.new

    os_model.getSurfaces.each do |s|
      type = s.surfaceType.downcase
      next unless type == "wall" || type == "roofceiling" || type == "floor"
      next unless s.outsideBoundaryCondition.downcase == "outdoors"
      next if s.construction.empty?
      next if s.construction.get.to_LayeredConstruction.empty?
      lc = s.construction.get.to_LayeredConstruction.get
      id = lc.nameString
      next if walls[:c].key?(id)
      next if roofs[:c].key?(id)
      next if flors[:c].key?(id)
      a = lc.getNetArea
      f = s.filmResistance

      case type
      when "wall"
        walls[:c][id] = {a: a, lc: lc}
        walls[:c][id][:f] = f unless walls[:c][id].key?(:f)
        walls[:c][id][:f] = f if f < walls[:c][id][:f]
      when "roofceiling"
        roofs[:c][id] = {a: a, lc: lc}
        roofs[:c][id][:f] = f unless roofs[:c][id].key?(:f)
        roofs[:c][id][:f] = f if f < roofs[:c][id][:f]
      else
        flors[:c][id] = {a: a, lc: lc}
        flors[:c][id][:f] = f unless flors[:c][id].key?(:f)
        flors[:c][id][:f] = f if f < flors[:c][id][:f]
      end
    end

    walls[:c] = walls[:c].sort_by{ |k,v| v[:a] }.reverse!.to_h
    walls[:c][walls[:dft]][:a] = 0
    walls[:c].keys.each { |id| walls[:chx] << id }

    roofs[:c] = roofs[:c].sort_by{ |k,v| v[:a] }.reverse!.to_h
    roofs[:c][roofs[:dft]][:a] = 0
    roofs[:c].keys.each { |id| roofs[:chx] << id }

    flors[:c] = flors[:c].sort_by{ |k,v| v[:a] }.reverse!.to_h
    flors[:c][flors[:dft]][:a] = 0
    flors[:c].keys.each { |id| flors[:chx] << id }

    expect(walls[:c].size).to eq(4)
    w1 = "Typical Insulated Metal Building Wall R-8.85 1"
    w2 = "Typical Insulated Metal Building Wall R-11.9"
    w3 = "Typical Insulated Metal Building Wall R-11.9 1"
    expect(walls[:c].key?(w1)).to be(true)
    expect(walls[:c].key?(w2)).to be(true)
    expect(walls[:c].key?(w3)).to be(true)
    expect(walls[:c].keys[0]).to eq("ALL wall constructions")
    expect(walls[:c]["ALL wall constructions"][:a]).to be_within(TOL).of(0)

    wall1 = walls[:c][w1]
    wall2 = walls[:c][w2]
    wall3 = walls[:c][w3]
    expect(wall1[:a] > wall2[:a]).to be(true)
    expect(wall2[:a] > wall3[:a]).to be(true)
    expect(wall1[:f]).to be_within(TOL).of(wall2[:f])
    expect(wall3[:f]).to be_within(TOL).of(wall3[:f])
    expect(wall1[:f]).to be_within(TOL).of(0.150)
    expect(wall2[:f]).to be_within(TOL).of(0.150)
    expect(wall3[:f]).to be_within(TOL).of(0.150)
    expect(1/TBD.rsi(wall1[:lc], wall1[:f])).to be_within(TOL).of(0.642) # R08.8
    expect(1/TBD.rsi(wall2[:lc], wall2[:f])).to be_within(TOL).of(0.477) # R11.9

    # Deeper dive into w1 (more prevalent).
    targeted = os_model.getConstructionByName(w1)
    expect(targeted.empty?).to be(false)
    targeted = targeted.get
    expect(targeted.to_LayeredConstruction.empty?).to be(false)
    targeted = targeted.to_LayeredConstruction.get
    expect(targeted.is_a?(OpenStudio::Model::LayeredConstruction)).to be(true)
    expect(targeted.layers.size).to eq(3)
    targeted.layers.each do |layer|
      next unless layer.nameString == "Typical Insulation R-7.55 1"
      expect(layer.to_MasslessOpaqueMaterial.empty?).to be(false)
      layer = layer.to_MasslessOpaqueMaterial.get
      expect(layer.thermalResistance).to be_within(TOL).of(1.33) # m2.K/W (R7.6)
    end

    # Set w1 (a wall construction) as the 'Bulk Storage Roof' construction. This
    # triggers a TBD warning when uprating: a safeguard limiting uprated
    # constructions to single surface type (e.g. can't be referenced by both
    # roof AND wall surfaces).
    bulk = "Bulk Storage Roof"
    bulk_roof = os_model.getSurfaceByName(bulk)
    expect(bulk_roof.empty?).to be(false)
    bulk_roof = bulk_roof.get
    expect(bulk_roof.isConstructionDefaulted).to be(true)

    bulk_construction = bulk_roof.construction
    expect(bulk_construction.empty?).to be(false)
    bulk_construction = bulk_construction.get.to_LayeredConstruction
    expect(bulk_construction.empty?).to be(false)
    bulk_construction = bulk_construction.get
    expect(bulk_construction.numLayers).to eq(2)
    expect(bulk_roof.setConstruction(targeted)).to be(true)
    expect(bulk_roof.isConstructionDefaulted).to be(false)

    argh[:wall_option ] = "ALL wall constructions"
    argh[:option      ] = "efficient (BETBG)"                # vs preceding test
    argh[:uprate_walls] = true
    argh[:wall_ut     ] = 0.210                                          # (R27)

    json = TBD.process(os_model, argh)
    expect(json.is_a?(Hash)).to be(true)
    expect(json.key?(:io)).to be(true)
    expect(json.key?(:surfaces)).to be(true)
    io       = json[:io]
    surfaces = json[:surfaces]
    expect(TBD.status).to eq(WRN)
    expect(TBD.logs.size).to eq(1)
    msg = "Cloning '#{bulk}' construction - not '#{w1}' (TBD::uprate)"
    expect(TBD.logs.first[:message]).to eq(msg)
    expect(io.nil?).to be(false)
    expect(io.is_a?(Hash)).to be(true)
    expect(io.empty?).to be(false)
    expect(surfaces.nil?).to be(false)
    expect(surfaces.is_a?(Hash)).to be(true)
    expect(surfaces.size).to eq(23)
    expect(io.key?(:edges))
    expect(io[:edges].size).to eq(300)

    bulk_roof = os_model.getSurfaceByName(bulk)
    expect(bulk_roof.empty?).to be(false)
    bulk_roof = bulk_roof.get
    bulk_construction = bulk_roof.construction
    expect(bulk_construction.empty?).to be(false)
    bulk_construction = bulk_construction.get.to_LayeredConstruction
    expect(bulk_construction.empty?).to be(false)
    bulk_construction = bulk_construction.get
    expect(bulk_construction.nameString).to eq("#{bulk} c tbd")
    expect(bulk_construction.numLayers).to eq(3)                         # not 2
    layer0 = bulk_construction.layers[0]
    layer1 = bulk_construction.layers[1]
    layer2 = bulk_construction.layers[2]
    expect(layer1.nameString).to eq("#{bulk} m tbd")             # not uprated

    layer = layer0.to_StandardOpaqueMaterial
    expect(layer.empty?).to be(false)
    siding = layer.get.thickness / layer.get.thermalConductivity
    layer = layer2.to_StandardOpaqueMaterial
    expect(layer.empty?).to be(false)
    gypsum = layer.get.thickness / layer.get.thermalConductivity
    extra = siding + gypsum + wall1[:f]
    wall_surfaces = []

    os_model.getSurfaces.each do |s|
      next unless s.surfaceType.downcase == "wall"
      next unless s.outsideBoundaryCondition.downcase == "outdoors"
      next if s.construction.empty?
      next if s.construction.get.to_LayeredConstruction.empty?
      c = s.construction.get.to_LayeredConstruction.get
      expect(c.numLayers).to eq(3)
      expect(c.layers[0]).to eq(layer0)              # same as Bulk Storage Roof
      expect(c.layers[1].nameString.include?(" uprated ")).to be(true)
      expect(c.layers[1].nameString.include?(" m tbd")).to be(true)
      expect(c.layers[2]).to eq(layer2)             # same as Bul;k Storage Roof
      wall_surfaces << s
    end

    expect(wall_surfaces.size).to eq(10)

    # TBD objects.
    expect(surfaces.key?(bulk)).to be(true)
    expect(surfaces[bulk].key?(:heatloss)).to be(true)
    expect(surfaces[bulk].key?(:net)).to be(true)
    expect(surfaces[bulk][:heatloss]).to be_within(TOL).of(49.80)
    expect(surfaces[bulk][:net]).to be_within(TOL).of(3157.28)
    expect(surfaces[bulk].key?(:construction)).to be(true)     # not yet derated
    nom = surfaces[bulk][:construction].nameString
    expect(nom.include?("cloned")).to be(true)

    uprated = os_model.getConstructionByName(w1)      # uprated, not yet derated
    expect(uprated.empty?).to be(false)
    uprated = uprated.get
    expect(uprated.to_LayeredConstruction.empty?).to be(false)
    uprated = uprated.to_LayeredConstruction.get
    expect(uprated.layers.size).to eq(3)
    uprated_layer_r = 0

    uprated.layers.each do |layer|
      next unless layer.nameString.include?("uprated")
      expect(layer.to_MasslessOpaqueMaterial.empty?).to be(false)
      layer = layer.to_MasslessOpaqueMaterial.get
      uprated_layer_r = layer.thermalResistance

      # The switch from "poor" to "efficient" thermal bridging details is key.
      expect(uprated_layer_r).to be_within(TOL).of(5.932)   # vs 51.92 m2.K/W !!
    end

    rt = TBD.rsi(uprated, wall1[:f])
    expect(1/rt).to be_within(TOL).of(0.162) # 6.16 (with surface films), or R35
    # Still, that R35 factors-in "minor" or "clear-field" thermal bridging
    # from studs, Z-bars and/or fasteners. The final, nominal insulation layer
    # may need to be ~R40. That's 8" of XPS in a wall.

    # Loop through all walls, fetch nets areas & heatlosses from psi's.
    net   = 0
    hloss = 0

    surfaces.each do |id, surface|
      next unless surface.key?(:boundary)
      next unless surface[:boundary] == "Outdoors"
      next unless surface.key?(:type)
      next unless surface[:type] == :wall
      next unless surface.key?(:construction)
      next unless surface.key?(:heatloss)
      next unless surface.key?(:net)
      hloss += surface[:heatloss]
      net += surface[:net]
    end

    expect(hloss).to be_within(TOL).of(125.48) # vs 485.59 W/K
    expect(net).to be_within(TOL).of(2411.7)
    u = hloss / net
    de_u = 1 / uprated_layer_r + u
    de_r = 1 / de_u
    new_r = de_r + extra
    new_u = 1 / new_r
    expect(new_r).to be_within(TOL).of(4.76)                    # R27 (NECB2017)
    expect(new_u).to be_within(TOL).of(argh[:wall_ut])            # 0.210 W/m2.K

    # Bulk storage wall demonstration.
    wll1 = "Bulk Storage Left Wall"
    wll2 = "Bulk Storage Rear Wall"
    wll3 = "Bulk Storage Right Wall"
    rs = {}

    [wll1, wll2, wll3].each do |i|
      sface = os_model.getSurfaceByName(i)
      expect(sface.empty?).to be(false)
      sface = sface.get
      c = sface.construction
      expect(c.empty?).to be(false)
      c = c.get.to_LayeredConstruction
      expect(c.empty?).to be(false)
      c = c.get
      expect(c.numLayers).to eq(3)

      layer = c.layers[0].to_StandardOpaqueMaterial
      expect(layer.empty?).to be(false)
      d = layer.get.thickness
      k = layer.get.thermalConductivity
      expect(d / k).to be_within(TOL).of(siding)

      layer = c.layers[1].to_MasslessOpaqueMaterial
      expect(layer.empty?).to be(false)
      rsi = layer.get.thermalResistance
      expect(rsi).to be_within(TOL).of(4.3381) if i == wll1   # vs 4.1493 m2.K/W
      expect(rsi).to be_within(TOL).of(4.8052) if i == wll2   # vs 5.4252 m2.K/W
      expect(rsi).to be_within(TOL).of(4.7446) if i == wll3   # vs 5.3642 m2.K/W

      layer = c.layers[2].to_StandardOpaqueMaterial
      expect(layer.empty?).to be(false)
      d = layer.get.thickness
      k = layer.get.thermalConductivity
      expect(d / k).to be_within(TOL).of(gypsum)

      u = c.thermalConductance
      expect(u.empty?).to be(false)
      rs[i] = 1 / u.get
    end

    expect(rs.key?(wll1)).to be(true)
    expect(rs.key?(wll2)).to be(true)
    expect(rs.key?(wll3)).to be(true)
    expect(rs[wll1]).to be_within(TOL).of(4.4175)             # vs 4.2287 m2.K/W
    expect(rs[wll2]).to be_within(TOL).of(4.8847)             # vs 5.5046 m2.K/W
    expect(rs[wll3]).to be_within(TOL).of(4.8240)             # vs 5.4436 m2.K/W

    u = surfaces[wll1][:heatloss] / surfaces[wll1][:net]
    expect(u).to be_within(TOL).of(0.0619)      # vs 0.2217 W/m2.K from bridging
    de_u = 1 / uprated_layer_r + u
    de_r = 1 / de_u
    new_r = de_r + extra
    new_u = 1 / new_r
    expect(new_r).to be_within(TOL).of(4.5671)                   # R26, vs R24.9
    ratio  = -(uprated_layer_r - de_r) * 100 / rt
    expect(ratio).to be_within(TOL).of(-25.87)                     # vs -91.60 %
    expect(surfaces[wll1].key?(:ratio)).to be(true)
    expect(surfaces[wll1][:ratio]).to be_within(TOL).of(ratio)

    u = surfaces[wll2][:heatloss] / surfaces[wll2][:net]
    expect(u).to be_within(TOL).of(0.0395)      # vs 0.1652 W/m2.K from bridging
    de_u = 1 / uprated_layer_r + u
    de_r = 1 / de_u
    new_r = de_r + extra
    new_u = 1 / new_r
    expect(new_r).to be_within(TOL).of(5.0342)                 # R28.6, vs R32.1
    ratio  = -(uprated_layer_r - de_r) * 100 / rt
    expect(ratio).to be_within(TOL).of(-18.29)                      # vs -89.16%
    expect(surfaces[wll2].key?(:ratio)).to be(true)
    expect(surfaces[wll2][:ratio]).to be_within(TOL).of(ratio)

    u = surfaces[wll3][:heatloss] / surfaces[wll3][:net]
    expect(u).to be_within(TOL).of(0.0422)      # vs 0.1671 W/m2.K from bridging
    de_u = 1 / uprated_layer_r + u
    de_r = 1 / de_u
    new_r = de_r + extra
    new_u = 1 / new_r
    expect(new_r).to be_within(TOL).of(4.9735)                 # R28.2, vs R31.8
    ratio  = -(uprated_layer_r - de_r) * 100 / rt
    expect(ratio).to be_within(TOL).of(-19.27)                      # vs -89.27%
    expect(surfaces[wll3].key?(:ratio)).to be(true)
    expect(surfaces[wll3][:ratio]).to be_within(TOL).of(ratio)

    file = File.join(__dir__, "files/osms/out/up3_warehouse.osm")
    os_model.save(file, true)
  end

  it "can test (failed) uprating cases" do
    TBD.clean!
    translator = OpenStudio::OSVersion::VersionTranslator.new
    version = OpenStudio.openStudioVersion.split(".").map(&:to_i).join.to_i
    # 5ZoneNoHVAC model holds an Air Wall material (deprecated as of v3.5).
    # The 'if version < 350' control below circumvents the issue, but the entire
    # test as well! See smalloffice.osm test towards the end.

    if version < 350
      argh = {}
      walls = []
      construction = nil
      id = "ASHRAE 189.1-2009 ExtWall Mass ClimateZone 5"

      file = File.join(__dir__, "files/osms/in/5ZoneNoHVAC.osm")
      path = OpenStudio::Path.new(file)
      model = translator.loadModel(path)
      expect(model.empty?).to be(false)
      model = model.get

      # Get geometry data for testing (4x exterior walls, same construction).
      model.getSurfaces.each do |s|
        next unless s.surfaceType == "Wall"
        next unless s.outsideBoundaryCondition == "Outdoors"
        walls << s.nameString
        c = s.construction
        expect(c.empty?).to be(false)
        c = c.get.to_LayeredConstruction
        expect(c.empty?).to be(false)
        c = c.get
        construction = c if construction.nil?
        expect(c).to eq(construction)
      end

      expect(walls.size).to eq(4)
      expect(construction.nameString).to eq(id)
      expect(construction.layers.size).to eq(4)
      insulation = construction.layers[2].to_StandardOpaqueMaterial
      expect(insulation.empty?).to be(false)
      insulation = insulation.get
      expect(insulation.thickness).to be_within(0.0001).of(0.0794)
      expect(insulation.thermalConductivity).to be_within(0.0001).of(0.0432)
      original_r = insulation.thickness / insulation.thermalConductivity
      expect(original_r).to be_within(TOL).of(1.8380)

      argh[:option] = "efficient (BETBG)"
      json = TBD.process(model, argh)
      expect(json.is_a?(Hash)).to be(true)
      expect(json.key?(:io)).to be(true)
      expect(json.key?(:surfaces)).to be(true)
      io       = json[:io]
      surfaces = json[:surfaces]
      expect(TBD.status).to eq(0)
      expect(TBD.logs.empty?).to be(true)

      walls.each do |wall|
        expect(surfaces.key?(wall)).to be(true)
        expect(surfaces[wall].key?(:heatloss)).to be(true)
        long = (surfaces[wall][:heatloss] - 27.746).abs < TOL   # 40 metres wide
        short = (surfaces[wall][:heatloss] - 14.548).abs < TOL  # 20 metres wide
        valid = long || short
        expect(valid).to be(true)
      end

      # The 4-sided model has 2x "long" front/back + 2x "short" side exterior
      # walls, with a total TBD-calculated heat loss (from thermal bridging) of:
      #
      #   2x 27.746 W/K + 2x 14.548 W/K = ~84.588 W/K
      #
      # Spread over ~273.6 m2 of gross wall area, that is A LOT! Why (given the
      # "efficient" PSI values)? Each wall has a long "strip" window, almost the
      # full wall width (reaching to within a few millimetres of each corner).
      # This ~slices the host wall into 2x very narrow strips. Although the
      # thermal bridging details are considered "efficient", the total length of
      # linear thermal bridges is very high given the limited exposed (gross)
      # area. If area-weighted, derating the insulation layer of the referenced
      # wall construction above would entail factoring in this extra thermal
      # conductance of ~0.309 W/m2.K (84.6/273.6), which would reduce the
      # insulation thickness quite significantly.
      #
      #   Ut = Uo + ( ∑psi • L )/A
      #
      # Expressed otherwise:
      #
      #   Ut = Uo + 0.309
      #
      # So what initial Uo value should the construction offer (prior to
      # derating) to ensure compliance with NECB2017/2020 prescriptive
      # requirements (one of the few energy codes with prescriptive Ut
      # requirements)? For climate zone 7, the target wall Ut is 0.210 W/m2.K
      # (Rsi 4.76 m2.K/W or R27). Taking into account air film resistances and
      # non-insulating layer resistances (e.g. ~Rsi 1 m2.K/W), the (max)
      # insulating layer U (target) becomes ~0.277 (Rsi 3.6 or R20.5).
      #
      #   0.277 = layer U + 0.309
      #
      # Duh-oh! Even with an infinitely thick insulation layer (U ~= 0), it
      # would be impossible to reach NECB2017/2020 prescritive requirements with
      # "efficient" thermal breaks. Solutions? Eliminate windows :\ Otherwise,
      # further improve detailing as to achieve ~0.1 W/K per linear metre
      # (easier said than done). Here, an average PSI value of 0.150 W/K per
      # linear metre (i.e. ~76.1 W/K instead of ~84.6 W/K) still won't cut it
      # for a U of 0.01 W/m2.K (Rsi 100 or R568). Instead, an average PSI
      # value of 0.090 (~45.6 W/K, very high performance) would allow compliance
      # for a U of 0.1 W/m2.K (Rsi 10 or R57, ... $$$).
      #
      # Long story short: there will inevitably be cases where TBD is unable to
      # "uprate" a construction prior to "derating". This is neither a TBD bug
      # nor an RP-1365/ISO model limitation. It is simply "bad" design, albeit
      # unintentional. Nevertheless, TBD should exit in such cases with an
      # ERROR message.
      #
      # And if one were to instead model each of the OpenStudio walls described
      # above as 2x distinct OpenStudio surfaces? e.g.:
      #   - 95% of exposed wall area Uo 0.01 W/m2.K
      #   - 5% of exposed wall area as a "thermal bridge" strip (~5.6 W/m2.K *)
      #
      #     * (76.1 W/K over 5% of 273.6 m2)
      #
      # One would still consistently arrive at the same area-weighted average
      # Ut, in this case 0.288 (> 0.277). No free lunches.
      #
      # ---
      #
      # TBD's "uprating" method reorders the equation & attempts the following:
      #
      #   Uo = 0.277 - ( ∑psi • L )/A
      #
      # The method exits with an ERROR in 2x cases:
      #   - calculated Uo is negative, i.e. ( ∑psi • L )/A > 0.277
      #   - calculated layer r violates E+ material constraints (e.g. too thin)
      #
      # Retrying the previous example, yet requesting uprating calculations:
      TBD.clean!
      argh  = {}
      model = translator.loadModel(path)
      expect(model.empty?).to be(false)
      model = model.get

      argh[:option      ] = "efficient (BETBG)"
      argh[:uprate_walls] = true
      argh[:uprate_roofs] = true
      argh[:wall_option ] = "ALL wall constructions"
      argh[:roof_option ] = "ALL roof constructions"
      argh[:wall_ut     ] = 0.210               # NECB CZ7 2017 (RSi 4.76 / R27)
      argh[:roof_ut     ] = 0.138               # NECB CZ7 2017 (RSi 7.25 / R41)
      json = TBD.process(model, argh)
      expect(json.is_a?(Hash)).to be(true)
      expect(json.key?(:io)).to be(true)
      expect(json.key?(:surfaces)).to be(true)
      io       = json[:io]
      surfaces = json[:surfaces]
      expect(TBD.error?).to be(true)
      expect(TBD.logs.empty?).to be(false)
      expect(TBD.logs.size).to eq(2)
      expect(TBD.logs.first[:message].include?("Zero")).to be(true)
      expect(TBD.logs.first[:message].include?(": new Rsi")).to be(true)  # ~< 0
      expect(TBD.logs.last[:message].include?("Unable to uprate")).to be(true)
      expect(argh.key?(:wall_uo)).to be(false)
      expect(argh.key?(:roof_uo)).to be(true)
      expect(argh[:roof_uo].nil?).to be(false)
      expect(argh[:roof_uo]).to be_within(TOL).of(0.118)        # RSi 8.47 (R48)

      # ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- #
      TBD.clean!
      argh  = {}
      walls = []
      model = translator.loadModel(path)
      expect(model.empty?).to be(false)
      model = model.get

      argh[:io_path     ] = File.join(__dir__, "../json/tbd_5ZoneNoHVAC.json")
      argh[:schema_path ] = File.join(__dir__, "../tbd.schema.json")
      argh[:uprate_walls] = true
      argh[:uprate_roofs] = true
      argh[:wall_option ] = "ALL wall constructions"
      argh[:roof_option ] = "ALL roof constructions"
      argh[:wall_ut     ] = 0.210               # NECB CZ7 2017 (RSi 4.76 / R27)
      argh[:roof_ut     ] = 0.138               # NECB CZ7 2017 (RSi 7.25 / R41)
      json = TBD.process(model, argh)
      expect(json.is_a?(Hash)).to be(true)
      expect(json.key?(:io)).to be(true)
      expect(json.key?(:surfaces)).to be(true)
      io       = json[:io]
      surfaces = json[:surfaces]
      expect(TBD.status).to eq(0)
      expect(argh.key?(:wall_uo)).to be(true)
      expect(argh.key?(:roof_uo)).to be(true)
      expect(argh[:wall_uo].nil?).to be(false)
      expect(argh[:roof_uo].nil?).to be(false)
      expect(argh[:wall_uo]).to be_within(TOL).of(0.086)       # RSi 11.63 (R66)
      expect(argh[:roof_uo]).to be_within(TOL).of(0.129)       # RSi  7.75 (R44)

      model.getSurfaces.each do |s|
        next unless s.surfaceType == "Wall"
        next unless s.outsideBoundaryCondition == "Outdoors"
        walls << s.nameString
        c = s.construction
        expect(c.empty?).to be(false)
        c = c.get.to_LayeredConstruction
        expect(c.empty?).to be(false)
        c = c.get
        expect(c.nameString.include?(" c tbd")).to be(true)
        expect(c.layers.size).to eq(4)
        insul = c.layers[2].to_StandardOpaqueMaterial
        expect(insul.empty?).to be(false)
        insul = insul.get
        expect(insul.nameString.include?(" uprated m tbd")).to be(true)
        expect(insul.thermalConductivity).to be_within(0.0001).of(0.0432)
        th1 = (insul.thickness - 0.191).abs < 0.001     # derated Rsi 4.42 (R26)
        th2 = (insul.thickness - 0.186).abs < 0.001     # derated Rsi 4.31 (R25)
        th = th1 || th2                   # depending if 'short' or 'long' walls
        expect(th).to be(true)
      end

      walls.each do |wall|
        expect(surfaces.key?(wall)).to be(true)
        expect(surfaces[wall].key?(:r)).to be(true) # uprated/underated RSi
        expect(surfaces[wall].key?(:u)).to be(true) # uprated/underated assembly
        expect(surfaces[wall][:r]).to be_within(0.001).of(11.205)          # R64
        expect(surfaces[wall][:u]).to be_within(0.001).of(0.086)           # R66
      end

      # ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- #
      # Final attempt, with PSI values of 0.09 W/K per linear metre (JSON file).
      model   = OpenStudio::Model::Model.new
      version = model.getVersion.versionIdentifier.split('.').map(&:to_i)
      v = version.join.to_i

      unless v < 320
        file = File.join(__dir__, "files/osms/in/5ZoneNoHVAC_btap.osm")
        path = OpenStudio::Path.new(file)
        model = translator.loadModel(path)
        expect(model.empty?).to be(false)
        model = model.get
        TBD.clean!
        argh = {}
        argh[:io_path] = File.join(__dir__, "../json/tbd_5ZoneNoHVAC_btap.json")
        argh[:schema_path ] = File.join(__dir__, "../tbd.schema.json")
        argh[:uprate_walls] = true
        argh[:wall_option ] = "ALL wall constructions"
        argh[:wall_ut     ] = 0.210             # NECB CZ7 2017 (RSi 4.76 / R41)
        json = TBD.process(model, argh)
        expect(json.is_a?(Hash)).to be(true)
        expect(json.key?(:io)).to be(true)
        expect(json.key?(:surfaces)).to be(true)
        io       = json[:io]
        surfaces = json[:surfaces]
        expect(TBD.error?).to be(true)
        expect(TBD.logs.empty?).to be(false)
        expect(TBD.logs.size).to eq(2)
        expect(TBD.logs.first[:message].include?("Invalid")).to be(true)
        expect(TBD.logs.first[:message].include?("Can't uprate ")).to be(true)
        expect(TBD.logs.last[:message].include?("Unable to uprate")).to be(true)
        expect(argh.key?(:wall_uo)).to be(false)
        expect(argh.key?(:roof_uo)).to be(false)
      end
    end


    # --- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- --- #
    # --- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- --- #
    # Trying smalloffice.osm case.
    file  = File.join(__dir__, "files/osms/in/smalloffice.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model.empty?).to be(false)
    model = model.get

    walls = []
    north = "Perimeter_ZN_3_wall_north"
    south = "Perimeter_ZN_1_wall_south"
    west  = "Perimeter_ZN_4_wall_west"
    east  = "Perimeter_ZN_2_wall_east"

    # Get geometry data for testing (4x exterior walls, same construction).
    model.getSurfaces.each do |s|
      next unless s.surfaceType == "Wall"
      next unless s.outsideBoundaryCondition == "Outdoors"
      walls << s.nameString
      construction = s.construction
      expect(construction.empty?).to be(false)
      construction = construction.get.to_LayeredConstruction
      expect(construction.empty?).to be(false)
      construction = construction.get
      expect(construction.layers.size).to eq(4)
      insulation = construction.layers[2].to_MasslessOpaqueMaterial
      expect(insulation.empty?).to be(false)
      insulation = insulation.get

      resistance = TBD.rsi(construction, s.filmResistance)

      case s.nameString
      when north
        expect(insulation.thermalResistance).to be_within(0.01).of(0.634)
        expect(resistance).to be_within(0.01).of(1.018)
      when south
        expect(insulation.thermalResistance).to be_within(0.01).of(0.595)
        expect(resistance).to be_within(0.01).of(0.979)
      else
        expect(insulation.thermalResistance).to be_within(0.01).of(0.627)
        expect(resistance).to be_within(0.01).of(1.011)
      end
    end

    # ----- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ----- #
    # Vanilla, no uprating case.
    TBD.clean!
    argh = {}
    argh[:option] = "efficient (BETBG)"
    json = TBD.process(model, argh)
    expect(json.is_a?(Hash)).to be(true)
    expect(json.key?(:io)).to be(true)
    expect(json.key?(:surfaces)).to be(true)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.status).to eq(0)
    expect(TBD.logs.empty?).to be(true)

    w_area = 1.83 * 1.524 # window width x height
    d_area = 1.83 * 2.130 #   door width x height

    walls.each do |wall|
      expect(surfaces.key?(wall)).to be(true)
      expect(surfaces[wall].key?(:heatloss)).to be(true)
      expect(surfaces[wall].key?(:net     )).to be(true)
      expect(surfaces[wall].key?(:gross   )).to be(true)
      expect(surfaces[wall].key?(:r       )).to be(true)
      loss  = surfaces[wall][:heatloss]
      net   = surfaces[wall][:net     ]
      gross = surfaces[wall][:gross   ]
      r     = surfaces[wall][:r       ]

      case wall
      when north
        # parapet                       =   27.69m x  9.2% x 0.200 W/K.m = 0.509
        # corner                        = 2x 3.05m x 50.3% x 0.200 W/K.m = 0.614
        # grade                         =   27.69m         x 0.200 W/K.m = 5.538
        # fenestration                  =   40.25m         x 0.200 W/K.m = 8.050
        expect(loss ).to be_within(0.01).of(14.71)
        expect(gross).to be_within(0.01).of(84.45)          #     27.69W x 3.05H
        expect(net  ).to be_within(0.01).of(67.72)
        expect(net  ).to be_within(0.01).of(gross - 6 * w_area)
        expect(r    ).to be_within(0.01).of(0.634)
      when south
        # parapet                       =   27.69m x  8.7% x 0.200 W/K.m = 0.482
        # corner                        = 2x 3.05m x 48.7% x 0.200 W/K.m = 0.594
        # grade                         =   27.69m         x 0.200 W/K.m = 5.538
        # fenestration                  =   46.34m         x 0.200 W/K.m = 9.268
        expect(loss ).to be_within(0.01).of(15.88)
        expect(gross).to be_within(0.01).of(84.45)              # 27.69W x 3.05H
        expect(net  ).to be_within(0.01).of(63.82)
        expect(net  ).to be_within(0.01).of(gross - 6 * w_area - d_area)
        expect(r    ).to be_within(0.01).of(0.595)
      else
        # parapet                       =   18.46m x  9.1% x 0.200 W/K.m = 0.336
        # corner                        = 2x 3.05m x 50.5% x 0.200 W/K.m = 0.616
        # grade                         =   18.46m         x 0.200 W/K.m = 3.692
        # fenestration                  =   26.83m         x 0.200 W/K.m = 5.366
        expect(loss ).to be_within(0.01).of(10.01)
        expect(gross).to be_within(0.01).of(56.30)              # 18.46W x 3.05H
        expect(net  ).to be_within(0.01).of(45.15)
        expect(net  ).to be_within(0.01).of(gross - 4 * w_area)
        expect(r    ).to be_within(0.01).of(0.627)
      end
    end

    # The south-facing wall holds 0.249 W/K.m2 worth of thermal bridging, while
    # both east-facing and west-facing walls hold 0.224 W/K.m2. The north-facing
    # wall holds 0.217 W/K.m2 (the lowest of all 4x walls), which (once
    # processed by TBD) will nearly reach prescribed NECB2017 & NECB2020 climate
    # zone 7 Ut requirements of 0.210 W/m2.K (Rsi 4.76 m2.K/W or R27). Taking
    # into account air film resistances and non-insulating layer resistances
    # (e.g. ~Rsi 0.384 m2.K/W) of the north-facing wall construction, the (max)
    # admissible insulating layer U becomes ~0.228 (Rsi 4.38 or R24.9).
    #
    #   0.228 = layer U + 0.217 ... layer U = 0.0112 (or RSi 89.3 or R507)
    #
    # TBD would fail for the south-facing wall in isolation, as the losses
    # exceed the admissible insulating layer U factor:
    #
    #   0.228 = layer U + 0.249
    #
    # However, TBD's uprating calculations here consider all MAJOR thermal
    # bridge losses (of exposed walls), spread out over total exposed wall area.
    # Ultimately, the required, area-weighted wall Uo will be somewhere between
    # 0.0112 and 0 W/m2.K (i.e. an R-factor ranging from ~500 to infinity).
    TBD.clean!
    argh  = {}
    model = translator.loadModel(path)
    expect(model.empty?).to be(false)
    model = model.get

    argh[:option      ] = "efficient (BETBG)"
    argh[:uprate_walls] = true
    argh[:wall_option ] = "ALL wall constructions"
    argh[:wall_ut     ] = 0.210                 # NECB CZ7 2017 (RSi 4.76 / R27)
    json = TBD.process(model, argh)
    expect(json.is_a?(Hash)).to be(true)
    expect(json.key?(:io)).to be(true)
    expect(json.key?(:surfaces)).to be(true)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.status).to eq(0)

    expect(argh.key?(:wall_uo)).to be(true)
    expect(argh.key?(:roof_uo)).to be(false)
    expect(argh[:wall_uo].nil?).to be(false)
    expect(argh[:wall_uo]).to be_within(0.00001).of(0.00021) # RSi 4,762 (R27K)!

    # As expected, the area-weighted required Uo to satisfy the NECB2017/2020
    # climate zone 7 requirement (given the extra heat loss from MAJOR thermal
    # bridging) is mathematically possible, but unpractical. EnergyPlus would
    # likely reject these (significant) changes in its CTF calculations.

    # ----- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ----- #
    # Final uprating attempt, yet referencing slightly 'poorer' PSI factors.
    TBD.clean!
    argh  = {}
    model = translator.loadModel(path)
    expect(model.empty?).to be(false)
    model = model.get

    argh[:io_path     ] = File.join(__dir__, "../json/tbd_smalloffice.json")
    argh[:schema_path ] = File.join(__dir__, "../tbd.schema.json")
    argh[:uprate_walls] = true
    argh[:wall_option ] = "ALL wall constructions"
    argh[:wall_ut     ] = 0.210                 # NECB CZ7 2017 (RSi 4.76 / R27)
    json = TBD.process(model, argh)
    expect(json.is_a?(Hash)).to be(true)
    expect(json.key?(:io)).to be(true)
    expect(json.key?(:surfaces)).to be(true)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.error?).to be(true)
    expect(TBD.logs.size).to eq(2)
    # TBD.logs.each do |log|
    #   puts log
    # end
    expect(TBD.logs.first[:message].include?("Zero")).to be(true)
    expect(TBD.logs.last[:message].include?("Unable to uprate")).to be(true)
    expect(argh.key?(:wall_uo)).to be(false)
    expect(argh.key?(:roof_uo)).to be(false)
  end

  it "can pre-process UA parameters" do
    TBD.clean!
    argh = {}

    translator = OpenStudio::OSVersion::VersionTranslator.new
    file       = File.join(__dir__, "files/osms/in/warehouse.osm")
    path       = OpenStudio::Path.new(file)
    model      = translator.loadModel(path)
    expect(model.empty?).to be(false)
    model      = model.get
    setpoints  = TBD.heatingTemperatureSetpoints?(model)
    setpoints  = TBD.coolingTemperatureSetpoints?(model) || setpoints
    expect(setpoints).to be(true)
    airloops   = TBD.airLoopsHVAC?(model)
    expect(airloops).to be(true)

    model.getSpaces.each do |space|
      expect(space.thermalZone.empty?).to be(false)
      expect(TBD.plenum?(space, airloops, setpoints)).to be(false)
      zone     = space.thermalZone.get
      heat_spt = TBD.maxHeatScheduledSetpoint(zone)
      cool_spt = TBD.minCoolScheduledSetpoint(zone)
      expect(heat_spt.key?(:spt)).to be(true)
      expect(cool_spt.key?(:spt)).to be(true)
      heating  = heat_spt[:spt]
      cooling  = cool_spt[:spt]

      case zone.nameString
      when "Zone1 Office ZN"
        expect(heating).to be_within(0.1).of(21.1)
        expect(cooling).to be_within(0.1).of(23.9)
      when "Zone2 Fine Storage ZN"
        expect(heating).to be_within(0.1).of(15.6)
        expect(cooling).to be_within(0.1).of(26.7)
      else
        expect(heating).to be_within(0.1).of(10.0)
        expect(cooling).to be_within(0.1).of(50.0)
      end
    end

    ids = { a: "Office Front Wall",
            b: "Office Left Wall",
            c: "Fine Storage Roof",
            d: "Fine Storage Office Front Wall",
            e: "Fine Storage Office Left Wall",
            f: "Fine Storage Front Wall",
            g: "Fine Storage Left Wall",
            h: "Fine Storage Right Wall",
            i: "Bulk Storage Roof",
            j: "Bulk Storage Rear Wall",
            k: "Bulk Storage Left Wall",
            l: "Bulk Storage Right Wall" }.freeze

    id2 = { a: "Office Front Door",
            b: "Office Left Wall Door",
            c: "Fine Storage Left Door",
            d: "Fine Storage Right Door",
            e: "Bulk Storage Door-1",
            f: "Bulk Storage Door-2",
            g: "Bulk Storage Door-3",
            h: "Overhead Door 1",
            i: "Overhead Door 2",
            j: "Overhead Door 3",
            k: "Overhead Door 4",
            l: "Overhead Door 5",
            m: "Overhead Door 6",
            n: "Overhead Door 7" }.freeze

    psi    = TBD::PSI.new
    ref    = "code (Quebec)"
    shorts = psi.shorthands(ref)
    expect(shorts[:has].empty?).to be(false)
    expect(shorts[:val].empty?).to be(false)
    has    = shorts[:has]
    val    = shorts[:val]
    expect(has.empty?).to be(false)
    expect(val.empty?).to be(false)

    argh[:option     ] = "poor (BETBG)"
    argh[:seed       ] = "./files/osms/in/warehouse.osm"
    argh[:io_path    ] = File.join(__dir__, "../json/tbd_warehouse10.json")
    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")
    argh[:gen_ua     ] = true
    argh[:ua_ref     ] = ref
    argh[:version    ] = model.getVersion.versionIdentifier

    json = TBD.process(model, argh)
    expect(json.is_a?(Hash)).to be(true)
    expect(json.key?(:io)).to be(true)
    expect(json.key?(:surfaces)).to be(true)
    argh[:io      ] = json[:io]
    argh[:surfaces] = json[:surfaces]
    expect(TBD.status).to eq(0)
    expect(TBD.logs.empty?).to be(true)
    expect(argh[:io      ].nil?).to be(false)
    expect(argh[:io      ].is_a?(Hash)).to be(true)
    expect(argh[:io      ].empty?).to be(false)
    expect(argh[:surfaces].nil?).to be(false)
    expect(argh[:surfaces].is_a?(Hash)).to be(true)
    expect(argh[:io      ].key?(:edges))
    expect(argh[:io      ][:edges].size).to eq(300)
    expect(argh[:surfaces].size).to eq(23)

    argh[:io][:description] = "test"
    # Set up 2x heating setpoint (HSTP) "blocks":
    #   bloc1: spaces/zones with HSTP >= 18°C
    #   bloc2: spaces/zones with HSTP < 18°C
    #   (ref: 2021 Quebec energy code 3.3. UA' trade-off methodology)
    #   ... could be generalized in the future e.g., more blocks, user-set HSTP.
    #
    # Determine UA' compliance separately for (i) bloc1 & (ii) bloc2.
    #
    # Each block's UA' = ∑ U•area + ∑ PSI•length + ∑ KHI•count
    blc = { walls:   0, roofs:     0, floors:    0, doors:     0,
            windows: 0, skylights: 0, rimjoists: 0, parapets:  0,
            trim:    0, corners:   0, balconies: 0, grade:     0,
            other:   0 # includes party wall edges, expansion joints, etc.
          }

    bloc1       = {}
    bloc2       = {}
    bloc1[:pro] = blc
    bloc1[:ref] = blc.clone
    bloc2[:pro] = blc.clone
    bloc2[:ref] = blc.clone

    argh[:surfaces].each do |id, surface|
      expect(surface.key?(:deratable)).to be(true)
      next unless surface[:deratable]
      expect(ids.has_value?(id)).to be(true)
      expect(surface.key?(:ref )).to be(true)
      expect(surface.key?(:type)).to be(true)
      expect(surface.key?(:net )).to be(true)
      expect(surface.key?(:u   )).to be(true)
      expect(surface[:net] > TOL).to be(true)
      expect(surface[:u  ] > TOL).to be(true)

      expect(surface[:u]).to be_within(0.01).of(0.48)           if id == ids[:a]
      expect(surface[:u]).to be_within(0.01).of(0.48)           if id == ids[:b]
      expect(surface[:u]).to be_within(0.01).of(0.31)           if id == ids[:c]
      expect(surface[:u]).to be_within(0.01).of(0.48)           if id == ids[:d]
      expect(surface[:u]).to be_within(0.01).of(0.48)           if id == ids[:e]
      expect(surface[:u]).to be_within(0.01).of(0.48)           if id == ids[:f]
      expect(surface[:u]).to be_within(0.01).of(0.48)           if id == ids[:g]
      expect(surface[:u]).to be_within(0.01).of(0.48)           if id == ids[:h]
      expect(surface[:u]).to be_within(0.01).of(0.55)           if id == ids[:i]
      expect(surface[:u]).to be_within(0.01).of(0.64)           if id == ids[:j]
      expect(surface[:u]).to be_within(0.01).of(0.64)           if id == ids[:k]
      expect(surface[:u]).to be_within(0.01).of(0.64)           if id == ids[:l]

      expect(surface[:ref]).to be_within(0.01).of(0.28)         if id == ids[:a]
      expect(surface[:ref]).to be_within(0.01).of(0.28)         if id == ids[:b]
      expect(surface[:ref]).to be_within(0.01).of(0.18)         if id == ids[:c]
      expect(surface[:ref]).to be_within(0.01).of(0.28)         if id == ids[:d]
      expect(surface[:ref]).to be_within(0.01).of(0.28)         if id == ids[:e]
      expect(surface[:ref]).to be_within(0.01).of(0.28)         if id == ids[:f]
      expect(surface[:ref]).to be_within(0.01).of(0.28)         if id == ids[:g]
      expect(surface[:ref]).to be_within(0.01).of(0.28)         if id == ids[:h]
      expect(surface[:ref]).to be_within(0.01).of(0.23)         if id == ids[:i]
      expect(surface[:ref]).to be_within(0.01).of(0.34)         if id == ids[:j]
      expect(surface[:ref]).to be_within(0.01).of(0.34)         if id == ids[:k]
      expect(surface[:ref]).to be_within(0.01).of(0.34)         if id == ids[:l]

      expect(surface.key?(:heating)).to be(true)
      expect(surface.key?(:cooling)).to be(true)

      bloc = bloc1
      bloc = bloc2                                     if surface[:heating] < 18

      if surface[:type] == :wall
        bloc[:pro][:walls ] += surface[:net] * surface[:u  ]
        bloc[:ref][:walls ] += surface[:net] * surface[:ref]
      elsif surface[:type ] == :ceiling
        bloc[:pro][:roofs ] += surface[:net] * surface[:u  ]
        bloc[:ref][:roofs ] += surface[:net] * surface[:ref]
      else
        bloc[:pro][:floors] += surface[:net] * surface[:u  ]
        bloc[:ref][:floors] += surface[:net] * surface[:ref]
      end

      if surface.key?(:doors)
        surface[:doors].each do |i, door|
          expect(id2.has_value?(i)).to be(true)
          expect(door.key?(:gross )).to be(true )
          expect(door.key?(:glazed)).to be(false)
          expect(door.key?(:u     )).to be(true )
          expect(door.key?(:ref   )).to be(true )
          expect(door[:gross] > TOL).to be(true )
          expect(door[:u    ] > TOL).to be(true )
          expect(door[:ref  ] > TOL).to be(true )
          expect(door[:u]).to be_within(0.01).of(3.98)

          bloc[:pro][:doors] += door[:gross] * door[:u  ]
          bloc[:ref][:doors] += door[:gross] * door[:ref]
        end
      end

      if surface.key?(:skylights)
        surface[:skylights].each do |i, skylight|
          expect(skylight.key?(:gross)).to be(true)
          expect(skylight.key?(:u    )).to be(true)
          expect(skylight.key?(:ref  )).to be(true)
          expect(skylight[:gross] > TOL).to be(true)
          expect(skylight[:u    ] > TOL).to be(true)
          expect(skylight[:ref  ] > TOL).to be(true)
          expect(skylight[:u]).to be_within(0.01).of(6.64)

          bloc[:pro][:skylights] += skylight[:gross] * skylight[:u  ]
          bloc[:ref][:skylights] += skylight[:gross] * skylight[:ref]
        end
      end

      id3 = { a: "Office Front Wall Window 1",
              b: "Office Front Wall Window2" }.freeze

      if surface.key?(:windows)
        surface[:windows].each do |i, window|
          expect(window.key?(:u   )).to be(true)
          expect(window.key?(:ref )).to be(true)
          expect(window[:ref] > TOL).to be(true)
          expect(window[:u  ] > 0  ).to be(true)
          expect(window[:u    ]).to be_within(0.01).of(4.00)     if i == id3[:a]
          expect(window[:u    ]).to be_within(0.01).of(3.50)     if i == id3[:b]
          expect(window[:gross]).to be_within(0.10).of(5.58)     if i == id3[:a]
          expect(window[:gross]).to be_within(0.10).of(5.58)     if i == id3[:b]

          bloc[:pro][:windows] += window[:gross] * window[:u  ]
          bloc[:ref][:windows] += window[:gross] * window[:ref]

          next if i == id3[:a] || i == id3[:b]
          expect(window[:gross]).to be_within(0.1).of(3.25)
          expect(window[:u    ]).to be_within(0.01).of(2.35)
        end
      end

      if surface.key?(:edges)
        surface[:edges].values.each do |edge|
          expect(edge.key?(:type )).to be(true)
          expect(edge.key?(:ratio)).to be(true)
          expect(edge.key?(:ref  )).to be(true)
          expect(edge.key?(:psi  )).to be(true)
          next unless edge[:psi] > TOL

          tt = psi.safe(ref, edge[:type])
          expect(tt.nil?).to be(false)
          expect(edge[:ref]).to be_within(0.01).of(val[tt] * edge[:ratio])
          rate = edge[:ref] / edge[:psi] * 100

          case tt
          when :rimjoist
            expect(rate).to be_within(0.1).of(30.0)
            bloc[:pro][:rimjoists] += edge[:length] * edge[:psi  ]
            bloc[:ref][:rimjoists] += edge[:length] * edge[:ratio] * val[tt]
          when :parapet
            expect(rate).to be_within(0.1).of(40.6)
            bloc[:pro][:parapets ] += edge[:length] * edge[:psi  ]
            bloc[:ref][:parapets ] += edge[:length] * edge[:ratio] * val[tt]
          when :fenestration
            expect(rate).to be_within(0.1).of(40.0)
            bloc[:pro][:trim     ] += edge[:length] * edge[:psi  ]
            bloc[:ref][:trim     ] += edge[:length] * edge[:ratio] * val[tt]
          when :corner
            expect(rate).to be_within(0.1).of(35.3)
            bloc[:pro][:corners  ] += edge[:length] * edge[:psi  ]
            bloc[:ref][:corners  ] += edge[:length] * edge[:ratio] * val[tt]
          when :grade
            expect(rate).to be_within(0.1).of(52.9)
            bloc[:pro][:grade    ] += edge[:length] * edge[:psi  ]
            bloc[:ref][:grade    ] += edge[:length] * edge[:ratio] * val[tt]
          else
            expect(rate).to be_within(0.1).of( 0.0)
            bloc[:pro][:other    ] += edge[:length] * edge[:psi  ]
            bloc[:ref][:other    ] += edge[:length] * edge[:ratio] * val[tt]
          end
        end
      end

      if surface.key?(:pts)
        surface[:pts].values.each do |pts|
          expect(pts.key?(:val)).to be(true)
          expect(pts.key?(:n  )).to be(true)
          expect(pts.key?(:ref)).to be(true)

          bloc[:pro][:other] += pts[:val] * pts[:n]
          bloc[:ref][:other] += pts[:ref] * pts[:n]
        end
      end
    end

    expect(bloc1[:pro][:walls    ]).to be_within(0.1).of(  60.1)
    expect(bloc1[:pro][:roofs    ]).to be_within(0.1).of(   0.0)
    expect(bloc1[:pro][:floors   ]).to be_within(0.1).of(   0.0)
    expect(bloc1[:pro][:doors    ]).to be_within(0.1).of(  23.3)
    expect(bloc1[:pro][:windows  ]).to be_within(0.1).of(  57.1)
    expect(bloc1[:pro][:skylights]).to be_within(0.1).of(   0.0)
    expect(bloc1[:pro][:rimjoists]).to be_within(0.1).of(  17.5)
    expect(bloc1[:pro][:parapets ]).to be_within(0.1).of(   0.0)
    expect(bloc1[:pro][:trim     ]).to be_within(0.1).of(  23.3)
    expect(bloc1[:pro][:corners  ]).to be_within(0.1).of(   3.6)
    expect(bloc1[:pro][:balconies]).to be_within(0.1).of(   0.0)
    expect(bloc1[:pro][:grade    ]).to be_within(0.1).of(  29.8)
    expect(bloc1[:pro][:other    ]).to be_within(0.1).of(   0.0)

    bloc1_pro_UA = bloc1[:pro].values.reduce(:+)
    expect(bloc1_pro_UA).to be_within(0.1).of(214.8)
    # Info: Design (fully heated): 199.2 W/K vs 114.2 W/K

    expect(bloc1[:ref][:walls    ]).to be_within(0.1).of(  35.0)
    expect(bloc1[:ref][:roofs    ]).to be_within(0.1).of(   0.0)
    expect(bloc1[:ref][:floors   ]).to be_within(0.1).of(   0.0)
    expect(bloc1[:ref][:doors    ]).to be_within(0.1).of(   5.3)
    expect(bloc1[:ref][:windows  ]).to be_within(0.1).of(  35.3)
    expect(bloc1[:ref][:skylights]).to be_within(0.1).of(   0.0)
    expect(bloc1[:ref][:rimjoists]).to be_within(0.1).of(   5.3)
    expect(bloc1[:ref][:parapets ]).to be_within(0.1).of(   0.0)
    expect(bloc1[:ref][:trim     ]).to be_within(0.1).of(   9.3)
    expect(bloc1[:ref][:corners  ]).to be_within(0.1).of(   1.3)
    expect(bloc1[:ref][:balconies]).to be_within(0.1).of(   0.0)
    expect(bloc1[:ref][:grade    ]).to be_within(0.1).of(  15.8)
    expect(bloc1[:ref][:other    ]).to be_within(0.1).of(   0.0)

    bloc1_ref_UA = bloc1[:ref].values.reduce(:+)
    expect(bloc1_ref_UA).to be_within(0.1).of(107.2)

    expect(bloc2[:pro][:walls    ]).to be_within(0.1).of(1342.0)
    expect(bloc2[:pro][:roofs    ]).to be_within(0.1).of(2169.2)
    expect(bloc2[:pro][:floors   ]).to be_within(0.1).of(   0.0)
    expect(bloc2[:pro][:doors    ]).to be_within(0.1).of( 245.6)
    expect(bloc2[:pro][:windows  ]).to be_within(0.1).of(   0.0)
    expect(bloc2[:pro][:skylights]).to be_within(0.1).of( 454.3)
    expect(bloc2[:pro][:rimjoists]).to be_within(0.1).of(  17.5)
    expect(bloc2[:pro][:parapets ]).to be_within(0.1).of( 234.1)
    expect(bloc2[:pro][:trim     ]).to be_within(0.1).of( 155.0)
    expect(bloc2[:pro][:corners  ]).to be_within(0.1).of(  25.4)
    expect(bloc2[:pro][:balconies]).to be_within(0.1).of(   0.0)
    expect(bloc2[:pro][:grade    ]).to be_within(0.1).of( 218.9)
    expect(bloc2[:pro][:other    ]).to be_within(0.1).of(   1.6)

    bloc2_pro_UA = bloc2[:pro].values.reduce(:+)
    expect(bloc2_pro_UA).to be_within(0.1).of(4863.6)

    expect(bloc2[:ref][:walls    ]).to be_within(0.1).of( 732.0)
    expect(bloc2[:ref][:roofs    ]).to be_within(0.1).of( 961.8)
    expect(bloc2[:ref][:floors   ]).to be_within(0.1).of(   0.0)
    expect(bloc2[:ref][:doors    ]).to be_within(0.1).of(  67.5)
    expect(bloc2[:ref][:windows  ]).to be_within(0.1).of(   0.0)
    expect(bloc2[:ref][:skylights]).to be_within(0.1).of( 225.9)
    expect(bloc2[:ref][:rimjoists]).to be_within(0.1).of(   5.3)
    expect(bloc2[:ref][:parapets ]).to be_within(0.1).of(  95.1)
    expect(bloc2[:ref][:trim     ]).to be_within(0.1).of(  62.0)
    expect(bloc2[:ref][:corners  ]).to be_within(0.1).of(   9.0)
    expect(bloc2[:ref][:balconies]).to be_within(0.1).of(   0.0)
    expect(bloc2[:ref][:grade    ]).to be_within(0.1).of( 115.9)
    expect(bloc2[:ref][:other    ]).to be_within(0.1).of(   1.0)

    bloc2_ref_UA = bloc2[:ref].values.reduce(:+)
    expect(bloc2_ref_UA).to be_within(0.1).of(2275.4)

    # Testing summaries function.
    ua = TBD.ua_summary(Time.now, argh)
    expect(ua.nil?).to be(false)
    expect(ua.empty?).to be(false)
    expect(ua.is_a?(Hash)).to be(true)
    expect(ua.key?(:model))
    expect(ua.key?(:fr)).to be(true)
    expect(ua.key?(:en)).to be(true)

    expect(ua[:fr].key?(:objective)).to be(true)
    expect(ua[:fr].key?(:details  )).to be(true)
    expect(ua[:fr].key?(:areas    )).to be(true)
    expect(ua[:fr].key?(:notes    )).to be(true)
    expect(ua[:fr].key?(:b1       )).to be(true)
    expect(ua[:fr].key?(:b2       )).to be(true)
    expect(ua[:fr][:details  ].is_a?(Array)).to be(true)
    expect(ua[:fr][:areas    ].is_a?(Hash )).to be(true)
    expect(ua[:fr][:details  ].empty?).to be(false)
    expect(ua[:fr][:objective].empty?).to be(false)
    expect(ua[:fr][:areas    ].empty?).to be(false)
    expect(ua[:fr][:notes    ].empty?).to be(false)
    expect(ua[:fr][:b1       ].empty?).to be(false)
    expect(ua[:fr][:b2       ].empty?).to be(false)
    expect(ua[:fr][:areas].key?(:walls )).to be(true )
    expect(ua[:fr][:areas].key?(:roofs )).to be(true )
    expect(ua[:fr][:areas].key?(:floors)).to be(false)

    expect(ua[:fr][:b1].key?(:summary  )).to be(true )
    expect(ua[:fr][:b1].key?(:walls    )).to be(true )
    expect(ua[:fr][:b1].key?(:roofs    )).to be(false)
    expect(ua[:fr][:b1].key?(:floors   )).to be(false)
    expect(ua[:fr][:b1].key?(:doors    )).to be(true )
    expect(ua[:fr][:b1].key?(:windows  )).to be(true )
    expect(ua[:fr][:b1].key?(:skylights)).to be(false)
    expect(ua[:fr][:b1].key?(:rimjoists)).to be(true )
    expect(ua[:fr][:b1].key?(:parapets )).to be(false)
    expect(ua[:fr][:b1].key?(:trim     )).to be(true )
    expect(ua[:fr][:b1].key?(:corners  )).to be(true )
    expect(ua[:fr][:b1].key?(:balconies)).to be(false)
    expect(ua[:fr][:b1].key?(:grade    )).to be(true )
    expect(ua[:fr][:b1].key?(:other    )).to be(false)

    expect(ua[:fr][:b2].key?(:summary  )).to be(true )
    expect(ua[:fr][:b2].key?(:walls    )).to be(true )
    expect(ua[:fr][:b2].key?(:roofs    )).to be(true )
    expect(ua[:fr][:b2].key?(:floors   )).to be(false)
    expect(ua[:fr][:b2].key?(:doors    )).to be(true )
    expect(ua[:fr][:b2].key?(:windows  )).to be(false)
    expect(ua[:fr][:b2].key?(:skylights)).to be(true )
    expect(ua[:fr][:b2].key?(:rimjoists)).to be(true )
    expect(ua[:fr][:b2].key?(:parapets )).to be(true )
    expect(ua[:fr][:b2].key?(:trim     )).to be(true )
    expect(ua[:fr][:b2].key?(:corners  )).to be(true )
    expect(ua[:fr][:b2].key?(:balconies)).to be(false)
    expect(ua[:fr][:b2].key?(:grade    )).to be(true )
    expect(ua[:fr][:b2].key?(:other    )).to be(true )

    expect(ua[:en].key?(:b1)).to be(true)
    expect(ua[:en].key?(:b2)).to be(true)
    expect(ua[:en][:b1].empty?).to be(false)
    expect(ua[:en][:b2].empty?).to be(false)

    expect(ua[:en][:b1].key?(:summary  )).to be(true )
    expect(ua[:en][:b1].key?(:walls    )).to be(true )
    expect(ua[:en][:b1].key?(:roofs    )).to be(false)
    expect(ua[:en][:b1].key?(:floors   )).to be(false)
    expect(ua[:en][:b1].key?(:doors    )).to be(true )
    expect(ua[:en][:b1].key?(:windows  )).to be(true )
    expect(ua[:en][:b1].key?(:skylights)).to be(false)
    expect(ua[:en][:b1].key?(:rimjoists)).to be(true )
    expect(ua[:en][:b1].key?(:parapets )).to be(false)
    expect(ua[:en][:b1].key?(:trim     )).to be(true )
    expect(ua[:en][:b1].key?(:corners  )).to be(true )
    expect(ua[:en][:b1].key?(:balconies)).to be(false)
    expect(ua[:en][:b1].key?(:grade    )).to be(true )
    expect(ua[:en][:b1].key?(:other    )).to be(false)

    expect(ua[:en][:b2].key?(:summary  )).to be(true )
    expect(ua[:en][:b2].key?(:walls    )).to be(true )
    expect(ua[:en][:b2].key?(:roofs    )).to be(true )
    expect(ua[:en][:b2].key?(:floors   )).to be(false)
    expect(ua[:en][:b2].key?(:doors    )).to be(true )
    expect(ua[:en][:b2].key?(:windows  )).to be(false)
    expect(ua[:en][:b2].key?(:skylights)).to be(true )
    expect(ua[:en][:b2].key?(:rimjoists)).to be(true )
    expect(ua[:en][:b2].key?(:parapets )).to be(true )
    expect(ua[:en][:b2].key?(:trim     )).to be(true )
    expect(ua[:en][:b2].key?(:corners  )).to be(true )
    expect(ua[:en][:b2].key?(:balconies)).to be(false)
    expect(ua[:en][:b2].key?(:grade    )).to be(true )
    expect(ua[:en][:b2].key?(:other    )).to be(true )

    ud_md_en = TBD.ua_md(ua, :en)
    path     = File.join(__dir__, "files/ua/ua_en.md")
    File.open(path, "w") { |file| file.puts ud_md_en }

    ud_md_fr = TBD.ua_md(ua, :fr)
    path     = File.join(__dir__, "files/ua/ua_fr.md")
    File.open(path, "w") { |file| file.puts ud_md_fr }

    # Try with an incomplete reference, e.g. (non thermal bridging)
    TBD.clean!
    file  = File.join(__dir__, "files/osms/in/warehouse.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model.empty?).to be(false)
    model = model.get
    # When faced with an edge that may be characterized by more than one thermal
    # bridge type (e.g. ground-floor door "sill" vs "grade" edge; "corner" vs
    # corner window "jamb"), TBD retains the edge type (amongst candidate edge
    # types) representing the greatest heat loss:
    #
    #   psi = edge[:psi].values.max
    #   type = edge[:psi].key(psi)
    #
    # As long as there is a slight difference in PSI-values between candidate
    # edge types, the automated selection will be deterministic. With 2 or more
    # edge types sharing the exact same PSI value (e.g. 0.3 W/K per m), the
    # final selection of edge type becomes less obvious. It is not randomly
    # selected, but rather based on the (somewhat arbitrary) design choice of
    # which edge type is processed first in psi.rb (line ~1300 onwards). For
    # instance, fenestration perimeter joints are treated before corners or
    # parapets. When dealing with equal hash values, Ruby's Hash "key" method
    # returns the first key (i.e. edge type) that matches the criterion:
    #
    #   https://docs.ruby-lang.org/en/2.0.0/Hash.html#method-i-key
    #
    # From an energy simulation results perspective, the consequences of this
    # pseudo-random choice are insignificant (i.e. same PSI-value). For UA'
    # comparisons, the situation becomes less obvious in outlier cases. When a
    # reference value needs to be generated for the edge described above, TBD
    # retains the original autoselected edge type, yet applies reference PSI
    # values (e.g. code). So far so good. However, when "(non thermal bridging)"
    # is retained as a default PSI design set (not as a reference set), all edge
    # types will necessarily have 0 W/K per metre as PSI-values. Same with the
    # "efficient (BETBG)" PSI set (all but one type at 0.2 W/K per m). Not
    # obvious (for users) which edge type will be selected by TBD for multi-type
    # edges. This also has the undesirable effect of generating variations in
    # reference UA' tallies, depending on the chosen design PSI set (as the
    # reference PSI set may have radically different PSI-values depending on
    # the pseudo-random edge type selection). Fortunately, this effect is
    # limited to the somewhat academic PSI sets like "(non thermal bridging)" or
    # "efficient (BETBG)".
    #
    # In the end, the above discussion remains an "aide-mémoire" for future
    # guide material, yet also as a basis for peer-review commentary of upcoming
    # standards on thermal bridging.
    argh[:io         ] = nil
    argh[:surfaces   ] = nil
    argh[:option     ] = "(non thermal bridging)"
    argh[:io_path    ] = nil
    argh[:schema_path] = nil
    argh[:gen_ua     ] = true
    argh[:ua_ref     ] = ref
    json = TBD.process(model, argh)
    expect(json.is_a?(Hash)).to be(true)
    expect(json.key?(:io)).to be(true)
    expect(json.key?(:surfaces)).to be(true)
    argh[:io         ] = json[:io]
    argh[:surfaces   ] = json[:surfaces]

    expect(TBD.status).to eq(0)
    expect(TBD.logs.empty?).to be(true)
    expect(argh[:io      ].nil?).to be(false)
    expect(argh[:io      ].is_a?(Hash)).to be(true)
    expect(argh[:io      ].empty?).to be(false)
    expect(argh[:surfaces].nil?).to be(false)
    expect(argh[:surfaces].is_a?(Hash)).to be(true)
    expect(argh[:io      ].key?(:edges))
    expect(argh[:io      ][:edges].size).to eq(300)
    expect(argh[:surfaces].size).to eq(23)

    # Testing summaries function.
    argh[:io][:description] = "testing non thermal bridging"

    ua = TBD.ua_summary(Time.now, argh)
    expect(ua.nil?).to be(false)
    expect(ua.empty?).to be(false)
    expect(ua.is_a?(Hash)).to be(true)
    expect(ua.key?(:model))

    en_ud_md = TBD.ua_md(ua, :en)
    path     = File.join(__dir__, "files/ua/en_ua.md")
    File.open(path, "w") { |file| file.puts en_ud_md  }

    fr_ud_md = TBD.ua_md(ua, :fr)
    path     = File.join(__dir__, "files/ua/fr_ua.md")
    File.open(path, "w") { |file| file.puts fr_ud_md }
  end

  it "can work off of a cloned model" do
    TBD.clean!
    argh1 = { option: "poor (BETBG)" }
    argh2 = { option: "poor (BETBG)" }
    argh3 = { option: "poor (BETBG)" }

    translator = OpenStudio::OSVersion::VersionTranslator.new
    file       = File.join(__dir__, "files/osms/in/warehouse.osm")
    path       = OpenStudio::Path.new(file)
    model      = translator.loadModel(path)
    expect(model.empty?).to be(false)
    model      = model.get
    alt_model  = model.clone
    alt_file   = File.join(__dir__, "files/osms/out/alt_warehouse.osm")
    alt_model.save(alt_file, true)

    # Despite one being the clone of the other, files will not be identical,
    # namely due to unique handles.
    expect(FileUtils.identical?(file, alt_file)).to be(false)

    json1 = TBD.process(model, argh1)
    expect(json1.is_a?(Hash)).to be(true)
    expect(json1.key?(:io)).to be(true)
    expect(json1.key?(:surfaces)).to be(true)
    argh1[:io      ] = json1[:io      ]
    argh1[:surfaces] = json1[:surfaces]
    expect(TBD.status).to eq(0)
    expect(TBD.logs.empty?).to be(true)
    expect(argh1[:io].nil?).to be(false)
    expect(argh1[:io].is_a?(Hash)).to be(true)
    expect(argh1[:io].empty?).to be(false)
    expect(argh1[:io].key?(:edges)).to be(true)
    expect(argh1[:io][:edges].size).to eq(300)
    expect(argh1[:surfaces].nil?).to be(false)
    expect(argh1[:surfaces].is_a?(Hash)).to be(true)
    expect(argh1[:surfaces].size).to eq(23)
    out1  = JSON.pretty_generate(argh1[:io])
    file1 = File.join(__dir__, "../json/tbd_warehouse12.out.json")
    File.open(file1, "w") { |f| f.puts out1 }

    TBD.clean!
    alt_file  = File.join(__dir__, "files/osms/out/alt_warehouse.osm")
    alt_path  = OpenStudio::Path.new(alt_file)
    alt_model = translator.loadModel(alt_path)
    expect(alt_model.empty?).to be(false)
    alt_model = alt_model.get

    json2 = TBD.process(alt_model, argh2)
    expect(json2.is_a?(Hash)).to be(true)
    expect(json2.key?(:io)).to be(true)
    expect(json2.key?(:surfaces)).to be(true)
    argh2[:io      ] = json2[:io      ]
    argh2[:surfaces] = json2[:surfaces]
    expect(TBD.status).to eq(0)
    expect(TBD.logs.empty?).to be(true)
    expect(argh2[:io].nil?).to be(false)
    expect(argh2[:io].is_a?(Hash)).to be(true)
    expect(argh2[:io].empty?).to be(false)
    expect(argh2[:io].key?(:edges)).to be(true)
    expect(argh2[:io][:edges].size).to eq(300)
    expect(argh2[:surfaces].nil?).to be(false)
    expect(argh2[:surfaces].is_a?(Hash)).to be(true)
    expect(argh2[:surfaces].size).to eq(23)
    out2  = JSON.pretty_generate(argh2[:io])
    file2 = File.join(__dir__, "../json/tbd_warehouse13.out.json")
    File.open(file2, "w") { |f| f.puts out2 }

    # The JSON output files are identical.
    expect(FileUtils.identical?(file1, file2)).to be(true)

    time = Time.now

    # Original output UA' MD file.
    argh1[:ua_ref          ] = "code (Quebec)"
    argh1[:io][:description] = "testing equality"
    argh1[:version         ] = model.getVersion.versionIdentifier
    argh1[:seed            ] = File.join(__dir__, "files/osms/in/warehouse.osm")
    ua1  = TBD.ua_summary(time, argh1)
    expect(ua1.nil?).to be(false)
    expect(ua1.empty?).to be(false)
    expect(ua1.is_a?(Hash)).to be(true)
    expect(ua1.key?(:model))
    ua1_md = TBD.ua_md(ua1, :en)
    expect(ua1_md.is_a?(Array)).to be(true)
    expect(ua1_md.empty?).to be(false)
    ua1_md.each { |x| expect(x.is_a?(String)).to be(true) }
    path1 = File.join(__dir__, "files/ua/ua1.md")
    File.open(path1, "w") { |f| f.puts ua1_md }

    # Alternate output UA' MD file.
    argh2[:ua_ref          ] = "code (Quebec)"
    argh2[:io][:description] = "testing equality"
    argh2[:version         ] = model.getVersion.versionIdentifier
    argh2[:seed            ] = File.join(__dir__, "files/osms/in/warehouse.osm")
    ua2 = TBD.ua_summary(time, argh2)
    expect(ua2.nil?).to be(false)
    expect(ua2.empty?).to be(false)
    expect(ua2.is_a?(Hash)).to be(true)
    expect(ua2.key?(:model))
    ua2_md = TBD.ua_md(ua2, :en)
    expect(ua2_md.is_a?(Array)).to be(true)
    expect(ua2_md.empty?).to be(false)
    ua2_md.each { |x| expect(x.is_a?(String)).to be(true) }
    path2 = File.join(__dir__, "files/ua/ua2.md")
    File.open(path2, "w") { |f| f.puts ua2_md }

    # Both output UA' MD files should be identical.
    expect(TBD.status).to eq(0)
    expect(TBD.logs.empty?).to be(true)
    expect(FileUtils.identical?(path1, path2)).to be(true)

    TBD.clean!
    file  = File.join(__dir__, "files/osms/in/warehouse.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model.empty?).to be(false)
    model = model.get

    alt2_model = OpenStudio::Model::Model.new
    alt2_model.addObjects(model.toIdfFile.objects)        # << thanks Macumber !
    alt2_file  = File.join(__dir__, "files/osms/out/alt2_warehouse.osm")
    alt2_model.save(alt2_file, true)

    # Still get the differences in handles (not consequential at all if the TBD
    # JSON output files are identical).
    expect(FileUtils.identical?(file, alt2_file)).to be(false)

    json3 = TBD.process(alt2_model, argh3)
    expect(json3.is_a?(Hash)).to be(true)
    expect(json3.key?(:io)).to be(true)
    expect(json3.key?(:surfaces)).to be(true)
    argh3[:io      ] = json3[:io      ]
    argh3[:surfaces] = json3[:surfaces]
    expect(TBD.status).to eq(0)
    expect(TBD.logs.empty?).to be(true)
    expect(argh3[:io].nil?).to be(false)
    expect(argh3[:io].is_a?(Hash)).to be(true)
    expect(argh3[:io].empty?).to be(false)
    expect(argh3[:io].key?(:edges)).to be(true)
    expect(argh3[:io][:edges].size).to eq(300)
    expect(argh3[:surfaces].nil?).to be(false)
    expect(argh3[:surfaces].is_a?(Hash)).to be(true)
    expect(argh3[:surfaces].size).to eq(23)

    out3  = JSON.pretty_generate(argh3[:io])
    file3 = File.join(__dir__, "../json/tbd_warehouse14.out.json")
    File.open(file3, "w") { |f| f.puts out3 }

    # Nice. Both TBD JSON output files are identical!
    # "/../json/tbd_warehouse12.out.json" vs "/../json/tbd_warehouse14.out.json"
    expect(FileUtils.identical?(file1, file3)).to be(true)
  end

  it "can generate and access KIVA inputs (seb)" do
    TBD.clean!
    argh = {}
    translator = OpenStudio::OSVersion::VersionTranslator.new
    file = File.join(__dir__, "files/osms/in/seb.osm")
    path = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model.empty?).to be(false)
    model = model.get

    # For continuous insulation and/or finishings, OpenStudio/EnergyPlus/Kiva
    # offer 2x solutions :
    #
    #   1. Add standard - not massless - materials as new construction layers
    #   2. Add Kiva custom blocks
    #
    # ... sticking with Option #1. A few examples:

    # Generic 1-1/2" XPS insulation.
    xps_38mm = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    xps_38mm.setName("XPS_38mm")
    xps_38mm.setRoughness("Rough")
    xps_38mm.setThickness(0.0381)
    xps_38mm.setConductivity(0.029)
    xps_38mm.setDensity(28)
    xps_38mm.setSpecificHeat(1450)
    xps_38mm.setThermalAbsorptance(0.9)
    xps_38mm.setSolarAbsorptance(0.7)

    # 1. Current code-compliant slab-on-grade (perimeter) solution.
    kiva_slab_2020s = OpenStudio::Model::FoundationKiva.new(model)
    kiva_slab_2020s.setName("Kiva slab 2020s")
    kiva_slab_2020s.setInteriorHorizontalInsulationMaterial(xps_38mm)
    kiva_slab_2020s.setInteriorHorizontalInsulationWidth(1.2)
    kiva_slab_2020s.setInteriorVerticalInsulationMaterial(xps_38mm)
    kiva_slab_2020s.setInteriorVerticalInsulationDepth(0.138)

    # 2. Beyond-code slab-on-grade (continuous) insulation setup. Add 1-1/2"
    #    XPS insulation layer (under slab) to surface construction.
    kiva_slab_HP = OpenStudio::Model::FoundationKiva.new(model)
    kiva_slab_HP.setName("Kiva slab HP")

    # 3. Do the same for (full height) basements - no insulation under slab for
    #    vintages 1980s & 2020s. Add (full-height) layered insulation and/or
    #    finishing to basement wall construction.
    kiva_basement = OpenStudio::Model::FoundationKiva.new(model)
    kiva_basement.setName("Kiva basement")

    # 4. Beyond-code basement slab (perimeter) insulation setup. Add
    #    (full-height)layered insulation and/or finishing to basement wall
    #    construction.
    kiva_basement_HP = OpenStudio::Model::FoundationKiva.new(model)
    kiva_basement_HP.setName("Kiva basement HP")
    kiva_basement_HP.setInteriorHorizontalInsulationMaterial(xps_38mm)
    kiva_basement_HP.setInteriorHorizontalInsulationWidth(1.2)
    kiva_basement_HP.setInteriorVerticalInsulationMaterial(xps_38mm)
    kiva_basement_HP.setInteriorVerticalInsulationDepth(0.138)

    # Set "Foundation" as boundary condition of 1x slab-on-grade, and link it
    # to 1x Kiva Foundation object.
    oa1f = model.getSurfaceByName("Open area 1 Floor")
    expect(oa1f.empty?).to be(false)
    oa1f = oa1f.get
    expect(oa1f.setOutsideBoundaryCondition("Foundation")).to be(true)
    oa1f.setAdjacentFoundation(kiva_slab_2020s)
    construction = oa1f.construction
    expect(construction.empty?).to be(false)
    construction = construction.get
    expect(oa1f.setConstruction(construction)).to be(true)
    arg = "TotalExposedPerimeter"
    per = oa1f.createSurfacePropertyExposedFoundationPerimeter(arg, 12.59)
    expect(per.empty?).to be(false)

    file = File.join(__dir__, "files/osms/out/seb_KIVA.osm")
    model.save(file, true)

    # Re-open for testing.
    path = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model.empty?).to be(false)
    model = model.get

    oa1f = model.getSurfaceByName("Open area 1 Floor")
    expect(oa1f.empty?).to be(false)
    oa1f = oa1f.get
    expect(oa1f.outsideBoundaryCondition.downcase).to eq("foundation")
    foundation = oa1f.adjacentFoundation
    expect(foundation.empty?).to be(false)
    foundation = foundation.get

    oa15 = model.getSurfaceByName("Openarea 1 Wall 5")              # 3.89m wide
    expect(oa15.empty?).to be(false)
    oa15 = oa15.get
    construction = oa15.construction.get
    expect(oa15.setOutsideBoundaryCondition("Foundation")).to be(true)
    expect(oa15.setAdjacentFoundation(foundation)).to be(true)
    expect(oa15.setConstruction(construction)).to be(true)

    kfs = model.getFoundationKivas
    expect(kfs.empty?).to be(false)
    expect(kfs.size).to eq(4)
    settings = model.getFoundationKivaSettings
    expect(settings.soilConductivity).to be_within(0.01).of(1.73)

    argh[:option  ] = "poor (BETBG)"
    argh[:gen_kiva] = true
    json = TBD.process(model, argh)
    expect(json.is_a?(Hash)).to be(true)
    expect(json.key?(:io)).to be(true)
    expect(json.key?(:surfaces)).to be(true)
    io       = json[:io]
    surfaces = json[:surfaces]
    expect(TBD.status).to eq(0)
    expect(TBD.logs.empty?).to be(true)
    expect(io.nil?).to be(false)
    expect(io.is_a?(Hash)).to be(true)
    expect(io.empty?).to be(false)
    expect(surfaces.nil?).to be(false)
    expect(surfaces.is_a?(Hash)).to be(true)
    expect(surfaces.size).to eq(56)

    found_floor = false
    found_wall  = false

    surfaces.each do |id, surface|
      next unless surface.key?(:kiva)
      expect(id).to eq("Open area 1 Floor").or eq("Openarea 1 Wall 5")

      if id == "Open area 1 Floor"
        expect(surface[:kiva]).to eq(:basement)
        expect(surface.key?(:exposed)).to be (true)
        expect(surface[:exposed]).to be_within(0.01).of(8.70)     # 12.59 - 3.89
        found_floor = true
      else
        expect(surface[:kiva]).to eq("Open area 1 Floor")
        found_wall = true
      end
    end

    expect(found_floor).to be(true)
    expect(found_wall).to be(true)

    file = File.join(__dir__, "files/osms/out/seb_KIVA2.osm")
    model.save(file, true)
  end

  it "can generate and access KIVA inputs (midrise apts - variant)" do
    TBD.clean!
    argh = {}
    translator = OpenStudio::OSVersion::VersionTranslator.new
    file = File.join(__dir__, "files/osms/in/midrise_KIVA.osm")
    path = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model.empty?).to be(false)
    model = model.get

    argh[:option  ] = "poor (BETBG)"
    argh[:gen_kiva] = true
    json = TBD.process(model, argh)
    expect(json.is_a?(Hash)).to be(true)
    expect(json.key?(:io)).to be(true)
    expect(json.key?(:surfaces)).to be(true)
    io       = json[:io]
    surfaces = json[:surfaces]
    expect(TBD.status).to eq(0)
    expect(TBD.logs.empty?).to be(true)
    expect(io.nil?).to be(false)
    expect(io.is_a?(Hash)).to be(true)
    expect(io.empty?).to be(false)
    expect(surfaces.nil?).to be(false)
    expect(surfaces.is_a?(Hash)).to be(true)
    expect(surfaces.size).to eq(180)

    # Validate.
    surfaces.each do |id, surface|
      next unless surface.key?(:foundation)                    # ... only floors
      next unless surface.key?(:kiva)
      expect(surface[:kiva]).to eq(:slab)
      expect(surface.key?(:exposed)).to be(true)
      expect(id).to eq("g Floor C")
      expect(surface[:exposed]).to be_within(TOL).of(3.36)
      gFC = model.getSurfaceByName("g Floor C")
      expect(gFC.empty?).to be(false)
      gFC = gFC.get
      expect(gFC.outsideBoundaryCondition.downcase).to eq("foundation")
    end

    file = File.join(__dir__, "files/osms/out/midrise_KIVA2.osm")
    model.save(file, true)
  end

  it "can generate multiple KIVA exposed perimeters (midrise apts - variant)" do
    TBD.clean!
    argh = {}
    translator = OpenStudio::OSVersion::VersionTranslator.new
    file = File.join(__dir__, "files/osms/in/midrise_KIVA.osm")
    path = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model.empty?).to be(false)
    model = model.get

    # Reset all ground-facing floor surfaces as "foundations".
    model.getSurfaces.each do |s|
      next unless s.outsideBoundaryCondition.downcase == "ground"
      expect(s.construction.empty?).to be(false)
      construction = s.construction.get
      expect(s.setOutsideBoundaryCondition("Foundation")).to be(true)
      expect(s.setConstruction(construction)).to be(true)
    end

    argh[:option  ] = "poor (BETBG)"
    argh[:gen_kiva] = true
    json = TBD.process(model, argh)
    expect(json.is_a?(Hash)).to be(true)
    expect(json.key?(:io)).to be(true)
    expect(json.key?(:surfaces)).to be(true)
    io       = json[:io]
    surfaces = json[:surfaces]
    expect(TBD.status).to eq(0)
    expect(TBD.logs.empty?).to be(true)
    expect(io.nil?).to be(false)
    expect(io.is_a?(Hash)).to be(true)
    expect(io.empty?).to be(false)
    expect(surfaces.nil?).to be(false)
    expect(surfaces.is_a?(Hash)).to be(true)
    expect(surfaces.size).to eq(180)

    # Validate.
    surfaces.each do |id, surface|
      next unless surface.key?(:foundation)                        # only floors
      next unless surface.key?(:kiva)
      expect(surface[:kiva]).to eq(:slab)
      expect(surface.key?(:exposed)).to be(true)
      exp = surface[:exposed]
      found = false

      model.getSurfaces.each do |s|
        next unless s.nameString == id
        next unless s.outsideBoundaryCondition.downcase == "foundation"
        found = true

        expect(exp).to be_within(0.01).of(19.20) if id == "g GFloor NWA"
        expect(exp).to be_within(0.01).of(19.20) if id == "g GFloor NEA"
        expect(exp).to be_within(0.01).of(19.20) if id == "g GFloor SWA"
        expect(exp).to be_within(0.01).of(19.20) if id == "g GFloor SEA"
        expect(exp).to be_within(0.01).of(11.58) if id == "g GFloor S1A"
        expect(exp).to be_within(0.01).of(11.58) if id == "g GFloor S2A"
        expect(exp).to be_within(0.01).of(11.58) if id == "g GFloor N1A"
        expect(exp).to be_within(0.01).of(11.58) if id == "g GFloor N2A"
        expect(exp).to be_within(0.01).of( 3.36) if id == "g Floor C"
      end

      expect(found).to be(true)
    end

    file = File.join(__dir__, "files/osms/out/midrise_KIVA3.osm")
    model.save(file, true)
  end

  it "can generate KIVA exposed perimeters (warehouse)" do
    TBD.clean!
    argh = {}
    translator = OpenStudio::OSVersion::VersionTranslator.new
    file = File.join(__dir__, "files/osms/in/warehouse.osm")
    path = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model.empty?).to be(false)
    model = model.get

    fl1 = "Fine Storage Floor"
    fl2 = "Office Floor"
    fl3 = "Bulk Storage Floor"

    # Reset all ground-facing floor surfaces as "foundations".
    model.getSurfaces.each do |s|
      next unless s.outsideBoundaryCondition.downcase == "ground"
      expect(s.construction.empty?).to be(false)
      construction = s.construction.get
      expect(s.setOutsideBoundaryCondition("Foundation")).to be(true)
      expect(s.setConstruction(construction)).to be(true)
    end

    argh[:option  ] = "(non thermal bridging)"
    argh[:gen_kiva] = true
    json = TBD.process(model, argh)
    expect(json.is_a?(Hash)).to be(true)
    expect(json.key?(:io)).to be(true)
    expect(json.key?(:surfaces)).to be(true)
    io       = json[:io]
    surfaces = json[:surfaces]
    expect(TBD.status).to eq(0)
    expect(TBD.logs.empty?).to be(true)
    expect(io.nil?).to be(false)
    expect(io.is_a?(Hash)).to be(true)
    expect(io.empty?).to be(false)
    expect(surfaces.nil?).to be(false)
    expect(surfaces.is_a?(Hash)).to be(true)
    expect(surfaces.size).to eq(23)

    # Validate.
    surfaces.each do |id, surface|
      next unless surface.key?(:foundation)                        # only floors
      next unless surface.key?(:kiva)
      expect(surface[:kiva]).to eq(:slab)
      expect(surface.key?(:exposed)).to be(true)
      exp = surface[:exposed]
      found = false

      model.getSurfaces.each do |s|
        next unless s.nameString == id
        next unless s.outsideBoundaryCondition.downcase == "foundation"
        found = true

        expect(exp).to be_within(0.01).of( 71.62) if id == "fl1"
        expect(exp).to be_within(0.01).of( 35.05) if id == "fl2"
        expect(exp).to be_within(0.01).of(185.92) if id == "fl3"
      end

      expect(found).to be(true)
    end

    pth = File.join(__dir__, "files/osms/out/warehouse_KIVA.osm")
    model.save(pth, true)

    # Now re-open for testing.
    path = OpenStudio::Path.new(pth)
    model = translator.loadModel(path)
    expect(model.empty?).to be(false)
    model = model.get

    model.getSurfaces.each do |s|
      next unless s.isGroundSurface
      expect(s.nameString).to eq(fl1).or eq(fl2).or eq(fl3)
      expect(s.outsideBoundaryCondition).to eq("Foundation")
    end

    kfs = model.getFoundationKivas
    expect(kfs.empty?).to be(false)
    expect(kfs.size).to eq(3)
  end

  it "can invalidate KIVA inputs (smalloffice)" do
    TBD.clean!
    argh = {}
    translator = OpenStudio::OSVersion::VersionTranslator.new
    file = File.join(__dir__, "files/osms/in/smalloffice.osm")
    path = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model.empty?).to be(false)
    model = model.get

    # Reset all ground-facing floor surfaces as "foundations".
    model.getSurfaces.each do |s|
      next unless s.outsideBoundaryCondition.downcase == "ground"
      expect(s.construction.empty?).to be(false)
      construction = s.construction.get
      expect(s.setOutsideBoundaryCondition("Foundation")).to be(true)
      expect(s.setConstruction(construction)).to be(true)
    end

    argh[:option  ] = "poor (BETBG)"
    argh[:gen_kiva] = true
    json = TBD.process(model, argh)
    expect(json.is_a?(Hash)).to be(true)
    expect(json.key?(:io)).to be(true)
    expect(json.key?(:surfaces)).to be(true)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.status).to eq(ERR)
    expect(TBD.logs.size).to eq(5)

    TBD.logs.each do |log|
      expect(log[:message].include?("KIVA requires standard mat")).to be(true)
    end

    expect(io.nil?).to be(false)
    expect(io.is_a?(Hash)).to be(true)
    expect(io.empty?).to be(false)
    expect(surfaces.nil?).to be(false)
    expect(surfaces.is_a?(Hash)).to be(true)
    expect(surfaces.size).to eq(43)

    surfaces.values.each { |s| expect(s.key?(:kiva)).to be(false) }

    file = File.join(__dir__, "files/osms/out/smalloffice_kiva.osm")
    model.save(file, true)
  end

  it "can compute uFactor for ceilings, walls, and floors" do
    os_model = OpenStudio::Model::Model.new
    space = OpenStudio::Model::Space.new(os_model)

    material = OpenStudio::Model::MasslessOpaqueMaterial.new(os_model)
    material.setRoughness("Smooth")
    material.setThermalResistance(4.0)
    material.setThermalAbsorptance(0.9)
    material.setSolarAbsorptance(0.7)
    material.setVisibleAbsorptance(0.7)

    layers = OpenStudio::Model::MaterialVector.new
    layers << material
    construction = OpenStudio::Model::Construction.new(os_model)
    construction.setLayers(layers)
    expect(construction.thermalConductance.empty?).to be(false)
    expect(construction.thermalConductance.get).to be_within(0.001).of(0.25)
    expect(construction.uFactor(0).empty?).to be(false)
    expect(construction.uFactor(0).get).to be_within(0.001).of(0.25)

    vertices = OpenStudio::Point3dVector.new
    vertices << OpenStudio::Point3d.new( 10, 10, 5)
    vertices << OpenStudio::Point3d.new( 0, 10, 5)
    vertices << OpenStudio::Point3d.new( 0, 0, 5)
    vertices << OpenStudio::Point3d.new( 10, 0, 5)
    ceiling = OpenStudio::Model::Surface.new(vertices, os_model)
    ceiling.setSpace(space)
    ceiling.setConstruction(construction)
    expect(ceiling.surfaceType.downcase).to eq("roofceiling")
    expect(ceiling.outsideBoundaryCondition.downcase).to eq("outdoors")
    expect(ceiling.filmResistance).to be_within(0.001).of(0.136)
    expect(ceiling.uFactor.empty?).to be(false)
    expect(ceiling.uFactor.get).to be_within(0.001).of(0.242)

    vertices = OpenStudio::Point3dVector.new
    vertices << OpenStudio::Point3d.new( 0, 10, 5)
    vertices << OpenStudio::Point3d.new( 0, 10, 0)
    vertices << OpenStudio::Point3d.new( 0, 0, 0)
    vertices << OpenStudio::Point3d.new( 0, 0, 5)
    wall = OpenStudio::Model::Surface.new(vertices, os_model)
    wall.setSpace(space)
    wall.setConstruction(construction)
    expect(wall.surfaceType.downcase).to eq("wall")
    expect(wall.outsideBoundaryCondition.downcase).to eq("outdoors")
    expect(wall.tilt).to be_within(0.001).of(Math::PI/2.0)
    expect(wall.filmResistance).to be_within(0.001).of(0.150)
    expect(wall.uFactor.empty?).to be(false)
    expect(wall.uFactor.get).to be_within(0.001).of(0.241)

    vertices = OpenStudio::Point3dVector.new
    vertices << OpenStudio::Point3d.new( 0, 10, 0)
    vertices << OpenStudio::Point3d.new( 10, 10, 0)
    vertices << OpenStudio::Point3d.new( 10, 0, 0)
    vertices << OpenStudio::Point3d.new( 0, 0, 0)
    floor = OpenStudio::Model::Surface.new(vertices, os_model)
    floor.setSpace(space)
    floor.setConstruction(construction)
    expect(floor.surfaceType.downcase).to eq("floor")
    expect(floor.outsideBoundaryCondition.downcase).to eq("ground")
    expect(floor.tilt).to be_within(0.001).of(Math::PI)
    expect(floor.filmResistance).to be_within(0.001).of(0.160)
    expect(floor.uFactor.empty?).to be(false)
    expect(floor.uFactor.get).to be_within(0.001).of(0.241)

    # make outdoors (like a soffit)
    expect(floor.setOutsideBoundaryCondition("Outdoors")).to be(true)
    expect(floor.filmResistance).to be_within(0.001).of(0.190)
    expect(floor.uFactor.empty?).to be(false)
    expect(floor.uFactor.get).to be_within(0.001).of(0.239)

    # now make these surfaces not outdoors
    expect(ceiling.setOutsideBoundaryCondition("Adiabatic")).to be(true)
    expect(ceiling.filmResistance).to be_within(0.001).of(0.212)
    expect(ceiling.uFactor.empty?).to be(false)
    expect(ceiling.uFactor.get).to be_within(0.001).of(0.237)

    expect(wall.setOutsideBoundaryCondition("Adiabatic")).to be(true)
    expect(wall.filmResistance).to be_within(0.001).of(0.239)
    expect(wall.uFactor.empty?).to be(false)
    expect(wall.uFactor.get).to be_within(0.001).of(0.236)

    expect(floor.setOutsideBoundaryCondition("Adiabatic")).to be(true)
    expect(floor.filmResistance).to be_within(0.001).of(0.321)
    expect(floor.uFactor.empty?).to be(false)
    expect(floor.uFactor.get).to be_within(0.001).of(0.231)

    # doubling number of layers. Good.
    layers = OpenStudio::Model::MaterialVector.new
    layers << material
    layers << material
    construction = OpenStudio::Model::Construction.new(os_model)
    construction.setLayers(layers)
    expect(construction.thermalConductance.empty?).to be(false)
    expect(construction.thermalConductance.get).to be_within(0.001).of(0.125)
    expect(construction.uFactor(0).empty?).to be(false)
    expect(construction.uFactor(0).get).to be_within(0.001).of(0.125)

    # All good.
    floor.setConstruction(construction)
    expect(floor.setOutsideBoundaryCondition("Outdoors")).to be(true)
    expect(floor.filmResistance).to be_within(0.001).of(0.190)
    expect(floor.thermalConductance.empty?).to be(false)
    expect(floor.thermalConductance.get).to be_within(0.001).of(0.125)
    expect(floor.uFactor.empty?).to be(false)
    expect(floor.uFactor.get).to be_within(0.001).of(0.122)

    # Constructions/materials generated from DOE Prototype (Small Office).
    # Material,
    # 5/8 in. Gypsum Board,                   !- Name
    # MediumSmooth,                           !- Roughness
    # 0.0159,                                 !- Thickness {m}
    # 0.159999999999999,                      !- Conductivity {W/m-K}
    # 799.999999999999,                       !- Density {kg/m3}
    # 1090,                                   !- Specific Heat {J/kg-K}
    # 0.9,                                    !- Thermal Absorptance
    # 0.7,                                    !- Solar Absorptance
    # 0.7;                                    !- Visible Absorptance

    # OS:Material,
    # {7462f6dd-da46-4439-8dbe-ca9fd849f87b}, !- Handle
    # 5/8 in. Gypsum Board,                   !- Name
    # MediumSmooth,                           !- Roughness
    # 0.0159,                                 !- Thickness {m}
    # 0.159999999999999,                      !- Conductivity {W/m-K}
    # 799.999999999999,                       !- Density {kg/m3}
    # 1090,                                   !- Specific Heat {J/kg-K}
    # 0.9,                                    !- Thermal Absorptance
    # 0.7,                                    !- Solar Absorptance
    # 0.7;                                    !- Visible Absorptance
    gypsum = OpenStudio::Model::MasslessOpaqueMaterial.new(os_model)
    gypsum.setRoughness("MediumSmooth")
    gypsum.setThermalConductivity(0.16)
    gypsum.setThickness(0.0159)
    gypsum.setThermalAbsorptance(0.9)
    gypsum.setSolarAbsorptance(0.7)
    gypsum.setVisibleAbsorptance(0.7)

    # Material:NoMass,
    # Typical Insulation R-35.4 1,            !- Name
    # Smooth,                                 !- Roughness
    # 6.23478649910089,                       !- Thermal Resistance {m2-K/W}
    # 0.9,                                    !- Thermal Absorptance
    # 0.7,                                    !- Solar Absorptance
    # 0.7;                                    !- Visible Absorptance
    #
    # Material:NoMass, (once derated)
    # Attic_roof_east Typical Insulation R-35.4 2 tbd, !- Name
    # Smooth,                                 !- Roughness
    # 4.20893587096259,                       !- Thermal Resistance {m2-K/W}
    # 0.9,                                    !- Thermal Absorptance
    # 0.7,                                    !- Solar Absorptance
    # 0.7;                                    !- Visible Absorptance
    #
    # OS:Material:NoMass,
    # {730da72e-2cdb-42f1-91aa-44ebaf6b683b}, !- Handle
    # Attic_roof_east Typical Insulation R-35.4 2 tbd, !- Name
    # Smooth,                                 !- Roughness
    # 4.20893587096259,                       !- Thermal Resistance {m2-K/W} **
    # 0.9,                                    !- Thermal Absorptance
    # 0.7,                                    !- Solar Absorptance
    # 0.7;                                    !- Visible Absorptance

    # ** derated, initially ~6.24?
    ratedR35 = OpenStudio::Model::MasslessOpaqueMaterial.new(os_model)
    ratedR35.setRoughness("Smooth")
    ratedR35.setThermalResistance(6.24)
    ratedR35.setThermalAbsorptance(0.9)
    ratedR35.setSolarAbsorptance(0.7)
    ratedR35.setVisibleAbsorptance(0.7)

    deratedR35 = OpenStudio::Model::MasslessOpaqueMaterial.new(os_model)
    deratedR35.setRoughness("Smooth")
    deratedR35.setThermalResistance(4.21)
    deratedR35.setThermalAbsorptance(0.9)
    deratedR35.setSolarAbsorptance(0.7)
    deratedR35.setVisibleAbsorptance(0.7)

    # OS:Material,
    # {cce5c80d-e6fa-4569-9c4f-7b66f0700c6d}, !- Handle
    # 25mm Stucco,                            !- Name
    # Smooth,                                 !- Roughness
    # 0.0254,                                 !- Thickness {m}
    # 0.719999999999999,                      !- Conductivity {W/m-K}
    # 1855.99999999999,                       !- Density {kg/m3}
    # 839.999999999997,                       !- Specific Heat {J/kg-K}
    # 0.9,                                    !- Thermal Absorptance
    # 0.7,                                    !- Solar Absorptance
    # 0.7;                                    !- Visible Absorptance
    stucco = OpenStudio::Model::StandardOpaqueMaterial.new(os_model)
    stucco.setRoughness("Smooth")
    stucco.setThermalConductivity(0.72)
    stucco.setThickness(0.0254)
    stucco.setDensity(1856.0)
    stucco.setSpecificHeat(840.0)
    stucco.setThermalAbsorptance(0.9)
    stucco.setSolarAbsorptance(0.7)
    stucco.setVisibleAbsorptance(0.7)
    stucco.setName("25mm Stucco") # RSi = 0.0353

    # Material:NoMass,
    # Typical Insulation R-9.06,              !- Name
    # Smooth,                                 !- Roughness
    # 1.59504467488221,                       !- Thermal Resistance {m2-K/W}
    # 0.9,                                    !- Thermal Absorptance
    # 0.7,                                    !- Solar Absorptance
    # 0.7;                                    !- Visible Absorptance
    #
    # OS:Material:NoMass,
    # {5621c538-653b-4356-b037-e3d3feff7ac1}, !- Handle
    # Perimeter_ZN_1_wall_south Typical Insulation R-9.06 1 tbd, !- Name
    # Smooth,                                 !- Roughness
    # 0.594690149255382,                      !- Thermal Resistance {m2-K/W} **
    # 0.9,                                    !- Thermal Absorptance
    # 0.7,                                    !- Solar Absorptance
    # 0.7;                                    !- Visible Absorptance

    # ** derated, initially ~1.60?
    ratedR9 = OpenStudio::Model::MasslessOpaqueMaterial.new(os_model)
    ratedR9.setRoughness("Smooth")
    ratedR9.setThermalResistance(1.60)
    ratedR9.setThermalAbsorptance(0.9)
    ratedR9.setSolarAbsorptance(0.7)
    ratedR9.setVisibleAbsorptance(0.7)

    deratedR9 = OpenStudio::Model::MasslessOpaqueMaterial.new(os_model)
    deratedR9.setRoughness("Smooth")
    deratedR9.setThermalResistance(0.59)
    deratedR9.setThermalAbsorptance(0.9)
    deratedR9.setSolarAbsorptance(0.7)
    deratedR9.setVisibleAbsorptance(0.7)

    # FLOOR        air film resistance = 0.190 (USi = 5.4)
    # WALL         air film resistance = 0.150 (USi = 6.7)
    # ROOFCEILING  air film resistance = 0.136 (USi = 7.4)
    #
    # Construction,
    # Typical Wood Joist Attic Floor R-37.04 1, !- Name
    # 5/8 in. Gypsum Board,                   !- Layer 1
    # Typical Insulation R-35.4 1;            !- Layer 2
    #
    # OS:Construction,
    # {909c4492-fe3b-4850-9468-150aa692b15b}, !- Handle
    # Attic_roof_east Typical Wood Joist Attic Floor R-37.04 tbd, !- Name
    # ,                                       !- Surface Rendering Name
    # {7462f6dd-da46-4439-8dbe-ca9fd849f87b}, !- Layer 1 (Gypsum)
    # {730da72e-2cdb-42f1-91aa-44ebaf6b683b}; !- Layer 2 (R35 insulation)
    layers = OpenStudio::Model::MaterialVector.new
    layers << gypsum                          # RSi = 0.099375
    layers << ratedR35                        # Rsi = 6.24
                                              #     = 6.34    TOTAL (w/o films)
                                              #     = 6.54    TOTAL if floor
                                              #     = 6.50    TOTAL if wall
                                              #     = 6.44    TOTAL if roof
    rated_attic = OpenStudio::Model::Construction.new(os_model)
    rated_attic.setLayers(layers)
    expect(rated_attic.thermalConductance.get).to be_within(0.01).of(0.158)

    layers = OpenStudio::Model::MaterialVector.new
    layers << gypsum                          # RSi = 0.099375
    layers << deratedR35                      # Rsi = 4.21
                                              #     = 4.31    TOTAL (w/o films)
                                              #     = 4.55    TOTAL if floor
                                              #     = 4.46    TOTAL if wall
                                              #     = 4.45    TOTAL if roof
    derated_attic = OpenStudio::Model::Construction.new(os_model)
    derated_attic.setLayers(layers)
    expect(derated_attic.thermalConductance.get).to be_within(0.01).of(0.232)

    # OS:Construction,
    # {f234620a-99ac-491d-9979-2b49bdb02f43}, !- Handle
    # Perimeter_ZN_1_wall_south Typical Insulated ... ... R-11.24 tbd, !- Name
    # ,                                       !- Surface Rendering Name
    # {cce5c80d-e6fa-4569-9c4f-7b66f0700c6d}, !- Layer 1 (Stucco)
    # {7462f6dd-da46-4439-8dbe-ca9fd849f87b}, !- Layer 2 (Gypsum)
    # {5621c538-653b-4356-b037-e3d3feff7ac1}, !- Layer 3 (R9 insulation)
    # {7462f6dd-da46-4439-8dbe-ca9fd849f87b}; !- Layer 4 (Gypsum)
    layers = OpenStudio::Model::MaterialVector.new
    layers << stucco                          # RSi = 0.0353
    layers << gypsum                          # RSi = 0.099375
    layers << ratedR9                         # Rsi = 1.6
    layers << gypsum                          # RSi = 0.099375
                                              #     = 1.83    TOTAL (w/o films)
                                              #     = 2.065   TOTAL if floor
                                              #     = 1.98    TOTAL if wall
                                              #     = 1.43    TOTAL if roof
    rated_perimeter = OpenStudio::Model::Construction.new(os_model)
    rated_perimeter.setLayers(layers)
    expect(rated_perimeter.thermalConductance.get).to be_within(0.01).of(0.546)

    layers = OpenStudio::Model::MaterialVector.new
    layers << stucco                          # RSi = 0.0353
    layers << gypsum                          # RSi = 0.099375
    layers << deratedR9                       # RSi = 0.59
    layers << gypsum                          # RSi = 0.099375
                                              #     = 0.824    TOTAL (w/o films)
                                              #     = 1.059    TOTAL if floor
                                              #     = 0.974    TOTAL if wall
                                              #     = 0.960    TOTAL if roof
    derated_perimeter = OpenStudio::Model::Construction.new(os_model)
    derated_perimeter.setLayers(layers)
    expect(derated_perimeter.thermalConductance.get).to be_within(0.01).of(1.214)

    floor.setOutsideBoundaryCondition("Outdoors")
    floor.setConstruction(rated_attic)
    rated_attic_RSi = 1.0 / floor.uFactor.to_f
    expect(rated_attic_RSi).to be_within(0.01).of(6.53)
    # puts "... rated attic thermal conductance:#{floor.thermalConductance}"
    # puts "... rated attic uFactor:#{floor.uFactor}"
    #     = 6.34    TOTAL (w/o films)         , USi = 0.158
    #     = 6.54    TOTAL if floor            , USi = 0.153
    #     = 6.50    TOTAL if wall             , USi = 0.154
    #     = 6.44    TOTAL if roof             , USi = 0.156

    floor.setConstruction(derated_attic)
    derated_attic_RSi = 1.0 / floor.uFactor.to_f
    expect(derated_attic_RSi).to be_within(0.01).of(4.50)
    # puts "... derated attic thermal conductance:#{floor.thermalConductance}"
    # puts "... derated attic uFactor:#{floor.uFactor}"
    #     = 4.31    TOTAL (w/o films)         , USi = 0.232
    #     = 4.55    TOTAL if floor            , USi = 0.220
    #     = 4.46    TOTAL if wall             , USi = 0.224
    #     = 4.45    TOTAL if roof             , USi = 0.225

    floor.setConstruction(rated_perimeter)
    rated_perimeter_RSi = 1.0 / floor.uFactor.to_f
    expect(rated_perimeter_RSi).to be_within(0.01).of(2.03)
    # puts "... rated perimeter thermal conductance:#{floor.thermalConductance}"
    # puts "... rated Perimeter uFactor:#{floor.uFactor}"
    #     = 1.83    TOTAL (w/o films)         , USi = 0.546
    #     = 2.065   TOTAL if floor            , USi = 0.484
    #     = 1.98    TOTAL if wall             , USi = 0.505
    #     = 1.43    TOTAL if roof             , USi = 0.699

    floor.setConstruction(derated_perimeter)
    derated_perimeter_RSi = 1.0 / floor.uFactor.to_f
    expect(derated_perimeter_RSi).to be_within(0.01).of(1.016)
    #puts "... derated perimeter thermal conductance:#{floor.thermalConductance}"
    #puts "... derated perimeter uFactor:#{floor.uFactor}"
    #     = 0.824    TOTAL (w/ofilms)          , USi = 1.214
    #     = 1.059    TOTAL if floor            , USi = 0.944
    #     = 0.974    TOTAL if wall             , USi = 1.027
    #     = 0.960    TOTAL if roof             , USi = 1.042
  end

  it "can test invalid surface geometries" do
    # OpenStudio models can hold a number of inaccuracies, e.g. 4-sided surface
    # where 1 vertex does not fall along the same 3D plane as the 3 others. It
    # happens. Very often OpenStudio/EnergyPlus (and many OpenStudio/Energy
    # measures) have adequate tolerances (or automated corrections) to
    # accommodate such faults, whether originally stemming from negligence or as
    # automatically-generated artefacts (from 3rd-party BIM/BEM packages). The
    # tests below demonstrate how TBD may (better) catch specific surface
    # anomalies that may invalidate TBD processes (while informing users),
    # instead of allowing Ruby crashes (quite uninformative). These tests are
    # likely to evolve over time, as they are reactions to user bug reports.
    # These tests will likely make their way to the TBD Tests repo.

    # --- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- --- #
    #
    # Catching slivers: TBD currently relies on a hardcoded, minimum 10mm
    # tolerance for edge lengths. One could argue anything under 100mm should be
    # redflagged. In any case, TBD should catch such surface slivers.
    TBD.clean!
    argh = {}

    translator = OpenStudio::OSVersion::VersionTranslator.new
    file = File.join(__dir__, "files/osms/in/smalloffice.osm")
    path = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model.empty?).to be(false)
    model = model.get

    original = model.getSurfaceByName("Perimeter_ZN_1_wall_south")
    expect(original.empty?).to be(false)
    original = original.get

    # puts original
    # OS:Surface,
    #   {67ca62ce-e572-4957-8e6a-efb74825f170}, !- Handle
    #   Perimeter_ZN_1_wall_south,              !- Name
    #   Wall,                                   !- Surface Type
    #   {1296f169-6fa2-4db3-a598-be70282232ee}, !- Construction Name
    #   {72459874-7e2c-4ecd-ae58-b2d96c368b31}, !- Space Name
    #   Outdoors,                               !- Outside Boundary Condition
    #   ,                                       !- Outside Boundary Condition Object
    #   SunExposed,                             !- Sun Exposure
    #   WindExposed,                            !- Wind Exposure
    #   ,                                       !- View Factor to Ground
    #   ,                                       !- Number of Vertices
    #   0, 0, 3.05,                             !- X,Y,Z Vertex 1 {m}
    #   0, 0, 0,                                !- X,Y,Z Vertex 2 {m}
    #   27.69, 0, 0,                            !- X,Y,Z Vertex 3 {m}
    #   27.69, 0, 3.05;                         !- X,Y,Z Vertex 4 {m}

    # Trim down original wall height by 10mm.
    vec = OpenStudio::Point3dVector.new
    vec << OpenStudio::Point3d.new( 0.00, 0.00, 3.040) # ... not 3.05
    vec << OpenStudio::Point3d.new( 0.00, 0.00, 0.000)
    vec << OpenStudio::Point3d.new(27.69, 0.00, 0.000)
    vec << OpenStudio::Point3d.new(27.69, 0.00, 3.040) # ... not 3.05
    expect(original.setVertices(vec)).to be(true)

    # puts original
    # OS:Surface,
    #   {67ca62ce-e572-4957-8e6a-efb74825f170}, !- Handle
    #   Perimeter_ZN_1_wall_south,              !- Name
    #   Wall,                                   !- Surface Type
    #   {1296f169-6fa2-4db3-a598-be70282232ee}, !- Construction Name
    #   {72459874-7e2c-4ecd-ae58-b2d96c368b31}, !- Space Name
    #   Outdoors,                               !- Outside Boundary Condition
    #   ,                                       !- Outside Boundary Condition Object
    #   SunExposed,                             !- Sun Exposure
    #   WindExposed,                            !- Wind Exposure
    #   ,                                       !- View Factor to Ground
    #   ,                                       !- Number of Vertices
    #   0, 0, 3.04,                             !- X,Y,Z Vertex 1 {m}
    #   0, 0, 0,                                !- X,Y,Z Vertex 2 {m}
    #   27.69, 0, 0,                            !- X,Y,Z Vertex 3 {m}
    #   27.69, 0, 3.04;                         !- X,Y,Z Vertex 4 {m}

    # Add new "sliver" to enclose space volume
    space = original.space
    expect(space.empty?).to be(false)
    space = space.get

    vec = OpenStudio::Point3dVector.new
    vec << OpenStudio::Point3d.new( 0.00, 0.00, 3.050)
    vec << OpenStudio::Point3d.new( 0.00, 0.00, 3.040)
    vec << OpenStudio::Point3d.new(27.69, 0.00, 3.040)
    vec << OpenStudio::Point3d.new(27.69, 0.00, 3.050)
    sliver = OpenStudio::Model::Surface.new(vec, model)
    sliver.setName("SLIVER")
    expect(sliver.setSpace(space)).to be(true)
    expect(sliver.setVertices(vec)).to be(true)

    # puts sliver
    # OS:Surface,
    #   {94b771e3-674b-41d5-bee4-2088638a791a}, !- Handle
    #   SLIVER,                                 !- Name
    #   Wall,                                   !- Surface Type
    #   ,                                       !- Construction Name
    #   {72459874-7e2c-4ecd-ae58-b2d96c368b31}, !- Space Name
    #   Outdoors,                               !- Outside Boundary Condition
    #   ,                                       !- Outside Boundary Condition Object
    #   SunExposed,                             !- Sun Exposure
    #   WindExposed,                            !- Wind Exposure
    #   ,                                       !- View Factor to Ground
    #   ,                                       !- Number of Vertices
    #   0, 0, 3.05,                             !- X,Y,Z Vertex 1 {m}
    #   0, 0, 3.04,                             !- X,Y,Z Vertex 2 {m}
    #   27.69, 0, 3.04,                         !- X,Y,Z Vertex 3 {m}
    #   27.69, 0, 3.05;                         !- X,Y,Z Vertex 4 {m}

    # Calling TBD's 'validate' method in isolation.
    expect(TBD.validate(sliver)).to be(false)
    expect(TBD.status).to eq(ERR)
    expect(TBD.logs.empty?).to be(false)
    expect(TBD.logs.size).to eq(1)
    message = TBD.logs.first[:message]
    expect(message.include?("< 0.01m (TBD::validate)")).to be(true)
    TBD.clean!

    expect(TBD.validate(original)).to be(true)
    expect(TBD.status.zero?).to be(true)
    expect(TBD.logs.empty?).to be(true)
    TBD.clean!

    argh[:option] = "(non thermal bridging)"
    json = TBD.process(model, argh)
    expect(json.is_a?(Hash)).to be(true)
    expect(json.key?(:io)).to be(true)
    expect(json.key?(:surfaces)).to be(true)
    io       = json[:io]
    surfaces = json[:surfaces]
    expect(TBD.status).to eq(ERR)
    expect(TBD.logs.empty?).to be(false)
    expect(TBD.logs.size).to eq(1)
    message = TBD.logs.first[:message]
    expect(message.include?("< 0.01m (TBD::validate)")).to be(true)
    expect(io.nil?).to be(false)
    expect(io.is_a?(Hash)).to be(true)
    expect(io.empty?).to be(false)
    expect(surfaces.nil?).to be(false)
    expect(surfaces.is_a?(Hash)).to be(true)
    expect(surfaces.size).to eq(43)

    # Repeat exercice for subsurface as sliver.
    TBD.clean!
    argh = {}

    file = File.join(__dir__, "files/osms/in/smalloffice.osm")
    path = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model.empty?).to be(false)
    model = model.get

    door = model.getSubSurfaceByName("Perimeter_ZN_1_wall_south_door")
    expect(door.empty?).to be(false)
    door = door.get

    # puts door
    # OS:SubSurface,
    #   {53588f1b-5734-4f40-b8d3-73d92c10e021}, !- Handle
    #   Perimeter_ZN_1_wall_south_door,         !- Name
    #   GlassDoor,                              !- Sub Surface Type
    #   ,                                       !- Construction Name
    #   {67ca62ce-e572-4957-8e6a-efb74825f170}, !- Surface Name
    #   ,                                       !- Outside Boundary Condition Object
    #   ,                                       !- View Factor to Ground
    #   ,                                       !- Frame and Divider Name
    #   1,                                      !- Multiplier
    #   ,                                       !- Number of Vertices
    #   12.93, 0, 2.134,                        !- X,Y,Z Vertex 1 {m}
    #   12.93, 0, 0,                            !- X,Y,Z Vertex 2 {m}
    #   14.76, 0, 0,                            !- X,Y,Z Vertex 3 {m}
    #   14.76, 0, 2.134;                        !- X,Y,Z Vertex 4 {m}

    # Trim down door width to 10mm.
    vec = OpenStudio::Point3dVector.new
    vec << OpenStudio::Point3d.new(14.750, 0.000, 2.134) # ... not 12.93
    vec << OpenStudio::Point3d.new(14.750, 0.000, 0.000) # ... not 12.93
    vec << OpenStudio::Point3d.new(14.760, 0.000, 0.000)
    vec << OpenStudio::Point3d.new(14.760, 0.000, 2.134)
    expect(door.setVertices(vec)).to be(true)

    # puts door
    # OS:SubSurface,
    #   {53588f1b-5734-4f40-b8d3-73d92c10e021}, !- Handle
    #   Perimeter_ZN_1_wall_south_door,         !- Name
    #   GlassDoor,                              !- Sub Surface Type
    #   ,                                       !- Construction Name
    #   {67ca62ce-e572-4957-8e6a-efb74825f170}, !- Surface Name
    #   ,                                       !- Outside Boundary Condition Object
    #   ,                                       !- View Factor to Ground
    #   ,                                       !- Frame and Divider Name
    #   1,                                      !- Multiplier
    #   ,                                       !- Number of Vertices
    #   14.66, 0, 2.134,                        !- X,Y,Z Vertex 1 {m}
    #   14.66, 0, 0,                            !- X,Y,Z Vertex 2 {m}
    #   14.76, 0, 0,                            !- X,Y,Z Vertex 3 {m}
    #   14.76, 0, 2.134;                        !- X,Y,Z Vertex 4 {m}

    expect(TBD.validate(door)).to be(false)
    expect(TBD.status).to eq(ERR)
    expect(TBD.logs.empty?).to be(false)
    expect(TBD.logs.size).to eq(1)
    message = TBD.logs.first[:message]
    expect(message.include?("< 0.01m (TBD::validate)")).to be(true)
    TBD.clean!
  end

  it "checks for Frame & Divider reveals" do
    # To define an outside reveal (e.g. 100mm offset of a window from the brick
    # cladding of its base/parent/host wall), EnergyPlus subsurface vertices
    # must be offset, by e.g. 100mm, from the host surface. However, OpenStudio
    # allows users to maintain co-planar surface definitions (e.g. window and
    # wall vertices along same 3D plane), and automates e.g. a 100mm .idf offset
    # via Frame & Divider reveal options. As such, TBD/Topolys can safely
    # process the OpenStudio subsurface vertices to identify head, sill and jamb
    # thermal bridges. There are no changes brought to TBD source code - this
    # test simply validates that with/without Frame & Divider reveals, TBD is
    # able to process OpenStudio models indifferently.
    TBD.clean!
    argh = {}
    translator = OpenStudio::OSVersion::VersionTranslator.new
    file = File.join(__dir__, "files/osms/in/smalloffice.osm")
    path = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model.empty?).to be(false)
    model = model.get

    # 1. Run with an unaltered model.
    argh[:option     ] = "code (Quebec)"
    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")

    json = TBD.process(model, argh)
    expect(json.is_a?(Hash)).to be(true)
    expect(json.key?(:io      )).to be(true)
    expect(json.key?(:surfaces)).to be(true)

    io       = json[:io      ]
    surfaces = json[:surfaces]

    expect(TBD.status).to eq(0)
    expect(TBD.logs.empty?).to be(true)
    expect(io.nil?).to be(false)
    expect(io.is_a?(Hash)).to be(true)
    expect(io.empty?).to be(false)
    expect(surfaces.nil?).to be(false)
    expect(surfaces.is_a?(Hash)).to be(true)
    expect(surfaces.size).to eq(43)

    expect(surfaces.key?("Perimeter_ZN_1_wall_south")).to be(true)
    surface = surfaces["Perimeter_ZN_1_wall_south"]
    expect(surface.key?(:ratio   )).to be(true)
    expect(surface.key?(:heatloss)).to be(true)
    expect(surface[:ratio   ]).to be_within(TOL).of(-10.88)
    expect(surface[:heatloss]).to be_within(TOL).of( 23.40)

    # Mimic the export functionality of the measure and save .osm file.
    out1 = JSON.pretty_generate(io)
    file1 = File.join(__dir__, "../json/tbd_smalloffice3.out.json")
    File.open(file1, "w") { |f| f.puts out1 }
    pth = File.join(__dir__, "files/osms/out/model_FD.osm")
    model.save(pth, true)

    # 2. Repeat, yet add Frame & Divider with outside reveal to 1x window.
    TBD.clean!
    argh = {}
    file = File.join(__dir__, "files/osms/in/smalloffice.osm")
    path = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model.empty?).to be(false)
    model = model.get

    # Fetch window & add 100mm outside reveal depth to F&D.
    sub = model.getSubSurfaceByName("Perimeter_ZN_1_wall_south_Window_1")
    expect(sub.empty?).to be(false)
    sub = sub.get
    fd = OpenStudio::Model::WindowPropertyFrameAndDivider.new(model)
    fd.setName("Perimeter_ZN_1_wall_south_Window_1_fd")
    expect(fd.setOutsideRevealDepth(0.100)).to be(true)
    expect(fd.isOutsideRevealDepthDefaulted).to be(false)
    expect(fd.outsideRevealDepth).to be_within(TOL).of(0.100)
    expect(sub.setWindowPropertyFrameAndDivider(fd)).to be(true)

    argh[:option     ] = "code (Quebec)"
    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")

    json = TBD.process(model, argh)
    expect(json.is_a?(Hash)).to be(true)
    expect(json.key?(:io      )).to be(true)
    expect(json.key?(:surfaces)).to be(true)

    io       = json[:io      ]
    surfaces = json[:surfaces]

    expect(TBD.status).to eq(0)
    expect(TBD.logs.empty?).to be(true)
    expect(io.nil?).to be(false)
    expect(io.is_a?(Hash)).to be(true)
    expect(io.empty?).to be(false)
    expect(surfaces.nil?).to be(false)
    expect(surfaces.is_a?(Hash)).to be(true)
    expect(surfaces.size).to eq(43)

    expect(surfaces.key?("Perimeter_ZN_1_wall_south")).to be(true)
    surface = surfaces["Perimeter_ZN_1_wall_south"]
    expect(surface.key?(:ratio   )).to be(true)
    expect(surface.key?(:heatloss)).to be(true)
    expect(surface[:ratio   ]).to be_within(TOL).of(-10.88)
    expect(surface[:heatloss]).to be_within(TOL).of( 23.40)

    # Mimic the export functionality of the measure and save .osm file.
    out2 = JSON.pretty_generate(io)
    file2 = File.join(__dir__, "../json/tbd_smalloffice4.out.json")
    File.open(file2, "w") { |f| f.puts out2 }
    pth = File.join(__dir__, "files/osms/out/model_FD_rvl.osm")
    model.save(pth, true)

    # Both wall and window are defined along the XZ plane. Comparing generated
    # .idf files, the Y-axis coordinates of the window with a Frame & Divider
    # reveal is indeed offset by 100mm vs its host wall vertices. Comparing
    # EnergyPlus results, host walls in both .idf files have the same derated
    # U-factors, and reference the same derated construction and material.
    expect(FileUtils.identical?(file1, file2)).to be(true)
  end

  it "checks for parellel edges in close proximity" do
    TBD.clean!
    argh               = {}
    argh[:option     ] = "code (Quebec)"
    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")

    tr    = OpenStudio::OSVersion::VersionTranslator.new
    file  = File.join(__dir__, "files/osms/in/seb.osm")
    path  = OpenStudio::Path.new(file)
    model = tr.loadModel(path)
    expect(model.empty?).to be(false)
    model = model.get
    json  = TBD.process(model, argh)

    expect(json.is_a?(Hash)    ).to be( true)
    expect(json.key?(:io      )).to be( true)
    expect(json.key?(:surfaces)).to be( true)
    io        = json[:io      ]
    surfaces  = json[:surfaces]
    expect(TBD.status.zero?    ).to be( true)
    expect(TBD.logs.empty?     ).to be( true)
    expect(surfaces.nil?       ).to be(false)
    expect(surfaces.is_a?(Hash)).to be( true)
    expect(surfaces.size       ).to eq(   56)
    expect(io.nil?             ).to be(false)
    expect(io.is_a?(Hash)      ).to be( true)
    expect(io.empty?           ).to be(false)
    expect(io.key?(:edges)     ).to be( true)

    subs = {}

    io[:edges].each do |edge|
      expect(edge.is_a?(Hash)    ).to be(true)
      expect(edge.key?(:surfaces)).to be(true)
      expect(edge.key?(:type    )).to be(true)
      expect(edge.key?(:v0x     )).to be(true)
      expect(edge.key?(:v1x     )).to be(true)
      expect(edge.key?(:v0y     )).to be(true)
      expect(edge.key?(:v1y     )).to be(true)
      expect(edge.key?(:v0z     )).to be(true)
      expect(edge.key?(:v1z     )).to be(true)

      ok = false
      nb = 0 # only process vertical edges (each linking 1x subsurface)
      next if (edge[:v0z] - edge[:v1z]).abs < TOL

      edge[:surfaces].each do |id|
        ok = id.include?("Sub Surface")
        break if ok
      end

      next unless ok

      edge[:surfaces].each do |id|
        next unless id.include?("Sub Surface")

        type = edge[:type].to_s.downcase
        expect(type.include?("jamb")).to be(true)
        nb += 1
        subs[id] = [] unless subs.key?(id)
        subs[id] << { v0: Topolys::Point3D.new(edge[:v0x].to_f,
                                               edge[:v0y].to_f,
                                               edge[:v0z].to_f),
                      v1: Topolys::Point3D.new(edge[:v1x].to_f,
                                               edge[:v1y].to_f,
                                               edge[:v1z].to_f) }
      end

      # None of the subsurfaces share a common edge in the seb.osm. A vertical
      # subsurface edge is shared only with its base (parent) surface.
      expect(nb).to eq(1)
    end

    nb = 0
    expect(subs.size).to eq(8)

    subs.values.each { |sub| expect(sub.size).to eq(2) }

    subs.each do |id1, sub1|
      subs.each do |id2, sub2|
        next if id1 == id2

        sub1.each do |sb1|
          sub2.each do |sb2|
            # With default tolerances, none of the subsurface edges "match" up.
            expect(TBD.matches?(sb1, sb2)).to be(false)
            # Greater tolerances however trigger 5x matches, as follows:
            # "Sub Surface 7" ~ "Sub Surface 8" ~ "Sub Surface 6"
            # "Sub Surface 3" ~ "Sub Surface 5" ~ "Sub Surface 4"
            # "Sub Surface 1" ~ "Sub Surface 2"
            nb += 1 if TBD.matches?(sb1, sb2, 0.100)
          end
        end
      end
    end

    expect(nb).to eq(10) # Twice 5x: each edge is once object, once subject

    dads = {}

    subs.keys.each do |id|
      kid = model.getSubSurfaceByName(id)
      expect(kid.empty?).to be(false)
      kid = kid.get
      dad = kid.surface
      expect(dad.empty?).to be(false)
      dad = dad.get
      nom = dad.nameString
      expect(surfaces.key?(nom)).to be(true)
      loss = surfaces[nom][:heatloss]
      dads[nom] = loss

      case nom
      when "Entryway  Wall 4"     then expect(loss).to be_within(TOL).of(2.705)
      when "Entryway  Wall 5"     then expect(loss).to be_within(TOL).of(4.820)
      when "Entryway  Wall 6"     then expect(loss).to be_within(TOL).of(2.008)
      when "Smalloffice 1 Wall 1" then expect(loss).to be_within(TOL).of(5.938)
      when "Smalloffice 1 Wall 2" then expect(loss).to be_within(TOL).of(3.838)
      when "Smalloffice 1 Wall 6" then expect(loss).to be_within(TOL).of(3.709)
      when "Utility1 Wall 1"      then expect(loss).to be_within(TOL).of(5.472)
      when "Utility1 Wall 5"      then expect(loss).to be_within(TOL).of(5.440)
      end
    end

    # Repeat exercise, while resetting tolerance to 100mm.
    TBD.clean!
    argh               = {}
    argh[:option     ] = "code (Quebec)"
    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")
    argh[:sub_tol    ] = 0.100

    file  = File.join(__dir__, "files/osms/in/seb.osm")
    path  = OpenStudio::Path.new(file)
    model = tr.loadModel(path)
    expect(model.empty?).to be(false)
    model = model.get
    json  = TBD.process(model, argh)

    expect(json.is_a?(Hash)    ).to be( true)
    expect(json.key?(:io      )).to be( true)
    expect(json.key?(:surfaces)).to be( true)
    io        = json[:io      ]
    surfaces  = json[:surfaces]
    expect(TBD.status.zero?    ).to be( true)
    expect(TBD.logs.empty?     ).to be( true)
    expect(surfaces.nil?       ).to be(false)
    expect(surfaces.is_a?(Hash)).to be( true)
    expect(surfaces.size       ).to eq(   56)
    expect(io.nil?             ).to be(false)
    expect(io.is_a?(Hash)      ).to be( true)
    expect(io.empty?           ).to be(false)
    expect(io.key?(:edges)     ).to be( true)

    subs = {}

    io[:edges].each do |edge|
      expect(edge.is_a?(Hash)    ).to be(true)
      expect(edge.key?(:surfaces)).to be(true)
      expect(edge.key?(:type    )).to be(true)
      expect(edge.key?(:v0x     )).to be(true)
      expect(edge.key?(:v1x     )).to be(true)
      expect(edge.key?(:v0y     )).to be(true)
      expect(edge.key?(:v1y     )).to be(true)
      expect(edge.key?(:v0z     )).to be(true)
      expect(edge.key?(:v1z     )).to be(true)

      ok = false
      next if (edge[:v0z] - edge[:v1z]).abs < TOL

      edge[:surfaces].each do |id|
        ok = id.include?("Sub Surface")
        break if ok
      end

      next unless ok

      edge[:surfaces].each do |id|
        next unless id.include?("Sub Surface")

        type = edge[:type].to_s.downcase
        subs[id] = [] unless subs.key?(id)
        subs[id] << type
      end
    end

    # "Sub Surface 7" ~ "Sub Surface 8" ~ "Sub Surface 6"
    # "Sub Surface 3" ~ "Sub Surface 5" ~ "Sub Surface 4"
    # "Sub Surface 1" ~ "Sub Surface 2"
    subs.each do |id, types|
      expect(types.size).to eq(2)
      kid = model.getSubSurfaceByName(id)
      expect(kid.empty?).to be(false)
      kid = kid.get
      dad = kid.surface
      expect(dad.empty?).to be(false)
      dad = dad.get
      nom = dad.nameString
      expect(surfaces.key?(nom)).to be(true)
      loss = surfaces[nom][:heatloss]
      less = 0.200    # jamb PSI factor (in W/K per meter)
      # Sub Surface 6 : 0.496           (height in meters)
      # Sub Surface 8 : 0.488
      # Sub Surface 7 : 0.497
      # Sub Surface 5 : 1.153
      # Sub Surface 3 : 1.162
      # Sub Surface 4 : 1.163
      # Sub Surface 1 : 0.618
      # Sub Surface 2 : 0.618

      case id
      when "Sub Surface 5"
        expect(types.include?("jamb")      ).to be(false)
        expect(types.include?("transition")).to be( true)
        less *= (2 * 1.153) # 2x transitions; no jambs
      when "Sub Surface 8"
        expect(types.include?("jamb")      ).to be(false)
        expect(types.include?("transition")).to be( true)
        less *= (2 * 0.488) # 2x transitions; no jambs
      when "Sub Surface 6"
        expect(types.include?("jamb")      ).to be( true)
        expect(types.include?("transition")).to be( true)
        less *= (1 * 0.496) # 1x transition; 1x jamb
      when "Sub Surface 7"
        expect(types.include?("jamb")      ).to be( true)
        expect(types.include?("transition")).to be( true)
        less *= (1 * 0.497) # 1x transition; 1x jamb
      when "Sub Surface 3"
        expect(types.include?("jamb")      ).to be( true)
        expect(types.include?("transition")).to be( true)
        less *= (1 * 1.162) # 1x transition; 1x jamb
      when "Sub Surface 4"
        expect(types.include?("jamb")      ).to be( true)
        expect(types.include?("transition")).to be( true)
        less *= (1 * 1.163) # 1x transition; 1x jamb
      when "Sub Surface 1"
        expect(types.include?("jamb")      ).to be( true)
        expect(types.include?("transition")).to be( true)
        less *= (1 * 0.618) # 1x transition; 1x jamb
      when "Sub Surface 2"
        expect(types.include?("jamb")      ).to be( true)
        expect(types.include?("transition")).to be( true)
        less *= (1 * 0.618) # 1x transition; 1x jamb
      end

      # 'dads[ (parent surface identifier) ]' holds TBD-estimated heat loss
      # from major thermal bridging (in W/K) in the initial case. The
      # substitution of 1x or 2x subsurface jamb edge types to (mild)
      # transition(s) reduces the (revised) heat loss in the second case.
      expect(loss + less).to be_within(TOL).of(dads[nom])
    end
  end

  it "checks for subsurface multipliers" do
    TBD.clean!
    argh           = {}
    argh[:option ] = "code (Quebec)"
    argh[:gen_ua ] = true
    argh[:ua_ref ] = "code (Quebec)"
    argh[:version] = OpenStudio.openStudioVersion

    front = "Office Front Wall"
    left  = "Office Left Wall"
    file  = File.join(__dir__, "files/osms/in/warehouse.osm")
    path  = OpenStudio::Path.new(file)
    tr    = OpenStudio::OSVersion::VersionTranslator.new
    model = tr.loadModel(path)
    expect(model.empty?).to be(false)
    model = model.get
    json  = TBD.process(model, argh)

    expect(json.is_a?(Hash)    ).to be(true)
    expect(json.key?(:io      )).to be(true)
    expect(json.key?(:surfaces)).to be(true)
    io        = json[:io      ]
    surfaces  = json[:surfaces]
    expect(TBD.status          ).to eq(   0)
    expect(TBD.logs.empty?     ).to be(true)

    # Testing UA summaries.
    argh[:io              ] = io
    argh[:surfaces        ] = surfaces
    argh[:io][:description] = "test UA vs multipliers"

    ua = TBD.ua_summary(Time.now, argh)
    expect(ua.nil?        ).to be(false)
    expect(ua.empty?      ).to be(false)
    expect(ua.is_a?(Hash) ).to be( true)
    expect(ua.key?(:model)).to be( true)

    mult_ud_md = TBD.ua_md(ua, :en)
    pth = File.join(__dir__, "files/ua/ua_mult.md")
    File.open(pth, "w") { |file| file.puts mult_ud_md }

    [front, left].each do |side|
      wall = model.getSurfaceByName(side)
      expect(wall.empty?).to be(false)
      wall = wall.get

      if side == front
        sub_area = (1 * 3.90) + (2 * 5.58) # 1x double-width door + 2x windows
        expect(wall.grossArea).to be_within(0.01).of(110.54)
        expect(wall.netArea  ).to be_within(0.01).of( 95.49)
        expect(wall.netArea  ).to be_within(0.05).of(wall.grossArea - sub_area)
      else # side == left
        sub_area = (1 * 1.95) + (2 * 3.26) # 1x single-width door + 2x windows
        expect(wall.grossArea).to be_within(0.01).of( 39.02)
        expect(wall.netArea  ).to be_within(0.01).of( 30.56)
        expect(wall.netArea  ).to be_within(0.05).of(wall.grossArea - sub_area)
      end

      expect(surfaces.key?(side)          ).to be(true)
      expect(surfaces[side].key?(:windows)).to be(true)
      expect(surfaces[side][:windows].size).to eq(   2)

      surfaces[side][:windows].keys.each do |sub|
        expect(sub.include?(side)     ).to be(true)
        expect(sub.include?(" Window")).to be(true)
      end

      expect(surfaces[side].key?(:heatloss)).to be(true)
      hloss = surfaces[side][:heatloss]

      # Per office ouside-facing wall:
      #   - nb: number of distinct edges, per MAJOR thermal bridge type
      #   - lm: total edge lengths (m), per MAJOR thermal bridge type
      jambs   = { nb: 0, lm: 0 }
      sills   = { nb: 0, lm: 0 }
      heads   = { nb: 0, lm: 0 }
      grades  = { nb: 0, lm: 0 }
      rims    = { nb: 0, lm: 0 }
      corners = { nb: 0, lm: 0 }

      io[:edges].each do |edge|
        expect(edge.key?(:surfaces)        ).to be( true)
        expect(edge[:surfaces].is_a?(Array)).to be( true)
        expect(edge[:surfaces].empty?      ).to be(false)
        next unless edge[:surfaces].include?(side)

        expect(edge.key?(:length)).to be(true)
        expect(edge.key?(:type  )).to be(true)
        next if edge[:type] == :transition

        case edge[:type]
        when :jamb
          jambs[  :nb] += 1
          jambs[  :lm] += edge[:length]
        when :sill
          sills[  :nb] += 1
          sills[  :lm] += edge[:length]
        when :head
          heads[  :nb] += 1
          heads[  :lm] += edge[:length]
        when :gradeconvex
          grades[ :nb] += 1
          grades[ :lm] += edge[:length]
        when :rimjoist
          rims[   :nb] += 1
          rims[   :lm] += edge[:length]
        else
          corners[:nb] += 1
          corners[:lm] += edge[:length]
        end
      end

      expect(  jambs[:nb]).to eq(6) # 2x windows + 1x door ... 2x
      expect(  sills[:nb]).to eq(2) # 2x windows
      expect(  heads[:nb]).to eq(3) # 2x windows + 1x door
      expect( grades[:nb]).to eq(3) # split by door sill
      expect(   rims[:nb]).to eq(1)
      expect(corners[:nb]).to eq(1)

      if side == front
        expect(  jambs[:lm]).to be_within(0.01).of(10.37)
        expect(  sills[:lm]).to be_within(0.01).of( 7.31)
        expect(  heads[:lm]).to be_within(0.01).of( 9.14)
        expect( grades[:lm]).to be_within(0.01).of(25.91)
        expect(   rims[:lm]).to be_within(0.01).of(25.91) # same as grade
        expect(corners[:lm]).to be_within(0.01).of( 4.27)

        loss  = 0.200 * (jambs[:lm] + sills[:lm] + heads[:lm])
        loss += 0.450 * grades[:lm]
        loss += 0.300 * (rims[:lm] + corners[:lm]) / 2
        expect(loss ).to be_within(0.01).of(21.55)
        expect(hloss).to be_within(0.01).of(loss)
      else # left
        expect(  jambs[:lm]).to be_within(0.01).of(10.37) # same as front
        expect(  sills[:lm]).to be_within(0.01).of( 4.27)
        expect(  heads[:lm]).to be_within(0.01).of( 5.18)
        expect( grades[:lm]).to be_within(0.01).of( 9.14)
        expect(   rims[:lm]).to be_within(0.01).of( 9.14) # same as grade
        expect(corners[:lm]).to be_within(0.01).of( 4.27) # same as front
        expect(hloss       ).to be_within(0.01).of(10.09)
      end
    end

    # Re-open model and add multipliers to both front & left subsurfaces.
    TBD.clean!
    argh           = {}
    argh[:option ] = "code (Quebec)"
    argh[:gen_ua ] = true
    argh[:ua_ref ] = "code (Quebec)"
    argh[:version] = OpenStudio.openStudioVersion

    mult  = 2
    model = tr.loadModel(path)
    expect(model.empty?).to be(false)
    model = model.get

    # Set subsurface multipliers.
    model.getSubSurfaces.each do |sub|
      parent    = sub.surface
      expect(parent.empty?).to be(false)
      parent    = parent.get
      front_sub = parent.nameString.include?(front)
      left_sub  = parent.nameString.include?(left)
      next unless front_sub || left_sub

      expect(sub.setMultiplier(mult)).to be(true)
      expect(sub.multiplier         ).to eq(mult)
    end

    # out = File.join(__dir__, "files/osms/out/mult_warehouse.osm")
    # model.save(out, true)

    json     = TBD.process(model, argh)
    expect(json.is_a?(Hash)    ).to be(true)
    expect(json.key?(:io      )).to be(true)
    expect(json.key?(:surfaces)).to be(true)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.status.zero?    ).to be(true)
    expect(TBD.logs.empty?     ).to be(true)

    # Testing UA summaries.
    argh[:io              ] = io
    argh[:surfaces        ] = surfaces
    argh[:io][:description] = "test UA vs multipliers"

    ua2 = TBD.ua_summary(Time.now, argh)
    expect(ua2.nil?        ).to be(false)
    expect(ua2.empty?      ).to be(false)
    expect(ua2.is_a?(Hash) ).to be( true)
    expect(ua2.key?(:model)).to be( true)

    mult_ud_md2 = TBD.ua_md(ua2, :en)
    pth = File.join(__dir__, "files/ua/ua_mult2.md")
    File.open(pth, "w") { |file| file.puts mult_ud_md2 }

    [front, left].each do |side|
      wall = model.getSurfaceByName(side)
      expect(wall.empty?).to be(false)
      wall = wall.get

      if side == front
        sub_area = (2 * 3.90) + (4 * 5.58) # 2x double-width door + 4x windows
        expect(wall.grossArea).to be_within(0.01).of(110.54)
        expect(wall.netArea  ).to be_within(0.01).of( 80.43)
        expect(wall.netArea  ).to be_within(0.05).of(wall.grossArea - sub_area)
      else # side == left
        sub_area = (2 * 1.95) + (4 * 3.26) # 2x single-width door + 4x windows
        expect(wall.grossArea).to be_within(0.01).of( 39.02)
        expect(wall.netArea  ).to be_within(0.01).of( 22.10)
        expect(wall.netArea  ).to be_within(0.05).of(wall.grossArea - sub_area)
      end

      expect(surfaces.key?(side)          ).to be(true)
      expect(surfaces[side].key?(:windows)).to be(true)
      expect(surfaces[side][:windows].size).to eq(   2)

      surfaces[side][:windows].keys do |sub|
        expect(sub.include?(side)     ).to be(true)
        expect(sub.include?(" Window")).to be(true)
      end

      # 2nd tallies, per office ouside-facing wall:
      #   - nb: number of distinct edges, per MAJOR thermal bridge type
      #   - lm: total edge lengths (m), per MAJOR thermal bridge type
      jambs2   = { nb: 0, lm: 0 }
      sills2   = { nb: 0, lm: 0 }
      heads2   = { nb: 0, lm: 0 }
      grades2  = { nb: 0, lm: 0 }
      rims2    = { nb: 0, lm: 0 }
      corners2 = { nb: 0, lm: 0 }

      io[:edges].each do |edge|
        expect(edge.key?(:surfaces)        ).to be( true)
        expect(edge[:surfaces].is_a?(Array)).to be( true)
        expect(edge[:surfaces].empty?      ).to be(false)
        next unless edge[:surfaces].include?(side)

        expect(edge.key?(:length)).to be(true)
        expect(edge.key?(:type  )).to be(true)
        next if edge[:type] == :transition

        case edge[:type]
        when :jamb
          jambs2[  :nb] += 1
          jambs2[  :lm] += edge[:length]
        when :sill
          sills2[  :nb] += 1
          sills2[  :lm] += edge[:length]
        when :head
          heads2[  :nb] += 1
          heads2[  :lm] += edge[:length]
        when :gradeconvex
          grades2[ :nb] += 1
          grades2[ :lm] += edge[:length]
        when :rimjoist
          rims2[   :nb] += 1
          rims2[   :lm] += edge[:length]
        else
          corners2[:nb] += 1
          corners2[:lm] += edge[:length]
        end
      end

      expect(surfaces[side].key?(:heatloss)).to be(true)
      hloss = surfaces[side][:heatloss]

      expect(  jambs2[:nb]).to eq(6) # no change vs initial, unaltered model
      expect(  sills2[:nb]).to eq(2)
      expect(  heads2[:nb]).to eq(3)
      expect( grades2[:nb]).to eq(3)
      expect(   rims2[:nb]).to eq(1)
      expect(corners2[:nb]).to eq(1)

      if side == front
        expect(  jambs2[:lm]).to be_within(0.01).of(10.37 * mult)
        expect(  sills2[:lm]).to be_within(0.01).of( 7.31 * mult)
        expect(  heads2[:lm]).to be_within(0.01).of( 9.14 * mult)
        expect(   rims2[:lm]).to be_within(0.01).of(25.91) # unchanged
        expect(corners2[:lm]).to be_within(0.01).of( 4.27) # unchanged

        # In the OpenStudio warehouse model, the front door (2x 915mm) "sill" is
        # aligned along the slab-on-"grade" edge. It is the only such "shared"
        # subsurface edge in this (front wall) example. In TBD, such common
        # edges initially hold multiple thermal bridge types in memory, until a
        # single, dominant type (based on PSI factor) is finally assigned
        # (here, "grade" not "sill").
        #
        # By adding a 2x multiplier in OpenStudio, door area and perimeter have
        # doubled while the initial subsurface vertices remain as before. This
        # of course breaks model geometrical consistency (vs Topolys), which is
        # expected with multipliers - they remain abstract modifiers that do not
        # lend easily to 3D representation. It would be imprudent for
        # TBD/Topolys to "stretch" subsurface vertex 3D position, based on
        # OpenStudio subsurface multipliers. This would often generate
        # unintended conflicts with parent and siblings (i.e. other subsurfaces
        # sharing the same parent). As such, TBD would overestimate the total
        # "grade" length by the added "sill" length.
        expect( grades2[:lm]).to be_within(0.01).of(25.91 + 2 * 0.915)

        # This (user-selected) discrepancy can easily be countered (by the very
        # same user), by proportionally adjusting the selected "grade" PSI
        # factor (using TBD JSON customization). For this reason, TBD will not
        # raise this as an error. Nonetheless, the use of subsurface multipliers
        # will require a clear set of recommendations in TBD's online Guide.
        extra  = 0.200 * jambs2[:lm] / 2
        extra += 0.200 * sills2[:lm] / 2
        extra += 0.200 * heads2[:lm] / 2
        extra += 0.450 * 2 * 0.915
        expect(extra).to be_within(0.01).of(6.19)
        expect(hloss).to be_within(0.01).of(21.55 + extra)
      else # left
        expect(  jambs2[:lm]).to be_within(0.01).of(10.37 * mult)
        expect(  sills2[:lm]).to be_within(0.01).of( 4.27 * mult)
        expect(  heads2[:lm]).to be_within(0.01).of( 5.18 * mult)
        expect(   rims2[:lm]).to be_within(0.01).of( 9.14) # unchanged
        expect(corners2[:lm]).to be_within(0.01).of( 4.27) # unchanged

        # See above comments for grade vs sill discrepancy.
        expect( grades2[:lm]).to be_within(0.01).of( 9.14 + 0.915)

        extra  = 0.200 * jambs2[:lm] / 2
        extra += 0.200 * sills2[:lm] / 2
        extra += 0.200 * heads2[:lm] / 2
        extra += 0.450 * 0.915
        expect(extra).to be_within(0.01).of(4.37)
        expect(hloss).to be_within(0.01).of(10.09 + extra)
      end
    end
  end

  it "checks for subsurface vertex inheritance" do
    TBD.clean!
    argh  = { option: "code (Quebec)" }
    file  = File.join(__dir__, "files/osms/in/warehouse.osm")
    path  = OpenStudio::Path.new(file)
    tr    = OpenStudio::OSVersion::VersionTranslator.new
    model = tr.loadModel(path)
    expect(model.empty?).to be(false)
    model = model.get

    hloss1   = 0
    hloss2   = 0
    minY     = 1000
    maxZ     = 0
    leftwall = "Fine Storage Left Wall"
    leftdoor = "Fine Storage Left Door"
    leftside = "Fine Storage Left Sidelight"
    wall     = model.getSurfaceByName(leftwall)
    door     = model.getSubSurfaceByName(leftdoor)

    expect(wall.empty?  ).to be(false)
    expect(door.empty?  ).to be(false)
    wall     = wall.get
    door     = door.get
    parent   = door.surface
    expect(parent.empty?).to eq(false)
    parent   = parent.get
    expect(parent).to eq(wall)

    door.vertices.each { |vtx| minY = [minY,vtx.y].min }
    door.vertices.each { |vtx| maxZ = [maxZ,vtx.z].max }

    expect(minY).to be_within(0.01).of(19.35)
    expect(maxZ).to be_within(0.01).of( 2.13)

    # Adding a partial-height (sill +900mm above grade, width 500mm) sidelight,
    # adjacent to the door (sharing an edge).
    vertices  = OpenStudio::Point3dVector.new
    vertices << OpenStudio::Point3d.new(0.0, minY      , maxZ)
    vertices << OpenStudio::Point3d.new(0.0, minY      ,  0.9)
    vertices << OpenStudio::Point3d.new(0.0, minY - 0.5,  0.9)
    vertices << OpenStudio::Point3d.new(0.0, minY - 0.5, maxZ)
    sidelight = OpenStudio::Model::SubSurface.new(vertices, model)
    sidelight.setName(leftside)

    expect(sidelight.setSubSurfaceType("FixedWindow")).to be(true)
    expect(sidelight.setSurface(wall)                ).to be(true)

    json      = TBD.process(model, argh)
    expect(json.is_a?(Hash)    ).to be(true)
    expect(json.key?(:io      )).to be(true)
    expect(json.key?(:surfaces)).to be(true)
    io        = json[:io      ]
    surfaces  = json[:surfaces]
    expect(TBD.status.zero?    ).to be(true)
    expect(TBD.logs.empty?     ).to be(true)
    expect(io.key?(:edges     )).to be(true)

    expect(surfaces.key?(leftwall)           ).to be(true)
    expect(surfaces[leftwall].key?(:heatloss)).to be(true)
    hloss1 = surfaces[leftwall][:heatloss]

    # Counters of distinct Fine Storage Left Wall subsurface edges.
    side_heads = 0
    side_sills = 0
    side_jambs = 0
    side_trns  = 0
    door_grade = 0
    door_heads = 0
    door_sills = 0
    door_jambs = 0
    door_trns  = 0

    # Length tallies of Fine Storage Left Wall subsurface edges.
    side_head_m  = 0
    side_sill_m  = 0
    side_jamb_m  = 0
    side_trns_m  = 0
    door_grade_m = 0
    door_head_m  = 0
    door_sill_m  = 0
    door_jamb_m  = 0
    door_trns_m  = 0

    io[:edges].each do |edge|
      expect(edge.key?(:surfaces)        ).to be( true)
      expect(edge[:surfaces].is_a?(Array)).to be( true)
      expect(edge[:surfaces].empty?      ).to be(false)
      next unless edge[:surfaces].include?(leftside)

      expect(edge.key?(:type  )).to be(true)
      expect(edge.key?(:length)).to be(true)

      side_heads += 1 if edge[:type].to_s.include?("head"      )
      side_sills += 1 if edge[:type].to_s.include?("sill"      )
      side_jambs += 1 if edge[:type].to_s.include?("jamb"      )
      side_trns  += 1 if edge[:type].to_s.include?("transition")

      side_head_m += edge[:length] if edge[:type].to_s.include?("head"      )
      side_sill_m += edge[:length] if edge[:type].to_s.include?("sill"      )
      side_jamb_m += edge[:length] if edge[:type].to_s.include?("jamb"      )
      side_trns_m += edge[:length] if edge[:type].to_s.include?("transition")
    end

    expect(side_heads).to eq(1)
    expect(side_sills).to eq(1)
    expect(side_jambs).to eq(1) # instead shared with door
    expect(side_trns ).to eq(1) # shared with initial left door

    expect(side_head_m).to be_within(0.01).of(       0.5)
    expect(side_sill_m).to be_within(0.01).of(       0.5)
    expect(side_jamb_m).to be_within(0.01).of(maxZ - 0.9)
    expect(side_trns_m).to be_within(0.01).of(maxZ - 0.9) # same as jamb

    io[:edges].each do |edge|
      expect(edge.key?(:surfaces)        ).to be( true)
      expect(edge[:surfaces].is_a?(Array)).to be( true)
      expect(edge[:surfaces].empty?      ).to be(false)
      next unless edge[:surfaces].include?(leftdoor)

      expect(edge.key?(:type  )).to be(true)
      expect(edge.key?(:length)).to be(true)

      door_grade += 1 if edge[:type].to_s.include?("grade"     )
      door_heads += 1 if edge[:type].to_s.include?("head"      )
      door_sills += 1 if edge[:type].to_s.include?("sill"      )
      door_jambs += 1 if edge[:type].to_s.include?("jamb"      )
      door_trns  += 1 if edge[:type].to_s.include?("transition") # shared

      door_head_m += edge[:length] if edge[:type].to_s.include?("head"      )
      door_sill_m += edge[:length] if edge[:type].to_s.include?("sill"      )
      door_jamb_m += edge[:length] if edge[:type].to_s.include?("jamb"      )
      door_trns_m += edge[:length] if edge[:type].to_s.include?("transition")
    end

    # 5x edges (instead of original 4x).
    expect(door_grade).to eq(1)
    expect(door_heads).to eq(1)
    expect(door_sills).to eq(0) # overriden as grade
    expect(door_jambs).to eq(2) # 1x full height + 1x partial height
    expect(door_trns ).to eq(1) # shared with sidelight

    expect(door_jamb_m).to be_within(0.01).of(maxZ + 0.9)
    expect(door_trns_m).to be_within(0.01).of(maxZ - 0.9) # same as sidelight


    # Repeat exercise with a transorm above door and sidelight.
    TBD.clean!
    argh  = { option: "code (Quebec)" }
    file  = File.join(__dir__, "files/osms/in/warehouse.osm")
    path  = OpenStudio::Path.new(file)
    tr    = OpenStudio::OSVersion::VersionTranslator.new
    model = tr.loadModel(path)
    expect(model.empty?).to be(false)
    model = model.get

    trnsom = "Fine Storage Left Transom"
    minY   = 1000
    maxY   = 0
    maxZ   = 0
    wall   = model.getSurfaceByName(leftwall)
    door   = model.getSubSurfaceByName(leftdoor)
    expect(wall.empty?).to be(false)
    expect(door.empty?).to be(false)
    wall   = wall.get
    door   = door.get

    door.vertices.each { |vtx| minY = [minY,vtx.y].min }
    door.vertices.each { |vtx| maxY = [maxY,vtx.y].max }
    door.vertices.each { |vtx| maxZ = [maxZ,vtx.z].max }

    # Adding a partial-height (sill +900mm above grade, width 500mm) sidelight,
    # adjacent to the door (sharing an edge).
    vertices  = OpenStudio::Point3dVector.new
    vertices << OpenStudio::Point3d.new(0.0, minY      , maxZ)
    vertices << OpenStudio::Point3d.new(0.0, minY      ,  0.9)
    vertices << OpenStudio::Point3d.new(0.0, minY - 0.5,  0.9)
    vertices << OpenStudio::Point3d.new(0.0, minY - 0.5, maxZ)
    sidelight = OpenStudio::Model::SubSurface.new(vertices, model)
    sidelight.setName(leftside)
    expect(sidelight.setSubSurfaceType("FixedWindow")).to be(true)
    expect(sidelight.setSurface(wall)                ).to be(true)

    # Adding a transom over the full width of the door and sidelight.
    vertices  = OpenStudio::Point3dVector.new
    vertices << OpenStudio::Point3d.new(0.0, maxY      , maxZ + 0.4)
    vertices << OpenStudio::Point3d.new(0.0, maxY      , maxZ      )
    vertices << OpenStudio::Point3d.new(0.0, minY - 0.5, maxZ      )
    vertices << OpenStudio::Point3d.new(0.0, minY - 0.5, maxZ + 0.4)
    transom   = OpenStudio::Model::SubSurface.new(vertices, model)
    transom.setName(trnsom)

    expect(transom.setSubSurfaceType("FixedWindow")).to be( true)
    expect(transom.setSurface(wall)                ).to be( true)

    json      = TBD.process(model, argh)
    expect(json.is_a?(Hash)    ).to be(true)
    expect(json.key?(:io      )).to be(true)
    expect(json.key?(:surfaces)).to be(true)
    io        = json[:io      ]
    surfaces  = json[:surfaces]
    expect(TBD.status.zero?    ).to be(true)
    expect(TBD.logs.empty?     ).to be(true)
    expect(io.key?(:edges)     ).to be(true)

    expect(surfaces.key?(leftwall)           ).to be(true)
    expect(surfaces[leftwall].key?(:heatloss)).to be(true)
    hloss2 = surfaces[leftwall][:heatloss]

    # Additional heat loss (versus initial case with 1x + 1x sidelight) is
    # limited to the 2x transom jambs x 0.200 W/m2.K
    expect(hloss2 - hloss1).to be_within(0.01).of(2 * 0.4 * 0.200)

    # Counters of distinct Fine Storage Left Wall subsurface edges.
    side_heads = 0
    side_sills = 0
    side_jambs = 0
    side_trns  = 0
    door_grade = 0
    door_heads = 0
    door_sills = 0
    door_jambs = 0
    door_trns  = 0
    trsm_heads = 0
    trsm_sills = 0
    trsm_jambs = 0
    trsm_trns  = 0

    # Length tallies of Fine Storage Left Wall subsurface edges.
    side_head_m  = 0
    side_sill_m  = 0
    side_jamb_m  = 0
    side_trns_m  = 0
    door_grade_m = 0
    door_head_m  = 0
    door_sill_m  = 0
    door_jamb_m  = 0
    door_trns_m  = 0
    trsm_head_m  = 0
    trsm_sill_m  = 0
    trsm_jamb_m  = 0
    trsm_trns_m  = 0

    io[:edges].each do |edge|
      expect(edge.key?(:surfaces        )).to be( true)
      expect(edge[:surfaces].is_a?(Array)).to be( true)
      expect(edge[:surfaces].empty?      ).to be(false)

      next unless edge[:surfaces].include?(leftside)

      expect(edge.key?(:type  )).to be(true)
      expect(edge.key?(:length)).to be(true)

      side_heads += 1 if edge[:type].to_s.include?("head"      )
      side_sills += 1 if edge[:type].to_s.include?("sill"      )
      side_jambs += 1 if edge[:type].to_s.include?("jamb"      )
      side_trns  += 1 if edge[:type].to_s.include?("transition")

      side_head_m += edge[:length] if edge[:type].to_s.include?("head"      )
      side_sill_m += edge[:length] if edge[:type].to_s.include?("sill"      )
      side_jamb_m += edge[:length] if edge[:type].to_s.include?("jamb"      )
      side_trns_m += edge[:length] if edge[:type].to_s.include?("transition")
    end

    expect(side_heads).to eq(0) # instead shared with transom
    expect(side_sills).to eq(1)
    expect(side_jambs).to eq(1) # instead shared with door
    expect(side_trns ).to eq(2) # shared with left door & transom

    expect(side_head_m).to be_within(0.01).of(             0.0)
    expect(side_sill_m).to be_within(0.01).of(             0.5)
    expect(side_jamb_m).to be_within(0.01).of(maxZ - 0.9      )
    expect(side_trns_m).to be_within(0.01).of(maxZ - 0.9 + 0.5)

    io[:edges].each do |edge|
      expect(edge.key?(:surfaces        )).to be( true)
      expect(edge[:surfaces].is_a?(Array)).to be( true)
      expect(edge[:surfaces].empty?      ).to be(false)

      next unless edge[:surfaces].include?(leftdoor)

      expect(edge.key?(:type  )).to be(true)
      expect(edge.key?(:length)).to be(true)

      door_grade += 1 if edge[:type].to_s.include?("grade"     )
      door_heads += 1 if edge[:type].to_s.include?("head"      )
      door_sills += 1 if edge[:type].to_s.include?("sill"      )
      door_jambs += 1 if edge[:type].to_s.include?("jamb"      )
      door_trns  += 1 if edge[:type].to_s.include?("transition") # shared

      door_head_m += edge[:length] if edge[:type].to_s.include?("head"      )
      door_sill_m += edge[:length] if edge[:type].to_s.include?("sill"      )
      door_jamb_m += edge[:length] if edge[:type].to_s.include?("jamb"      )
      door_trns_m += edge[:length] if edge[:type].to_s.include?("transition")
    end

    # Again, 5x edges (instead of original 4x).
    expect(door_grade).to eq(1)
    expect(door_heads).to eq(0) # now shared with transom (see transition)
    expect(door_sills).to eq(0) # overriden as grade
    expect(door_jambs).to eq(2) # 1x full height + 1x partial height
    expect(door_trns ).to eq(2) # shared with sidelight + transom

    expect(door_jamb_m).to be_within(0.01).of(maxZ + 0.9)
    expect(door_trns_m).to be_within(0.01).of(maxZ - 0.9 + maxY - minY)

    io[:edges].each do |edge|
      expect(edge.key?(:surfaces)        ).to be( true)
      expect(edge[:surfaces].is_a?(Array)).to be( true)
      expect(edge[:surfaces].empty?      ).to be(false)

      next unless edge[:surfaces].include?(trnsom)

      expect(edge.key?(:type  )).to be(true)
      expect(edge.key?(:length)).to be(true)

      trsm_heads += 1 if edge[:type].to_s.include?("head"      )
      trsm_sills += 1 if edge[:type].to_s.include?("sill"      )
      trsm_jambs += 1 if edge[:type].to_s.include?("jamb"      )
      trsm_trns  += 1 if edge[:type].to_s.include?("transition") # shared

      trsm_head_m += edge[:length] if edge[:type].to_s.include?("head"      )
      trsm_sill_m += edge[:length] if edge[:type].to_s.include?("sill"      )
      trsm_jamb_m += edge[:length] if edge[:type].to_s.include?("jamb"      )
      trsm_trns_m += edge[:length] if edge[:type].to_s.include?("transition")
    end

    # 5x edges (instead of original 4x).
    expect(trsm_heads).to eq(1)
    expect(trsm_sills).to eq(0) # instead shared with door and sidelight
    expect(trsm_jambs).to eq(2) # 1x full height + 1x partial height
    expect(trsm_trns ).to eq(2) # shared with sidelight + door

    expect(trsm_jamb_m).to be_within(0.01).of(2 * 0.4          )
    expect(trsm_trns_m).to be_within(0.01).of(maxY - minY + 0.5)
    expect(trsm_head_m).to be_within(0.01).of(trsm_trns_m      )
  end

  it "can check for conditioned attics" do
    v = OpenStudio.openStudioVersion.split(".").map(&:to_i).join.to_i

    if v > 300
      TBD.clean!
      argh  = { option: "code (Quebec)" }
      tr    = OpenStudio::OSVersion::VersionTranslator.new
      file  = File.join(__dir__, "files/osms/in/resto1.osm")
      path  = OpenStudio::Path.new(file)
      model = tr.loadModel(path)
      expect(model.empty?).to be(false)
      model = model.get

      # Unaltered template v3.2.1 'FullServiceRestaurant' OpenStudio model.
      # ... no constructions, no setpoints), to be modified by BTAP.
      loops     = TBD.airLoopsHVAC?(model)
      setpoints = TBD.heatingTemperatureSetpoints?(model)
      setpoints = TBD.coolingTemperatureSetpoints?(model) || setpoints
      expect(model.getConstructions.empty?).to be( true)
      expect(setpoints                    ).to be(false)
      expect(loops                        ).to be(false)

      json      = TBD.process(model, argh)
      expect(json.is_a?(Hash)    ).to be( true)
      expect(json.key?(:io      )).to be( true)
      expect(json.key?(:surfaces)).to be( true)
      io        = json[:io      ]
      surfaces  = json[:surfaces]
      expect(surfaces.nil?       ).to be(false)
      expect(surfaces.is_a?(Hash)).to be( true)
      expect(surfaces.size       ).to eq(   18)
      expect(TBD.error?          ).to be( true)
      expect(TBD.logs.empty?     ).to be(false)
      expect(io.nil?             ).to be(false)
      expect(io.is_a?(Hash)      ).to be( true)
      expect(io.empty?           ).to be(false)
      expect(io.key?(:edges     )).to be(false)

      # No constructions to derate - 'surfaces' only holds pre-TBD attributes.
      surfaces.values.each do |surface|
        expect(surface.is_a?(Hash)        ).to be( true)
        expect(surface.key?(:space       )).to be( true)
        expect(surface.key?(:stype       )).to be( true) # spacetype
        expect(surface.key?(:conditioned )).to be( true)
        expect(surface.key?(:deratable   )).to be( true)
        expect(surface.key?(:construction)).to be(false)

        expect(surface[:conditioned      ]).to be( true)
        expect(surface[:deratable        ]).to be(false)
      end

      # Fetch conditioned attic floor.
      id    = "attic-floor-dinning"
      expect(surfaces.key?(id)         ).to be( true)
      space = surfaces[id][:space]
      expect(space.partofTotalFloorArea).to be(false)
      expect(space.thermalZone.empty?  ).to be(false)
      zone  = space.thermalZone.get
      expect(zone.isPlenum             ).to be(false)

      heat = TBD.maxHeatScheduledSetpoint(zone)
      cool = TBD.minCoolScheduledSetpoint(zone)

      expect(heat.nil?       ).to be(false)
      expect(cool.nil?       ).to be(false)
      expect(heat.is_a?(Hash)).to be( true)
      expect(cool.is_a?(Hash)).to be( true)
      expect(heat.key?(:spt )).to be( true)
      expect(cool.key?(:spt )).to be( true)
      expect(heat.key?(:dual)).to be( true)
      expect(cool.key?(:dual)).to be( true)
      expect(heat[:spt ].nil?).to be( true)
      expect(cool[:spt ].nil?).to be( true)
      expect(heat[:dual]     ).to be(false)
      expect(cool[:dual]     ).to be(false)

      expect(TBD.plenum?(space, loops, setpoints)).to be(false)

      # Replace "attic" space type with "plenum", then try again.
      attic  = model.getSpaceByName("attic")
      expect(attic.empty?).to be(false)
      attic  = attic.get
      sptype = attic.spaceType
      expect(sptype.empty?).to be(false)
      sptype.get.setName("plenum")
      expect(TBD.plenum?(attic, loops, setpoints)).to be(true) # works ...


      # -- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- -- #
      TBD.clean!
      argh  = { option: "code (Quebec)" }
      file  = File.join(__dir__, "files/osms/in/resto2.osm")
      path  = OpenStudio::Path.new(file)
      model = tr.loadModel(path)
      expect(model.empty?).to be(false)
      model = model.get

      # Partially altered 'FullServiceRestaurant' model, midway in BTAP processes
      # (just before 'apply_envelope', under 'model_apply_standard').
      loops     = TBD.airLoopsHVAC?(model)
      setpoints = TBD.heatingTemperatureSetpoints?(model)
      setpoints = TBD.coolingTemperatureSetpoints?(model) || setpoints
      expect(model.getConstructions.empty?).to be(false)

      expect(setpoints).to be( true)
      expect(loops    ).to be(false)

      # No point here in replacing attic space type with "plenum" - a last resort
      # check, ignored here by TBD as there are valid setpoints set elsewhere in
      # the model. Instead, temporarily add a heating dual setpoint schedule to
      # the attic zone thermostat (yet without valid schedule temperatures).
      attic = model.getSpaceByName("attic")
      expect(attic.empty?              ).to be(false)
      attic = attic.get
      expect(attic.partofTotalFloorArea).to be(false)
      expect(attic.thermalZone.empty?  ).to be(false)
      zone  = attic.thermalZone.get
      expect(zone.isPlenum             ).to be(false)
      tstat = zone.thermostat
      expect(tstat.empty?              ).to be(false)
      tstat = tstat.get

      expect(tstat.to_ThermostatSetpointDualSetpoint.empty?).to be(false)
      tstat = tstat.to_ThermostatSetpointDualSetpoint.get

      # Before the addition.
      expect(tstat.getHeatingSchedule.empty?).to be(true)
      expect(tstat.getCoolingSchedule.empty?).to be(true)

      heat = TBD.maxHeatScheduledSetpoint(zone)
      cool = TBD.minCoolScheduledSetpoint(zone)

      expect(heat.nil?       ).to be(false)
      expect(cool.nil?       ).to be(false)
      expect(heat.is_a?(Hash)).to be( true)
      expect(cool.is_a?(Hash)).to be( true)
      expect(heat.key?(:spt )).to be( true)
      expect(cool.key?(:spt )).to be( true)
      expect(heat.key?(:dual)).to be( true)
      expect(cool.key?(:dual)).to be( true)
      expect(heat[:spt ].nil?).to be( true)
      expect(cool[:spt ].nil?).to be( true)
      expect(heat[:dual]     ).to be(false)
      expect(cool[:dual]     ).to be(false)

      expect(TBD.plenum?(attic, loops, setpoints)).to be(false)

      # Add a dual setpoint temperature schedule.
      identifier = "TEMPORARY attic setpoint schedule"
      sched = OpenStudio::Model::ScheduleCompact.new(model)
      sched.setName(identifier)
      expect(sched.constantValue.empty?                        ).to be(true)
      expect(tstat.setHeatingSetpointTemperatureSchedule(sched)).to be(true)

      # After the addition.
      expect(tstat.getHeatingSchedule.empty?).to be(false)
      expect(tstat.getCoolingSchedule.empty?).to be( true)
      heat = TBD.maxHeatScheduledSetpoint(zone)

      expect(heat.nil?       ).to be(false)
      expect(heat.is_a?(Hash)).to be( true)
      expect(heat.key?(:spt )).to be( true)
      expect(heat.key?(:dual)).to be( true)
      expect(heat[:spt ].nil?).to be( true)
      expect(heat[:dual]     ).to be( true)

      expect(TBD.plenum?(attic, loops, setpoints)).to be(true) # works ...

      json      = TBD.process(model, argh)
      expect(json.is_a?(Hash)    ).to be( true)
      expect(json.key?(:io      )).to be( true)
      expect(json.key?(:surfaces)).to be( true)
      io        = json[:io      ]
      surfaces  = json[:surfaces]
      expect(TBD.error?          ).to be( true)
      expect(TBD.logs.empty?     ).to be(false)

      # The incomplete (temporary) schedule triggers a non-FATAL TBD error.
      TBD.logs.each do |log|
        expect(log[:message].include?("Empty '"                 )).to be(true)
        expect(log[:message].include?("::scheduleCompactMinMax)")).to be(true)
      end

      expect(surfaces.nil?       ).to be(false)
      expect(surfaces.is_a?(Hash)).to be( true)
      expect(surfaces.size       ).to eq(   18)
      expect(io.nil?             ).to be(false)
      expect(io.is_a?(Hash)      ).to be( true)
      expect(io.empty?           ).to be(false)
      expect(io.key?(:edges     )).to be( true)

      surfaces.values.each do |surface|
        expect(surface.is_a?(Hash)        ).to be(true)
        expect(surface.key?(:conditioned )).to be(true)
        expect(surface.key?(:deratable   )).to be(true)
        expect(surface.key?(:construction)).to be(true)
        expect(surface.key?(:ground      )).to be(true)

        next     if surface[:ground   ]
        next unless surface[:deratable]

        id = surface[:construction].nameString
        ok = id.include?("BTAP-Ext-Roof") || id.include?("BTAP-Ext-Wall")
        expect(ok).to be(true)
      end

      # Once done, ensure temporary schedule is dissociated from the thermostat
      # and deleted from the model.
      tstat.resetHeatingSetpointTemperatureSchedule
      expect(tstat.getHeatingSchedule.empty?).to be(true)

      sched2 = model.getScheduleByName(identifier)
      expect(sched2.empty?   ).to be(false)
      sched.remove
      sched2 = model.getScheduleByName(identifier)
      expect(sched2.empty?   ).to be( true)
      heat   = TBD.maxHeatScheduledSetpoint(zone)
      expect(heat.nil?       ).to be(false)
      expect(heat.is_a?(Hash)).to be( true)
      expect(heat.key?(:spt )).to be( true)
      expect(heat.key?(:dual)).to be( true)
      expect(heat[:spt ].nil?).to be( true)
      expect(heat[:dual]     ).to be(false)

      expect(TBD.plenum?(attic, loops, setpoints)).to be(false) # as before ...
    end
  end

  it "validate (uprated) BTAP output" do
    v = OpenStudio.openStudioVersion.split(".").map(&:to_i).join.to_i

    if v > 300
      TBD.clean!

      argh                = {}
      argh[:schema_path ] = File.join(__dir__, "../tbd.schema.json")
      argh[:io_path     ] = File.join(__dir__, "../json/tbd_resto_btap.json")
      argh[:uprate_walls] = true
      argh[:wall_option ] = "ALL wall constructions"
      argh[:wall_ut     ] = 0.210               # NECB CZ7 2017 (RSi 4.76 / R27)

      tr    = OpenStudio::OSVersion::VersionTranslator.new
      file  = File.join(__dir__, "files/osms/in/resto.osm")
      path  = OpenStudio::Path.new(file)
      model = tr.loadModel(path)
      expect(model.empty?).to be(false)
      model = model.get
      net   = 0
      gross = 0

      model.getSurfaces.each do |surface|
        next unless surface.outsideBoundaryCondition.downcase == "outdoors"
        next unless surface.surfaceType.downcase == "wall"

        net   += surface.netArea
        gross += surface.grossArea
      end

      expect(net  ).to be_within(TOL).of(193.00)
      expect(gross).to be_within(TOL).of(275.72)
      fwdr = ( gross - net ) * 100 / gross
      expect(fwdr).to be_within(TOL).of(30.00)

      json      = TBD.process(model, argh)
      expect(json.is_a?(Hash    )).to be( true)
      expect(json.key?(:io      )).to be( true)
      expect(json.key?(:surfaces)).to be( true)
      io        = json[:io      ]
      surfaces  = json[:surfaces]
      expect(TBD.error?          ).to be(false)
      expect(TBD.logs.empty?     ).to be( true)

      expect(argh.key?(:wall_uo)).to be(true)
      expect(argh[:wall_uo]     ).to be_within(TOL).of(0.00236) # RSi 423 (R2K)
    end
  end

  it "can process floorszone multipliers" do
    TBD.clean!
    argh           = {}
    argh[:option ] = "code (Quebec)"

    file  = File.join(__dir__, "files/osms/in/midrise_KIVA.osm")
    path  = OpenStudio::Path.new(file)
    tr    = OpenStudio::OSVersion::VersionTranslator.new
    model = tr.loadModel(path)
    expect(model.empty?).to be(false)
    model = model.get

    json      = TBD.process(model, argh)
    expect(json.is_a?(Hash)    ).to be(true)
    expect(json.key?(:io      )).to be(true)
    expect(json.key?(:surfaces)).to be(true)
    io        = json[:io      ]
    surfaces  = json[:surfaces]
    expect(TBD.status.zero?    ).to be(true)
    expect(TBD.logs.empty?     ).to be(true)

    model.getSurfaces.each do |surface|
      id = surface.nameString
      next unless surface.surfaceType.downcase == "floor"
      next     if surface.isGroundSurface

      facing = surface.outsideBoundaryCondition.downcase
      floor  = id.downcase.include?("floor")
      top    = id.downcase.include?("t ")
      mid    = id.downcase.include?("m ")
      expect(floor && (top || mid)).to be(true)
      expect(facing).to eq("adiabatic")

      io[:edges].each do |edge|
        next unless edge[:surfaces].include?(id)

        expect(edge[:type]).to eq(:rimjoist)
      end
    end
  end
end
