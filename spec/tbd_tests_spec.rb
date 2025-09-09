require "tbd"

RSpec.describe TBD_Tests do
  TOL  = TBD::TOL.dup
  TOL2 = TBD::TOL2.dup
  DBG  = TBD::DBG.dup
  INF  = TBD::INF.dup
  WRN  = TBD::WRN.dup
  ERR  = TBD::ERR.dup
  FTL  = TBD::FTL.dup
  DMIN = TBD::DMIN.dup
  DMAX = TBD::DMAX.dup
  KMIN = TBD::KMIN.dup
  KMAX = TBD::KMAX.dup
  UMAX = TBD::UMAX.dup
  UMIN = TBD::UMIN.dup
  RMIN = TBD::RMIN.dup
  RMAX = TBD::RMAX.dup

  it "can process thermal bridging and derating: LoScrigno" do
    expect(TBD.level     ).to eq(INF)
    expect(TBD.reset(DBG)).to eq(DBG)
    expect(TBD.level     ).to eq(DBG)
    expect(TBD.clean!    ).to eq(DBG)
    # The following populates OpenStudio and Topolys models of "Lo Scrigno"
    # (or Jewel Box), by Renzo Piano (Lingotto Factory, Turin); a cantilevered,
    # single space art gallery (space #1) above a supply plenum with slanted
    # undersides (space #2), and resting on four main pillars.

    # The first ~800 lines generate the OpenStudio model from scratch, relying
    # the OpenStudio SDK and SketchUp-fed 3D surface vertices. It would be
    # easier to simply read in the saved .osm file (1x-time generation) of the
    # model. The generation code is maintained as is for debugging purposes
    # (e.g. SketchUp-reported vertices are +/- accurate). The remaining 1/3
    # of this first RSpec reproduces TBD's 'process' method. It is repeated
    # step-by-step here for detailed testing purposes.
    model    = OpenStudio::Model::Model.new
    building = model.getBuilding

    os_s = OpenStudio::Model::ShadingSurfaceGroup.new(model)
    # For the purposes of the RSpec, vertical access (elevator and stairs,
    # normally fully glazed) are modelled as (opaque) extensions of either
    # space. Surfaces are prefixed as follows:
    #   - "g_" : art gallery
    #   - "p_" : underfloor plenum (supplying gallery)
    #   - "s_" : stairwell (leading to/through plenum & gallery)
    #   - "e_" : (side) elevator leading to gallery
    os_g = OpenStudio::Model::Space.new(model) # gallery & elevator
    os_p = OpenStudio::Model::Space.new(model) # plenum & stairwell
    os_g.setName("scrigno_gallery")
    os_p.setName( "scrigno_plenum")

    # For the purposes of the spec, all opaque envelope assemblies are built up
    # from a single, 3-layered construction. All subsurfaces are Simple Glazing
    # constructions.
    construction = OpenStudio::Model::Construction.new(model)
    fenestration = OpenStudio::Model::Construction.new(model)
    elevator     = OpenStudio::Model::Construction.new(model)
    shadez       = OpenStudio::Model::Construction.new(model)
    glazing      = OpenStudio::Model::SimpleGlazing.new(model)
    exterior     = OpenStudio::Model::MasslessOpaqueMaterial.new(model)
    xps8x25mm    = OpenStudio::Model::MasslessOpaqueMaterial.new(model)
    insulation   = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    interior     = OpenStudio::Model::StandardOpaqueMaterial.new(model)

    construction.setName("scrigno_construction")
    fenestration.setName("scrigno_fen")
    elevator.setName("elevator")
    shadez.setName("scrigno_shading")
    glazing.setName("scrigno_glazing")
    exterior.setName("scrigno_exterior")
    xps8x25mm.setName("xps8x25mm")
    insulation.setName("scrigno_insulation")
    interior.setName("scrigno_interior")

    # Material properties.
    expect(exterior.setRoughness("Rough"        )).to be true
    expect(insulation.setRoughness("MediumRough")).to be true
    expect(interior.setRoughness("MediumRough"  )).to be true
    expect(xps8x25mm.setRoughness("Rough"       )).to be true

    expect(glazing.setUFactor(                 2.0000)).to be true
    expect(glazing.setSolarHeatGainCoefficient(0.5000)).to be true
    expect(glazing.setVisibleTransmittance(    0.7000)).to be true

    expect(exterior.setThermalResistance(      0.3626)).to be true
    expect(exterior.setThermalAbsorptance(     0.9000)).to be true
    expect(exterior.setSolarAbsorptance(       0.7000)).to be true
    expect(exterior.setVisibleAbsorptance(     0.7000)).to be true

    expect(insulation.setThickness(            0.1184)).to be true
    expect(insulation.setConductivity(         0.0450)).to be true
    expect(insulation.setDensity(            265.0000)).to be true
    expect(insulation.setSpecificHeat(       836.8000)).to be true
    expect(insulation.setThermalAbsorptance(   0.9000)).to be true
    expect(insulation.setSolarAbsorptance(     0.7000)).to be true
    expect(insulation.setVisibleAbsorptance(   0.7000)).to be true

    expect(interior.setThickness(              0.0126)).to be true
    expect(interior.setConductivity(           0.1600)).to be true
    expect(interior.setDensity(              784.9000)).to be true
    expect(interior.setSpecificHeat(         830.0000)).to be true
    expect(interior.setThermalAbsorptance(     0.9000)).to be true
    expect(interior.setSolarAbsorptance(       0.9000)).to be true
    expect(interior.setVisibleAbsorptance(     0.9000)).to be true

    expect(xps8x25mm.setThermalResistance( 8 * 0.8800)).to be true
    expect(xps8x25mm.setThermalAbsorptance(    0.9000)).to be true
    expect(xps8x25mm.setSolarAbsorptance(      0.7000)).to be true
    expect(xps8x25mm.setVisibleAbsorptance(    0.7000)).to be true

    # Layered constructions.
    layers = OpenStudio::Model::MaterialVector.new
    layers << glazing
    expect(fenestration.setLayers(layers)).to be true

    layers = OpenStudio::Model::MaterialVector.new
    layers << exterior
    layers << insulation
    layers << interior
    expect(construction.setLayers(layers)).to be true

    layers  = OpenStudio::Model::MaterialVector.new
    layers << exterior
    layers << xps8x25mm
    layers << interior
    expect(elevator.setLayers(layers)).to be true

    layers  = OpenStudio::Model::MaterialVector.new
    layers << exterior
    expect(shadez.setLayers(layers)).to be true

    defaults = OpenStudio::Model::DefaultSurfaceConstructions.new(model)
    subs     = OpenStudio::Model::DefaultSubSurfaceConstructions.new(model)
    set      = OpenStudio::Model::DefaultConstructionSet.new(model)

    expect(defaults.setWallConstruction(          construction)).to be true
    expect(defaults.setRoofCeilingConstruction(   construction)).to be true
    expect(defaults.setFloorConstruction(         construction)).to be true
    expect(subs.setFixedWindowConstruction(       fenestration)).to be true
    expect(subs.setOperableWindowConstruction(    fenestration)).to be true
    expect(subs.setDoorConstruction(              fenestration)).to be true
    expect(subs.setGlassDoorConstruction(         fenestration)).to be true
    expect(subs.setOverheadDoorConstruction(      fenestration)).to be true
    expect(subs.setSkylightConstruction(          fenestration)).to be true
    expect(set.setAdiabaticSurfaceConstruction(   construction)).to be true
    expect(set.setInteriorPartitionConstruction(  construction)).to be true
    expect(set.setDefaultExteriorSurfaceConstructions(defaults)).to be true
    expect(set.setDefaultInteriorSurfaceConstructions(defaults)).to be true
    expect(set.setDefaultInteriorSubSurfaceConstructions( subs)).to be true
    expect(set.setDefaultExteriorSubSurfaceConstructions( subs)).to be true
    expect(set.setSpaceShadingConstruction(             shadez)).to be true
    expect(set.setBuildingShadingConstruction(          shadez)).to be true
    expect(set.setSiteShadingConstruction(              shadez)).to be true
    expect(building.setDefaultConstructionSet(             set)).to be true

    # Set building shading surfaces:
    # (4x above gallery roof + 2x North/South balconies)
    os_v  = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 12.4, 45.0, 50.0)
    os_v << OpenStudio::Point3d.new( 12.4, 25.0, 50.0)
    os_v << OpenStudio::Point3d.new( 22.7, 25.0, 50.0)
    os_v << OpenStudio::Point3d.new( 22.7, 45.0, 50.0)

    os_r1_shade = OpenStudio::Model::ShadingSurface.new(os_v, model)
    os_r1_shade.setName("r1_shade")
    expect(os_r1_shade.setShadingSurfaceGroup(os_s)).to be true

    os_v  = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 22.7, 45.0, 50.0)
    os_v << OpenStudio::Point3d.new( 22.7, 37.5, 50.0)
    os_v << OpenStudio::Point3d.new( 48.7, 37.5, 50.0)
    os_v << OpenStudio::Point3d.new( 48.7, 45.0, 50.0)

    os_r2_shade = OpenStudio::Model::ShadingSurface.new(os_v, model)
    os_r2_shade.setName("r2_shade")
    expect(os_r2_shade.setShadingSurfaceGroup(os_s)).to be true

    os_v  = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 22.7, 32.5, 50.0)
    os_v << OpenStudio::Point3d.new( 22.7, 25.0, 50.0)
    os_v << OpenStudio::Point3d.new( 48.7, 25.0, 50.0)
    os_v << OpenStudio::Point3d.new( 48.7, 32.5, 50.0)

    os_r3_shade = OpenStudio::Model::ShadingSurface.new(os_v, model)
    os_r3_shade.setName("r3_shade")
    expect(os_r3_shade.setShadingSurfaceGroup(os_s)).to be true

    os_v  = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 48.7, 45.0, 50.0)
    os_v << OpenStudio::Point3d.new( 48.7, 25.0, 50.0)
    os_v << OpenStudio::Point3d.new( 59.0, 25.0, 50.0)
    os_v << OpenStudio::Point3d.new( 59.0, 45.0, 50.0)

    os_r4_shade = OpenStudio::Model::ShadingSurface.new(os_v, model)
    os_r4_shade.setName("r4_shade")
    expect(os_r4_shade.setShadingSurfaceGroup(os_s)).to be true

    os_v  = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 47.4, 40.2, 44.0)
    os_v << OpenStudio::Point3d.new( 47.4, 41.7, 44.0)
    os_v << OpenStudio::Point3d.new( 45.7, 41.7, 44.0)
    os_v << OpenStudio::Point3d.new( 45.7, 40.2, 44.0)

    os_N_balcony = OpenStudio::Model::ShadingSurface.new(os_v, model)
    os_N_balcony.setName("N_balcony") # 1.70m as thermal bridge
    expect(os_N_balcony.setShadingSurfaceGroup(os_s)).to be true

    os_v  = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 28.1, 29.8, 44.0)
    os_v << OpenStudio::Point3d.new( 28.1, 28.3, 44.0)
    os_v << OpenStudio::Point3d.new( 47.4, 28.3, 44.0)
    os_v << OpenStudio::Point3d.new( 47.4, 29.8, 44.0)

    os_S_balcony = OpenStudio::Model::ShadingSurface.new(os_v, model)
    os_S_balcony.setName("S_balcony") # 19.3m as thermal bridge
    expect(os_S_balcony.setShadingSurfaceGroup(os_s)).to be true

    # 1st space: gallery (g) with elevator (e) surfaces
    os_v  = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 17.4, 40.2, 49.5)
    os_v << OpenStudio::Point3d.new( 17.4, 40.2, 44.0)
    os_v << OpenStudio::Point3d.new( 17.4, 29.8, 44.0)
    os_v << OpenStudio::Point3d.new( 17.4, 29.8, 49.5)

    os_g_W_wall = OpenStudio::Model::Surface.new(os_v, model)
    os_g_W_wall.setName("g_W_wall")
    expect(os_g_W_wall.setSpace(os_g)).to be true
    expect(os_g_W_wall.surfaceType.downcase).to eq("wall")
    expect(os_g_W_wall.isConstructionDefaulted).to be true

    c = set.getDefaultConstruction(os_g_W_wall).get.to_LayeredConstruction.get
    expect(c.numLayers).to eq(3)
    expect(c.isOpaque).to be true
    expect(c.nameString).to eq("scrigno_construction")

    os_v  = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 54.0, 40.2, 49.5)
    os_v << OpenStudio::Point3d.new( 54.0, 40.2, 44.0)
    os_v << OpenStudio::Point3d.new( 17.4, 40.2, 44.0)
    os_v << OpenStudio::Point3d.new( 17.4, 40.2, 49.5)

    os_g_N_wall = OpenStudio::Model::Surface.new(os_v, model)
    os_g_N_wall.setName("g_N_wall")
    expect(os_g_N_wall.setSpace(os_g)).to be true
    expect(os_g_N_wall.uFactor).to_not be_empty
    expect(os_g_N_wall.uFactor.get).to be_within(TOL).of(0.31)

    os_v  = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 47.4, 40.2, 46.0)
    os_v << OpenStudio::Point3d.new( 47.4, 40.2, 44.0)
    os_v << OpenStudio::Point3d.new( 46.4, 40.2, 44.0)
    os_v << OpenStudio::Point3d.new( 46.4, 40.2, 46.0)

    os_g_N_door = OpenStudio::Model::SubSurface.new(os_v, model)
    os_g_N_door.setName("g_N_door")
    expect(os_g_N_door.setSubSurfaceType("GlassDoor")).to be true
    expect(os_g_N_door.setSurface(os_g_N_wall)).to be true
    expect(os_g_N_door.uFactor).to_not be_empty
    expect(os_g_N_door.uFactor.get).to be_within(TOL).of(2.00)

    os_v  = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 54.0, 29.8, 49.5)
    os_v << OpenStudio::Point3d.new( 54.0, 29.8, 44.0)
    os_v << OpenStudio::Point3d.new( 54.0, 40.2, 44.0)
    os_v << OpenStudio::Point3d.new( 54.0, 40.2, 49.5)

    os_g_E_wall = OpenStudio::Model::Surface.new(os_v, model)
    os_g_E_wall.setName("g_E_wall")
    expect(os_g_E_wall.setSpace(os_g)).to be true

    os_v  = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 17.4, 29.8, 49.5)
    os_v << OpenStudio::Point3d.new( 17.4, 29.8, 44.0)
    os_v << OpenStudio::Point3d.new( 24.0, 29.8, 44.0)
    os_v << OpenStudio::Point3d.new( 24.0, 29.8, 49.5)

    os_g_S1_wall = OpenStudio::Model::Surface.new(os_v, model)
    os_g_S1_wall.setName("g_S1_wall")
    expect(os_g_S1_wall.setSpace(os_g)).to be true
    expect(os_g_S1_wall.uFactor).to_not be_empty
    expect(os_g_S1_wall.uFactor.get).to be_within(TOL).of(0.31)

    os_v  = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 24.0, 29.8, 49.5)
    os_v << OpenStudio::Point3d.new( 24.0, 29.8, 46.7)
    os_v << OpenStudio::Point3d.new( 28.0, 29.8, 46.7)
    os_v << OpenStudio::Point3d.new( 28.0, 29.8, 49.5)

    os_g_S2_wall = OpenStudio::Model::Surface.new(os_v, model)
    os_g_S2_wall.setName("g_S2_wall")
    expect(os_g_S2_wall.setSpace(os_g)).to be true
    expect(os_g_S2_wall.uFactor).to_not be_empty
    expect(os_g_S2_wall.uFactor.get).to be_within(TOL).of(0.31)

    os_v  = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 28.0, 29.8, 49.5)
    os_v << OpenStudio::Point3d.new( 28.0, 29.8, 44.0)
    os_v << OpenStudio::Point3d.new( 54.0, 29.8, 44.0)
    os_v << OpenStudio::Point3d.new( 54.0, 29.8, 49.5)

    os_g_S3_wall = OpenStudio::Model::Surface.new(os_v, model)
    os_g_S3_wall.setName("g_S3_wall")
    expect(os_g_S3_wall.setSpace(os_g)).to be true
    expect(os_g_S3_wall.uFactor).to_not be_empty
    expect(os_g_S3_wall.uFactor.get).to be_within(TOL).of(0.31)

    os_v  = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 46.4, 29.8, 46.0)
    os_v << OpenStudio::Point3d.new( 46.4, 29.8, 44.0)
    os_v << OpenStudio::Point3d.new( 47.4, 29.8, 44.0)
    os_v << OpenStudio::Point3d.new( 47.4, 29.8, 46.0)

    os_g_S3_door = OpenStudio::Model::SubSurface.new(os_v, model)
    os_g_S3_door.setName("g_S3_door")
    expect(os_g_S3_door.setSubSurfaceType("GlassDoor")).to be true
    expect(os_g_S3_door.setSurface(os_g_S3_wall)).to be true
    expect(os_g_S3_door.uFactor).to_not be_empty
    expect(os_g_S3_door.uFactor.get).to be_within(TOL).of(2.00)

    os_v  = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 17.4, 40.2, 49.5)
    os_v << OpenStudio::Point3d.new( 17.4, 29.8, 49.5)
    os_v << OpenStudio::Point3d.new( 54.0, 29.8, 49.5)
    os_v << OpenStudio::Point3d.new( 54.0, 40.2, 49.5)

    os_g_top = OpenStudio::Model::Surface.new(os_v, model)
    os_g_top.setName("g_top")
    expect(os_g_top.setSpace(os_g)).to be true
    expect(os_g_top.uFactor).to_not be_empty
    expect(os_g_top.uFactor.get).to be_within(TOL).of(0.31)
    expect(os_g_top.surfaceType.downcase).to eq("roofceiling")
    expect(os_g_top.isConstructionDefaulted).to be true

    c = set.getDefaultConstruction(os_g_top).get.to_LayeredConstruction.get
    expect(c.numLayers).to eq(3)
    expect(c.isOpaque).to be true
    expect(c.nameString).to eq("scrigno_construction")

    # Leaving a 1" strip of rooftop (0.915 m2) so roof m2 > skylight m2.
    os_v  = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 17.4, 40.2        , 49.5)
    os_v << OpenStudio::Point3d.new( 17.4, 29.8 + 0.025, 49.5)
    os_v << OpenStudio::Point3d.new( 54.0, 29.8 + 0.025, 49.5)
    os_v << OpenStudio::Point3d.new( 54.0, 40.2        , 49.5)

    os_g_sky = OpenStudio::Model::SubSurface.new(os_v, model)
    os_g_sky.setName("g_sky")
    expect(os_g_sky.setSurface(os_g_top)).to be true

    os_v  = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 24.0, 29.8, 46.7)
    os_v << OpenStudio::Point3d.new( 24.0, 28.3, 46.7)
    os_v << OpenStudio::Point3d.new( 28.0, 28.3, 46.7)
    os_v << OpenStudio::Point3d.new( 28.0, 29.8, 46.7)

    os_e_top = OpenStudio::Model::Surface.new(os_v, model)
    os_e_top.setName("e_top")
    expect(os_e_top.setSpace(os_g)).to be true

    os_v  = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 24.0, 28.3, 40.8)
    os_v << OpenStudio::Point3d.new( 24.0, 29.8, 40.8)
    os_v << OpenStudio::Point3d.new( 28.0, 29.8, 40.8)
    os_v << OpenStudio::Point3d.new( 28.0, 28.3, 40.8)

    os_e_floor = OpenStudio::Model::Surface.new(os_v, model)
    os_e_floor.setName("e_floor")
    expect(os_e_floor.setSpace(os_g)).to be true
    expect(os_e_floor.setOutsideBoundaryCondition("Outdoors")).to be true
    expect(os_e_floor.surfaceType.downcase).to eq("floor")
    expect(os_e_floor.isConstructionDefaulted).to be true

    c = set.getDefaultConstruction(os_e_floor).get.to_LayeredConstruction.get
    expect(c.numLayers).to eq(3)
    expect(c.isOpaque).to be true
    expect(c.nameString).to eq("scrigno_construction")
    expect(os_e_floor.setConstruction(elevator)).to be true
    expect(os_e_floor.isConstructionDefaulted).to be false

    c = os_e_floor.construction.get.to_LayeredConstruction.get
    expect(c.numLayers).to eq(3)
    expect(c.isOpaque).to be true
    expect(c.nameString).to eq("elevator")

    os_v  = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 24.0, 29.8, 46.7)
    os_v << OpenStudio::Point3d.new( 24.0, 29.8, 40.8)
    os_v << OpenStudio::Point3d.new( 24.0, 28.3, 40.8)
    os_v << OpenStudio::Point3d.new( 24.0, 28.3, 46.7)

    os_e_W_wall = OpenStudio::Model::Surface.new(os_v, model)
    os_e_W_wall.setName("e_W_wall")
    expect(os_e_W_wall.setSpace(os_g)).to be true

    os_v  = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 24.0, 28.3, 46.7)
    os_v << OpenStudio::Point3d.new( 24.0, 28.3, 40.8)
    os_v << OpenStudio::Point3d.new( 28.0, 28.3, 40.8)
    os_v << OpenStudio::Point3d.new( 28.0, 28.3, 46.7)

    os_e_S_wall = OpenStudio::Model::Surface.new(os_v, model)
    os_e_S_wall.setName("e_S_wall")
    expect(os_e_S_wall.setSpace(os_g)).to be true

    os_v  = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 28.0, 28.3, 46.7)
    os_v << OpenStudio::Point3d.new( 28.0, 28.3, 40.8)
    os_v << OpenStudio::Point3d.new( 28.0, 29.8, 40.8)
    os_v << OpenStudio::Point3d.new( 28.0, 29.8, 46.7)

    os_e_E_wall = OpenStudio::Model::Surface.new(os_v, model)
    os_e_E_wall.setName("e_E_wall")
    expect(os_e_E_wall.setSpace(os_g)).to be true

    os_v  = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 28.0, 29.8, 42.4060)
    os_v << OpenStudio::Point3d.new( 28.0, 29.8, 40.8000)
    os_v << OpenStudio::Point3d.new( 24.0, 29.8, 40.8000)
    os_v << OpenStudio::Point3d.new( 24.0, 29.8, 43.0075)

    os_e_N_wall = OpenStudio::Model::Surface.new(os_v, model)
    os_e_N_wall.setName("e_N_wall")
    expect(os_e_N_wall.setSpace(os_g)).to be true

    os_v  = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 28.0, 29.8, 44.0000)
    os_v << OpenStudio::Point3d.new( 28.0, 29.8, 42.4060)
    os_v << OpenStudio::Point3d.new( 24.0, 29.8, 43.0075)
    os_v << OpenStudio::Point3d.new( 24.0, 29.8, 44.0000)

    os_e_p_wall = OpenStudio::Model::Surface.new(os_v, model)
    os_e_p_wall.setName("e_p_wall")
    expect(os_e_p_wall.setSpace(os_g)).to be true

    os_v  = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 17.4, 29.8, 44.0)
    os_v << OpenStudio::Point3d.new( 17.4, 40.2, 44.0)
    os_v << OpenStudio::Point3d.new( 54.0, 40.2, 44.0)
    os_v << OpenStudio::Point3d.new( 54.0, 29.8, 44.0)

    os_g_floor = OpenStudio::Model::Surface.new(os_v, model)
    os_g_floor.setName("g_floor")
    expect(os_g_floor.setSpace(os_g) ).to be true

    # 2nd space: plenum (p) with stairwell (s) surfaces
    os_v  = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 17.4, 40.2, 44.0)
    os_v << OpenStudio::Point3d.new( 17.4, 29.8, 44.0)
    os_v << OpenStudio::Point3d.new( 54.0, 29.8, 44.0)
    os_v << OpenStudio::Point3d.new( 54.0, 40.2, 44.0)

    os_p_top = OpenStudio::Model::Surface.new(os_v, model)
    os_p_top.setName("p_top")
    expect(os_p_top.setSpace(os_p)).to be true
    expect(os_p_top.setAdjacentSurface(os_g_floor)).to be true
    expect(os_g_floor.setAdjacentSurface(os_p_top)).to be true
    expect(os_p_top.setOutsideBoundaryCondition(  "Surface")).to be true
    expect(os_g_floor.setOutsideBoundaryCondition("Surface")).to be true

    os_v  = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 24.0, 29.8, 44.0000)
    os_v << OpenStudio::Point3d.new( 24.0, 29.8, 43.0075)
    os_v << OpenStudio::Point3d.new( 28.0, 29.8, 42.4060)
    os_v << OpenStudio::Point3d.new( 28.0, 29.8, 44.0000)

    os_p_e_wall = OpenStudio::Model::Surface.new(os_v, model)
    os_p_e_wall.setName("p_e_wall")
    expect(os_p_e_wall.setSpace(os_p)).to be true
    expect(os_e_p_wall.setAdjacentSurface(os_p_e_wall)).to be true
    expect(os_p_e_wall.setAdjacentSurface(os_e_p_wall)).to be true
    expect(os_p_e_wall.setOutsideBoundaryCondition("Surface")).to be true
    expect(os_e_p_wall.setOutsideBoundaryCondition("Surface")).to be true

    os_v  = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 17.4, 29.8, 44.0000)
    os_v << OpenStudio::Point3d.new( 24.0, 29.8, 43.0075)
    os_v << OpenStudio::Point3d.new( 24.0, 29.8, 44.0000)

    os_p_S1_wall = OpenStudio::Model::Surface.new(os_v, model)
    os_p_S1_wall.setName("p_S1_wall")
    expect(os_p_S1_wall.setSpace(os_p)).to be true

    os_v  = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 28.0, 29.8, 44.0000)
    os_v << OpenStudio::Point3d.new( 28.0, 29.8, 42.4060)
    os_v << OpenStudio::Point3d.new( 30.7, 29.8, 42.0000)
    os_v << OpenStudio::Point3d.new( 40.7, 29.8, 42.0000)
    os_v << OpenStudio::Point3d.new( 54.0, 29.8, 44.0000)

    os_p_S2_wall = OpenStudio::Model::Surface.new(os_v, model)
    os_p_S2_wall.setName("p_S2_wall")
    expect(os_p_S2_wall.setSpace(os_p)).to be true

    os_v  = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 54.0, 40.2, 44.0)
    os_v << OpenStudio::Point3d.new( 40.7, 40.2, 42.0)
    os_v << OpenStudio::Point3d.new( 30.7, 40.2, 42.0)
    os_v << OpenStudio::Point3d.new( 17.4, 40.2, 44.0)

    os_p_N_wall = OpenStudio::Model::Surface.new(os_v, model)
    os_p_N_wall.setName("p_N_wall")
    expect(os_p_N_wall.setSpace(os_p)).to be true

    os_v  = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 30.7, 29.8, 42.0)
    os_v << OpenStudio::Point3d.new( 30.7, 40.2, 42.0)
    os_v << OpenStudio::Point3d.new( 40.7, 40.2, 42.0)
    os_v << OpenStudio::Point3d.new( 40.7, 29.8, 42.0)

    os_p_floor = OpenStudio::Model::Surface.new(os_v, model)
    os_p_floor.setName("p_floor")
    expect(os_p_floor.setSpace(os_p)).to be true
    expect(os_p_floor.setOutsideBoundaryCondition("Outdoors")).to be true

    os_v  = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 40.7, 29.8, 42.0)
    os_v << OpenStudio::Point3d.new( 40.7, 40.2, 42.0)
    os_v << OpenStudio::Point3d.new( 54.0, 40.2, 44.0)
    os_v << OpenStudio::Point3d.new( 54.0, 29.8, 44.0)

    os_p_E_floor = OpenStudio::Model::Surface.new(os_v, model)
    os_p_E_floor.setName("p_E_floor")
    expect(os_p_E_floor.setSpace(os_p)).to be true
    expect(os_p_E_floor.setSurfaceType("Floor")).to be true # walls by default

    os_v  = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 17.4, 29.8, 44.0000)
    os_v << OpenStudio::Point3d.new( 17.4, 40.2, 44.0000)
    os_v << OpenStudio::Point3d.new( 24.0, 40.2, 43.0075)
    os_v << OpenStudio::Point3d.new( 24.0, 29.8, 43.0075)

    os_p_W1_floor = OpenStudio::Model::Surface.new(os_v, model)
    os_p_W1_floor.setName("p_W1_floor")
    expect(os_p_W1_floor.setSpace(os_p)).to be true
    expect(os_p_W1_floor.setSurfaceType("Floor")).to be true

    os_v  = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 24.0, 29.8, 43.0075)
    os_v << OpenStudio::Point3d.new( 24.0, 33.1, 43.0075)
    os_v << OpenStudio::Point3d.new( 30.7, 33.1, 42.0000)
    os_v << OpenStudio::Point3d.new( 30.7, 29.8, 42.0000)

    os_p_W2_floor = OpenStudio::Model::Surface.new(os_v, model)
    os_p_W2_floor.setName("p_W2_floor")
    expect(os_p_W2_floor.setSpace(os_p)).to be true
    expect(os_p_W2_floor.setSurfaceType("Floor")).to be true

    os_v  = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 24.0, 36.9, 43.0075)
    os_v << OpenStudio::Point3d.new( 24.0, 40.2, 43.0075)
    os_v << OpenStudio::Point3d.new( 30.7, 40.2, 42.0000)
    os_v << OpenStudio::Point3d.new( 30.7, 36.9, 42.0000)

    os_p_W3_floor = OpenStudio::Model::Surface.new(os_v, model)
    os_p_W3_floor.setName("p_W3_floor")
    expect(os_p_W3_floor.setSpace(os_p)).to be true
    expect(os_p_W3_floor.setSurfaceType("Floor")).to be true

    os_v  = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 29.0, 33.1, 42.2556)
    os_v << OpenStudio::Point3d.new( 29.0, 36.9, 42.2556)
    os_v << OpenStudio::Point3d.new( 30.7, 36.9, 42.0000)
    os_v << OpenStudio::Point3d.new( 30.7, 33.1, 42.0000)

    os_p_W4_floor = OpenStudio::Model::Surface.new(os_v, model)
    os_p_W4_floor.setName("p_W4_floor")
    expect(os_p_W4_floor.setSpace(os_p)).to be true
    expect(os_p_W4_floor.setSurfaceType("Floor")).to be true

    os_v  = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 24.0, 36.9, 43.0075)
    os_v << OpenStudio::Point3d.new( 24.0, 36.9, 40.8000)
    os_v << OpenStudio::Point3d.new( 24.0, 33.1, 40.8000)
    os_v << OpenStudio::Point3d.new( 24.0, 33.1, 43.0075)

    os_s_W_wall = OpenStudio::Model::Surface.new(os_v, model)
    os_s_W_wall.setName("s_W_wall")
    expect(os_s_W_wall.setSpace(os_p)).to be true

    os_v  = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 29.0, 36.9, 42.2556)
    os_v << OpenStudio::Point3d.new( 29.0, 36.9, 40.8000)
    os_v << OpenStudio::Point3d.new( 24.0, 36.9, 40.8000)
    os_v << OpenStudio::Point3d.new( 24.0, 36.9, 43.0075)

    os_s_N_wall = OpenStudio::Model::Surface.new(os_v, model)
    os_s_N_wall.setName("s_N_wall")
    expect(os_s_N_wall.setSpace(os_p)).to be true

    os_v  = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 29.0, 33.1, 42.2556)
    os_v << OpenStudio::Point3d.new( 29.0, 33.1, 40.8000)
    os_v << OpenStudio::Point3d.new( 29.0, 36.9, 40.8000)
    os_v << OpenStudio::Point3d.new( 29.0, 36.9, 42.2556)

    os_s_E_wall = OpenStudio::Model::Surface.new(os_v, model)
    os_s_E_wall.setName("s_E_wall")
    expect(os_s_E_wall.setSpace(os_p)).to be true

    os_v  = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 24.0, 33.1, 43.0075)
    os_v << OpenStudio::Point3d.new( 24.0, 33.1, 40.8000)
    os_v << OpenStudio::Point3d.new( 29.0, 33.1, 40.8000)
    os_v << OpenStudio::Point3d.new( 29.0, 33.1, 42.2556)

    os_s_S_wall = OpenStudio::Model::Surface.new(os_v, model)
    os_s_S_wall.setName("s_S_wall")
    expect(os_s_S_wall.setSpace(os_p)).to be true

    os_v  = OpenStudio::Point3dVector.new
    os_v << OpenStudio::Point3d.new( 24.0, 33.1, 40.8)
    os_v << OpenStudio::Point3d.new( 24.0, 36.9, 40.8)
    os_v << OpenStudio::Point3d.new( 29.0, 36.9, 40.8)
    os_v << OpenStudio::Point3d.new( 29.0, 33.1, 40.8)

    os_s_floor = OpenStudio::Model::Surface.new(os_v, model)
    os_s_floor.setName("s_floor")
    expect(os_s_floor.setSpace(os_p)).to be true
    expect(os_s_floor.setSurfaceType("Floor")).to be true
    expect(os_s_floor.setOutsideBoundaryCondition("Outdoors")).to be true

    # Assign thermal zones.
    model.getSpaces.each do |space|
      zone = OpenStudio::Model::ThermalZone.new(model)
      zone.setName("#{space.nameString}|zone")
      space.setThermalZone(zone)
    end

    pth = File.join(__dir__, "files/osms/out/loscrigno.osm")
    model.save(pth, true)


    t_model  = Topolys::Model.new
    argh     = { setpoints: false, parapet: true }
    surfaces = {}

    model.getSurfaces.sort_by { |s| s.nameString }.each do |s|
      surface = TBD.properties(s, argh)
      expect(surface).to_not be_nil
      expect(surface).to be_a(Hash)
      expect(surface).to have_key(:space)

      surfaces[s.nameString] = surface
    end

    expect(surfaces.size).to eq(31)

    surfaces.each do |id, surface|
      expect(surface[:conditioned]).to be true
      expect(surface).to have_key(:heating)
      expect(surface).to have_key(:cooling)
    end

    surfaces.each do |id, surface|
      expect(surface).to_not have_key(:deratable)
      surface[:deratable] = false
      next     if surface[:ground     ]
      next unless surface[:conditioned]

      unless surface[:boundary].downcase == "outdoors"
        next unless surfaces.key?(surface[:boundary])
        next     if surfaces[surface[:boundary]][:conditioned]
      end

      expect(surface).to have_key(:index)
      surface[:deratable] = true
    end

    [:windows, :doors, :skylights].each do |holes| # sort kids
      surfaces.values.each do |surface|
        next unless surface.key?(holes)

        surface[holes] = surface[holes].sort_by { |_, s| s[:minz] }.to_h
      end
    end

    expect(surfaces["g_top"    ]).to have_key(:type)
    expect(surfaces["g_S1_wall"]).to have_key(:type)
    expect(surfaces["g_S2_wall"]).to have_key(:type)
    expect(surfaces["g_S3_wall"]).to have_key(:type)
    expect(surfaces["g_N_wall" ]).to have_key(:type)

    expect(surfaces["g_top"    ]).to have_key(:skylights)
    expect(surfaces["g_top"    ]).to_not have_key(:windows)
    expect(surfaces["g_top"    ]).to_not have_key(:doors)

    expect(surfaces["g_S1_wall"]).to_not have_key(:skylights)
    expect(surfaces["g_S1_wall"]).to_not have_key(:windows)
    expect(surfaces["g_S1_wall"]).to_not have_key(:doors)

    expect(surfaces["g_S2_wall"]).to_not have_key(:skylights)
    expect(surfaces["g_S2_wall"]).to_not have_key(:windows)
    expect(surfaces["g_S2_wall"]).to_not have_key(:doors)

    expect(surfaces["g_S3_wall"]).to_not have_key(:skylights)
    expect(surfaces["g_S3_wall"]).to_not have_key(:windows)
    expect(surfaces["g_S3_wall"]).to have_key(:doors)

    expect(surfaces["g_N_wall"]).to_not have_key(:skylights)
    expect(surfaces["g_N_wall"]).to_not have_key(:windows)
    expect(surfaces["g_N_wall"]).to have_key(:doors)

    expect(surfaces["g_top"    ][:skylights].size).to eq(1)
    expect(surfaces["g_S3_wall"][:doors    ].size).to eq(1)
    expect(surfaces["g_N_wall" ][:doors    ].size).to eq(1)
    expect(surfaces["g_top"    ][:skylights]).to have_key("g_sky")
    expect(surfaces["g_S3_wall"][:doors    ]).to have_key("g_S3_door")
    expect(surfaces["g_N_wall" ][:doors    ]).to have_key("g_N_door")

    # Split "surfaces" hash into "floors", "ceilings" and "walls" hashes.
    floors   = surfaces.select  { |_, s|  s[:type] == :floor   }
    ceilings = surfaces.select  { |_, s|  s[:type] == :ceiling }
    walls    = surfaces.select  { |_, s|  s[:type] == :wall    }

    floors   = floors.sort_by   { |_, s| [s[:minz], s[:space]] }.to_h
    ceilings = ceilings.sort_by { |_, s| [s[:minz], s[:space]] }.to_h
    walls    = walls.sort_by    { |_, s| [s[:minz], s[:space]] }.to_h

    expect(floors.size  ).to eq( 9) # 7
    expect(ceilings.size).to eq( 3)
    expect(walls.size   ).to eq(19) # 17

    # Fetch OpenStudio shading surfaces & key attributes.
    shades = {}

    model.getShadingSurfaces.each do |s|
      expect(s.shadingSurfaceGroup).to_not be_empty
      id      = s.nameString
      group   = s.shadingSurfaceGroup.get
      shading = group.to_ShadingSurfaceGroup
      tr      = TBD.transforms(group)

      expect(tr).to be_a(Hash)
      expect(tr).to have_key(:t)
      expect(tr).to have_key(:r)
      t = tr[:t]
      r = tr[:r]
      expect(t).to_not be_nil
      expect(r).to_not be_nil

      expect(shading).to_not be_empty
      empty = shading.get.space.empty?
      r    += shading.get.space.get.directionofRelativeNorth unless empty
      n     = TBD.trueNormal(s, r)
      expect(n).to_not be_nil

      points = (t * s.vertices).map{ |v| Topolys::Point3D.new(v.x, v.y, v.z) }

      minz = (points.map{ |p| p.z }).min

      shades[id] = { group: group, points: points, minz: minz, n: n }
    end

    expect(shades.size).to eq(6)

    # Mutually populate TBD & Topolys surfaces. Keep track of created "holes".
    holes         = {}
    floor_holes   = TBD.dads(t_model, floors)
    ceiling_holes = TBD.dads(t_model, ceilings)
    wall_holes    = TBD.dads(t_model, walls)

    holes.merge!(floor_holes)
    holes.merge!(ceiling_holes)
    holes.merge!(wall_holes)

    expect(floor_holes       ).to be_empty
    expect(ceiling_holes.size).to eq(1)
    expect(wall_holes.size   ).to eq(2)
    expect(holes.size        ).to eq(3)

    floors.values.each do |props| # testing normals
      t_x = props[:face].outer.plane.normal.x
      t_y = props[:face].outer.plane.normal.y
      t_z = props[:face].outer.plane.normal.z

      expect(props[:n].x).to be_within(0.001).of(t_x)
      expect(props[:n].y).to be_within(0.001).of(t_y)
      expect(props[:n].z).to be_within(0.001).of(t_z)
    end

    # OpenStudio (opaque) surfaces VS number of Topolys (opaque) faces.
    expect(surfaces.size     ).to eq(31)
    expect(t_model.faces.size).to eq(31)

    TBD.dads(t_model, shades)
    expect(t_model.faces.size).to eq(37)

    # Loop through Topolys edges and populate TBD edge hash. Initially, there
    # should be a one-to-one correspondence between Topolys and TBD edge
    # objects. Use Topolys-generated identifiers as unique edge hash keys.
    edges = {}

    holes.each do |id, wire| # start with hole edges
      wire.edges.each do |e|
        i  = e.id
        l  = e.length
        ex = edges.key?(i)

        edges[i] = { length: l, v0: e.v0, v1: e.v1, surfaces: {} } unless ex

        next if edges[i][:surfaces].key?(wire.attributes[:id])

        edges[i][:surfaces][wire.attributes[:id]] = { wire: wire.id }
      end
    end

    expect(edges.size).to eq(12)

    # Next, floors, ceilings & walls; then shades.
    TBD.faces(floors, edges)

    expect(edges.size).to eq(51)

    TBD.faces(ceilings, edges)
    expect(edges.size).to eq(60)

    TBD.faces(walls, edges)
    expect(edges.size).to eq(78)

    TBD.faces(shades, edges)
    expect(        edges.size).to eq(100)
    expect(t_model.edges.size).to eq(100)

    # edges.values.each do |edge|
    #   puts "#{'%5.2f' % edge[:length]}m #{edge[:surfaces].keys.to_a}"
    # end
    # 10.38m ["g_sky", "g_top", "g_W_wall"]
    # 36.60m ["g_sky", "g_top"]
    # 10.38m ["g_sky", "g_top", "g_E_wall"]
    # 36.60m ["g_sky", "g_top", "g_N_wall"]
    #  2.00m ["g_N_door", "g_N_wall"]
    #  1.00m ["g_N_door", "g_floor", "p_top", "p_N_wall", "g_N_wall", "N_balcony"]
    #  2.00m ["g_N_door", "g_N_wall"]
    #  1.00m ["g_N_door", "g_N_wall"]
    #  2.00m ["g_S3_door", "g_S3_wall"]
    #  1.00m ["g_S3_door", "g_floor", "p_top", "p_S2_wall", "g_S3_wall", "S_balcony"]
    #  2.00m ["g_S3_door", "g_S3_wall"]
    #  1.00m ["g_S3_door", "g_S3_wall"]
    #  1.50m ["e_floor", "e_W_wall"]
    #  4.00m ["e_floor", "e_N_wall"]
    #  1.50m ["e_floor", "e_E_wall"]
    #  4.00m ["e_floor", "e_S_wall"]
    #  3.80m ["s_floor", "s_W_wall"]
    #  5.00m ["s_floor", "s_N_wall"]
    #  3.80m ["s_floor", "s_E_wall"]
    #  5.00m ["s_floor", "s_S_wall"]
    # 10.40m ["p_E_floor", "p_floor"]
    # 13.45m ["p_E_floor", "p_N_wall"]
    # 10.40m ["p_E_floor", "g_floor", "p_top", "g_E_wall"]
    # 13.45m ["p_E_floor", "p_S2_wall"]
    #  3.30m ["p_W2_floor", "p_W1_floor"]
    #  5.06m ["p_W2_floor", "s_S_wall"]
    #  1.72m ["p_W2_floor", "p_W4_floor"]
    #  3.30m ["p_W2_floor", "p_floor"]
    #  2.73m ["p_W2_floor", "p_S2_wall"]
    #  4.04m ["p_W2_floor", "e_N_wall", "e_p_wall", "p_e_wall"]
    #  3.80m ["p_floor", "p_W4_floor"]
    #  3.30m ["p_floor", "p_W3_floor"]
    # 10.00m ["p_floor", "p_N_wall"]
    # 10.00m ["p_floor", "p_S2_wall"]
    #  3.80m ["p_W4_floor", "s_E_wall"]
    #  1.72m ["p_W4_floor", "p_W3_floor"]
    #  3.30m ["p_W3_floor", "p_W1_floor"]
    #  6.78m ["p_W3_floor", "p_N_wall"]
    #  5.06m ["p_W3_floor", "s_N_wall"]
    # 10.40m ["p_W1_floor", "g_floor", "p_top", "g_W_wall"]
    #  6.67m ["p_W1_floor", "p_N_wall"]
    #  3.80m ["p_W1_floor", "s_W_wall"]
    #  6.67m ["p_W1_floor", "p_S1_wall"]
    # 28.30m ["g_floor", "p_top", "p_N_wall", "g_N_wall"]
    #  0.70m ["g_floor", "p_top", "p_N_wall", "g_N_wall", "N_balcony"]
    #  6.60m ["g_floor", "p_top", "p_N_wall", "g_N_wall"]
    #  6.60m ["g_floor", "p_top", "p_S2_wall", "g_S3_wall"]
    # 18.30m ["g_floor", "p_top", "p_S2_wall", "g_S3_wall", "S_balcony"]
    #  0.10m ["g_floor", "p_top", "p_S2_wall", "g_S3_wall"]
    #  4.00m ["g_floor", "p_top", "e_p_wall", "p_e_wall"]
    #  6.60m ["g_floor", "p_top", "p_S1_wall", "g_S1_wall"]
    #  1.50m ["e_top", "e_W_wall"]
    #  4.00m ["e_top", "e_S_wall"]
    #  1.50m ["e_top", "e_E_wall"]
    #  4.00m ["e_top", "g_S2_wall"]
    #  0.02m ["g_top", "g_W_wall"]
    #  6.60m ["g_top", "g_S1_wall"]
    #  4.00m ["g_top", "g_S2_wall"]
    # 26.00m ["g_top", "g_S3_wall"]
    #  0.02m ["g_top", "g_E_wall"]
    #  5.90m ["e_E_wall", "e_S_wall"]
    #  1.61m ["e_E_wall", "e_N_wall"]
    #  1.59m ["e_E_wall", "p_S2_wall", "e_p_wall", "p_e_wall"]
    #  2.70m ["e_E_wall", "g_S3_wall"]
    #  2.21m ["e_N_wall", "e_W_wall"]
    #  5.90m ["e_S_wall", "e_W_wall"]
    #  2.70m ["e_W_wall", "g_S1_wall"]
    #  0.99m ["e_W_wall", "e_p_wall", "p_e_wall", "p_S1_wall"]
    #  2.21m ["s_S_wall", "s_W_wall"]
    #  1.46m ["s_S_wall", "s_E_wall"]
    #  1.46m ["s_N_wall", "s_E_wall"]
    #  2.21m ["s_N_wall", "s_W_wall"]
    #  5.50m ["g_W_wall", "g_N_wall"]
    #  5.50m ["g_W_wall", "g_S1_wall"]
    #  2.80m ["g_S1_wall", "g_S2_wall"]
    #  5.50m ["g_N_wall", "g_E_wall"]
    #  5.50m ["g_E_wall", "g_S3_wall"]
    #  2.80m ["g_S3_wall", "g_S2_wall"]
    #  1.50m ["S_balcony"]
    # 19.30m ["S_balcony"]
    #  1.50m ["S_balcony"]
    #  1.50m ["N_balcony"]
    #  1.70m ["N_balcony"]
    #  1.50m ["N_balcony"]
    #  7.50m ["r3_shade", "r1_shade"]
    # 26.00m ["r3_shade"]
    #  7.50m ["r3_shade", "r4_shade"]
    # 26.00m ["r3_shade"]
    #  7.50m ["r2_shade", "r1_shade"]
    # 26.00m ["r2_shade"]
    #  7.50m ["r2_shade", "r4_shade"]
    # 26.00m ["r2_shade"]
    #  5.00m ["r4_shade"]
    # 10.30m ["r4_shade"]
    # 20.00m ["r4_shade"]
    # 10.30m ["r4_shade"]
    # 20.00m ["r1_shade"]
    # 10.30m ["r1_shade"]
    #  5.00m ["r1_shade"]
    # 10.30m ["r1_shade"]

    # The following surfaces should all share an edge.
    p_S2_wall_face = walls["p_S2_wall"][:face]
    e_p_wall_face  = walls["e_p_wall" ][:face]
    p_e_wall_face  = walls["p_e_wall" ][:face]
    e_E_wall_face  = walls["e_E_wall" ][:face]

    p_S2_wall_edge_ids = Set.new(p_S2_wall_face.outer.edges.map{ |oe| oe.id} )
    e_p_wall_edges_ids = Set.new( e_p_wall_face.outer.edges.map{ |oe| oe.id} )
    p_e_wall_edges_ids = Set.new( p_e_wall_face.outer.edges.map{ |oe| oe.id} )
    e_E_wall_edges_ids = Set.new( e_E_wall_face.outer.edges.map{ |oe| oe.id} )

    intersection = p_S2_wall_edge_ids &
                   e_p_wall_edges_ids &
                   p_e_wall_edges_ids
    expect(intersection.size).to eq(1)

    intersection = p_S2_wall_edge_ids &
                   e_p_wall_edges_ids &
                   p_e_wall_edges_ids &
                   e_E_wall_edges_ids
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
    p_top_face    = ceilings["p_top"][:face]
    g_floor_wire  = g_floor_face.outer
    g_floor_edges = g_floor_wire.edges
    p_top_wire    = p_top_face.outer
    p_top_edges   = p_top_wire.edges
    shared_edges  = p_top_face.shared_outer_edges(g_floor_face)

    expect(g_floor_edges.size).to be > 4
    expect(g_floor_edges.size).to eq(p_top_edges.size)
    expect( shared_edges.size).to eq(p_top_edges.size)

    g_floor_edges.each do |g_floor_edge|
      expect(p_top_edges.find { |e| e.id == g_floor_edge.id } ).to be_truthy
    end

    expect(floors.size  ).to eq( 9)
    expect(ceilings.size).to eq( 3)
    expect(walls.size   ).to eq(19)
    expect(shades.size  ).to eq( 6)

    zenith = Topolys::Vector3D.new(0, 0, 1).freeze
    north  = Topolys::Vector3D.new(0, 1, 0).freeze
    east   = Topolys::Vector3D.new(1, 0, 0).freeze

    edges.values.each do |edge|
      origin     = edge[:v0].point
      terminal   = edge[:v1].point
      dx         = (origin.x - terminal.x).abs
      dy         = (origin.y - terminal.y).abs
      dz         = (origin.z - terminal.z).abs
      horizontal = dz.abs < TOL
      vertical   = dx < TOL && dy < TOL
      edge_V     = terminal - origin
      expect(edge_V.magnitude > TOL).to be true
      edge_plane = Topolys::Plane3D.new(origin, edge_V)

      if vertical
        reference_V = north.dup
      elsif horizontal
        reference_V = zenith.dup
      else
        reference   = edge_plane.project(origin + zenith)
        reference_V = reference - origin
      end

      edge[:surfaces].each do |id, surface|
        t_model.wires.each do |wire|
          next unless surface[:wire] == wire.id

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

            point_on_plane    = edge_plane.project(point)
            origin_point_V    = point_on_plane - origin
            point_V_magnitude = origin_point_V.magnitude
            next unless point_V_magnitude > TOL

            if inverted
              plane = Topolys::Plane3D.from_points(terminal, origin, point)
            else
              plane = Topolys::Plane3D.from_points(origin, terminal, point)
            end

            dnx = (normal.x - plane.normal.x).abs
            dny = (normal.y - plane.normal.y).abs
            dnz = (normal.z - plane.normal.z).abs
            next unless dnx < TOL && dny < TOL && dnz < TOL

            farther    = point_V_magnitude > farthest_V.magnitude
            farthest   = point          if farther
            farthest_V = origin_point_V if farther
          end

          angle = edge_V.angle(farthest_V)
          expect(angle).to be_within(TOL).of(Math::PI / 2)
          angle = reference_V.angle(farthest_V)

          adjust = false

          if vertical
            adjust = true if east.dot(farthest_V) < -TOL
          else
            dN  = north.dot(farthest_V)
            dN1 = north.dot(farthest_V).abs - 1

            if dN.abs < TOL || dN1.abs < TOL
              adjust = true if east.dot(farthest_V) < -TOL
            else
              adjust = true if dN < -TOL
            end
          end

          angle  = 2 * Math::PI - angle if adjust
          angle -= 2 * Math::PI         if (angle - 2 * Math::PI).abs < TOL
          surface[:angle ] = angle
          farthest_V.normalize!
          surface[:polar ] = farthest_V
          surface[:normal] = normal
        end # end of edge-linked, surface-to-wire loop
      end # end of edge-linked surface loop

      edge[:horizontal] = horizontal
      edge[:vertical  ] = vertical
      edge[:surfaces  ] = edge[:surfaces].sort_by{ |i, p| p[:angle] }.to_h
    end # end of edge loop

    expect(edges.size        ).to eq(100)
    expect(t_model.edges.size).to eq(100)

    argh[:option] = "poor (BETBG)"
    expect(argh.size).to eq(3)

    json = TBD.inputs(surfaces, edges, argh)
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty

    expect(argh.size).to eq(5)
    expect(argh).to have_key(:option)
    expect(argh).to have_key(:setpoints)
    expect(argh).to have_key(:parapet)
    expect(argh).to have_key(:io_path)
    expect(argh).to have_key(:schema_path)

    expect(argh[:option     ]).to eq("poor (BETBG)")
    expect(argh[:setpoints  ]).to be false
    expect(argh[:parapet    ]).to be true
    expect(argh[:io_path    ]).to be_nil
    expect(argh[:schema_path]).to be_nil

    expect(json).to be_a(Hash)
    expect(json).to have_key(:psi)
    expect(json).to have_key(:khi)
    expect(json).to have_key(:io)

    expect(json[:psi]).to be_a(TBD::PSI)
    expect(json[:khi]).to be_a(TBD::KHI)
    expect(json[:io ]).to_not be_empty
    expect(json[:io ]).to have_key(:building)
    expect(json[:io ][:building]).to have_key(:psi)

    psi    = json[:io][:building][:psi]
    shorts = json[:psi].shorthands(psi)
    expect(shorts[:has]).to_not be_empty
    expect(shorts[:val]).to_not be_empty

    edges.values.each do |edge|
      next unless edge.key?(:surfaces)

      deratables = []
      set        = {}

      edge[:surfaces].keys.each do |id|
        next unless surfaces.key?(id)

        deratables << id if surfaces[id][:deratable]
      end

      next if deratables.empty?

      edge[:surfaces].keys.each do |id|
        next unless surfaces.key?(id)
        next unless deratables.include?(id)

        # Evaluate current set content before processing a new linked surface.
        is               = {}
        is[:head        ] = set.keys.to_s.include?("head")
        is[:sill        ] = set.keys.to_s.include?("sill")
        is[:jamb        ] = set.keys.to_s.include?("jamb")
        is[:doorhead    ] = set.keys.to_s.include?("doorhead")
        is[:doorsill    ] = set.keys.to_s.include?("doorsill")
        is[:doorjamb    ] = set.keys.to_s.include?("doorjamb")
        is[:skylighthead] = set.keys.to_s.include?("skylighthead")
        is[:skylightsill] = set.keys.to_s.include?("skylightsill")
        is[:skylightjamb] = set.keys.to_s.include?("skylightjamb")
        is[:spandrel    ] = set.keys.to_s.include?("spandrel")
        is[:corner      ] = set.keys.to_s.include?("corner")
        is[:parapet     ] = set.keys.to_s.include?("parapet")
        is[:roof        ] = set.keys.to_s.include?("roof")
        is[:party       ] = set.keys.to_s.include?("party")
        is[:grade       ] = set.keys.to_s.include?("grade")
        is[:balcony     ] = set.keys.to_s.include?("balcony")
        is[:balconysill ] = set.keys.to_s.include?("balconysill")
        is[:rimjoist    ] = set.keys.to_s.include?("rimjoist")

        # Label edge as ...
        #         :head,         :sill,         :jamb (vertical fenestration)
        #     :doorhead,     :doorsill,     :doorjamb (opaque door)
        # :skylighthead, :skylightsill, :skylightjamb (all other cases)
        #
        # ... if linked to:
        #   1x subsurface (vertical or non-vertical)
        edge[:surfaces].keys.each do |i|
          break    if is[:head        ]
          break    if is[:sill        ]
          break    if is[:jamb        ]
          break    if is[:doorhead    ]
          break    if is[:doorsill    ]
          break    if is[:doorjamb    ]
          break    if is[:skylighthead]
          break    if is[:skylightsill]
          break    if is[:skylightjamb]
          next     if deratables.include?(i)
          next unless holes.key?(i)

          # In most cases, subsurface edges simply delineate the rough opening
          # of its base surface (here, a "gardian"). Door sills, corner windows,
          # as well as a subsurface header aligned with a plenum "floor"
          # (ceiling tiles), are common instances where a subsurface edge links
          # 2x (opaque) surfaces. Deratable surface "id" may not be the gardian
          # of subsurface "i" - the latter may be a neighbour. The single
          # "target" surface to derate is not the gardian in such cases.
          gardian = deratables.size == 1 ? id : ""
          target  = gardian

          # Retrieve base surface's subsurfaces.
          windows   = surfaces[id].key?(:windows)
          doors     = surfaces[id].key?(:doors)
          skylights = surfaces[id].key?(:skylights)

          windows   =   windows ? surfaces[id][:windows  ] : {}
          doors     =     doors ? surfaces[id][:doors    ] : {}
          skylights = skylights ? surfaces[id][:skylights] : {}

          # The gardian is "id" if subsurface "ids" holds "i".
          ids = windows.keys + doors.keys + skylights.keys

          if gardian.empty?
            other = deratables.first == id ? deratables.last : deratables.first

            gardian = ids.include?(i) ?    id : other
            target  = ids.include?(i) ? other : id

            windows   = surfaces[gardian].key?(:windows)
            doors     = surfaces[gardian].key?(:doors)
            skylights = surfaces[gardian].key?(:skylights)

            windows   =   windows ? surfaces[gardian][:windows  ] : {}
            doors     =     doors ? surfaces[gardian][:doors    ] : {}
            skylights = skylights ? surfaces[gardian][:skylights] : {}

            ids = windows.keys + doors.keys + skylights.keys
          end

          unless ids.include?(i)
            log(ERR, "Orphaned subsurface #{i} (mth)")
            next
          end

          window   =   windows.key?(i) ?   windows[i] : {}
          door     =     doors.key?(i) ?     doors[i] : {}
          skylight = skylights.key?(i) ? skylights[i] : {}

          sub = window   unless window.empty?
          sub = door     unless door.empty?
          sub = skylight unless skylight.empty?

          window = sub[:type] == :window
          door   = sub[:type] == :door
          glazed = door && sub.key?(:glazed) && sub[:glazed]

          s1      = edge[:surfaces][target]
          s2      = edge[:surfaces][i     ]
          concave = TBD.concave?(s1, s2)
          convex  = TBD.convex?(s1, s2)
          flat    = !concave && !convex

          # Subsurface edges are tagged as head, sill or jamb, regardless of
          # building PSI set subsurface-related tags. If the latter is simply
          # :fenestration, then its single PSI factor is systematically
          # assigned to e.g. a window's :head, :sill & :jamb edges.
          #
          # Additionally, concave or convex variants also inherit from the base
          # type if undefined in the PSI set.
          #
          # If a subsurface is not horizontal, TBD tags any horizontal edge as
          # either :head or :sill based on the polar angle of the subsurface
          # around the edge vs sky zenith. Otherwise, all other subsurface edges
          # are tagged as :jamb.
          if ((s2[:normal].dot(zenith)).abs - 1).abs < TOL # horizontal surface
            if glazed || window
              set[:jamb       ] = shorts[:val][:jamb       ] if flat
              set[:jambconcave] = shorts[:val][:jambconcave] if concave
              set[:jambconvex ] = shorts[:val][:jambconvex ] if convex
               is[:jamb       ] = true
            elsif door
              set[:doorjamb       ] = shorts[:val][:doorjamb       ] if flat
              set[:doorjambconcave] = shorts[:val][:doorjambconcave] if concave
              set[:doorjambconvex ] = shorts[:val][:doorjambconvex ] if convex
               is[:doorjamb       ] = true
            else
              set[:skylightjamb       ] = shorts[:val][:skylightjamb       ] if flat
              set[:skylightjambconcave] = shorts[:val][:skylightjambconcave] if concave
              set[:skylightjambconvex ] = shorts[:val][:skylightjambconvex ] if convex
               is[:skylightjamb       ] = true
            end
          else
            if glazed || window
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
            elsif door
              if edge[:horizontal]
                if s2[:polar].dot(zenith) < 0

                  set[:doorhead       ] = shorts[:val][:doorhead       ] if flat
                  set[:doorheadconcave] = shorts[:val][:doorheadconcave] if concave
                  set[:doorheadconvex ] = shorts[:val][:doorheadconvex ] if convex
                   is[:doorhead       ] = true
                else
                  set[:doorsill       ] = shorts[:val][:doorsill       ] if flat
                  set[:doorsillconcave] = shorts[:val][:doorsillconcave] if concave
                  set[:doorsillconvex ] = shorts[:val][:doorsillconvex ] if convex
                   is[:doorsill       ] = true
                end
              else
                set[:doorjamb       ] = shorts[:val][:doorjamb       ] if flat
                set[:doorjambconcave] = shorts[:val][:doorjambconcave] if concave
                set[:doorjambconvex ] = shorts[:val][:doorjambconvex ] if convex
                 is[:doorjamb       ] = true
              end
            else
              if edge[:horizontal]
                if s2[:polar].dot(zenith) < 0
                  set[:skylighthead       ] = shorts[:val][:skylighthead       ] if flat
                  set[:skylightheadconcave] = shorts[:val][:skylightheadconcave] if concave
                  set[:skylightheadconvex ] = shorts[:val][:skylightheadconvex ] if convex
                   is[:skylighthead       ] = true
                else
                  set[:skylightsill       ] = shorts[:val][:skylightsill       ] if flat
                  set[:skylightsillconcave] = shorts[:val][:skylightsillconcave] if concave
                  set[:skylightsillconvex ] = shorts[:val][:skylightsillconvex ] if convex
                   is[:skylightsill       ] = true
                end
              else
                set[:skylightjamb       ] = shorts[:val][:skylightjamb       ] if flat
                set[:skylightjambconcave] = shorts[:val][:skylightjambconcave] if concave
                set[:skylightjambconvex ] = shorts[:val][:skylightjambconvex ] if convex
                 is[:skylightjamb       ] = true
              end
            end
          end
        end

        # Label edge as :spandrel if linked to:
        #   1x deratable, non-spandrel wall
        #   1x deratable, spandrel wall
        edge[:surfaces].keys.each do |i|
          break     if is[:spandrel]
          break unless deratables.size == 2
          break unless walls.key?(id)
          break unless walls[id][:spandrel]
          next      if i == id
          next  unless deratables.include?(i)
          next  unless walls.key?(i)
          next      if walls[i][:spandrel]

          s1      = edge[:surfaces][id]
          s2      = edge[:surfaces][i ]
          concave = TBD.concave?(s1, s2)
          convex  = TBD.convex?(s1, s2)
          flat    = !concave && !convex

          set[:spandrel       ] = shorts[:val][:spandrel       ] if flat
          set[:spandrelconcave] = shorts[:val][:spandrelconcave] if concave
          set[:spandrelconvex ] = shorts[:val][:spandrelconvex ] if convex
           is[:spandrel       ] = true
        end

        # Label edge as :cornerconcave or :cornerconvex if linked to:
        #   2x deratable walls & f(relative polar wall vectors around edge)
        edge[:surfaces].keys.each do |i|
          break     if is[:corner]
          break unless deratables.size == 2
          break unless walls.key?(id)
          next      if i == id
          next  unless deratables.include?(i)
          next  unless walls.key?(i)

          s1      = edge[:surfaces][id]
          s2      = edge[:surfaces][i ]
          concave = TBD.concave?(s1, s2)
          convex  = TBD.convex?(s1, s2)

          set[:cornerconcave] = shorts[:val][:cornerconcave] if concave
          set[:cornerconvex ] = shorts[:val][:cornerconvex ] if convex
           is[:corner       ] = true
        end

        # Label edge as :parapet/:roof if linked to:
        #   1x deratable wall
        #   1x deratable ceiling
        edge[:surfaces].keys.each do |i|
          break     if is[:parapet]
          break     if is[:roof   ]
          break unless deratables.size == 2
          break unless ceilings.key?(id)
          next      if i == id
          next  unless deratables.include?(i)
          next  unless walls.key?(i)

          s1      = edge[:surfaces][id]
          s2      = edge[:surfaces][i ]
          concave = TBD.concave?(s1, s2)
          convex  = TBD.convex?(s1, s2)
          flat    = !concave && !convex

          if argh[:parapet]
            set[:parapet       ] = shorts[:val][:parapet       ] if flat
            set[:parapetconcave] = shorts[:val][:parapetconcave] if concave
            set[:parapetconvex ] = shorts[:val][:parapetconvex ] if convex
             is[:parapet       ] = true
          else
            set[:roof       ] = shorts[:val][:roof       ] if flat
            set[:roofconcave] = shorts[:val][:roofconcave] if concave
            set[:roofconvex ] = shorts[:val][:roofconvex ] if convex
             is[:roof       ] = true
          end
        end

        # Label edge as :party if linked to:
        #   1x OtherSideCoefficients surface
        #   1x (only) deratable surface
        edge[:surfaces].keys.each do |i|
          break     if is[:party]
          break unless deratables.size == 1
          next      if i == id
          next  unless surfaces.key?(i)
          next      if holes.key?(i)
          next      if shades.key?(i)

          facing = surfaces[i][:boundary].downcase
          next unless facing == "othersidecoefficients"

          s1      = edge[:surfaces][id]
          s2      = edge[:surfaces][i ]
          concave = concave?(s1, s2)
          convex  = convex?(s1, s2)
          flat    = !concave && !convex

          set[:party       ] = shorts[:val][:party       ] if flat
          set[:partyconcave] = shorts[:val][:partyconcave] if concave
          set[:partyconvex ] = shorts[:val][:partyconvex ] if convex
           is[:party       ] = true
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

        # Label edge as :rimjoist, :balcony or :balconysill if linked to:
        #   1x deratable surface
        #   1x CONDITIONED floor
        #   1x shade (optional)
        #   1x subsurface (optional)
        balcony     = false
        balconysill = false

        edge[:surfaces].keys.each do |i|
          break if balcony
          next  if i == id

          balcony = shades.key?(i)
        end

        edge[:surfaces].keys.each do |i|
          break unless balcony
          break     if balconysill
          next      if i == id

          balconysill = holes.key?(i)
        end

        edge[:surfaces].keys.each do |i|
          break     if is[:rimjoist] || is[:balcony] || is[:balconysill]
          break unless deratables.size == 2
          break     if floors.key?(id)
          next      if i == id
          next  unless floors.key?(i)
          next  unless floors[i].key?(:conditioned)
          next  unless floors[i][:conditioned]
          next      if floors[i][:ground]

          other = deratables.first unless deratables.first == id
          other = deratables.last  unless deratables.last  == id
          other = id                   if deratables.size  == 1

          s1      = edge[:surfaces][id   ]
          s2      = edge[:surfaces][other]
          concave = TBD.concave?(s1, s2)
          convex  = TBD.convex?(s1, s2)
          flat    = !concave && !convex

          if balconysill
            set[:balconysill       ] = shorts[:val][:balconysill       ] if flat
            set[:balconysillconcave] = shorts[:val][:balconysillconcave] if concave
            set[:balconysillconvex ] = shorts[:val][:balconysillconvex ] if convex
             is[:balconysill       ] = true
          elsif balcony
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
        end # edge's surfaces loop
      end

      edge[:psi] = set unless set.empty?
      edge[:set] = psi unless set.empty?
    end # edge loop

    # Tracking (mild) transitions.
    transitions = {}

    edges.each do |tag, edge|
      trnz      = []
      deratable = false
      next     if edge.key?(:psi)
      next unless edge.key?(:surfaces)

      edge[:surfaces].keys.each do |id|
        next unless surfaces.key?(id)
        next unless surfaces[id][:deratable]

        deratable = surfaces[id][:deratable]
        trnz << id
      end

      next unless deratable

      edge[:psi] = { transition: 0.000 }
      edge[:set] = json[:io][:building][:psi]

      transitions[tag] = trnz unless trnz.empty?
    end

    # Lo Scrigno: such transitions occur between plenum floor plates.
    expect(transitions).to_not be_empty
    expect(transitions.size).to eq(10)
    # transitions.values.each { |trr| puts "#{trr}\n" }
    # ["p_E_floor" , "p_floor"   ] *
    # ["p_W2_floor", "p_W1_floor"] +
    # ["p_W4_floor", "p_W2_floor"] $
    # ["p_floor"   , "p_W2_floor"] *
    # ["p_floor"   , "p_W4_floor"] *
    # ["p_floor"   , "p_W3_floor"] *
    # ["p_W3_floor", "p_W4_floor"] $
    # ["p_W3_floor", "p_W1_floor"] +
    # ["g_S2_wall" , "g_S1_wall" ] !
    # ["g_S3_wall" , "g_S2_wall" ] !
    w1_count = 0

    transitions.values.each do |trnz|
      expect(trnz.size).to eq(2)

      if trnz.include?("g_S2_wall")     # !
        expect(trnz).to include("g_S1_wall").or include("g_S3_wall")
      elsif trnz.include?("p_W1_floor") # +
        w1_count += 1
        expect(trnz).to include("p_W2_floor").or include("p_W3_floor")
      elsif trnz.include?("p_floor")    # *
        expect(trnz).to_not include("p_W1_floor")
      else                              # $
        expect(trnz).to include("p_W4_floor")
      end
    end

    expect(w1_count).to eq(2)

    # At this stage, edges may have been tagged multiple times (e.g. :sill as
    # well as :balconysill); TBD has yet to make final edge type determinations.
    n_derating_edges                 = 0
    n_edges_at_grade                 = 0
    n_edges_as_balconies             = 0
    n_edges_as_balconysills          = 0
    n_edges_as_parapets              = 0
    n_edges_as_rimjoists             = 0
    n_edges_as_concave_rimjoists     = 0
    n_edges_as_convex_rimjoists      = 0
    n_edges_as_fenestrations         = 0
    n_edges_as_heads                 = 0
    n_edges_as_sills                 = 0
    n_edges_as_jambs                 = 0
    n_edges_as_concave_jambs         = 0
    n_edges_as_convex_jambs          = 0
    n_edges_as_doorheads             = 0
    n_edges_as_doorsills             = 0
    n_edges_as_doorjambs             = 0
    n_edges_as_doorconcave_jambs     = 0
    n_edges_as_doorconvex_jambs      = 0
    n_edges_as_skylightheads         = 0
    n_edges_as_skylightsills         = 0
    n_edges_as_skylightjambs         = 0
    n_edges_as_skylightconcave_jambs = 0
    n_edges_as_skylightconvex_jambs  = 0
    n_edges_as_corners               = 0
    n_edges_as_concave_corners       = 0
    n_edges_as_convex_corners        = 0
    n_edges_as_transitions           = 0

    edges.values.each do |edge|
      next unless edge.key?(:psi)

      n_derating_edges                 += 1
      n_edges_at_grade                 += 1 if edge[:psi].key?(:grade)
      n_edges_at_grade                 += 1 if edge[:psi].key?(:gradeconcave)
      n_edges_at_grade                 += 1 if edge[:psi].key?(:gradeconvex)
      n_edges_as_balconies             += 1 if edge[:psi].key?(:balcony)
      n_edges_as_balconysills          += 1 if edge[:psi].key?(:balconysill)
      n_edges_as_parapets              += 1 if edge[:psi].key?(:parapetconcave)
      n_edges_as_parapets              += 1 if edge[:psi].key?(:parapetconvex)
      n_edges_as_rimjoists             += 1 if edge[:psi].key?(:rimjoist)
      n_edges_as_concave_rimjoists     += 1 if edge[:psi].key?(:rimjoistconcave)
      n_edges_as_convex_rimjoists      += 1 if edge[:psi].key?(:rimjoistconvex)
      n_edges_as_fenestrations         += 1 if edge[:psi].key?(:fenestration)
      n_edges_as_heads                 += 1 if edge[:psi].key?(:head)
      n_edges_as_sills                 += 1 if edge[:psi].key?(:sill)
      n_edges_as_jambs                 += 1 if edge[:psi].key?(:jamb)
      n_edges_as_concave_jambs         += 1 if edge[:psi].key?(:jambconcave)
      n_edges_as_convex_jambs          += 1 if edge[:psi].key?(:jambconvex)
      n_edges_as_doorheads             += 1 if edge[:psi].key?(:doorhead)
      n_edges_as_doorsills             += 1 if edge[:psi].key?(:doorsill)
      n_edges_as_doorjambs             += 1 if edge[:psi].key?(:doorjamb)
      n_edges_as_doorconcave_jambs     += 1 if edge[:psi].key?(:doorjambconcave)
      n_edges_as_doorconvex_jambs      += 1 if edge[:psi].key?(:doorjambconvex)
      n_edges_as_skylightheads         += 1 if edge[:psi].key?(:skylighthead)
      n_edges_as_skylightsills         += 1 if edge[:psi].key?(:skylightsill)
      n_edges_as_skylightjambs         += 1 if edge[:psi].key?(:skylightjamb)
      n_edges_as_skylightconcave_jambs += 1 if edge[:psi].key?(:skylightjambconcave)
      n_edges_as_skylightconvex_jambs  += 1 if edge[:psi].key?(:skylightjambconvex)
      n_edges_as_corners               += 1 if edge[:psi].key?(:corner)
      n_edges_as_concave_corners       += 1 if edge[:psi].key?(:cornerconcave)
      n_edges_as_convex_corners        += 1 if edge[:psi].key?(:cornerconvex)
      n_edges_as_transitions           += 1 if edge[:psi].key?(:transition)
    end

    expect(n_derating_edges                ).to eq(77)
    expect(n_edges_at_grade                ).to eq( 0)
    expect(n_edges_as_balconies            ).to eq( 2) # not balconysills
    expect(n_edges_as_balconysills         ).to eq( 2) # == sills
    expect(n_edges_as_parapets             ).to eq(12) # 5x around rooftop strip
    expect(n_edges_as_rimjoists            ).to eq( 5)
    expect(n_edges_as_concave_rimjoists    ).to eq( 5)
    expect(n_edges_as_convex_rimjoists     ).to eq(18)
    expect(n_edges_as_fenestrations        ).to eq( 0)
    expect(n_edges_as_heads                ).to eq( 2) # "vertical fenestration"
    expect(n_edges_as_sills                ).to eq( 2) # == balcony sills
    expect(n_edges_as_jambs                ).to eq( 4)
    expect(n_edges_as_concave_jambs        ).to eq( 0)
    expect(n_edges_as_convex_jambs         ).to eq( 0)
    expect(n_edges_as_doorheads            ).to eq( 0) # "vertical fenestration"
    expect(n_edges_as_doorsills            ).to eq( 0) # "vertical fenestration"
    expect(n_edges_as_doorjambs            ).to eq( 0) # "vertical fenestration"
    expect(n_edges_as_doorconcave_jambs    ).to eq( 0) # "vertical fenestration"
    expect(n_edges_as_doorconvex_jambs     ).to eq( 0) # "vertical fenestration"
    expect(n_edges_as_skylightheads        ).to eq( 0)
    expect(n_edges_as_skylightsills        ).to eq( 0)
    expect(n_edges_as_skylightjambs        ).to eq( 1) # along 1" rooftop strip
    expect(n_edges_as_skylightconcave_jambs).to eq( 0)
    expect(n_edges_as_skylightconvex_jambs ).to eq( 3) # 3x parapet edges
    expect(n_edges_as_corners              ).to eq( 0)
    expect(n_edges_as_concave_corners      ).to eq( 4)
    expect(n_edges_as_convex_corners       ).to eq(12)
    expect(n_edges_as_transitions          ).to eq(10)

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

        deratables[id] = s if surfaces[id][:deratable]
      end

      edge[:surfaces].each { |id, s| apertures[id] = s if holes.key?(id) }
      next if apertures.size > 1 # edge links 2x openings

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
        expect(surfaces[id]).to have_key(:r)
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

      n_surfaces_to_derate += 1
      surface[:heatloss]    = 0
      e = surface[:edges].values

      e.each { |edge| surface[:heatloss] += edge[:psi] * edge[:length] }
    end

    expect(n_surfaces_to_derate).to eq(27) # if "poor (BETBG)"

    ["e_p_wall", "g_floor", "p_top", "p_e_wall"].each do |id|
      expect(surfaces[id]).to_not have_key(:heatloss)
    end

    # If "poor (BETBG)".
    expect(surfaces["e_E_wall"  ][:heatloss]).to be_within(TOL).of( 6.02)
    expect(surfaces["e_N_wall"  ][:heatloss]).to be_within(TOL).of( 4.73)
    expect(surfaces["e_S_wall"  ][:heatloss]).to be_within(TOL).of( 7.70)
    expect(surfaces["e_W_wall"  ][:heatloss]).to be_within(TOL).of( 6.02)
    expect(surfaces["e_floor"   ][:heatloss]).to be_within(TOL).of( 8.01)
    expect(surfaces["e_top"     ][:heatloss]).to be_within(TOL).of( 4.40)
    expect(surfaces["g_E_wall"  ][:heatloss]).to be_within(TOL).of(18.19)
    expect(surfaces["g_N_wall"  ][:heatloss]).to be_within(TOL).of(54.25)
    expect(surfaces["g_S1_wall" ][:heatloss]).to be_within(TOL).of( 9.43)
    expect(surfaces["g_S2_wall" ][:heatloss]).to be_within(TOL).of( 3.20)
    expect(surfaces["g_S3_wall" ][:heatloss]).to be_within(TOL).of(28.88)
    expect(surfaces["g_W_wall"  ][:heatloss]).to be_within(TOL).of(18.19)
    expect(surfaces["g_top"     ][:heatloss]).to be_within(TOL).of(32.96)
    expect(surfaces["p_E_floor" ][:heatloss]).to be_within(TOL).of(18.65)
    expect(surfaces["p_N_wall"  ][:heatloss]).to be_within(TOL).of(37.25)
    expect(surfaces["p_S1_wall" ][:heatloss]).to be_within(TOL).of( 7.06)
    expect(surfaces["p_S2_wall" ][:heatloss]).to be_within(TOL).of(27.27)
    expect(surfaces["p_W1_floor"][:heatloss]).to be_within(TOL).of(13.77)
    expect(surfaces["p_W2_floor"][:heatloss]).to be_within(TOL).of( 5.92)
    expect(surfaces["p_W3_floor"][:heatloss]).to be_within(TOL).of( 5.92)
    expect(surfaces["p_W4_floor"][:heatloss]).to be_within(TOL).of( 1.90)
    expect(surfaces["p_floor"   ][:heatloss]).to be_within(TOL).of(10.00)
    expect(surfaces["s_E_wall"  ][:heatloss]).to be_within(TOL).of( 5.04)
    expect(surfaces["s_N_wall"  ][:heatloss]).to be_within(TOL).of( 6.58)
    expect(surfaces["s_S_wall"  ][:heatloss]).to be_within(TOL).of( 6.58)
    expect(surfaces["s_W_wall"  ][:heatloss]).to be_within(TOL).of( 5.68)
    expect(surfaces["s_floor"   ][:heatloss]).to be_within(TOL).of( 8.80)

    surfaces.each do |id, surface|
      next unless surface.key?(:construction)
      next unless surface.key?(:index)
      next unless surface.key?(:ltype)
      next unless surface.key?(:r)
      next unless surface.key?(:edges)
      next unless surface.key?(:heatloss)
      next unless surface[:heatloss].abs > TOL

      s = model.getSurfaceByName(id)
      next if s.empty?

      s = s.get

      index     = surface[:index       ]
      current_c = surface[:construction]
      c         = current_c.clone(model).to_LayeredConstruction.get
      m         = nil
      m         = TBD.derate(id, surface, c) if index

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
              cc         = current_cc.clone(model).to_LayeredConstruction.get
              cc.setLayer(surfaces[nom][:index], m)
              cc.setName("#{nom} c tbd")
              adjacent.setConstruction(cc)
            end
          end
        end
      end
    end

    floors.each do |id, floor|
      next unless floor.key?(:edges)

      s = model.getSurfaceByName(id)
      expect(s).to_not be_empty
      expect(s.get.isConstructionDefaulted).to be false
      expect(s.get.construction.get.nameString).to include(" tbd")
    end

    ceilings.each do |id, ceiling|
      next unless ceiling.key?(:edges)

      s = model.getSurfaceByName(id)
      expect(s).to_not be_empty
      expect(s.get.isConstructionDefaulted).to be false
      expect(s.get.construction.get.nameString).to include(" tbd")
    end

    walls.each do |id, wall|
      next unless wall.key?(:edges)

      s = model.getSurfaceByName(id)
      expect(s).to_not be_empty
      expect(s.get.isConstructionDefaulted).to be false
      expect(s.get.construction.get.nameString).to include(" tbd")
    end
  end

  it "can check for balcony sills (ASHRAE 90.1 2022)" do
    translator = OpenStudio::OSVersion::VersionTranslator.new
    TBD.clean!

    # "Lo Scrigno" (or Jewel Box), by Renzo Piano (Lingotto Factory, Turin); a
    # cantilevered, single space art gallery (space #1) above a supply plenum
    # with slanted undersides (space #2) resting on four main pillars.
    file  = File.join(__dir__, "files/osms/out/loscrigno.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    argh = { option: "90.1.22|steel.m|default" }

    json     = TBD.process(model, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty
    expect(surfaces).to be_a Hash
    expect(surfaces.size).to eq(31)
    expect(io).to be_a(Hash)
    expect(io).to have_key(:edges)
    expect(io[:edges].size).to eq(77)

    n_edges_at_grade             = 0
    n_edges_as_balconies         = 0
    n_edges_as_balconysills      = 0
    n_edges_as_balconydoorsills  = 0
    n_edges_as_concave_parapets  = 0
    n_edges_as_convex_parapets   = 0
    n_edges_as_concave_roofs     = 0
    n_edges_as_convex_roofs      = 0
    n_edges_as_rimjoists         = 0
    n_edges_as_concave_rimjoists = 0
    n_edges_as_convex_rimjoists  = 0
    n_edges_as_fenestrations     = 0
    n_edges_as_heads             = 0
    n_edges_as_sills             = 0
    n_edges_as_jambs             = 0
    n_edges_as_doorheads         = 0
    n_edges_as_doorsills         = 0
    n_edges_as_doorjambs         = 0
    n_edges_as_skylightjambs     = 0
    n_edges_as_concave_jambs     = 0
    n_edges_as_convex_jambs      = 0
    n_edges_as_corners           = 0
    n_edges_as_concave_corners   = 0
    n_edges_as_convex_corners    = 0
    n_edges_as_transitions       = 0

    io[:edges].each do |edge|
      expect(edge).to have_key(:type)

      n_edges_at_grade             += 1 if edge[:type] == :grade
      n_edges_at_grade             += 1 if edge[:type] == :gradeconcave
      n_edges_at_grade             += 1 if edge[:type] == :gradeconvex
      n_edges_as_balconies         += 1 if edge[:type] == :balcony
      n_edges_as_balconies         += 1 if edge[:type] == :balconyconcave
      n_edges_as_balconies         += 1 if edge[:type] == :balconyconvex
      n_edges_as_balconysills      += 1 if edge[:type] == :balconysill
      n_edges_as_balconysills      += 1 if edge[:type] == :balconysillconcave
      n_edges_as_balconysills      += 1 if edge[:type] == :balconysillconvex
      n_edges_as_balconydoorsills  += 1 if edge[:type] == :balconydoorsill
      n_edges_as_balconydoorsills  += 1 if edge[:type] == :balconydoorsillconcave
      n_edges_as_balconydoorsills  += 1 if edge[:type] == :balconydoorsillconvex
      n_edges_as_concave_parapets  += 1 if edge[:type] == :parapetconcave
      n_edges_as_convex_parapets   += 1 if edge[:type] == :parapetconvex
      n_edges_as_concave_roofs     += 1 if edge[:type] == :roofconcave
      n_edges_as_convex_roofs      += 1 if edge[:type] == :roofconvex
      n_edges_as_rimjoists         += 1 if edge[:type] == :rimjoist
      n_edges_as_concave_rimjoists += 1 if edge[:type] == :rimjoistconcave
      n_edges_as_convex_rimjoists  += 1 if edge[:type] == :rimjoistconvex
      n_edges_as_fenestrations     += 1 if edge[:type] == :fenestration
      n_edges_as_heads             += 1 if edge[:type] == :head
      n_edges_as_heads             += 1 if edge[:type] == :headconcave
      n_edges_as_heads             += 1 if edge[:type] == :headconvex
      n_edges_as_sills             += 1 if edge[:type] == :sill
      n_edges_as_sills             += 1 if edge[:type] == :sillconcave
      n_edges_as_sills             += 1 if edge[:type] == :sillconvex
      n_edges_as_jambs             += 1 if edge[:type] == :jamb
      n_edges_as_concave_jambs     += 1 if edge[:type] == :jambconcave
      n_edges_as_convex_jambs      += 1 if edge[:type] == :jambconvex
      n_edges_as_doorheads         += 1 if edge[:type] == :doorhead
      n_edges_as_doorsills         += 1 if edge[:type] == :doorsill
      n_edges_as_doorjambs         += 1 if edge[:type] == :doorjamb
      n_edges_as_skylightjambs     += 1 if edge[:type] == :skylightjamb
      n_edges_as_skylightjambs     += 1 if edge[:type] == :skylightjambconvex
      n_edges_as_corners           += 1 if edge[:type] == :corner
      n_edges_as_concave_corners   += 1 if edge[:type] == :cornerconcave
      n_edges_as_convex_corners    += 1 if edge[:type] == :cornerconvex
      n_edges_as_transitions       += 1 if edge[:type] == :transition
    end

    # Lo Scrigno holds 8x wall/roof edges:
    #   - 4x along gallery roof/skylight (all convex)
    #   - 4x along the elevator roof (3x convex + 1x concave)
    #
    # The gallery wall/roof edges are not modelled here "as built", but rather
    # closer to details of another Renzo Piano extension: the Modern Wing of the
    # Art Institute of Chicago. Both galleries are similar in that daylighting
    # is zenithal, covering all (or nearly all) of the roof surface. In the
    # case of Chicago, the roof is ~entirely glazed (as reflected in the model).
    #
    # www.archdaily.com/24652/the-modern-wing-renzo-piano/
    # 5010473228ba0d42220015f8-the-modern-wing-renzo-piano-image?next_project=no
    #
    # However, a small 1" strip is maintained along the South roof/wall edge of
    # the gallery to ensure skylight area < roof area.
    #
    # No judgement here on the suitability of the design for either Chicago or
    # Turin. The model nonetheless remains an interesting (~extreme) test case
    # for TBD. Except along the South parapet, the transition from "wall-to-roof"
    # and "roof-to-skylight" are one and the same. So is the edge a :skylight
    # edge? or a :parapet (or :roof) edge? They're both. In such cases, the final
    # selection in TBD is based on the greatest PSI-factor. In ASHRAE 90.1 2022,
    # only "vertical fenestration" edge PSI-factors are explicitely
    # stated/published. For this reason, the 8x TBD-built-in ASHRAE PSI sets
    # have 0 W/K per meter assigned for any non-regulated edge, e.g.:
    #
    #   - skylight perimeters
    #   - non-fenestrated door perimeters
    #   - corners
    #
    # There are (possibly) 2x admissible interpretations of how to treat
    # non-regulated heat losss (edges as linear thermal bridges) in 90.1:
    #   1. assign 0 W/K•m for both proposed design and budget building models
    #   2. assign more realistic PSI-factors, equally to both proposed/budget
    #
    # In both cases, the treatment of non-regulated heat loss remains "neutral"
    # between both proposed design and budget building models. Option #2 remains
    # closer to reality (more heat loss in winter, likely more heat gain in
    # summer), which is preferable for HVAC autosizing. Yet 90.1 (2022) ECB
    # doesn't seem to afford this type of flexibility, contrary to the "neutral"
    # treatment of (non-regulated) miscellaneous (process) loads. So for now,
    # TBD's built-in ASHRAE 90.1 2022 (A10) PSI-factor sets recflect option #1.
    #
    # Users who choose option #2 can always write up a custom ASHRAE 90.1 (A10)
    # PSI-factor set on file (tbd.json), initially based on the built-in 90.1
    # sets while resetting non-zero PSI-factors.
    expect(n_edges_at_grade            ).to eq( 0)
    expect(n_edges_as_balconies        ).to eq( 2)
    expect(n_edges_as_balconysills     ).to eq( 2) # (2x instances of GlassDoor)
    expect(n_edges_as_balconydoorsills ).to eq( 0)
    expect(n_edges_as_concave_parapets ).to eq( 1)
    expect(n_edges_as_convex_parapets  ).to eq(11)
    expect(n_edges_as_concave_roofs    ).to eq( 0)
    expect(n_edges_as_convex_roofs     ).to eq( 0)
    expect(n_edges_as_rimjoists        ).to eq( 5)
    expect(n_edges_as_concave_rimjoists).to eq( 5)
    expect(n_edges_as_convex_rimjoists ).to eq(18)
    expect(n_edges_as_fenestrations    ).to eq( 0)
    expect(n_edges_as_heads            ).to eq( 2) # GlassDoor == fenestration
    expect(n_edges_as_sills            ).to eq( 0) # (2x balconysills)
    expect(n_edges_as_jambs            ).to eq( 4)
    expect(n_edges_as_concave_jambs    ).to eq( 0)
    expect(n_edges_as_convex_jambs     ).to eq( 0)
    expect(n_edges_as_doorheads        ).to eq( 0)
    expect(n_edges_as_doorjambs        ).to eq( 0)
    expect(n_edges_as_doorsills        ).to eq( 0)
    expect(n_edges_as_skylightjambs    ).to eq( 1) # along 1" rooftop strip
    expect(n_edges_as_corners          ).to eq( 0)
    expect(n_edges_as_concave_corners  ).to eq( 4)
    expect(n_edges_as_convex_corners   ).to eq(12)
    expect(n_edges_as_transitions      ).to eq(10)

    # For the purposes of the RSpec, vertical access (elevator and stairs,
    # normally fully glazed) are modelled as (opaque) extensions of either
    # space. Deratable (exterior) surfaces are grouped, prefixed as follows:
    #
    #   - "g_" : art gallery
    #   - "p_" : underfloor plenum (supplying gallery)
    #   - "s_" : stairwell (leading to/through plenum & gallery)
    #   - "e_" : (side) elevator leading to gallery
    #
    # East vs West walls have equal heat loss (W/K) from major thermal bridging
    # as they are symmetrical. North vs South walls differ slightly due to:
    #   - adjacency with elevator walls
    #   - different balcony lengths
    expect(surfaces["g_E_wall"  ][:heatloss]).to be_within(TOL).of( 4.30)
    expect(surfaces["g_W_wall"  ][:heatloss]).to be_within(TOL).of( 4.30)
    expect(surfaces["g_N_wall"  ][:heatloss]).to be_within(TOL).of(15.95)
    expect(surfaces["g_S1_wall" ][:heatloss]).to be_within(TOL).of( 1.87)
    expect(surfaces["g_S2_wall" ][:heatloss]).to be_within(TOL).of( 1.04)
    expect(surfaces["g_S3_wall" ][:heatloss]).to be_within(TOL).of( 8.19)

    expect(surfaces["e_top"     ][:heatloss]).to be_within(TOL).of( 1.43)
    expect(surfaces["e_E_wall"  ][:heatloss]).to be_within(TOL).of( 0.32)
    expect(surfaces["e_W_wall"  ][:heatloss]).to be_within(TOL).of( 0.32)
    expect(surfaces["e_N_wall"  ][:heatloss]).to be_within(TOL).of( 0.95)
    expect(surfaces["e_S_wall"  ][:heatloss]).to be_within(TOL).of( 0.85)
    expect(surfaces["e_floor"   ][:heatloss]).to be_within(TOL).of( 2.46)

    expect(surfaces["s_E_wall"  ][:heatloss]).to be_within(TOL).of( 1.17)
    expect(surfaces["s_W_wall"  ][:heatloss]).to be_within(TOL).of( 1.17)
    expect(surfaces["s_N_wall"  ][:heatloss]).to be_within(TOL).of( 1.54)
    expect(surfaces["s_S_wall"  ][:heatloss]).to be_within(TOL).of( 1.54)
    expect(surfaces["s_floor"   ][:heatloss]).to be_within(TOL).of( 2.70)

    expect(surfaces["p_W1_floor"][:heatloss]).to be_within(TOL).of( 4.23)
    expect(surfaces["p_W2_floor"][:heatloss]).to be_within(TOL).of( 1.82)
    expect(surfaces["p_W3_floor"][:heatloss]).to be_within(TOL).of( 1.82)
    expect(surfaces["p_W4_floor"][:heatloss]).to be_within(TOL).of( 0.58)
    expect(surfaces["p_E_floor" ][:heatloss]).to be_within(TOL).of( 5.73)
    expect(surfaces["p_N_wall"  ][:heatloss]).to be_within(TOL).of(11.44)
    expect(surfaces["p_S2_wall" ][:heatloss]).to be_within(TOL).of( 8.16)
    expect(surfaces["p_S1_wall" ][:heatloss]).to be_within(TOL).of( 2.04)
    expect(surfaces["p_floor"   ][:heatloss]).to be_within(TOL).of( 3.07)

    expect(argh).to have_key(:io)
    out  = JSON.pretty_generate(argh[:io])
    outP = File.join(__dir__, "../json/tbd_loscrigno1.out.json")
    File.open(outP, "w") { |outP| outP.puts out }
  end

  it "can switch between parapet/roof edge types" do
    translator = OpenStudio::OSVersion::VersionTranslator.new
    TBD.clean!

    file  = File.join(__dir__, "files/osms/out/loscrigno.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    # Ensure the plenum is 'unoccupied', i.e. not part of the total floor area.
    plnum = model.getSpaceByName("scrigno_plenum")
    expect(plnum).to_not be_empty
    plnum = plnum.get
    expect(plnum.setPartofTotalFloorArea(false)).to be true

    # As a side test, switch glass doors to (opaque) doors.
    model.getSubSurfaces.each do |sub|
      next unless sub.subSurfaceType.downcase == "glassdoor"

      expect(sub.setSubSurfaceType("Door")).to be true
    end

    # Switching wall/roof edges from/to:
    #    - "parapet" PSI-factor 0.26 W/K•m
    #    - "roof"    PSI-factor 0.02 W/K•m !!
    #
    # ... as per 90.1 2022 (non-"parapet" admisible thresholds are much lower).
    argh = { option: "90.1.22|steel.m|default", parapet: false }

    json     = TBD.process(model, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty
    expect(surfaces).to be_a Hash
    expect(surfaces.size).to eq(31)
    expect(io).to be_a(Hash)
    expect(io).to have_key(:edges)
    expect(io[:edges].size).to eq(77)

    n_edges_at_grade             = 0
    n_edges_as_balconies         = 0
    n_edges_as_balconysills      = 0
    n_edges_as_balconydoorsills  = 0
    n_edges_as_concave_parapets  = 0
    n_edges_as_convex_parapets   = 0
    n_edges_as_concave_roofs     = 0
    n_edges_as_convex_roofs      = 0
    n_edges_as_rimjoists         = 0
    n_edges_as_concave_rimjoists = 0
    n_edges_as_convex_rimjoists  = 0
    n_edges_as_fenestrations     = 0
    n_edges_as_heads             = 0
    n_edges_as_sills             = 0
    n_edges_as_jambs             = 0
    n_edges_as_doorheads         = 0
    n_edges_as_doorsills         = 0
    n_edges_as_doorjambs         = 0
    n_edges_as_skylightjambs     = 0
    n_edges_as_concave_jambs     = 0
    n_edges_as_convex_jambs      = 0
    n_edges_as_corners           = 0
    n_edges_as_concave_corners   = 0
    n_edges_as_convex_corners    = 0
    n_edges_as_transitions       = 0

    io[:edges].each do |edge|
      expect(edge).to have_key(:type)

      n_edges_at_grade             += 1 if edge[:type] == :grade
      n_edges_at_grade             += 1 if edge[:type] == :gradeconcave
      n_edges_at_grade             += 1 if edge[:type] == :gradeconvex
      n_edges_as_balconies         += 1 if edge[:type] == :balcony
      n_edges_as_balconies         += 1 if edge[:type] == :balconyconcave
      n_edges_as_balconies         += 1 if edge[:type] == :balconyconvex
      n_edges_as_balconysills      += 1 if edge[:type] == :balconysill
      n_edges_as_balconysills      += 1 if edge[:type] == :balconysillconcave
      n_edges_as_balconysills      += 1 if edge[:type] == :balconysillconvex
      n_edges_as_balconydoorsills  += 1 if edge[:type] == :balconydoorsill
      n_edges_as_balconydoorsills  += 1 if edge[:type] == :balconydoorsillconcave
      n_edges_as_balconydoorsills  += 1 if edge[:type] == :balconydoorsillconvex
      n_edges_as_concave_parapets  += 1 if edge[:type] == :parapetconcave
      n_edges_as_convex_parapets   += 1 if edge[:type] == :parapetconvex
      n_edges_as_concave_roofs     += 1 if edge[:type] == :roofconcave
      n_edges_as_convex_roofs      += 1 if edge[:type] == :roofconvex
      n_edges_as_rimjoists         += 1 if edge[:type] == :rimjoist
      n_edges_as_concave_rimjoists += 1 if edge[:type] == :rimjoistconcave
      n_edges_as_convex_rimjoists  += 1 if edge[:type] == :rimjoistconvex
      n_edges_as_fenestrations     += 1 if edge[:type] == :fenestration
      n_edges_as_heads             += 1 if edge[:type] == :head
      n_edges_as_heads             += 1 if edge[:type] == :headconcave
      n_edges_as_heads             += 1 if edge[:type] == :headconvex
      n_edges_as_sills             += 1 if edge[:type] == :sill
      n_edges_as_sills             += 1 if edge[:type] == :sillconcave
      n_edges_as_sills             += 1 if edge[:type] == :sillconvex
      n_edges_as_jambs             += 1 if edge[:type] == :jamb
      n_edges_as_concave_jambs     += 1 if edge[:type] == :jambconcave
      n_edges_as_convex_jambs      += 1 if edge[:type] == :jambconvex
      n_edges_as_doorheads         += 1 if edge[:type] == :doorhead
      n_edges_as_doorsills         += 1 if edge[:type] == :doorsill
      n_edges_as_doorjambs         += 1 if edge[:type] == :doorjamb
      n_edges_as_skylightjambs     += 1 if edge[:type] == :skylightjamb
      n_edges_as_skylightjambs     += 1 if edge[:type] == :skylightjambconvex
      n_edges_as_corners           += 1 if edge[:type] == :corner
      n_edges_as_concave_corners   += 1 if edge[:type] == :cornerconcave
      n_edges_as_convex_corners    += 1 if edge[:type] == :cornerconvex
      n_edges_as_transitions       += 1 if edge[:type] == :transition
    end

    expect(n_edges_at_grade            ).to eq( 0)
    expect(n_edges_as_balconies        ).to eq( 2)
    expect(n_edges_as_balconysills     ).to eq( 0)
    expect(n_edges_as_balconydoorsills ).to eq( 2) # ... no longer GlassDoors
    expect(n_edges_as_concave_parapets ).to eq( 0) #  1x if parapet (not roof)
    expect(n_edges_as_convex_parapets  ).to eq( 0) # 11x if parapet (not roof)
    expect(n_edges_as_concave_roofs    ).to eq( 1)
    expect(n_edges_as_convex_roofs     ).to eq(11)
    expect(n_edges_as_rimjoists        ).to eq( 5)
    expect(n_edges_as_concave_rimjoists).to eq( 5)
    expect(n_edges_as_convex_rimjoists ).to eq(18)
    expect(n_edges_as_fenestrations    ).to eq( 0)
    expect(n_edges_as_heads            ).to eq( 0)
    expect(n_edges_as_sills            ).to eq( 0)
    expect(n_edges_as_jambs            ).to eq( 0)
    expect(n_edges_as_concave_jambs    ).to eq( 0)
    expect(n_edges_as_convex_jambs     ).to eq( 0)
    expect(n_edges_as_doorheads        ).to eq( 2) # GlassDoor != fenestration
    expect(n_edges_as_doorjambs        ).to eq( 4) # GlassDoor != fenestration
    expect(n_edges_as_doorsills        ).to eq( 0) # (2x balconydoorsills)
    expect(n_edges_as_skylightjambs    ).to eq( 1) # along 1" rooftop strip
    expect(n_edges_as_corners          ).to eq( 0)
    expect(n_edges_as_concave_corners  ).to eq( 4)
    expect(n_edges_as_convex_corners   ).to eq(12)
    expect(n_edges_as_transitions      ).to eq(10)

    # Re-do, without changing door surface types.
    file  = File.join(__dir__, "files/osms/out/loscrigno.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    argh = {option: "90.1.22|steel.m|default", parapet: false}

    json     = TBD.process(model, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty
    expect(surfaces).to be_a Hash
    expect(surfaces.size).to eq(31)
    expect(io).to be_a(Hash)
    expect(io).to have_key(:edges)
    expect(io[:edges].size).to eq(77)

    #      roof PSI :  0.02 W/K•m
    # - parapet PSI :  0.26 W/K•m
    # ---------------------------
    # =   delta PSI : -0.24 W/K•m
    #
    # e.g. East & West   : reduction of 10.4m x -0.24 W/K•m = -2.496 W/K
    # e.g. North         : reduction of 36.6m x -0.24 W/K•m = -8.784 W/K
    #
    # Total length of roof/parapets : 11m + 2x 36.6m + 2x 10.4m = 105m
    # ... 105m x -0.24 W/K•m = -25.2 W/K
    expect(surfaces["g_E_wall"  ][:heatloss]).to be_within(TOL).of( 1.80) #   4.3 = -2.5
    expect(surfaces["g_W_wall"  ][:heatloss]).to be_within(TOL).of( 1.80) #   4.3 = -2.5
    expect(surfaces["g_N_wall"  ][:heatloss]).to be_within(TOL).of( 7.17) # 15.95 = -8.8
    expect(surfaces["g_S1_wall" ][:heatloss]).to be_within(TOL).of( 1.08) #  1.87 = -0.8
    expect(surfaces["g_S2_wall" ][:heatloss]).to be_within(TOL).of( 0.08) #  1.04 = -1.0
    expect(surfaces["g_S3_wall" ][:heatloss]).to be_within(TOL).of( 5.07) #  8.19 = -3.1

    expect(surfaces["e_top"     ][:heatloss]).to be_within(TOL).of( 0.11) #  1.32 = -1.2
    expect(surfaces["e_E_wall"  ][:heatloss]).to be_within(TOL).of( 0.14) #  0.32 = -0.2
    expect(surfaces["e_W_wall"  ][:heatloss]).to be_within(TOL).of( 0.14) #  0.32 = -0.2
    expect(surfaces["e_N_wall"  ][:heatloss]).to be_within(TOL).of( 0.95)
    expect(surfaces["e_S_wall"  ][:heatloss]).to be_within(TOL).of( 0.37) #  0.85 = -0.5
    expect(surfaces["e_floor"   ][:heatloss]).to be_within(TOL).of( 2.46)

    expect(surfaces["s_E_wall"  ][:heatloss]).to be_within(TOL).of( 1.17)
    expect(surfaces["s_W_wall"  ][:heatloss]).to be_within(TOL).of( 1.17)
    expect(surfaces["s_N_wall"  ][:heatloss]).to be_within(TOL).of( 1.54)
    expect(surfaces["s_S_wall"  ][:heatloss]).to be_within(TOL).of( 1.54)
    expect(surfaces["s_floor"   ][:heatloss]).to be_within(TOL).of( 2.70)

    expect(surfaces["p_W1_floor"][:heatloss]).to be_within(TOL).of( 4.23)
    expect(surfaces["p_W2_floor"][:heatloss]).to be_within(TOL).of( 1.82)
    expect(surfaces["p_W3_floor"][:heatloss]).to be_within(TOL).of( 1.82)
    expect(surfaces["p_W4_floor"][:heatloss]).to be_within(TOL).of( 0.58)
    expect(surfaces["p_E_floor" ][:heatloss]).to be_within(TOL).of( 5.73)
    expect(surfaces["p_N_wall"  ][:heatloss]).to be_within(TOL).of(11.44)
    expect(surfaces["p_S2_wall" ][:heatloss]).to be_within(TOL).of( 8.16)
    expect(surfaces["p_S1_wall" ][:heatloss]).to be_within(TOL).of( 2.04)
    expect(surfaces["p_floor"   ][:heatloss]).to be_within(TOL).of( 3.07)

    expect(argh).to have_key(:io)
    out  = JSON.pretty_generate(argh[:io])
    outP = File.join(__dir__, "../json/tbd_loscrigno1.out.json")
    File.open(outP, "w") { |outP| outP.puts out }

    # --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- #
    # 4x cases (warehouse.osm):
    #   - 1x :parapet (default) case
    #   - 2x :roof case
    #   - 2x JSON variations
    TBD.clean!

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

    # CASE 1: :parapet (default) case.
    file  = File.join(__dir__, "files/osms/in/warehouse.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    argh = {option: "90.1.22|steel.m|default"}

    json     = TBD.process(model, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty
    expect(surfaces).to be_a Hash
    expect(surfaces.size).to eq(23)
    expect(io).to be_a(Hash)
    expect(io).to have_key(:edges)
    expect(io[:edges].size).to eq(300)

    surfaces.each do |id, surface|
      expect(ids).to     have_value(id)     if surface.key?(:edges)
      expect(ids).to_not have_value(id) unless surface.key?(:edges)
    end

    surfaces.each do |id, surface|
      next unless surface.key?(:edges)

      expect(ids).to have_value(id)
      expect(surface).to have_key(:heatloss)
      expect(surface).to have_key(:ratio)
      h = surface[:heatloss]
      s = model.getSurfaceByName(id)
      expect(s).to_not be_empty
      s = s.get
      expect(s.nameString).to eq(id)
      expect(s.isConstructionDefaulted).to be false
      expect(s.construction.get.nameString).to include(" tbd")
      expect(h).to be_within(TOL).of(  8.00) if id == ids[:a] #  50.20 if "poor"
      expect(h).to be_within(TOL).of(  4.24) if id == ids[:b] #  24.06 if "poor"
      expect(h).to be_within(TOL).of( 17.23) if id == ids[:c] #  87.16 ...
      expect(h).to be_within(TOL).of(  6.53) if id == ids[:d] #  22.61
      expect(h).to be_within(TOL).of(  2.30) if id == ids[:e] #   9.15
      expect(h).to be_within(TOL).of(  1.95) if id == ids[:f] #  26.47
      expect(h).to be_within(TOL).of(  2.10) if id == ids[:g] #  27.19
      expect(h).to be_within(TOL).of(  3.00) if id == ids[:h] #  41.36
      expect(h).to be_within(TOL).of( 26.97) if id == ids[:i] # 161.02
      expect(h).to be_within(TOL).of(  5.25) if id == ids[:j] #  62.28
      expect(h).to be_within(TOL).of(  8.06) if id == ids[:k] # 117.87
      expect(h).to be_within(TOL).of(  8.06) if id == ids[:l] #  95.77

      c = s.construction
      expect(c).to_not be_empty
      c = c.get.to_LayeredConstruction
      expect(c).to_not be_empty
      c = c.get
      expect(c.layers[1].nameString).to include("m tbd")
    end

    surfaces.each do |id, surface|
      if surface.key?(:ratio) # ... vs "poor (BETBG)"
        expect(surface[:ratio]).to be_within(0.2).of(-18.3) if id == ids[:b] # -53.0%
        expect(surface[:ratio]).to be_within(0.2).of( -3.5) if id == ids[:c] # -15.6%
        expect(surface[:ratio]).to be_within(0.2).of( -1.3) if id == ids[:i] #  -7.3%
        expect(surface[:ratio]).to be_within(0.2).of( -1.5) if id == ids[:j]
      else
        expect(surface[:boundary].downcase).to_not eq("outdoors")
      end
    end

    # CASE 2: :roof (not default :parapet) case.
    file  = File.join(__dir__, "files/osms/in/warehouse.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    argh = {option: "90.1.22|steel.m|default", parapet: false}

    json     = TBD.process(model, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty
    expect(surfaces).to be_a Hash
    expect(surfaces.size).to eq(23)
    expect(io).to be_a(Hash)
    expect(io).to have_key(:edges)
    expect(io[:edges].size).to eq(300)

    surfaces.each do |id, surface|
      expect(ids).to     have_value(id)     if surface.key?(:edges)
      expect(ids).to_not have_value(id) unless surface.key?(:edges)
    end

    surfaces.each do |id, surface|
      next unless surface.key?(:edges)

      expect(ids).to have_value(id)
      expect(surface).to have_key(:heatloss)
      expect(surface).to have_key(:ratio)
      h = surface[:heatloss]
      s = model.getSurfaceByName(id)
      expect(s).to_not be_empty
      s = s.get
      expect(s.nameString).to eq(id)
      expect(s.isConstructionDefaulted).to be false
      expect(s.construction.get.nameString).to include(" tbd")
      expect(h).to be_within(TOL).of(  8.00) if id == ids[:a] #  8.00 !
      expect(h).to be_within(TOL).of(  4.24) if id == ids[:b] #  4.24 !
      expect(h).to be_within(TOL).of(  1.33) if id == ids[:c] # 17.23
      expect(h).to be_within(TOL).of(  4.17) if id == ids[:d] #  6.53
      expect(h).to be_within(TOL).of(  1.47) if id == ids[:e] #  2.30
      expect(h).to be_within(TOL).of(  0.15) if id == ids[:f] #  1.95
      expect(h).to be_within(TOL).of(  0.16) if id == ids[:g] #  2.10
      expect(h).to be_within(TOL).of(  0.23) if id == ids[:h] #  3.00
      expect(h).to be_within(TOL).of(  2.07) if id == ids[:i] # 26.97
      expect(h).to be_within(TOL).of(  0.40) if id == ids[:j] #  5.25
      expect(h).to be_within(TOL).of(  0.62) if id == ids[:k] #  8.06
      expect(h).to be_within(TOL).of(  0.62) if id == ids[:l] #  8.06
      # ! office walls: same results ... no parapet/roof

      c = s.construction
      expect(c).to_not be_empty
      c = c.get.to_LayeredConstruction
      expect(c).to_not be_empty
      c = c.get
      expect(c.layers[1].nameString).to include("m tbd")
    end

    surfaces.each do |id, surface|
      if surface.key?(:ratio) # ... vs "parapet"
        expect(surface[:ratio]).to be_within(0.2).of(-18.3) if id == ids[:b] # !
        expect(surface[:ratio]).to be_within(0.2).of( -0.3) if id == ids[:c] # -3.5%
        expect(surface[:ratio]).to be_within(0.2).of( -0.1) if id == ids[:i] # -1.3%
        expect(surface[:ratio]).to be_within(0.2).of( -0.1) if id == ids[:j] # -1.3%
        # ! office walls: same results ... no parapet/roof
      else
        expect(surface[:boundary].downcase).to_not eq("outdoors")
      end
    end

    # CASE 3: Same as CASE 1 (:parapet), yet reset to :roof for "Bulk Storage"
    # via JSON file. Extra surface-specific heat loss from derating will switch
    # between CASE 1 vs CASE 2 values.
    file  = File.join(__dir__, "files/osms/in/warehouse.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    argh               = {}
    argh[:option     ] = "90.1.22|steel.m|default"
    argh[:io_path    ] = File.join(__dir__, "../json/tbd_warehouse17.json")
    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")

    json     = TBD.process(model, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty
    expect(surfaces).to be_a Hash
    expect(surfaces.size).to eq(23)
    expect(io).to be_a(Hash)
    expect(io).to have_key(:edges)
    expect(io[:edges].size).to eq(300)

    surfaces.each do |id, surface|
      expect(ids).to     have_value(id)     if surface.key?(:edges)
      expect(ids).to_not have_value(id) unless surface.key?(:edges)
    end

    surfaces.each do |id, surface|
      next unless surface.key?(:edges)

      expect(ids).to have_value(id)
      expect(surface).to have_key(:heatloss)
      expect(surface).to have_key(:ratio)
      h = surface[:heatloss]
      s = model.getSurfaceByName(id)
      expect(s).to_not be_empty
      s = s.get
      expect(s.nameString).to eq(id)
      expect(s.isConstructionDefaulted).to be false
      expect(s.construction.get.nameString).to include(" tbd")
      expect(h).to be_within(TOL).of(  8.00) if id == ids[:a] # !
      expect(h).to be_within(TOL).of(  4.24) if id == ids[:b] # !
      expect(h).to be_within(TOL).of( 17.23) if id == ids[:c]
      expect(h).to be_within(TOL).of(  6.53) if id == ids[:d]
      expect(h).to be_within(TOL).of(  2.30) if id == ids[:e]
      expect(h).to be_within(TOL).of(  1.95) if id == ids[:f]
      expect(h).to be_within(TOL).of(  2.10) if id == ids[:g]
      expect(h).to be_within(TOL).of(  3.00) if id == ids[:h]
      expect(h).to be_within(TOL).of(  2.07) if id == ids[:i] # Bulk
      expect(h).to be_within(TOL).of(  0.40) if id == ids[:j] # Bulk
      expect(h).to be_within(TOL).of(  0.62) if id == ids[:k] # Bulk
      expect(h).to be_within(TOL).of(  0.62) if id == ids[:l] # Bulk
      # ! office walls: same results ... no parapet/roof

      c = s.construction
      expect(c).to_not be_empty
      c = c.get.to_LayeredConstruction
      expect(c).to_not be_empty
      c = c.get
      expect(c.layers[1].nameString).to include("m tbd")
    end

    surfaces.each do |id, surface|
      if surface.key?(:ratio)
        expect(surface[:ratio]).to be_within(0.2).of(-18.3) if id == ids[:b] # !
        expect(surface[:ratio]).to be_within(0.2).of( -3.5) if id == ids[:c]
        expect(surface[:ratio]).to be_within(0.2).of( -0.1) if id == ids[:i] # Bulk
        expect(surface[:ratio]).to be_within(0.2).of( -0.1) if id == ids[:j] # Bulk Rear
        # ! office walls: same results ... no parapet/roof
      else
        expect(surface[:boundary].downcase).to_not eq("outdoors")
      end
    end

    # CASE 4: Same as CASE 3 (:parapet, reset to :roof for "Bulk Storage"
    # via JSON file), yet wall/roof edge along "Bulk Storage Rear Wall",
    # ids[:j], is reset to :parapet (via JSON file). Again, extra surface
    # -specific heat loss from derating will switch between CASE 1 vs CASE 2
    # values (either one or the other). Exceptionally in the case of the "Bulk
    # Storage Roof", the extra heat loss (and derating %) are greater somewhat
    # (vs CASE 3), as it remains affected by the (unaltered) :roof edges along:
    #
    #   - "Bulk Storage Left Wall"
    #   - "Bulk Storage Right Wall"
    #
    file  = File.join(__dir__, "files/osms/in/warehouse.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    argh               = {}
    argh[:option     ] = "90.1.22|steel.m|default"
    argh[:io_path    ] = File.join(__dir__, "../json/tbd_warehouse18.json")
    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")

    json     = TBD.process(model, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty
    expect(surfaces).to be_a Hash
    expect(surfaces.size).to eq(23)
    expect(io).to be_a(Hash)
    expect(io).to have_key(:edges)
    expect(io[:edges].size).to eq(300)

    surfaces.each do |id, surface|
      expect(ids).to     have_value(id)     if surface.key?(:edges)
      expect(ids).to_not have_value(id) unless surface.key?(:edges)
    end

    surfaces.each do |id, surface|
      next unless surface.key?(:edges)

      expect(ids).to have_value(id)
      expect(surface).to have_key(:heatloss)
      expect(surface).to have_key(:ratio)
      h = surface[:heatloss]
      s = model.getSurfaceByName(id)
      expect(s).to_not be_empty
      s = s.get
      expect(s.nameString).to eq(id)
      expect(s.isConstructionDefaulted).to be false
      expect(s.construction.get.nameString).to include(" tbd")
      expect(h).to be_within(TOL).of(  8.00) if id == ids[:a] # !
      expect(h).to be_within(TOL).of(  4.24) if id == ids[:b] # !
      expect(h).to be_within(TOL).of( 17.23) if id == ids[:c]
      expect(h).to be_within(TOL).of(  6.53) if id == ids[:d]
      expect(h).to be_within(TOL).of(  2.30) if id == ids[:e]
      expect(h).to be_within(TOL).of(  1.95) if id == ids[:f]
      expect(h).to be_within(TOL).of(  2.10) if id == ids[:g]
      expect(h).to be_within(TOL).of(  3.00) if id == ids[:h]
      expect(h).to be_within(TOL).of(  8.20) if id == ids[:i] # 2.07 < x < 26.97
      expect(h).to be_within(TOL).of(  5.25) if id == ids[:j] # Bulk Rear Wall
      expect(h).to be_within(TOL).of(  0.62) if id == ids[:k] # Bulk
      expect(h).to be_within(TOL).of(  0.62) if id == ids[:l] # Bulk
      # ! office walls: same results ... no parapet/roof

      c = s.construction
      expect(c).to_not be_empty
      c = c.get.to_LayeredConstruction
      expect(c).to_not be_empty
      c = c.get
      expect(c.layers[1].nameString).to include("m tbd")
    end

    surfaces.each do |id, surface|
      if surface.key?(:ratio)
        expect(surface[:ratio]).to be_within(0.2).of(-18.3) if id == ids[:b] # !
        expect(surface[:ratio]).to be_within(0.2).of( -3.5) if id == ids[:c]
        expect(surface[:ratio]).to be_within(0.2).of( -0.4) if id == ids[:i] # 0.1 < x < 1.3%
        expect(surface[:ratio]).to be_within(0.2).of( -1.5) if id == ids[:j] # Bulk Rear
        # ! office walls: same results ... no parapet/roof
      else
        expect(surface[:boundary].downcase).to_not eq("outdoors")
      end
    end
  end

  it "can process DOE Prototype smalloffice.osm" do
    translator = OpenStudio::OSVersion::VersionTranslator.new
    TBD.clean!

    file  = File.join(__dir__, "files/osms/in/smalloffice.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    model.getSpaces.each do |space|
      expect(space.thermalZone).to_not be_empty
      zone = space.thermalZone.get

      heat_spt = TBD.maxHeatScheduledSetpoint(zone)
      cool_spt = TBD.minCoolScheduledSetpoint(zone)
      expect(heat_spt).to have_key(:spt)
      expect(cool_spt).to have_key(:spt)

      heating = heat_spt[:spt]
      cooling = cool_spt[:spt]
      stpts   = TBD.setpoints(space)
      expect(stpts).to have_key(:heating)
      expect(stpts).to have_key(:cooling)

      if zone.nameString == "Attic ZN"
        expect(heating).to be_nil
        expect(cooling).to be_nil
        expect(stpts[:heating]).to be_nil
        expect(stpts[:cooling]).to be_nil
        expect(zone.isPlenum).to be false
        expect(TBD.plenum?(space)).to be false
        next
      end

      expect(TBD.plenum?(space)).to be false
      expect(heating).to be_within(0.1).of(21.1)
      expect(cooling).to be_within(0.1).of(23.9)
      expect(stpts[:heating]).to_not be_nil
      expect(stpts[:cooling]).to_not be_nil
      expect(stpts[:heating]).to be_within(0.1).of(21.1)
      expect(stpts[:cooling]).to be_within(0.1).of(23.9)
    end

    # Tracking insulated ceiling surfaces below attic.
    model.getSurfaces.each do |s|
      next unless s.surfaceType == "RoofCeiling"
      next unless s.isConstructionDefaulted

      c = s.construction
      expect(c).to_not be_empty
      c = c.get.to_LayeredConstruction
      expect(c).to_not be_empty
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
    model.getSurfaces.each do |s|
      next unless s.surfaceType == "Wall"
      next unless s.outsideBoundaryCondition == "Outdoors"

      id  = s.construction.get.nameString
      str = "Typical Insulated Wood Framed Exterior Wall R-11.24"
      expect(id).to include(str)

      c = s.construction
      expect(c).to_not be_empty
      c = c.get.to_LayeredConstruction
      expect(c).to_not be_empty
      c = c.get

      expect(c.layers.size).to eq(4)
      expect(c.layers[0].nameString).to eq("25mm Stucco")
      expect(c.layers[1].nameString).to eq("5/8 in. Gypsum Board")
      str2 = "Typical Insulation R-9.06 1"
      expect(c.layers[2].nameString).to include(str2)
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

    argh = { option: "poor (BETBG)" }

    json     = TBD.process(model, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty
    expect(surfaces).to be_a(Hash)
    expect(surfaces.size).to eq(43)
    expect(io).to be_a(Hash)
    expect(io).to have_key(:edges)
    expect(io[:edges].size).to eq(105)

    surfaces.each do |id, surface|
      expect(surface).to have_key(:conditioned)
      next unless surface[:conditioned]

      expect(surface).to have_key(:heating)
      expect(surface).to have_key(:cooling)

      # Testing glass door detection
      if surface.key?(:doors)
        surface[:doors].each do |i, door|
          expect(door).to have_key(:glazed)
          expect(door).to have_key(:u)
          expect(door[:glazed]).to be true
          expect(door[:u     ]).to be_a(Numeric)
          expect(door[:u     ]).to be_within(TOL).of(6.40)
        end
      end
    end

    # Testing attic surfaces.
    surfaces.each do |id, surface|
      expect(surface).to have_key(:space)
      next unless surface[:space].nameString == "Attic"

      # Attic is an UNENCLOSED zone - outdoor-facing surfaces are not derated.
      expect(surface).to have_key(:conditioned)
      expect(surface[:conditioned]).to be false
      expect(surface).to_not have_key(:heatloss)
      expect(surface).to_not have_key(:ratio)

      # Attic floor surfaces adjacent to ceiling surfaces below (CONDITIONED
      # office spaces) share derated constructions (although inverted).
      expect(surface).to have_key(:boundary)
      b = surface[:boundary]
      next if b.downcase == "outdoors"

      # TBD/Topolys should be tracking the adjacent CONDITIONED surface.
      expect(surfaces).to have_key(b)
      expect(surfaces[b]).to be_a(Hash)
      expect(surfaces[b]).to have_key(:conditioned)
      expect(surfaces[b][:conditioned]).to be true

      if id == "Attic_floor_core"
        expect(surfaces[b]).to_not have_key(:ratio)
        expect(surfaces[b]).to have_key(:heatloss)
        expect(surfaces[b][:heatloss]).to be_within(TOL).of(0.00)
      end

      next if id == "Attic_floor_core"

      expect(surfaces[b]).to have_key(:heatloss)
      h = surfaces[b][:heatloss]
      expect(h).to be_within(TOL).of(20.11) if id.include?("north")
      expect(h).to be_within(TOL).of(20.22) if id.include?("south")
      expect(h).to be_within(TOL).of(13.42) if id.include?( "west")
      expect(h).to be_within(TOL).of(13.42) if id.include?( "east")

      # Derated constructions?
      s = model.getSurfaceByName(id)
      expect(s).to_not be_empty
      s = s.get
      expect(s.nameString).to eq(id)
      expect(s.surfaceType).to eq("Floor")

      # In the small office OSM, attic floor constructions are not set by
      # the attic default construction set. They are instead set for the
      # adjacent ceilings below (building default construction set). So
      # attic floor surfaces automatically inherit derated constructions.
      expect(s.isConstructionDefaulted).to be true
      c = s.construction.get.to_LayeredConstruction
      expect(c).to_not be_empty
      c = c.get
      expect(c.nameString).to include("c tbd")
      expect(c.layers.size).to eq(2)
      expect(c.layers[0].nameString).to eq("5/8 in. Gypsum Board")
      expect(c.layers[1].nameString).to include("m tbd")

      # Comparing derating ratios of constructions.
      expect(c.layers[1].to_MasslessOpaqueMaterial).to_not be_empty
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

      expect(surface).to have_key(:heatloss)

      if id == "Core_ZN_ceiling"
        expect(surface[:heatloss]).to be_within(0.001).of(0)
        expect(surface).to_not have_key(:ratio)
        expect(surface).to have_key(:u)
        expect(surface[:u]).to be_within(0.001).of(0.153)
        next
      end

      expect(surface).to have_key(:ratio)
      h = surface[:heatloss]
      s = model.getSurfaceByName(id)
      expect(s).to_not be_empty
      s = s.get
      expect(s.nameString).to eq(id)
      expect(s.isConstructionDefaulted).to be false
      expect(s.construction.get.nameString).to include(" tbd")
      next unless s.surfaceType == "Wall"

      expect(h).to be_within(TOL).of(51.17) if id.include?("_1_") # South
      expect(h).to be_within(TOL).of(33.08) if id.include?("_2_") # East
      expect(h).to be_within(TOL).of(48.32) if id.include?("_3_") # North
      expect(h).to be_within(TOL).of(33.08) if id.include?("_4_") # West

      c = s.construction
      expect(c).to_not be_empty
      c = c.get.to_LayeredConstruction
      expect(c).to_not be_empty
      c = c.get
      expect(c.layers.size).to eq(4)
      expect(c.layers[2].nameString).to include("m tbd")
      next unless id.include?("_1_") # South

      l_fen     = 0
      l_head    = 0
      l_sill    = 0
      l_jamb    = 0
      l_grade   = 0
      l_parapet = 0
      l_corner  = 0

      surface[:edges].values.each do |edge|
        l_fen     += edge[:length] if edge[:type] == :fenestration
        l_head    += edge[:length] if edge[:type] == :head
        l_sill    += edge[:length] if edge[:type] == :sill
        l_jamb    += edge[:length] if edge[:type] == :jamb
        l_grade   += edge[:length] if edge[:type] == :grade
        l_grade   += edge[:length] if edge[:type] == :gradeconcave
        l_grade   += edge[:length] if edge[:type] == :gradeconvex
        l_parapet += edge[:length] if edge[:type] == :parapet
        l_parapet += edge[:length] if edge[:type] == :parapetconcave
        l_parapet += edge[:length] if edge[:type] == :parapetconvex
        l_corner  += edge[:length] if edge[:type] == :cornerconcave
        l_corner  += edge[:length] if edge[:type] == :cornerconvex
      end

      expect(l_fen    ).to be_within(TOL).of( 0.00)
      expect(l_head   ).to be_within(TOL).of(12.81)
      expect(l_sill   ).to be_within(TOL).of(10.98)
      expect(l_jamb   ).to be_within(TOL).of(22.56)
      expect(l_grade  ).to be_within(TOL).of(27.69)
      expect(l_parapet).to be_within(TOL).of(27.69)
      expect(l_corner ).to be_within(TOL).of( 6.10)
    end
  end

  it "can process DOE prototype smalloffice.osm (hardset)" do
    translator = OpenStudio::OSVersion::VersionTranslator.new
    TBD.clean!

    file  = File.join(__dir__, "files/osms/in/smalloffice.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    # In the preceding test, attic floor surfaces inherit constructions from
    # adjacent office ceiling surfaces below. In this variant, attic floors
    # adjacent to NSEW perimeter office ceilings have hardset constructions
    # assigned to them (inverted). Results should remain the same as above.
    model.getSurfaces.each do |s|
      expect(s.space).to_not be_empty
      next unless s.space.get.nameString == "Attic"
      next unless s.nameString.include?("_perimeter")

      expect(s.surfaceType).to eq("Floor")
      expect(s.isConstructionDefaulted).to be true
      c = s.construction.get.to_LayeredConstruction
      expect(c).to_not be_empty
      c = c.get
      expect(c.layers.size).to eq(2)
      # layer[0]: "5/8 in. Gypsum Board"
      # layer[1]: "Typical Insulation R-35.4 1"

      construction = c.clone(model).to_LayeredConstruction.get
      expect(construction.handle.to_s).to_not be_empty
      expect(construction.nameString).to_not be_empty

      str = "Typical Wood Joist Attic Floor R-37.04 2"
      expect(construction.nameString).to eq(str)
      construction.setName("#{s.nameString} floor")
      expect(construction.layers.size).to eq(2)
      expect(s.setConstruction(construction)).to be true
      expect(s.isConstructionDefaulted).to be false
    end

    argh = { option: "poor (BETBG)" }

    json     = TBD.process(model, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty
    expect(surfaces).to be_a(Hash)
    expect(surfaces.size).to eq(43)
    expect(io).to be_a(Hash)
    expect(io).to have_key(:edges)
    expect(io[:edges].size).to eq(105)

    # Testing attic surfaces.
    surfaces.each do |id, surface|
      expect(surface).to have_key(:space)
      next unless surface[:space].nameString == "Attic"

      # Attic is an UNENCLOSED zone - outdoor-facing surfaces are not derated.
      expect(surface).to have_key(:conditioned)
      expect(surface[:conditioned]).to be false
      expect(surface).to_not have_key(:heatloss)
      expect(surface).to_not have_key(:ratio)

      expect(surface).to have_key(:boundary)
      b = surface[:boundary]
      next if b == "Outdoors"

      expect(surfaces).to have_key(b)
      expect(surfaces[b]).to have_key(:conditioned)
      expect(surfaces[b][:conditioned]).to be true
      next if id == "Attic_floor_core"

      expect(surfaces[b]).to have_key(:ratio)
      expect(surfaces[b]).to have_key(:heatloss)
      h = surfaces[b][:heatloss]

      # Derated constructions?
      s = model.getSurfaceByName(id)
      expect(s).to_not be_empty
      s = s.get
      expect(s.nameString).to eq(id)
      expect(s.surfaceType).to eq("Floor")
      expect(s.isConstructionDefaulted).to be false
      c = s.construction.get.to_LayeredConstruction
      expect(c).to_not be_empty
      c = c.get
      next unless c.nameString == "Attic_floor_perimeter_south floor"

      expect(c.nameString).to include("c tbd")
      expect(c.layers.size).to eq(2)
      expect(c.layers[0].nameString).to eq("5/8 in. Gypsum Board")
      expect(c.layers[1].nameString).to include("m tbd")
      expect(c.layers[1].to_MasslessOpaqueMaterial).to_not be_empty
      m = c.layers[1].to_MasslessOpaqueMaterial.get

      # Before derating.
      initial_R  = s.filmResistance
      initial_R += 0.0994
      initial_R += 6.2348

      # After derating.
      derated_R  = s.filmResistance
      derated_R += 0.0994
      derated_R += m.thermalResistance

      ratio = -(initial_R - derated_R) * 100 / initial_R
      expect(ratio).to be_within(1).of(surfaces[b][:ratio])
      # "5/8 in. Gypsum Board"        : RSi = 0,0994 m2.K/W
      # "Typical Insulation R-35.4 1" : RSi = 6,2348 m2.K/W

      surfaces.each do |id, surface|
        next unless surface.key?(:edges)

        expect(surface).to have_key(:heatloss)
        expect(surface).to have_key(:ratio)
        h = surface[:heatloss]
        s = model.getSurfaceByName(id)
        expect(s).to_not be_empty
        s = s.get
        expect(s.nameString).to eq(id)
        expect(s.isConstructionDefaulted).to be false
        expect(s.construction.get.nameString).to include(" tbd")
        next unless s.surfaceType == "Wall"

        # Testing outdoor-facing walls.
        expect(h).to be_within(TOL).of(51.17) if id.include?("_1_") # South
        expect(h).to be_within(TOL).of(33.08) if id.include?("_2_") # East
        expect(h).to be_within(TOL).of(48.32) if id.include?("_3_") # North
        expect(h).to be_within(TOL).of(33.08) if id.include?("_4_") # West

        c = s.construction
        expect(c).to_not be_empty
        c = c.get.to_LayeredConstruction
        expect(c).to_not be_empty
        c = c.get
        expect(c.layers.size).to eq(4)
        expect(c.layers[2].nameString).to include("m tbd")
        next unless id.include?("_1_") # South

        l_fen     = 0
        l_head    = 0
        l_sill    = 0
        l_jamb    = 0
        l_grade   = 0
        l_parapet = 0
        l_corner  = 0

        surface[:edges].values.each do |edge|
          l_fen     += edge[:length] if edge[:type] == :fenestration
          l_head    += edge[:length] if edge[:type] == :head
          l_sill    += edge[:length] if edge[:type] == :sill
          l_jamb    += edge[:length] if edge[:type] == :jamb
          l_grade   += edge[:length] if edge[:type] == :grade
          l_grade   += edge[:length] if edge[:type] == :gradeconcave
          l_grade   += edge[:length] if edge[:type] == :gradeconvex
          l_parapet += edge[:length] if edge[:type] == :parapet
          l_parapet += edge[:length] if edge[:type] == :parapetconcave
          l_parapet += edge[:length] if edge[:type] == :parapetconvex
          l_corner  += edge[:length] if edge[:type] == :cornerconcave
          l_corner  += edge[:length] if edge[:type] == :cornerconvex
        end

        expect(l_fen    ).to be_within(TOL).of( 0.00)
        expect(l_head   ).to be_within(TOL).of(46.35)
        expect(l_sill   ).to be_within(TOL).of(46.35)
        expect(l_jamb   ).to be_within(TOL).of(46.35)
        expect(l_grade  ).to be_within(TOL).of(27.69)
        expect(l_parapet).to be_within(TOL).of(27.69)
        expect(l_corner ).to be_within(TOL).of( 6.10)
      end
    end
  end

  it "can process DOE Prototype warehouse.osm" do
    translator = OpenStudio::OSVersion::VersionTranslator.new
    TBD.clean!

    file  = File.join(__dir__, "files/osms/in/warehouse.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    model.getSurfaces.each do |s|
      next unless s.outsideBoundaryCondition == "Outdoors"

      expect(s.space).to_not be_empty
      expect(s.isConstructionDefaulted).to be true
      c = s.construction
      expect(c).to_not be_empty
      c = c.get.to_LayeredConstruction
      expect(c).to_not be_empty
      c = c.get

      id   = c.nameString
      name = s.nameString
      expect(c.layers[1].to_MasslessOpaqueMaterial).to_not be_empty

      m = c.layers[1].to_MasslessOpaqueMaterial.get
      r = m.thermalResistance

      if name.include?("Bulk")
        expect(r).to be_within(TOL).of(1.33) if id.include?("Wall")
        expect(r).to be_within(TOL).of(1.68) if id.include?("Roof")
      else
        expect(r).to be_within(TOL).of(1.87) if id.include?("Wall")
        expect(r).to be_within(TOL).of(3.06) if id.include?("Roof")
      end
    end

    argh = { option: "poor (BETBG)" }

    json     = TBD.process(model, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty
    expect(surfaces).to be_a(Hash)
    expect(surfaces.size).to eq(23)
    expect(io).to be_a(Hash)
    expect(io).to have_key(:edges)
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
            l: "Bulk Storage Right Wall"
          }.freeze

    # Testing.
    surfaces.each do |id, surface|
      expect(ids).to     have_value(id)     if surface.key?(:edges)
      expect(ids).to_not have_value(id) unless surface.key?(:edges)
    end

    surfaces.each do |id, surface|
      next unless surface.key?(:edges)

      expect(ids).to have_value(id)
      expect(surface).to have_key(:heatloss)
      expect(surface).to have_key(:ratio)
      h = surface[:heatloss]
      s = model.getSurfaceByName(id)
      expect(s).to_not be_empty
      s = s.get
      expect(s.nameString).to eq(id)
      expect(s.isConstructionDefaulted).to be false
      expect(s.construction.get.nameString).to include(" tbd")
      expect(h).to be_within(TOL).of( 50.20) if id == ids[:a]
      expect(h).to be_within(TOL).of( 24.06) if id == ids[:b]
      expect(h).to be_within(TOL).of( 87.16) if id == ids[:c]
      expect(h).to be_within(TOL).of( 22.61) if id == ids[:d]
      expect(h).to be_within(TOL).of(  9.15) if id == ids[:e]
      expect(h).to be_within(TOL).of( 26.47) if id == ids[:f]
      expect(h).to be_within(TOL).of( 27.19) if id == ids[:g]
      expect(h).to be_within(TOL).of( 41.36) if id == ids[:h]
      expect(h).to be_within(TOL).of(161.02) if id == ids[:i]
      expect(h).to be_within(TOL).of( 62.28) if id == ids[:j]
      expect(h).to be_within(TOL).of(117.87) if id == ids[:k]
      expect(h).to be_within(TOL).of( 95.77) if id == ids[:l]

      c = s.construction
      expect(c).to_not be_empty
      c = c.get.to_LayeredConstruction
      expect(c).to_not be_empty
      c = c.get
      expect(c.layers[1].nameString).to include("m tbd")
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
    translator = OpenStudio::OSVersion::VersionTranslator.new
    TBD.clean!

    file  = File.join(__dir__, "files/osms/in/warehouse.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    # Run the measure with a basic TBD JSON input file, e.g.
    #   - a custom PSI set, e.g. "compliant" set
    #   - (4x) custom edges, e.g. "bad" :fenestration perimeters between
    #      - "Office Left Wall Window1" & "Office Left Wall"
    #
    # The TBD JSON input file should hold the following:
    #
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
    argh               = {}
    argh[:option     ] = "(non thermal bridging)"
    argh[:io_path    ] = File.join(__dir__, "../json/tbd_warehouse.json")
    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")

    json     = TBD.process(model, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty
    expect(surfaces).to be_a(Hash)
    expect(surfaces.size).to eq(23)
    expect(io).to be_a(Hash)
    expect(io).to have_key(:edges)
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
            l: "Bulk Storage Right Wall"
          }.freeze

    surfaces.each do |id, surface|
      expect(ids).to     have_value(id)     if surface.key?(:edges)
      expect(ids).to_not have_value(id) unless surface.key?(:edges)
    end

    surfaces.each do |id, surface|
      next unless surface.key?(:edges)

      expect(ids).to have_value(id)
      expect(surface).to have_key(:ratio)
      expect(surface).to have_key(:heatloss)
      h = surface[:heatloss]
      s = model.getSurfaceByName(id)
      expect(s).to_not be_empty
      s = s.get
      expect(s.nameString).to eq(id)
      expect(s.isConstructionDefaulted).to be false
      expect(s.construction.get.nameString).to include(" tbd")
      expect(h).to be_within(TOL).of( 25.90) if id == ids[:a]
      expect(h).to be_within(TOL).of( 17.41) if id == ids[:b] # 13.38 compliant
      expect(h).to be_within(TOL).of( 45.44) if id == ids[:c]
      expect(h).to be_within(TOL).of(  8.04) if id == ids[:d]
      expect(h).to be_within(TOL).of(  3.46) if id == ids[:e]
      expect(h).to be_within(TOL).of( 13.27) if id == ids[:f]
      expect(h).to be_within(TOL).of( 14.04) if id == ids[:g]
      expect(h).to be_within(TOL).of( 21.20) if id == ids[:h]
      expect(h).to be_within(TOL).of( 88.34) if id == ids[:i]
      expect(h).to be_within(TOL).of( 30.98) if id == ids[:j]
      expect(h).to be_within(TOL).of( 64.44) if id == ids[:k]
      expect(h).to be_within(TOL).of( 48.97) if id == ids[:l]

      c = s.construction
      expect(c).to_not be_empty
      c = c.get.to_LayeredConstruction
      expect(c).to_not be_empty
      c = c.get
      expect(c.layers[1].nameString).to include("m tbd")
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
    out  = JSON.pretty_generate(io)
    outP = File.join(__dir__, "../json/tbd_warehouse.out.json")
    File.open(outP, "w") { |outP| outP.puts out }

    # 2. Re-use the exported file as input for another warehouse.
    model2 = translator.loadModel(path)
    expect(model2).to_not be_empty
    model2 = model2.get

    argh[:io_path] = File.join(__dir__, "../json/tbd_warehouse.out.json")

    json2    = TBD.process(model2, argh)
    expect(json2).to be_a(Hash)
    expect(json2).to have_key(:io)
    expect(json2).to have_key(:surfaces)
    io2      = json2[:io      ]
    surfaces = json2[:surfaces]
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty
    expect(surfaces).to be_a(Hash)
    expect(surfaces.size).to eq(23)
    expect(io).to be_a(Hash)
    expect(io).to have_key(:edges)
    expect(io[:edges].size).to eq(300)

    # Testing (again).
    surfaces.each do |id, surface|
      next unless surface.key?(:edges)

      expect(surface).to have_key(:ratio)
      expect(surface).to have_key(:heatloss)
      h = surface[:heatloss]
      s = model.getSurfaceByName(id)
      expect(s).to_not be_empty
      s = s.get
      expect(s.nameString).to eq(id)
      expect(s.isConstructionDefaulted).to be false
      expect(s.construction.get.nameString).to include(" tbd")
      expect(h).to be_within(TOL).of( 25.90) if id == ids[:a]
      expect(h).to be_within(TOL).of( 17.41) if id == ids[:b]
      expect(h).to be_within(TOL).of( 45.44) if id == ids[:c]
      expect(h).to be_within(TOL).of(  8.04) if id == ids[:d]
      expect(h).to be_within(TOL).of(  3.46) if id == ids[:e]
      expect(h).to be_within(TOL).of( 13.27) if id == ids[:f]
      expect(h).to be_within(TOL).of( 14.04) if id == ids[:g]
      expect(h).to be_within(TOL).of( 21.20) if id == ids[:h]
      expect(h).to be_within(TOL).of( 88.34) if id == ids[:i]
      expect(h).to be_within(TOL).of( 30.98) if id == ids[:j]
      expect(h).to be_within(TOL).of( 64.44) if id == ids[:k]
      expect(h).to be_within(TOL).of( 48.97) if id == ids[:l]

      c = s.construction
      expect(c).to_not be_empty
      c = c.get.to_LayeredConstruction
      expect(c).to_not be_empty
      c = c.get
      expect(c.layers[1].nameString).to include("m tbd")
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

    # Now mimic (again) the export functionality of the measure. Both output
    # files should be the same.
    out2  = JSON.pretty_generate(io2)
    outP2 = File.join(__dir__, "../json/tbd_warehouse2.out.json")
    File.open(outP2, "w") { |outP2| outP2.puts out2 }
    expect(FileUtils).to be_identical(outP, outP2)
  end

  it "can process DOE Prototype warehouse.osm + JSON I/O (2)" do
    translator = OpenStudio::OSVersion::VersionTranslator.new
    TBD.clean!

    file  = File.join(__dir__, "files/osms/in/warehouse.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    # Run the measure with a basic TBD JSON input file, e.g.
    #   - a custom PSI set, e.g. "compliant" set
    #   - (1x) custom edges, e.g. "bad" :fenestration perimeters between
    #     - "Office Left Wall Window1" & "Office Left Wall"
    #     - 1x? this time, with explicit 3D coordinates for shared edge.
    #
    # The TBD JSON input file should hold the following:
    #
    # "edges": [
    #  {
    #    "psi": "bad",
    #    "type": "fen",
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
    argh               = {}
    argh[:option     ] = "(non thermal bridging)"
    argh[:io_path    ] = File.join(__dir__, "../json/tbd_warehouse1.json")
    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")

    json     = TBD.process(model, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty
    expect(surfaces).to be_a(Hash)
    expect(surfaces.size).to eq(23)
    expect(io).to be_a(Hash)
    expect(io).to have_key(:edges)
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
      expect(ids).to     have_value(id)     if surface.key?(:edges)
      expect(ids).to_not have_value(id) unless surface.key?(:edges)
    end

    surfaces.each do |id, surface|
      next unless surface.key?(:edges)

      expect(ids).to have_value(id)
      expect(surface).to have_key(:ratio)
      expect(surface).to have_key(:heatloss)
      h = surface[:heatloss]
      s = model.getSurfaceByName(id)
      expect(s).to_not be_empty
      s = s.get
      expect(s.nameString).to eq(id)
      expect(s.isConstructionDefaulted).to be false
      expect(s.construction.get.nameString).to include(" tbd")
      expect(h).to be_within(TOL).of( 25.90) if id == ids[:a]
      expect(h).to be_within(TOL).of( 14.55) if id == ids[:b] # 13.4 compliant
      expect(h).to be_within(TOL).of( 45.44) if id == ids[:c]
      expect(h).to be_within(TOL).of(  8.04) if id == ids[:d]
      expect(h).to be_within(TOL).of(  3.46) if id == ids[:e]
      expect(h).to be_within(TOL).of( 13.27) if id == ids[:f]
      expect(h).to be_within(TOL).of( 14.04) if id == ids[:g]
      expect(h).to be_within(TOL).of( 21.20) if id == ids[:h]
      expect(h).to be_within(TOL).of( 88.34) if id == ids[:i]
      expect(h).to be_within(TOL).of( 30.98) if id == ids[:j]
      expect(h).to be_within(TOL).of( 64.44) if id == ids[:k]
      expect(h).to be_within(TOL).of( 48.97) if id == ids[:l]

      c = s.construction
      expect(c).to_not be_empty
      c = c.get.to_LayeredConstruction
      expect(c).to_not be_empty
      c = c.get
      expect(c.layers[1].nameString).to include("m tbd")
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
    out  = JSON.pretty_generate(io)
    outP = File.join(__dir__, "../json/tbd_warehouse1.out.json")
    File.open(outP, "w") { |outP| outP.puts out }

    # 2. Re-use the exported file as input for another warehouse
    model2 = translator.loadModel(path)
    expect(model2).to_not be_empty
    model2 = model2.get

    argh[:io_path] = File.join(__dir__, "../json/tbd_warehouse1.out.json")

    json2    = TBD.process(model2, argh)
    expect(json2).to be_a(Hash)
    expect(json2).to have_key(:io)
    expect(json2).to have_key(:surfaces)
    io2      = json2[:io      ]
    surfaces = json2[:surfaces]
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty
    expect(surfaces).to be_a(Hash)
    expect(surfaces.size).to eq(23)
    expect(io).to be_a(Hash)
    expect(io).to have_key(:edges)
    expect(io[:edges].size).to eq(300)

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

    # Now mimic (again) the export functionality of the measure. Both output
    # files should be the same.
    out2  = JSON.pretty_generate(io2)
    outP2 = File.join(__dir__, "../json/tbd_warehouse3.out.json")
    File.open(outP2, "w") { |outP2| outP2.puts out2 }
    expect(FileUtils).to be_identical(outP, outP2)
  end

  it "can factor in spacetype-specific PSI sets (JSON input)" do
    translator = OpenStudio::OSVersion::VersionTranslator.new
    TBD.clean!

    file  = File.join(__dir__, "files/osms/in/warehouse.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    argh               = {}
    argh[:option     ] = "compliant" # superseded by :building PSI set on file
    argh[:io_path    ] = File.join(__dir__, "../json/tbd_warehouse5.json")
    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")

    json     = TBD.process(model, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty
    expect(surfaces).to be_a(Hash)
    expect(surfaces.size).to eq(23)
    expect(io).to be_a(Hash)
    expect(io).to have_key(:spacetypes)
    expect(io).to have_key(:edges)
    expect(io[:edges].size).to eq(300)

    sTyp1 = "Warehouse Office"
    sTyp2 = "Warehouse Fine"

    io[:spacetypes].each do |spacetype|
      expect(spacetype).to have_key(:id)
      expect(spacetype[:id]).to eq(sTyp1).or eq(sTyp2)
      expect(spacetype).to have_key(:psi)
    end

    surfaces.each do |id, surface|
      next unless surface[:boundary].downcase == "outdoors"
      next unless surface.key?(:ratio)

      expect(surface).to have_key(:heatloss)
      heatloss = surface[:heatloss]
      expect(heatloss.abs).to be > 0
      expect(surface).to have_key(:space)
      next unless surface[:space].nameString == "Zone1 Office"

      # All applicable thermal bridges/edges derating the office walls inherit
      # the "Warehouse Office" spacetype PSI values (JSON file), except for the
      # shared :rimjoist with the Fine Storage space above. The "Warehouse Fine"
      # spacetype set has a higher :rimjoist PSI value of 0.5 W/K per metre,
      # which overrides the "Warehouse Office" value of 0.3 W/K per metre.
      expect(heatloss).to be_within(TOL).of(11.61) if id == "Office Left Wall"
      expect(heatloss).to be_within(TOL).of(22.94) if id == "Office Front Wall"
    end
  end

  it "can sort multiple story-specific PSI sets (JSON input)" do
    translator = OpenStudio::OSVersion::VersionTranslator.new
    TBD.clean!

    file  = File.join(__dir__, "files/osms/in/midrise.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    model.getSpaces.each do |space|
      expect(space.thermalZone).to_not be_empty
      zone  = space.thermalZone.get
      stpts = TBD.setpoints(space)
      expect(TBD.plenum?(space)).to be false
      expect(stpts).to have_key(:heating)
      expect(stpts).to have_key(:cooling)

      if zone.nameString == "Office ZN"
        expect(stpts[:heating]).to be_within(0.1).of(21.1)
        expect(stpts[:cooling]).to be_within(0.1).of(23.9)
      else
        expect(stpts[:heating]).to be_within(0.1).of(21.7)
        expect(stpts[:cooling]).to be_within(0.1).of(24.4)
      end
    end

    argh               = {}
    argh[:option     ] = "(non thermal bridging)" # overridden
    argh[:io_path    ] = File.join(__dir__, "../json/midrise.json")
    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")

    json     = TBD.process(model, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty
    expect(surfaces).to be_a(Hash)
    expect(surfaces.size).to eq(180)
    expect(io).to be_a(Hash)
    expect(io).to have_key(:stories)
    expect(io).to have_key(:edges)
    expect(io[:edges].size).to eq(282)

    surfaces.each do |id, surface|
      expect(surface).to have_key(:conditioned)
      next unless surface[:conditioned]

      expect(surface).to have_key(:heating)
      expect(surface).to have_key(:cooling)
    end

    # A side test. Validating that TBD doesn't tag shared edge between exterior
    # wall and interior ceiling (adiabatic conditions) as 'party' for
    # 'multiplied' mid-level spaces. In fact, there shouldn't be a single
    # instance of a 'party' edge in the TBD model.
    surfaces.each do |id, surface|
      next unless surface.key?(:ratio)

      expect(surface).to have_key(:edges)

      surface[:edges].values.each do |edge|
        expect(edge).to have_key(:type)
        expect(edge[:type]).to_not eq(:party)
      end
    end

    expect(io[:stories].size).to eq(3)
    stories = ["Building Story 1", "Building Story 2", "Building Story 3"]
    types   = [:parapetconvex, :transition]

    io[:stories].each do |story|
      expect(story).to have_key(:psi)
      expect(story).to have_key(:id)
      expect(stories).to include(story[:id])
    end

    counter = 0

    surfaces.each do |id, surface|
      next unless surface.key?(:ratio)

      expect(surface).to have_key(:story)
      expect(surface).to have_key(:boundary)
      expect(surface[:boundary]).to eq("Outdoors")

      nom = surface[:story].nameString
      expect(stories).to include(nom)
      expect(nom).to eq(stories[0]) if id.include?("g ")
      expect(nom).to eq(stories[1]) if id.include?("m ")
      expect(nom).to eq(stories[2]) if id.include?("t ")
      expect(surface).to have_key(:edges)

      counter += 1

      # Illustrating that story-specific PSI set is used when only 1x story.
      surface[:edges].values.each do |edge|
        expect(edge).to have_key(:type)
        expect(edge).to have_key(:psi)
        next unless id.include?("Roof")

        expect(types).to include(edge[:type])
        next unless edge[:type] == :parapetconvex
        next     if id == "t Roof C"

        expect(edge[:psi]).to be_within(TOL).of(0.178) # 57.3% of 0.311
      end

      # Illustrating that story-specific PSI set is used when only 1x story.
      surface[:edges].values.each do |edge|
        next unless id.include?("t ")
        next unless id.include?("Wall ")
        next unless edge[:type] == :parapetconvex
        next     if id.include?(" C")

        expect(edge[:psi]).to be_within(TOL).of(0.133) # 42.7% of 0.311
      end

      # The shared :rimjoist between middle story and ground floor units could
      # either inherit the "Building Story 1" or "Building Story 2" :rimjoist
      # PSI values. TBD retains the most conductive PSI values in such cases.
      surface[:edges].values.each do |edge|
        next unless id.include?("m ")
        next unless id.include?("Wall ")
        next     if id.include?(" C")
        next unless edge[:type] == :rimjoist

        # Inheriting "Building Story 1" :rimjoist PSI of 0.501 W/K per metre.
        # The SEA unit is above an office space below, which has curtain wall.
        # RSi of insulation layers (to derate):
        #   - office walls   : 0.740 m2.K/W (26.1%)
        #   - SEA walls      : 2.100 m2.K/W (73.9%)
        #
        #   - SEA walls      : 26.1% of 0.501 = 0.3702 W/K per metre
        #   - other walls    : 50.0% of 0.501 = 0.2505 W/K per metre
        if ["m SWall SEA", "m EWall SEA"].include?(id)
          expect(edge[:psi]).to be_within(0.002).of(0.3702)
        else
          expect(edge[:psi]).to be_within(0.002).of(0.2505)
        end
      end
    end

    expect(counter).to eq(51)
  end

  it "can process seb.osm (UNCONDITIONED attic)" do
    translator = OpenStudio::OSVersion::VersionTranslator.new
    version    = OpenStudio.openStudioVersion.split(".").join.to_i
    TBD.clean!

    file  = File.join(__dir__, "files/osms/in/seb.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    # Consider the plenum as UNCONDITIONED - not indirectly-conditioned.
    plnum = model.getSpaceByName("Level 0 Ceiling Plenum")
    expect(plnum).to_not be_empty
    plnum = plnum.get
    expect(TBD.unconditioned?(plnum)).to be false

    key = "space_conditioning_category"
    val = "Unconditioned"
    expect(plnum.additionalProperties.hasFeature(key)).to be false
    expect(plnum.additionalProperties.setFeature(key, val)).to be true
    expect(TBD.plenum?(plnum)).to be true # fyi, still has "plenum" spacetype
    expect(TBD.unconditioned?(plnum)).to be true # ... more reliable
    expect(TBD.setpoints(plnum)[:heating]).to be_nil
    expect(TBD.setpoints(plnum)[:cooling]).to be_nil
    expect(TBD.status).to be_zero

    model.getSurfaces.each do |s|
      expect(s.space).to_not be_empty
      expect(s.isConstructionDefaulted).to be false
      c = s.construction
      expect(c).to_not be_empty
      c = c.get.to_LayeredConstruction
      expect(c).to_not be_empty
      c = c.get

      id   = c.nameString
      name = s.nameString

      if s.outsideBoundaryCondition == "Outdoors"
        expect(c.layers.size).to eq(4)
        expect(c.layers[2].to_StandardOpaqueMaterial).to_not be_empty
        m = c.layers[2].to_StandardOpaqueMaterial.get
        r = m.thickness / m.thermalConductivity
        expect(r).to be_within(TOL).of(1.47) if s.surfaceType == "Wall"
        expect(r).to be_within(TOL).of(5.08) if s.surfaceType == "RoofCeiling"
      elsif s.outsideBoundaryCondition == "Surface"
        next unless s.surfaceType == "RoofCeiling"

        expect(c.layers.size).to eq(1)
        expect(c.layers[0].to_StandardOpaqueMaterial).to_not be_empty
        m = c.layers[0].to_StandardOpaqueMaterial.get
        r = m.thickness / m.thermalConductivity
        expect(r).to be_within(TOL).of(0.12)
      end
    end

    # Save model as UNCONDITIONED.
    file = File.join(__dir__, "files/osms/out/unconditioned.osm")
    model.save(file, true)

    # The v1.11.5 (2016) seb.osm, shipped with OpenStudio, holds (what would now
    # be considered as deprecated) a definition of plenum floors (i.e. ceiling
    # tiles) generating quite a few warnings. From 'run/eplusout.err' (24.1.0):
    #
    # ** Warning ** GetSurfaceData: InterZone Surface Tilts do not match ....
    # **   ~~~   **   Tilt=0.0 in Surface=LEVEL 0 ENTRY WAY  CEILING PLENUM ...
    # **   ~~~   **   Tilt=0.0 in Surface=ENTRY WAY  DROPPEDCEILING, Zone ...
    # ** Warning ** GetSurfaceData: InterZone Surface Classes do not match ...
    # **   ~~~   ** Surface="LEVEL 0 ENTRY WAY  CEILING PLENUM DROPPEDCEILING"
    # **   ~~~   ** Adjacent Surface="ENTRY WAY  DROPPEDCEILING", surface ...
    # **   ~~~   ** Other errors/warnings may follow about these surfaces.
    # ** Warning ** GetSurfaceData: InterZone Surface Tilts do not match ....
    # **   ~~~   **   Tilt=0.0 in Surface=LEVEL 0 OPEN AREA 1 CEILING PLENUM ...
    # **   ~~~   **   Tilt=0.0 in Surface=OPEN AREA 1 DROPPEDCEILING, ...
    # ** Warning ** GetSurfaceData: InterZone Surface Classes do not match ....
    # **   ~~~   ** Surface="LEVEL 0 OPEN AREA 1 CEILING PLENUM DROPPEDCEILING",
    # **   ~~~   ** Adjacent Surface="OPEN AREA 1 DROPPEDCEILING", surface ...
    # **   ~~~   ** Other errors/warnings may follow about these surfaces.
    # ** Warning ** GetSurfaceData: InterZone Surface Tilts do not match ....
    # **   ~~~   **   Tilt=0.0 in Surface=LEVEL 0 SMALL OFFICE 1 CEILING ...
    # **   ~~~   **   Tilt=0.0 in Surface=SMALL OFFICE 1 DROPPEDCEILING, ...
    # ** Warning ** GetSurfaceData: InterZone Surface Classes do not match ....
    # **   ~~~   ** Surface="LEVEL 0 SMALL OFFICE 1 CEILING PLENUM ...
    # **   ~~~   ** Adjacent Surface="SMALL OFFICE 1 DROPPEDCEILING", ...
    # **   ~~~   ** Other errors/warnings may follow about these surfaces.
    # ** Warning ** GetSurfaceData: InterZone Surface Tilts do not match ....
    # **   ~~~   **   Tilt=0.0 in Surface=LEVEL 0 UTILITY 1 CEILING PLENUM ...
    # **   ~~~   **   Tilt=0.0 in Surface=UTILITY 1 DROPPEDCEILING, ...
    # ** Warning ** GetSurfaceData: InterZone Surface Classes do not match ....
    # **   ~~~   ** Surface="LEVEL 0 UTILITY 1 CEILING PLENUM DROPPEDCEILING",
    # **   ~~~   ** Adjacent Surface="UTILITY 1 DROPPEDCEILING", surface ...
    # **   ~~~   ** Other errors/warnings may follow about these surfaces.
    # ** Warning ** No floor exists in Zone="LEVEL 0 CEILING PLENUM ZONE", ...
    # ** Warning ** CalculateZoneVolume: 1 zone is not fully enclosed ...

    # Ensuring TBD similarly derates model surfaces, before vs after the fix. In
    # other words, TBD doesn't trip over a plenum "Floor" vs "RoofCeiling" when
    # the plenum is UNCONDITIONED like a vented attic.
    2.times do |time|
      unless time.zero?
        file  = File.join(__dir__, "files/osms/out/unconditioned.osm")
        path  = OpenStudio::Path.new(file)
        model = translator.loadModel(path)
        expect(model).to_not be_empty
        model = model.get

        # "Shading Surface 4" is overlapping with a plenum exterior wall.
        sh4 = model.getShadingSurfaceByName("Shading Surface 4")
        expect(sh4).to_not be_empty
        sh4 = sh4.get
        sh4.remove

        plnum = model.getSpaceByName("Level 0 Ceiling Plenum")
        expect(plnum).to_not be_empty
        plnum = plnum.get
        expect(TBD.unconditioned?(plnum)).to be true

        thzone = plnum.thermalZone
        expect(thzone).to_not be_empty
        thzone = thzone.get

        # Before the fix.
        unless version < 350
          expect(plnum.isEnclosedVolume).to be true
          expect(plnum.isVolumeDefaulted).to be true
          expect(plnum.isVolumeAutocalculated).to be true
        end

        if version > 350 && version < 370
          expect(plnum.volume.round(0)).to eq(234)
        else
          expect(plnum.volume.round(0)).to eq(0)
        end

        expect(thzone.isVolumeDefaulted).to be true
        expect(thzone.isVolumeAutocalculated).to be true
        expect(thzone.volume).to be_empty

        plnum.surfaces.each do |s|
          next if s.outsideBoundaryCondition.downcase == "outdoors"

          # If a SEB plenum surface isn't facing outdoors, it's 1 of 4 "floor"
          # surfaces (each facing a ceiling surface below).
          adj = s.adjacentSurface
          expect(adj).to_not be_empty
          adj = adj.get
          expect(adj.vertices.size).to eq(s.vertices.size)

          # Same vertex sequence? Should be in reverse order.
          adj.vertices.each_with_index do |vertex, i|
            expect(TBD.same?(vertex, s.vertices.at(i))).to be true
          end

          expect(adj.surfaceType).to eq("RoofCeiling")
          expect(s.surfaceType).to eq("RoofCeiling")
          expect(s.setSurfaceType("Floor")).to be true
          expect(s.setVertices(s.vertices.reverse)).to be true

          # Vertices now in reverse order.
          adj.vertices.reverse.each_with_index do |vertex, i|
            expect(TBD.same?(vertex, s.vertices.at(i))).to be true
          end
        end

        # Save for future testing.
        file = File.join(__dir__, "files/osms/out/unconditioned2.osm")
        model.save(file, true)

        # After the fix.
        unless version < 350
          expect(plnum.isEnclosedVolume).to be true
          expect(plnum.isVolumeDefaulted).to be true
          expect(plnum.isVolumeAutocalculated).to be true
        end

        expect(plnum.volume.round(0)).to eq(50)
        expect(thzone.isVolumeDefaulted).to be true
        expect(thzone.isVolumeAutocalculated).to be true
        expect(thzone.volume).to be_empty
      end

      argh = {option: "poor (BETBG)"}

      json     = TBD.process(model, argh)
      expect(json).to be_a(Hash)
      expect(json).to have_key(:io)
      expect(json).to have_key(:surfaces)
      io       = json[:io      ]
      surfaces = json[:surfaces]
      expect(TBD.status).to be_zero
      expect(TBD.logs).to be_empty
      expect(surfaces).to be_a(Hash)
      expect(surfaces.size).to eq(56)
      expect(io).to be_a(Hash)
      expect(io).to have_key(:edges)
      expect(io[:edges].size).to eq(80)

      edges = io[:edges]
      edges = edges.reject { |s| s.to_s.include?("sill"  ) }
      edges = edges.reject { |s| s.to_s.include?("head"  ) }
      edges = edges.reject { |s| s.to_s.include?("jamb"  ) }
      edges = edges.reject { |s| s.to_s.include?("grade" ) }
      edges = edges.reject { |s| s.to_s.include?("corner") }
      edges = edges.reject { |s| s.to_s.include?("sill"  ) }

      expect(edges.size).to eq(26)

      edges.each do |edge|
        type      = edge[:type    ]
        size      = edge[:surfaces].size
        shades    = edge[:surfaces].select { |s| s.include?("Shading") }
        walls     = edge[:surfaces].select { |s| s.include?("Wall") }
        ceilings  = edge[:surfaces].select { |s| s.include?("DroppedCeiling") }

        pceilings = ceilings.select { |s| s.include?("Plenum") }
        expect(type).to eq(:transition).or eq(:parapetconvex)

        if type == :transition
          if size == 2 || size == 4
            expect(walls.size).to eq(size)
          elsif size == 3
            expect(shades.size).to eq(1)
            expect(walls.size).to eq(2)
          else
            expect(size).to eq(6)
            # ... shared between:
            #   - 1x paired interior walls                    = 2x
            #   - 2x pairs of adjacent ceilings (either side) = 4x
            #     ___________________________________________ = 6x in TOTAL
            expect(walls.size).to eq(2)
            expect(ceilings.size).to eq(4)
            expect(pceilings.size).to eq(2)
          end
        else
          # ... shared between:
          #   - 1x exterior wall (occupied space)             = 1x
          #   - 1x plenum wall overhead                       = 1x
          #   - 1x shading (maybe)
          #   - 1x pair of adjacent ceilings (either side)    = 2x
          #     _____________________________________________ = 4x (or 5x) in TOTAL
          if size == 5
            expect(shades.size).to eq(1)
          else
            expect(size).to eq(4)
            expect(shades.size).to eq(0)
          end

          expect(walls.size).to eq(2)
          expect(ceilings.size).to eq(2)
          expect(pceilings.size).to eq(1)
        end
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
              q: "Open area 1 DroppedCeiling"
            }.freeze

      surfaces.each do |id, surface|
        expect(surface).to have_key(:deratable)
        expect(surface).to have_key(:conditioned)
        expect(surface).to have_key(:space)
        space = surface[:space]
        next unless surface[:deratable]

        expect(surface[:conditioned]).to be false    if space == plnum
        expect(surface[:conditioned]).to be true unless space == plnum
        expect(ids).to_not have_value(id)            if space == plnum
        expect(ids).to have_value(id)            unless space == plnum
        next unless surface[:conditioned]

        expect(surface).to have_key(:edges)
        expect(surface).to have_key(:heating)
        expect(surface).to have_key(:cooling)
      end

      surfaces.each do |id, surface|
        next unless surface.key?(:edges)

        expect(surface).to have_key(:ratio)
        expect(surface).to have_key(:heatloss)
        h = surface[:heatloss]
        s = model.getSurfaceByName(id)
        expect(s).to_not be_empty
        s = s.get
        expect(s.nameString).to eq(id)
        expect(s.isConstructionDefaulted).to be false
        expect(s.construction.get.nameString).to include(" tbd")
        expect(h).to be_within(TOL).of( 6.43) if id == ids[:a]
        expect(h).to be_within(TOL).of(11.18) if id == ids[:b]
        expect(h).to be_within(TOL).of( 4.56) if id == ids[:c]
        expect(h).to be_within(TOL).of( 0.42) if id == ids[:d]
        expect(h).to be_within(TOL).of(12.66) if id == ids[:e]
        expect(h).to be_within(TOL).of(12.59) if id == ids[:f]
        expect(h).to be_within(TOL).of( 0.50) if id == ids[:g]
        expect(h).to be_within(TOL).of(14.06) if id == ids[:h]
        expect(h).to be_within(TOL).of( 9.04) if id == ids[:i]
        expect(h).to be_within(TOL).of( 8.75) if id == ids[:j]
        expect(h).to be_within(TOL).of( 0.53) if id == ids[:k]
        expect(h).to be_within(TOL).of( 5.06) if id == ids[:l]
        expect(h).to be_within(TOL).of( 6.25) if id == ids[:m]
        expect(h).to be_within(TOL).of( 9.04) if id == ids[:n]
        expect(h).to be_within(TOL).of( 6.74) if id == ids[:o]
        expect(h).to be_within(TOL).of( 4.32) if id == ids[:p]
        expect(h).to be_within(TOL).of( 0.76) if id == ids[:q]

        c = s.construction
        expect(c).to_not be_empty
        c = c.get.to_LayeredConstruction
        expect(c).to_not be_empty
        c = c.get
        i = 0
        i = 2 if s.outsideBoundaryCondition == "Outdoors"
        expect(c.layers[i].nameString).to include("m tbd")
      end

      surfaces.each do |id, surface|
        if surface.key?(:ratio)
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

          s = model.getSurfaceByName(id)
          expect(s).to_not be_empty
          s = s.get
          expect(s.nameString).to eq(id)
          expect(s.surfaceType).to eq("Wall")
          expect(s.isConstructionDefaulted).to be false
          c = s.construction.get.to_LayeredConstruction
          expect(c).to_not be_empty
          c = c.get
          expect(c.nameString).to include("c tbd")
          expect(c.layers.size).to eq(4)
          expect(c.layers[2].nameString).to include("m tbd")
          expect(c.layers[2].to_StandardOpaqueMaterial).to_not be_empty
          m = c.layers[2].to_StandardOpaqueMaterial.get

          initial_R = s.filmResistance + 2.4674
          derated_R = s.filmResistance + 0.9931
          derated_R += m.thickness / m.thermalConductivity

          ratio = -(initial_R - derated_R) * 100 / initial_R
          expect(ratio).to be_within(1).of(surfaces[id][:ratio])
        else
          if surface[:boundary].downcase == "outdoors"
            expect(surface[:conditioned]).to be false
          end
        end
      end
    end

    #            MODEL VARIANT   annual GJ  (PRE-TBD)
    # ________________________   _________
    #        unconditioned SEB      257.04
    #  fixed unconditioned SEB      258.40
    # ________________________   _________
    #                                +1.36  (+0.5%) ... QC City, OS v3.6.1
    #
    # A diff comparison of both generated .osm files do not reveal changes other
    # than the aforementioned fixes (before running TBD). Boils down to removing
    # the fixed shading? "Floor" vs "RoofCeiling" heat transfer coefficients?
    # In any case, GJ differences are about the same (pre- vs post-TBD).
    #
    #            MODEL VARIANT   annual GJ  (POST-TBD)
    # ________________________   _________
    #        unconditioned SEB      262.70
    #  fixed unconditioned SEB      264.05
    # ________________________   _________
    #                               +1.35  (+0.5%) ... QC City, OS v3.6.1
  end

  it "can process seb.osm (CONDITIONED plenum)" do
    translator = OpenStudio::OSVersion::VersionTranslator.new
    version    = OpenStudio.openStudioVersion.split(".").join.to_i
    TBD.clean!

    file  = File.join(__dir__, "files/osms/in/seb.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    # Out of the box, plenum is INDIRECTLY-CONDITIONED - not UNCONDITIONED.
    plnum = model.getSpaceByName("Level 0 Ceiling Plenum")
    expect(plnum).to_not be_empty
    plnum = plnum.get

    expect(TBD.plenum?(plnum)).to be true # has "plenum" spacetype
    expect(TBD.unconditioned?(plnum)).to be false
    expect(TBD.setpoints(plnum)[:heating].to_i).to eq(21)
    expect(TBD.setpoints(plnum)[:cooling].to_i).to eq(24)
    expect(TBD.status).to be_zero

    # Contrary to the previous "seb.osm (UNCONDITIONED) attic" RSpec, the fix
    # triggers TBD to label as ":ceiling" edges shared by:
    #   - 1x plenum "Floor"
    #   - 1x adjacent (occupied) room "RoofCeiling"
    #   - 1x plenum outdoor-facing "Wall"
    #   - 1x (occupied) room outdoor-facing "Wall"
    #
    # Before the fix, TBD labels these same edges as ":transition". In normal
    # circumstances, this wouldn't usually affect simulation results, as both
    # :transition and :ceiling PSI-factors would normally be set to 0.0 W/K per
    # linear meter. But users remain free to reset either value, so ...
    2.times do |time|
      unless time.zero?
        file  = File.join(__dir__, "files/osms/in/seb.osm")
        path  = OpenStudio::Path.new(file)
        model = translator.loadModel(path)
        expect(model).to_not be_empty
        model = model.get

        # "Shading Surface 4" is overlapping with a plenum exterior wall.
        sh4 = model.getShadingSurfaceByName("Shading Surface 4")
        expect(sh4).to_not be_empty
        sh4 = sh4.get
        sh4.remove

        plnum = model.getSpaceByName("Level 0 Ceiling Plenum")
        expect(plnum).to_not be_empty
        plnum = plnum.get

        thzone = plnum.thermalZone
        expect(thzone).to_not be_empty
        thzone = thzone.get

        # Before the fix.
        unless version < 350
          expect(plnum.isEnclosedVolume).to be true
          expect(plnum.isVolumeDefaulted).to be true
          expect(plnum.isVolumeAutocalculated).to be true
        end

        if version > 350 && version < 370
          expect(plnum.volume.round(0)).to eq(234)
        else
          expect(plnum.volume.round(0)).to eq(0)
        end

        expect(thzone.isVolumeDefaulted).to be true
        expect(thzone.isVolumeAutocalculated).to be true
        expect(thzone.volume).to be_empty

        plnum.surfaces.each do |s|
          next if s.outsideBoundaryCondition.downcase == "outdoors"

          # If a SEB plenum surface isn't facing outdoors, it's 1 of 4 "floor"
          # surfaces (each facing a ceiling surface below).
          adj = s.adjacentSurface
          expect(adj).to_not be_empty
          adj = adj.get
          expect(adj.vertices.size).to eq(s.vertices.size)

          # Same vertex sequence? Should be in reverse order.
          adj.vertices.each_with_index do |vertex, i|
            expect(TBD.same?(vertex, s.vertices.at(i))).to be true
          end

          expect(adj.surfaceType).to eq("RoofCeiling")
          expect(s.surfaceType).to eq("RoofCeiling")
          expect(s.setSurfaceType("Floor")).to be true
          expect(s.setVertices(s.vertices.reverse)).to be true

          # Vertices now in reverse order.
          adj.vertices.reverse.each_with_index do |vertex, i|
            expect(TBD.same?(vertex, s.vertices.at(i))).to be true
          end
        end

        # Save for future testing.
        file = File.join(__dir__, "files/osms/out/seb2.osm")
        model.save(file, true)

        # After the fix.
        unless version < 350
          expect(plnum.isEnclosedVolume).to be true
          expect(plnum.isVolumeDefaulted).to be true
          expect(plnum.isVolumeAutocalculated).to be true
        end

        expect(plnum.volume.round(0)).to eq(50) # right answer
        expect(thzone.isVolumeDefaulted).to be true
        expect(thzone.isVolumeAutocalculated).to be true
        expect(thzone.volume).to be_empty
      end

      argh = {option: "poor (BETBG)"}

      json     = TBD.process(model, argh)
      expect(json).to be_a(Hash)
      expect(json).to have_key(:io)
      expect(json).to have_key(:surfaces)
      io       = json[:io      ]
      surfaces = json[:surfaces]
      expect(TBD.status).to be_zero
      expect(TBD.logs).to be_empty
      expect(surfaces).to be_a(Hash)
      expect(surfaces.size).to eq(56)
      expect(io).to be_a(Hash)
      expect(io).to have_key(:edges)
      expect(io[:edges].size).to eq(106) # not 80 as if it were UNCONDITIONED

      edges = io[:edges]
      edges = edges.reject { |s| s.to_s.include?("sill"  ) }
      edges = edges.reject { |s| s.to_s.include?("head"  ) }
      edges = edges.reject { |s| s.to_s.include?("jamb"  ) }
      edges = edges.reject { |s| s.to_s.include?("grade" ) }
      edges = edges.reject { |s| s.to_s.include?("corner") }
      edges = edges.reject { |s| s.to_s.include?("sill"  ) }

      expect(edges.size).to eq(44)

      edges.each do |edge|
        type      = edge[:type    ]
        size      = edge[:surfaces].size
        shades    = edge[:surfaces].select { |s| s.include?("Shading") }
        walls     = edge[:surfaces].select { |s| s.include?("Wall") }
        ceilings  = edge[:surfaces].select { |s| s.include?("DroppedCeiling") }
        roofs     = edge[:surfaces].select { |s| s.include?("RoofCeiling") }

        pceilings = ceilings.select { |s| s.include?("Plenum") }

        expect(type).to eq(:transition).or eq(:parapetconvex).or eq(:ceiling)
        expect(type).to_not eq(:ceiling) if time == 0 # :transition instead

        if type == :transition
          if time == 1
            expect(size).to eq(2).or eq(3).or eq(4) # not 5
            expect(walls.size).to eq(size) if size == 4
          else
            expect(size).to eq(2).or eq(3).or eq(4).or eq(5)
          end

          if size == 2 # between 2x exterior walls OR 2x plenum roof surfaces
            next if walls.size == size

            expect(walls.size).to eq(0)
            expect(ceilings.size).to eq(0)
            expect(roofs.size).to eq(2)
            expect(pceilings.size).to eq(0)
          elsif size == 3
            expect(shades.size).to eq(1)
            expect(walls.size).to eq(2)
          elsif size == 4 # between 2x room ceilings, along 2x exterior walls
            next if walls.size == size

            # Holds "Shading Surface 4"? Then it's before the fix.
            if shades.size == 2
              expect(time).to eq(0)
              expect(walls.size).to eq(2)
              expect(shades).to include("Shading Surface 4")
              next
            end

            expect(walls.size).to eq(2)
            expect(ceilings.size).to eq(2)
            expect(roofs.size).to eq(0)
            expect(pceilings.size).to eq(1)
          else
            expect(time).to eq(0)
            expect(size).to eq(5)
            expect(shades.size).to eq(1)
            expect(shades).to include("Shading Surface 4")
            expect(walls.size).to eq(2)
            expect(ceilings.size).to eq(2)
            expect(roofs.size).to eq(0)
            expect(pceilings.size).to eq(1)
          end
        elsif type == :parapetconvex
          if size == 4
            expect(time).to eq(0)
            expect(shades.size).to eq(2)
            expect(shades).to include("Shading Surface 4")
            expect(walls.size).to eq(1)
            expect(ceilings.size).to eq(0)
            expect(roofs.size).to eq(1)
            next
          elsif size == 3
            expect(time).to eq(1)
            expect(shades.size).to eq(1)
            expect(shades).to_not include("Shading Surface 4")
            expect(walls.size).to eq(1)
            expect(ceilings.size).to eq(0)
            expect(roofs.size).to eq(1)
          else
            expect(size).to eq(2)
            expect(shades.size).to eq(0)
            expect(walls.size).to eq(1)
            expect(ceilings.size).to eq(0)
            expect(roofs.size).to eq(1)
          end
        else
          expect(time).to eq(1)
          expect(type).to eq(:ceiling)
          expect(size).to eq(4)
          expect(shades.size).to eq(0)
          expect(walls.size).to eq(2)
          expect(ceilings.size).to eq(2)
          expect(pceilings.size).to eq(1)
          expect(roofs.size).to eq(0)
        end
      end
    end
  end

  it "can take in custom (expansion) joints as thermal bridges" do
    translator = OpenStudio::OSVersion::VersionTranslator.new
    TBD.clean!

    file  = File.join(__dir__, "files/osms/in/warehouse.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    # TBD will automatically tag as a (mild) "transition" any shared edge
    # between 2x linked walls that +/- share the same 3D plane. An edge shared
    # between 2x roof surfaces will equally be tagged as a "transition" edge.
    #
    # By default, transition edges are set @0 W/K.m i.e., no derating occurs.
    # Although structural expansion joints or roof curbs are not as commonly
    # encountered as mild transitions, they do constitute significant thermal
    # bridges (to consider). Unfortunately, "joints" remain undistinguishable
    # from transition edges when parsing OpenStudio geometry. The test here
    # illustrates how users can override default "transition" tags via JSON
    # input files.
    #
    # The "tbd_warehouse6.json" file identifies 2x edges in the US DOE
    # warehouse prototype building that TBD tags as (mild) transitions by
    # default. Both edges concern the "Fine Storage" space (likely as a means
    # to ensure surface convexity in the EnergyPlus model). The "ok" PSI set
    # holds a single "joint" PSI value of 0.9 W/K per metre (let's assume both
    # edges are significant expansion joints, rather than modelling artifacts).
    # Each "expansion joint" here represents 4.27m x 0.9 W/K.m (== 3.84 W/K).
    # As wall constructions are the same for all 4x walls concerned, each wall
    # inherits 1/2 of the extra heat loss from each joint, i.e. 1.92 W/K.
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

    argh               = {}
    argh[:option     ] = "poor (BETBG)"
    argh[:io_path    ] = File.join(__dir__, "../json/tbd_warehouse6.json")
    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")

    json     = TBD.process(model, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty
    expect(surfaces).to be_a(Hash)
    expect(surfaces.size).to eq(23)
    expect(io).to be_a(Hash)
    expect(io).to have_key(:edges)
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
      expect(ids).to_not have_value(id) unless surface.key?(:edges)
    end

    surfaces.each do |id, surface|
      next unless surface.key?(:edges)

      expect(ids).to have_value(id)
      expect(surface).to have_key(:ratio)
      expect(surface).to have_key(:heatloss)
      h = surface[:heatloss]
      s = model.getSurfaceByName(id)
      expect(s).to_not be_empty
      s = s.get
      expect(s.nameString).to eq(id)
      expect(s.isConstructionDefaulted).to be false
      expect(s.construction.get.nameString).to include(" tbd")
      expect(h).to be_within(TOL).of( 50.20) if id == ids[:a]
      expect(h).to be_within(TOL).of( 24.06) if id == ids[:b]
      expect(h).to be_within(TOL).of( 87.16) if id == ids[:c]
      expect(h).to be_within(TOL).of( 24.53) if id == ids[:d] # 22.61 + 1.92
      expect(h).to be_within(TOL).of( 11.07) if id == ids[:e] #  9.15 + 1.92
      expect(h).to be_within(TOL).of( 28.39) if id == ids[:f] # 26.47 + 1.92
      expect(h).to be_within(TOL).of( 29.11) if id == ids[:g] # 27.19 + 1.92
      expect(h).to be_within(TOL).of( 41.36) if id == ids[:h]
      expect(h).to be_within(TOL).of(161.02) if id == ids[:i]
      expect(h).to be_within(TOL).of( 62.28) if id == ids[:j]
      expect(h).to be_within(TOL).of(117.87) if id == ids[:k]
      expect(h).to be_within(TOL).of( 95.77) if id == ids[:l]

      c = s.construction
      expect(c).to_not be_empty
      c = c.get.to_LayeredConstruction
      expect(c).to_not be_empty
      c = c.get
      expect(c.layers[1].nameString).to include("m tbd")
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

  it "can process seb2.osm (0 W/K per m)" do
    translator = OpenStudio::OSVersion::VersionTranslator.new
    TBD.clean!

    file  = File.join(__dir__, "files/osms/out/seb2.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    argh  = { option: "(non thermal bridging)" }

    json     = TBD.process(model, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty
    expect(surfaces).to be_a(Hash)
    expect(surfaces.size).to eq(56)
    expect(io).to be_a(Hash)
    expect(io).to have_key(:edges)
    expect(io[:edges].size).to eq(106)

    surfaces.each do |id, surface|
      expect(surface).to have_key(:conditioned)
      next unless surface[:conditioned]

      expect(surface).to have_key(:heating)
      expect(surface).to have_key(:cooling)
    end

    # Since all PSI values = 0, we're not expecting any derated surfaces
    surfaces.values.each { |surface| expect(surface).to_not have_key(:ratio) }
  end

  it "can process seb2.osm (0 W/K per m) with JSON" do
    translator = OpenStudio::OSVersion::VersionTranslator.new
    TBD.clean!

    file  = File.join(__dir__, "files/osms/out/seb2.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    argh               = {}
    argh[:option     ] = "(non thermal bridging)"
    argh[:io_path    ] = File.join(__dir__, "../json/tbd_seb.json")
    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")

    json     = TBD.process(model, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty
    expect(surfaces).to be_a(Hash)
    expect(surfaces.size).to eq(56)
    expect(io).to be_a(Hash)
    expect(io).to have_key(:edges)
    expect(io[:edges].size).to eq(106)

    # As the :building PSI set on file remains "(non thermal bridging)", one
    # should not expect differences in results, i.e. derating shouldn't occur.
    surfaces.values.each { |surface| expect(surface).to_not have_key(:ratio) }
  end

  it "can process seb2.osm (0 W/K per m) with JSON (non-0)" do
    translator = OpenStudio::OSVersion::VersionTranslator.new
    TBD.clean!

    file  = File.join(__dir__, "files/osms/out/seb2.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    # Consider the plenum as UNCONDITIONED.
    plnum = model.getSpaceByName("Level 0 Ceiling Plenum")
    expect(plnum).to_not be_empty
    plnum = plnum.get
    expect(TBD.unconditioned?(plnum)).to be false

    key = "space_conditioning_category"
    val = "Unconditioned"
    expect(plnum.additionalProperties.hasFeature(key)).to be false
    expect(plnum.additionalProperties.setFeature(key, val)).to be true
    expect(TBD.plenum?(plnum)).to be true # fyi, still has "plenum" spacetype
    expect(TBD.unconditioned?(plnum)).to be true # ... more reliable
    expect(TBD.setpoints(plnum)[:heating]).to be_nil
    expect(TBD.setpoints(plnum)[:cooling]).to be_nil
    expect(TBD.status).to be_zero

    argh               = {}
    argh[:option     ] = "(non thermal bridging)"
    argh[:io_path    ] = File.join(__dir__, "../json/tbd_seb_n0.json")
    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")

    json     = TBD.process(model, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty
    expect(surfaces).to be_a(Hash)
    expect(surfaces.size).to eq(56)
    expect(io).to be_a(Hash)
    expect(io).to have_key(:edges)
    expect(io[:edges].size).to eq(80) # 106 if plenum were INDIRECTLYCONDITIONED

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
            q: "Open area 1 DroppedCeiling"
          }.freeze

    # The :building PSI set on file "compliant" supersedes the argh[:option]
    # "(non thermal bridging)", so one should expect differences in results,
    # i.e. derating should occur. The next 2 tests:
    #   1. setting both argh[:option] & file :building to "compliant"
    #   2. setting argh[:option] to "compliant" + removing :building from file
    # ... all 3x cases should yield the same results.
    surfaces.each do |id, surface|
      expect(ids).to have_value(id) if surface.key?(:edges)
    end

    surfaces.each do |id, surface|
      next unless surface.key?(:edges)

      expect(ids).to have_value(id)
      expect(surface).to have_key(:heatloss)
      expect(surface).to have_key(:ratio)
      h = surface[:heatloss]
      s = model.getSurfaceByName(id)
      expect(s).to_not be_empty
      s = s.get
      expect(s.nameString).to eq(id)
      expect(s.isConstructionDefaulted).to be false
      expect(s.construction.get.nameString).to include(" tbd")
      expect(h).to be_within(TOL).of( 3.62) if id == ids[:a]
      expect(h).to be_within(TOL).of( 6.28) if id == ids[:b]
      expect(h).to be_within(TOL).of( 2.62) if id == ids[:c]
      expect(h).to be_within(TOL).of( 0.17) if id == ids[:d]
      expect(h).to be_within(TOL).of( 7.13) if id == ids[:e]
      expect(h).to be_within(TOL).of( 7.09) if id == ids[:f]
      expect(h).to be_within(TOL).of( 0.20) if id == ids[:g]
      expect(h).to be_within(TOL).of( 7.94) if id == ids[:h]
      expect(h).to be_within(TOL).of( 5.17) if id == ids[:i]
      expect(h).to be_within(TOL).of( 5.01) if id == ids[:j]
      expect(h).to be_within(TOL).of( 0.22) if id == ids[:k]
      expect(h).to be_within(TOL).of( 2.47) if id == ids[:l]
      expect(h).to be_within(TOL).of( 3.11) if id == ids[:m]
      expect(h).to be_within(TOL).of( 4.43) if id == ids[:n]
      expect(h).to be_within(TOL).of( 3.35) if id == ids[:o]
      expect(h).to be_within(TOL).of( 2.12) if id == ids[:p]
      expect(h).to be_within(TOL).of( 0.31) if id == ids[:q]

      c = s.construction
      expect(c).to_not be_empty
      c = c.get.to_LayeredConstruction
      expect(c).to_not be_empty
      c = c.get
      i = 0
      i = 2 if s.outsideBoundaryCondition == "Outdoors"
      expect(c.layers[i].nameString).to include("m tbd")
    end

    surfaces.each do |id, surface|
      if surface.key?(:ratio)
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

        s = model.getSurfaceByName(id)
        expect(s).to_not be_empty
        s = s.get
        expect(s.nameString).to eq(id)
        expect(s.surfaceType).to eq("Wall")
        expect(s.isConstructionDefaulted).to be false
        c = s.construction.get.to_LayeredConstruction
        expect(c).to_not be_empty
        c = c.get
        expect(c.nameString).to include("c tbd")
        expect(c.layers.size).to eq(4)
        expect(c.layers[2].nameString).to include("m tbd")
        expect(c.layers[2].to_StandardOpaqueMaterial).to_not be_empty
        m = c.layers[2].to_StandardOpaqueMaterial.get

        initial_R = s.filmResistance + 2.4674
        derated_R = s.filmResistance + 0.9931
        derated_R += m.thickness / m.thermalConductivity

        ratio = -(initial_R - derated_R) * 100 / initial_R
        expect(ratio).to be_within(1).of(surfaces[id][:ratio])
      else
        if surface[:boundary].downcase == "outdoors"
          expect(surface[:conditioned]).to be false
        end
      end
    end
  end

  it "can process seb2.osm (0 W/K per m) with JSON (non-0) 2" do
    translator = OpenStudio::OSVersion::VersionTranslator.new
    TBD.clean!

    file  = File.join(__dir__, "files/osms/out/seb2.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    # Consider the plenum as UNCONDITIONED.
    plnum = model.getSpaceByName("Level 0 Ceiling Plenum")
    expect(plnum).to_not be_empty
    plnum = plnum.get
    expect(TBD.unconditioned?(plnum)).to be false

    key = "space_conditioning_category"
    val = "Unconditioned"
    expect(plnum.additionalProperties.hasFeature(key)).to be false
    expect(plnum.additionalProperties.setFeature(key, val)).to be true
    expect(TBD.plenum?(plnum)).to be true
    expect(TBD.unconditioned?(plnum)).to be true
    expect(TBD.setpoints(plnum)[:heating]).to be_nil
    expect(TBD.setpoints(plnum)[:cooling]).to be_nil
    expect(TBD.status).to be_zero

    # Setting both PSI option & file :building to "compliant"
    argh               = {}
    argh[:option     ] = "compliant" # instead of "(non thermal bridging)"
    argh[:io_path    ] = File.join(__dir__, "../json/tbd_seb_n0.json")
    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")

    json     = TBD.process(model, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty
    expect(surfaces).to be_a(Hash)
    expect(surfaces.size).to eq(56)
    expect(io).to be_a(Hash)
    expect(io).to have_key(:edges)
    expect(io[:edges].size).to eq(80) # 106 if plnum INDIRECTLYCONDITIONED

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
            q: "Open area 1 DroppedCeiling"
          }.freeze

    surfaces.each do |id, surface|
      expect(ids).to_not have_value(id) unless surface.key?(:edges)
    end

    surfaces.each do |id, surface|
      next unless surface.key?(:edges)

      expect(ids).to have_value(id)
      expect(surface).to have_key(:heatloss)
      expect(surface).to have_key(:ratio)
      h = surface[:heatloss]
      s = model.getSurfaceByName(id)
      expect(s).to_not be_empty
      s = s.get
      expect(s.nameString).to eq(id)
      expect(s.isConstructionDefaulted).to be false
      expect(s.construction.get.nameString).to include(" tbd")
      expect(h).to be_within(TOL).of( 3.62) if id == ids[:a]
      expect(h).to be_within(TOL).of( 6.28) if id == ids[:b]
      expect(h).to be_within(TOL).of( 2.62) if id == ids[:c]
      expect(h).to be_within(TOL).of( 0.17) if id == ids[:d]
      expect(h).to be_within(TOL).of( 7.13) if id == ids[:e]
      expect(h).to be_within(TOL).of( 7.09) if id == ids[:f]
      expect(h).to be_within(TOL).of( 0.20) if id == ids[:g]
      expect(h).to be_within(TOL).of( 7.94) if id == ids[:h]
      expect(h).to be_within(TOL).of( 5.17) if id == ids[:i]
      expect(h).to be_within(TOL).of( 5.01) if id == ids[:j]
      expect(h).to be_within(TOL).of( 0.22) if id == ids[:k]
      expect(h).to be_within(TOL).of( 2.47) if id == ids[:l]
      expect(h).to be_within(TOL).of( 3.11) if id == ids[:m]
      expect(h).to be_within(TOL).of( 4.43) if id == ids[:n]
      expect(h).to be_within(TOL).of( 3.35) if id == ids[:o]
      expect(h).to be_within(TOL).of( 2.12) if id == ids[:p]
      expect(h).to be_within(TOL).of( 0.31) if id == ids[:q]

      c = s.construction
      expect(c).to_not be_empty
      c = c.get.to_LayeredConstruction
      expect(c).to_not be_empty
      c = c.get
      i = 0
      i = 2 if s.outsideBoundaryCondition == "Outdoors"
      expect(c.layers[i].nameString).to include("m tbd")
    end

    surfaces.each do |id, surface|
      if surface.key?(:ratio)
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

        s = model.getSurfaceByName(id)
        expect(s).to_not be_empty
        s = s.get
        expect(s.nameString).to eq(id)
        expect(s.surfaceType).to eq("Wall")
        expect(s.isConstructionDefaulted).to be false
        c = s.construction.get.to_LayeredConstruction
        expect(c).to_not be_empty
        c = c.get
        expect(c.nameString).to include("c tbd")
        expect(c.layers.size).to eq(4)
        expect(c.layers[2].nameString).to include("m tbd")
        expect(c.layers[2].to_StandardOpaqueMaterial).to_not be_empty
        m = c.layers[2].to_StandardOpaqueMaterial.get

        initial_R = s.filmResistance + 2.4674
        derated_R = s.filmResistance + 0.9931
        derated_R += m.thickness / m.thermalConductivity

        ratio = -(initial_R - derated_R) * 100 / initial_R
        expect(ratio).to be_within(1).of(surfaces[id][:ratio])
      else
        if surface[:boundary].downcase == "outdoors"
          expect(surface[:conditioned]).to be false
        end
      end
    end
  end

  it "can process seb2.osm (0 W/K per m) with JSON (non-0) 3" do
    translator = OpenStudio::OSVersion::VersionTranslator.new
    TBD.clean!

    file  = File.join(__dir__, "files/osms/out/seb2.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    # Consider the plenum as UNCONDITIONED.
    plnum = model.getSpaceByName("Level 0 Ceiling Plenum")
    expect(plnum).to_not be_empty
    plnum = plnum.get
    expect(TBD.unconditioned?(plnum)).to be false

    key = "space_conditioning_category"
    val = "Unconditioned"
    expect(plnum.additionalProperties.hasFeature(key)).to be false
    expect(plnum.additionalProperties.setFeature(key, val)).to be true
    expect(TBD.plenum?(plnum)).to be true
    expect(TBD.unconditioned?(plnum)).to be true
    expect(TBD.setpoints(plnum)[:heating]).to be_nil
    expect(TBD.setpoints(plnum)[:cooling]).to be_nil
    expect(TBD.status).to be_zero

    # Setting PSI set to "compliant" while removing the :building from file.
    argh               = {}
    argh[:option     ] = "compliant" # instead of "(non thermal bridging)"
    argh[:io_path    ] = File.join(__dir__, "../json/tbd_seb_n1.json")
    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")

    json     = TBD.process(model, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty
    expect(surfaces).to be_a(Hash)
    expect(surfaces.size).to eq(56)
    expect(io).to be_a(Hash)
    expect(io).to have_key(:edges)
    expect(io[:edges].size).to eq(80) # 106 if plnum INDIRECTLYCONDITIONED

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
            q: "Open area 1 DroppedCeiling"
          }.freeze

    surfaces.each do |id, surface|
      expect(ids).to_not have_value(id) unless surface.key?(:edges)
    end

    surfaces.each do |id, surface|
      next unless surface.key?(:edges)

      expect(ids).to have_value(id)
      expect(surface).to have_key(:ratio)
      expect(surface).to have_key(:heatloss)
      h = surface[:heatloss]
      s = model.getSurfaceByName(id)
      expect(s).to_not be_empty
      s = s.get
      expect(s.nameString).to eq(id)
      expect(s.isConstructionDefaulted).to be false
      expect(s.construction.get.nameString).to include(" tbd")
      expect(h).to be_within(TOL).of( 3.62) if id == ids[:a]
      expect(h).to be_within(TOL).of( 6.28) if id == ids[:b]
      expect(h).to be_within(TOL).of( 2.62) if id == ids[:c]
      expect(h).to be_within(TOL).of( 0.17) if id == ids[:d]
      expect(h).to be_within(TOL).of( 7.13) if id == ids[:e]
      expect(h).to be_within(TOL).of( 7.09) if id == ids[:f]
      expect(h).to be_within(TOL).of( 0.20) if id == ids[:g]
      expect(h).to be_within(TOL).of( 7.94) if id == ids[:h]
      expect(h).to be_within(TOL).of( 5.17) if id == ids[:i]
      expect(h).to be_within(TOL).of( 5.01) if id == ids[:j]
      expect(h).to be_within(TOL).of( 0.22) if id == ids[:k]
      expect(h).to be_within(TOL).of( 2.47) if id == ids[:l]
      expect(h).to be_within(TOL).of( 3.11) if id == ids[:m]
      expect(h).to be_within(TOL).of( 4.43) if id == ids[:n]
      expect(h).to be_within(TOL).of( 3.35) if id == ids[:o]
      expect(h).to be_within(TOL).of( 2.12) if id == ids[:p]
      expect(h).to be_within(TOL).of( 0.31) if id == ids[:q]

      c = s.construction
      expect(c).to_not be_empty
      c = c.get.to_LayeredConstruction
      expect(c).to_not be_empty
      c = c.get
      i = 0
      i = 2 if s.outsideBoundaryCondition == "Outdoors"
      expect(c.layers[i].nameString).to include("m tbd")
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

        s = model.getSurfaceByName(id)
        expect(s).to_not be_empty
        s = s.get
        expect(s.nameString).to eq(id)
        expect(s.surfaceType).to eq("Wall")
        expect(s.isConstructionDefaulted).to be false
        c = s.construction.get.to_LayeredConstruction
        expect(c).to_not be_empty
        c = c.get
        expect(c.nameString).to include("c tbd")
        expect(c.layers.size).to eq(4)
        expect(c.layers[2].nameString).to include("m tbd")
        expect(c.layers[2].to_StandardOpaqueMaterial).to_not be_empty
        m = c.layers[2].to_StandardOpaqueMaterial.get

        initial_R = s.filmResistance + 2.4674
        derated_R = s.filmResistance + 0.9931
        derated_R += m.thickness / m.thermalConductivity

        ratio = -(initial_R - derated_R) * 100 / initial_R
        expect(ratio).to be_within(1).of(surfaces[id][:ratio])
      else
        if surface[:boundary].downcase == "outdoors"
          expect(surface[:conditioned]).to be false
        end
      end
    end
  end

  it "can process JSON surface KHI entries" do
    translator = OpenStudio::OSVersion::VersionTranslator.new
    expect(TBD.level     ).to eq(DBG)
    expect(TBD.clean!    ).to eq(DBG)

    # First, basic IO tests with invalid entries.
    k = TBD::KHI.new
    expect(k.point).to be_a(Hash)
    expect(k.point.size).to eq(14)

    # Invalid identifier key.
    new_KHI = { name: "new_KHI", point: 1.0 }
    expect(k.append(new_KHI)).to be false
    expect(TBD.debug?).to be true
    expect(TBD.logs.size).to eq(1)
    expect(TBD.logs.first[:message]).to include("Missing 'id' key")
    TBD.clean!

    # Invalid identifier.
    new_KHI = { id: nil, point: 1.0 }
    expect(k.append(new_KHI)).to be false
    expect(TBD.error?).to be true
    expect(TBD.logs.size).to eq(1)
    expect(TBD.logs.first[:message]).to include("'KHI id' NilClass?")
    TBD.clean!

    # Odd (yet valid) identifier.
    new_KHI = { id: [], point: 1.0 }
    expect(k.append(new_KHI)).to be true
    expect(TBD.status).to be_zero
    expect(k.point.keys).to include("[]")
    expect(k.point.size).to eq(15)

    # Existing identifier.
    new_KHI = { id: "code (Quebec)", point: 1.0 }
    expect(k.append(new_KHI)).to be false
    expect(TBD.error?).to be true
    expect(TBD.logs.size).to eq(1)
    expect(TBD.logs.first[:message]).to include("existing KHI entry")
    TBD.clean!

    # Missing point conductance.
    new_KHI = { id: "foo" }
    expect(k.append(new_KHI)).to be false
    expect(TBD.debug?).to be true
    expect(TBD.logs.size).to eq(1)
    expect(TBD.logs.first[:message]).to include("Missing 'point' key")

    # Valid JSON entries.
    TBD.clean!
    version = OpenStudio.openStudioVersion.split(".").join.to_i

    # The v1.11.5 (2016) seb.osm, shipped with OpenStudio, holds (what would now
    # be considered as deprecated) a definition of plenum floors (i.e. ceiling
    # tiles) generating several warnings with more recent OpenStudio versions.
    file  = File.join(__dir__, "files/osms/in/seb.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    # "Shading Surface 4" is overlapping with a plenum exterior wall - delete.
    sh4 = model.getShadingSurfaceByName("Shading Surface 4")
    expect(sh4).to_not be_empty
    sh4 = sh4.get
    sh4.remove

    plenum = model.getSpaceByName("Level 0 Ceiling Plenum")
    expect(plenum).to_not be_empty
    plenum = plenum.get

    thzone = plenum.thermalZone
    expect(thzone).to_not be_empty
    thzone = thzone.get

    # Before the fix.
    unless version < 350
      expect(plenum.isEnclosedVolume).to be true
      expect(plenum.isVolumeDefaulted).to be true
      expect(plenum.isVolumeAutocalculated).to be true
    end

    if version > 350 && version < 370
      expect(plenum.volume.round(0)).to eq(234)
    else
      expect(plenum.volume.round(0)).to eq(0)
    end

    expect(thzone.isVolumeDefaulted).to be true
    expect(thzone.isVolumeAutocalculated).to be true
    expect(thzone.volume).to be_empty

    plenum.surfaces.each do |s|
      next if s.outsideBoundaryCondition.downcase == "outdoors"

      # If a SEB plenum surface isn't facing outdoors, it's 1 of 4 "floor"
      # surfaces (each facing a ceiling surface below).
      adj = s.adjacentSurface
      expect(adj).to_not be_empty
      adj = adj.get
      expect(adj.vertices.size).to eq(s.vertices.size)

      # Same vertex sequence? Should be in reverse order.
      adj.vertices.each_with_index do |vertex, i|
        expect(TBD.same?(vertex, s.vertices.at(i))).to be true
      end

      expect(adj.surfaceType).to eq("RoofCeiling")
      expect(s.surfaceType).to eq("RoofCeiling")
      expect(s.setSurfaceType("Floor")).to be true
      expect(s.setVertices(s.vertices.reverse)).to be true

      # Vertices now in reverse order.
      adj.vertices.reverse.each_with_index do |vertex, i|
        expect(TBD.same?(vertex, s.vertices.at(i))).to be true
      end
    end

    # After the fix.
    unless version < 350
      expect(plenum.isEnclosedVolume).to be true
      expect(plenum.isVolumeDefaulted).to be true
      expect(plenum.isVolumeAutocalculated).to be true
    end

    expect(plenum.volume.round(0)).to eq(50) # right answer
    expect(thzone.isVolumeDefaulted).to be true
    expect(thzone.isVolumeAutocalculated).to be true
    expect(thzone.volume).to be_empty

    file = File.join(__dir__, "files/osms/out/seb2.osm")
    model.save(file, true)


    argh               = {}
    argh[:option     ] = "(non thermal bridging)"
    argh[:io_path    ] = File.join(__dir__, "../json/tbd_seb_n2.json")
    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")

    json     = TBD.process(model, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty
    expect(surfaces).to be_a(Hash)
    expect(surfaces.size).to eq(56)
    expect(io).to be_a(Hash)
    expect(io).to have_key(:edges)
    expect(io[:edges].size).to eq(106)

    # As the :building PSI set on file remains "(non thermal bridging)", one
    # should not expect differences in results, i.e. derating shouldn't occur.
    # However, the JSON file holds KHI entries for "Entryway  Wall 2" :
    # 3x "columns" @0.5 W/K + 4x supports @0.5W/K = 3.5 W/K
    surfaces.values.each do |surface|
      next unless surface.key?(:ratio)

      expect(surface[:heatloss]).to be_within(TOL).of(3.5)
    end

    # Retrieve :parapet edges along the "Open Area" plenum.
    open = model.getSpaceByName("Open area 1")
    expect(open).to_not be_empty
    open = open.get

    open_roofs = TBD.roofs(open)
    expect(open_roofs.size).to eq(1)
    open_roof  = open_roofs.first
    roof_id    = open_roof.nameString
    expect(roof_id).to eq("Level 0 Open area 1 Ceiling Plenum RoofCeiling")

    # There are only 2 types of edges along the "Open Area" plenum roof:
    #   1. (5x) convex :parapet edges, and
    #   2. (5x) transition edges (shared with neighbouring flat roof surfaces).
    roof_edges  = io[:edges].select { |edg| edg[:surfaces].include?(roof_id) }
    parapets    = roof_edges.select { |edg| edg[:type] == :parapetconvex }
    transitions = roof_edges.select { |edg| edg[:type] == :transition }
    expect(parapets.size).to eq(5)
    expect(transitions.size).to eq(5)
    expect(roof_edges.size).to eq(parapets.size + transitions.size)

    roof_edges.each { |edg| expect(edg[:surfaces].size).to eq(2) }
  end

  it "can process JSON surface KHI & PSI entries" do
    translator = OpenStudio::OSVersion::VersionTranslator.new
    TBD.clean!

    file  = File.join(__dir__, "files/osms/out/seb2.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    # Consider the plenum as UNCONDITIONED.
    plnum = model.getSpaceByName("Level 0 Ceiling Plenum")
    expect(plnum).to_not be_empty
    plnum = plnum.get
    expect(TBD.unconditioned?(plnum)).to be false

    key = "space_conditioning_category"
    val = "Unconditioned"
    expect(plnum.additionalProperties.hasFeature(key)).to be false
    expect(plnum.additionalProperties.setFeature(key, val)).to be true
    expect(TBD.plenum?(plnum)).to be true
    expect(TBD.unconditioned?(plnum)).to be true
    expect(TBD.setpoints(plnum)[:heating]).to be_nil
    expect(TBD.setpoints(plnum)[:cooling]).to be_nil
    expect(TBD.status).to be_zero

    argh               = {}
    argh[:option     ] = "(non thermal bridging)" # no :building PSI set on file
    argh[:io_path    ] = File.join(__dir__, "../json/tbd_seb_n3.json")
    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")

    json     = TBD.process(model, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty
    expect(surfaces).to be_a(Hash)
    expect(surfaces.size).to eq(56)
    expect(io).to be_a(Hash)
    expect(io).to have_key(:edges)
    expect(io[:edges].size).to eq(80) # 106 if plnum INDIRECTLYCONDITIONED

    expect(io).to have_key(:building) # despite no being on file - good
    expect(io[:building]).to have_key(:psi)
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
      expect(surface[:heatloss]).to be_within(TOL).of(5.17) if id == nom1
      expect(surface[:heatloss]).to be_within(TOL).of(0.13) if id == nom2
      expect(surface).to have_key(:edges)
      expect(surface[:edges].size).to eq(10) if id == nom1
      expect(surface[:edges].size).to eq( 6) if id == nom2
    end

    expect(io).to have_key(:edges)
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
    nb_rimjoist_edges   = 0
    nb_parapet_edges    = 0
    nb_fen_edges        = 0
    nb_head_edges       = 0
    nb_sill_edges       = 0
    nb_jamb_edges       = 0
    nb_corners          = 0
    nb_concave_edges    = 0
    nb_convex_edges     = 0
    nb_balcony_edges    = 0
    nb_party_edges      = 0
    nb_grade_edges      = 0
    nb_transition_edges = 0

    io[:edges].each do |edge|
      expect(edge).to have_key(:psi)
      expect(edge).to have_key(:type)
      expect(edge).to have_key(:length)
      expect(edge).to have_key(:surfaces)
      t     = edge[:type]
      s     = {}
      valid = edge[:surfaces].include?(nom1) || edge[:surfaces].include?(nom2)
      next unless valid

      io[:psis].each { |set| s = set if set[:id] == edge[:psi] }

      next if s.empty?

      expect(s).to be_a(Hash)
      nb_rimjoist_edges   += 1 if t == :rimjoist
      nb_rimjoist_edges   += 1 if t == :rimjoistconcave
      nb_rimjoist_edges   += 1 if t == :rimjoistconvex
      nb_parapet_edges    += 1 if t == :parapet
      nb_parapet_edges    += 1 if t == :parapetconcave
      nb_parapet_edges    += 1 if t == :parapetconvex
      nb_fen_edges        += 1 if t == :fenestration
      nb_head_edges       += 1 if t == :head
      nb_sill_edges       += 1 if t == :sill
      nb_jamb_edges       += 1 if t == :jamb
      nb_corners          += 1 if t == :corner
      nb_concave_edges    += 1 if t == :cornerconcave
      nb_convex_edges     += 1 if t == :cornerconvex
      nb_balcony_edges    += 1 if t == :balcony
      nb_party_edges      += 1 if t == :party
      nb_grade_edges      += 1 if t == :grade
      nb_grade_edges      += 1 if t == :gradeconcave
      nb_grade_edges      += 1 if t == :gradeconvex
      nb_transition_edges += 1 if t == :transition

      expect(t).to eq(:parapetconvex).or eq(:transition)
      next unless t == :parapetconvex

      expect(edge[:length]).to be_within(TOL).of(3.6)
    end

    expect(nb_rimjoist_edges  ).to be_zero
    expect(nb_parapet_edges   ).to eq(1) # parapet linked to "good" PSI set
    expect(nb_fen_edges       ).to be_zero
    expect(nb_head_edges      ).to be_zero
    expect(nb_sill_edges      ).to be_zero
    expect(nb_jamb_edges      ).to be_zero
    expect(nb_corners         ).to be_zero
    expect(nb_concave_edges   ).to be_zero
    expect(nb_convex_edges    ).to be_zero
    expect(nb_balcony_edges   ).to be_zero
    expect(nb_party_edges     ).to be_zero
    expect(nb_grade_edges     ).to be_zero
    expect(nb_transition_edges).to eq(2) # all PSI sets inherit :transitions

    # Reset counters to track the total number of edges delineating either
    # derated surfaces that DO NOT contribute in derating their insulation
    # materials i.e. not found in the "good" PSI set.
    nb_rimjoist_edges   = 0
    nb_parapet_edges    = 0
    nb_fen_edges        = 0
    nb_head_edges       = 0
    nb_sill_edges       = 0
    nb_jamb_edges       = 0
    nb_corners          = 0
    nb_concave_edges    = 0
    nb_convex_edges     = 0
    nb_balcony_edges    = 0
    nb_party_edges      = 0
    nb_grade_edges      = 0
    nb_transition_edges = 0

    io[:edges].each do |edge|
      s     = {}
      valid = edge[:surfaces].include?(nom1) || edge[:surfaces].include?(nom2)
      next unless valid

      io[:psis].each { |set| s = set if set[:id] == edge[:psi] }

      next unless s.empty?
      expect(edge[:psi]).to eq(argh[:option])

      t = edge[:type]
      nb_rimjoist_edges   += 1 if t == :rimjoist
      nb_rimjoist_edges   += 1 if t == :rimjoistconcave
      nb_rimjoist_edges   += 1 if t == :rimjoistconvex
      nb_parapet_edges    += 1 if t == :parapet
      nb_parapet_edges    += 1 if t == :parapetconcave
      nb_parapet_edges    += 1 if t == :parapetconvex
      nb_fen_edges        += 1 if t == :fenestration
      nb_head_edges       += 1 if t == :head
      nb_sill_edges       += 1 if t == :sill
      nb_jamb_edges       += 1 if t == :jamb
      nb_corners          += 1 if t == :corner
      nb_concave_edges    += 1 if t == :cornerconcave
      nb_convex_edges     += 1 if t == :cornerconvex
      nb_balcony_edges    += 1 if t == :balcony
      nb_party_edges      += 1 if t == :party
      nb_grade_edges      += 1 if t == :grade
      nb_grade_edges      += 1 if t == :gradeconcave
      nb_grade_edges      += 1 if t == :gradeconvex
      nb_transition_edges += 1 if t == :transition
    end

    expect(nb_rimjoist_edges  ).to be_zero
    expect(nb_parapet_edges   ).to eq(2) # not linked to "good" PSI set
    expect(nb_fen_edges       ).to be_zero
    expect(nb_head_edges      ).to eq(1)
    expect(nb_sill_edges      ).to eq(1)
    expect(nb_jamb_edges      ).to eq(2)
    expect(nb_corners         ).to be_zero
    expect(nb_concave_edges   ).to be_zero
    expect(nb_convex_edges    ).to eq(2) # edges between walls 5 & 4
    expect(nb_balcony_edges   ).to be_zero
    expect(nb_party_edges     ).to be_zero
    expect(nb_grade_edges     ).to eq(1)
    expect(nb_transition_edges).to eq(3) # shared roof edges

    # Reset counters again to track the total number of edges delineating either
    # derated surfaces that DO NOT contribute in derating their insulation
    # materials i.e., automatically set as :transitions in "good" PSI set.
    nb_rimjoist_edges   = 0
    nb_parapet_edges    = 0
    nb_fen_edges        = 0
    nb_head_edges       = 0
    nb_sill_edges       = 0
    nb_jamb_edges       = 0
    nb_corners          = 0
    nb_concave_edges    = 0
    nb_convex_edges     = 0
    nb_balcony_edges    = 0
    nb_party_edges      = 0
    nb_grade_edges      = 0
    nb_transition_edges = 0

    io[:edges].each do |edge|
      t     = edge[:type]
      s     = {}
      valid = edge[:surfaces].include?(nom1) || edge[:surfaces].include?(nom2)
      next unless valid

      io[:psis].each { |set| s = set if set[:id] == edge[:psi] }

      next if s.empty?

      expect(s).to be_a(Hash)
      next if t.to_s.include?("parapet")

      nb_rimjoist_edges   += 1 if t == :rimjoist
      nb_rimjoist_edges   += 1 if t == :rimjoistconcave
      nb_rimjoist_edges   += 1 if t == :rimjoistconvex
      nb_parapet_edges    += 1 if t == :parapet
      nb_parapet_edges    += 1 if t == :parapetconcave
      nb_parapet_edges    += 1 if t == :parapetconvex
      nb_fen_edges        += 1 if t == :fenestration
      nb_head_edges       += 1 if t == :head
      nb_sill_edges       += 1 if t == :sill
      nb_jamb_edges       += 1 if t == :jamb
      nb_corners          += 1 if t == :corner
      nb_concave_edges    += 1 if t == :cornerconcave
      nb_convex_edges     += 1 if t == :cornerconvex
      nb_balcony_edges    += 1 if t == :balcony
      nb_party_edges      += 1 if t == :party
      nb_grade_edges      += 1 if t == :grade
      nb_grade_edges      += 1 if t == :gradeconcave
      nb_grade_edges      += 1 if t == :gradeconvex
      nb_transition_edges += 1 if t == :transition
    end

    expect(nb_rimjoist_edges  ).to be_zero
    expect(nb_parapet_edges   ).to be_zero
    expect(nb_fen_edges       ).to be_zero
    expect(nb_head_edges      ).to be_zero
    expect(nb_jamb_edges      ).to be_zero
    expect(nb_sill_edges      ).to be_zero
    expect(nb_corners         ).to be_zero
    expect(nb_concave_edges   ).to be_zero
    expect(nb_convex_edges    ).to be_zero
    expect(nb_balcony_edges   ).to be_zero
    expect(nb_party_edges     ).to be_zero
    expect(nb_grade_edges     ).to be_zero
    expect(nb_transition_edges).to eq(2) # edges between walls 5 & 6
  end

  it "can process JSON surface KHI & PSI entries + building & edge" do
    translator = OpenStudio::OSVersion::VersionTranslator.new
    TBD.clean!

    # First, basic IO tests with invalid entries.
    ps = TBD::PSI.new
    expect(ps.set).to be_a(Hash)
    expect(ps.has).to be_a(Hash)
    expect(ps.val).to be_a(Hash)
    expect(ps.set.size).to eq(16)
    expect(ps.has.size).to eq(16)
    expect(ps.val.size).to eq(16)

    expect(ps.gen(nil)).to be false
    expect(TBD.status).to be_zero

    # Invalid identifier key.
    new_PSI = { name: "new_PSI", balcony: 1.0 }
    expect(ps.append(new_PSI)).to be false
    expect(TBD.debug?).to be true
    expect(TBD.logs.size).to eq(1)
    expect(TBD.logs.first[:message]).to include("Missing 'id' key")
    TBD.clean!

    # Invalid identifier.
    new_PSI = { id: nil, balcony: 1.0 }
    expect(ps.append(new_PSI)).to be false
    expect(TBD.error?).to be true
    expect(TBD.logs.size).to eq(1)
    expect(TBD.logs.first[:message]).to include("'set ID' NilClass?")
    TBD.clean!

    # Odd (yet valid) identifier.
    new_PSI = { id: [], balcony: 1.0 }
    expect(ps.append(new_PSI)).to be true
    expect(TBD.status).to be_zero
    expect(ps.set.keys).to include("[]")
    expect(ps.has.keys).to include("[]")
    expect(ps.val.keys).to include("[]")
    expect(ps.set.size).to eq(17)
    expect(ps.has.size).to eq(17)
    expect(ps.val.size).to eq(17)

    # Existing identifier.
    new_PSI = { id: "code (Quebec)", balcony: 1.0 }
    expect(ps.append(new_PSI)).to be false
    expect(TBD.error?).to be true
    expect(TBD.logs.size).to eq(1)
    expect(TBD.logs.first[:message]).to include("existing PSI set")
    TBD.clean!

    # Side test on balcony/sill.
    expect(ps.safe("code (Quebec)", :balconysillconcave)).to eq(:balconysill)

    # Defined vs missing conductances.
    new_PSI = { id: "foo" }
    expect(ps.append(new_PSI)).to be true

    s = ps.shorthands("foo")
    expect(TBD.status).to be_zero
    expect(s).to be_a(Hash)
    expect(s).to have_key(:has)
    expect(s).to have_key(:val)

    [:joint, :transition].each do |type|
      expect(s[:has]).to have_key(type)
      expect(s[:val]).to have_key(type)
      expect(s[:has][type]).to be true
      expect(s[:val][type]).to be_within(TOL).of(0)
    end

    [:balcony, :rimjoist, :fenestration, :parapet].each do |type|
      expect(s[:has]).to have_key(type)
      expect(s[:val]).to have_key(type)
      expect(s[:has][type]).to be false
      expect(s[:val][type]).to be_within(TOL).of(0)
    end

    # --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- #
    # Valid JSON entries.
    TBD.clean!

    name  = "Entryway  Wall 5"
    file  = File.join(__dir__, "files/osms/out/seb2.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    # Consider the plenum as UNCONDITIONED.
    plnum = model.getSpaceByName("Level 0 Ceiling Plenum")
    expect(plnum).to_not be_empty
    plnum = plnum.get
    expect(TBD.unconditioned?(plnum)).to be false

    key = "space_conditioning_category"
    val = "Unconditioned"
    expect(plnum.additionalProperties.hasFeature(key)).to be false
    expect(plnum.additionalProperties.setFeature(key, val)).to be true
    expect(TBD.plenum?(plnum)).to be true
    expect(TBD.unconditioned?(plnum)).to be true
    expect(TBD.setpoints(plnum)[:heating]).to be_nil
    expect(TBD.setpoints(plnum)[:cooling]).to be_nil
    expect(TBD.status).to be_zero

    argh               = {}
    argh[:option     ] = "(non thermal bridging)"
    argh[:io_path    ] = File.join(__dir__, "../json/tbd_seb_n4.json")
    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")

    json     = TBD.process(model, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty
    expect(surfaces).to be_a(Hash)
    expect(surfaces.size).to eq(56)
    expect(io).to be_a(Hash)
    expect(io).to have_key(:edges)
    expect(io[:edges].size).to eq(80)

    # As the :building PSI set on file == "(non thermal bridging)", derating
    # shouldn't occur at large. However, the JSON file holds a custom edge
    # entry for "Entryway  Wall 5" : "bad" fenestration perimeters, which
    # only derates the host wall itself
    surfaces.each do |id, surface|
      next unless surface[:boundary].downcase == "outdoors"

      expect(surface).to_not have_key(:ratio)           unless id == name
      expect(surface[:heatloss]).to be_within(TOL).of(8.89) if id == name
    end
  end

  it "can process JSON surface KHI & PSI + building & edge (2)" do
    translator = OpenStudio::OSVersion::VersionTranslator.new
    TBD.clean!

    file  = File.join(__dir__, "files/osms/out/seb2.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    argh               = {}
    argh[:option     ] = "(non thermal bridging)"
    argh[:io_path    ] = File.join(__dir__, "../json/tbd_seb_n5.json")
    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")

    json     = TBD.process(model, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty
    expect(surfaces).to be_a(Hash)
    expect(surfaces.size).to eq(56)
    expect(io).to be_a(Hash)
    expect(io).to have_key(:edges)
    expect(io[:edges].size).to eq(106)

    # As above, yet the KHI points are now set @0.5 W/K per m (instead of 0)
    surfaces.each do |id, surface|
      next unless surface[:boundary].downcase == "outdoors"

      expect(surface).to_not have_key(:ratio) unless id == "Entryway  Wall 5"
      next                                    unless id == "Entryway  Wall 5"

      expect(surface[:heatloss]).to be_within(TOL).of(12.39)
    end
  end

  it "can process JSON surface KHI & PSI + building & edge (3)" do
    translator = OpenStudio::OSVersion::VersionTranslator.new
    TBD.clean!

    file  = File.join(__dir__, "files/osms/out/seb2.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    # Consider the plenum as UNCONDITIONED.
    plnum = model.getSpaceByName("Level 0 Ceiling Plenum")
    expect(plnum).to_not be_empty
    plnum = plnum.get
    expect(TBD.unconditioned?(plnum)).to be false

    key = "space_conditioning_category"
    val = "Unconditioned"
    expect(plnum.additionalProperties.hasFeature(key)).to be false
    expect(plnum.additionalProperties.setFeature(key, val)).to be true
    expect(TBD.plenum?(plnum)).to be true
    expect(TBD.unconditioned?(plnum)).to be true
    expect(TBD.setpoints(plnum)[:heating]).to be_nil
    expect(TBD.setpoints(plnum)[:cooling]).to be_nil
    expect(TBD.status).to be_zero

    argh               = {}
    argh[:option     ] = "(non thermal bridging)"
    argh[:io_path    ] = File.join(__dir__, "../json/tbd_seb_n6.json")
    argh[:schama_path] = File.join(__dir__, "../tbd.schema.json")

    json     = TBD.process(model, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty
    expect(surfaces).to be_a(Hash)
    expect(surfaces.size).to eq(56)
    expect(io).to be_a(Hash)
    expect(io).to have_key(:edges)
    expect(io[:edges].size).to eq(80)

    # As above, with a "good" surface PSI set
    surfaces.each do |id, surface|
      next unless surface[:boundary].downcase == "outdoors"

      expect(surface).to_not have_key(:ratio) unless id == "Entryway  Wall 5"
      next                                    unless id == "Entryway  Wall 5"

      expect(surface[:heatloss]).to be_within(TOL).of(14.05)
    end
  end

  it "can process JSON surface KHI & PSI + building & edge (4)" do
    translator = OpenStudio::OSVersion::VersionTranslator.new
    TBD.clean!

    file  = File.join(__dir__, "files/osms/out/seb2.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    # Consider the plenum as UNCONDITIONED.
    plnum = model.getSpaceByName("Level 0 Ceiling Plenum")
    expect(plnum).to_not be_empty
    plnum = plnum.get
    expect(TBD.unconditioned?(plnum)).to be false

    key = "space_conditioning_category"
    val = "Unconditioned"
    expect(plnum.additionalProperties.hasFeature(key)).to be false
    expect(plnum.additionalProperties.setFeature(key, val)).to be true
    expect(TBD.plenum?(plnum)).to be true
    expect(TBD.unconditioned?(plnum)).to be true
    expect(TBD.setpoints(plnum)[:heating]).to be_nil
    expect(TBD.setpoints(plnum)[:cooling]).to be_nil
    expect(TBD.status).to be_zero

    argh               = {}
    argh[:option     ] = "compliant" # superseded by :building PSI set on file
    argh[:io_path    ] = File.join(__dir__, "../json/tbd_seb_n7.json")
    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")

    json     = TBD.process(model, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty
    expect(surfaces).to be_a Hash
    expect(surfaces.size).to eq(56)
    expect(io).to be_a(Hash)
    expect(io).to have_key(:edges)
    expect(io[:edges].size).to eq(80)

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
      walls = ["Entryway  Wall 5", "Entryway  Wall 6", "Entryway  Wall 4"]
      next unless surface[:boundary].downcase == "outdoors"

      expect(surface).to have_key(:ratio)         if walls.include?(id)
      expect(surface).to_not have_key(:ratio) unless walls.include?(id)
      next unless id == "Entryway  Wall 5"

      expect(surface[:heatloss]).to be_within(TOL).of(15.62)
    end
  end

  it "can factor in negative PSI-factors (JSON input)" do
    translator = OpenStudio::OSVersion::VersionTranslator.new
    TBD.clean!

    file  = File.join(__dir__, "files/osms/in/warehouse.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    argh               = {}
    argh[:option     ] = "compliant" # superseded by :building PSI set on file
    argh[:io_path    ] = File.join(__dir__, "../json/tbd_warehouse4.json")
    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")

    json     = TBD.process(model, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty
    expect(surfaces).to be_a Hash
    expect(surfaces.size).to eq(23)
    expect(io).to be_a(Hash)
    expect(io).to have_key(:edges)
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

    surfaces.each do |id, surface|
      expect(ids).to have_value(id)         if surface.key?(:edges)
      expect(ids).to_not have_value(id) unless surface.key?(:edges)
    end

    surfaces.each do |id, surface|
      next unless surface[:boundary].downcase == "outdoors"
      next unless surface.key?(:ratio)

      expect(ids).to have_value(id)
      expect(surface).to have_key(:heatloss)

      # Ratios are typically negative e.g., a steel corner column decreasing
      # linked surface RSi values. In some cases, a corner PSI can be positive
      # (and thus increasing linked surface RSi values). This happens when
      # estimating PSI-factors for convex corners while relying on an interior
      # dimensioning convention e.g., BETBG Detail 7.6.2, ISO 14683.
      expect(surface[:ratio]).to be_within(TOL).of(0.18) if id == ids[:a]
      expect(surface[:ratio]).to be_within(TOL).of(0.55) if id == ids[:b]
      expect(surface[:ratio]).to be_within(TOL).of(0.15) if id == ids[:d]
      expect(surface[:ratio]).to be_within(TOL).of(0.43) if id == ids[:e]
      expect(surface[:ratio]).to be_within(TOL).of(0.20) if id == ids[:f]
      expect(surface[:ratio]).to be_within(TOL).of(0.13) if id == ids[:h]
      expect(surface[:ratio]).to be_within(TOL).of(0.12) if id == ids[:j]
      expect(surface[:ratio]).to be_within(TOL).of(0.04) if id == ids[:k]
      expect(surface[:ratio]).to be_within(TOL).of(0.04) if id == ids[:l]

      # In such cases, negative heatloss means heat gained.
      expect(surface[:heatloss]).to be_within(TOL).of(-0.10) if id == ids[:a]
      expect(surface[:heatloss]).to be_within(TOL).of(-0.10) if id == ids[:b]
      expect(surface[:heatloss]).to be_within(TOL).of(-0.10) if id == ids[:d]
      expect(surface[:heatloss]).to be_within(TOL).of(-0.10) if id == ids[:e]
      expect(surface[:heatloss]).to be_within(TOL).of(-0.20) if id == ids[:f]
      expect(surface[:heatloss]).to be_within(TOL).of(-0.20) if id == ids[:h]
      expect(surface[:heatloss]).to be_within(TOL).of(-0.40) if id == ids[:j]
      expect(surface[:heatloss]).to be_within(TOL).of(-0.20) if id == ids[:k]
      expect(surface[:heatloss]).to be_within(TOL).of(-0.20) if id == ids[:l]
    end
  end

  it "can process JSON file read/validate" do
    TBD.clean!

    argh               = {}
    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")
    argh[:io_path    ] = File.join(__dir__, "../json/tbd_json_test.json")

    expect(File.exist?(argh[:schema_path])).to be true
    schema = File.read(argh[:schema_path])
    schema = JSON.parse(schema, symbolize_names: true)
    io     = File.read(argh[:io_path])
    io     = JSON.parse(io, symbolize_names: true)
    expect(JSON::Validator.validate(schema, io)).to be true
    expect(io).to have_key(:description)
    expect(io).to have_key(:schema)
    expect(io).to have_key(:edges)
    expect(io).to have_key(:surfaces)
    expect(io).to have_key(:building)
    expect(io).to_not have_key(:spaces)
    expect(io).to_not have_key(:spacetypes)
    expect(io).to_not have_key(:stories)
    expect(io).to_not have_key(:logs)
    expect(io[:edges].size   ).to eq(1)
    expect(io[:surfaces].size).to eq(1)

    # Loop through input psis to ensure uniqueness vs PSI defaults.
    psi = TBD::PSI.new
    expect(io).to have_key(:psis)

    io[:psis].each { |p| expect(psi.append(p)).to be true }

    expect(psi.set.size).to eq(18)
    expect(psi.set).to have_key("poor (BETBG)")
    expect(psi.set).to have_key("regular (BETBG)")
    expect(psi.set).to have_key("efficient (BETBG)")
    expect(psi.set).to have_key("spandrel (BETBG)")
    expect(psi.set).to have_key("spandrel HP (BETBG)")
    expect(psi.set).to have_key("code (Quebec)")
    expect(psi.set).to have_key("uncompliant (Quebec)")
    expect(psi.set).to have_key("90.1.22|steel.m|default")
    expect(psi.set).to have_key("90.1.22|steel.m|unmitigated")
    expect(psi.set).to have_key("90.1.22|mass.ex|default")
    expect(psi.set).to have_key("90.1.22|mass.ex|unmitigated")
    expect(psi.set).to have_key("90.1.22|mass.in|default")
    expect(psi.set).to have_key("90.1.22|mass.in|unmitigated")
    expect(psi.set).to have_key("90.1.22|wood.fr|default")
    expect(psi.set).to have_key("90.1.22|wood.fr|unmitigated")
    expect(psi.set).to have_key("(non thermal bridging)")
    expect(psi.set).to have_key("good")      # appended
    expect(psi.set).to have_key("compliant") # appended

    # Similar treatment for khis.
    khi = TBD::KHI.new
    expect(io).to have_key(:khis)

    io[:khis].each { |k| expect(khi.append(k)).to be true }

    expect(khi.point.size).to eq(16)
    expect(khi.point).to have_key("poor (BETBG)")
    expect(khi.point).to have_key("regular (BETBG)")
    expect(khi.point).to have_key("efficient (BETBG)")
    expect(khi.point).to have_key("code (Quebec)")
    expect(khi.point).to have_key("uncompliant (Quebec)")
    expect(khi.point).to have_key("90.1.22|steel.m|default")
    expect(khi.point).to have_key("90.1.22|steel.m|unmitigated")
    expect(khi.point).to have_key("90.1.22|mass.ex|default")
    expect(khi.point).to have_key("90.1.22|mass.ex|unmitigated")
    expect(khi.point).to have_key("90.1.22|mass.in|default")
    expect(khi.point).to have_key("90.1.22|mass.in|unmitigated")
    expect(khi.point).to have_key("90.1.22|wood.fr|default")
    expect(khi.point).to have_key("90.1.22|wood.fr|unmitigated")
    expect(khi.point).to have_key("(non thermal bridging)")
    expect(khi.point).to have_key("column")  # appended
    expect(khi.point).to have_key("support") # appended

    expect(khi.point["column" ]).to eq(0.5)
    expect(khi.point["support"]).to eq(0.5)

    expect(psi.set).to have_key("spandrel (BETBG)")
    expect(psi.set).to have_key("spandrel HP (BETBG)")

    expect(io).to have_key(:building)
    expect(io).to have_key(:surfaces)
    expect(io[:building]).to have_key(:psi)
    expect(io[:building][:psi]).to eq("compliant")
    expect(psi.set).to have_key(io[:building][:psi])

    io[:surfaces].each do |surface|
      expect(surface).to have_key(:id)
      expect(surface).to have_key(:psi)
      expect(surface).to have_key(:khis)
      expect(surface[:id  ]).to eq("front wall")
      expect(surface[:psi ]).to eq("good")
      expect(surface[:khis].size).to eq(2)
      expect(psi.set).to have_key(surface[:psi])

      surface[:khis].each do |k|
        expect(k).to have_key(:id)
        expect(khi.point).to have_key(k[:id])
        expect(k[:count]).to eq(3) if k[:id] == "column"
        expect(k[:count]).to eq(4) if k[:id] == "support"
      end
    end

    expect(io).to have_key(:edges)

    io[:edges].each do |edge|
      expect(edge).to have_key(:surfaces)
      expect(edge).to have_key(:psi)
      expect(edge[:psi]).to eq("compliant")
      expect(psi.set).to have_key(edge[:psi])

      edge[:surfaces].each { |surface| expect(surface).to eq("front wall") }
    end

    # A reminder that built-in KHIs are not frozen ...
    khi.point["code (Quebec)"] = 2.0
    expect(khi.point["code (Quebec)"]).to eq(2.0)

    # Load PSI combo JSON example - likely the most expected or common use.
    argh[:io_path] = File.join(__dir__, "../json/tbd_PSI_combo.json")

    io = File.read(argh[:io_path])
    io = JSON.parse(io, symbolize_names: true)
    expect(JSON::Validator.validate(schema, io)).to be true
    expect(io).to have_key(:description)
    expect(io).to have_key(:schema)
    expect(io).to have_key(:spaces)
    expect(io).to have_key(:building)
    expect(io).to_not have_key(:spacetypes)
    expect(io).to_not have_key(:stories)
    expect(io).to_not have_key(:edges)
    expect(io).to_not have_key(:surfaces)
    expect(io).to_not have_key(:logs)
    expect(io[:spaces].size).to eq(1)

    # Loop through input psis to ensure uniqueness vs PSI defaults.
    psi = TBD::PSI.new
    expect(io).to have_key(:psis)

    io[:psis].each { |p| expect(psi.append(p)).to be true }

    expect(psi.set.size).to eq(18)
    expect(psi.set).to have_key("poor (BETBG)")
    expect(psi.set).to have_key("regular (BETBG)")
    expect(psi.set).to have_key("efficient (BETBG)")
    expect(psi.set).to have_key("spandrel (BETBG)")
    expect(psi.set).to have_key("spandrel HP (BETBG)")
    expect(psi.set).to have_key("code (Quebec)")
    expect(psi.set).to have_key("uncompliant (Quebec)")
    expect(psi.set).to have_key("90.1.22|steel.m|default")
    expect(psi.set).to have_key("90.1.22|steel.m|unmitigated")
    expect(psi.set).to have_key("90.1.22|mass.ex|default")
    expect(psi.set).to have_key("90.1.22|mass.ex|unmitigated")
    expect(psi.set).to have_key("90.1.22|mass.in|default")
    expect(psi.set).to have_key("90.1.22|mass.in|unmitigated")
    expect(psi.set).to have_key("90.1.22|wood.fr|default")
    expect(psi.set).to have_key("90.1.22|wood.fr|unmitigated")
    expect(psi.set).to have_key("(non thermal bridging)")
    expect(psi.set).to have_key("OK")      # appended
    expect(psi.set).to have_key("Awesome") # appended

    expect(psi.set["Awesome"][:rimjoist]).to eq(0.2)
    expect(io).to have_key(:building)
    expect(io[:building]).to have_key(:psi)
    expect(io[:building][:psi]).to eq("Awesome")
    expect(psi.set).to have_key(io[:building][:psi])
    expect(io).to have_key(:spaces)

    io[:spaces].each do |space|
      expect(space).to have_key(:psi)
      expect(space[:id ]).to eq("ground-floor restaurant")
      expect(space[:psi]).to eq("OK")
      expect(psi.set).to have_key(space[:psi])
    end

    # Load PSI combo2 JSON example - a more elaborate example, yet common.
    # Post-JSON validation required to handle case sensitive keys & value
    # strings (e.g. "ok" vs "OK" in the file).
    argh[:io_path] = File.join(__dir__, "../json/tbd_PSI_combo2.json")

    io = File.read(argh[:io_path])
    io = JSON.parse(io, symbolize_names: true)
    expect(JSON::Validator.validate(schema, io)).to be true
    expect(io).to have_key(:description)
    expect(io).to have_key(:schema)
    expect(io).to have_key(:edges)
    expect(io).to have_key(:surfaces)
    expect(io).to have_key(:building)
    expect(io).to_not have_key(:spaces)
    expect(io).to_not have_key(:spacetypes)
    expect(io).to_not have_key(:stories)
    expect(io).to_not have_key(:logs)
    expect(io[:edges   ].size).to eq(1)
    expect(io[:surfaces].size).to eq(1)

    # Loop through input psis to ensure uniqueness vs PSI defaults.
    psi = TBD::PSI.new
    expect(io).to have_key(:psis)

    io[:psis].each { |pzi| expect(psi.append(pzi)).to be true }

    expect(psi.set.size).to eq(19)
    expect(psi.set).to have_key("poor (BETBG)")
    expect(psi.set).to have_key("regular (BETBG)")
    expect(psi.set).to have_key("efficient (BETBG)")
    expect(psi.set).to have_key("spandrel (BETBG)")
    expect(psi.set).to have_key("spandrel HP (BETBG)")
    expect(psi.set).to have_key("code (Quebec)")
    expect(psi.set).to have_key("uncompliant (Quebec)")
    expect(psi.set).to have_key("90.1.22|steel.m|default")
    expect(psi.set).to have_key("90.1.22|steel.m|unmitigated")
    expect(psi.set).to have_key("90.1.22|mass.ex|default")
    expect(psi.set).to have_key("90.1.22|mass.ex|unmitigated")
    expect(psi.set).to have_key("90.1.22|mass.in|default")
    expect(psi.set).to have_key("90.1.22|mass.in|unmitigated")
    expect(psi.set).to have_key("90.1.22|wood.fr|default")
    expect(psi.set).to have_key("90.1.22|wood.fr|unmitigated")
    expect(psi.set).to have_key("(non thermal bridging)")
    expect(psi.set).to have_key("OK")              # appended
    expect(psi.set).to have_key("Awesome")         # appended
    expect(psi.set).to have_key("Party wall edge") # appended

    expect(psi.set["Party wall edge"][:party]).to eq(0.4)
    expect(io).to have_key(:surfaces)
    expect(io).to have_key(:building)
    expect(io[:building]).to have_key(:psi)
    expect(io[:building][:psi]).to eq("Awesome")
    expect(psi.set).to have_key(io[:building][:psi])

    io[:surfaces].each do |surface|
      expect(surface).to have_key(:id)
      expect(surface).to have_key(:psi)
      expect(surface[:id ]).to eq("ground-floor restaurant South-wall")
      expect(surface[:psi]).to eq("ok")
      expect(psi.set).to_not have_key(surface[:psi])
    end

    expect(io).to have_key(:edges)
    wlls = []
    wlls << "ground-floor restaurant West-wall"
    wlls << "ground-floor restaurant party wall"

    io[:edges].each do |edge|
      expect(edge).to have_key(:type)
      expect(edge).to have_key(:psi)
      expect(edge[:psi]).to eq("Party wall edge")
      expect(edge[:type].to_s).to include("party")
      expect(psi.set).to have_key(edge[:psi])
      expect(psi.set[edge[:psi]]).to have_key(:party)
      expect(edge).to have_key(:surfaces)

      edge[:surfaces].each { |surface| expect(wlls).to include(surface) }
    end

    # Load full PSI JSON example - with duplicate keys for "party".
    # "JSON Schema Lint" (*) will recognize the duplicate and - as with
    # duplicate Ruby hash keys - will have the second entry ("party": 0.8)
    # override the first ("party": 0.7). Another reminder of post-JSON
    # validation.
    #
    #   * https://jsonschemalint.com/#!/version/draft-04/markup/json
    argh[:io_path] = File.join(__dir__, "../json/tbd_full_PSI.json")

    io = File.read(argh[:io_path])
    io = JSON.parse(io, symbolize_names: true)
    expect(JSON::Validator.validate(schema, io)).to be true

    expect(io).to have_key(:description)
    expect(io).to have_key(:schema)
    expect(io).to_not have_key(:edges)
    expect(io).to_not have_key(:surfaces)
    expect(io).to_not have_key(:spaces)
    expect(io).to_not have_key(:spacetypes)
    expect(io).to_not have_key(:stories)
    expect(io).to_not have_key(:building)
    expect(io).to_not have_key(:logs)

    # Loop through input psis to ensure uniqueness vs PSI defaults.
    psi = TBD::PSI.new
    expect(io).to have_key(:psis)

    io[:psis].each { |p| expect(psi.append(p)).to be true }

    expect(psi.set.size).to eq(17)
    expect(psi.set).to have_key("poor (BETBG)")
    expect(psi.set).to have_key("regular (BETBG)")
    expect(psi.set).to have_key("efficient (BETBG)")
    expect(psi.set).to have_key("spandrel (BETBG)")
    expect(psi.set).to have_key("spandrel HP (BETBG)")
    expect(psi.set).to have_key("code (Quebec)")
    expect(psi.set).to have_key("uncompliant (Quebec)")
    expect(psi.set).to have_key("90.1.22|steel.m|default")
    expect(psi.set).to have_key("90.1.22|steel.m|unmitigated")
    expect(psi.set).to have_key("90.1.22|mass.ex|default")
    expect(psi.set).to have_key("90.1.22|mass.ex|unmitigated")
    expect(psi.set).to have_key("90.1.22|mass.in|default")
    expect(psi.set).to have_key("90.1.22|mass.in|unmitigated")
    expect(psi.set).to have_key("90.1.22|wood.fr|default")
    expect(psi.set).to have_key("90.1.22|wood.fr|unmitigated")
    expect(psi.set).to have_key("(non thermal bridging)")
    expect(psi.set).to have_key("OK")              # appended

    expect(psi.set["OK"][:party]).to eq(0.8)

    # Load minimal PSI JSON example.
    argh[:io_path] = File.join(__dir__, "../json/tbd_minimal_PSI.json")

    io = File.read(argh[:io_path])
    io = JSON.parse(io, symbolize_names: true)
    expect(JSON::Validator.validate(schema, io)).to be true

    # Load minimal KHI JSON example.
    argh[:io_path] = File.join(__dir__, "../json/tbd_minimal_KHI.json")

    io = File.read(argh[:io_path])
    io = JSON.parse(io, symbolize_names: true)
    expect(JSON::Validator.validate(schema, io)).to be true
    v = JSON::Validator.validate(argh[:schema_path], argh[:io_path], uri: true)
    expect(v).to be true

    # Load complete results (ex. UA') example.
    argh[:io_path] = File.join(__dir__, "../json/tbd_warehouse11.json")

    io = File.read(argh[:io_path])
    io = JSON.parse(io, symbolize_names: true)
    expect(JSON::Validator.validate(schema, io)).to be true
    v = JSON::Validator.validate(argh[:schema_path], argh[:io_path], uri: true)
    expect(v).to be true
  end

  it "can factor in spacetype-specific PSI sets (JSON input)" do
    translator = OpenStudio::OSVersion::VersionTranslator.new
    TBD.clean!

    file  = File.join(__dir__, "files/osms/in/warehouse.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    argh               = {}
    argh[:option     ] = "compliant" # superseded by :building PSI set on file
    argh[:io_path    ] = File.join(__dir__, "../json/tbd_warehouse5.json")
    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")

    json     = TBD.process(model, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty
    expect(surfaces).to be_a(Hash)
    expect(surfaces.size).to eq(23)
    expect(io).to be_a(Hash)
    expect(io).to have_key(:edges)
    expect(io[:edges].size).to eq(300)

    types = ["Warehouse Office", "Warehouse Fine"]
    expect(io).to have_key(:spacetypes)

    io[:spacetypes].each do |spacetype|
      expect(spacetype).to have_key(:psi)
      expect(spacetype).to have_key(:id)
      expect(types).to include(spacetype[:id])
    end

    surfaces.each do |id, surface|
      next unless surface[:boundary].downcase == "outdoors"
      next unless surface.key?(:ratio)

      expect(surface).to have_key(:heatloss)
      heatloss = surface[:heatloss]
      expect(heatloss.abs).to be > 0
      expect(surface).to have_key(:space)
      next unless surface[:space].nameString == "Zone1 Office"

      # All applicable thermal bridges/edges derating the office walls inherit
      # the "Warehouse Office" spacetype PSI values (JSON file), except for the
      # shared :rimjoist with the Fine Storage space above. The "Warehouse Fine"
      # spacetype set has a higher :rimjoist PSI value of 0.5 W/K per metre,
      # which overrides the "Warehouse Office" value of 0.3 W/K per metre.
      expect(heatloss).to be_within(TOL).of(11.61) if id == "Office Left Wall"
      expect(heatloss).to be_within(TOL).of(22.94) if id == "Office Front Wall"
    end
  end

  it "can factor in story-specific PSI sets (JSON input)" do
    translator = OpenStudio::OSVersion::VersionTranslator.new
    TBD.clean!

    file  = File.join(__dir__, "files/osms/in/smalloffice.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    argh               = {}
    argh[:option     ] = "compliant" # superseded by :building PSI set on file
    argh[:io_path    ] = File.join(__dir__, "../json/tbd_smalloffice.json")
    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")

    json     = TBD.process(model, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty
    expect(surfaces).to be_a(Hash)
    expect(surfaces.size).to eq(43)
    expect(io).to be_a(Hash)
    expect(io).to have_key(:stories)
    expect(io).to have_key(:edges)
    expect(io[:edges].size).to eq(105)

    io[:stories].each do |story|
      expect(story).to have_key(:psi)
      expect(story).to have_key(:id)
      expect(story[:id]).to eq("Building Story 1")
    end

    surfaces.each do |id, surface|
      next unless surface.key?(:ratio)

      expect(surface).to have_key(:heatloss)
      expect(surface[:heatloss].abs).to be > 0
      next unless surface.key?(:story)

      expect(surface[:story].nameString).to eq("Building Story 1")
    end
  end

  it "can sort multiple story-specific PSI sets (JSON input)" do
    translator = OpenStudio::OSVersion::VersionTranslator.new
    TBD.clean!

    file  = File.join(__dir__, "files/osms/in/midrise.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    argh               = {}
    argh[:option     ] = "(non thermal bridging)" # overridden
    argh[:io_path    ] = File.join(__dir__, "../json/midrise.json")
    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")

    json     = TBD.process(model, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty
    expect(surfaces).to be_a(Hash)
    expect(surfaces.size).to eq(180)
    expect(io).to be_a(Hash)
    expect(io).to have_key(:edges)
    expect(io[:edges].size).to eq(282)

    counter = 0
    stories = ["Building Story 1", "Building Story 2", "Building Story 3"]
    edges   = [:parapetconvex, :transition]
    expect(io).to have_key(:stories)
    expect(io[:stories].size).to eq(stories.size)

    io[:stories].each do |story|
      expect(story).to have_key(:id)
      expect(story).to have_key(:psi)
      expect(stories).to include(story[:id])
    end

    surfaces.each do |id, surface|
      next unless surface.key?(:ratio)

      expect(surface).to have_key(:edges)
      expect(surface).to have_key(:story)
      expect(surface).to have_key(:boundary)
      expect(surface[:boundary]).to eq("Outdoors")
      nom = surface[:story].nameString
      expect(stories).to include(nom)
      expect(nom).to eq(stories[0]) if id.include?("g ")
      expect(nom).to eq(stories[1]) if id.include?("m ")
      expect(nom).to eq(stories[2]) if id.include?("t ")

      counter += 1

      # Illustrating that story-specific PSI set is used when only 1x story.
      surface[:edges].values.each do |edge|
        expect(edge).to have_key(:type)
        expect(edge).to have_key(:psi)
        next unless id.include?("Roof")

        expect(edges).to include(edge[:type])
        next if edge[:type] == :transition
        next if id == "t Roof C"

        expect(edge[:psi]).to be_within(TOL).of(0.178) # 57.3% of 0.311
      end

      # Illustrating that story-specific PSI set is used when only 1x story.
      surface[:edges].values.each do |edge|
        next unless id.include?("t ")
        next unless id.include?("Wall ")
        next unless edge[:type] == :parapetconvex
        next     if id.include?(" C")

        expect(edge[:psi]).to be_within(TOL).of(0.133) # 42.7% of 0.311
      end

      # The shared :rimjoist between middle story and ground floor units could
      # either inherit the "Building Story 1" or "Building Story 2" :rimjoist
      # PSI values. TBD retains the most conductive PSI values in such cases.
      surface[:edges].values.each do |edge|
        next unless id.include?("m ")
        next unless id.include?("Wall ")
        next     if id.include?(" C")
        next unless edge[:type] == :rimjoist

        # Inheriting "Building Story 1" :rimjoist PSI of 0.501 W/K per metre.
        # The SEA unit is above an office space below, which has curtain wall.
        # RSi of insulation layers (to derate):
        #   - office walls   : 0.740 m2.K/W (26.1%)
        #   - SEA walls      : 2.100 m2.K/W (73.9%)
        #
        #   - SEA walls      : 26.1% of 0.501 = 0.3702 W/K per metre
        #   - other walls    : 50.0% of 0.501 = 0.2505 W/K per metre
        if ["m SWall SEA", "m EWall SEA"].include?(id)
          expect(edge[:psi]).to be_within(0.002).of(0.3702)
        else
          expect(edge[:psi]).to be_within(0.002).of(0.2505)
        end
      end
    end

    expect(counter).to eq(51)
  end

  it "can handle parties" do
    translator = OpenStudio::OSVersion::VersionTranslator.new
    TBD.clean!

    file  = File.join(__dir__, "files/osms/out/seb2.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    # Consider the plenum as UNCONDITIONED.
    plnum = model.getSpaceByName("Level 0 Ceiling Plenum")
    expect(plnum).to_not be_empty
    plnum = plnum.get
    expect(TBD.unconditioned?(plnum)).to be false

    key = "space_conditioning_category"
    val = "Unconditioned"
    expect(plnum.additionalProperties.hasFeature(key)).to be false
    expect(plnum.additionalProperties.setFeature(key, val)).to be true
    expect(TBD.plenum?(plnum)).to be true
    expect(TBD.unconditioned?(plnum)).to be true
    expect(TBD.setpoints(plnum)[:heating]).to be_nil
    expect(TBD.setpoints(plnum)[:cooling]).to be_nil
    expect(TBD.status).to be_zero

    # Generate a new SurfacePropertyOtherSideCoefficients object.
    other = OpenStudio::Model::SurfacePropertyOtherSideCoefficients.new(model)
    other.setName("other_side_coefficients")
    expect(other.setZoneAirTemperatureCoefficient(1)).to be true

    # Reset outside boundary conditions for "open area wall 5" (and plenum wall
    # above) by assigning an "OtherSideCoefficients" object (no longer relying
    # on "Adiabatic" string).
    id1 = "Openarea 1 Wall 5"
    s1  = model.getSurfaceByName(id1)
    expect(s1).to_not be_empty
    s1  = s1.get
    expect(s1.setSurfacePropertyOtherSideCoefficients(other)).to be true
    expect(s1.outsideBoundaryCondition).to eq("OtherSideCoefficients")

    id2 = "Level0 Open area 1 Ceiling Plenum AbvClgPlnmWall 5"
    s2  = model.getSurfaceByName(id2)
    expect(s2).to_not be_empty
    s2  = s2.get
    expect(s2.setSurfacePropertyOtherSideCoefficients(other)).to be true
    expect(s2.outsideBoundaryCondition).to eq("OtherSideCoefficients")

    argh               = {}
    argh[:option     ] = "compliant"
    argh[:io_path    ] = File.join(__dir__, "../json/tbd_seb_n8.json")
    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")

    json     = TBD.process(model, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty
    expect(surfaces).to be_a(Hash)
    expect(surfaces.size).to eq(56)
    expect(io).to be_a(Hash)
    expect(io).to have_key(:edges)
    expect(io[:edges].size).to eq(79)

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
            o: "Openarea 1 Wall 6",
            p: "Openarea 1 Wall 7",
            q: "Open area 1 DroppedCeiling"
          }.freeze # removed n: "Openarea 1 Wall 5"

    surfaces.each do |id, surface|
      expect(ids).to     have_value(id)     if surface.key?(:edges)
      expect(ids).to_not have_value(id) unless surface.key?(:edges)
    end

    surfaces.each do |id, surface|
      next unless surface.key?(:edges)

      expect(ids).to have_value(id)
      expect(surface).to have_key(:ratio)
      expect(surface).to have_key(:heatloss)
      h = surface[:heatloss]
      s = model.getSurfaceByName(id)
      expect(s).to_not be_empty
      s = s.get
      expect(s.nameString).to eq(id)
      expect(s.isConstructionDefaulted).to be false
      expect(s.construction.get.nameString).to include(" tbd")

      expect(h).to be_within(TOL).of( 3.62) if id == ids[:a]
      expect(h).to be_within(TOL).of( 6.28) if id == ids[:b]
      expect(h).to be_within(TOL).of( 2.62) if id == ids[:c]
      expect(h).to be_within(TOL).of( 0.17) if id == ids[:d]
      expect(h).to be_within(TOL).of( 7.13) if id == ids[:e]
      expect(h).to be_within(TOL).of( 7.09) if id == ids[:f]
      expect(h).to be_within(TOL).of( 0.20) if id == ids[:g]
      expect(h).to be_within(TOL).of( 7.94) if id == ids[:h]
      expect(h).to be_within(TOL).of( 5.17) if id == ids[:i]
      expect(h).to be_within(TOL).of( 5.01) if id == ids[:j]
      expect(h).to be_within(TOL).of( 0.22) if id == ids[:k]
      expect(h).to be_within(TOL).of( 2.47) if id == ids[:l]
      expect(h).to be_within(TOL).of( 4.03) if id == ids[:m] # 3.11
      expect(h).to be_within(TOL).of( 4.43) if id == ids[:n]
      expect(h).to be_within(TOL).of( 4.27) if id == ids[:o] # 3.35
      expect(h).to be_within(TOL).of( 2.12) if id == ids[:p]
      expect(h).to be_within(TOL).of( 2.16) if id == ids[:q] # 0.31

      # The 2x side walls linked to the new party wall "Openarea 1 Wall 5":
      #   - "Openarea 1 Wall 4", ids[m]
      #   - "Openarea 1 Wall 6", ids[o]
      # ... have 1x half-corner replaced by 100% of a party wall edge, hence
      # the increase in extra heat loss.
      #
      # The "Open area 1 DroppedCeiling", ids[q], has almost a 7x increase in
      # extra heat loss. It used to take ~7.6% of the parapet PSI it shared with
      # "Wall 5". As the latter is no longer a deratable surface (i.e., a party
      # wall), the dropped ceiling hence takes on 100% of the party wall edge
      # it still shares with "Wall 5".
      c = s.construction
      expect(c).to_not be_empty
      c = c.get.to_LayeredConstruction
      expect(c).to_not be_empty
      c = c.get
      i = 0
      i = 2 if s.outsideBoundaryCondition == "Outdoors"
      expect(c.layers[i].nameString).to include("m tbd")
    end
  end

  it "can factor in unenclosed space such as attics" do
    translator = OpenStudio::OSVersion::VersionTranslator.new
    TBD.clean!

    file  = File.join(__dir__, "files/osms/in/smalloffice.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    argh               = {}
    argh[:option     ] = "compliant" # superseded by :building PSI set on file
    argh[:io_path    ] = File.join(__dir__, "../json/tbd_smalloffice.json")
    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")

    json     = TBD.process(model, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty
    expect(surfaces).to be_a(Hash)
    expect(surfaces.size).to eq(43)
    expect(io).to be_a(Hash)
    expect(io).to have_key(:edges)
    expect(io[:edges].size).to eq(105)

    # Check derating of attic floor (5x surfaces).
    model.getSpaces.each do |space|
      next unless space.nameString == "Attic"

      expect(space.thermalZone).to_not be_empty
      zone = space.thermalZone.get
      expect(zone.isPlenum).to be false
      expect(zone.canBePlenum).to be true
      expect(TBD.plenum?(space)).to be false

      space.surfaces.each do |s|
        id = s.nameString
        expect(surfaces).to have_key(id)
        expect(surfaces[id]).to have_key(:space)
        next unless surfaces[id][:space].nameString == "Attic"

        expect(surfaces[id][:conditioned]).to be false
        next if surfaces[id][:boundary] == "Outdoors"

        expect(s.adjacentSurface).to_not be_empty
        adjacent = s.adjacentSurface.get.nameString
        expect(surfaces).to have_key(adjacent)
        expect(surfaces[id][:boundary]).to eq(adjacent)
        expect(surfaces[adjacent][:conditioned]).to be true
      end
    end

    # Check derating of ceilings (below attic).
    surfaces.each do |id, surface|
      next unless surface.key?(:ratio)
      next     if surface[:boundary].downcase == "outdoors"

      expect(surface).to have_key(:heatloss)
      expect(surface[:heatloss].abs).to be > 0
      expect(id).to include("Perimeter_ZN_")
      expect(id).to include("_ceiling")
    end

    # Check derating of outdoor-facing walls.
    surfaces.each do |id, surface|
      next unless surface.key?(:ratio)
      next unless surface[:boundary].downcase == "outdoors"

      expect(surface).to have_key(:heatloss)
      expect(surface[:heatloss].abs).to be > 0
    end
  end

  it "can factor in heads, sills and jambs" do
    translator = OpenStudio::OSVersion::VersionTranslator.new
    TBD.clean!

    file = File.join(__dir__, "files/osms/in/warehouse.osm")
    path = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    argh               = {}
    argh[:option     ] = "compliant" # superseded by :building PSI set on file
    argh[:io_path    ] = File.join(__dir__, "../json/tbd_warehouse7.json")
    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")

    json     = TBD.process(model, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty
    expect(surfaces).to be_a(Hash)
    expect(surfaces.size).to eq(23)
    expect(io).to be_a(Hash)
    expect(io).to have_key(:edges)
    expect(io[:edges].size).to eq(300)

    n_transitions   = 0
    n_parapets      = 0
    n_fen_edges     = 0
    n_heads         = 0
    n_sills         = 0
    n_jambs         = 0
    n_skylightheads = 0
    n_skylightsills = 0
    n_skylightjambs = 0

    types = {
      t1: :transition,
      t2: :parapetconvex,
      t3: :fenestration,
      t4: :head,
      t5: :sill,
      t6: :jamb,
      t7: :skylighthead,
      t8: :skylightsill,
      t9: :skylightjamb
    }.freeze

    surfaces.each do |id, surface|
      next unless surface[:boundary].downcase == "outdoors"
      next unless surface.key?(:ratio)

      expect(surface).to have_key(:heatloss)
      expect(surface[:heatloss].abs).to be > 0
      next unless id == "Bulk Storage Roof"

      expect(surfaces[id]).to have_key(:edges)
      expect(surfaces[id][:edges].size).to eq(132)

      surfaces[id][:edges].values.each do |edge|
        expect(edge).to have_key(:type)
        t = edge[:type]
        expect(types.values).to include(t)

        n_transitions   += 1 if edge[:type] == types[:t1]
        n_parapets      += 1 if edge[:type] == types[:t2]
        n_fen_edges     += 1 if edge[:type] == types[:t3]
        n_heads         += 1 if edge[:type] == types[:t4]
        n_sills         += 1 if edge[:type] == types[:t5]
        n_jambs         += 1 if edge[:type] == types[:t6]
        n_skylightheads += 1 if edge[:type] == types[:t7]
        n_skylightsills += 1 if edge[:type] == types[:t8]
        n_skylightjambs += 1 if edge[:type] == types[:t9]
      end
    end

    expect(n_transitions  ).to eq(  1)
    expect(n_parapets     ).to eq(  3)
    expect(n_fen_edges    ).to eq(  0)
    expect(n_heads        ).to eq(  0)
    expect(n_sills        ).to eq(  0)
    expect(n_jambs        ).to eq(  0)
    expect(n_skylightheads).to eq(  0)
    expect(n_skylightsills).to eq(  0)
    expect(n_skylightjambs).to eq(128)
  end

  it "has a PSI class" do
    TBD.clean!

    psi = TBD::PSI.new
    expect(psi.set).to have_key("poor (BETBG)")
    expect(psi.complete?("poor (BETBG)")).to be true
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty

    expect(psi.set).to_not have_key("new set")
    expect(psi.complete?("new set")).to be false
    expect(TBD.error?).to be true
    expect(TBD.logs.size).to eq(1)
    TBD.clean!

    new_set = {
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

    expect(psi.append(new_set)).to be true
    expect(psi.set).to have_key("new set")
    expect(psi.complete?("new set")).to be true
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty

    expect(psi.set["new set"][:grade].to_i).to be_zero
    new_set[:grade] = 1.0
    expect(psi.append(new_set)).to be false # does not override existing value
    expect(TBD.error?).to be true
    expect(TBD.logs.size).to eq(1)
    expect(psi.set["new set"][:grade].to_i).to be_zero
    expect(psi.set).to_not have_key("incomplete set")
    expect(psi.complete?("incomplete set")).to be false

    incomplete_set = {
      id:    "incomplete set",
      grade: 0.000
    }.freeze

    expect(psi.append(incomplete_set)).to be true
    expect(psi.set).to have_key("incomplete set")
    expect(psi.complete?("incomplete set")).to be false
    expect(psi.set).to_not have_key("all sills")

    all_sills = {
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
    }.freeze

    expect(psi.append(all_sills)).to be true
    expect(psi.set).to have_key("all sills")
    expect(psi.complete?("all sills")).to be true

    shorts = psi.shorthands("all sills")
    expect(shorts[:has]).to_not be_empty
    expect(shorts[:val]).to_not be_empty

    holds = shorts[:has]
    vals  = shorts[:val]
    expect(holds[:fenestration]).to be true
    expect(vals[:sill       ]).to be_within(0.001).of(0.371)
    expect(vals[:sillconcave]).to be_within(0.001).of(0.372)
    expect(vals[:sillconvex ]).to be_within(0.001).of(0.373)
    expect(psi.set).to_not have_key("partial sills")

    partial_sills = {
      id:            "partial sills",
      fenestration:  0.391,
      head:          0.381,
      headconcave:   0.382,
      headconvex:    0.383,
      sill:          0.371,
      sillconcave:   0.372,
      # sillconvex:    0.373, # dropping the convex variant
      jamb:          0.361,
      jambconcave:   0.362,
      jambconvex:    0.363,
      rimjoist:      0.001,
      parapet:       0.002,
      corner:        0.003,
      balcony:       0.004,
      party:         0.005,
      grade:         0.006
    }.freeze

    expect(psi.append(partial_sills)).to be true
    expect(psi.set).to have_key("partial sills")
    expect(psi.complete?("partial sills")).to be true # can be a building set
    shorts = psi.shorthands("partial sills")
    expect(shorts[:has]).to_not be_empty
    expect(shorts[:val]).to_not be_empty

    holds = shorts[:has]
    vals  = shorts[:val]
    expect(holds[:sillconvex]).to be false # absent from PSI set
    expect(vals[:sill       ]).to be_within(0.001).of(0.371)
    expect(vals[:sillconcave]).to be_within(0.001).of(0.372)
    expect(vals[:sillconvex ]).to be_within(0.001).of(0.371) # inherits :sill
    expect(psi.set).to_not have_key("no sills")

    no_sills = {
      id:            "no sills",
      fenestration:  0.391,
      head:          0.381,
      headconcave:   0.382,
      headconvex:    0.383,
      # sill:          0.371, # dropping the concave variant
      # sillconcave:   0.372, # dropping the concave variant
      # sillconvex:    0.373, # dropping the convex variant
      jamb:          0.361,
      jambconcave:   0.362,
      jambconvex:    0.363,
      rimjoist:      0.001,
      parapet:       0.002,
      corner:        0.003,
      balcony:       0.004,
      party:         0.005,
      grade:         0.006
    }.freeze

    expect(psi.append(no_sills)).to be true
    expect(psi.set).to have_key("no sills")
    expect(psi.complete?("no sills")).to be true # can be a building set
    shorts = psi.shorthands("no sills")
    expect(shorts[:has]).to_not be_empty
    expect(shorts[:val]).to_not be_empty

    holds = shorts[:has]
    vals  = shorts[:val]
    expect(holds[:sill       ]).to be false # absent from PSI set
    expect(holds[:sillconcave]).to be false # absent from PSI set
    expect(holds[:sillconvex ]).to be false # absent from PSI set
    expect(vals[:sill        ]).to be_within(0.001).of(0.391)
    expect(vals[:sillconcave ]).to be_within(0.001).of(0.391)
    expect(vals[:sillconvex  ]).to be_within(0.001).of(0.391) # :fenestration
  end

  it "can factor-in Frame & Divider (F&D) objects" do
    translator = OpenStudio::OSVersion::VersionTranslator.new
    version    = OpenStudio.openStudioVersion.split(".").join.to_i
    TBD.clean!

    model = OpenStudio::Model::Model.new
    vec   = OpenStudio::Point3dVector.new
    vec  << OpenStudio::Point3d.new( 2.00, 0.00, 3.00)
    vec  << OpenStudio::Point3d.new( 2.00, 0.00, 1.00)
    vec  << OpenStudio::Point3d.new( 4.00, 0.00, 1.00)
    vec  << OpenStudio::Point3d.new( 4.00, 0.00, 3.00)
    sub   = OpenStudio::Model::SubSurface.new(vec, model)

    # Aide-mémoire: attributes/objects subsurfaces are allowed to have/be.
    OpenStudio::Model::SubSurface.validSubSurfaceTypeValues.each do |type|
      expect(sub.setSubSurfaceType(type)).to be true
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
        expect(sub.allowWindowPropertyFrameAndDivider   ).to be true
        next if version < 330

        expect(sub.allowDaylightingDeviceTubularDiffuser).to be false
        expect(sub.allowDaylightingDeviceTubularDome    ).to be false
      when "OperableWindow"
        expect(sub.allowWindowPropertyFrameAndDivider   ).to be true
        next if version < 330

        expect(sub.allowDaylightingDeviceTubularDiffuser).to be false
        expect(sub.allowDaylightingDeviceTubularDome    ).to be false
      when "Door"
        expect(sub.allowWindowPropertyFrameAndDivider   ).to be false
        next if version < 330

        expect(sub.allowDaylightingDeviceTubularDiffuser).to be false
        expect(sub.allowDaylightingDeviceTubularDome    ).to be false
      when "GlassDoor"
        expect(sub.allowWindowPropertyFrameAndDivider   ).to be true
        next if version < 330

        expect(sub.allowDaylightingDeviceTubularDiffuser).to be false
        expect(sub.allowDaylightingDeviceTubularDome    ).to be false
      when "OverheadDoor"
        expect(sub.allowWindowPropertyFrameAndDivider   ).to be false
        next if version < 330

        expect(sub.allowDaylightingDeviceTubularDiffuser).to be false
        expect(sub.allowDaylightingDeviceTubularDome    ).to be false
      when "Skylight"
        if version < 321
          expect(sub.allowWindowPropertyFrameAndDivider ).to be false
        else
          expect(sub.allowWindowPropertyFrameAndDivider ).to be true
        end

        next if version < 330

        expect(sub.allowDaylightingDeviceTubularDiffuser).to be false
        expect(sub.allowDaylightingDeviceTubularDome    ).to be false
      when "TubularDaylightDome"
        expect(sub.allowWindowPropertyFrameAndDivider   ).to be false
        next if version < 330

        expect(sub.allowDaylightingDeviceTubularDiffuser).to be false
        expect(sub.allowDaylightingDeviceTubularDome    ).to be true
      when "TubularDaylightDiffuser"
        expect(sub.allowWindowPropertyFrameAndDivider   ).to be false
        next if version < 330

        expect(sub.allowDaylightingDeviceTubularDiffuser).to be true
        expect(sub.allowDaylightingDeviceTubularDome    ).to be false
      else
        expect(true).to be false # Unknown SubSurfaceType!
      end
    end

    file  = File.join(__dir__, "files/osms/in/warehouse.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    wll = "Office Front Wall"
    win = "Office Front Wall Window 1"

    front = model.getSurfaceByName(wll)
    expect(front).to_not be_empty
    front = front.get

    argh               = {}
    argh[:option     ] = "poor (BETBG)"
    argh[:io_path    ] = File.join(__dir__, "../json/tbd_warehouse8.json")
    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")

    json     = TBD.process(model, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty
    expect(surfaces).to be_a(Hash)
    expect(surfaces.size).to eq(23)
    expect(io).to be_a(Hash)
    expect(io).to have_key(:edges)
    expect(io[:edges].size).to eq(300)

    n_transitions = 0
    n_fen_edges   = 0
    n_heads       = 0
    n_sills       = 0
    n_jambs       = 0
    n_doorheads   = 0
    n_doorsills   = 0
    n_doorjambs   = 0
    n_grades      = 0
    n_corners     = 0
    n_rimjoists   = 0
    fen_length    = 0

    t1  = :transition
    t2  = :fenestration
    t3  = :head
    t4  = :sill
    t5  = :jamb
    t6  = :doorhead
    t7  = :doorsill
    t8  = :doorjamb
    t9  = :gradeconvex
    t10 = :cornerconvex
    t11 = :rimjoist

    surfaces.each do |id, surface|
      next unless surface[:boundary].downcase == "outdoors"
      next unless surface.key?(:ratio)

      expect(surface).to have_key(:heatloss)
      expect(surface[:heatloss].abs).to be > 0
      next unless id == wll

      expect(surface[:heatloss]).to be_within(0.1).of(50.2)
      expect(surface).to have_key(:edges)
      expect(surface[:edges].size).to eq(17)

      surface[:edges].values.each do |edge|
        expect(edge).to have_key(:type)

        n_transitions += 1 if edge[:type] == t1
        n_fen_edges   += 1 if edge[:type] == t2
        n_heads       += 1 if edge[:type] == t3
        n_sills       += 1 if edge[:type] == t4
        n_jambs       += 1 if edge[:type] == t5
        n_doorheads   += 1 if edge[:type] == t6
        n_doorsills   += 1 if edge[:type] == t7
        n_doorjambs   += 1 if edge[:type] == t8
        n_grades      += 1 if edge[:type] == t9
        n_corners     += 1 if edge[:type] == t10
        n_rimjoists   += 1 if edge[:type] == t11

        fen_length    += edge[:length] if edge[:type] == t2
      end
    end

    expect(n_transitions).to eq(1)
    expect(n_fen_edges  ).to eq(4) # Office Front Wall Window 1
    expect(n_heads      ).to eq(1) # Window 2
    expect(n_sills      ).to eq(1) # Window 2
    expect(n_jambs      ).to eq(2) # Window 2
    expect(n_doorheads  ).to eq(1) # door
    expect(n_doorsills  ).to eq(0) # grade PSI > fenestration PSI
    expect(n_doorjambs  ).to eq(2) # door
    expect(n_grades     ).to eq(3) # including door sill
    expect(n_corners    ).to eq(1)
    expect(n_rimjoists  ).to eq(1)

    # Net & gross areas, as well as fenestration perimeters, reflect cases
    # without frame & divider objects. This is also what would be reported by
    # SketchUp, for instance.
    expect(fen_length     ).to be_within(TOL).of( 10.36) # Window 1 perimeter
    expect(front.netArea  ).to be_within(TOL).of( 95.49)
    expect(front.grossArea).to be_within(TOL).of(110.54)


    # Open another warehouse model and add/assign a Frame & Divider object.
    file     = File.join(__dir__, "files/osms/in/warehouse.osm")
    path     = OpenStudio::Path.new(file)
    model_FD = translator.loadModel(path)
    expect(model_FD).to_not be_empty
    model_FD = model_FD.get

    # Adding/validating Frame & Divider object.
    fd    = OpenStudio::Model::WindowPropertyFrameAndDivider.new(model_FD)
    width = 0.03
    expect(fd.setFrameWidth(width)).to be true # 30mm (narrow) around glazing
    expect(fd.setFrameConductance(2.500)).to be true

    window_FD = model_FD.getSubSurfaceByName(win)
    expect(window_FD).to_not be_empty
    window_FD = window_FD.get

    expect(window_FD.allowWindowPropertyFrameAndDivider).to be true
    expect(window_FD.setWindowPropertyFrameAndDivider(fd)).to be true
    width2 = window_FD.windowPropertyFrameAndDivider.get.frameWidth
    expect(width2).to be_within(TOL).of(width)

    front_FD = model_FD.getSurfaceByName(wll)
    expect(front_FD).to_not be_empty
    front_FD = front_FD.get

    expect(window_FD.netArea  ).to be_within(TOL).of(  5.58)
    expect(window_FD.grossArea).to be_within(TOL).of(  5.58) # not 5.89 (OK)
    expect(front_FD.grossArea ).to be_within(TOL).of(110.54) # this is OK

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
      expect(window_FD.roughOpeningArea).to be_within(TOL).of( 5.89)
      expect(front_FD.netArea          ).to be_within(TOL).of(95.17) # great !!
      expect(front_FD.windowToWallRatio).to be_within(TOL).of(0.104) # !!
    else
      expect(front_FD.netArea          ).to be_within(TOL).of(95.49) # !95.17
      expect(front_FD.windowToWallRatio).to be_within(TOL).of(0.101) # !0.104
    end

    # If one runs an OpenStudio +v3.4 simulation with the exported file below
    # ("model_FD.osm"), EnergyPlus will correctly report (e.g. eplustbl.htm)
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
    pth = File.join(__dir__, "files/osms/out/model_FD.osm")
    model_FD.save(pth, true)

    argh               = {}
    argh[:option     ] = "poor (BETBG)"
    argh[:io_path    ] = File.join(__dir__, "../json/tbd_warehouse8.json")
    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")

    json     = TBD.process(model_FD, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.status.zero?).to eq(true)
    expect(TBD.logs).to be_empty
    expect(surfaces).to be_a(Hash)
    expect(surfaces.size).to eq(23)
    expect(io).to be_a(Hash)
    expect(io).to have_key(:edges)
    expect(io[:edges].size).to eq(300)

    # TBD calling on workarounds.
    net_area   = surfaces[wll][:net  ]
    gross_area = surfaces[wll][:gross]
    expect(net_area  ).to be_within(TOL).of( 95.17) # ! API 95.49
    expect(gross_area).to be_within(TOL).of(110.54) # same
    expect(surfaces[wll]).to have_key(:windows)
    expect(surfaces[wll][:windows].size).to eq(2)

    surfaces[wll][:windows].each do |i, window|
      expect(window).to have_key(:points)
      expect(window[:points].size).to eq(4)
      next unless i == win

      expect(window).to have_key(:gross)
      expect(window[:gross]).to be_within(TOL).of(5.89) # ! API 5.58
    end

    # Adding a clerestory window, slightly above "Office Front Wall Window 1",
    # to test/validate overlapping cases. Starting with a safe case.
    #
    # FYI, original "Office Front Wall Window 1" (without F&D widths).
    #   3.66, 0, 2.44
    #   3.66, 0, 0.91
    #   7.31, 0, 0.91
    #   7.31, 0, 2.44

    cl_v  = OpenStudio::Point3dVector.new
    cl_v << OpenStudio::Point3d.new( 3.66, 0.00, 4.00)
    cl_v << OpenStudio::Point3d.new( 3.66, 0.00, 2.47)
    cl_v << OpenStudio::Point3d.new( 7.31, 0.00, 2.47)
    cl_v << OpenStudio::Point3d.new( 7.31, 0.00, 4.00)
    clerestory = OpenStudio::Model::SubSurface.new(cl_v, model_FD)
    clerestory.setName("clerestory")
    expect(clerestory.setSurface(front_FD)).to be true
    expect(clerestory.setSubSurfaceType("FixedWindow")).to be true
    # ... reminder: set subsurface type AFTER setting its parent surface!

    argh = { option: "poor (BETBG)" }

    json     = TBD.process(model_FD, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.warn?).to be true # surfaces have already been derated
    expect(TBD.logs.size).to eq(12)
    expect(surfaces).to be_a(Hash)
    expect(surfaces.size).to eq(23)
    expect(surfaces).to have_key(wll)
    expect(io).to be_a(Hash)
    expect(io).to have_key(:edges)
    expect(io[:edges].size).to eq(305)

    expect(surfaces[wll]).to have_key(:windows)
    wins = surfaces[wll][:windows]
    expect(wins.size).to eq(3)
    expect(wins).to have_key("clerestory")
    expect(wins).to have_key(win)

    expect(wins["clerestory"]).to have_key(:points)
    expect(wins[win         ]).to have_key(:points)

    v1 = window_FD.vertices         # original OSM vertices for window
    f1 = TBD.offset(v1, width, 300) # offset vertices, forcing v300 version
    expect(f1).to be_a(OpenStudio::Point3dVector)
    expect(f1.size).to eq(4)

    f1.each { |f| expect(f).to be_a(OpenStudio::Point3d) }

    f1area = OpenStudio.getArea(f1)
    expect(f1area).to_not be_empty
    f1area = f1area.get

    expect(f1area).to be_within(TOL).of(5.89             )
    expect(f1area).to be_within(TOL).of(wins[win][:area ])
    expect(f1area).to be_within(TOL).of(wins[win][:gross])

    # For SDK versions prior to v321, the offset vertices are generated in the
    # right order with respect to the original subsurface vertices.
    expect((f1[0].x - v1[0].x).abs).to be_within(TOL).of(width)
    expect((f1[1].x - v1[1].x).abs).to be_within(TOL).of(width)
    expect((f1[2].x - v1[2].x).abs).to be_within(TOL).of(width)
    expect((f1[3].x - v1[3].x).abs).to be_within(TOL).of(width)
    expect((f1[0].y - v1[0].y).abs).to be_within(TOL).of(0    )
    expect((f1[1].y - v1[1].y).abs).to be_within(TOL).of(0    )
    expect((f1[2].y - v1[2].y).abs).to be_within(TOL).of(0    )
    expect((f1[3].y - v1[3].y).abs).to be_within(TOL).of(0    )
    expect((f1[0].z - v1[0].z).abs).to be_within(TOL).of(width)
    expect((f1[1].z - v1[1].z).abs).to be_within(TOL).of(width)
    expect((f1[2].z - v1[2].z).abs).to be_within(TOL).of(width)
    expect((f1[3].z - v1[3].z).abs).to be_within(TOL).of(width)

    v2 = clerestory.vertices
    p2 = wins["clerestory"][:points] # same as original OSM vertices

    expect((p2[0].x - v2[0].x).abs).to be_within(TOL).of(0)
    expect((p2[1].x - v2[1].x).abs).to be_within(TOL).of(0)
    expect((p2[2].x - v2[2].x).abs).to be_within(TOL).of(0)
    expect((p2[3].x - v2[3].x).abs).to be_within(TOL).of(0)
    expect((p2[0].y - v2[0].y).abs).to be_within(TOL).of(0)
    expect((p2[1].y - v2[1].y).abs).to be_within(TOL).of(0)
    expect((p2[2].y - v2[2].y).abs).to be_within(TOL).of(0)
    expect((p2[3].y - v2[3].y).abs).to be_within(TOL).of(0)
    expect((p2[0].z - v2[0].z).abs).to be_within(TOL).of(0)
    expect((p2[1].z - v2[1].z).abs).to be_within(TOL).of(0)
    expect((p2[2].z - v2[2].z).abs).to be_within(TOL).of(0)
    expect((p2[3].z - v2[3].z).abs).to be_within(TOL).of(0)

    # In addition, the top of the "Office Front Wall Window 1" is aligned with
    # the bottom of the clerestory, i.e. no conflicts between siblings.
    expect((f1[0].z - p2[1].z).abs).to be_within(TOL).of(0)
    expect((f1[3].z - p2[2].z).abs).to be_within(TOL).of(0)
    expect(TBD.warn?).to be true

    # Testing both 'fits?' & 'overlaps?' functions.
    TBD.clean!
    vec2 = OpenStudio::Point3dVector.new

    p2.each { |p| vec2 << OpenStudio::Point3d.new(p.x, p.y, p.z) }

    expect(TBD.fits?(f1, vec2)).to be false
    expect(TBD.overlaps?(f1, vec2)).to be false
    expect(TBD.status).to be_zero

    # Same exercise, yet provide clerestory with Frame & Divider.
    fd2    = OpenStudio::Model::WindowPropertyFrameAndDivider.new(model_FD)
    width2 = 0.06
    expect(fd2.setFrameWidth(width2)).to be true
    expect(fd2.setFrameConductance(2.500)).to be true
    expect(clerestory.allowWindowPropertyFrameAndDivider).to be true
    expect(clerestory.setWindowPropertyFrameAndDivider(fd2)).to be true
    width3 = clerestory.windowPropertyFrameAndDivider.get.frameWidth
    expect(width3).to be_within(TOL).of(width2)

    argh = { option: "poor (BETBG)" }

    json     = TBD.process(model_FD, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.error?).to be true # conflict between F&D windows
    expect(TBD.logs.size).to eq(13)
    expect(surfaces).to be_a(Hash)
    expect(surfaces.size).to eq(23)
    expect(surfaces).to have_key(wll)
    expect(io).to be_a(Hash)
    expect(io).to have_key(:edges)
    expect(io[:edges].size).to eq(304)

    expect(surfaces[wll]).to have_key(:windows)
    wins = surfaces[wll][:windows]
    expect(wins.size).to eq(3)
    expect(wins).to have_key("clerestory")
    expect(wins).to have_key(win)
    expect(wins["clerestory"]).to have_key(:points)
    expect(wins[win         ]).to have_key(:points)

    # As there are conflicts between both windows (due to conflicting Frame &
    # Divider parameters), TBD will ignore Frame & Divider coordinates and fall
    # back to original OpenStudio subsurface vertices.
    v1 = window_FD.vertices # original OSM vertices for window
    p1 = wins[win][:points] # Topolys vertices, as original

    expect((p1[0].x - v1[0].x).abs).to be_within(TOL).of(0)
    expect((p1[1].x - v1[1].x).abs).to be_within(TOL).of(0)
    expect((p1[2].x - v1[2].x).abs).to be_within(TOL).of(0)
    expect((p1[3].x - v1[3].x).abs).to be_within(TOL).of(0)
    expect((p1[0].y - v1[0].y).abs).to be_within(TOL).of(0)
    expect((p1[1].y - v1[1].y).abs).to be_within(TOL).of(0)
    expect((p1[2].y - v1[2].y).abs).to be_within(TOL).of(0)
    expect((p1[3].y - v1[3].y).abs).to be_within(TOL).of(0)
    expect((p1[0].z - v1[0].z).abs).to be_within(TOL).of(0)
    expect((p1[1].z - v1[1].z).abs).to be_within(TOL).of(0)
    expect((p1[2].z - v1[2].z).abs).to be_within(TOL).of(0)
    expect((p1[3].z - v1[3].z).abs).to be_within(TOL).of(0)

    v2 = clerestory.vertices
    p2 = wins["clerestory"][:points] # same as original OSM vertices

    expect((p2[0].x - v2[0].x).abs).to be_within(TOL).of(0)
    expect((p2[1].x - v2[1].x).abs).to be_within(TOL).of(0)
    expect((p2[2].x - v2[2].x).abs).to be_within(TOL).of(0)
    expect((p2[3].x - v2[3].x).abs).to be_within(TOL).of(0)
    expect((p2[0].y - v2[0].y).abs).to be_within(TOL).of(0)
    expect((p2[1].y - v2[1].y).abs).to be_within(TOL).of(0)
    expect((p2[2].y - v2[2].y).abs).to be_within(TOL).of(0)
    expect((p2[3].y - v2[3].y).abs).to be_within(TOL).of(0)
    expect((p2[0].z - v2[0].z).abs).to be_within(TOL).of(0)
    expect((p2[1].z - v2[1].z).abs).to be_within(TOL).of(0)
    expect((p2[2].z - v2[2].z).abs).to be_within(TOL).of(0)
    expect((p2[3].z - v2[3].z).abs).to be_within(TOL).of(0)

    # In addition, the top of the "Office Front Wall Window 1" is no longer
    # aligned with the bottom of the clerestory.
    expect(((p1[0].z - p2[1].z).abs - width).abs).to be_within(TOL).of(0)
    expect(((p1[3].z - p2[2].z).abs - width).abs).to be_within(TOL).of(0)

    TBD.clean!
    vec1 = OpenStudio::Point3dVector.new
    vec2 = OpenStudio::Point3dVector.new

    p1.each { |p| vec1 << OpenStudio::Point3d.new(p.x, p.y, p.z) }
    p2.each { |p| vec2 << OpenStudio::Point3d.new(p.x, p.y, p.z) }

    expect(TBD.fits?(vec1, vec2)).to be false
    expect(TBD.overlaps?(vec1, vec2)).to be false
    expect(TBD.status).to be_zero


    # --- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- --- #
    # Testing more complex cases, e.g. triangular windows, irregular 4-side
    # windows, rough opening edges overlapping parent surface edges. There's
    # overlap between this set of tests and a similar set in OSut.
    model = OpenStudio::Model::Model.new
    space = OpenStudio::Model::Space.new(model)
    space.setName("Space")

    # Windows are SimpleGlazing constructions.
    fen     = OpenStudio::Model::Construction.new(model)
    glazing = OpenStudio::Model::SimpleGlazing.new(model)
    layers  = OpenStudio::Model::MaterialVector.new
    fen.setName("FD fen")
    glazing.setName("FD glazing")
    expect(glazing.setUFactor(2.0)).to be true
    layers << glazing
    expect(fen.setLayers(layers)).to be true

    # Frame & Divider object.
    w000 = 0.000
    w200 = 0.200 # 0mm to 200mm (wide!) around glazing
    fd   = OpenStudio::Model::WindowPropertyFrameAndDivider.new(model)
    fd.setName("FD")
    expect(fd.setFrameConductance(0.500)).to be true
    expect(fd.isFrameWidthDefaulted).to be true
    expect(fd.frameWidth).to be_within(TOL).of(w000)

    # A square base wall surface:
    v0  = OpenStudio::Point3dVector.new
    v0 << OpenStudio::Point3d.new( 0.00, 0.00, 10.00)
    v0 << OpenStudio::Point3d.new( 0.00, 0.00,  0.00)
    v0 << OpenStudio::Point3d.new(10.00, 0.00,  0.00)
    v0 << OpenStudio::Point3d.new(10.00, 0.00, 10.00)

    # A first triangular window:
    v1  = OpenStudio::Point3dVector.new
    v1 << OpenStudio::Point3d.new( 2.00, 0.00, 8.00)
    v1 << OpenStudio::Point3d.new( 1.00, 0.00, 6.00)
    v1 << OpenStudio::Point3d.new( 4.00, 0.00, 9.00)

    # A larger, irregular window:
    v2  = OpenStudio::Point3dVector.new
    v2 << OpenStudio::Point3d.new( 7.00, 0.00, 4.00)
    v2 << OpenStudio::Point3d.new( 4.00, 0.00, 1.00)
    v2 << OpenStudio::Point3d.new( 8.00, 0.00, 2.00)
    v2 << OpenStudio::Point3d.new( 9.00, 0.00, 3.00)

    # A final triangular window, near the wall's upper right corner:
    v3  = OpenStudio::Point3dVector.new
    v3 << OpenStudio::Point3d.new( 9.00, 0.00, 9.80)
    v3 << OpenStudio::Point3d.new( 9.80, 0.00, 9.00)
    v3 << OpenStudio::Point3d.new( 9.80, 0.00, 9.80)

    w0 = OpenStudio::Model::Surface.new(v0, model)
    w1 = OpenStudio::Model::SubSurface.new(v1, model)
    w2 = OpenStudio::Model::SubSurface.new(v2, model)
    w3 = OpenStudio::Model::SubSurface.new(v3, model)
    w0.setName("w0")
    w1.setName("w1")
    w2.setName("w2")
    w3.setName("w3")
    expect(w0.setSpace(space)).to be true
    sub_gross = 0

    [w1, w2, w3].each do |w|
      expect(w.setSubSurfaceType("FixedWindow")).to be true
      expect(w.setSurface(w0)).to be true
      expect(w.setConstruction(fen)).to be true
      expect(w.uFactor).to_not be_empty
      expect(w.uFactor.get).to be_within(0.1).of(2.0)
      expect(w.allowWindowPropertyFrameAndDivider).to be true
      expect(w.setWindowPropertyFrameAndDivider(fd)).to be true
      width = w.windowPropertyFrameAndDivider.get.frameWidth
      expect(width).to be_within(TOL).of(w000)

      sub_gross += w.grossArea
    end

    expect(w1.grossArea).to be_within(TOL).of(1.50)
    expect(w2.grossArea).to be_within(TOL).of(6.00)
    expect(w3.grossArea).to be_within(TOL).of(0.32)
    expect(w0.grossArea).to be_within(TOL).of(100.00)
    expect(w1.netArea).to be_within(TOL).of(w1.grossArea)
    expect(w2.netArea).to be_within(TOL).of(w2.grossArea)
    expect(w3.netArea).to be_within(TOL).of(w3.grossArea)
    expect(w0.netArea).to be_within(TOL).of(w0.grossArea - sub_gross)

    # Applying 2 sets of alterations:
    #   - without, then with Frame & Dividers (F&D)
    #   - 3 successive 20deg rotations around:
    angle  = Math::PI / 9
    origin = OpenStudio::Point3d.new(0, 0, 0)
    east   = OpenStudio::Point3d.new(1, 0, 0) - origin
    up     = OpenStudio::Point3d.new(0, 0, 1) - origin
    north  = OpenStudio::Point3d.new(0, 1, 0) - origin

    4.times.each do |i| # successive rotations
      unless i.zero?
        r = OpenStudio.createRotation(origin,  east, angle) if i == 1
        r = OpenStudio.createRotation(origin,    up, angle) if i == 2
        r = OpenStudio.createRotation(origin, north, angle) if i == 3
        expect(w0.setVertices(r.inverse * w0.vertices)).to be true
        expect(w1.setVertices(r.inverse * w1.vertices)).to be true
        expect(w2.setVertices(r.inverse * w2.vertices)).to be true
        expect(w3.setVertices(r.inverse * w3.vertices)).to be true
      end

      2.times.each do |j| # F&D
        if j.zero?
          wx = w000
          fd.resetFrameWidth unless i.zero?
        else
          wx = w200
          expect(fd.setFrameWidth(wx)).to be true

          [w1, w2, w3].each do |w|
            width = w.windowPropertyFrameAndDivider.get.frameWidth
            expect(width).to be_within(TOL).of(wx)
          end
        end

        # TBD's 'properties' relies on OSut's 'offset' solution when dealing
        # with subsurfaces with F&D. It offers 3x options:
        #   1. native, 3D vector-based calculations (only option for OS < v321)
        #   2. SDK's reliance on Boost's 'buffer' (default for v321 < OS < v340)
        #   3. SDK's 'rough opening' vertices (default for SDK v340+)
        #
        # Options #2 & #3 both rely on Boost's 'buffer' method. But SDK v340+
        # doesn't correct Boost-generated vertices (back to counterclockwise).
        # Option #2 ensures counterclockwise sequences, although the first
        # vertex in the array is no longer in sync with the original OpenStudio
        # vertices. Not consequential for fitting and overlapping detection, or
        # net/gross/rough areas tallies. Otherwise, both options generate the
        # same vertices.
        #
        # For triangular subsurfaces, Options #2 & #3 may generate additional
        # vertices near acute angles, e.g. 6 (3 of which would be ~colinear).
        # Calculated areas, as well as fitting & overlapping detection, still
        # work. Yet inaccuracies do creep in with respect to Option #1. To
        # maintain consistency in TBD calculations when switching SDK versions,
        # TBD's use of OSut's offset method is as follows (see 'properties' in
        # geo.rb):
        #
        #    offset(s.vertices, width, 300)
        #
        # There may be slight differences in reported SDK results vs TBD UA
        # reports (e.g. WWR, net areas) with acute triangular windows ... which
        # is fine.
        surface = TBD.properties(w0, argh)
        expect(surface).to_not be_nil
        expect(surface).to be_a(Hash)
        expect(surface).to have_key(:gross)
        expect(surface).to have_key(:net)
        expect(surface).to have_key(:windows)
        expect(surface[:gross]).to be_a(Numeric)
        expect(surface[:gross]).to be_within(0.1).of(100)
        expect(surface[:windows]).to be_a(Hash)
        expect(surface[:windows]).to have_key("w1")
        expect(surface[:windows]).to have_key("w2")
        expect(surface[:windows]).to have_key("w3")
        expect(surface[:windows]["w1"]).to be_a(Hash)
        expect(surface[:windows]["w2"]).to be_a(Hash)
        expect(surface[:windows]["w3"]).to be_a(Hash)
        expect(surface[:windows]["w1"]).to have_key(:gross)
        expect(surface[:windows]["w2"]).to have_key(:gross)
        expect(surface[:windows]["w3"]).to have_key(:gross)
        expect(surface[:windows]["w1"]).to have_key(:points)
        expect(surface[:windows]["w2"]).to have_key(:points)
        expect(surface[:windows]["w3"]).to have_key(:points)
        expect(surface[:windows]["w1"][:points].size).to eq(3)
        expect(surface[:windows]["w2"][:points].size).to eq(4)
        expect(surface[:windows]["w3"][:points].size).to eq(3)

        if j.zero?
          expect(surface[:windows]["w1"][:gross]).to be_within(TOL).of(1.50)
          expect(surface[:windows]["w2"][:gross]).to be_within(TOL).of(6.00)
          expect(surface[:windows]["w3"][:gross]).to be_within(TOL).of(0.32)
        else
          expect(surface[:windows]["w1"][:gross]).to be_within(TOL).of(3.75)
          expect(surface[:windows]["w2"][:gross]).to be_within(TOL).of(8.64)
          expect(surface[:windows]["w3"][:gross]).to be_within(TOL).of(1.10)
        end
      end
    end

    # Neither warning nor error == no conflicts between windows (with new
    # new vertices offset by 200mm) and with the base wall.
    expect(TBD.status).to be_zero
  end

  it "can flag errors and integrate TBD logs in JSON output" do
    translator = OpenStudio::OSVersion::VersionTranslator.new
    TBD.clean!

    file  = File.join(__dir__, "files/osms/in/warehouse.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    office = model.getSpaceByName("Zone1 Office")
    expect(office).to_not be_empty

    front_office_wall = model.getSurfaceByName("Office Front Wall")
    expect(front_office_wall).to_not be_empty
    front_office_wall = front_office_wall.get
    expect(front_office_wall.nameString).to eq("Office Front Wall")
    expect(front_office_wall.surfaceType).to eq("Wall")

    left_office_wall = model.getSurfaceByName("Office Left Wall")
    expect(left_office_wall).to_not be_empty
    left_office_wall = left_office_wall.get
    expect(left_office_wall.nameString).to eq("Office Left Wall")
    expect(left_office_wall.surfaceType).to eq("Wall")

    right_fine_wall = model.getSurfaceByName("Fine Storage Right Wall")
    expect(right_fine_wall).to_not be_empty
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
    clerestory = OpenStudio::Model::SubSurface.new(os_v, model)
    clerestory.setName("clerestory")
    expect(clerestory.setSurface(front_office_wall)).to be true
    expect(clerestory.setSubSurfaceType("FixedWindow")).to be true
    # ... reminder: set subsurface type AFTER setting its parent surface.

    # A new, highly-conductive material.
    material = OpenStudio::Model::MasslessOpaqueMaterial.new(model)
    material.setName("poor material")
    expect(material.nameString).to eq("poor material")
    expect(material.setThermalResistance(RMIN)).to be true
    mat = OpenStudio::Model::MaterialVector.new
    mat << material

    # A 'standard' variant (RMIN)
    material2 = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    material2.setName("poor material2")
    expect(material2.nameString).to eq("poor material2")
    expect(material2.setThermalConductivity(KMAX)).to be true
    expect(material2.setThickness(DMIN)).to be true
    mat2 = OpenStudio::Model::MaterialVector.new
    mat2 << material2

    # Another 'massless' material, whose name already includes " tbd".
    material3 = OpenStudio::Model::MasslessOpaqueMaterial.new(model)
    material3.setName("poor material m tbd")
    expect(material3.nameString).to eq("poor material m tbd")
    expect(material3.setThermalResistance(1.0)).to be true
    expect(material3.thermalResistance).to be_within(0.1).of(1.0)
    mat3 = OpenStudio::Model::MaterialVector.new
    mat3 << material3

    # Assign highly-conductive material to a new construction.
    construction = OpenStudio::Model::Construction.new(model)
    construction.setName("poor construction")
    expect(construction.nameString).to eq("poor construction")
    expect(construction.layers).to be_empty
    expect(construction.setLayers(mat2)).to be true # or switch with 'mat'
    expect(construction.layers.size).to eq(1)

    # Assign " tbd" massless material to a new construction.
    construction2 = OpenStudio::Model::Construction.new(model)
    construction2.setName("poor construction tbd")
    expect(construction2.nameString).to eq("poor construction tbd")
    expect(construction2.layers).to be_empty
    expect(construction2.setLayers(mat3)).to be true
    expect(construction2.layers.size).to eq(1)

    # Assign construction to the "Office Left Wall".
    expect(left_office_wall.setConstruction(construction)).to be true

    # Assign construction2 to the "Fine Storage Right Wall".
    expect(right_fine_wall.setConstruction(construction2)).to be true

    subs = front_office_wall.subSurfaces
    expect(subs).to_not be_empty
    expect(subs.size).to eq(4)

    argh               = {}
    argh[:option     ] = "poor (BETBG)"
    argh[:io_path    ] = File.join(__dir__, "../json/tbd_warehouse9.json")
    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")
    # {
    #   "schema": "https://github.com/rd2/tbd/blob/master/tbd.schema.json",
    #   "description": "testing error detection",
    #   "psis": [
    #     {
    #       "id": "detailed 2",
    #       "fen": 0.600
    #     },
    #     {
    #       "id": "regular (BETBG)",   <<<< ERROR #1 - can't reset built-in sets
    #       "fen": 0.700
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
    #       "type": "fen",
    #       "surfaces": [
    #         "Office Front Wall",
    #         "Office Front Wall Window 1"
    #       ]
    #     }
    #   ]
    # }

    json     = TBD.process(model, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.error?).to be true
    expect(TBD.logs.size).to eq(6)
    expect(io).to be_a(Hash)
    expect(surfaces).to be_a(Hash)
    expect(surfaces.size).to eq(23)
    expect(io).to be_a(Hash)
    expect(io).to have_key(:edges)
    expect(io[:edges].size).to eq(300)

    expect(surfaces).to have_key("Office Front Wall")
    expect(surfaces).to have_key("Office Left Wall")
    expect(surfaces).to have_key("Fine Storage Right Wall")

    expect(surfaces["Office Front Wall"]).to have_key(:edges)
    expect(surfaces["Office Left Wall"]).to have_key(:edges)
    expect(surfaces["Fine Storage Right Wall"]).to have_key(:edges)

    # TBD.logs.each { |log| puts log[:message] }
    # Skipping 'clerestory': vertex # 3 or 4 (TBD::properties)
    # 'regular (BETBG)': existing PSI set (TBD::append)
    # JSON/KHI surface 'Office Front Wall' 'beam' (TBD::inputs)
    # Missing edge PSI detailed (TBD::inputs)
    # Won't derate 'poor construction tbd 1': tagged as derated (TBD::derate)
    # Won't assign 197.714 W/K to 'Office Left Wall': too conductive (TBD::derate)

    # Despite input file (non-fatal) errors, TBD successfully processes thermal
    # bridges and derates OSM construction materials by falling back on defaults
    # in the case of errors.

    # For the 5-sided window, TBD will simply ignore all edges/bridges linked to
    # the 'clerestory' subsurface.
    io[:edges].each do |edge|
      expect(edge).to have_key(:surfaces)

      edge[:surfaces].each { |s| expect(s).to_not eq("clerestory") }
    end

    expect(surfaces["Office Front Wall"][:edges].size).to eq(17)
    sills = 0

    surfaces["Office Front Wall"][:edges].values.each do |e|
      expect(e).to have_key(:type)
      sills += 1 if e[:type] == :sill
    end

    expect(sills).to eq(2) # not 3

    # Fallback to ERROR # 1: not really a fallback, more a demonstration that
    # "regular (BETBG)" isn't referred to by any edge-linked derated surfaces.
    # ... & fallback to ERROR # 3: no edge relying on 'detailed' PSI set.
    io[:edges].each { |edge| expect(edge[:psi]).to eq("poor (BETBG)") }

    # Fallback to ERROR # 2: no KHI for "Office Front Wall".
    expect(io).to have_key(:khis)
    expect(io[:khis].size).to eq(1)
    expect(surfaces["Office Front Wall"]).to_not have_key(:khis)

    # ... concerning the "Office Left Wall" (underatable material).
    left_office_wall = model.getSurfaceByName("Office Left Wall")
    expect(left_office_wall).to_not be_empty
    left_office_wall = left_office_wall.get

    c = left_office_wall.construction.get.to_LayeredConstruction.get
    expect(c.numLayers).to eq(1)
    layer = c.getLayer(0).to_StandardOpaqueMaterial
    expect(layer).to_not be_empty
    layer = layer.get
    expect(layer.name.get).to eq("Office Left Wall m tbd")
    expect(layer.thermalConductivity).to be_within(0.1).of(KMAX)
    expect(layer.thickness).to be_within(0.001).of(DMIN)

    # Regardless of the targetted material type ('standard' vs 'massless'), TBD
    # will ensure a minimal RSi value (see OSut RMIN), i.e. no derating despite
    # the surface having thermal bridges.
    expect(surfaces["Office Left Wall"]).to have_key(:heatloss)
    expect(surfaces["Office Left Wall"]).to have_key(:r_heatloss)

    expect(surfaces["Office Left Wall"][:heatloss  ]).to be_within(0.1).of(197.7)
    expect(surfaces["Office Left Wall"][:r_heatloss]).to be_within(0.1).of(197.7)

    expect(surfaces["Fine Storage Right Wall"]).to     have_key(:heatloss)
    expect(surfaces["Fine Storage Right Wall"]).to_not have_key(:r_heatloss)

    # Concerning the new material (with a name already including " tbd"):
    # TBD ignores all such materials (a safeguard against iterative TBD
    # runs). Contrary to the previous critical cases of highly conductive
    # materials, TBD doesn't even try to set the :r_heatloss hash value - tough!
    right_fine_wall = model.getSurfaceByName("Fine Storage Right Wall")
    expect(right_fine_wall).to_not be_empty
    right_fine_wall = right_fine_wall.get

    c     = right_fine_wall.construction.get.to_LayeredConstruction.get
    layer = c.getLayer(0).to_MasslessOpaqueMaterial
    expect(layer).to_not be_empty
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
    tbd_msgs          = []

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
    translator = OpenStudio::OSVersion::VersionTranslator.new
    TBD.clean!

    file  = File.join(__dir__, "files/osms/in/5Zone_2.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get
    plnum = model.getSpaceByName("PLENUM-1")
    expect(plnum).to_not be_empty
    plnum = plnum.get

    model.getSpaces.each do |space|
      stpts = TBD.setpoints(space)
      expect(stpts).to have_key(:heating)
      expect(stpts).to have_key(:cooling)
      expect(TBD.plenum?(space)).to be false

      if space == plnum
        expect(stpts[:heating]).to be_nil
        expect(stpts[:cooling]).to be_nil
      else
        expect(stpts[:heating]).to be_within(0.1).of(22.2)
        expect(stpts[:cooling]).to be_within(0.1).of(23.9)
      end
    end

    # PLENUM floors.
    flr_ids = ["C1-1P", "C2-1P", "C3-1P", "C4-1P", "C5-1P"]

    floors = model.getSurfaces.select { |s| flr_ids.include?(s.nameString) }

    floors.each do |fl|
      expect(flr_ids).to include(fl.nameString)
      space = fl.space
      expect(space).to_not be_empty
      expect(space.get).to eq(plnum)

      c = fl.construction
      expect(c).to_not be_empty
      c = c.get.to_LayeredConstruction
      expect(c).to_not be_empty
      c = c.get
      expect(c.nameString).to eq("CLNG-1")
      expect(c.layers.size).to eq(1)
      expect(c.layers[0].nameString).to eq("MAT-CLNG-1") # RSi 0.650
    end

    # Tracking outdoor-facing office walls.
    walls = []

    model.getSurfaces.each do |s|
      next unless s.surfaceType.downcase == "wall"

      walls << s if s.outsideBoundaryCondition.downcase == "outdoors"
    end

    expect(walls.size).to eq(8)

    walls.each do |s|
      expect(s.isConstructionDefaulted).to be false
      c = s.construction
      expect(c).to_not be_empty
      c = c.get.to_LayeredConstruction
      expect(c).to_not be_empty
      c = c.get

      expect(c.nameString).to eq("WALL-1")
      expect(c.layers.size).to eq(4)
      expect(c.layers[0].nameString).to eq("WD01") # RSi 0.165
      expect(c.layers[1].nameString).to eq("PW03") # RSI 0.110
      expect(c.layers[2].nameString).to eq("IN02") # RSi 2.090
      expect(c.layers[3].nameString).to eq("GP01") # RSi 0.079
    end

    argh = { option: "poor (BETBG)" }

    json     = TBD.process(model, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty
    expect(surfaces).to be_a(Hash)
    expect(surfaces.size).to eq(40)
    expect(io).to be_a(Hash)
    expect(io).to have_key(:edges)
    expect(io[:edges].size).to eq(47)

    doors   = []
    derated = []

    ids = { a: "LEFT-1",
            b: "RIGHT-1",
            c: "FRONT-1",
            d: "BACK-1",
            e: "C1-1", # ceiling below plenum/attic
            f: "C2-1", # "
            g: "C3-1", # "
            h: "C4-1", # "
            i: "C5-1"  # "
          }.freeze

    surfaces.each do |id, surface|
      expect(surface).to have_key(:type)
      expect(surface).to have_key(:conditioned)
      next unless surface[:conditioned]
      next unless surface.key?(:edges)

      doors += surface[:doors].values if surface.key?(:doors)

      derated << id
      expect(ids).to have_value(id)
    end

    expect(derated.size).to eq(ids.size)
    expect(doors.size).to eq(2)

    # Side-testing glass door detection.
    doors.each do |door|
      expect(door).to have_key(:u)
      expect(door).to have_key(:glazed)
      expect(door[:glazed]).to be true
      expect(door[:u]).to be_a(Numeric)
      expect(door[:u]).to be_within(TOL).of(6.54)
    end

    # Testing plenum/attic surfaces.
    plnum_floors   = []
    derated_floors = []

    surfaces.each do |id, surface|
      expect(surface).to have_key(:space)
      next unless surface[:space] == plnum
      next unless surface[:type ] == :floor

      expect(derated).to_not include(id)
      expect(flr_ids).to include(id)
      plnum_floors << id
      next unless surface.key?(:heatloss)

      derated_floors << id if surface.key?(:heatloss)
    end

    # None are derated, i.e. plenum more akin to an UNCONDITIONED attic.
    expect(plnum_floors.size).to eq(5)
    expect(derated_floors).to be_empty

    # Plenum floors are not derated, yet the adjacent ceiling below should be.
    derated_ceilings = []

    plnum_floors.each do |id|
      expect(surfaces[id]).to have_key(:boundary)
      b = surfaces[id][:boundary]

      expect(surfaces).to have_key(b)
      expect(surfaces[b]).to have_key(:heatloss)
      expect(surfaces[b]).to have_key(:conditioned)
      expect(surfaces[b]).to have_key(:space)
      expect(surfaces[b][:conditioned]).to be true
      expect(surfaces[b][:space]).to_not eq(plnum)

      expect(ids).to_not include(id)
      next if id == "C5-1P" # core space ceiling

      expect(surfaces[b]).to have_key(:ratio)
      h = surfaces[b][:heatloss]
      expect(h).to be_within(TOL).of(5.79) if id == "C1-1P"
      expect(h).to be_within(TOL).of(2.89) if id == "C2-1P"
      expect(h).to be_within(TOL).of(5.79) if id == "C3-1P"
      expect(h).to be_within(TOL).of(2.89) if id == "C4-1P"

      derated_ceilings << id
    end

    expect(derated_ceilings.size).to eq(4)

    surfaces.each do |id, surface|
      next unless surface.key?(:edges)

      expect(ids).to have_value(id)
      expect(surface).to have_key(:heatloss)
      next if id == ids[:i]

      expect(surface).to have_key(:ratio)
      h = surface[:heatloss]
      s = model.getSurfaceByName(id)
      expect(s).to_not be_empty
      s = s.get
      expect(s.nameString).to eq(id)
      expect(s.isConstructionDefaulted).to be false
      expect(s.construction.get.nameString).to include(" tbd")
      expect(h).to be_within(TOL).of( 0.00) if id == "C5-1"
      expect(h).to be_within(TOL).of(64.92) if id == "FRONT-1"
    end
  end

  it "can handle TDDs" do
    translator = OpenStudio::OSVersion::VersionTranslator.new
    version    = OpenStudio.openStudioVersion.split(".").join.to_i
    TBD.clean!

    methods = OpenStudio::Model::Model.instance_methods
    methods = methods.select { |m| m.to_s.downcase.include?("tubular") }
    methods.map! { |m| m.to_s.downcase }

    types = OpenStudio::Model::SubSurface.validSubSurfaceTypeValues
    expect(types).to include("TubularDaylightDome")
    expect(types).to include("TubularDaylightDiffuser")

    file  = File.join(__dir__, "files/osms/in/warehouse.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    # As of v3.3.0, OpenStudio SDK (fully) supports Tubular Daylighting Devices:
    #
    #   https://bigladdersoftware.com/epx/docs/9-6/input-output-reference/
    #   group-daylighting.html#daylightingdevicetubular
    #
    #   https://openstudio-sdk-documentation.s3.amazonaws.com/cpp/
    #   OpenStudio-3.3.0-doc/model/html/
    #   classopenstudio_1_1model_1_1_daylighting_device_tubular.html
    #
    # For SDK versions >= v3.3.0, testing new TDD methods.
    unless version < 330
      expect(methods).to_not be_empty
      valid = methods.any? { |method| method.include?("tubular") }
      expect(valid).to be true

      # Simple Glazing constructions for both dome & diffuser.
      fen = OpenStudio::Model::Construction.new(model)
      fen.setName("tubular_fen")

      glazing = OpenStudio::Model::SimpleGlazing.new(model)
      glazing.setName("tubular_glazing")
      expect(glazing.setUFactor(                 6.00)).to be true
      expect(glazing.setSolarHeatGainCoefficient(0.50)).to be true
      expect(glazing.setVisibleTransmittance(    0.70)).to be true

      layers = OpenStudio::Model::MaterialVector.new
      layers << glazing
      expect(fen.setLayers(layers)).to be true

      # Tube walls.
      construction = OpenStudio::Model::Construction.new(model)
      construction.setName("tube_construction")

      interior = OpenStudio::Model::StandardOpaqueMaterial.new(model)
      interior.setName("tube_wall")
      expect(interior.setRoughness(  "MediumRough")).to be true
      expect(interior.setThickness(         0.0126)).to be true
      expect(interior.setConductivity(      0.1600)).to be true
      expect(interior.setDensity(         784.9000)).to be true
      expect(interior.setSpecificHeat(    830.0000)).to be true
      expect(interior.setThermalAbsorptance(0.9000)).to be true
      expect(interior.setSolarAbsorptance(  0.9000)).to be true
      expect(interior.setVisibleAbsorptance(0.9000)).to be true

      layers = OpenStudio::Model::MaterialVector.new
      layers << interior
      expect(construction.setLayers(layers)).to be true

      # Host spaces & surfaces.
      sp1 = "Zone1 Office"
      sp2 = "Zone2 Fine Storage"
      z   = "Zone2 Fine Storage ZN"
      s1  = "Office Roof"          #  Office surface hosting new TDD diffuser
      s2  = "Office Roof Reversed" #          FineStorage floor, above office
      s3  = "Fine Storage Roof"    # FineStorage surface hosting new TDD dome

      # Fetch host spaces & surfaces.
      office = model.getSpaceByName(sp1)
      expect(office).to_not be_empty
      office = office.get

      storage = model.getSpaceByName(sp2)
      expect(storage).to_not be_empty
      storage = storage.get

      zone = storage.thermalZone
      expect(zone).to_not be_empty
      zone = zone.get
      expect(zone.nameString).to eq(z)

      ceiling = model.getSurfaceByName(s1)
      expect(ceiling).to_not be_empty
      ceiling = ceiling.get

      sp = ceiling.space
      expect(sp).to_not be_empty
      sp = sp.get
      expect(sp).to eq(office)

      floor = model.getSurfaceByName(s2)
      expect(floor).to_not be_empty
      floor = floor.get

      sp = floor.space
      expect(sp).to_not be_empty
      sp = sp.get
      expect(sp).to eq(storage)

      adj = ceiling.adjacentSurface
      expect(adj).to_not be_empty
      adj = adj.get
      expect(adj).to eq(floor)

      adj = floor.adjacentSurface
      expect(adj).to_not be_empty
      adj = adj.get
      expect(adj).to eq(ceiling)

      roof = model.getSurfaceByName(s3)
      expect(roof).to_not be_empty
      roof = roof.get

      sp = roof.space
      expect(sp).to_not be_empty
      sp = sp.get
      expect(sp).to eq(storage)

      # Setting heights & Z-axis coordinates.
      ceiling_Z   = ceiling.centroid.z
      roof_Z      = roof.centroid.z
      length      = roof_Z - ceiling_Z
      totalLength = length + 0.7
      dome_Z      = ceiling_Z + totalLength

      # A new, 1mx1m diffuser subsurface in Office.
      os_v = OpenStudio::Point3dVector.new
      os_v << OpenStudio::Point3d.new( 11.0, 4.0, ceiling_Z)
      os_v << OpenStudio::Point3d.new( 11.0, 5.0, ceiling_Z)
      os_v << OpenStudio::Point3d.new( 10.0, 5.0, ceiling_Z)
      os_v << OpenStudio::Point3d.new( 10.0, 4.0, ceiling_Z)

      diffuser = OpenStudio::Model::SubSurface.new(os_v, model)
      diffuser.setName("diffuser")
      expect(diffuser.setConstruction(fen)).to be true
      expect(diffuser.setSubSurfaceType("TubularDaylightDiffuser")).to be true
      expect(diffuser.setSurface(ceiling)).to be true
      expect(diffuser.uFactor).to_not be_empty
      expect(diffuser.uFactor.get).to be_within(0.1).of(6.0)

      # A new, 1mx1m dome subsurface above Fine Storage roof.
      os_v = OpenStudio::Point3dVector.new
      os_v << OpenStudio::Point3d.new( 11.0, 4.0, dome_Z)
      os_v << OpenStudio::Point3d.new( 11.0, 5.0, dome_Z)
      os_v << OpenStudio::Point3d.new( 10.0, 5.0, dome_Z)
      os_v << OpenStudio::Point3d.new( 10.0, 4.0, dome_Z)

      dome = OpenStudio::Model::SubSurface.new(os_v, model)
      dome.setName("dome")
      expect(dome.setConstruction(fen)).to be true
      expect(dome.setSubSurfaceType("TubularDaylightDome")).to be true
      expect(dome.setSurface(roof)).to be true
      expect(dome.uFactor).to_not be_empty
      expect(dome.uFactor.get).to be_within(0.1).of(6.0)

      expect(ceiling.tilt).to be_within(TOL).of(diffuser.tilt)
      expect(dome.tilt   ).to be_within(TOL).of(    roof.tilt)

      rsi      = 0.28 # default effective TDD RSi (dome to diffuser)
      diameter = Math.sqrt(dome.grossArea/Math::PI) * 2

      tdd = OpenStudio::Model::DaylightingDeviceTubular.new(
              dome, diffuser, construction)

      expect(tdd.setDiameter(diameter)).to be true
      expect(tdd.setTotalLength(totalLength)).to be true
      expect(tdd.addTransitionZone(zone, length)).to be true
      cl = OpenStudio::Model::TransitionZoneVector
      expect(tdd.transitionZones.class  ).to eq(cl)
      expect(tdd.numberofTransitionZones).to eq(1)

      expect(tdd.subSurfaceDome).to eq(dome)
      expect(tdd.subSurfaceDiffuser).to eq(diffuser)

      c = tdd.construction
      expect(c.to_LayeredConstruction).to_not be_empty
      c = c.to_LayeredConstruction.get

      expect(c.nameString).to eq(construction.nameString)
      expect(tdd.diameter).to be_within(TOL).of(diameter)
      expect(tdd.effectiveThermalResistance).to be_within(TOL).of(rsi)

      pth = File.join(__dir__, "files/osms/out/tdd_warehouse.osm")
      model.save(pth, true)

      # Testing if TBD recognizes the TDD as a "skylight" (for derating & UA').
      argh = { option: "poor (BETBG)" }

      json     = TBD.process(model, argh)
      expect(json).to be_a(Hash)
      expect(json).to have_key(:io)
      expect(json).to have_key(:surfaces)
      io       = json[:io      ]
      surfaces = json[:surfaces]
      expect(TBD.status.zero?).to be(true)
      expect(TBD.logs).to be_empty
      expect(surfaces).to be_a(Hash)
      expect(surfaces.size).to eq(23)
      expect(io).to be_a(Hash)
      expect(io).to have_key(:edges)
      expect(io[:edges].size).to eq(304)

      # Both diffuser and parent (office) ceiling are stored as TBD 'surfaces'.
      expect(surfaces).to have_key(s1)
      surface = surfaces[s1]
      expect(surface).to have_key(:skylights)
      expect(surface[:skylights].size).to eq(1)
      expect(surface[:skylights]).to have_key("diffuser")

      skylight = surface[:skylights]["diffuser"]
      expect(skylight).to be_a(Hash)
      expect(skylight).to have_key(:u)
      expect(skylight[:u]).to be_a(Numeric)
      expect(skylight[:u]).to be_within(TOL).of(1/rsi)
      # ... yet TBD only derates constructions of opaque surfaces in CONDITIONED
      # spaces if:
      #
      #   (i) facing outdoors or
      #   (ii) facing UNCONDITIONED spaces like attics (see psi.rb).
      #
      # Here, the ceiling is not tagged by TBD as a deratable surface.
      # Diffuser edges are therefore not logged in TBD's 'edges'.
      expect(surface).to_not have_key(:heatloss)
      expect(surface).to_not have_key(:ratio)

      # Only edges of the dome (linked to the Fine Storage roof) are stored.
      io[:edges].each do |edge|
        expect(edge).to be_a(Hash)
        expect(edge).to have_key(:surfaces)
        expect(edge[:surfaces]).to be_a(Array)

        edge[:surfaces].each do |id|
          expect(id).to eq("dome") if ["dome", "diffuser"].include?(id)
        end
      end

      expect(surfaces).to have_key(s3)
      surface = surfaces[s3]

      expect(surface).to have_key(:skylights)
      expect(surface[:skylights].size).to eq(15) # original 14x +1
      expect(surface[:skylights]).to have_key("dome")

      surface[:skylights].each do |i, skylight|
        expect(skylight).to have_key(:u)
        expect(skylight[:u]).to be_a(Numeric)
        expect(skylight[:u]).to be_within(TOL).of(6.64) unless i == "dome"
        expect(skylight[:u]).to be_within(TOL).of(1/rsi)    if i == "dome"
      end

      expect(surface).to have_key(:heatloss)
      expect(surface[:heatloss]).to be_within(TOL).of(89.16) # +2.0 W/K
      expect(io[:edges].size).to eq(304) # 4x extra edges for dome only

      out  = JSON.pretty_generate(io)
      outP = File.join(__dir__, "../json/tbd_warehouse15.out.json")
      File.open(outP, "w") { |outP| outP.puts out }

      # Re-use the exported file as input for another warehouse.
      model2 = translator.loadModel(pth)
      expect(model2).to_not be_empty
      model2 = model2.get

      argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")
      argh[:io_path    ] = File.join(__dir__, "../json/tbd_warehouse15.out.json")

      json2    = TBD.process(model2, argh)
      expect(json2).to be_a(Hash)
      expect(json2).to have_key(:io)
      expect(json2).to have_key(:surfaces)
      io2      = json2[:io      ]
      surfaces = json2[:surfaces]
      expect(TBD.status).to be_zero
      expect(TBD.logs).to be_empty
      expect(surfaces).to be_a(Hash)
      expect(surfaces.size).to eq(23)
      expect(io).to be_a(Hash)
      expect(io).to have_key(:edges)
      expect(io[:edges].size).to eq(304)

      # Now mimic (again) the export functionality of the measure. Both output
      # files should be the same.
      out2 = JSON.pretty_generate(io2)
      outP2 = File.join(__dir__, "../json/tbd_warehouse16.out.json")
      File.open(outP2, "w") { |outP2| outP2.puts out2 }
      expect(FileUtils).to be_identical(outP, outP2)
    else
      expect(methods).to be_empty

      # SDK pre-v3.3.0 testing on one of the existing skylights, as a tubular
      # TDD dome (without a complete TDD object).
      nom  = "FineStorage_skylight_5"
      sky5 = model.getSubSurfaceByName(nom)
      expect(sky5).to_not be_empty
      sky5 = sky5.get
      expect(sky5.subSurfaceType.downcase).to eq("skylight")
      name = "U 1.17 SHGC 0.39 Simple Glazing Skylight U-1.17 SHGC 0.39 2"

      skylight = sky5.construction
      expect(skylight).to_not be_empty
      expect(skylight.get.nameString).to eq(name)

      expect(sky5.setSubSurfaceType("TubularDaylightDome")).to be true
      skylight = sky5.construction
      expect(skylight).to_not be_empty
      expect(skylight.get.nameString).to eq("Typical Interior Window")
      # Weird to see "Typical Interior Window" as a suitable construction for a
      # tubular skylight dome, but that's the assigned default construction in
      # the DOE prototype warehouse model.

      roof = model.getSurfaceByName("Fine Storage Roof")
      expect(roof).to_not be_empty
      roof = roof.get

      # Testing if TBD recognizes it as a "skylight" (for derating & UA').
      argh = { option: "poor (BETBG)" }

      json     = TBD.process(model, argh)
      expect(json).to be_a(Hash)
      expect(json).to have_key(:io)
      expect(json).to have_key(:surfaces)
      io       = json[:io      ]
      surfaces = json[:surfaces]
      expect(TBD.status).to be_zero
      expect(TBD.logs).to be_empty
      expect(surfaces).to be_a(Hash)
      expect(surfaces.size).to eq(23)
      expect(io).to be_a(Hash)
      expect(io).to have_key(:edges)
      expect(io[:edges].size).to eq(300)

      expect(surfaces).to have_key("Fine Storage Roof")
      surface = surfaces["Fine Storage Roof"]

      if surface.key?(:skylights)
        expect(surface[:skylights]).to have_key(nom)

        surface[:skylights].each do |i, skylight|
          expect(skylight).to have_key(:u)
          expect(skylight[:u]).to be_a(Numeric)
          expect(skylight[:u]).to be_within(TOL).of(6.64) unless i == nom
          expect(skylight[:u]).to be_within(TOL).of(7.18)     if i == nom
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
    translator = OpenStudio::OSVersion::VersionTranslator.new
    version    = OpenStudio.openStudioVersion.split(".").join.to_i
    TBD.clean!

    file  = File.join(__dir__, "files/osms/in/5Zone_2.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    # For SDK versions >= v3.3.0, testing new DaylightingTubularDevice methods.
    unless version < 330
      # Both dome & diffuser: Simple Glazing constructions.
      fen = OpenStudio::Model::Construction.new(model)
      fen.setName("tubular_fen")
      expect(fen.nameString).to eq("tubular_fen")
      expect(fen.layers).to be_empty

      glazing = OpenStudio::Model::SimpleGlazing.new(model)
      glazing.setName("tubular_glazing")
      expect(glazing.nameString).to eq("tubular_glazing")
      expect(glazing.setUFactor(6.0)).to be true
      expect(glazing.setSolarHeatGainCoefficient(0.50)).to be true
      expect(glazing.setVisibleTransmittance(0.70)).to be true

      layers = OpenStudio::Model::MaterialVector.new
      layers << glazing
      expect(fen.setLayers(layers)).to be true
      expect(fen.layers.size).to eq(1)
      expect(fen.layers[0].handle.to_s).to eq(glazing.handle.to_s)
      expect(fen.uFactor).to_not be_empty
      expect(fen.uFactor.get).to be_within(0.1).of(6.0)

      # Tube walls.
      construction = OpenStudio::Model::Construction.new(model)
      construction.setName("tube_construction")
      expect(construction.nameString).to eq("tube_construction")
      expect(construction.layers).to be_empty

      interior = OpenStudio::Model::StandardOpaqueMaterial.new(model)
      interior.setName("tube_wall")
      expect(interior.nameString).to eq("tube_wall")
      expect(interior.setRoughness("MediumRough")).to be true
      expect(interior.setThickness(0.0126)).to be true
      expect(interior.setConductivity(0.16)).to be true
      expect(interior.setDensity(784.9)).to be true
      expect(interior.setSpecificHeat(830)).to be true
      expect(interior.setThermalAbsorptance(0.9)).to be true
      expect(interior.setSolarAbsorptance(0.9)).to be true
      expect(interior.setVisibleAbsorptance(0.9)).to be true

      layers = OpenStudio::Model::MaterialVector.new
      layers << interior
      expect(construction.setLayers(layers)).to be true
      expect(construction.layers.size).to eq(1)
      expect(construction.layers[0].handle.to_s).to eq(interior.handle.to_s)

      # Host spaces & surfaces.
      sp1 = "SPACE5-1"
      sp2 = "PLENUM-1"
      z   = "PLENUM-1 Thermal Zone"
      s1  = "C5-1"  # sp1 surface hosting new TDD diffuser
      s2  = "C5-1P" # plenum surface, above sp1
      s3  = "TOP-1" # plenum surface hosting new TDD dome

      # Fetch host spaces & surfaces.
      space = model.getSpaceByName(sp1)
      expect(space).to_not be_empty
      space = space.get

      plenum = model.getSpaceByName(sp2)
      expect(plenum).to_not be_empty
      plenum = plenum.get

      zone = plenum.thermalZone
      expect(zone).to_not be_empty
      zone = zone.get
      expect(zone.nameString).to eq(z)

      ceiling = model.getSurfaceByName(s1)
      expect(ceiling).to_not be_empty
      ceiling = ceiling.get
      sp = ceiling.space
      expect(sp).to_not be_empty
      sp = sp.get
      expect(sp).to eq(space)

      floor = model.getSurfaceByName(s2)
      expect(floor).to_not be_empty
      floor = floor.get
      sp = floor.space
      expect(sp).to_not be_empty
      sp = sp.get
      expect(sp).to eq(plenum)

      adj = ceiling.adjacentSurface
      expect(adj).to_not be_empty
      adj = adj.get
      expect(adj).to eq(floor)

      adj = floor.adjacentSurface
      expect(adj).to_not be_empty
      adj = adj.get
      expect(adj).to eq(ceiling)

      roof = model.getSurfaceByName(s3)
      expect(roof).to_not be_empty
      roof = roof.get
      sp = roof.space
      expect(sp).to_not be_empty
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
      diffuser = OpenStudio::Model::SubSurface.new(os_v, model)
      diffuser.setName("diffuser")
      expect(diffuser.setConstruction(fen)).to be true
      expect(diffuser.setSubSurfaceType("TubularDaylightDiffuser")).to be true
      expect(diffuser.setSurface(ceiling)).to be true
      expect(diffuser.uFactor).to_not be_empty
      expect(diffuser.uFactor.get).to be_within(0.1).of(6.0)

      # A new, 1mx1m dome subsurface above Plenum roof.
      os_v = OpenStudio::Point3dVector.new
      os_v << OpenStudio::Point3d.new( 15.75,  7.15, dome_Z)
      os_v << OpenStudio::Point3d.new( 15.75,  8.15, dome_Z)
      os_v << OpenStudio::Point3d.new( 14.75,  8.15, dome_Z)
      os_v << OpenStudio::Point3d.new( 14.75,  7.15, dome_Z)
      dome = OpenStudio::Model::SubSurface.new(os_v, model)
      dome.setName("dome")
      expect(dome.setConstruction(fen)).to be true
      expect(dome.setSubSurfaceType("TubularDaylightDome")).to be true
      expect(dome.setSurface(roof)).to be true
      expect(dome.uFactor).to_not be_empty
      expect(dome.uFactor.get).to be_within(0.1).of(6.0)

      expect(ceiling.tilt).to be_within(TOL).of(diffuser.tilt)
      expect(dome.tilt).to be_within(TOL).of(roof.tilt)

      rsi = 0.28
      diameter = Math.sqrt(dome.grossArea/Math::PI) * 2

      tdd = OpenStudio::Model::DaylightingDeviceTubular.new(
              dome, diffuser, construction, diameter, totalLength, rsi)

      expect(tdd.addTransitionZone(zone, length)).to be true
      cl = OpenStudio::Model::TransitionZoneVector
      expect(tdd.transitionZones.class).to eq(cl)
      expect(tdd.numberofTransitionZones).to eq(1)
      expect(tdd.totalLength).to be_within(0.001).of(totalLength)

      expect(tdd.subSurfaceDome).to eq(dome)
      expect(tdd.subSurfaceDiffuser).to eq(diffuser)
      c = tdd.construction
      expect(c.to_LayeredConstruction).to_not be_empty
      c = c.to_LayeredConstruction.get
      expect(c.nameString).to eq(construction.nameString)
      expect(tdd.diameter).to be_within(0.001).of(diameter)
      expect(tdd.effectiveThermalResistance).to be_within(TOL).of(rsi)

      pth = File.join(__dir__, "files/osms/out/tdd_5Z_test.osm")
      model.save(pth, true)

      # Testing if TBD recognizes the TDD as a "skylight" (for derating & UA').
      argh = { option: "poor (BETBG)" }

      json     = TBD.process(model, argh)
      expect(json).to be_a(Hash)
      expect(json).to have_key(:io)
      expect(json).to have_key(:surfaces)
      io       = json[:io      ]
      surfaces = json[:surfaces]
      expect(TBD.status).to be_zero
      expect(TBD.logs).to be_empty
      expect(surfaces).to be_a(Hash)
      expect(surfaces.size).to eq(40)
      expect(io).to be_a(Hash)
      expect(io).to have_key(:edges)
      expect(io[:edges].size).to eq(51) # 4x extra edges for diffuser - not dome

      # Both diffuser and parent ceiling are stored as TBD 'surfaces'.
      expect(surfaces).to have_key(s1)
      surface = surfaces[s1]
      expect(surface).to have_key(:skylights)
      expect(surface[:skylights].size).to eq(1)
      expect(surface[:skylights]).to have_key("diffuser")
      skylight = surface[:skylights]["diffuser"]
      expect(skylight).to have_key(:u)
      expect(skylight[:u]).to be_a(Numeric)
      expect(skylight[:u]).to be_within(TOL).of(1/rsi)

      # ... yet TBD only derates constructions of opaque surfaces in CONDITIONED
      # spaces IF (i) facing outdoors or (ii) facing UNCONDITIONED spaces like
      # attics (see psi.rb). Here, the ceiling is tagged by TBD as a deratable
      # surface, and hence the diffuser edges are logged in TBD's 'edges'.
      expect(surface).to have_key(:ratio)
      expect(surface).to have_key(:heatloss)
      expect(surface[:heatloss]).to be_within(TOL).of(2.00) # 4x 0.500 W/K

      # Only edges of the diffuser (linked to the ceiling) are stored.
      io[:edges].each do |edge|
        expect(edge).to be_a(Hash)
        expect(edge).to have_key(:surfaces)
        expect(edge[:surfaces]).to be_a(Array)

        edge[:surfaces].each do |id|
          expect(id).to eq("diffuser") if ["dome", "diffuser"].include?(id)
        end
      end

      expect(surfaces).to have_key(s3)
      surface = surfaces[s3]

      expect(surface).to have_key(:skylights)
      expect(surface[:skylights]).to_not be_nil
      expect(surface[:skylights].size).to eq(1)
      expect(surface[:skylights]).to have_key("dome")
      skylight = surface[:skylights]["dome"]

      expect(skylight).to have_key(:u)
      expect(skylight[:u]).to be_a(Numeric)
      expect(skylight[:u]).to be_within(TOL).of(1/rsi)
      expect(surface).to_not have_key(:heatloss)
      expect(surface).to_not have_key(:ratio)

      out  = JSON.pretty_generate(io)
      outP = File.join(__dir__, "../json/tbd_5Z.out.json")
      File.open(outP, "w") { |outP| outP.puts out }

      # Re-use the exported file as input for another 5Z test.
      model2 = translator.loadModel(pth)
      expect(model2).to_not be_empty
      model2 = model2.get

      argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")
      argh[:io_path    ] = File.join(__dir__, "../json/tbd_5Z.out.json")

      json2    = TBD.process(model2, argh)
      expect(json2).to be_a(Hash)
      expect(json2).to have_key(:io)
      expect(json2).to have_key(:surfaces)
      io2      = json2[:io      ]
      surfaces = json2[:surfaces]
      expect(TBD.status).to be_zero
      expect(TBD.logs).to be_empty
      expect(surfaces).to be_a(Hash)
      expect(surfaces.size).to eq(40)
      expect(io2).to be_a(Hash)
      expect(io2).to have_key(:edges)
      expect(io2[:edges].size).to eq(51)

      # Now mimic (again) the export functionality of the measure. Both output
      # files should be the same.
      out2  = JSON.pretty_generate(io2)
      outP2 = File.join(__dir__, "../json/tbd_5Z_2.out.json")
      File.open(outP2, "w") { |outP2| outP2.puts out2 }
      expect(FileUtils).to be_identical(outP, outP2)
    end
  end

  it "can handle TDDs in attics" do
    translator = OpenStudio::OSVersion::VersionTranslator.new
    version    = OpenStudio.openStudioVersion.split(".").join.to_i
    TBD.clean!

    file  = File.join(__dir__, "files/osms/in/smalloffice.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    # For SDK versions >= v3.3.0, testing new DaylightingTubularDevice methods.
    unless version < 330
      # Both dome & diffuser: Simple Glazing constructions.
      fen = OpenStudio::Model::Construction.new(model)
      fen.setName("tubular_fen")
      expect(fen.nameString).to eq("tubular_fen")
      expect(fen.layers).to be_empty

      glazing = OpenStudio::Model::SimpleGlazing.new(model)
      glazing.setName("tubular_glazing")
      expect(glazing.nameString).to eq("tubular_glazing")
      expect(glazing.setUFactor(6.0)).to be true
      expect(glazing.setSolarHeatGainCoefficient(0.50)).to be true
      expect(glazing.setVisibleTransmittance(0.70)).to be true

      layers = OpenStudio::Model::MaterialVector.new
      layers << glazing
      expect(fen.setLayers(layers)).to be true
      expect(fen.layers.size).to eq(1)
      expect(fen.layers[0].handle.to_s).to eq(glazing.handle.to_s)
      expect(fen.uFactor).to_not be_empty
      expect(fen.uFactor.get).to be_within(0.1).of(6.0)

      # Tube walls.
      construction = OpenStudio::Model::Construction.new(model)
      construction.setName("tube_construction")
      expect(construction.nameString).to eq("tube_construction")
      expect(construction.layers).to be_empty

      interior = OpenStudio::Model::StandardOpaqueMaterial.new(model)
      interior.setName("tube_wall")
      expect(interior.nameString).to eq("tube_wall")
      expect(interior.setRoughness("MediumRough")).to be true
      expect(interior.setThickness(0.0126)).to be true
      expect(interior.setConductivity(0.16)).to be true
      expect(interior.setDensity(784.9)).to be true
      expect(interior.setSpecificHeat(830)).to be true
      expect(interior.setThermalAbsorptance(0.9)).to be true
      expect(interior.setSolarAbsorptance(0.9)).to be true
      expect(interior.setVisibleAbsorptance(0.9)).to be true

      layers = OpenStudio::Model::MaterialVector.new
      layers << interior
      expect(construction.setLayers(layers)).to be true
      expect(construction.layers.size).to eq(1)
      expect(construction.layers[0].handle.to_s).to eq(interior.handle.to_s)

      # Host spaces & surfaces.
      sp1 = "Core_ZN"
      sp2 = "Attic"
      z   = "Attic ZN"
      s1  = "Core_ZN_ceiling"  # sp1 surface hosting new TDD diffuser
      s2  = "Attic_floor_core" # attic surface, above sp1
      s3  = "Attic_roof_north" # attic surface hosting new TDD dome

      # Fetch host spaces & surfaces.
      core = model.getSpaceByName(sp1)
      expect(core).to_not be_empty
      core = core.get

      attic = model.getSpaceByName(sp2)
      expect(attic).to_not be_empty
      attic = attic.get

      zone = attic.thermalZone
      expect(zone).to_not be_empty
      zone = zone.get
      expect(zone.nameString).to eq(z)

      ceiling = model.getSurfaceByName(s1)
      expect(ceiling).to_not be_empty
      ceiling = ceiling.get

      sp = ceiling.space
      expect(sp).to_not be_empty
      sp = sp.get
      expect(sp).to eq(core)

      floor = model.getSurfaceByName(s2)
      expect(floor).to_not be_empty
      floor = floor.get

      sp = floor.space
      expect(sp).to_not be_empty
      sp = sp.get
      expect(sp).to eq(attic)

      adj = ceiling.adjacentSurface
      expect(adj).to_not be_empty
      adj = adj.get
      expect(adj).to eq(floor)

      adj = floor.adjacentSurface
      expect(adj).to_not be_empty
      adj = adj.get
      expect(adj).to eq(ceiling)

      roof = model.getSurfaceByName(s3)
      expect(roof).to_not be_empty
      roof = roof.get

      sp = roof.space
      expect(sp).to_not be_empty
      sp = sp.get
      expect(sp).to eq(attic)

      # Setting heights & Z-axis coordinates.
      ceiling_Z   = 3.05
      roof_Z      = 5.51
      length      = roof_Z - ceiling_Z
      totalLength = length + 1.0
      dome_Z      = ceiling_Z + totalLength

      # A new, 1mx1m diffuser subsurface in Core ceiling.
      os_v = OpenStudio::Point3dVector.new
      os_v << OpenStudio::Point3d.new( 14.345, 10.845, ceiling_Z)
      os_v << OpenStudio::Point3d.new( 14.345, 11.845, ceiling_Z)
      os_v << OpenStudio::Point3d.new( 13.345, 11.845, ceiling_Z)
      os_v << OpenStudio::Point3d.new( 13.345, 10.845, ceiling_Z)
      diffuser = OpenStudio::Model::SubSurface.new(os_v, model)
      diffuser.setName("diffuser")
      expect(diffuser.setConstruction(fen)).to be true
      expect(diffuser.setSubSurfaceType("TubularDaylightDiffuser")).to be true
      expect(diffuser.setSurface(ceiling)).to be true
      expect(diffuser.uFactor).to_not be_empty
      expect(diffuser.uFactor.get).to be_within(0.1).of(6.0)

      # A new, 1mx1m dome subsurface above Attic roof.
      os_v = OpenStudio::Point3dVector.new
      os_v << OpenStudio::Point3d.new( 14.345, 10.845, dome_Z)
      os_v << OpenStudio::Point3d.new( 14.345, 11.845, dome_Z)
      os_v << OpenStudio::Point3d.new( 13.345, 11.845, dome_Z)
      os_v << OpenStudio::Point3d.new( 13.345, 10.845, dome_Z)
      dome = OpenStudio::Model::SubSurface.new(os_v, model)
      dome.setName("dome")
      expect(dome.setConstruction(fen)).to be true
      expect(dome.setSubSurfaceType("TubularDaylightDome")).to be true
      expect(dome.setSurface(roof)).to be true
      expect(dome.uFactor).to_not be_empty
      expect(dome.uFactor.get).to be_within(0.1).of(6.0)

      expect(ceiling.tilt).to be_within(TOL).of(diffuser.tilt)
      expect(dome.tilt).to be_within(TOL).of(0.0)
      expect(roof.tilt).to be_within(TOL).of(0.32)

      rsi      = 0.28
      diameter = Math.sqrt(dome.grossArea/Math::PI) * 2

      tdd = OpenStudio::Model::DaylightingDeviceTubular.new(
              dome, diffuser, construction, diameter, totalLength, rsi)

      expect(tdd.addTransitionZone(zone, length)).to be true
      cl = OpenStudio::Model::TransitionZoneVector
      expect(tdd.transitionZones.class).to eq(cl)
      expect(tdd.numberofTransitionZones).to eq(1)
      expect(tdd.totalLength).to be_within(0.001).of(totalLength)

      expect(tdd.subSurfaceDome).to eq(dome)
      expect(tdd.subSurfaceDiffuser).to eq(diffuser)
      c = tdd.construction
      expect(c.to_LayeredConstruction).to_not be_empty
      c = c.to_LayeredConstruction.get
      expect(c.nameString).to eq(construction.nameString)
      expect(tdd.diameter).to be_within(0.001).of(diameter)
      expect(tdd.effectiveThermalResistance).to be_within(TOL).of(rsi)

      pth = File.join(__dir__, "files/osms/out/tdd_smalloffice_test.osm")
      model.save(pth, true)

      # Testing if TBD recognizes the TDD as a "skylight" (for derating & UA').
      argh = { option: "poor (BETBG)" }

      json     = TBD.process(model, argh)
      expect(json).to be_a(Hash)
      expect(json).to have_key(:io)
      expect(json).to have_key(:surfaces)
      io       = json[:io      ]
      surfaces = json[:surfaces]
      expect(TBD.status).to be_zero
      expect(TBD.logs).to be_empty
      expect(surfaces).to be_a(Hash)
      expect(surfaces.size).to eq(43)
      expect(io).to be_a(Hash)
      expect(io).to have_key(:edges)
      expect(io[:edges].size).to eq(109)

      # Both diffuser and parent ceiling are stored as TBD 'surfaces'.
      expect(surfaces).to have_key(s1)
      surface = surfaces[s1]
      expect(surface).to have_key(:skylights)
      expect(surface[:skylights]).to have_key("diffuser")

      skylight = surface[:skylights]["diffuser"]
      expect(skylight).to have_key(:u)
      expect(skylight[:u]).to be_a(Numeric)
      expect(skylight[:u]).to be_within(TOL).of(1/rsi)

      # ... yet TBD only derates constructions of opaque surfaces in CONDITIONED
      # spaces IF (i) facing outdoors or (ii) facing UNCONDITIONED spaces like
      # attics (see psi.rb). Here, the ceiling is tagged by TBD as a deratable
      # surface, and hence the diffuser edges are logged in TBD's 'edges'.
      expect(surface).to have_key(:ratio)
      expect(surface).to have_key(:heatloss)
      expect(surface[:heatloss]).to be_within(TOL).of(2.00) # 4x 0.500 W/K

      # Only edges of the diffuser (linked to the ceiling) are stored.
      io[:edges].each do |edge|
        expect(edge).to be_a(Hash)
        expect(edge).to have_key(:surfaces)
        expect(edge[:surfaces]).to be_a(Array)

        edge[:surfaces].each do |id|
          next unless ["dome", "diffuser"].include?(id)

          expect(id).to eq("diffuser")
        end
      end

      expect(surfaces).to have_key(s3)
      surface = surfaces[s3]
      expect(surface).to have_key(:skylights)
      expect(surface[:skylights]).to have_key("dome")

      skylight = surface[:skylights]["dome"]
      expect(skylight).to have_key(:u)
      expect(skylight[:u]).to be_a(Numeric)
      expect(skylight[:u]).to be_within(TOL).of(1/rsi)
      expect(surface).to_not have_key(:heatloss)
      expect(surface).to_not have_key(:ratio)

      expect(io[:edges].size).to eq(109) # 4x extra edges for diffuser only

      out  = JSON.pretty_generate(io)
      outP = File.join(__dir__, "../json/tbd_smalloffice1.out.json")

      File.open(outP, "w") { |outP| outP.puts out }

      # Re-use the exported file as input for another test.
      model2 = translator.loadModel(pth)
      expect(model2).to_not be_empty
      model2 = model2.get
      jpath  = "../json/tbd_smalloffice1.out.json"

      argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")
      argh[:io_path    ] = File.join(__dir__, jpath)

      json2    = TBD.process(model2, argh)
      expect(json2).to be_a(Hash)
      expect(json2).to have_key(:io)
      expect(json2).to have_key(:surfaces)
      io2      = json2[:io      ]
      surfaces = json2[:surfaces]
      expect(TBD.status).to be_zero
      expect(TBD.logs).to be_empty
      expect(surfaces).to be_a(Hash)
      expect(surfaces.size).to eq(43)
      expect(io).to be_a(Hash)
      expect(io).to have_key(:edges)
      expect(io[:edges].size).to eq(109)

      # Now mimic (again) the export functionality of the measure. Both output
      # files should be the same.
      out2  = JSON.pretty_generate(io2)
      outP2 = File.join(__dir__, "../json/tbd_smalloffice2.out.json")
      File.open(outP2, "w") { |outP2| outP2.puts out2 }
      expect(FileUtils).to be_identical(outP, outP2)
    end
  end

  it "can handle air gaps as materials" do
    translator = OpenStudio::OSVersion::VersionTranslator.new
    TBD.clean!

    file  = File.join(__dir__, "files/osms/in/warehouse.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get
    id    = "Bulk Storage Rear Wall"

    s = model.getSurfaceByName(id)
    expect(s).to_not be_empty
    s = s.get
    expect(s.nameString).to eq(id)
    expect(s.surfaceType).to eq("Wall")
    expect(s.isConstructionDefaulted).to be true
    c = s.construction.get.to_LayeredConstruction
    expect(c).to_not be_empty
    c = c.get
    expect(c.numLayers).to eq(3)

    gap = OpenStudio::Model::AirGap.new(model)
    expect(gap.handle.to_s).to_not be_empty
    expect(gap.nameString).to_not be_empty
    expect(gap.nameString).to eq("Material Air Gap 1")
    gap.setName("#{id} air gap")
    expect(gap.nameString).to eq("#{id} air gap")
    expect(gap.setThermalResistance(0.180)).to be true
    expect(gap.thermalResistance).to be_within(TOL).of(0.180)
    expect(c.insertLayer(1, gap)).to be true
    expect(c.numLayers).to eq(4)

    pth = File.join(__dir__, "files/osms/out/warehouse_airgap.osm")
    model.save(pth, true)

    argh = { option: "poor (BETBG)" }

    TBD.process(model, argh)
    expect(TBD.status).to be_zero
  end

  it "can uprate (ALL roof) constructions" do
    translator = OpenStudio::OSVersion::VersionTranslator.new
    TBD.clean!

    file = File.join(__dir__, "files/osms/in/warehouse.osm")
    path = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    # Mimics measure.
    walls = {c: {}, dft: "ALL wall constructions" }
    roofs = {c: {}, dft: "ALL roof constructions" }
    flors = {c: {}, dft: "ALL floor constructions"}

    walls[:c][walls[:dft]] = {a: 100000000000000}
    roofs[:c][roofs[:dft]] = {a: 100000000000000}
    flors[:c][flors[:dft]] = {a: 100000000000000}

    walls[:chx] = OpenStudio::StringVector.new
    roofs[:chx] = OpenStudio::StringVector.new
    flors[:chx] = OpenStudio::StringVector.new

    model.getSurfaces.each do |s|
      type = s.surfaceType.downcase
      next unless ["wall", "roofceiling", "floor"].include?(type)
      next unless s.outsideBoundaryCondition.downcase == "outdoors"
      next     if s.construction.empty?
      next     if s.construction.get.to_LayeredConstruction.empty?

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
      # each slope has a unique pitch: 50deg (s1), 0deg (s2), & 60dge (s3). All
      # three surfaces reference the same construction.
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
        walls[:c][id]     = {a: a, lc: lc}
        walls[:c][id][:f] = f unless walls[:c][id].key?(:f)
        walls[:c][id][:f] = f     if walls[:c][id][:f] > f
      when "roofceiling"
        roofs[:c][id]     = {a: a, lc: lc}
        roofs[:c][id][:f] = f unless roofs[:c][id].key?(:f)
        roofs[:c][id][:f] = f     if roofs[:c][id][:f] > f
      else
        flors[:c][id]     = {a: a, lc: lc}
        flors[:c][id][:f] = f unless flors[:c][id].key?(:f)
        flors[:c][id][:f] = f     if flors[:c][id][:f] > f
      end
    end

    walls[:c] = walls[:c].sort_by{ |k,v| v[:a] }.reverse!.to_h
    roofs[:c] = roofs[:c].sort_by{ |k,v| v[:a] }.reverse!.to_h
    flors[:c] = flors[:c].sort_by{ |k,v| v[:a] }.reverse!.to_h

    walls[:c][walls[:dft]][:a] = 0
    roofs[:c][roofs[:dft]][:a] = 0
    flors[:c][flors[:dft]][:a] = 0

    walls[:c].keys.each { |id| walls[:chx] << id }
    roofs[:c].keys.each { |id| roofs[:chx] << id }
    flors[:c].keys.each { |id| flors[:chx] << id }

    expect(roofs[:c].size).to eq(3)
    rf1 = "Typical Insulated Metal Building Roof R-10.31 1"
    rf2 = "Typical Insulated Metal Building Roof R-18.18"
    expect(roofs[:c].keys[0]).to eq("ALL roof constructions")
    expect(roofs[:c]["ALL roof constructions"][:a]).to be_within(TOL).of(0)
    roof1 = roofs[:c].values[1]
    roof2 = roofs[:c].values[2]
    expect(roof1[:a] > roof2[:a]).to be true
    expect(roof1[:f]).to be_within(TOL).of(roof2[:f])
    expect(roof1[:f]).to be_within(TOL).of(0.1360)
    expect(1/TBD.rsi(roof1[:lc], roof1[:f])).to be_within(TOL).of(0.5512) # R10
    expect(1/TBD.rsi(roof2[:lc], roof2[:f])).to be_within(TOL).of(0.3124) # R18

    # Deeper dive into rf1 (more prevalent).
    targeted = model.getConstructionByName(rf1)
    expect(targeted).to_not be_empty
    targeted = targeted.get
    expect(targeted.to_LayeredConstruction).to_not be_empty
    targeted = targeted.to_LayeredConstruction.get
    expect(targeted.is_a?(OpenStudio::Model::LayeredConstruction)).to be true
    expect(targeted.layers.size).to eq(2)

    targeted.layers.each do |layer|
      next unless layer.nameString == "Typical Insulation R-9.53 1"
      expect(layer.to_MasslessOpaqueMaterial).to_not be_empty
      layer = layer.to_MasslessOpaqueMaterial.get
      expect(layer.thermalResistance).to be_within(TOL).of(1.68) # m2.K/W (R9.5)
    end

    # argh[:roof_option ] = "Typical Insulated Metal Building Roof R-10.31 1"
    argh                = {}
    argh[:roof_option ] = "ALL roof constructions"
    argh[:option      ] = "poor (BETBG)"
    argh[:uprate_roofs] = true
    argh[:roof_ut     ] = 0.138 # NECB 2017 (RSi 7.25 / R41)

    json     = TBD.process(model, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty
    expect(surfaces).to be_a(Hash)
    expect(surfaces.size).to eq(23)
    expect(io).to be_a(Hash)
    expect(io).to have_key(:edges)
    expect(io[:edges].size).to eq(300)

    bulk = "Bulk Storage Roof"
    fine = "Fine Storage Roof"

    # OpenStudio objects.
    bulk_roof = model.getSurfaceByName(bulk)
    fine_roof = model.getSurfaceByName(fine)
    expect(bulk_roof).to_not be_empty
    expect(fine_roof).to_not be_empty
    bulk_roof = bulk_roof.get
    fine_roof = fine_roof.get

    bulk_construction = bulk_roof.construction
    fine_construction = fine_roof.construction
    expect(bulk_construction).to_not be_empty
    expect(fine_construction).to_not be_empty

    bulk_construction = bulk_construction.get.to_LayeredConstruction
    fine_construction = fine_construction.get.to_LayeredConstruction
    expect(bulk_construction).to_not be_empty
    expect(fine_construction).to_not be_empty

    bulk_construction = bulk_construction.get
    fine_construction = fine_construction.get
    expect(bulk_construction.nameString).to eq("Bulk Storage Roof c tbd")
    expect(fine_construction.nameString).to eq("Fine Storage Roof c tbd")
    expect(bulk_construction.layers.size).to eq(2)
    expect(fine_construction.layers.size).to eq(2)

    bulk_insulation = bulk_construction.layers.at(1).to_MasslessOpaqueMaterial
    fine_insulation = fine_construction.layers.at(1).to_MasslessOpaqueMaterial
    expect(bulk_insulation).to_not be_empty
    expect(fine_insulation).to_not be_empty

    bulk_insulation   = bulk_insulation.get
    fine_insulation   = fine_insulation.get
    bulk_insulation_r = bulk_insulation.thermalResistance
    fine_insulation_r = fine_insulation.thermalResistance
    expect(bulk_insulation_r).to be_within(TOL).of(7.307) # once derated
    expect(fine_insulation_r).to be_within(TOL).of(6.695) # once derated

    # TBD objects.
    expect(surfaces).to have_key(bulk)
    expect(surfaces).to have_key(fine)
    expect(surfaces[bulk]).to have_key(:heatloss)
    expect(surfaces[fine]).to have_key(:heatloss)
    expect(surfaces[bulk]).to have_key(:net)
    expect(surfaces[fine]).to have_key(:net)

    expect(surfaces[bulk][:heatloss]).to be_within(TOL).of(161.02)
    expect(surfaces[fine][:heatloss]).to be_within(TOL).of( 87.16)
    expect(surfaces[bulk][:net     ]).to be_within(TOL).of(3157.28)
    expect(surfaces[fine][:net     ]).to be_within(TOL).of(1372.60)

    heatloss = surfaces[bulk][:heatloss] + surfaces[fine][:heatloss]
    area     = surfaces[bulk][:net     ] + surfaces[fine][:net     ]

    expect(heatloss).to be_within(TOL).of( 248.19)
    expect(area    ).to be_within(TOL).of(4529.88)

    expect(surfaces[bulk]).to have_key(:construction) # not yet derated
    expect(surfaces[fine]).to have_key(:construction)

    expect(surfaces[bulk][:construction].nameString).to eq(rf1)
    expect(surfaces[fine][:construction].nameString).to eq(rf1) # no longer rf2

    uprated = model.getConstructionByName(rf1) # not yet derated
    expect(uprated).to_not be_empty
    uprated = uprated.get
    expect(uprated.to_LayeredConstruction).to_not be_empty
    uprated = uprated.to_LayeredConstruction.get

    expect(uprated.is_a?(OpenStudio::Model::LayeredConstruction)).to be true
    expect(uprated.layers.size).to eq(2)
    uprated_layer_r = 0

    uprated.layers.each do |layer|
      next unless layer.nameString.include?(" uprated")

      expect(layer.to_MasslessOpaqueMaterial).to_not be_empty
      layer           = layer.to_MasslessOpaqueMaterial.get
      uprated_layer_r = layer.thermalResistance
      expect(layer.thermalResistance).to be_within(TOL).of(11.65) # m2.K/W (R66)
    end

    rt = TBD.rsi(uprated, roof1[:f])
    expect(1/rt).to be_within(TOL).of(0.0849) # R67 (with surface films)

    # Bulk storage roof demonstration.
    u = surfaces[bulk][:heatloss] / surfaces[bulk][:net]
    expect(u).to be_within(TOL).of(0.051) # W/m2.K

    de_u   = 1 / uprated_layer_r + u
    de_r   = 1 / de_u
    bulk_r = de_r + roof1[:f]
    bulk_u = 1 / bulk_r
    expect(de_u).to be_within(TOL).of(0.137) # bit below required Ut of 0.138
    expect(de_r).to be_within(TOL).of(bulk_insulation_r) # 7.307, not 11.65
    ratio  = -(uprated_layer_r - de_r) * 100 / (uprated_layer_r + roof1[:f])
    expect(ratio).to be_within(TOL).of(-36.84)
    expect(surfaces[bulk]).to have_key(:ratio)
    expect(surfaces[bulk][:ratio]).to be_within(TOL).of(ratio)

    # Fine storage roof demonstration.
    u = surfaces[fine][:heatloss] / surfaces[fine][:net]
    expect(u).to be_within(TOL).of(0.063) # W/m2.K

    de_u   = 1 / uprated_layer_r + u
    de_r   = 1 / de_u
    fine_r = de_r + roof1[:f]
    fine_u = 1 / fine_r
    expect(de_u).to be_within(TOL).of(0.149) # above required Ut of 0.138
    expect(de_r).to be_within(TOL).of(fine_insulation_r) # 6.695, not 11.65
    ratio  = -(uprated_layer_r - de_r) * 100 / (uprated_layer_r + roof1[:f])
    expect(ratio).to be_within(TOL).of(-42.03)
    expect(surfaces[fine]).to have_key(:ratio)
    expect(surfaces[fine][:ratio]).to be_within(TOL).of(ratio)

    ua    = bulk_u * surfaces[bulk][:net] + fine_u * surfaces[fine][:net]
    ave_u = ua / area
    expect(ave_u).to be_within(TOL).of(argh[:roof_ut]) # area-weighted average

    file = File.join(__dir__, "files/osms/out/up_warehouse.osm")
    model.save(file, true)
  end

  it "can uprate (ALL wall) constructions - poor (BETBG)" do
    translator = OpenStudio::OSVersion::VersionTranslator.new
    TBD.clean!

    file  = File.join(__dir__, "files/osms/in/warehouse.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    # Mimics measure.
    walls = {c: {}, dft: "ALL wall constructions" }
    roofs = {c: {}, dft: "ALL roof constructions" }
    flors = {c: {}, dft: "ALL floor constructions"}

    walls[:c][walls[:dft]] = {a: 100000000000000}
    roofs[:c][roofs[:dft]] = {a: 100000000000000}
    flors[:c][flors[:dft]] = {a: 100000000000000}

    walls[:chx] = OpenStudio::StringVector.new
    roofs[:chx] = OpenStudio::StringVector.new
    flors[:chx] = OpenStudio::StringVector.new

    model.getSurfaces.each do |s|
      type = s.surfaceType.downcase
      next unless ["wall", "roofceiling", "floor"].include?(type)
      next unless s.outsideBoundaryCondition.downcase == "outdoors"
      next     if s.construction.empty?
      next     if s.construction.get.to_LayeredConstruction.empty?

      lc = s.construction.get.to_LayeredConstruction.get
      id = lc.nameString
      next if walls[:c].key?(id)
      next if roofs[:c].key?(id)
      next if flors[:c].key?(id)

      a = lc.getNetArea
      f = s.filmResistance

      case type
      when "wall"
        walls[:c][id]     = {a: a, lc: lc}
        walls[:c][id][:f] = f unless walls[:c][id].key?(:f)
        walls[:c][id][:f] = f     if walls[:c][id][:f] > f
      when "roofceiling"
        roofs[:c][id]     = {a: a, lc: lc}
        roofs[:c][id][:f] = f unless roofs[:c][id].key?(:f)
        roofs[:c][id][:f] = f     if roofs[:c][id][:f] > f
      else
        flors[:c][id]     = {a: a, lc: lc}
        flors[:c][id][:f] = f unless flors[:c][id].key?(:f)
        flors[:c][id][:f] = f     if flors[:c][id][:f] > f
      end
    end

    walls[:c] = walls[:c].sort_by{ |k,v| v[:a] }.reverse!.to_h
    roofs[:c] = roofs[:c].sort_by{ |k,v| v[:a] }.reverse!.to_h
    flors[:c] = flors[:c].sort_by{ |k,v| v[:a] }.reverse!.to_h

    walls[:c][walls[:dft]][:a] = 0
    roofs[:c][roofs[:dft]][:a] = 0
    flors[:c][flors[:dft]][:a] = 0

    walls[:c].keys.each { |id| walls[:chx] << id }
    roofs[:c].keys.each { |id| roofs[:chx] << id }
    flors[:c].keys.each { |id| flors[:chx] << id }

    expect(walls[:c].size).to eq(4)

    w1 = "Typical Insulated Metal Building Wall R-8.85 1"
    w2 = "Typical Insulated Metal Building Wall R-11.9"
    w3 = "Typical Insulated Metal Building Wall R-11.9 1"

    expect(walls[:c]).to have_key(w1)
    expect(walls[:c]).to have_key(w2)
    expect(walls[:c]).to have_key(w3)

    expect(walls[:c].keys[0]).to eq("ALL wall constructions")
    expect(walls[:c]["ALL wall constructions"][:a]).to be_within(TOL).of(0)

    wall1 = walls[:c][w1]
    wall2 = walls[:c][w2]
    wall3 = walls[:c][w3]

    expect(wall1[:a] > wall2[:a]).to be true
    expect(wall2[:a] > wall3[:a]).to be true

    expect(wall1[:f]).to be_within(TOL).of(wall2[:f])
    expect(wall3[:f]).to be_within(TOL).of(wall3[:f])
    expect(wall1[:f]).to be_within(TOL).of(0.150)
    expect(wall2[:f]).to be_within(TOL).of(0.150)
    expect(wall3[:f]).to be_within(TOL).of(0.150)
    expect(1/TBD.rsi(wall1[:lc], wall1[:f])).to be_within(TOL).of(0.642) # R08.8
    expect(1/TBD.rsi(wall2[:lc], wall2[:f])).to be_within(TOL).of(0.477) # R11.9

    # Deeper dive into w1 (more prevalent).
    targeted = model.getConstructionByName(w1)
    expect(targeted).to_not be_empty
    targeted = targeted.get
    expect(targeted.to_LayeredConstruction).to_not be_empty
    targeted = targeted.to_LayeredConstruction.get
    expect(targeted.is_a?(OpenStudio::Model::LayeredConstruction)).to be true
    expect(targeted.layers.size).to eq(3)

    targeted.layers.each do |layer|
      next unless layer.nameString == "Typical Insulation R-7.55 1"
      expect(layer.to_MasslessOpaqueMaterial).to_not be_empty
      layer = layer.to_MasslessOpaqueMaterial.get
      expect(layer.thermalResistance).to be_within(TOL).of(1.33) # m2.K/W (R7.6)
    end

    # Set w1 (a wall construction) as the 'Bulk Storage Roof' construction. This
    # triggers a TBD warning when uprating: a safeguard limiting uprated
    # constructions to single surface type (e.g. can't be referenced by both
    # roof AND wall surfaces).
    bulk = "Bulk Storage Roof"

    bulk_roof = model.getSurfaceByName(bulk)
    expect(bulk_roof).to_not be_empty
    bulk_roof = bulk_roof.get
    expect(bulk_roof.isConstructionDefaulted).to be true

    bulk_construction = bulk_roof.construction
    expect(bulk_construction).to_not be_empty
    bulk_construction = bulk_construction.get.to_LayeredConstruction
    expect(bulk_construction).to_not be_empty
    bulk_construction = bulk_construction.get
    expect(bulk_construction.numLayers).to eq(2)
    expect(bulk_roof.setConstruction(targeted)).to be true
    expect(bulk_roof.isConstructionDefaulted).to be false

    argh                = {}
    argh[:wall_option ] = "ALL wall constructions"
    argh[:option      ] = "poor (BETBG)"
    argh[:uprate_walls] = true
    argh[:wall_ut     ] = 0.210 # (R27)

    json     = TBD.process(model, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.warn?).to be true
    expect(TBD.logs.size).to eq(1)
    expect(surfaces).to be_a(Hash)
    expect(surfaces.size).to eq(23)
    expect(io).to be_a(Hash)
    expect(io).to have_key(:edges)
    expect(io[:edges].size).to eq(300)

    msg = "Cloning '#{bulk}' construction - not '#{w1}' (TBD::uprate)"
    expect(TBD.logs.first[:message]).to eq(msg)

    bulk_roof = model.getSurfaceByName(bulk)
    expect(bulk_roof).to_not be_empty
    bulk_roof = bulk_roof.get

    bulk_construction = bulk_roof.construction
    expect(bulk_construction).to_not be_empty
    bulk_construction = bulk_construction.get.to_LayeredConstruction
    expect(bulk_construction).to_not be_empty
    bulk_construction = bulk_construction.get
    expect(bulk_construction.nameString).to eq("#{bulk} c tbd")
    expect(bulk_construction.numLayers ).to eq(3) # not 2

    layer0 = bulk_construction.layers[0]
    layer1 = bulk_construction.layers[1]
    layer2 = bulk_construction.layers[2]
    expect(layer1.nameString).to eq("#{bulk} m tbd")# not uprated

    layer  = layer0.to_StandardOpaqueMaterial
    expect(layer).to_not be_empty
    siding = layer.get.thickness / layer.get.thermalConductivity
    layer  = layer2.to_StandardOpaqueMaterial
    expect(layer).to_not be_empty
    gypsum = layer.get.thickness / layer.get.thermalConductivity
    extra  = siding + gypsum + wall1[:f]

    wall_surfaces = []

    model.getSurfaces.each do |s|
      next unless s.surfaceType.downcase == "wall"
      next unless s.outsideBoundaryCondition.downcase == "outdoors"
      next     if s.construction.empty?
      next     if s.construction.get.to_LayeredConstruction.empty?

      c = s.construction.get.to_LayeredConstruction.get
      expect(c.numLayers).to eq(3)
      expect(c.layers[0]).to eq(layer0) # same as Bulk Storage Roof
      expect(c.layers[1].nameString).to include(" uprated ")
      expect(c.layers[1].nameString).to include(" m tbd")
      expect(c.layers[2]).to eq(layer2) # same as Bulk Storage Roof
      wall_surfaces << s
    end

    expect(wall_surfaces.size).to eq(10)

    # TBD objects.
    expect(surfaces).to have_key(bulk)
    expect(surfaces[bulk]).to have_key(:heatloss)
    expect(surfaces[bulk]).to have_key(:net)

    # By initially inheriting the wall construction, the bulk roof surface is
    # slightly less derated (152.40 W/K instead of 161.02 W/K), due to TBD's
    # proportionate psi distribution between surface edges.
    expect(surfaces[bulk][:heatloss]).to be_within(TOL).of(152.40)
    expect(surfaces[bulk][:net]).to be_within(TOL).of(3157.28)
    expect(surfaces[bulk]).to have_key(:construction) # not yet derated
    nom = surfaces[bulk][:construction].nameString
    expect(nom).to include("cloned")

    uprated = model.getConstructionByName(w1) # uprated, not yet derated
    expect(uprated).to_not be_empty
    uprated = uprated.get
    expect(uprated.to_LayeredConstruction).to_not be_empty
    uprated = uprated.to_LayeredConstruction.get
    expect(uprated.layers.size).to eq(3)
    uprated_layer_r = 0

    uprated.layers.each do |layer|
      next unless layer.nameString.include?("uprated")

      expect(layer.to_MasslessOpaqueMaterial).to_not be_empty
      uprated_layer_r = layer.to_MasslessOpaqueMaterial.get.thermalResistance
      expect(uprated_layer_r).to be_within(TOL).of(51.92) # m2.K/W
    end

    rt = TBD.rsi(uprated, wall1[:f])
    expect(1/rt).to be_within(TOL).of(0.019) # 52.63 (with surface films)

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
      net   += surface[:net     ]
    end

    expect(hloss).to be_within(TOL).of(485.59)
    expect(net  ).to be_within(TOL).of(2411.7)
    u     = hloss / net
    de_u  = 1 / uprated_layer_r + u
    de_r  = 1 / de_u
    new_r = de_r + extra
    new_u = 1 / new_r
    expect(new_r).to be_within(TOL).of(4.76)           # R27 (NECB2017)
    expect(new_u).to be_within(TOL).of(argh[:wall_ut]) # 0.210 W/m2.K

    # Bulk storage wall demonstration.
    wll1 = "Bulk Storage Left Wall"
    wll2 = "Bulk Storage Rear Wall"
    wll3 = "Bulk Storage Right Wall"
    rs   = {}

    [wll1, wll2, wll3].each do |i|
      sface = model.getSurfaceByName(i)
      expect(sface).to_not be_empty
      sface = sface.get

      c = sface.construction
      expect(c).to_not be_empty
      c = c.get.to_LayeredConstruction
      expect(c).to_not be_empty
      c = c.get

      expect(c.numLayers).to eq(3)
      layer = c.layers[0].to_StandardOpaqueMaterial
      expect(layer).to_not be_empty

      d = layer.get.thickness
      k = layer.get.thermalConductivity
      expect(d / k).to be_within(TOL).of(siding)

      layer = c.layers[1].to_MasslessOpaqueMaterial
      expect(layer).to_not be_empty
      rsi   = layer.get.thermalResistance

      expect(rsi).to be_within(TOL).of(4.1493) if i == wll1
      expect(rsi).to be_within(TOL).of(5.4252) if i == wll2
      expect(rsi).to be_within(TOL).of(5.3642) if i == wll3

      layer = c.layers[2].to_StandardOpaqueMaterial
      expect(layer).to_not be_empty
      d = layer.get.thickness
      k = layer.get.thermalConductivity
      expect(d / k).to be_within(TOL).of(gypsum)

      u = c.thermalConductance
      expect(u).to_not be_empty
      rs[i] = 1 / u.get
    end

    expect(rs).to have_key(wll1)
    expect(rs).to have_key(wll2)
    expect(rs).to have_key(wll3)
    expect(rs[wll1]).to be_within(TOL).of(4.2287)
    expect(rs[wll2]).to be_within(TOL).of(5.5046)
    expect(rs[wll3]).to be_within(TOL).of(5.4436)

    u     = surfaces[wll1][:heatloss] / surfaces[wll1][:net]
    expect(u).to be_within(TOL).of(0.2217) # W/m2.K from thermal bridging
    de_u  = 1 / uprated_layer_r + u
    de_r  = 1 / de_u
    new_r = de_r + extra
    new_u = 1 / new_r
    expect(new_r).to be_within(TOL).of(4.3782) # R24.9 ... lot of doors
    ratio = -(uprated_layer_r - de_r) * 100 / rt
    expect(ratio).to be_within(TOL).of(-91.60)
    expect(surfaces[wll1]).to have_key(:ratio)
    expect(surfaces[wll1][:ratio]).to be_within(TOL).of(ratio)

    u     = surfaces[wll2][:heatloss] / surfaces[wll2][:net]
    expect(u).to be_within(TOL).of(0.1652) # W/m2.K from thermal bridging
    de_u  = 1 / uprated_layer_r + u
    de_r  = 1 / de_u
    new_r = de_r + extra
    new_u = 1 / new_r
    expect(new_r).to be_within(TOL).of(5.6542) # R32.1 ... no openings
    ratio = -(uprated_layer_r - de_r) * 100 / rt
    expect(ratio).to be_within(TOL).of(-89.16)
    expect(surfaces[wll2]).to have_key(:ratio)
    expect(surfaces[wll2][:ratio]).to be_within(TOL).of(ratio)

    u     = surfaces[wll3][:heatloss] / surfaces[wll3][:net]
    expect(u).to be_within(TOL).of(0.1671) # W/m2.K from thermal bridging
    de_u  = 1 / uprated_layer_r + u
    de_r  = 1 / de_u
    new_r = de_r + extra
    new_u = 1 / new_r
    expect(new_r).to be_within(TOL).of(5.5931) # R31.8 ... a few doors
    ratio = -(uprated_layer_r - de_r) * 100 / rt
    expect(ratio).to be_within(TOL).of(-89.27)
    expect(surfaces[wll3]).to have_key(:ratio)
    expect(surfaces[wll3][:ratio]).to be_within(TOL).of(ratio)

    file = File.join(__dir__, "files/osms/out/up2_warehouse.osm")
    model.save(file, true)
  end

  it "can uprate (ALL wall) constructions - efficient (BETBG)" do
    translator = OpenStudio::OSVersion::VersionTranslator.new
    TBD.clean!

    file  = File.join(__dir__, "files/osms/in/warehouse.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    # Mimics measure.
    walls = { c: {}, dft: "ALL wall constructions" }
    roofs = { c: {}, dft: "ALL roof constructions" }
    flors = { c: {}, dft: "ALL floor constructions"}

    walls[:c][walls[:dft]] = {a: 100000000000000}
    roofs[:c][roofs[:dft]] = {a: 100000000000000}
    flors[:c][flors[:dft]] = {a: 100000000000000}

    walls[:chx] = OpenStudio::StringVector.new
    roofs[:chx] = OpenStudio::StringVector.new
    flors[:chx] = OpenStudio::StringVector.new

    model.getSurfaces.each do |s|
      type = s.surfaceType.downcase
      next unless ["wall", "roofceiling", "floor"].include?(type)
      next unless s.outsideBoundaryCondition.downcase == "outdoors"
      next     if s.construction.empty?
      next     if s.construction.get.to_LayeredConstruction.empty?

      lc = s.construction.get.to_LayeredConstruction.get
      id = lc.nameString
      next if walls[:c].key?(id)
      next if roofs[:c].key?(id)
      next if flors[:c].key?(id)

      a = lc.getNetArea
      f = s.filmResistance

      case type
      when "wall"
        walls[:c][id]     = {a: a, lc: lc}
        walls[:c][id][:f] = f unless walls[:c][id].key?(:f)
        walls[:c][id][:f] = f     if walls[:c][id][:f] > f
      when "roofceiling"
        roofs[:c][id]     = {a: a, lc: lc}
        roofs[:c][id][:f] = f unless roofs[:c][id].key?(:f)
        roofs[:c][id][:f] = f     if roofs[:c][id][:f] > f
      else
        flors[:c][id]     = {a: a, lc: lc}
        flors[:c][id][:f] = f unless flors[:c][id].key?(:f)
        flors[:c][id][:f] = f     if flors[:c][id][:f] > f
      end
    end

    walls[:c] = walls[:c].sort_by{ |k,v| v[:a] }.reverse!.to_h
    roofs[:c] = roofs[:c].sort_by{ |k,v| v[:a] }.reverse!.to_h
    flors[:c] = flors[:c].sort_by{ |k,v| v[:a] }.reverse!.to_h

    walls[:c][walls[:dft]][:a] = 0
    roofs[:c][roofs[:dft]][:a] = 0
    flors[:c][flors[:dft]][:a] = 0

    walls[:c].keys.each { |id| walls[:chx] << id }
    roofs[:c].keys.each { |id| roofs[:chx] << id }
    flors[:c].keys.each { |id| flors[:chx] << id }

    expect(walls[:c].size).to eq(4)

    w1 = "Typical Insulated Metal Building Wall R-8.85 1"
    w2 = "Typical Insulated Metal Building Wall R-11.9"
    w3 = "Typical Insulated Metal Building Wall R-11.9 1"

    expect(walls[:c]).to have_key(w1)
    expect(walls[:c]).to have_key(w2)
    expect(walls[:c]).to have_key(w3)

    expect(walls[:c].keys[0]).to eq("ALL wall constructions")
    expect(walls[:c]["ALL wall constructions"][:a]).to be_within(TOL).of(0)

    wall1 = walls[:c][w1]
    wall2 = walls[:c][w2]
    wall3 = walls[:c][w3]

    expect(wall1[:a] > wall2[:a]).to be true
    expect(wall2[:a] > wall3[:a]).to be true

    expect(wall1[:f]).to be_within(TOL).of(wall2[:f])
    expect(wall3[:f]).to be_within(TOL).of(wall3[:f])
    expect(wall1[:f]).to be_within(TOL).of(0.150)
    expect(wall2[:f]).to be_within(TOL).of(0.150)
    expect(wall3[:f]).to be_within(TOL).of(0.150)

    expect(1/TBD.rsi(wall1[:lc], wall1[:f])).to be_within(TOL).of(0.642) # R08.8
    expect(1/TBD.rsi(wall2[:lc], wall2[:f])).to be_within(TOL).of(0.477) # R11.9

    # Deeper dive into w1 (more prevalent).
    targeted = model.getConstructionByName(w1)
    expect(targeted).to_not be_empty
    targeted = targeted.get
    expect(targeted.to_LayeredConstruction).to_not be_empty
    targeted = targeted.to_LayeredConstruction.get

    expect(targeted.is_a?(OpenStudio::Model::LayeredConstruction)).to be true
    expect(targeted.layers.size).to eq(3)

    targeted.layers.each do |layer|
      next unless layer.nameString == "Typical Insulation R-7.55 1"

      expect(layer.to_MasslessOpaqueMaterial).to_not be_empty
      layer = layer.to_MasslessOpaqueMaterial.get
      expect(layer.thermalResistance).to be_within(TOL).of(1.33) # m2.K/W (R7.6)
    end

    # Set w1 (a wall construction) as the 'Bulk Storage Roof' construction. This
    # triggers a TBD warning when uprating: a safeguard limiting uprated
    # constructions to single surface type (e.g. can't be referenced by both
    # roof AND wall surfaces).
    bulk      = "Bulk Storage Roof"
    bulk_roof = model.getSurfaceByName(bulk)
    expect(bulk_roof).to_not be_empty
    bulk_roof = bulk_roof.get
    expect(bulk_roof.isConstructionDefaulted).to be true

    bulk_construction = bulk_roof.construction
    expect(bulk_construction).to_not be_empty
    bulk_construction = bulk_construction.get.to_LayeredConstruction
    expect(bulk_construction).to_not be_empty
    bulk_construction = bulk_construction.get
    expect(bulk_construction.numLayers).to eq(2)
    expect(bulk_roof.setConstruction(targeted)).to be true
    expect(bulk_roof.isConstructionDefaulted).to be false

    argh                = {}
    argh[:wall_option ] = "ALL wall constructions"
    argh[:option      ] = "efficient (BETBG)" # vs preceding test
    argh[:uprate_walls] = true
    argh[:wall_ut     ] = 0.210 # (R27)

    json     = TBD.process(model, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.warn?).to be true
    expect(TBD.logs.size).to eq(1)
    expect(surfaces).to be_a(Hash)
    expect(surfaces.size).to eq(23)
    expect(io).to be_a(Hash)
    expect(io).to have_key(:edges)
    expect(io[:edges].size).to eq(300)

    msg = "Cloning '#{bulk}' construction - not '#{w1}' (TBD::uprate)"
    expect(TBD.logs.first[:message]).to eq(msg)

    bulk_roof = model.getSurfaceByName(bulk)
    expect(bulk_roof).to_not be_empty
    bulk_roof = bulk_roof.get

    bulk_construction = bulk_roof.construction
    expect(bulk_construction).to_not be_empty
    bulk_construction = bulk_construction.get.to_LayeredConstruction
    expect(bulk_construction).to_not be_empty
    bulk_construction = bulk_construction.get
    expect(bulk_construction.nameString).to eq("#{bulk} c tbd")
    expect(bulk_construction.numLayers).to eq(3) # not 2

    layer0 = bulk_construction.layers[0]
    layer1 = bulk_construction.layers[1]
    layer2 = bulk_construction.layers[2]
    expect(layer1.nameString).to eq("#{bulk} m tbd") # not uprated

    layer  = layer0.to_StandardOpaqueMaterial
    expect(layer).to_not be_empty
    siding = layer.get.thickness / layer.get.thermalConductivity
    layer  = layer2.to_StandardOpaqueMaterial
    expect(layer).to_not be_empty
    gypsum = layer.get.thickness / layer.get.thermalConductivity
    extra  = siding + gypsum + wall1[:f]

    wall_surfaces = []

    model.getSurfaces.each do |s|
      next unless s.surfaceType.downcase == "wall"
      next unless s.outsideBoundaryCondition.downcase == "outdoors"
      next     if s.construction.empty?
      next     if s.construction.get.to_LayeredConstruction.empty?

      c = s.construction.get.to_LayeredConstruction.get
      expect(c.numLayers).to eq(3)
      expect(c.layers[0]).to eq(layer0) # same as Bulk Storage Roof
      expect(c.layers[1].nameString).to include(" uprated ")
      expect(c.layers[1].nameString).to include(" m tbd")
      expect(c.layers[2]).to eq(layer2) # same as Bul;k Storage Roof
      wall_surfaces << s
    end

    expect(wall_surfaces.size).to eq(10)

    # TBD objects.
    expect(surfaces).to have_key(bulk)
    expect(surfaces[bulk]).to have_key(:construction) # not yet derated
    expect(surfaces[bulk]).to have_key(:net)
    expect(surfaces[bulk]).to have_key(:heatloss)
    expect(surfaces[bulk][:heatloss]).to be_within(TOL).of(  49.80)
    expect(surfaces[bulk][:net     ]).to be_within(TOL).of(3157.28)
    nom = surfaces[bulk][:construction].nameString
    expect(nom).to include("cloned")

    uprated = model.getConstructionByName(w1) # uprated, not yet derated
    expect(uprated).to_not be_empty
    uprated = uprated.get
    expect(uprated.to_LayeredConstruction).to_not be_empty
    uprated = uprated.to_LayeredConstruction.get
    expect(uprated.layers.size).to eq(3)

    uprated_layer_r = 0

    uprated.layers.each do |layer|
      next unless layer.nameString.include?("uprated")

      expect(layer.to_MasslessOpaqueMaterial).to_not be_empty
      layer = layer.to_MasslessOpaqueMaterial.get

      # The switch from "poor" to "efficient" thermal bridging details is key.
      uprated_layer_r = layer.thermalResistance
      expect(uprated_layer_r).to be_within(TOL).of(5.932) # vs 51.92 m2.K/W !!
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
      next unless surface.key?(:construction)
      next unless surface.key?(:heatloss)
      next unless surface.key?(:net)
      next unless surface.key?(:type)
      next unless surface[:boundary] == "Outdoors"
      next unless surface[:type    ] == :wall

      hloss += surface[:heatloss]
      net   += surface[:net]
    end

    expect(hloss).to be_within(TOL).of( 125.48) # vs 485.59 W/K
    expect(net  ).to be_within(TOL).of(2411.70)
    u     = hloss / net
    de_u  = 1 / uprated_layer_r + u
    de_r  = 1 / de_u
    new_r = de_r + extra
    new_u = 1 / new_r
    expect(new_r).to be_within(TOL).of(          4.76) # R27 (NECB2017)
    expect(new_u).to be_within(TOL).of(argh[:wall_ut]) # 0.210 W/m2.K

    # Bulk storage wall demonstration.
    wll1 = "Bulk Storage Left Wall"
    wll2 = "Bulk Storage Rear Wall"
    wll3 = "Bulk Storage Right Wall"
    rs = {}

    [wll1, wll2, wll3].each do |i|
      sface = model.getSurfaceByName(i)
      expect(sface).to_not be_empty
      sface = sface.get

      c = sface.construction
      expect(c).to_not be_empty
      c = c.get.to_LayeredConstruction
      expect(c).to_not be_empty
      c = c.get
      expect(c.numLayers).to eq(3)

      layer = c.layers[0].to_StandardOpaqueMaterial
      expect(layer).to_not be_empty

      d = layer.get.thickness
      k = layer.get.thermalConductivity
      expect(d / k).to be_within(TOL).of(siding)

      layer = c.layers[1].to_MasslessOpaqueMaterial
      expect(layer).to_not be_empty

      rsi = layer.get.thermalResistance
      expect(rsi).to be_within(TOL).of(4.3381) if i == wll1 # vs 4.1493 m2.K/W
      expect(rsi).to be_within(TOL).of(4.8052) if i == wll2 # vs 5.4252 m2.K/W
      expect(rsi).to be_within(TOL).of(4.7446) if i == wll3 # vs 5.3642 m2.K/W

      layer = c.layers[2].to_StandardOpaqueMaterial
      expect(layer).to_not be_empty
      d = layer.get.thickness
      k = layer.get.thermalConductivity
      expect(d / k).to be_within(TOL).of(gypsum)

      u = c.thermalConductance
      expect(u).to_not be_empty
      rs[i] = 1 / u.get
    end

    expect(rs).to have_key(wll1)
    expect(rs).to have_key(wll2)
    expect(rs).to have_key(wll3)

    expect(rs[wll1]).to be_within(TOL).of(4.4175) # vs 4.2287 m2.K/W
    expect(rs[wll2]).to be_within(TOL).of(4.8847) # vs 5.5046 m2.K/W
    expect(rs[wll3]).to be_within(TOL).of(4.8240) # vs 5.4436 m2.K/W

    u = surfaces[wll1][:heatloss] / surfaces[wll1][:net]
    expect(u).to be_within(TOL).of(0.0619) # vs 0.2217 W/m2.K from bridging

    de_u  = 1 / uprated_layer_r + u
    de_r  = 1 / de_u
    new_r = de_r + extra
    new_u = 1 / new_r
    expect(new_r).to be_within(TOL).of(4.5671) # R26, vs R24.9
    ratio = -(uprated_layer_r - de_r) * 100 / rt
    expect(ratio).to be_within(TOL).of(-25.87) # vs -91.60 %
    expect(surfaces[wll1]).to have_key(:ratio)
    expect(surfaces[wll1][:ratio]).to be_within(TOL).of(ratio)

    u = surfaces[wll2][:heatloss] / surfaces[wll2][:net]
    expect(u).to be_within(TOL).of(0.0395) # vs 0.1652 W/m2.K from bridging

    de_u  = 1 / uprated_layer_r + u
    de_r  = 1 / de_u
    new_r = de_r + extra
    new_u = 1 / new_r
    expect(new_r).to be_within(TOL).of(5.0342)# R28.6, vs R32.1
    ratio = -(uprated_layer_r - de_r) * 100 / rt
    expect(ratio).to be_within(TOL).of(-18.29) # vs -89.16%
    expect(surfaces[wll2]).to have_key(:ratio)
    expect(surfaces[wll2][:ratio]).to be_within(TOL).of(ratio)

    u = surfaces[wll3][:heatloss] / surfaces[wll3][:net]
    expect(u).to be_within(TOL).of(0.0422)# vs 0.1671 W/m2.K from bridging

    de_u  = 1 / uprated_layer_r + u
    de_r  = 1 / de_u
    new_r = de_r + extra
    new_u = 1 / new_r
    expect(new_r).to be_within(TOL).of(4.9735) # R28.2, vs R31.8
    ratio = -(uprated_layer_r - de_r) * 100 / rt
    expect(ratio).to be_within(TOL).of(-19.27) # vs -89.27%
    expect(surfaces[wll3]).to have_key(:ratio)
    expect(surfaces[wll3][:ratio]).to be_within(TOL).of(ratio)

    file = File.join(__dir__, "files/osms/out/up3_warehouse.osm")
    model.save(file, true)
  end

  it "can test 5ZoneNoHVAC (failed) uprating" do
    translator = OpenStudio::OSVersion::VersionTranslator.new
    TBD.clean!

    walls = []
    id    = "ASHRAE 189.1-2009 ExtWall Mass ClimateZone 5"
    file  = File.join(__dir__, "files/osms/in/5ZoneNoHVAC.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    # Get geometry data for testing (4x exterior walls, same construction).
    construction = nil

    model.getSurfaces.each do |s|
      next unless s.surfaceType == "Wall"
      next unless s.outsideBoundaryCondition == "Outdoors"

      walls << s.nameString
      c = s.construction
      expect(c).to_not be_empty
      c = c.get.to_LayeredConstruction
      expect(c).to_not be_empty
      c = c.get

      construction = c if construction.nil?
      expect(c).to eq(construction)
    end

    expect(walls.size              ).to eq( 4)
    expect(construction.nameString ).to eq(id)
    expect(construction.layers.size).to eq( 4)

    insulation = construction.layers[2].to_StandardOpaqueMaterial
    expect(insulation).to_not be_empty
    insulation = insulation.get
    expect(insulation.thickness).to be_within(0.0001).of(0.0794)
    expect(insulation.thermalConductivity).to be_within(0.0001).of(0.0432)
    original_r = insulation.thickness / insulation.thermalConductivity
    expect(original_r).to be_within(TOL).of(1.8380)

    argh = { option: "efficient (BETBG)" } # all PSI-factors @ 0.2 W/K•m

    json     = TBD.process(model, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty

    walls.each do |wall|
      expect(surfaces).to have_key(wall)
      expect(surfaces[wall]).to have_key(:heatloss)

      long  = (surfaces[wall][:heatloss] - 27.746).abs < TOL # 40 metres wide
      short = (surfaces[wall][:heatloss] - 14.548).abs < TOL # 20 metres wide
      expect(long || short).to be true
    end

    # The 4-sided model has 2x "long" front/back + 2x "short" side exterior
    # walls, with a total TBD-calculated heat loss (from thermal bridging) of:
    #
    #   2x 27.746 W/K + 2x 14.548 W/K = ~84.588 W/K
    #
    # Spread over ~273.6 m2 of gross wall area, that is A LOT! Why (given the
    # "efficient" PSI-factors)? Each wall has a long "strip" window, almost the
    # full wall width (reaching to within a few millimetres of each corner).
    # This ~slices the host wall into 2x very narrow strips. Although the
    # thermal bridging details are considered "efficient", the total length of
    # linear thermal bridges is very high given the limited exposed (gross)
    # area. If area-weighted, derating the insulation layer of the referenced
    # wall construction above would entail factoring in this extra thermal
    # conductance of ~0.309 W/m2•K (84.6/273.6), which would increase the
    # insulation conductivity quite significantly.
    #
    #   Ut = Uo + ( ∑psi • L )/A
    #
    # Expressed otherwise:
    #
    #   Ut = Uo + 0.309
    #
    # So what initial Uo factor should the construction offer (prior to
    # derating) to ensure compliance with NECB2017/2020 prescriptive
    # requirements (one of the few energy codes with prescriptive Ut
    # requirements)? For climate zone 7, the target Ut is 0.210 W/m2•K (Rsi
    # 4.76 m2•K/W or R27). Taking into account air film resistances and
    # non-insulating layer resistances (e.g. ~Rsi 1 m2•K/W), the prescribed
    # (max) layer Ut becomes ~0.277 (Rsi 3.6 or R20.5).
    #
    #   0.277 = Uo? + 0.309
    #
    # Duh-oh! Even with an infinitely thick insulation layer (Uo ~= 0), it
    # would be impossible to reach NECB2017/2020 prescritive requirements with
    # "efficient" thermal breaks. Solutions? Eliminate windows :\ Otherwise,
    # further improve detailing as to achieve ~0.1 W/K per linear metre
    # (easier said than done). Here, an average PSI-factor of 0.150 W/K per
    # linear metre (i.e. ~76.1 W/K instead of ~84.6 W/K) still won't cut it
    # for a Uo of 0.01 W/m2•K (Rsi 100 or R568). Instead, an average PSI-factor
    # of 0.090 (~45.6 W/K, very high performance) would allow compliance for a
    # Uo of 0.1 W/m2•K (Rsi 10 or R57, ... $$$).
    #
    # Long story short: there will inevitably be cases where TBD is unable to
    # "uprate" a construction prior to "derating". This is neither a TBD bug
    # nor an RP-1365/ISO model limitation. It is simply "bad" input, although
    # likely unintentional. Nevertheless, TBD should exit in such cases with
    # an ERROR message.
    #
    # And if one were to instead model each of the OpenStudio walls described
    # above as 2x distinct OpenStudio surfaces? e.g.:
    #   - 95% of exposed wall area Uo 0.01 W/m2•K
    #   - 5% of exposed wall area as a "thermal bridge" strip (~5.6 W/m2•K *)
    #
    #     * (76.1 W/K over 5% of 273.6 m2)
    #
    # One would still consistently arrive at the same area-weighted average
    # Ut, in this case 0.288 (> 0.277). No free lunches.
    #
    # ---
    #
    # TBD's "uprating" method reorders the equation and attempts the
    # following:
    #
    #   Uo = 0.277 - ( ∑psi • L )/A
    #
    # The method exits with an ERROR in 2x cases:
    #   - calculated Uo is negative, i.e. ( ∑psi • L )/A > 0.277
    #   - calculated layer r violates E+ material constraints, e.g.
    #     - too conductive
    #     - too thin

    # -- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- -- #
    # Retrying the previous example, yet requesting uprating calculations:
    TBD.clean!

    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    argh                = {}
    argh[:option      ] = "efficient (BETBG)" # all PSI-factors @ 0.2 W/K•m
    argh[:uprate_walls] = true
    argh[:uprate_roofs] = true
    argh[:wall_option ] = "ALL wall constructions"
    argh[:roof_option ] = "ALL roof constructions"
    argh[:wall_ut     ] = 0.210 # NECB CZ7 2017 (RSi 4.76 / R27)
    argh[:roof_ut     ] = 0.138 # NECB CZ7 2017 (RSi 7.25 / R41)

    json     = TBD.process(model, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.error?).to be true
    expect(TBD.logs.size).to eq(2)
    expect(TBD.logs.first[:message]).to include("Zero")
    expect(TBD.logs.first[:message]).to include(": new Rsi")
    expect(TBD.logs.last[ :message]).to include("Unable to uprate")

    expect(argh).to_not have_key(:wall_uo)
    expect(argh).to     have_key(:roof_uo)
    expect(argh[:roof_uo]).to_not be_nil
    expect(argh[:roof_uo]).to be_within(TOL).of(0.118) # RSi 8.47 (R48)

    # -- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- -- #
    # Final attempt, with PSI-factors of 0.09 W/K per linear metre (JSON file).
    TBD.clean!

    walls = []
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    argh                = {}
    argh[:io_path     ] = File.join(__dir__, "../json/tbd_5ZoneNoHVAC.json")
    argh[:schema_path ] = File.join(__dir__, "../tbd.schema.json")
    argh[:uprate_walls] = true
    argh[:uprate_roofs] = true
    argh[:wall_option ] = "ALL wall constructions"
    argh[:roof_option ] = "ALL roof constructions"
    argh[:wall_ut     ] = 0.210 # NECB CZ7 2017 (RSi 4.76 / R27)
    argh[:roof_ut     ] = 0.138 # NECB CZ7 2017 (RSi 7.25 / R41)

    json      = TBD.process(model, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io        = json[:io      ]
    surfaces  = json[:surfaces]
    expect(TBD.status).to be_zero

    expect(argh).to have_key(:wall_uo)
    expect(argh).to have_key(:roof_uo)
    expect(argh[:wall_uo]).to_not be_nil
    expect(argh[:roof_uo]).to_not be_nil
    expect(argh[:wall_uo]).to be_within(TOL).of(0.086) # RSi 11.63 (R66)
    expect(argh[:roof_uo]).to be_within(TOL).of(0.129) # RSi  7.75 (R44)

    model.getSurfaces.each do |s|
      next unless s.surfaceType == "Wall"
      next unless s.outsideBoundaryCondition == "Outdoors"

      walls << s.nameString
      c = s.construction
      expect(c).to_not be_empty
      c = c.get.to_LayeredConstruction
      expect(c).to_not be_empty
      c = c.get

      expect(c.nameString).to include(" c tbd")
      expect(c.layers.size).to eq(4)

      insul = c.layers[2].to_StandardOpaqueMaterial
      expect(insul).to_not be_empty
      insul = insul.get
      expect(insul.nameString).to include(" uprated m tbd")

      k1 = (insul.thermalConductivity - 0.0261).round(4) == 0
      k2 = (insul.thermalConductivity - 0.0253).round(4) == 0
      expect(k1 || k2).to be true
      expect(insul.thickness).to be_within(0.0001).of(0.1120)
    end

    walls.each do |wall|
      expect(surfaces).to have_key(wall)
      expect(surfaces[wall]).to have_key(:r) # uprated, non-derated layer Rsi
      expect(surfaces[wall]).to have_key(:u) # uprated, non-derated assembly
      expect(surfaces[wall][:r]).to be_within(0.001).of(11.205) # R64
      expect(surfaces[wall][:u]).to be_within(0.001).of( 0.086) # R66
    end

    # -- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- -- #
    # Realistic, BTAP-costed PSI-factors.
    TBD.clean!

    jpath = "../json/tbd_5ZoneNoHVAC_btap.json"
    file  = File.join(__dir__, "files/osms/in/5ZoneNoHVAC.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    # Assign (missing) space types.
    north = model.getSpaceByName("Story 1 North Perimeter Space")
    east  = model.getSpaceByName("Story 1 East Perimeter Space")
    south = model.getSpaceByName("Story 1 South Perimeter Space")
    west  = model.getSpaceByName("Story 1 West Perimeter Space")
    core  = model.getSpaceByName("Story 1 Core Space")

    expect(north).to_not be_empty
    expect(east ).to_not be_empty
    expect(south).to_not be_empty
    expect(west ).to_not be_empty
    expect(core ).to_not be_empty

    north = north.get
    east  = east.get
    south = south.get
    west  = west.get
    core  = core.get

    audience  = OpenStudio::Model::SpaceType.new(model)
    warehouse = OpenStudio::Model::SpaceType.new(model)
    offices   = OpenStudio::Model::SpaceType.new(model)
    sales     = OpenStudio::Model::SpaceType.new(model)
    workshop  = OpenStudio::Model::SpaceType.new(model)

    audience.setName("Audience - auditorium")
    warehouse.setName("Warehouse - fine")
    offices.setName("Office - enclosed")
    sales.setName("Sales area")
    workshop.setName("Workshop space")

    expect(north.setSpaceType(audience )).to be true
    expect( east.setSpaceType(warehouse)).to be true
    expect(south.setSpaceType(offices  )).to be true
    expect( west.setSpaceType(sales    )).to be true
    expect( core.setSpaceType(workshop )).to be true

    argh                = {}
    argh[:io_path     ] = File.join(__dir__, jpath)
    argh[:schema_path ] = File.join(__dir__, "../tbd.schema.json")
    argh[:uprate_walls] = true
    argh[:wall_option ] = "ALL wall constructions"
    argh[:wall_ut     ] = 0.210 # NECB CZ7 2017 (RSi 4.76 / R41)

    TBD.process(model, argh)
    expect(argh).to_not have_key(:roof_uo)

    # OpenStudio prior to v3.5.X had a 3m maximum layer thickness, reflecting a
    # previous v8.8 EnergyPlus constraint. TBD caught such cases when uprating
    # (as per NECB requirements). From v3.5.0+, OpenStudio dropped the maximum
    # layer thickness limit, harmonizing with EnergyPlus:
    #
    #   https://github.com/NREL/OpenStudio/pull/4622
    #
    # This didn't mean EnergyPlus wouldn't halt a simulation due to invalid CTF
    # calculations - happens with very thick materials. Recent 2025 TBD changes
    # have removed this check. Users of pre-v3.5.X OpenStudio should expect
    # OS-generated simulation failures when uprating (extremes cases). Achtung!
    expect(TBD.status).to be_zero
    expect(argh).to have_key(:wall_uo)
    expect(argh[:wall_uo]).to be_within(0.0001).of(UMIN) # RSi 100 (R568)

    nb = 0

    model.getSurfaces.each do |s|
      next unless s.surfaceType.downcase == "wall"

      c = s.construction
      expect(c).to_not be_empty
      c = c.get.to_LayeredConstruction
      next if c.empty?

      c = c.get
      next unless c.nameString.include?("c tbd")

      lyr = TBD.insulatingLayer(c)
      expect(lyr).to be_a(Hash)
      expect(lyr).to have_key(:type)
      expect(lyr).to have_key(:index)
      expect(lyr).to have_key(:r)
      expect(lyr[:type]).to eq(:standard)
      expect(lyr[:index]).to be_between(0, c.numLayers)
      insul = c.getLayer(lyr[:index])
      insul = insul.to_StandardOpaqueMaterial
      expect(insul).to_not be_empty
      insul = insul.get
      expect(insul.thickness).to be_within(TOL).of(1.00)

      nb += 1
    end

    expect(nb).to eq(4)
  end

  it "can pre-process UA parameters" do
    translator = OpenStudio::OSVersion::VersionTranslator.new
    TBD.clean!

    ref   = "code (Quebec)"
    file  = File.join(__dir__, "files/osms/in/warehouse.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    heated = TBD.heatingTemperatureSetpoints?(model)
    cooled = TBD.coolingTemperatureSetpoints?(model)
    expect(heated).to be true
    expect(cooled).to be true

    model.getSpaces.each do |space|
      expect(TBD.unconditioned?(space)).to be false
      stpts = TBD.setpoints(space)
      expect(stpts).to be_a(Hash)
      expect(stpts).to have_key(:heating)
      expect(stpts).to have_key(:cooling)

      heating = stpts[:heating]
      cooling = stpts[:cooling]
      expect(heating).to be_a(Numeric)
      expect(cooling).to be_a(Numeric)

      if space.nameString == "Zone1 Office"
        expect(heating).to be_within(0.1).of(21.1)
        expect(cooling).to be_within(0.1).of(23.9)
      elsif space.nameString == "Zone2 Fine Storage"
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
            l: "Bulk Storage Right Wall"
          }.freeze

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
            n: "Overhead Door 7"
          }.freeze

    psi   = TBD::PSI.new
    shrts = psi.shorthands(ref)

    expect(shrts[:has]).to_not be_empty
    expect(shrts[:val]).to_not be_empty
    has = shrts[:has]
    val = shrts[:val]

    expect(has).to_not be_empty
    expect(val).to_not be_empty

    argh               = {}
    argh[:option     ] = "poor (BETBG)"
    argh[:seed       ] = "./files/osms/in/warehouse.osm"
    argh[:io_path    ] = File.join(__dir__, "../json/tbd_warehouse10.json")
    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")
    argh[:gen_ua     ] = true
    argh[:ua_ref     ] = ref
    argh[:version    ] = OpenStudio.openStudioVersion

    TBD.process(model, argh)
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty

    expect(argh).to have_key(:surfaces)
    expect(argh).to have_key(:io)
    expect(argh[:surfaces]).to be_a(Hash)
    expect(argh[:surfaces].size).to eq(23)

    expect(argh[:io]).to be_a(Hash)
    expect(argh[:io]).to_not be_empty
    expect(argh[:io]).to have_key(:edges)
    expect(argh[:io][:edges].size).to eq(300)

    argh[:io][:description] = "test"
    # Set up 2x heating setpoint (HSTP) "blocks":
    #   bloc1: spaces/zones with HSTP >= 18C
    #   bloc2: spaces/zones with HSTP < 18C
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
      expect(surface).to have_key(:deratable)
      next unless surface[:deratable]

      expect(ids).to have_value(id)
      expect(surface).to have_key(:type)
      expect(surface).to have_key(:net )
      expect(surface).to have_key(:u)

      expect(surface[:net] > TOL).to be true
      expect(surface[:u  ] > TOL).to be true

      expect(surface[:u]).to be_within(TOL).of(0.48) if id == ids[:a]
      expect(surface[:u]).to be_within(TOL).of(0.48) if id == ids[:b]
      expect(surface[:u]).to be_within(TOL).of(0.31) if id == ids[:c]
      expect(surface[:u]).to be_within(TOL).of(0.48) if id == ids[:d]
      expect(surface[:u]).to be_within(TOL).of(0.48) if id == ids[:e]
      expect(surface[:u]).to be_within(TOL).of(0.48) if id == ids[:f]
      expect(surface[:u]).to be_within(TOL).of(0.48) if id == ids[:g]
      expect(surface[:u]).to be_within(TOL).of(0.48) if id == ids[:h]
      expect(surface[:u]).to be_within(TOL).of(0.55) if id == ids[:i]
      expect(surface[:u]).to be_within(TOL).of(0.64) if id == ids[:j]
      expect(surface[:u]).to be_within(TOL).of(0.64) if id == ids[:k]
      expect(surface[:u]).to be_within(TOL).of(0.64) if id == ids[:l]

      # Reference values.
      expect(surface).to have_key(:ref)

      expect(surface[:ref]).to be_within(TOL).of(0.28) if id == ids[:a]
      expect(surface[:ref]).to be_within(TOL).of(0.28) if id == ids[:b]
      expect(surface[:ref]).to be_within(TOL).of(0.18) if id == ids[:c]
      expect(surface[:ref]).to be_within(TOL).of(0.28) if id == ids[:d]
      expect(surface[:ref]).to be_within(TOL).of(0.28) if id == ids[:e]
      expect(surface[:ref]).to be_within(TOL).of(0.28) if id == ids[:f]
      expect(surface[:ref]).to be_within(TOL).of(0.28) if id == ids[:g]
      expect(surface[:ref]).to be_within(TOL).of(0.28) if id == ids[:h]
      expect(surface[:ref]).to be_within(TOL).of(0.23) if id == ids[:i]
      expect(surface[:ref]).to be_within(TOL).of(0.34) if id == ids[:j]
      expect(surface[:ref]).to be_within(TOL).of(0.34) if id == ids[:k]
      expect(surface[:ref]).to be_within(TOL).of(0.34) if id == ids[:l]

      expect(surface).to have_key(:heating)
      expect(surface).to have_key(:cooling)
      bloc = bloc1
      bloc = bloc2 if surface[:heating] < 18

      if surface[:type ] == :wall
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
          expect(id2).to have_value(i)
          expect(door).to_not have_key(:glazed)
          expect(door).to have_key(:gross )
          expect(door).to have_key(:u)
          expect(door).to have_key(:ref)
          expect(door[:gross] > TOL).to be true
          expect(door[:ref  ] > TOL).to be true
          expect(door[:u    ] > TOL).to be true
          expect(door[:u    ]).to be_within(TOL).of(3.98)
          bloc[:pro][:doors] += door[:gross] * door[:u  ]
          bloc[:ref][:doors] += door[:gross] * door[:ref]
        end
      end

      if surface.key?(:skylights)
        surface[:skylights].each do |i, skylight|
          expect(skylight).to have_key(:gross)
          expect(skylight).to have_key(:u)
          expect(skylight).to have_key(:ref)
          expect(skylight[:gross] > TOL).to be true
          expect(skylight[:ref  ] > TOL).to be true
          expect(skylight[:u    ] > TOL).to be true
          expect(skylight[:u    ]).to be_within(TOL).of(6.64)
          bloc[:pro][:skylights] += skylight[:gross] * skylight[:u  ]
          bloc[:ref][:skylights] += skylight[:gross] * skylight[:ref]
        end
      end

      id3 = { a: "Office Front Wall Window 1",
              b: "Office Front Wall Window2"
            }.freeze

      if surface.key?(:windows)
        surface[:windows].each do |i, window|
          expect(window).to have_key(:u)
          expect(window).to have_key(:ref)
          expect(window[:ref] > TOL).to be true

          bloc[:pro][:windows] += window[:gross] * window[:u  ]
          bloc[:ref][:windows] += window[:gross] * window[:ref]

          expect(window[:u    ] > 0).to be true
          expect(window[:u    ]).to be_within(TOL).of(4.00) if i == id3[:a]
          expect(window[:u    ]).to be_within(TOL).of(3.50) if i == id3[:b]
          expect(window[:gross]).to be_within(TOL).of(5.58) if i == id3[:a]
          expect(window[:gross]).to be_within(TOL).of(5.58) if i == id3[:b]

          next if [id3[:a], id3[:b]].include?(i)

          expect(window[:gross]).to be_within(TOL).of(3.25)
          expect(window[:u    ]).to be_within(TOL).of(2.35)
        end
      end

      if surface.key?(:edges)
        surface[:edges].values.each do |edge|
          expect(edge).to have_key(:type )
          expect(edge).to have_key(:ratio)
          expect(edge).to have_key(:ref  )
          expect(edge).to have_key(:psi  )
          next unless edge[:psi] > TOL

          tt = psi.safe(ref, edge[:type])
          expect(tt).to_not be_nil

          expect(edge[:ref]).to be_within(TOL).of(val[tt] * edge[:ratio])
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
          when :door
            expect(rate).to be_within(0.1).of(40.0)
            bloc[:pro][:trim     ] += edge[:length] * edge[:psi  ]
            bloc[:ref][:trim     ] += edge[:length] * edge[:ratio] * val[tt]
          when :skylight
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
          expect(pts).to have_key(:val)
          expect(pts).to have_key(:n)
          expect(pts).to have_key(:ref)
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

    bloc1_pro_UA = bloc1[:pro].values.sum
    bloc1_ref_UA = bloc1[:ref].values.sum
    bloc2_pro_UA = bloc2[:pro].values.sum
    bloc2_ref_UA = bloc2[:ref].values.sum

    expect(bloc1_pro_UA).to be_within(0.1).of( 214.8)
    expect(bloc1_ref_UA).to be_within(0.1).of( 107.2)
    expect(bloc2_pro_UA).to be_within(0.1).of(4863.6)
    expect(bloc2_ref_UA).to be_within(0.1).of(2275.4)

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

    # Testing summaries function.
    ua = TBD.ua_summary(Time.now, argh)
    expect(ua).to_not be_nil
    expect(ua).to_not be_empty
    expect(ua).to be_a(Hash)
    expect(ua).to have_key(:model)
    expect(ua).to have_key(:fr)

    expect(ua[:fr]).to have_key(:objective)
    expect(ua[:fr]).to have_key(:details)
    expect(ua[:fr]).to have_key(:areas)
    expect(ua[:fr]).to have_key(:notes)

    expect(ua[:fr][:objective]).to_not be_empty

    expect(ua[:fr][:details]).to be_a(Array)
    expect(ua[:fr][:details]).to_not be_empty

    expect(ua[:fr][:areas]).to be_a(Hash)
    expect(ua[:fr][:areas]).to_not be_empty
    expect(ua[:fr][:areas]).to have_key(:walls)
    expect(ua[:fr][:areas]).to have_key(:roofs)
    expect(ua[:fr][:areas]).to_not have_key(:floors)
    expect(ua[:fr][:notes]).to_not be_empty

    expect(ua[:fr]).to have_key(:b1)
    expect(ua[:fr][:b1]).to_not be_empty
    expect(ua[:fr][:b1]).to have_key(:summary)
    expect(ua[:fr][:b1]).to have_key(:walls)
    expect(ua[:fr][:b1]).to have_key(:doors)
    expect(ua[:fr][:b1]).to have_key(:windows)
    expect(ua[:fr][:b1]).to have_key(:rimjoists)
    expect(ua[:fr][:b1]).to have_key(:trim)
    expect(ua[:fr][:b1]).to have_key(:corners)
    expect(ua[:fr][:b1]).to have_key(:grade)
    expect(ua[:fr][:b1]).to_not have_key(:roofs)
    expect(ua[:fr][:b1]).to_not have_key(:floors)
    expect(ua[:fr][:b1]).to_not have_key(:skylights)
    expect(ua[:fr][:b1]).to_not have_key(:parapets)
    expect(ua[:fr][:b1]).to_not have_key(:balconies)
    expect(ua[:fr][:b1]).to_not have_key(:other)

    expect(ua[:fr]).to have_key(:b2)
    expect(ua[:fr][:b2]).to_not be_empty
    expect(ua[:fr][:b2]).to have_key(:summary)
    expect(ua[:fr][:b2]).to have_key(:walls)
    expect(ua[:fr][:b2]).to have_key(:roofs)
    expect(ua[:fr][:b2]).to have_key(:doors)
    expect(ua[:fr][:b2]).to have_key(:skylights)
    expect(ua[:fr][:b2]).to have_key(:rimjoists)
    expect(ua[:fr][:b2]).to have_key(:parapets)
    expect(ua[:fr][:b2]).to have_key(:trim)
    expect(ua[:fr][:b2]).to have_key(:corners)
    expect(ua[:fr][:b2]).to have_key(:grade)
    expect(ua[:fr][:b2]).to have_key(:other)
    expect(ua[:fr][:b2]).to_not have_key(:floors)
    expect(ua[:fr][:b2]).to_not have_key(:windows)
    expect(ua[:fr][:b2]).to_not have_key(:balconies)

    expect(ua[:en]).to have_key(:b1)
    expect(ua[:en][:b1]).to_not be_empty
    expect(ua[:en][:b1]).to have_key(:summary)
    expect(ua[:en][:b1]).to have_key(:walls)
    expect(ua[:en][:b1]).to have_key(:doors)
    expect(ua[:en][:b1]).to have_key(:windows)
    expect(ua[:en][:b1]).to have_key(:rimjoists)
    expect(ua[:en][:b1]).to have_key(:trim)
    expect(ua[:en][:b1]).to have_key(:corners)
    expect(ua[:en][:b1]).to have_key(:grade)
    expect(ua[:en][:b1]).to_not have_key(:roofs)
    expect(ua[:en][:b1]).to_not have_key(:floors)
    expect(ua[:en][:b1]).to_not have_key(:skylights)
    expect(ua[:en][:b1]).to_not have_key(:parapets )
    expect(ua[:en][:b1]).to_not have_key(:balconies)
    expect(ua[:en][:b1]).to_not have_key(:other)

    expect(ua[:en]).to have_key(:b2)
    expect(ua[:en][:b2]).to_not be_empty
    expect(ua[:en][:b2]).to have_key(:summary)
    expect(ua[:en][:b2]).to have_key(:walls)
    expect(ua[:en][:b2]).to have_key(:roofs)
    expect(ua[:en][:b2]).to have_key(:doors)
    expect(ua[:en][:b2]).to have_key(:skylights)
    expect(ua[:en][:b2]).to have_key(:rimjoists)
    expect(ua[:en][:b2]).to have_key(:parapets)
    expect(ua[:en][:b2]).to have_key(:trim)
    expect(ua[:en][:b2]).to have_key(:corners)
    expect(ua[:en][:b2]).to have_key(:grade)
    expect(ua[:en][:b2]).to have_key(:other)
    expect(ua[:en][:b2]).to_not have_key(:floors)
    expect(ua[:en][:b2]).to_not have_key(:windows)
    expect(ua[:en][:b2]).to_not have_key(:balconies)

    ud_md_en = TBD.ua_md(ua, :en)
    ud_md_fr = TBD.ua_md(ua, :fr)
    path_en  = File.join(__dir__, "files/ua/ua_en.md")
    path_fr  = File.join(__dir__, "files/ua/ua_fr.md")

    File.open(path_en, "w") { |file| file.puts ud_md_en }
    File.open(path_fr, "w") { |file| file.puts ud_md_fr }

    # Try with an incomplete reference, e.g. (non thermal bridging).
    TBD.clean!

    file  = File.join(__dir__, "files/osms/in/warehouse.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    # When faced with an edge that may be characterized by more than one thermal
    # bridge type (e.g. ground-floor door "sill" vs "grade" edge; "corner" vs
    # corner window "jamb"), TBD retains the edge type (amongst candidate edge
    # types) representing the greatest heat loss:
    #
    #   psi = edge[:psi].values.max
    #   type = edge[:psi].key(psi)
    #
    # As long as there is a slight difference in PSI-factors between candidate
    # edge types, the automated selection will be deterministic. With 2 or more
    # edge types sharing the exact same PSI-factor (e.g. 0.3 W/K per m), the
    # final edge type selection becomes less obvious. It is not randomly
    # selected, but rather based on the (somewhat arbitrary) design choice of
    # which edge type is processed first in psi.rb (line ~1300 onwards). For
    # instance, fenestration perimeters are treated before corners or parapets.
    # When dealing with equal hash values, Ruby's Hash "key" method
    # returns the first key (i.e. edge type) that matches the criterion:
    #
    #   https://docs.ruby-lang.org/en/2.0.0/Hash.html#method-i-key
    #
    # From an energy simulation results perspective, the consequences of this
    # pseudo-random choice are insignificant (i.e. ~same PSI-factor). For UA'
    # comparisons, the situation becomes less obvious in outlier cases. When a
    # reference value needs to be generated for a given edge, TBD retains the
    # original autoselected edge type, yet applies reference PSI values (e.g.
    # "code"). So far so good. However, when "(non thermal bridging)" is
    # retained as a default PSI design set (not as a reference set), all edge
    # types will necessarily have PSI-factors of 0 W/K per metre. To minimize
    # the issue, slight variations (e.g. +/- 0.000001 W/K per inear meter) have
    # been added to TBD built-in PSI-factor sets (where required). Without this
    # fix, undesirable variations in reference UA' tallies may occur.
    #
    # This overview remains an "aide-mémoire" for future guide material.
    argh[:io         ] = nil
    argh[:surfaces   ] = nil
    argh[:option     ] = "(non thermal bridging)"
    argh[:io_path    ] = nil
    argh[:schema_path] = nil
    argh[:gen_ua     ] = true
    argh[:ua_ref     ] = ref

    TBD.process(model, argh)
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty
    expect(argh).to have_key(:surfaces)
    expect(argh).to have_key(:io)

    expect(argh[:surfaces]).to be_a(Hash)
    expect(argh[:surfaces].size).to eq(23)

    expect(argh[:io]).to be_a(Hash)
    expect(argh[:io]).to have_key(:edges)
    expect(argh[:io][:edges].size).to eq(300)

    # Testing summaries function.
    argh[:io][:description] = "testing non thermal bridging"

    ua = TBD.ua_summary(Time.now, argh)
    expect(ua).to_not be_nil
    expect(ua).to be_a(Hash)
    expect(ua).to_not be_empty
    expect(ua).to have_key(:model)

    en_ud_md = TBD.ua_md(ua, :en)
    fr_ud_md = TBD.ua_md(ua, :fr)
    path_en  = File.join(__dir__, "files/ua/en_ua.md")
    path_fr  = File.join(__dir__, "files/ua/fr_ua.md")
    File.open(path_en, "w") { |file| file.puts en_ud_md }
    File.open(path_fr, "w") { |file| file.puts fr_ud_md }
  end

  it "can work off of a cloned model" do
    translator = OpenStudio::OSVersion::VersionTranslator.new
    TBD.clean!

    argh1 = { option: "poor (BETBG)" }
    argh2 = { option: "poor (BETBG)" }
    argh3 = { option: "poor (BETBG)" }

    file  = File.join(__dir__, "files/osms/in/warehouse.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get
    mdl   = model.clone
    fil   = File.join(__dir__, "files/osms/out/alt_warehouse.osm")
    mdl.save(fil, true)

    # Despite one being the clone of the other, files will not be identical,
    # namely due to unique handles.
    expect(FileUtils).to_not be_identical(file, fil)

    TBD.process(model, argh1)
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty

    expect(argh1).to have_key(:surfaces)
    expect(argh1).to have_key(:io)

    expect(argh1[:surfaces]).to be_a(Hash)
    expect(argh1[:surfaces].size).to eq(23)

    expect(argh1[:io]).to be_a(Hash)
    expect(argh1[:io]).to have_key(:edges)
    expect(argh1[:io][:edges].size).to eq(300)

    out  = JSON.pretty_generate(argh1[:io])
    outP = File.join(__dir__, "../json/tbd_warehouse12.out.json")
    File.open(outP, "w") { |outP| outP.puts out }

    TBD.clean!
    fil  = File.join(__dir__, "files/osms/out/alt_warehouse.osm")
    pth  = OpenStudio::Path.new(fil)
    mdl  = translator.loadModel(pth)
    expect(mdl).to_not be_empty
    mdl  = mdl.get

    TBD.process(mdl, argh2)
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty

    expect(argh2).to have_key(:surfaces)
    expect(argh2).to have_key(:io)

    expect(argh2[:surfaces]).to be_a(Hash)
    expect(argh2[:surfaces].size).to eq(23)

    expect(argh2[:io]).to be_a(Hash)
    expect(argh2[:io]).to have_key(:edges)
    expect(argh2[:io][:edges].size).to eq(300)

    # The JSON output files are identical.
    out2  = JSON.pretty_generate(argh2[:io])
    outP2 = File.join(__dir__, "../json/tbd_warehouse13.out.json")
    File.open(outP2, "w") { |outP2| outP2.puts out2 }
    expect(FileUtils).to be_identical(outP, outP2)

    time = Time.now

    # Original output UA' MD file.
    argh1[:ua_ref          ] = "code (Quebec)"
    argh1[:io][:description] = "testing equality"
    argh1[:version         ] = OpenStudio.openStudioVersion
    argh1[:seed            ] = File.join(__dir__, "files/osms/in/warehouse.osm")

    o_ua = TBD.ua_summary(time, argh1)
    expect(o_ua).to_not be_nil
    expect(o_ua).to_not be_empty
    expect(o_ua).to be_a(Hash)
    expect(o_ua).to have_key(:model)

    o_ud_md_en = TBD.ua_md(o_ua, :en)
    path1      = File.join(__dir__, "files/ua/o_ua_en.md")
    File.open(path1, "w") { |file| file.puts o_ud_md_en }

    # Alternate output UA' MD file.
    argh2[:ua_ref          ] = "code (Quebec)"
    argh2[:io][:description] = "testing equality"
    argh2[:version         ] = OpenStudio.openStudioVersion
    argh2[:seed            ] = File.join(__dir__, "files/osms/in/warehouse.osm")

    alt_ua = TBD.ua_summary(time, argh2)
    expect(alt_ua).to_not be_nil
    expect(alt_ua).to_not be_empty
    expect(alt_ua).to be_a(Hash)
    expect(alt_ua).to have_key(:model)

    alt_ud_md_en = TBD.ua_md(alt_ua, :en)
    path2        = File.join(__dir__, "files/ua/alt_ua_en.md")
    File.open(path2, "w") { |file| file.puts alt_ud_md_en }

    # Both output UA' MD files should be identical.
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty
    expect(FileUtils).to be_identical(path1, path2)

    # Testing the Macumber suggestion (thumbs' up).
    TBD.clean!

    file  = File.join(__dir__, "files/osms/in/warehouse.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    mdl2 = OpenStudio::Model::Model.new
    mdl2.addObjects(model.toIdfFile.objects)
    fil2 = File.join(__dir__, "files/osms/out/alt2_warehouse.osm")
    mdl2.save(fil2, true)

    # Still get the differences in handles (not consequential at all if the TBD
    # JSON output files are identical).
    expect(FileUtils).to_not be_identical(file, fil2)

    TBD.process(mdl2, argh3)
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty

    expect(argh3).to have_key(:surfaces)
    expect(argh3).to have_key(:io)

    expect(argh3[:surfaces]).to be_a(Hash)
    expect(argh3[:surfaces].size).to eq(23)

    expect(argh3[:io]).to be_a(Hash)
    expect(argh3[:io]).to have_key(:edges)
    expect(argh3[:io][:edges].size).to eq(300)

    out3  = JSON.pretty_generate(argh3[:io])
    outP3 = File.join(__dir__, "../json/tbd_warehouse14.out.json")
    File.open(outP3, "w") { |outP3| outP3.puts out3 }

    # Nice. Both TBD JSON output files are identical!
    # "/../json/tbd_warehouse12.out.json" vs "/../json/tbd_warehouse14.out.json"
    expect(FileUtils).to be_identical(outP, outP3)
  end

  it "can generate and access KIVA inputs (seb)" do
    translator = OpenStudio::OSVersion::VersionTranslator.new
    TBD.clean!

    # --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- #
    file  = File.join(__dir__, "files/osms/out/seb2.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    # Fetch all 5 outdoor-facing walls of the Open Area space.
    oa13ID = "Openarea 1 Wall 3"
    oa14ID = "Openarea 1 Wall 4"
    oa15ID = "Openarea 1 Wall 5"
    oa16ID = "Openarea 1 Wall 6"
    oa17ID = "Openarea 1 Wall 7"
    oaIDs  = [oa13ID, oa14ID, oa15ID, oa16ID, oa17ID]

    oa13 = model.getSurfaceByName(oa13ID)
    oa14 = model.getSurfaceByName(oa14ID)
    oa15 = model.getSurfaceByName(oa15ID)
    oa16 = model.getSurfaceByName(oa16ID)
    oa17 = model.getSurfaceByName(oa17ID)
    expect(oa13).to_not be_empty
    expect(oa14).to_not be_empty
    expect(oa15).to_not be_empty
    expect(oa16).to_not be_empty
    expect(oa17).to_not be_empty
    oa13 = oa13.get
    oa14 = oa14.get
    oa15 = oa15.get
    oa16 = oa16.get
    oa17 = oa17.get

    woa13 = TBD.alignedWidth(oa13)
    woa14 = TBD.alignedWidth(oa14)
    woa15 = TBD.alignedWidth(oa15)
    woa16 = TBD.alignedWidth(oa16)
    woa17 = TBD.alignedWidth(oa17)
    expect(woa13.round(2)).to eq(2.29)
    expect(woa14.round(2)).to eq(2.14)
    expect(woa15.round(2)).to eq(3.89)
    expect(woa16.round(2)).to eq(2.45)
    expect(woa17.round(2)).to eq(1.82)

    # Assert 'exposed perimeter' of the Open Area space.
    exp = woa13 + woa14 + woa15 + woa16 + woa17
    expect(exp.round(2)).to eq(12.59)

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
    expect(oa1f).to_not be_empty
    oa1f = oa1f.get

    expect(oa1f.setOutsideBoundaryCondition("Foundation")).to be true
    oa1f.setAdjacentFoundation(kiva_slab_2020s)
    construction = oa1f.construction
    expect(construction).to_not be_empty
    construction = construction.get
    expect(oa1f.setConstruction(construction)).to be true

    arg = "TotalExposedPerimeter"
    per = oa1f.createSurfacePropertyExposedFoundationPerimeter(arg, exp)
    expect(per).to_not be_empty

    file = File.join(__dir__, "files/osms/out/seb_KIVA.osm")
    model.save(file, true)


    # --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- #
    # Re-open for testing.
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    oa1f = model.getSurfaceByName("Open area 1 Floor")
    expect(oa1f).to_not be_empty
    oa1f = oa1f.get

    expect(oa1f.outsideBoundaryCondition.downcase).to eq("foundation")
    foundation = oa1f.adjacentFoundation
    expect(foundation).to_not be_empty
    foundation = foundation.get

    oa15 = model.getSurfaceByName(oa15ID)
    expect(oa15).to_not be_empty
    oa15 = oa15.get

    construction = oa15.construction.get
    expect(oa15.setOutsideBoundaryCondition("Foundation")).to be true
    expect(oa15.setAdjacentFoundation(foundation)).to be true
    expect(oa15.setConstruction(construction)).to be true

    kfs = model.getFoundationKivas
    expect(kfs).to_not be_empty
    expect(kfs.size).to eq(4)
    expect(model.foundationKivaSettings).to be_empty

    argh            = {}
    argh[:option  ] = "poor (BETBG)"
    argh[:gen_kiva] = true

    json     = TBD.process(model, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.error?).to be true
    expect(TBD.logs.size).to eq(1)
    expect(TBD.logs.first[:message]).to include("Exiting - KIVA objects in ")
    expect(surfaces).to be_a(Hash)
    expect(surfaces.size).to eq(56)
    expect(io).to be_a(Hash)
    expect(io).to have_key(:edges)

    # 105x edges (-1x than the usual 106x for the seb2.osm). The edge linking
    # "Open area 1 Floor" to "Openarea 1 Wall 5" used to be of type :grade. As
    # both slab and wall are now ground-facing, TBD ignores the edge altogether.
    expect(io[:edges].size).to eq(105)
    expect(model.foundationKivaSettings).to be_empty
    expect(model.getSurfacePropertyExposedFoundationPerimeters.size).to eq(1)
    expect(model.getFoundationKivas.size).to eq(4)

    # TBD derates (above-grade) surfaces as usual. TBD is certainly 'aware' of
    # the "Foundation"-facing slab and wall (and their shared edge), yet exits
    # the KIVA generation step. As the warning message suggests, TBD safely
    # exits when the OpenStudio model already holds KIVA objects.
    surfaces.values.each { |surface| expect(surface).to_not have_key(:kiva) }

    # As with the previously altered "files/osms/out/seb_KIVA.osm", OpenStudio
    # can forward-translate and run an EnergyPlus simulation without warnings or
    # errors. As "Openarea 1 Wall 5" is now a "Foundation"-facing wall, the
    # exposed foundation perimeter length (set previously) is now invalid. Yet
    # there are no internal checks in OpenStudio and/or EnergyPlus to ensure
    # perimeter length consistency, WHEN exposed + foundation perimeter
    # lengths < total slab perimeter lengths. Simulation runs without a glitch;
    # simulation results would be 'off'.
    file = File.join(__dir__, "files/osms/out/seb_KIVA2.osm")
    model.save(file, true)


    # --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- #
    # Try again, yet by first purging existing KIVA objects in the model.
    TBD.clean!
    file  = File.join(__dir__, "files/osms/out/seb_KIVA.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    kfs = model.getFoundationKivas
    expect(kfs).to_not be_empty
    expect(kfs.size).to eq(4)
    expect(model.foundationKivaSettings).to be_empty

    oa1f = model.getSurfaceByName("Open area 1 Floor")
    expect(oa1f).to_not be_empty
    oa1f = oa1f.get

    expect(oa1f.outsideBoundaryCondition.downcase).to eq("foundation")
    foundation = oa1f.adjacentFoundation
    expect(foundation).to_not be_empty

    srfIDs = ["Open area 1 Floor"]

    # Incrementally change Open Area outdoor-facing walls to foundation-facing,
    # and ensure KIVA reset works. Exposed perimeter should remain the same.
    oaIDs.each_with_index do |oaID, i|
      i3 = i + 3

      oa1f = model.getSurfaceByName("Open area 1 Floor")
      expect(oa1f).to_not be_empty
      oa1f = oa1f.get

      expect(oa1f.outsideBoundaryCondition.downcase).to eq("foundation")
      foundation = oa1f.adjacentFoundation
      expect(foundation).to_not be_empty

      oaWALL = model.getSurfaceByName(oaID)
      expect(oaWALL).to_not be_empty
      oaWALL = oaWALL.get

      construction = oaWALL.construction.get
      expect(oaWALL.outsideBoundaryCondition.downcase).to eq("outdoors")
      expect(oaWALL.setOutsideBoundaryCondition("Foundation")).to be true
      expect(oaWALL.setConstruction(construction)).to be true

      srfIDs << oaID

      argh              = {}
      argh[:option    ] = "(non thermal bridging)"
      argh[:gen_kiva  ] = true
      argh[:reset_kiva] = true

      json     = TBD.process(model, argh)
      expect(json).to be_a(Hash)
      expect(json).to have_key(:io)
      expect(json).to have_key(:surfaces)
      io       = json[:io      ]
      surfaces = json[:surfaces]
      expect(TBD.info?).to be true
      expect(TBD.logs.size).to eq(i + 1)

      TBD.logs.each do |lg|
        expect(lg[:message]).to include("Purged KIVA objects from ")
      end

      expect(surfaces).to be_a(Hash)
      expect(surfaces.size).to eq(56)
      expect(io).to be_a(Hash)
      expect(io).to have_key(:edges)
      expect(io[:edges].size).to eq(105 - 2 * i)
      expect(model.foundationKivaSettings).to_not be_empty
      expect(model.getSurfacePropertyExposedFoundationPerimeters.size).to eq(1)
      expect(model.getFoundationKivas.size).to eq(1) # !4 ... previously purged

      perimeter = model.getSurfacePropertyExposedFoundationPerimeters.first
      expect(perimeter.totalExposedPerimeter).to_not be_empty
      expect(perimeter.totalExposedPerimeter.get.round(2)).to eq(exp.round(2))

      # By default, KIVA foundation objects have a 200mm 'wall height above
      # grade' value, i.e. a top, 8-in section exposed to outdoor air. This
      # seems to generate the following EnergyPlus warning:
      #
      #   ** Warning ** BuildingSurface:Detailed="OPENAREA 1 WALL 5", Sun Exposure="SUNEXPOSED".
      #   **   ~~~   ** ..This surface is not exposed to External Environment.  Sun exposure has no effect.
      #
      # Initial attempts to get rid of the warning include resetting both wind
      # and sun exposure AFTER setting boundary conditions to "Foundation", e.g.
      #
      #   expect(wall.setOutsideBoundaryCondition("Foundation")).to be true
      #   expect(wall.setWindExposure("NoWind")).to be true
      #   expect(wall.setSunExposure("NoSun")).to be true
      #
      # Alas, both "exposures" end up being reset in the saved OSM. One solution
      # is to first set the 'wall height above grade' value to 0. Works.
      kf  = model.getFoundationKivas.first
      expect(kf.isWallHeightAboveGradeDefaulted).to be true
      expect(kf.wallHeightAboveGrade.round(1)).to eq(0.2)
      expect(kf.setWallHeightAboveGrade(0)).to be true
      expect(kf.isWallHeightAboveGradeDefaulted).to be false
      expect(kf.wallHeightAboveGrade.round).to eq(0)

      ewalls = TBD.facets(model.getSpaces, "foundation", "wall")
      expect(ewalls.size).to eq(i + 1)

      ewalls.each do |wall|
        expect(wall.setWindExposure("NoWind")).to be true
        expect(wall.setSunExposure("NoSun")).to be true
      end

      found_floor = false
      found_walls = false

      surfaces.each do |id, surface|
        next unless surface.key?(:kiva)

        expect(srfIDs).to include(id)

        if id == "Open area 1 Floor"
          expect(surface[:kiva]).to eq(:basement)
          expect(surface).to have_key(:exposed)
          expect(surface[:exposed]).to be_within(TOL).of(exp)
          found_floor = true
        else
          expect(surface[:kiva]).to eq("Open area 1 Floor")
          found_walls = true
        end
      end

      expect(found_floor).to be true
      expect(found_walls).to be true
    end

    file = File.join(__dir__, "files/osms/out/seb_KIVA3.osm")
    model.save(file, true)


    # --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- #
    # Test initial model again.
    TBD.clean!
    file  = File.join(__dir__, "files/osms/out/seb2.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    # Add "Foundation" as outside boundary condition to slabs, WITHOUT adding
    # any other KIVA-related objects.
    model.getSurfaces.each do |s|
      next unless s.isGroundSurface
      next unless s.surfaceType.downcase == "floor"

      expect(s.setOutsideBoundaryCondition("Foundation")).to be true
    end

    argh            = {}
    argh[:option  ] = "(non thermal bridging)"
    argh[:gen_kiva] = true

    json     = TBD.process(model, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty
    expect(surfaces).to be_a(Hash)
    expect(surfaces.size).to eq(56)
    expect(io).to be_a(Hash)
    expect(io).to have_key(:edges)
    expect(io[:edges].size).to eq(106)

    slabs = 0

    surfaces.each do |id, s|
      next unless s.key?(:kiva)

      slabs += 1
      expect(s).to have_key(:exposed)
      slab = model.getSurfaceByName(id)
      expect(slab).to_not be_empty
      slab = slab.get

      expect(slab.adjacentFoundation).to_not be_empty
      perimeter = slab.surfacePropertyExposedFoundationPerimeter
      expect(perimeter).to_not be_empty
      perimeter = perimeter.get

      per = perimeter.totalExposedPerimeter
      expect(per).to_not be_empty
      per = per.get
      expect((per - s[:exposed]).abs).to be_within(TOL).of(0)

      expect(per).to be_within(TOL).of( 8.81) if id == "Small office 1 Floor"
      expect(per).to be_within(TOL).of( 8.21) if id == "Utility 1 Floor"
      expect(per).to be_within(TOL).of(12.59) if id == "Open area 1 Floor"
      expect(per).to be_within(TOL).of( 6.95) if id == "Entry way  Floor"
    end

    expect(slabs).to eq(4)

    file = File.join(__dir__, "files/osms/out/seb_KIVA4.osm")
    model.save(file, true)


    # --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- #
    # Recover KIVA-populated model and re- set/gen KIVA.
    argh              = {}
    argh[:option    ] = "(non thermal bridging)"
    argh[:gen_kiva  ] = true
    argh[:reset_kiva] = true

    json     = TBD.process(model, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.info?).to be true
    expect(TBD.logs.size).to eq(1)
    expect(TBD.logs.first[:message]).to include("Purged KIVA objects from ")
    expect(surfaces).to be_a(Hash)
    expect(surfaces.size).to eq(56)
    expect(io).to be_a(Hash)
    expect(io).to have_key(:edges)
    expect(io[:edges].size).to eq(106)

    slabs = 0

    # Same outcome as "seb_KIVA4.osm".
    surfaces.each do |id, s|
      next unless s.key?(:kiva)

      slabs += 1
      expect(s).to have_key(:exposed)
      slab = model.getSurfaceByName(id)
      expect(slab).to_not be_empty
      slab = slab.get

      expect(slab.adjacentFoundation).to_not be_empty
      perimeter = slab.surfacePropertyExposedFoundationPerimeter
      expect(perimeter).to_not be_empty
      perimeter = perimeter.get

      per = perimeter.totalExposedPerimeter
      expect(per).to_not be_empty
      per = per.get
      expect((per - s[:exposed]).abs).to be_within(TOL).of(0)

      expect(per).to be_within(TOL).of( 8.81) if id == "Small office 1 Floor"
      expect(per).to be_within(TOL).of( 8.21) if id == "Utility 1 Floor"
      expect(per).to be_within(TOL).of(12.59) if id == "Open area 1 Floor"
      expect(per).to be_within(TOL).of( 6.95) if id == "Entry way  Floor"
    end

    expect(slabs).to eq(4)

    # Forward-translating/running either "seb_KIVA4.osm" or "seb_KIVA5.osm"
    # would yield the same simulation results.
    file = File.join(__dir__, "files/osms/out/seb_KIVA5.osm")
    model.save(file, true)


    # --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- #
    # Recover KIVA-populated model and re-gen KIVA ... WITHOUT resetting KIVA.
    TBD.clean!
    argh            = {}
    argh[:option  ] = "(non thermal bridging)"
    argh[:gen_kiva] = true

    json     = TBD.process(model, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.error?).to be true
    expect(TBD.logs.size).to eq(1)
    expect(TBD.logs.first[:message]).to include("Exiting - KIVA objects in ")
    expect(surfaces).to be_a(Hash)
    expect(surfaces.size).to eq(56)
    expect(io).to be_a(Hash)
    expect(io).to have_key(:edges)
    expect(io[:edges].size).to eq(106)

    # Without a resetKIVA request, TBD exits with 1x error message.
    surfaces.values.each { |surface| expect(surface).to_not have_key(:kiva) }

    # As the initial model already has valid & complete KIVA inputs, one
    # obtains the same outcome as "seb_KIVA4.osm" & "seb_KIVA5.osm".
    file = File.join(__dir__, "files/osms/out/seb_KIVA6.osm")
    model.save(file, true)
  end

  it "can purge KIVA objects" do
    translator = OpenStudio::OSVersion::VersionTranslator.new
    TBD.clean!

    file  = File.join(__dir__, "files/osms/out/seb_KIVA.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    expect(model.foundationKivaSettings).to be_empty
    expect(model.getSurfacePropertyExposedFoundationPerimeters.size).to eq(1)
    expect(model.getFoundationKivas.size).to eq(4)

    adjacents  = 0
    foundation = nil

    model.getSurfaces.each do |surface|
      next unless surface.isGroundSurface
      next     if surface.adjacentFoundation.empty?

      adjacents += 1
      foundation = surface.adjacentFoundation.get
      expect(surface.surfacePropertyExposedFoundationPerimeter).to_not be_empty
      expect(surface.outsideBoundaryCondition.downcase).to eq("foundation")
    end

    expect(adjacents).to eq(1)
    expect(foundation).to be_a(OpenStudio::Model::FoundationKiva)

    # Add 2x custom blocks for testing.
    xps = model.getMaterialByName("XPS_38mm")
    expect(xps).to_not be_empty
    xps = xps.get
    expect(foundation.addCustomBlock(xps, 0.1, 0.1, -0.5)).to be true
    expect(foundation.addCustomBlock(xps, 0.2, 0.2, -1.5)).to be true

    blocks = foundation.customBlocks
    expect(blocks).to_not be_empty

    blocks.each { |block| expect(block.material).to eq(xps) }

    # Purge.
    expect(TBD.resetKIVA(model, "Ground")).to be true
    expect(model.foundationKivaSettings).to be_empty
    expect(model.getSurfacePropertyExposedFoundationPerimeters).to be_empty
    expect(model.getFoundationKivas).to be_empty
    expect(TBD.info?).to be true
    expect(TBD.logs.size).to eq(1)
    expect(TBD.logs.first[:message]).to include("Purged KIVA objects from ")

    model.getSurfaces.each do |surface|
      next unless surface.isGroundSurface

      expect(surface.adjacentFoundation).to be_empty
      expect(surface.surfacePropertyExposedFoundationPerimeter).to be_empty
      expect(surface.outsideBoundaryCondition).to eq("Ground")
    end

    file = File.join(__dir__, "files/osms/out/seb_noKIVA.osm")
    model.save(file, true)
  end

  it "can test Hash inputs" do
    translator = OpenStudio::OSVersion::VersionTranslator.new
    TBD.clean!

    input  = {}
    schema = "https://github.com/rd2/tbd/blob/master/tbd.schema.json"
    file   = File.join(__dir__, "files/osms/out/seb2.osm")
    path   = OpenStudio::Path.new(file)
    model  = translator.loadModel(path)
    expect(model).to_not be_empty
    model  = model.get

    # Rather than reading a TBD JSON input file (e.g. "json/tbd_seb_n2.json"),
    # read in the same content as a Hash. Better for scripted batch runs.
    psis     = []
    khis     = []
    surfaces = []

    psi                 = {}
    psi[:id           ] = "good"
    psi[:parapet      ] = 0.500
    psi[:party        ] = 0.900
    psis << psi

    psi                 = {}
    psi[:id           ] = "compliant"
    psi[:rimjoist     ] = 0.300
    psi[:parapet      ] = 0.325
    psi[:fenestration ] = 0.350
    psi[:corner       ] = 0.450
    psi[:balcony      ] = 0.500
    psi[:party        ] = 0.500
    psi[:grade        ] = 0.450
    psis << psi

    khi                 = {}
    khi[:id           ] = "column"
    khi[:point        ] = 0.500
    khis << khi

    khi                 = {}
    khi[:id           ] = "support"
    khi[:point        ] = 0.500
    khis << khi

    surface             = {}
    surface[:id       ] = "Entryway  Wall 5"
    surface[:khis     ] = []
    surface[:khis     ] << { id: "column",  count: 3 }
    surface[:khis     ] << { id: "support", count: 4 }
    surfaces << surface

    input[:schema     ] = schema
    input[:description] = "testing JSON surface KHI entries"
    input[:psis       ] = psis
    input[:khis       ] = khis
    input[:surfaces   ] = surfaces

    # Export to file. Both files should be the same.
    out     = JSON.pretty_generate(input)
    pth     = File.join(__dir__, "../json/tbd_seb_n2.out.json")
    File.open(pth, "w") { |pth| pth.puts out }
    initial = File.join(__dir__, "../json/tbd_seb_n2.json")
    expect(FileUtils).to be_identical(initial, pth)

    argh                = {}
    argh[:option      ] = "(non thermal bridging)"
    argh[:io_path     ] = input
    argh[:schema_path ] = File.join(__dir__, "../tbd.schema.json")

    json     = TBD.process(model, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty
    expect(surfaces).to be_a(Hash)
    expect(surfaces.size).to eq(56)
    expect(io).to be_a(Hash)
    expect(io).to have_key(:edges)
    expect(io[:edges].size).to eq(106)

    surfaces.values.each do |surface|
      next unless surface.key?(:ratio)

      expect(surface[:heatloss]).to be_within(TOL).of(3.5)
    end
  end

  it "can check for attics vs plenums" do
    translator = OpenStudio::OSVersion::VersionTranslator.new
    TBD.clean!

    # Outdoor-facing surfaces of UNCONDITIONED spaces are never derated by TBD.
    # Yet determining whether an OpenStudio space should be considered
    # UNCONDITIONED (e.g. an attic), rather than INDIRECTLYCONDITIONED
    # (e.g. a plenum) can be tricky depending on the (incomplete) state of
    # development of an OpenStudio model. In determining the conditioning
    # status of each OpenStudio space, TBD relies on OSut methods:
    #   - 'setpoints(space)': applicable space heating/cooling setpoints
    #   - 'heatingTemperatureSetpoints?': ANY space holding heating setpoints?
    #   - 'coolingTemperatureSetpoints?': ANY space holding cooling setpoints?
    #
    # Users can consult the online OSut API documentation to know more.

    # Small office test case (UNCONDITIONED attic).
    file  = File.join(__dir__, "files/osms/in/smalloffice.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get
    attic = model.getSpaceByName("Attic")
    expect(attic).to_not be_empty
    attic = attic.get

    model.getSpaces.each do |space|
      next if space == attic

      zone = space.thermalZone
      expect(zone).to_not be_empty
      zone = zone.get
      heat = TBD.maxHeatScheduledSetpoint(zone)
      cool = TBD.minCoolScheduledSetpoint(zone)

      expect(heat[:spt]).to be_within(TOL).of(21.11)
      expect(cool[:spt]).to be_within(TOL).of(23.89)
      expect(heat[:dual]).to be true
      expect(cool[:dual]).to be true

      expect(space.partofTotalFloorArea).to be true
      expect(TBD.plenum?(space)).to be false
      expect(TBD.unconditioned?(space)).to be false
      expect(TBD.setpoints(space)[:heating]).to be_within(TOL).of(21.11)
      expect(TBD.setpoints(space)[:cooling]).to be_within(TOL).of(23.89)
    end

    zone = attic.thermalZone
    expect(zone).to_not be_empty
    zone = zone.get
    heat = TBD.maxHeatScheduledSetpoint(zone)
    cool = TBD.minCoolScheduledSetpoint(zone)

    expect(heat[:spt ]).to be_nil
    expect(cool[:spt ]).to be_nil
    expect(heat[:dual]).to be false
    expect(cool[:dual]).to be false

    expect(TBD.plenum?(attic)).to be false
    expect(TBD.unconditioned?(attic)).to be true
    expect(TBD.setpoints(attic)[:heating]).to be_nil
    expect(TBD.setpoints(attic)[:cooling]).to be_nil
    expect(attic.partofTotalFloorArea).to be false
    expect(TBD.status).to be_zero

    argh = { option: "code (Quebec)" }

    json     = TBD.process(model, argh)
    expect(TBD.status).to be_zero
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(surfaces).to be_a(Hash)
    expect(surfaces.size).to eq(43)
    expect(io).to have_key(:edges)
    expect(io[:edges].size).to eq(105)

    surfaces.each do |id, surface|
      next unless id.include?("_roof_")

      expect(id).to include("Attic")
      expect(surface).to_not have_key(:ratio)
      expect(surface).to have_key(:conditioned)
      expect(surface).to have_key(:deratable)
      expect(surface[:conditioned]).to be false
      expect(surface[:deratable]).to be false
    end

    # Now tag attic as an INDIRECTLYCONDITIONED space (linked to "Core_ZN").
    file  = File.join(__dir__, "files/osms/in/smalloffice.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get
    attic = model.getSpaceByName("Attic")
    expect(attic).to_not be_empty
    attic = attic.get

    key = "indirectlyconditioned"
    val = "Core_ZN"
    expect(attic.additionalProperties.setFeature(key, val)).to be true
    expect(TBD.plenum?(attic)).to be false
    expect(TBD.unconditioned?(attic)).to be false
    expect(TBD.setpoints(attic)[:heating]).to be_within(TOL).of(21.11)
    expect(TBD.setpoints(attic)[:cooling]).to be_within(TOL).of(23.89)
    expect(TBD.status).to be_zero

    argh = { option: "code (Quebec)" }

    json     = TBD.process(model, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.status).to be_zero
    expect(surfaces).to be_a(Hash)
    expect(surfaces.size).to eq(43)
    expect(io).to have_key(:edges)
    expect(io[:edges].size).to eq(110)

    surfaces.each do |id, surface|
      next unless id.include?("_roof_")

      expect(id).to include("Attic")
      expect(surface).to have_key(:ratio)
      expect(surface).to have_key(:conditioned)
      expect(surface).to have_key(:deratable)
      expect(surface[:conditioned]).to be true
      expect(surface[:deratable]).to be true
    end

    expect(attic.additionalProperties.resetFeature(key)).to be true

    # -- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- -- #
    # 5Zone_2 test case (as INDIRECTLYCONDITIONED plenum).
    plenum_walls   = []
    plnum_walls    = ["WALL-1PB", "WALL-1PF", "WALL-1PL", "WALL-1PR"]
    other_ceilings = ["C1-1", "C2-1", "C3-1", "C4-1", "C5-1"]

    file  = File.join(__dir__, "files/osms/in/5Zone_2.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    # The model has valid thermostats.
    heated = TBD.heatingTemperatureSetpoints?(model)
    cooled = TBD.coolingTemperatureSetpoints?(model)
    expect(heated).to be true
    expect(cooled).to be true

    plnum = model.getSpaceByName("PLENUM-1")
    expect(plnum).to_not be_empty
    plnum = plnum.get

    # The plenum is more akin to an UNCONDITIONED attic (no thermostat).
    expect(TBD.plenum?(plnum)).to be false
    expect(TBD.unconditioned?(plnum)).to be true
    expect(TBD.setpoints(plnum)[:heating]).to be_nil
    expect(TBD.setpoints(plnum)[:cooling]).to be_nil
    expect(TBD.status).to be_zero

    argh  = { option: "uncompliant (Quebec)" }

    json     = TBD.process(model, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty
    expect(surfaces).to be_a(Hash)
    expect(surfaces.size).to eq(40)
    expect(io).to be_a(Hash)
    expect(io).to have_key(:edges)

    # Plenum "walls" are not derated.
    plnum_walls.each do |s|
      expect(surfaces).to have_key(s)
      expect(surfaces[s][:deratable]).to be false
    end

    # "Other" ceilings (i.e. those of conditioned spaces, adjacent to plenum
    # "floors") are like insulated attic ceilings, and therefore derated.
    other_ceilings.each do |s|
      expect(surfaces).to have_key(s)
      expect(surfaces[s][:deratable]).to be true
    end

    # There are no above-grade "rimjoists" identified by TBD:
    expect(io[:edges].count { |edge| edge[:type] == :rimjoist      }).to eq(0)
    expect(io[:edges].count { |edge| edge[:type] == :gradeconvex   }).to eq(8)
    expect(io[:edges].count { |edge| edge[:type] == :parapetconvex }).to eq(4)

    # --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- #
    # Try again, yet first reset the plenum as INDIRECTLYCONDITIONED.
    file  = File.join(__dir__, "files/osms/in/5Zone_2.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    # Ensure the plenum is 'unoccupied', i.e. not part of the total floor area.
    plnum = model.getSpaceByName("PLENUM-1")
    expect(plnum).to_not be_empty
    plnum = plnum.get
    expect(plnum.setPartofTotalFloorArea(false)).to be true

    key = "indirectlyconditioned"
    val = "SPACE5-1"
    expect(plnum.additionalProperties.setFeature(key, val)).to be true
    expect(TBD.plenum?(plnum)).to be false
    expect(TBD.unconditioned?(plnum)).to be false
    expect(TBD.setpoints(plnum)[:heating]).to be_within(TOL).of(22.20)
    expect(TBD.setpoints(plnum)[:cooling]).to be_within(TOL).of(23.90)
    expect(TBD.status).to be_zero

    file = File.join(__dir__, "files/osms/out/z5.osm")
    model.save(file, true)

    argh = { option: "uncompliant (Quebec)" }

    json     = TBD.process(model, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty
    expect(surfaces).to be_a(Hash)
    expect(surfaces.size).to eq(40)
    expect(io).to be_a(Hash)
    expect(io).to have_key(:edges)

    # Plenum "walls" are now derated.
    plnum_walls.each do |s|
      expect(surfaces).to have_key(s)
      expect(surfaces[s][:deratable]).to be true
    end

    # "Other" ceilings (i.e. those of conditioned spaces, adjacent to plenum
    # "floors") are now like uninsulated suspended ceilings (no longer derated).
    other_ceilings.each do |s|
      expect(surfaces).to have_key(s)
      expect(surfaces[s][:deratable]).to be false
    end

    # Prior to v3.4.0, plenum floors would have been tagged as "rimjoists". No
    # longer the case ("ceilings" are caught earlier in the process).
    expect(io[:edges].count { |edge| edge[:type] == :ceiling       }).to eq(4)
    expect(io[:edges].count { |edge| edge[:type] == :rimjoist      }).to eq(0)
    expect(io[:edges].count { |edge| edge[:type] == :gradeconvex   }).to eq(8)
    expect(io[:edges].count { |edge| edge[:type] == :parapetconvex }).to eq(4)

    # There are (very) rare cases of INDIRECTLYCONDITIONED technical spaces
    # (above occupied spaces) that have structural "floors" (not e.g. suspended
    # ceiling tiles), supporting significant static and dynamic loads (e.g.
    # Louis Kahn's Salk Institute). Yet for the vast majority of cases (e.g.
    # return air plenums), we see simple suspended ceilings. Their perimeter
    # edges do not thermally bridge (or derate) insulated building envelopes.
    #
    # Prior to v3.4.0, we initially retained a laissez-faire approach with TBD
    # regarding floors of INDIRECTLYCONDITIONED spaces (like plenums). Indeed,
    # many (older?) OpenStudio models have plenum floors with 'reset' surface
    # types ("RoofCeiling"), which was sufficient for TBD to not tag such edges
    # as "rimjoists", i.e. intermediate (structural) floor slabs. Sure, TBD
    # users could always override this default behaviour by specifying spacetype
    # -specific PSI factor sets (JSON inputs), with "rimjoists" of 0 W/K per
    # meter. Yet these workarounds necessarily implied additional steps for the
    # vast majority of TBD users. As of v3.4.0, the default automated TBD
    # outcome is to tag plenum "floors" as "ceilings" (no additional steps).
    #
    # The flip side is that additional consideration may be required for less
    # common cases involving plenums. Take for instance underfloor air supply
    # plenums. The carpeted floors building occupants actually walk on are not
    # structural concrete slabs (the perimeter edges of which would constitute
    # common thermal bridges, i.e. "rimjoists"). By default, TBD will now tag
    # the raised floor as a structural "floor" (with associated thermal
    # bridging) and instead tag the actual structural slab as "ceiling".
    # Although this doesn't sound OK initially, this works out just fine for
    # most cases: the "rimjoist" edge may not line up perfectly (vertically),
    # but there remains only one per surface (a similar outcome to 'offset'
    # masonry shelf angles). Users are always free to curtomize TBD (via
    # JSON input) if needed.

    # --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- #
    # Test a custom non-0 "ceiling" PSI-factor.
    file  = File.join(__dir__, "files/osms/out/z5.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    argh               = {}
    argh[:option     ] = "uncompliant (Quebec)"
    argh[:io_path    ] = File.join(__dir__, "../json/tbd_z5.json")
    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")

    json     = TBD.process(model, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty
    expect(surfaces).to be_a(Hash)
    expect(surfaces.size).to eq(40)
    expect(io).to be_a(Hash)
    expect(io).to have_key(:edges)

    # Plenum "walls" are (still) derated.
    plnum_walls.each do |s|
      expect(surfaces).to have_key(s)
      expect(surfaces[s][:deratable]).to be true
    end

    # "Other" ceilings (i.e. those of conditioned spaces, adjacent to plenum
    # "floors") are (still) no longer derated.
    other_ceilings.each do |s|
      expect(surfaces).to have_key(s)
      expect(surfaces[s][:deratable]).to be false
    end

    io[:edges].select { |edge| edge[:type] == :ceiling }.each do |edge|
      expect(edge[:psi]).to eq("salk")
    end

    expect(io[:edges].count { |edge| edge[:type] == :ceiling       }).to eq(4)
    expect(io[:edges].count { |edge| edge[:type] == :rimjoist      }).to eq(0)
    expect(io[:edges].count { |edge| edge[:type] == :gradeconvex   }).to eq(8)
    expect(io[:edges].count { |edge| edge[:type] == :parapetconvex }).to eq(4)

    out  = JSON.pretty_generate(io)
    file = File.join(__dir__, "../json/tbd_z5.out.json")
    File.open(file, "w") { |f| f.puts out }


    # --- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- --- #
    # The following variations of the 'FullServiceRestaurant' (v3.2.1) are
    # snapshots of incremental development of the same model. For each step,
    # the tests illustrate how TBD ends up considering the unoccupied space
    # (below roof) and how simple variable changes allow users to switch from
    # UNCONDITIONED to INDIRECTLYCONDITIONED (or vice versa).
    unless OpenStudio.openStudioVersion.split(".").join.to_i < 321
      TBD.clean!

      # Unaltered template OpenStudio model:
      #   - constructions: NO
      #   - setpoints    : NO
      #   - HVAC         : NO
      file  = File.join(__dir__, "files/osms/in/resto1.osm")
      path  = OpenStudio::Path.new(file)
      model = translator.loadModel(path)
      expect(model).to_not be_empty
      model = model.get
      attic = model.getSpaceByName("Attic")
      expect(attic).to_not be_empty
      attic = attic.get

      expect(model.getConstructions).to be_empty
      heated = TBD.heatingTemperatureSetpoints?(model)
      cooled = TBD.coolingTemperatureSetpoints?(model)
      expect(heated).to be false
      expect(cooled).to be false

      argh  = { option: "code (Quebec)" }

      json     = TBD.process(model, argh)
      expect(json).to be_a(Hash)
      expect(json).to have_key(:io)
      expect(json).to have_key(:surfaces)
      io       = json[:io      ]
      surfaces = json[:surfaces]
      expect(TBD.error?).to be true
      expect(TBD.logs).to_not be_empty
      expect(surfaces).to be_a(Hash)
      expect(surfaces.size).to eq(18)
      expect(io).to be_a(Hash)
      expect(io).to_not have_key(:edges)

      TBD.logs.each do |log|
        expect(log[:message]).to include("missing").or include("layer?")
      end

      # As the model doesn't hold any constructions, TBD skips over any
      # derating steps. Yet despite the OpenStudio model not holding ANY valid
      # heating or cooling setpoints, ALL spaces are considered CONDITIONED.
      surfaces.values.each do |surface|
        expect(surface).to be_a(Hash)
        expect(surface).to have_key(:space)
        expect(surface).to have_key(:stype) # spacetype
        expect(surface).to have_key(:conditioned)
        expect(surface).to have_key(:deratable)
        expect(surface).to_not have_key(:construction)
        expect(surface[:conditioned]).to be true # even attic
        expect(surface[:deratable  ]).to be false # no constructions!
      end

      # OSut correctly report spaces here as UNCONDITIONED. Tagging ALL spaces
      # instead as CONDITIONED in such (rare) cases is unique to TBD.
      id = "attic-floor-dinning"
      expect(surfaces).to have_key(id)

      attic = surfaces[id][:space]
      heat  = TBD.setpoints(attic)[:heating]
      cool  = TBD.setpoints(attic)[:cooling]
      expect(TBD.unconditioned?(attic)).to be true
      expect(heat).to be_nil
      expect(cool).to be_nil
      expect(attic.partofTotalFloorArea).to be false
      expect(TBD.plenum?(attic)).to be false


      # - ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- - #
      # A more developed 'FullServiceRestaurant' (midway BTAP generation):
      #   - constructions: YES
      #   - setpoints    : YES
      #   - HVAC         : NO
      TBD.clean!

      file  = File.join(__dir__, "files/osms/in/resto2.osm")
      path  = OpenStudio::Path.new(file)
      model = translator.loadModel(path)
      expect(model).to_not be_empty
      model = model.get

      # BTAP-set (interior) ceiling constructions (i.e. attic/plenum floors)
      # are characteristic of occupied floors (e.g. carpet over 4" concrete
      # slab). Clone/assign insulated roof construction to plenum/attic floors.
      set = model.getBuilding.defaultConstructionSet
      expect(set).to_not be_empty
      set = set.get

      interiors = set.defaultInteriorSurfaceConstructions
      exteriors = set.defaultExteriorSurfaceConstructions
      expect(interiors).to_not be_empty
      expect(exteriors).to_not be_empty
      interiors = interiors.get
      exteriors = exteriors.get
      roofs     = exteriors.roofCeilingConstruction
      expect(roofs).to_not be_empty
      roofs     = roofs.get
      insulated = roofs.clone(model).to_LayeredConstruction
      expect(insulated).to_not be_empty
      insulated = insulated.get
      insulated.setName("Insulated Attic Floors")
      expect(interiors.setRoofCeilingConstruction(insulated)).to be true

      # Validate re-assignment via individual attic floor surfaces.
      construction = nil
      ceilings     = []

      model.getSurfaces.each do |s|
        next unless s.surfaceType == "RoofCeiling"
        next unless s.outsideBoundaryCondition == "Surface"

        ceilings << s.nameString
        c = s.construction
        expect(c).to_not be_empty
        c = c.get.to_LayeredConstruction
        expect(c).to_not be_empty
        c = c.get
        expect(TBD.rsi(c, s.filmResistance)).to be_within(TOL).of(6.38)

        construction = c if construction.nil?
        expect(c).to eq(construction)
      end

      expect(construction            ).to eq(insulated)
      expect(construction.getNetArea ).to be_within(TOL).of(511.15)
      expect(ceilings.size           ).to eq(2)
      expect(construction.layers.size).to eq(2)
      expect(construction.nameString ).to eq("Insulated Attic Floors")
      expect(model.getConstructions).to_not be_empty
      heated = TBD.heatingTemperatureSetpoints?(model)
      cooled = TBD.coolingTemperatureSetpoints?(model)
      expect(heated).to be true
      expect(cooled).to be true

      attic = model.getSpaceByName("attic")
      expect(attic).to_not be_empty
      attic = attic.get

      expect(attic.partofTotalFloorArea).to be false
      heat = TBD.setpoints(attic)[:heating]
      cool = TBD.setpoints(attic)[:cooling]
      expect(heat).to be_nil
      expect(cool).to be_nil

      expect(TBD.plenum?(attic)).to be false
      expect(attic.partofTotalFloorArea).to be false
      expect(attic.thermalZone).to_not be_empty
      zone = attic.thermalZone.get
      expect(zone.isPlenum).to be false

      tstat = zone.thermostat
      expect(tstat).to_not be_empty
      tstat = tstat.get
      expect(tstat.to_ThermostatSetpointDualSetpoint).to_not be_empty
      tstat = tstat.to_ThermostatSetpointDualSetpoint.get
      expect(tstat.getHeatingSchedule).to be_empty
      expect(tstat.getCoolingSchedule).to be_empty

      heat = TBD.maxHeatScheduledSetpoint(zone)
      cool = TBD.minCoolScheduledSetpoint(zone)
      expect(heat).to_not be_nil
      expect(cool).to_not be_nil
      expect(heat).to be_a(Hash)
      expect(cool).to be_a(Hash)
      expect(heat).to have_key(:spt)
      expect(cool).to have_key(:spt)
      expect(heat).to have_key(:dual)
      expect(cool).to have_key(:dual)
      expect(heat[:spt]).to be_nil
      expect(cool[:spt]).to be_nil
      expect(heat[:dual]).to be false
      expect(cool[:dual]).to be false

      # The unoccupied space does not reference valid heating and/or cooling
      # temperature setpoint objects, and is therefore considered
      # UNCONDITIONED. Save for next iteration.
      file = File.join(__dir__, "files/osms/out/resto2a.osm")
      model.save(file, true)

      argh                = {}
      argh[:option      ] = "efficient (BETBG)"
      argh[:uprate_roofs] = true
      argh[:roof_option ] = "ALL roof constructions"
      argh[:roof_ut     ] = 0.138 # NECB CZ7 2017 (RSi 7.25 / R41)

      json     = TBD.process(model, argh)
      expect(json).to be_a(Hash)
      expect(json).to have_key(:io)
      expect(json).to have_key(:surfaces)
      io       = json[:io      ]
      surfaces = json[:surfaces]
      expect(TBD.status).to be_zero
      expect(TBD.logs).to be_empty
      expect(surfaces).to be_a(Hash)
      expect(surfaces.size).to eq(18)
      expect(io).to be_a(Hash)
      expect(io).to have_key(:edges)
      expect(io[:edges].size).to eq(31)

      expect(argh).to_not have_key(:wall_uo)
      expect(argh).to have_key(:roof_uo)
      expect(argh[:roof_uo]).to be_within(TOL).of(0.119)

      # Validate ceiling surfaces (both insulated & uninsulated).
      ua = 0.0
      a  = 0.0

      surfaces.each do |nom, surface|
        expect(surface).to be_a(Hash)

        expect(surface).to have_key(:conditioned)
        expect(surface).to have_key(:deratable)
        expect(surface).to have_key(:construction)
        expect(surface).to have_key(:ground)
        expect(surface).to have_key(:type)
        next     if surface[:ground]
        next unless surface[:type  ] == :ceiling

        # Sloped attic roof surfaces ignored by TBD.
        id = surface[:construction].nameString
        expect(nom).to include("-roof"    ) unless surface[:deratable]
        expect(id ).to include("BTAP-Ext-") unless surface[:deratable]
        expect(surface[:conditioned]   ).to be false unless surface[:deratable]
        next unless surface[:deratable]
        next unless surface.key?(:heatloss)

        # Leaves only insulated attic ceilings.
        expect(id).to eq("Insulated Attic Floors") # original construction
        s = model.getSurfaceByName(nom)
        expect(s).to_not be_empty
        s = s.get
        c = s.construction
        expect(c).to_not be_empty
        c = c.get.to_LayeredConstruction
        expect(c).to_not be_empty
        c = c.get

        expect(c.nameString).to include("c tbd") # TBD-derated
        a  += surface[:net]
        ua += 1 / TBD.rsi(c, s.filmResistance) * surface[:net]
      end

      expect(ua / a).to be_within(TOL).of(argh[:roof_ut])


      # - ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- - #
      # Altered model from previous iteration, yet no uprating this round.
      #   - constructions: YES
      #   - setpoints    : YES
      #   - HVAC         : NO
      TBD.clean!

      file   = File.join(__dir__, "files/osms/out/resto2a.osm")
      path   = OpenStudio::Path.new(file)
      model  = translator.loadModel(path)
      expect(model).to_not be_empty
      model  = model.get
      heated = TBD.heatingTemperatureSetpoints?(model)
      cooled = TBD.coolingTemperatureSetpoints?(model)
      expect(model.getConstructions).to_not be_empty
      expect(heated).to be true
      expect(cooled).to be true

      # In this iteration, ensure the unoccupied space is considered as an
      # INDIRECTLYCONDITIONED plenum (instead of an UNCONDITIONED attic), by
      # temporarily adding a heating dual setpoint schedule object to its zone
      # thermostat (yet without valid scheduled temperatures).
      attic = model.getSpaceByName("attic")
      expect(attic).to_not be_empty
      attic = attic.get
      expect(attic.partofTotalFloorArea).to be false
      expect(attic.thermalZone).to_not be_empty
      zone  = attic.thermalZone.get
      expect(zone.isPlenum).to be false
      tstat = zone.thermostat
      expect(tstat).to_not be_empty
      tstat = tstat.get

      expect(tstat.to_ThermostatSetpointDualSetpoint).to_not be_empty
      tstat = tstat.to_ThermostatSetpointDualSetpoint.get

      # Before the addition.
      expect(tstat.getHeatingSchedule).to be_empty
      expect(tstat.getCoolingSchedule).to be_empty

      heat  = TBD.maxHeatScheduledSetpoint(zone)
      cool  = TBD.minCoolScheduledSetpoint(zone)
      stpts = TBD.setpoints(attic)

      expect(heat).to_not be_nil
      expect(cool).to_not be_nil
      expect(heat).to be_a(Hash)
      expect(cool).to be_a(Hash)
      expect(heat).to have_key(:spt)
      expect(cool).to have_key(:spt)
      expect(heat).to have_key(:dual)
      expect(cool).to have_key(:dual)
      expect(heat[:spt]).to be_nil
      expect(cool[:spt]).to be_nil
      expect(heat[:dual]).to be false
      expect(cool[:dual]).to be false

      expect(stpts[:heating]).to be_nil
      expect(stpts[:cooling]).to be_nil
      expect(TBD.unconditioned?(attic)).to be true
      expect(TBD.plenum?(attic)).to be false

      # Add a dual setpoint temperature schedule.
      identifier = "TEMPORARY attic setpoint schedule"

      sched = OpenStudio::Model::ScheduleCompact.new(model)
      sched.setName(identifier)
      expect(sched.constantValue).to be_empty
      expect(tstat.setHeatingSetpointTemperatureSchedule(sched)).to be true

      # After the addition.
      expect(tstat.getHeatingSchedule).to_not be_empty
      expect(tstat.getCoolingSchedule).to be_empty
      heat  = TBD.maxHeatScheduledSetpoint(zone)
      stpts = TBD.setpoints(attic)

      expect(heat).to_not be_nil
      expect(heat).to be_a(Hash)
      expect(heat).to have_key(:spt)
      expect(heat).to have_key(:dual)
      expect(heat[:spt ]).to be_nil
      expect(heat[:dual]).to be true

      expect(stpts[:heating]).to be_within(TOL).of(21.0)
      expect(stpts[:cooling]).to be_within(TOL).of(24.0)

      expect(TBD.unconditioned?(attic)).to be false
      expect(TBD.plenum?(attic)).to be true # works ...

      argh = { option: "code (Quebec)" }

      json     = TBD.process(model, argh)
      expect(json ).to be_a(Hash)
      expect(json).to have_key(:io)
      expect(json).to have_key(:surfaces)
      io       = json[:io      ]
      surfaces = json[:surfaces]
      expect(TBD.error?).to be true
      expect(TBD.logs.size).to eq(18)
      expect(surfaces).to be_a(Hash)
      expect(surfaces.size).to eq(18)
      expect(io).to be_a(Hash)
      expect(io).to have_key(:edges)
      expect(io[:edges].size).to eq(35)

      # The incomplete (temporary) schedule triggers a non-FATAL TBD error.
      TBD.logs.each do |log|
        expect(log[:message]).to include("Empty '")
        expect(log[:message]).to include("::scheduleCompactMinMax)")
      end

      surfaces.each do |nom, surface|
        expect(surface).to be_a(Hash)

        expect(surface).to have_key(:conditioned)
        expect(surface).to have_key(:deratable)
        expect(surface).to have_key(:construction)
        expect(surface).to have_key(:ground)
        expect(surface).to have_key(:type)
        next unless surface[:type] == :ceiling

        # Sloped attic roof surfaces no longer ignored by TBD.
        id = surface[:construction].nameString
        expect(nom).to include("-roof"    )     if surface[:deratable]
        expect(nom).to include("_Ceiling" ) unless surface[:deratable]
        expect(id ).to include("BTAP-Ext-")     if surface[:deratable]

        expect(surface[:conditioned]).to be true
        next unless surface[:deratable]
        next unless surface.key?(:heatloss)

        # Leaves only insulated attic ceilings.
        expect(id).to eq("BTAP-Ext-Roof-Metal:U-0.162") # original construction
        s = model.getSurfaceByName(nom)
        expect(s).to_not be_empty
        s = s.get
        c = s.construction
        expect(c).to_not be_empty
        c = c.get.to_LayeredConstruction
        expect(c).to_not be_empty
        c = c.get
        expect(c.nameString).to include("c tbd") # TBD-derated
      end

      # Once done, ensure temporary schedule is dissociated from the thermostat
      # and deleted from the model.
      tstat.resetHeatingSetpointTemperatureSchedule
      expect(tstat.getHeatingSchedule).to be_empty

      sched2 = model.getScheduleByName(identifier)
      expect(sched2).to_not be_empty
      sched2.get.remove
      sched2 = model.getScheduleByName(identifier)
      expect(sched2).to be_empty

      heat  = TBD.maxHeatScheduledSetpoint(zone)
      stpts = TBD.setpoints(attic)

      expect(heat).to be_a(Hash)
      expect(heat).to have_key(:spt )
      expect(heat).to have_key(:dual)
      expect(heat[:spt ]).to be_nil
      expect(heat[:dual]).to be false

      expect(stpts[:heating]).to be_nil
      expect(stpts[:cooling]).to be_nil
      expect(TBD.plenum?(attic)).to be false # as before ...


      # -- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- -- #
      TBD.clean!

      # Same, altered model from previous iteration (yet to uprate):
      #   - constructions: YES
      #   - setpoints    : YES
      #   - HVAC         : NO
      file  = File.join(__dir__, "files/osms/out/resto2a.osm")
      path  = OpenStudio::Path.new(file)
      model = translator.loadModel(path)
      expect(model).to_not be_empty
      model = model.get
      expect(model.getConstructions).to_not be_empty

      heated = TBD.heatingTemperatureSetpoints?(model)
      cooled = TBD.coolingTemperatureSetpoints?(model)
      expect(heated).to be true
      expect(cooled).to be true

      # Get geometry data for testing (4x exterior roofs, same construction).
      id           = "BTAP-Ext-Roof-Metal:U-0.162"
      construction = nil
      roofs        = []

      model.getSurfaces.each do |s|
        next unless s.surfaceType == "RoofCeiling"
        next unless s.outsideBoundaryCondition == "Outdoors"

        roofs << s.nameString
        c = s.construction
        expect(c).to_not be_empty
        c = c.get.to_LayeredConstruction
        expect(c).to_not be_empty
        c = c.get

        construction = c if construction.nil?
        expect(c).to eq(construction)
      end

      expect(construction.getNetArea ).to be_within(TOL).of(569.51)
      expect(roofs.size              ).to eq( 4)
      expect(construction.nameString ).to eq(id)
      expect(construction.layers.size).to eq( 2)

      insulation = construction.layers[1].to_MasslessOpaqueMaterial
      expect(insulation).to_not be_empty
      insulation = insulation.get
      original_r = insulation.thermalResistance
      expect(original_r).to be_within(TOL).of(6.17)

      # Attic spacetype as plenum, an alternative to the inactive thermostat.
      attic  = model.getSpaceByName("attic")
      expect(attic).to_not be_empty
      attic  = attic.get
      sptype = attic.spaceType
      expect(sptype).to_not be_empty
      sptype = sptype.get
      sptype.setName("Attic as Plenum")

      stpts = TBD.setpoints(attic)
      expect(stpts[:heating]).to be_within(TOL).of(21.0)
      expect(TBD.unconditioned?(attic)).to be false
      expect(TBD.plenum?(attic)).to be true # works ...

      argh                = {}
      argh[:option      ] = "efficient (BETBG)"
      argh[:uprate_walls] = true
      argh[:uprate_roofs] = true
      argh[:wall_option ] = "ALL wall constructions"
      argh[:roof_option ] = "ALL roof constructions"
      argh[:wall_ut     ] = 0.210 # NECB CZ7 2017 (RSi 4.76 / R27)
      argh[:roof_ut     ] = 0.138 # NECB CZ7 2017 (RSi 7.25 / R41)

      json     = TBD.process(model, argh)
      expect(json).to be_a(Hash)
      expect(json).to have_key(:io)
      expect(json).to have_key(:surfaces)
      io       = json[:io      ]
      surfaces = json[:surfaces]
      expect(TBD.status).to be_zero

      expect(argh).to have_key(:wall_uo)
      expect(argh).to have_key(:roof_uo)
      expect(argh[:roof_uo]).to be_within(TOL).of(0.120) # RSi  8.3 ( R47)
      expect(argh[:wall_uo]).to be_within(TOL).of(0.012) # RSi 83.3 (R473)

      # Validate ceiling surfaces (both insulated & uninsulated).
      ua   = 0.0
      a    = 0
      area = 0

      surfaces.each do |nom, surface|
        expect(surface).to be_a(Hash)
        expect(surface).to have_key(:conditioned)
        expect(surface).to have_key(:deratable)
        expect(surface).to have_key(:construction)
        expect(surface).to have_key(:ground)
        expect(surface).to have_key(:type)
        next     if surface[:ground]
        next unless surface[:type  ] == :ceiling

        # Sloped plenum roof surfaces no longer ignored by TBD.
        id = surface[:construction].nameString
        expect(nom).to include("-roof"    ) if surface[:deratable]
        expect(id ).to include("BTAP-Ext-") if surface[:deratable]

        expect(surface[:conditioned]).to be true     if surface[:deratable]
        expect(nom).to include("_Ceiling") unless surface[:deratable]
        expect(surface[:conditioned]).to be true unless surface[:deratable]

        next unless surface[:deratable]
        next unless surface.key?(:heatloss)

        # Leaves only insulated plenum roof surfaces.
        expect(id).to eq("BTAP-Ext-Roof-Metal:U-0.162") # original construction
        s = model.getSurfaceByName(nom)
        expect(s).to_not be_empty
        s = s.get
        c = s.construction
        expect(c).to_not be_empty
        c = c.get.to_LayeredConstruction
        expect(c).to_not be_empty
        c = c.get
        expect(c.nameString).to include("c tbd") # TBD-derated

        a  += surface[:net]
        ua += 1 / TBD.rsi(c, s.filmResistance) * surface[:net]
      end

      expect(ua / a).to be_within(TOL).of(argh[:roof_ut])

      roofs.each do |roof|
        expect(surfaces).to have_key(roof)
        expect(surfaces[roof]).to have_key(:deratable)
        expect(surfaces[roof]).to have_key(:edges)
        expect(surfaces[roof][:deratable]).to be true

        surfaces[roof][:edges].values.each do |edge|
          expect(edge).to have_key(:psi)
          expect(edge).to have_key(:length)
          expect(edge).to have_key(:ratio)
          expect(edge).to have_key(:type)
          next if edge[:type] == :transition

          expect(edge[:ratio]).to be_within(TOL).of(0.579)
          expect(edge[:psi  ]).to be_within(TOL).of(0.200 * edge[:ratio])
        end

        loss = 22.61 * 0.200 * 0.579
        expect(surfaces[roof]).to have_key(:heatloss)
        expect(surfaces[roof]).to have_key(:net)
        expect(surfaces[roof][:heatloss]).to be_within(TOL).of(loss)
        area += surfaces[roof][:net]
      end

      expect(area).to be_within(TOL).of(569.50)
    end

    # --- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- --- #
    # Add skylight (+ skylight well) to corrected SEB model.
    TBD.clean!
    file  = File.join(__dir__, "files/osms/out/seb2.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    entry   = model.getSpaceByName("Entry way 1")
    office  = model.getSpaceByName("Small office 1")
    open    = model.getSpaceByName("Open area 1")
    utility = model.getSpaceByName("Utility 1")
    plenum  = model.getSpaceByName("Level 0 Ceiling Plenum")
    expect(entry).to_not be_empty
    expect(office).to_not be_empty
    expect(open).to_not be_empty
    expect(utility).to_not be_empty
    expect(plenum).to_not be_empty
    entry   = entry.get
    office  = office.get
    open    = open.get
    utility = utility.get
    plenum  = plenum.get
    expect(plenum.partofTotalFloorArea).to be false
    expect(TBD.unconditioned?(plenum)).to be false

    open_roofs = TBD.roofs(open)
    expect(open_roofs.size).to eq(1)
    open_roof = open_roofs.first
    roof_id   = open_roof.nameString
    expect(roof_id).to eq("Level 0 Open area 1 Ceiling Plenum RoofCeiling")

    srr = 0.05
    gra = TBD.grossRoofArea(model.getSpaces)
    tm2 = srr * gra
    rm2 = TBD.addSkyLights(model.getSpaces, {area: tm2})
    puts TBD.logs unless TBD.logs.empty?
    expect(TBD.status).to be_zero
    expect(rm2.round(2)).to eq(gra.round(2))

    entry_skies   = TBD.facets(entry, "Outdoors", "Skylight")
    office_skies  = TBD.facets(office, "Outdoors", "Skylight")
    utility_skies = TBD.facets(utility, "Outdoors", "Skylight")
    open_skies    = TBD.facets(open, "Outdoors", "Skylight")

    expect(entry_skies).to be_empty
    expect(office_skies).to be_empty
    expect(utility_skies).to be_empty
    expect(open_skies.size).to eq(1)
    open_sky = open_skies.first
    sky_id   = open_sky.nameString
    expect(sky_id).to eq("0:0:0:Open area 1:0")

    skm2 = open_sky.grossArea
    expect((skm2 / rm2).round(2)).to eq(srr)

    # Assign construction to new skylights.
    construction = TBD.genConstruction(model, {type: :skylight, uo: 2.8})
    expect(open_sky.setConstruction(construction)).to be true
    puts TBD.logs unless TBD.logs.empty?
    expect(TBD.status).to be_zero

    file = File.join(__dir__, "files/osms/out/seb2_sky.osm")
    model.save(file, true)

    open_well  = open_sky.surface
    expect(open_well).to_not be_empty
    open_well  = open_well.get
    expect(open_well.surfaceType.downcase).to eq("roofceiling")
    well_id    = open_well.nameString
    expect(well_id).to eq("0:0:0:Open area 1")

    argh               = {}
    argh[:option     ] = "regular (BETBG)"
    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")

    json     = TBD.process(model, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty
    expect(surfaces).to be_a(Hash)
    expect(surfaces.size).to eq(65) # ! 56 before skylight/well/leader lines
    expect(io).to be_a(Hash)
    expect(io).to have_key(:edges)
    expect(io[:edges].size).to eq(115) # ! 106 before skylight/well/leader lines

    # Extra 9 edges:
    #   - 4x new "skylightjamb" edges
    #   - 4x new "transition" edges around well
    #   - 1x "transition" edge along leader line, required for well cutout.
    sky_jambs = io[:edges].select { |ed| ed[:surfaces].include?(sky_id) }
    expect(sky_jambs.size).to eq(4)

    sky_jambs.each do |edg|
      expect(edg[:surfaces].size).to eq(2)
      expect(edg[:surfaces]).to include(well_id)
      expect(edg[:type]).to eq(:skylightjamb)
    end

    roof_edges  = io[:edges].select { |ed| ed[:surfaces].include?(roof_id) }
    parapets    = roof_edges.select { |ed| ed[:type] == :parapetconvex }
    transitions = roof_edges.select { |ed| ed[:type] == :transition }
    expect(parapets.size).to eq(5)
    expect(transitions.size).to eq(10)
    expect(roof_edges.size).to eq(parapets.size + transitions.size)

    parapets.each { |edg| expect(edg[:surfaces].size).to eq(2) }

    t1x = transitions.select { |edg| edg[:surfaces].size == 1 }
    t2x = transitions.select { |edg| edg[:surfaces].size == 2 }
    t4x = transitions.select { |edg| edg[:surfaces].size == 4 }
    expect(t1x.size).to eq(1) # leader line
    expect(t2x.size).to eq(5) # see "can process JSON surface KHI entries"
    expect(t4x.size).to eq(4) # around skylight well

    expect(transitions.size).to eq(t1x.size + t2x.size + t4x.size)

    # Skylight well cutout leader line backtracks onto itself.
    t1x = t1x.first
    expect(t1x[:surfaces]).to include(roof_id)

    t4x.each do |edg|
      expect(edg[:surfaces].size).to eq(4)
      expect(edg[:surfaces]).to include(roof_id) # roof with cutout
      expect(edg[:surfaces]).to include(well_id) # new base surface for skylight

      edg[:surfaces].each do |s|
        next if s == roof_id
        next if s == well_id

        expect(s).to include("0:0:0:0:")
        # e.g.:
        # ... Level 0 Open area 1 Ceiling Plenum RoofCeiling (i.e. roof_id)
        # ... 0:0:0:Open area 1 (i.e. well_id)
        # ... 0:0:0:0:3:Level 0 Ceiling Plenum (i.e. well wall, plenum side)
        # ... 0:0:0:0:3:Open area 1 (i.e. adjacent well wall, open area side)
      end
    end

    puts TBD.logs unless TBD.logs.empty?
    expect(TBD.status).to be_zero
  end

  it "can generate and access KIVA inputs (midrise apts)" do
    translator = OpenStudio::OSVersion::VersionTranslator.new
    TBD.clean!

    file  = File.join(__dir__, "files/osms/in/midrise.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    argh            = {}
    argh[:option  ] = "poor (BETBG)"
    argh[:gen_kiva] = true

    json     = TBD.process(model, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty
    expect(surfaces).to be_a(Hash)
    expect(surfaces.size).to eq(180)
    expect(io).to be_a(Hash)
    expect(io).to have_key(:edges)
    expect(io[:edges].size).to eq(282)

    # Validate.
    surfaces.each do |id, surface|
      next unless surface.key?(:foundation) # ... only floors
      next unless surface.key?(:kiva)

      expect(surface[:kiva]).to eq(:slab)
      expect(surface).to have_key(:exposed)
      expect(id).to eq("g Floor C")
      expect(surface[:exposed]).to be_within(TOL).of(3.36)
      gFC = model.getSurfaceByName("g Floor C")
      expect(gFC).to_not be_empty
      gFC = gFC.get
      expect(gFC.outsideBoundaryCondition.downcase).to eq("foundation")
    end

    file = File.join(__dir__, "files/osms/out/midrise_KIVA2.osm")
    model.save(file, true)
  end

  it "can generate multiple KIVA exposed perimeters (midrise apts)" do
    translator = OpenStudio::OSVersion::VersionTranslator.new
    TBD.clean!

    file  = File.join(__dir__, "files/osms/in/midrise.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    # Reset all ground-facing floor surfaces as "foundations".
    model.getSurfaces.each do |s|
      next unless s.outsideBoundaryCondition.downcase == "ground"

      expect(s.construction).to_not be_empty
      construction = s.construction.get
      expect(s.setOutsideBoundaryCondition("Foundation")).to be true
      expect(s.setConstruction(construction)).to be true
    end

    argh            = {}
    argh[:option  ] = "poor (BETBG)"
    argh[:gen_kiva] = true

    json     = TBD.process(model, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty
    expect(surfaces).to be_a(Hash)
    expect(surfaces.size).to eq(180)
    expect(io).to be_a(Hash)
    expect(io).to have_key(:edges)
    expect(io[:edges].size).to eq(282)

    # Validate.
    surfaces.each do |id, surface|
      next unless surface.key?(:foundation) # only floors
      next unless surface.key?(:kiva)

      expect(surface[:kiva]).to eq(:slab)
      expect(surface).to have_key(:exposed)
      exp   = surface[:exposed]
      found = false

      model.getSurfaces.each do |s|
        next unless s.nameString == id
        next unless s.outsideBoundaryCondition.downcase == "foundation"

        found = true

        expect(exp).to be_within(TOL).of(19.20) if id == "g GFloor NWA"
        expect(exp).to be_within(TOL).of(19.20) if id == "g GFloor NEA"
        expect(exp).to be_within(TOL).of(19.20) if id == "g GFloor SWA"
        expect(exp).to be_within(TOL).of(19.20) if id == "g GFloor SEA"
        expect(exp).to be_within(TOL).of(11.58) if id == "g GFloor S1A"
        expect(exp).to be_within(TOL).of(11.58) if id == "g GFloor S2A"
        expect(exp).to be_within(TOL).of(11.58) if id == "g GFloor N1A"
        expect(exp).to be_within(TOL).of(11.58) if id == "g GFloor N2A"
        expect(exp).to be_within(TOL).of( 3.36) if id == "g Floor C"
      end

      expect(found).to be true
    end

    file = File.join(__dir__, "files/osms/out/midrise_KIVA3.osm")
    model.save(file, true)
  end

  it "can generate KIVA exposed perimeters (warehouse)" do
    translator = OpenStudio::OSVersion::VersionTranslator.new
    TBD.clean!

    file  = File.join(__dir__, "files/osms/in/warehouse.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    fl1  = "Fine Storage Floor"
    fl2  = "Office Floor"
    fl3  = "Bulk Storage Floor"
    flrs = [fl1, fl2, fl3]

    # Reset all ground-facing floor surfaces as "foundations".
    model.getSurfaces.each do |s|
      next unless s.outsideBoundaryCondition.downcase == "ground"

      expect(s.construction).to_not be_empty
      construction = s.construction.get
      expect(s.setOutsideBoundaryCondition("Foundation")).to be true
      expect(s.setConstruction(construction)).to be true
    end

    argh            = {}
    argh[:option  ] = "(non thermal bridging)"
    argh[:gen_kiva] = true

    json     = TBD.process(model, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty
    expect(surfaces).to be_a(Hash)
    expect(surfaces.size).to eq(23)
    expect(io).to be_a(Hash)
    expect(io).to have_key(:edges)
    expect(io[:edges].size).to eq(300)

    # Validate.
    surfaces.each do |id, surface|
      next unless surface.key?(:foundation) # only floors
      next unless surface.key?(:kiva)

      expect(surface[:kiva]).to eq(:slab)
      expect(surface).to have_key(:exposed)
      exp   = surface[:exposed]
      found = false

      model.getSurfaces.each do |s|
        next unless s.nameString == id
        next unless s.outsideBoundaryCondition.downcase == "foundation"

        found = true
        expect(exp).to be_within(TOL).of( 71.62) if id == "fl1"
        expect(exp).to be_within(TOL).of( 35.05) if id == "fl2"
        expect(exp).to be_within(TOL).of(185.92) if id == "fl3"
      end

      expect(found).to be true
    end

    pth = File.join(__dir__, "files/osms/out/warehouse_KIVA.osm")
    model.save(pth, true)

    # Now re-open for testing.
    path  = OpenStudio::Path.new(pth)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    model.getSurfaces.each do |s|
      next unless s.isGroundSurface

      expect(flrs).to include(s.nameString)
      expect(s.outsideBoundaryCondition).to eq("Foundation")
    end

    kfs = model.getFoundationKivas
    expect(kfs).to_not be_empty
    expect(kfs.size).to eq(3)
  end

  it "can invalidate KIVA inputs (smalloffice)" do
    translator = OpenStudio::OSVersion::VersionTranslator.new
    TBD.clean!

    msg   = "Non-standard materials for "
    file  = File.join(__dir__, "files/osms/in/smalloffice.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    # Reset all ground-facing floor surfaces as "foundations".
    model.getSurfaces.each do |s|
      next unless s.outsideBoundaryCondition.downcase == "ground"

      expect(s.construction).to_not be_empty
      construction = s.construction.get
      expect(s.setOutsideBoundaryCondition("Foundation")).to be true
      expect(s.setConstruction(construction)).to be true
    end

    argh            = {}
    argh[:option  ] = "poor (BETBG)"
    argh[:gen_kiva] = true

    json     = TBD.process(model, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.error?).to be true
    expect(TBD.logs.size).to eq(5)
    expect(surfaces).to be_a(Hash)
    expect(surfaces.size).to eq(43)
    expect(io).to be_a(Hash)
    expect(io).to have_key(:edges)
    expect(io[:edges].size).to eq(105)

    TBD.logs.each { |log| expect(log[:message]).to include(msg) }

    surfaces.values.each do |s|
      # puts s.keys
      # puts
      expect(s).to_not have_key(:kiva)
    end

    file = File.join(__dir__, "files/osms/out/smalloffice_kiva.osm")
    model.save(file, true)
  end

  it "can compute uFactor for ceilings, walls, and floors" do
    model = OpenStudio::Model::Model.new
    space = OpenStudio::Model::Space.new(model)

    material = OpenStudio::Model::MasslessOpaqueMaterial.new(model)
    material.setRoughness("Smooth")
    material.setThermalResistance(4.0)
    material.setThermalAbsorptance(0.9)
    material.setSolarAbsorptance(0.7)
    material.setVisibleAbsorptance(0.7)

    layers = OpenStudio::Model::MaterialVector.new
    layers << material
    construction = OpenStudio::Model::Construction.new(model)
    construction.setLayers(layers)
    expect(construction.thermalConductance).to_not be_empty
    expect(construction.thermalConductance.get).to be_within(0.001).of(0.25)
    expect(construction.uFactor(0)).to_not be_empty
    expect(construction.uFactor(0).get).to be_within(0.001).of(0.25)

    vertices = OpenStudio::Point3dVector.new
    vertices << OpenStudio::Point3d.new( 10, 10, 5)
    vertices << OpenStudio::Point3d.new( 0, 10, 5)
    vertices << OpenStudio::Point3d.new( 0, 0, 5)
    vertices << OpenStudio::Point3d.new( 10, 0, 5)
    ceiling = OpenStudio::Model::Surface.new(vertices, model)
    ceiling.setSpace(space)
    ceiling.setConstruction(construction)
    expect(ceiling.surfaceType.downcase).to eq("roofceiling")
    expect(ceiling.outsideBoundaryCondition.downcase).to eq("outdoors")
    expect(ceiling.filmResistance).to be_within(0.001).of(0.136)
    expect(ceiling.uFactor).to_not be_empty
    expect(ceiling.uFactor.get).to be_within(0.001).of(0.242)

    vertices = OpenStudio::Point3dVector.new
    vertices << OpenStudio::Point3d.new( 0, 10, 5)
    vertices << OpenStudio::Point3d.new( 0, 10, 0)
    vertices << OpenStudio::Point3d.new( 0, 0, 0)
    vertices << OpenStudio::Point3d.new( 0, 0, 5)
    wall = OpenStudio::Model::Surface.new(vertices, model)
    wall.setSpace(space)
    wall.setConstruction(construction)
    expect(wall.surfaceType.downcase).to eq("wall")
    expect(wall.outsideBoundaryCondition.downcase).to eq("outdoors")
    expect(wall.tilt).to be_within(0.001).of(Math::PI/2.0)
    expect(wall.filmResistance).to be_within(0.001).of(0.150)
    expect(wall.uFactor).to_not be_empty
    expect(wall.uFactor.get).to be_within(0.001).of(0.241)

    vertices = OpenStudio::Point3dVector.new
    vertices << OpenStudio::Point3d.new( 0, 10, 0)
    vertices << OpenStudio::Point3d.new( 10, 10, 0)
    vertices << OpenStudio::Point3d.new( 10, 0, 0)
    vertices << OpenStudio::Point3d.new( 0, 0, 0)
    floor = OpenStudio::Model::Surface.new(vertices, model)
    floor.setSpace(space)
    floor.setConstruction(construction)
    expect(floor.surfaceType.downcase).to eq("floor")
    expect(floor.outsideBoundaryCondition.downcase).to eq("ground")
    expect(floor.tilt).to be_within(0.001).of(Math::PI)
    expect(floor.filmResistance).to be_within(0.001).of(0.160)
    expect(floor.uFactor).to_not be_empty
    expect(floor.uFactor.get).to be_within(0.001).of(0.241)

    # make outdoors (like a soffit)
    expect(floor.setOutsideBoundaryCondition("Outdoors")).to be true
    expect(floor.filmResistance).to be_within(0.001).of(0.190)
    expect(floor.uFactor).to_not be_empty
    expect(floor.uFactor.get).to be_within(0.001).of(0.239)

    # now make these surfaces not outdoors
    expect(ceiling.setOutsideBoundaryCondition("Adiabatic")).to be true
    expect(ceiling.filmResistance).to be_within(0.001).of(0.212)
    expect(ceiling.uFactor).to_not be_empty
    expect(ceiling.uFactor.get).to be_within(0.001).of(0.237)

    expect(wall.setOutsideBoundaryCondition("Adiabatic")).to be true
    expect(wall.filmResistance).to be_within(0.001).of(0.239)
    expect(wall.uFactor).to_not be_empty
    expect(wall.uFactor.get).to be_within(0.001).of(0.236)

    expect(floor.setOutsideBoundaryCondition("Adiabatic")).to be true
    expect(floor.filmResistance).to be_within(0.001).of(0.321)
    expect(floor.uFactor).to_not be_empty
    expect(floor.uFactor.get).to be_within(0.001).of(0.231)

    # doubling number of layers. Good.
    layers = OpenStudio::Model::MaterialVector.new
    layers << material
    layers << material
    construction = OpenStudio::Model::Construction.new(model)
    construction.setLayers(layers)
    expect(construction.thermalConductance).to_not be_empty
    expect(construction.thermalConductance.get).to be_within(0.001).of(0.125)
    expect(construction.uFactor(0)).to_not be_empty
    expect(construction.uFactor(0).get).to be_within(0.001).of(0.125)

    # All good.
    floor.setConstruction(construction)
    expect(floor.setOutsideBoundaryCondition("Outdoors")).to be true
    expect(floor.filmResistance).to be_within(0.001).of(0.190)
    expect(floor.thermalConductance).to_not be_empty
    expect(floor.thermalConductance.get).to be_within(0.001).of(0.125)
    expect(floor.uFactor).to_not be_empty
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
    gypsum = OpenStudio::Model::MasslessOpaqueMaterial.new(model)
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
    ratedR35 = OpenStudio::Model::MasslessOpaqueMaterial.new(model)
    ratedR35.setRoughness("Smooth")
    ratedR35.setThermalResistance(6.24)
    ratedR35.setThermalAbsorptance(0.9)
    ratedR35.setSolarAbsorptance(0.7)
    ratedR35.setVisibleAbsorptance(0.7)

    deratedR35 = OpenStudio::Model::MasslessOpaqueMaterial.new(model)
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
    stucco = OpenStudio::Model::StandardOpaqueMaterial.new(model)
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
    ratedR9 = OpenStudio::Model::MasslessOpaqueMaterial.new(model)
    ratedR9.setRoughness("Smooth")
    ratedR9.setThermalResistance(1.60)
    ratedR9.setThermalAbsorptance(0.9)
    ratedR9.setSolarAbsorptance(0.7)
    ratedR9.setVisibleAbsorptance(0.7)

    deratedR9 = OpenStudio::Model::MasslessOpaqueMaterial.new(model)
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
    rated_attic = OpenStudio::Model::Construction.new(model)
    rated_attic.setLayers(layers)
    expect(rated_attic.thermalConductance.get).to be_within(TOL).of(0.158)

    layers = OpenStudio::Model::MaterialVector.new
    layers << gypsum                          # RSi = 0.099375
    layers << deratedR35                      # Rsi = 4.21
                                              #     = 4.31    TOTAL (w/o films)
                                              #     = 4.55    TOTAL if floor
                                              #     = 4.46    TOTAL if wall
                                              #     = 4.45    TOTAL if roof
    derated_attic = OpenStudio::Model::Construction.new(model)
    derated_attic.setLayers(layers)
    expect(derated_attic.thermalConductance.get).to be_within(TOL).of(0.232)

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
    rated_perimeter = OpenStudio::Model::Construction.new(model)
    rated_perimeter.setLayers(layers)
    expect(rated_perimeter.thermalConductance.get).to be_within(TOL).of(0.546)

    layers = OpenStudio::Model::MaterialVector.new
    layers << stucco                          # RSi = 0.0353
    layers << gypsum                          # RSi = 0.099375
    layers << deratedR9                       # RSi = 0.59
    layers << gypsum                          # RSi = 0.099375
                                              #     = 0.824    TOTAL (w/o films)
                                              #     = 1.059    TOTAL if floor
                                              #     = 0.974    TOTAL if wall
                                              #     = 0.960    TOTAL if roof
    derated_perimeter = OpenStudio::Model::Construction.new(model)
    derated_perimeter.setLayers(layers)
    expect(derated_perimeter.thermalConductance.get).to be_within(TOL).of(1.214)

    floor.setOutsideBoundaryCondition("Outdoors")
    floor.setConstruction(rated_attic)
    rated_attic_RSi = 1.0 / floor.uFactor.to_f
    expect(rated_attic_RSi).to be_within(TOL).of(6.53)
    # puts "... rated attic thermal conductance:#{floor.thermalConductance}"
    # puts "... rated attic uFactor:#{floor.uFactor}"
    #     = 6.34    TOTAL (w/o films)         , USi = 0.158
    #     = 6.54    TOTAL if floor            , USi = 0.153
    #     = 6.50    TOTAL if wall             , USi = 0.154
    #     = 6.44    TOTAL if roof             , USi = 0.156

    floor.setConstruction(derated_attic)
    derated_attic_RSi = 1.0 / floor.uFactor.to_f
    expect(derated_attic_RSi).to be_within(TOL).of(4.50)
    # puts "... derated attic thermal conductance:#{floor.thermalConductance}"
    # puts "... derated attic uFactor:#{floor.uFactor}"
    #     = 4.31    TOTAL (w/o films)         , USi = 0.232
    #     = 4.55    TOTAL if floor            , USi = 0.220
    #     = 4.46    TOTAL if wall             , USi = 0.224
    #     = 4.45    TOTAL if roof             , USi = 0.225

    floor.setConstruction(rated_perimeter)
    rated_perimeter_RSi = 1.0 / floor.uFactor.to_f
    expect(rated_perimeter_RSi).to be_within(TOL).of(2.03)
    # puts "... rated perimeter thermal conductance:#{floor.thermalConductance}"
    # puts "... rated Perimeter uFactor:#{floor.uFactor}"
    #     = 1.83    TOTAL (w/o films)         , USi = 0.546
    #     = 2.065   TOTAL if floor            , USi = 0.484
    #     = 1.98    TOTAL if wall             , USi = 0.505
    #     = 1.43    TOTAL if roof             , USi = 0.699

    floor.setConstruction(derated_perimeter)
    derated_perimeter_RSi = 1.0 / floor.uFactor.to_f
    expect(derated_perimeter_RSi).to be_within(TOL).of(1.016)
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
    # accommodate such faults (whether originally stemming from negligence or
    # as automatically-generated artefacts (from 3rd-party BIM/BEM packages).
    # The tests below demonstrate how TBD may (better) catch specific surface
    # anomalies that may invalidate TBD processes (while informing users),
    # instead of allowing Ruby crashes (quite uninformative). These tests are
    # likely to evolve over time, as they are reactions to user bug reports.

    # --- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- --- #
    # Catching slivers: TBD currently relies on a hardcoded, minimum 10mm
    # tolerance for edge lengths. One could argue anything under 100mm should be
    # redflagged. In any case, TBD should catch such surface slivers.
    translator = OpenStudio::OSVersion::VersionTranslator.new
    TBD.clean!

    msg   = "Empty 'polygon (non-collinears < 3)' (OSut::poly)"
    file  = File.join(__dir__, "files/osms/in/smalloffice.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    original = model.getSurfaceByName("Perimeter_ZN_1_wall_south")
    expect(original).to_not be_empty
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
    expect(original.setVertices(vec)).to be true

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
    expect(space).to_not be_empty
    space = space.get

    vec = OpenStudio::Point3dVector.new
    vec << OpenStudio::Point3d.new( 0.00, 0.00, 3.050)
    vec << OpenStudio::Point3d.new( 0.00, 0.00, 3.040)
    vec << OpenStudio::Point3d.new(27.69, 0.00, 3.040)
    vec << OpenStudio::Point3d.new(27.69, 0.00, 3.050)
    sliver = OpenStudio::Model::Surface.new(vec, model)
    sliver.setName("SLIVER")
    expect(sliver.setSpace(space)).to be true
    expect(sliver.setVertices(vec)).to be true

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

    # Relying on OSut's 'poly' method in isolation.
    expect(TBD.poly(sliver)).to be_empty
    expect(TBD.error?).to be true
    expect(TBD.logs.size).to eq(1)
    expect(TBD.logs.first[:message]).to include(msg)
    TBD.clean!

    expect(TBD.poly(original)).to_not be_empty
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty


    argh = { option: "(non thermal bridging)" }

    json     = TBD.process(model, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.error?).to be true
    expect(TBD.logs.size).to eq(2)
    expect(surfaces).to be_a(Hash)
    expect(surfaces.size).to eq(43)
    expect(io).to be_a(Hash)

    m1 = TBD.logs.first[:message]
    m2 = TBD.logs.last[ :message]
    expect(m1).to eq(msg)
    expect(m2).to eq("Invalid 'SLIVER' arg #1 (TBD::properties)")

    # Repeat exercice for subsurface as sliver.
    TBD.clean!
    file  = File.join(__dir__, "files/osms/in/smalloffice.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    door = model.getSubSurfaceByName("Perimeter_ZN_1_wall_south_door")
    expect(door).to_not be_empty
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
    expect(door.setVertices(vec)).to be true

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

    expect(TBD.poly(door)).to be_empty
    expect(TBD.error?).to be true
    expect(TBD.logs.size).to eq(1)
    message = TBD.logs.first[:message]
    expect(message).to include(msg)
  end

  it "checks for Frame & Divider reveals" do
    translator = OpenStudio::OSVersion::VersionTranslator.new
    TBD.clean!

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
    file = File.join(__dir__, "files/osms/in/smalloffice.osm")
    path = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    # 1. Run with an unaltered model.
    argh               = {}
    argh[:option     ] = "code (Quebec)"
    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")

    json     = TBD.process(model, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty
    expect(surfaces).to be_a(Hash)
    expect(surfaces.size).to eq(43)
    expect(io).to be_a(Hash)
    expect(io).to have_key(:edges)
    expect(io[:edges].size).to eq(105)

    expect(surfaces).to have_key("Perimeter_ZN_1_wall_south")
    surface = surfaces["Perimeter_ZN_1_wall_south"]
    expect(surface).to have_key(:ratio)
    expect(surface).to have_key(:heatloss)
    expect(surface[:ratio   ]).to be_within(TOL).of(-10.88)
    expect(surface[:heatloss]).to be_within(TOL).of( 23.40)

    # Mimic the export functionality of the measure and save .osm file.
    out1  = JSON.pretty_generate(io)
    file1 = File.join(__dir__, "../json/tbd_smalloffice3.out.json")
    File.open(file1, "w") { |f| f.puts out1 }
    pth   = File.join(__dir__, "files/osms/out/model_FD.osm")
    model.save(pth, true)

    # 2. Repeat, yet add Frame & Divider with outside reveal to 1x window.
    TBD.clean!

    file  = File.join(__dir__, "files/osms/in/smalloffice.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    # Fetch window & add 100mm outside reveal depth to F&D.
    sub = model.getSubSurfaceByName("Perimeter_ZN_1_wall_south_Window_1")
    expect(sub).to_not be_empty
    sub = sub.get
    fd  = OpenStudio::Model::WindowPropertyFrameAndDivider.new(model)
    fd.setName("Perimeter_ZN_1_wall_south_Window_1_fd")
    expect(fd.setOutsideRevealDepth(0.100)).to be true
    expect(fd.isOutsideRevealDepthDefaulted).to be false
    expect(fd.outsideRevealDepth).to be_within(TOL).of(0.100)
    expect(sub.setWindowPropertyFrameAndDivider(fd)).to be true

    argh               = {}
    argh[:option     ] = "code (Quebec)"
    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")

    json     = TBD.process(model, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty
    expect(surfaces).to be_a(Hash)
    expect(surfaces.size).to eq(43)
    expect(io).to be_a(Hash)
    expect(io).to have_key(:edges)
    expect(io[:edges].size).to eq(105)

    expect(surfaces).to have_key("Perimeter_ZN_1_wall_south")
    surface = surfaces["Perimeter_ZN_1_wall_south"]
    expect(surface).to have_key(:ratio)
    expect(surface).to have_key(:heatloss)
    expect(surface[:ratio   ]).to be_within(TOL).of(-10.88)
    expect(surface[:heatloss]).to be_within(TOL).of( 23.40)

    # Mimic the export functionality of the measure and save .osm file.
    out2  = JSON.pretty_generate(io)
    file2 = File.join(__dir__, "../json/tbd_smalloffice4.out.json")
    File.open(file2, "w") { |f| f.puts out2 }
    pth   = File.join(__dir__, "files/osms/out/model_FD_rvl.osm")
    model.save(pth, true)

    # Both wall and window are defined along the XZ plane. Comparing generated
    # .idf files, the Y-axis coordinates of the window with a Frame & Divider
    # reveal is indeed offset by 100mm vs its host wall vertices. Comparing
    # EnergyPlus results, host walls in both .idf files have the same derated
    # U-factors, and reference the same derated construction and material.
    expect(FileUtils).to be_identical(file1, file2)
  end

  it "checks for parallel edges in close proximity" do
    translator = OpenStudio::OSVersion::VersionTranslator.new
    TBD.clean!

    file  = File.join(__dir__, "files/osms/out/seb2.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get
    subs  = {}
    pops  = []

    # Consider the plenum as UNCONDITIONED.
    plnum = model.getSpaceByName("Level 0 Ceiling Plenum")
    expect(plnum).to_not be_empty
    plnum = plnum.get

    key = "space_conditioning_category"
    val = "Unconditioned"
    expect(plnum.additionalProperties.hasFeature(key)).to be false
    expect(plnum.additionalProperties.setFeature(key, val)).to be true
    expect(TBD.plenum?(plnum)).to be true
    expect(TBD.unconditioned?(plnum)).to be true
    expect(TBD.setpoints(plnum)[:heating]).to be_nil
    expect(TBD.setpoints(plnum)[:cooling]).to be_nil
    expect(TBD.status).to be_zero

    # Fetch base surfaces with windows.
    model.getSurfaces.each do |surface|
      windows = surface.subSurfaces
      next if windows.empty?

      expect(windows.size).to eq(1)
      pops << surface.nameString
    end

    expect(pops.size).to eq(8)

    argh               = {}
    argh[:option     ] = "code (Quebec)"
    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")

    json     = TBD.process(model, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty
    expect(surfaces).to be_a(Hash)
    expect(surfaces.size).to eq(56)
    expect(io).to be_a(Hash)
    expect(io).to have_key(:edges)
    expect(io[:edges].size).to eq(80) # 106 if plenum remained conditioned

    io[:edges].each do |edge|
      expect(edge).to be_a(Hash)
      expect(edge).to have_key(:surfaces)
      expect(edge).to have_key(:type)
      expect(edge).to have_key(:v0x)
      expect(edge).to have_key(:v1x)
      expect(edge).to have_key(:v0y)
      expect(edge).to have_key(:v1y)
      expect(edge).to have_key(:v0z)
      expect(edge).to have_key(:v1z)

      # Only process vertical edges, with each linking 1x subsurface. No two
      # subsurfaces share an edge in the seb2.osm, i.e. no two jamb edges are
      # within TOL of each other.
      next if (edge[:v0z] - edge[:v1z]).abs < TOL

      windows = edge[:surfaces].select { |s| s.include?("Sub Surface") }
      next if windows.empty?

      expect(windows.size).to eq(1)
      id   = windows.first
      line = {}
      type = edge[:type].to_s.downcase
      expect(type).to include("jamb")

      subs[id ] = [] unless subs.key?(id)
      line[:v0] = Topolys::Point3D.new(edge[:v0x], edge[:v0y], edge[:v0z])
      line[:v1] = Topolys::Point3D.new(edge[:v1x], edge[:v1y], edge[:v1z])
      subs[id ] << line
    end

    expect(subs.size).to eq(8)
    nb   = 0
    dads = {}

    subs.values.each { |sub| expect(sub.size).to eq(2) }

    subs.each do |id1, sub1|
      subs.each do |id2, sub2|
        next if id1 == id2

        sub1.each do |sb1|
          sub2.each do |sb2|
            # With default tolerances, none of the subsurface edges "match" up.
            expect(TBD.matches?(sb1, sb2)).to be false
            # Greater tolerances however trigger 5x matches, as follows:
            # "Sub Surface 7" ~ "Sub Surface 8" ~ "Sub Surface 6"
            # "Sub Surface 3" ~ "Sub Surface 5" ~ "Sub Surface 4"
            # "Sub Surface 1" ~ "Sub Surface 2"
            nb += 1 if TBD.matches?(sb1, sb2, 0.100)
          end
        end
      end
    end

    expect(nb).to eq(10) # twice 5x: each edge is once object, once subject

    subs.keys.each do |id|
      kid = model.getSubSurfaceByName(id)
      expect(kid).to_not be_empty
      kid = kid.get
      dad = kid.surface
      expect(dad).to_not be_empty
      dad = dad.get
      nom = dad.nameString

      expect(pops).to include(nom)
      expect(surfaces).to have_key(nom)
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

    file  = File.join(__dir__, "files/osms/out/seb2.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get
    subs  = {}

    # Consider the plenum as UNCONDITIONED.
    plnum = model.getSpaceByName("Level 0 Ceiling Plenum")
    expect(plnum).to_not be_empty
    plnum = plnum.get

    key = "space_conditioning_category"
    val = "Unconditioned"
    expect(plnum.additionalProperties.hasFeature(key)).to be false
    expect(plnum.additionalProperties.setFeature(key, val)).to be true
    expect(TBD.unconditioned?(plnum)).to be true
    expect(TBD.status).to be_zero

    argh               = {}
    argh[:option     ] = "code (Quebec)"
    argh[:schema_path] = File.join(__dir__, "../tbd.schema.json")
    argh[:sub_tol    ] = 0.100

    json     = TBD.process(model, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io       = json[:io      ]
    surfaces = json[:surfaces]
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty
    expect(surfaces).to be_a(Hash)
    expect(surfaces.size).to eq(56)
    expect(io).to be_a(Hash)
    expect(io).to have_key(:edges)
    expect(io[:edges].size).to eq(80)

    io[:edges].each do |edge|
      expect(edge).to be_a(Hash)
      expect(edge).to have_key(:surfaces)
      expect(edge).to have_key(:type)
      expect(edge).to have_key(:v0x)
      expect(edge).to have_key(:v1x)
      expect(edge).to have_key(:v0y)
      expect(edge).to have_key(:v1y)
      expect(edge).to have_key(:v0z)
      expect(edge).to have_key(:v1z)
      next if (edge[:v0z] - edge[:v1z]).abs < TOL

      windows = edge[:surfaces].select { |s| s.include?("Sub Surface") }
      next if windows.empty?

      expect(windows.size).to eq(1)
      id   = windows.first
      type = edge[:type].to_s.downcase

      subs[id] = [] unless subs.key?(id)
      subs[id] << type
    end

    expect(subs.size).to eq(8)

    # "Sub Surface 7" ~ "Sub Surface 8" ~ "Sub Surface 6"
    # "Sub Surface 3" ~ "Sub Surface 5" ~ "Sub Surface 4"
    # "Sub Surface 1" ~ "Sub Surface 2"
    subs.each do |id, types|
      expect(types.size).to eq(2)
      kid = model.getSubSurfaceByName(id)
      expect(kid).to_not be_empty
      kid = kid.get
      dad = kid.surface
      expect(dad).to_not be_empty
      dad = dad.get
      nom = dad.nameString

      expect(surfaces).to have_key(nom)
      loss = surfaces[nom][:heatloss]
      less = 0.200 # jamb PSI factor (in W/K per meter)
      # Sub Surface 6 : 0.496        (height in meters)
      # Sub Surface 8 : 0.488
      # Sub Surface 7 : 0.497
      # Sub Surface 5 : 1.153
      # Sub Surface 3 : 1.162
      # Sub Surface 4 : 1.163
      # Sub Surface 1 : 0.618
      # Sub Surface 2 : 0.618

      case id
      when "Sub Surface 5"
        expect(types).to include("transition")
        less *= (2 * 1.153) # 2x transitions; no jambs
      when "Sub Surface 8"
        expect(types).to include("transition")
        less *= (2 * 0.488) # 2x transitions; no jambs
      when "Sub Surface 6"
        expect(types).to include("jamb")
        expect(types).to include("transition")
        less *= (1 * 0.496) # 1x transition; 1x jamb
      when "Sub Surface 7"
        expect(types).to include("jamb")
        expect(types).to include("transition")
        less *= (1 * 0.497) # 1x transition; 1x jamb
      when "Sub Surface 3"
        expect(types).to include("jamb")
        expect(types).to include("transition")
        less *= (1 * 1.162) # 1x transition; 1x jamb
      when "Sub Surface 4"
        expect(types).to include("jamb")
        expect(types).to include("transition")
        less *= (1 * 1.163) # 1x transition; 1x jamb
      when "Sub Surface 1"
        expect(types).to include("jamb")
        expect(types).to include("transition")
        less *= (1 * 0.618) # 1x transition; 1x jamb
      when "Sub Surface 2"
        expect(types).to include("jamb")
        expect(types).to include("transition")
        less *= (1 * 0.618) # 1x transition; 1x jamb
      else
        expect(false).to be true
      end

      # 'dads[ (parent surface identifier) ]' holds TBD-estimated heat loss
      # from major thermal bridging (in W/K) in the initial case. The
      # substitution of 1x or 2x subsurface jamb edge types to (mild)
      # transition(s) reduces the (revised) heat loss in the second case.
      expect(loss + less).to be_within(TOL).of(dads[nom])
    end
  end

  it "checks for subsurface multipliers" do
    translator = OpenStudio::OSVersion::VersionTranslator.new
    TBD.clean!

    front = "Office Front Wall"
    left  = "Office Left Wall"
    file  = File.join(__dir__, "files/osms/in/warehouse.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    argh           = {}
    argh[:option ] = "code (Quebec)"
    argh[:gen_ua ] = true
    argh[:ua_ref ] = "code (Quebec)"
    argh[:version] = OpenStudio.openStudioVersion

    TBD.process(model, argh)
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty
    expect(argh).to have_key(:surfaces)
    expect(argh).to have_key(:io)
    io       = argh[:io      ]
    surfaces = argh[:surfaces]
    expect(surfaces.size).to eq(23)

    io[:description] = "test UA vs multipliers"

    ua = TBD.ua_summary(Time.now, argh)
    expect(ua).to_not be_nil
    expect(ua).to_not be_empty
    expect(ua).to be_a(Hash)
    expect(ua).to have_key(:model)

    mult_ud_md = TBD.ua_md(ua, :en)
    pth        = File.join(__dir__, "files/ua/ua_mult.md")
    File.open(pth, "w") { |file| file.puts mult_ud_md }

    [front, left].each do |side|
      wall = model.getSurfaceByName(side)
      expect(wall).to_not be_empty
      wall = wall.get

      if side == front
        sub_area = (1 * 3.90) + (2 * 5.58) # 1x double-width door + 2x windows
        expect(wall.grossArea).to be_within(TOL).of(110.54)
        expect(wall.netArea  ).to be_within(TOL).of( 95.49)
        expect(wall.netArea  ).to be_within(0.05).of(wall.grossArea - sub_area)
      else # side == left
        sub_area = (1 * 1.95) + (2 * 3.26) # 1x single-width door + 2x windows
        expect(wall.grossArea).to be_within(TOL).of( 39.02)
        expect(wall.netArea  ).to be_within(TOL).of( 30.56)
        expect(wall.netArea  ).to be_within(0.05).of(wall.grossArea - sub_area)
      end

      expect(surfaces).to have_key(side)
      expect(surfaces[side]).to have_key(:windows)
      expect(surfaces[side][:windows].size).to eq(2)

      surfaces[side][:windows].keys.each do |sub|
        expect(sub).to include(side)
        expect(sub).to include(" Window")
      end

      expect(surfaces[side]).to have_key(:heatloss)
      hloss = surfaces[side][:heatloss]

      # Per office ouside-facing wall:
      #   - nb: number of distinct edges, per MAJOR thermal bridge type
      #   - lm: total edge lengths (m), per MAJOR thermal bridge type
      jambs     = { nb: 0, lm: 0 }
      sills     = { nb: 0, lm: 0 }
      heads     = { nb: 0, lm: 0 }
      doorjambs = { nb: 0, lm: 0 }
      doorsills = { nb: 0, lm: 0 }
      doorheads = { nb: 0, lm: 0 }
      grades    = { nb: 0, lm: 0 }
      rims      = { nb: 0, lm: 0 }
      corners   = { nb: 0, lm: 0 }

      io[:edges].each do |edge|
        expect(edge).to have_key(:surfaces)
        expect(edge[:surfaces]).to be_an(Array)
        expect(edge[:surfaces]).to_not be_empty
        next unless edge[:surfaces].include?(side)

        expect(edge).to have_key(:length)
        expect(edge).to have_key(:type)
        next if edge[:type] == :transition

        case edge[:type]
        when :jamb
          jambs[    :nb] += 1
          jambs[    :lm] += edge[:length]
        when :sill
          sills[    :nb] += 1
          sills[    :lm] += edge[:length]
        when :head
          heads[    :nb] += 1
          heads[    :lm] += edge[:length]
        when :doorjamb
          doorjambs[:nb] += 1
          doorjambs[:lm] += edge[:length]
        when :doorsill
          doorsills[:nb] += 1
          doorsills[:lm] += edge[:length]
        when :doorhead
          doorheads[:nb] += 1
          doorheads[:lm] += edge[:length]
        when :gradeconvex
          grades[   :nb] += 1
          grades[   :lm] += edge[:length]
        when :rimjoist
          rims[     :nb] += 1
          rims[     :lm] += edge[:length]
        else
          corners[  :nb] += 1
          corners[  :lm] += edge[:length]
        end
      end

      expect(    jambs[:nb]).to eq(4) # 2x windows ... 2x
      expect(    sills[:nb]).to eq(2) # 2x windows
      expect(    heads[:nb]).to eq(2) # 2x windows
      expect(doorjambs[:nb]).to eq(2) # 1x door ... 2x
      expect(doorsills[:nb]).to eq(0) # 1x door
      expect(doorheads[:nb]).to eq(1) # 1x door
      expect(   grades[:nb]).to eq(3) # split by door sill
      expect(     rims[:nb]).to eq(1)
      expect(  corners[:nb]).to eq(1)

      if side == front
        expect(    jambs[:lm]).to be_within(TOL).of( 6.10)
        expect(    sills[:lm]).to be_within(TOL).of( 7.31)
        expect(    heads[:lm]).to be_within(TOL).of( 7.31)
        expect(doorjambs[:lm]).to be_within(TOL).of( 4.27)
        expect(doorsills[:lm]).to be_within(TOL).of( 0.00)
        expect(doorheads[:lm]).to be_within(TOL).of( 1.83)
        expect(   grades[:lm]).to be_within(TOL).of(25.91)
        expect(     rims[:lm]).to be_within(TOL).of(25.91) # same as grade
        expect(  corners[:lm]).to be_within(TOL).of( 4.27)

        loss  = 0.200 * (jambs[:lm] + sills[:lm] + heads[:lm])
        loss += 0.200 * (doorjambs[:lm] + doorsills[:lm] + doorheads[:lm])
        loss += 0.450 * grades[:lm]
        loss += 0.300 * (rims[:lm] + corners[:lm]) / 2
        expect(loss ).to be_within(TOL).of(21.55)
        expect(hloss).to be_within(TOL).of(loss)
      else # left
        expect(    jambs[:lm]).to be_within(TOL).of( 6.10) # same as front
        expect(    sills[:lm]).to be_within(TOL).of( 4.27)
        expect(    heads[:lm]).to be_within(TOL).of( 4.27)
        expect(doorjambs[:lm]).to be_within(TOL).of( 4.27) # same as front
        expect(doorsills[:lm]).to be_within(TOL).of( 0.00)
        expect(doorheads[:lm]).to be_within(TOL).of( 0.91)
        expect(   grades[:lm]).to be_within(TOL).of( 9.14)
        expect(     rims[:lm]).to be_within(TOL).of( 9.14) # same as grade
        expect(  corners[:lm]).to be_within(TOL).of( 4.27) # same as front
        expect(hloss         ).to be_within(TOL).of(10.09)
      end
    end

    # Re-open model and add multipliers to both front & left subsurfaces.
    TBD.clean!

    mult  = 2
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    # Set subsurface multipliers.
    model.getSubSurfaces.each do |sub|
      parent    = sub.surface
      expect(parent).to_not be_empty
      parent    = parent.get
      front_sub = parent.nameString.include?(front)
      left_sub  = parent.nameString.include?(left)
      next unless front_sub || left_sub

      expect(sub.setMultiplier(mult)).to be true
      expect(sub.multiplier         ).to eq(mult)
    end

    argh           = {}
    argh[:option ] = "code (Quebec)"
    argh[:gen_ua ] = true
    argh[:ua_ref ] = "code (Quebec)"
    argh[:version] = OpenStudio.openStudioVersion

    json = TBD.process(model, argh)
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty
    expect(argh).to have_key(:io)
    expect(argh).to have_key(:surfaces)
    io       = argh[:io      ]
    surfaces = argh[:surfaces]

    argh[:io][:description] = "test UA vs multipliers"

    ua2 = TBD.ua_summary(Time.now, argh)
    expect(ua2).to_not be_nil
    expect(ua2).to_not be_empty
    expect(ua2).to be_a(Hash)
    expect(ua2).to have_key(:model)

    mult_ud_md2 = TBD.ua_md(ua2, :en)
    pth         = File.join(__dir__, "files/ua/ua_mult2.md")

    File.open(pth, "w") { |file| file.puts mult_ud_md2 }

    [front, left].each do |side|
      wall = model.getSurfaceByName(side)
      expect(wall).to_not be_empty
      wall = wall.get

      if side == front
        sub_area = (2 * 3.90) + (4 * 5.58) # 2x double-width door + 4x windows
        expect(wall.grossArea).to be_within(TOL).of(110.54)
        expect(wall.netArea  ).to be_within(TOL).of( 80.43)
        expect(wall.netArea  ).to be_within(0.05).of(wall.grossArea - sub_area)
      else # side == left
        sub_area = (2 * 1.95) + (4 * 3.26) # 2x single-width door + 4x windows
        expect(wall.grossArea).to be_within(TOL).of( 39.02)
        expect(wall.netArea  ).to be_within(TOL).of( 22.10)
        expect(wall.netArea  ).to be_within(0.05).of(wall.grossArea - sub_area)
      end

      expect(surfaces).to have_key(side)
      expect(surfaces[side]).to have_key(:windows)
      expect(surfaces[side][:windows].size).to eq(2)

      surfaces[side][:windows].keys do |sub|
        expect(sub).to include(side)
        expect(sub).to include(" Window")
      end

      # 2nd tallies, per office ouside-facing wall:
      #   - nb: number of distinct edges, per MAJOR thermal bridge type
      #   - lm: total edge lengths (m), per MAJOR thermal bridge type
      jambs2     = { nb: 0, lm: 0 }
      sills2     = { nb: 0, lm: 0 }
      heads2     = { nb: 0, lm: 0 }
      doorjambs2 = { nb: 0, lm: 0 }
      doorsills2 = { nb: 0, lm: 0 }
      doorheads2 = { nb: 0, lm: 0 }
      grades2    = { nb: 0, lm: 0 }
      rims2      = { nb: 0, lm: 0 }
      corners2   = { nb: 0, lm: 0 }

      io[:edges].each do |edge|
        expect(edge).to have_key(:surfaces)
        expect(edge[:surfaces]).to be_a(Array)
        expect(edge[:surfaces]).to_not be_empty
        next unless edge[:surfaces].include?(side)

        expect(edge).to have_key(:length)
        expect(edge).to have_key(:type  )
        next if edge[:type] == :transition

        case edge[:type]
        when :jamb
          jambs2[    :nb] += 1
          jambs2[    :lm] += edge[:length]
        when :sill
          sills2[    :nb] += 1
          sills2[    :lm] += edge[:length]
        when :head
          heads2[    :nb] += 1
          heads2[    :lm] += edge[:length]
        when :doorjamb
          doorjambs2[:nb] += 1
          doorjambs2[:lm] += edge[:length]
        when :doorsill
          doorsills2[:nb] += 1
          doorsills2[:lm] += edge[:length]
        when :doorhead
          doorheads2[:nb] += 1
          doorheads2[:lm] += edge[:length]
        when :gradeconvex
          grades2[   :nb] += 1
          grades2[   :lm] += edge[:length]
        when :rimjoist
          rims2[     :nb] += 1
          rims2[     :lm] += edge[:length]
        else
          corners2[  :nb] += 1
          corners2[  :lm] += edge[:length]
        end
      end

      expect(surfaces[side]).to have_key(:heatloss)
      hloss = surfaces[side][:heatloss]

      # No change vs initial, unaltered model.
      expect(    jambs2[:nb]).to eq(4)
      expect(    sills2[:nb]).to eq(2)
      expect(    heads2[:nb]).to eq(2)
      expect(doorjambs2[:nb]).to eq(2)
      expect(doorsills2[:nb]).to eq(0)
      expect(doorheads2[:nb]).to eq(1)
      expect(   grades2[:nb]).to eq(3)
      expect(     rims2[:nb]).to eq(1)
      expect(  corners2[:nb]).to eq(1)

      if side == front
        expect(    jambs2[:lm]).to be_within(TOL).of( 6.10 * mult)
        expect(    sills2[:lm]).to be_within(TOL).of( 7.31 * mult)
        expect(    heads2[:lm]).to be_within(TOL).of( 7.31 * mult)
        expect(doorjambs2[:lm]).to be_within(TOL).of( 4.27 * mult)
        expect(doorsills2[:lm]).to be_within(TOL).of( 0.00 * mult)
        expect(doorheads2[:lm]).to be_within(TOL).of( 1.83 * mult)
        expect(     rims2[:lm]).to be_within(TOL).of(25.91) # unchanged
        expect(  corners2[:lm]).to be_within(TOL).of( 4.27) # unchanged

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
        expect(grades2[:lm]).to be_within(TOL).of(25.91 + 2 * 0.915)

        # This (user-selected) discrepancy can easily be countered (by the very
        # same user), by proportionally adjusting the selected "grade" PSI
        # factor (using TBD JSON customization). For this reason, TBD will not
        # raise this as an error. Nonetheless, the use of subsurface multipliers
        # will require a clear set of recommendations in TBD's online Guide.
        extra  = 0.200 *     jambs2[:lm] / 2
        extra += 0.200 *     sills2[:lm] / 2
        extra += 0.200 *     heads2[:lm] / 2
        extra += 0.200 * doorjambs2[:lm] / 2
        extra += 0.200 * doorheads2[:lm] / 2
        extra += 0.200 * doorsills2[:lm] / 2
        extra += 0.450 * 2 * 0.915
        expect(extra).to be_within(TOL).of(6.19)
        expect(hloss).to be_within(TOL).of(21.55 + extra)
      else # left
        expect(    jambs2[:lm]).to be_within(TOL).of( 6.10 * mult)
        expect(    sills2[:lm]).to be_within(TOL).of( 4.27 * mult)
        expect(    heads2[:lm]).to be_within(TOL).of( 4.27 * mult)
        expect(doorjambs2[:lm]).to be_within(TOL).of( 4.27 * mult)
        expect(doorsills2[:lm]).to be_within(TOL).of( 0.00 * mult)
        expect(doorheads2[:lm]).to be_within(TOL).of( 0.91 * mult)
        expect(     rims2[:lm]).to be_within(TOL).of( 9.14) # unchanged
        expect(  corners2[:lm]).to be_within(TOL).of( 4.27) # unchanged

        # See above comments for grade vs sill discrepancy.
        expect(grades2[:lm]).to be_within(TOL).of(9.14 + 0.915)

        extra  = 0.200 * jambs2[:lm] / 2
        extra += 0.200 * sills2[:lm] / 2
        extra += 0.200 * heads2[:lm] / 2
        extra += 0.200 * doorjambs2[:lm] / 2
        extra += 0.200 * doorheads2[:lm] / 2
        extra += 0.200 * doorsills2[:lm] / 2
        extra += 0.450 * 0.915
        expect(extra).to be_within(TOL).of(4.37)
        expect(hloss).to be_within(TOL).of(10.09 + extra)
      end
    end
  end

  it "checks for subsurface vertex inheritance" do
    translator = OpenStudio::OSVersion::VersionTranslator.new
    TBD.clean!

    file  = File.join(__dir__, "files/osms/in/warehouse.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
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

    expect(wall).to_not be_empty
    expect(door).to_not be_empty
    wall     = wall.get
    door     = door.get
    parent   = door.surface
    expect(parent).to_not be_empty
    parent   = parent.get
    expect(parent).to eq(wall)

    door.vertices.each { |vtx| minY = [minY,vtx.y].min }
    door.vertices.each { |vtx| maxZ = [maxZ,vtx.z].max }

    expect(minY).to be_within(TOL).of(19.35)
    expect(maxZ).to be_within(TOL).of( 2.13)

    # Adding a partial-height (sill +900mm above grade, width 500mm) sidelight,
    # adjacent to the door (sharing an edge).
    vertices  = OpenStudio::Point3dVector.new
    vertices << OpenStudio::Point3d.new(0.0, minY      , maxZ)
    vertices << OpenStudio::Point3d.new(0.0, minY      ,  0.9)
    vertices << OpenStudio::Point3d.new(0.0, minY - 0.5,  0.9)
    vertices << OpenStudio::Point3d.new(0.0, minY - 0.5, maxZ)
    sidelight = OpenStudio::Model::SubSurface.new(vertices, model)
    sidelight.setName(leftside)

    expect(sidelight.setSubSurfaceType("FixedWindow")).to be true
    expect(sidelight.setSurface(wall)                ).to be true

    argh = { option: "code (Quebec)" }

    json      = TBD.process(model, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io        = json[:io      ]
    surfaces  = json[:surfaces]
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty
    expect(io).to be_a(Hash)
    expect(io).to have_key(:edges)
    expect(io[:edges].size).to eq(304)

    expect(surfaces).to have_key(leftwall)
    expect(surfaces[leftwall]).to have_key(:heatloss)
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
      expect(edge).to have_key(:surfaces)
      expect(edge[:surfaces]).to be_a(Array)
      expect(edge[:surfaces]).to_not be_empty
      next unless edge[:surfaces].include?(leftside)

      expect(edge).to have_key(:type)
      expect(edge).to have_key(:length)

      side_heads += 1 if edge[:type].to_s.include?("head")
      side_sills += 1 if edge[:type].to_s.include?("sill")
      side_jambs += 1 if edge[:type].to_s.include?("jamb")
      side_trns  += 1 if edge[:type].to_s.include?("transition")

      side_head_m += edge[:length] if edge[:type].to_s.include?("head")
      side_sill_m += edge[:length] if edge[:type].to_s.include?("sill")
      side_jamb_m += edge[:length] if edge[:type].to_s.include?("jamb")
      side_trns_m += edge[:length] if edge[:type].to_s.include?("transition")
    end

    expect(side_heads).to eq(1)
    expect(side_sills).to eq(1)
    expect(side_jambs).to eq(1) # instead shared with door
    expect(side_trns ).to eq(1) # shared with initial left door

    expect(side_head_m).to be_within(TOL).of(       0.5)
    expect(side_sill_m).to be_within(TOL).of(       0.5)
    expect(side_jamb_m).to be_within(TOL).of(maxZ - 0.9)
    expect(side_trns_m).to be_within(TOL).of(maxZ - 0.9) # same as jamb

    io[:edges].each do |edge|
      expect(edge).to have_key(:surfaces)
      expect(edge[:surfaces]).to be_a(Array)
      expect(edge[:surfaces]).to_not be_empty
      next unless edge[:surfaces].include?(leftdoor)

      expect(edge).to have_key(:type)
      expect(edge).to have_key(:length)

      door_grade += 1 if edge[:type].to_s.include?("grade")
      door_heads += 1 if edge[:type].to_s.include?("head")
      door_sills += 1 if edge[:type].to_s.include?("sill")
      door_jambs += 1 if edge[:type].to_s.include?("jamb")
      door_trns  += 1 if edge[:type].to_s.include?("transition") # shared

      door_head_m += edge[:length] if edge[:type].to_s.include?("head")
      door_sill_m += edge[:length] if edge[:type].to_s.include?("sill")
      door_jamb_m += edge[:length] if edge[:type].to_s.include?("jamb")
      door_trns_m += edge[:length] if edge[:type].to_s.include?("transition")
    end

    # 5x edges (instead of original 4x).
    expect(door_grade).to eq(1)
    expect(door_heads).to eq(1)
    expect(door_sills).to be_zero # overriden as grade
    expect(door_jambs).to eq(2) # 1x full height + 1x partial height
    expect(door_trns ).to eq(1) # shared with sidelight

    expect(door_jamb_m).to be_within(TOL).of(maxZ + 0.9)
    expect(door_trns_m).to be_within(TOL).of(maxZ - 0.9) # same as sidelight


    # Repeat exercise with a transorm above door and sidelight.
    TBD.clean!

    file  = File.join(__dir__, "files/osms/in/warehouse.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    trnsom = "Fine Storage Left Transom"
    minY   = 1000
    maxY   = 0
    maxZ   = 0
    wall   = model.getSurfaceByName(leftwall)
    door   = model.getSubSurfaceByName(leftdoor)
    expect(wall).to_not be_empty
    expect(door).to_not be_empty
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
    expect(sidelight.setSubSurfaceType("FixedWindow")).to be true
    expect(sidelight.setSurface(wall)                ).to be true

    # Adding a transom over the full width of the door and sidelight.
    vertices  = OpenStudio::Point3dVector.new
    vertices << OpenStudio::Point3d.new(0.0, maxY      , maxZ + 0.4)
    vertices << OpenStudio::Point3d.new(0.0, maxY      , maxZ      )
    vertices << OpenStudio::Point3d.new(0.0, minY - 0.5, maxZ      )
    vertices << OpenStudio::Point3d.new(0.0, minY - 0.5, maxZ + 0.4)
    transom   = OpenStudio::Model::SubSurface.new(vertices, model)
    transom.setName(trnsom)

    expect(transom.setSubSurfaceType("FixedWindow")).to be true
    expect(transom.setSurface(wall)                ).to be true

    argh = { option: "code (Quebec)" }

    json      = TBD.process(model, argh)
    expect(json).to be_a(Hash)
    expect(json).to have_key(:io)
    expect(json).to have_key(:surfaces)
    io        = json[:io      ]
    surfaces  = json[:surfaces]
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty
    expect(io).to be_a(Hash)
    expect(io).to have_key(:edges)
    expect(io[:edges].size).to eq(307)

    expect(surfaces).to have_key(leftwall)
    expect(surfaces[leftwall]).to have_key(:heatloss)
    hloss2 = surfaces[leftwall][:heatloss]

    # Additional heat loss (versus initial case with 1x + 1x sidelight) is
    # limited to the 2x transom jambs x 0.200 W/m2.K
    expect(hloss2 - hloss1).to be_within(TOL).of(2 * 0.4 * 0.200)

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
      expect(edge).to have_key(:surfaces)
      expect(edge[:surfaces]).to be_a(Array)
      expect(edge[:surfaces]).to_not be_empty
      next unless edge[:surfaces].include?(leftside)

      expect(edge).to have_key(:type)
      expect(edge).to have_key(:length)

      side_heads += 1 if edge[:type].to_s.include?("head")
      side_sills += 1 if edge[:type].to_s.include?("sill")
      side_jambs += 1 if edge[:type].to_s.include?("jamb")
      side_trns  += 1 if edge[:type].to_s.include?("transition")

      side_head_m += edge[:length] if edge[:type].to_s.include?("head")
      side_sill_m += edge[:length] if edge[:type].to_s.include?("sill")
      side_jamb_m += edge[:length] if edge[:type].to_s.include?("jamb")
      side_trns_m += edge[:length] if edge[:type].to_s.include?("transition")
    end

    expect(side_heads).to be_zero # instead shared with transom
    expect(side_sills).to eq(1)
    expect(side_jambs).to eq(1) # instead shared with door
    expect(side_trns ).to eq(2) # shared with left door & transom

    expect(side_head_m).to be_within(TOL).of(             0.0)
    expect(side_sill_m).to be_within(TOL).of(             0.5)
    expect(side_jamb_m).to be_within(TOL).of(maxZ - 0.9      )
    expect(side_trns_m).to be_within(TOL).of(maxZ - 0.9 + 0.5)

    io[:edges].each do |edge|
      expect(edge).to have_key(:surfaces)
      expect(edge[:surfaces]).to be_a(Array)
      expect(edge[:surfaces]).to_not be_empty
      next unless edge[:surfaces].include?(leftdoor)

      expect(edge).to have_key(:type)
      expect(edge).to have_key(:length)

      door_grade += 1 if edge[:type].to_s.include?("grade")
      door_heads += 1 if edge[:type].to_s.include?("head")
      door_sills += 1 if edge[:type].to_s.include?("sill")
      door_jambs += 1 if edge[:type].to_s.include?("jamb")
      door_trns  += 1 if edge[:type].to_s.include?("transition") # shared

      door_head_m += edge[:length] if edge[:type].to_s.include?("head")
      door_sill_m += edge[:length] if edge[:type].to_s.include?("sill")
      door_jamb_m += edge[:length] if edge[:type].to_s.include?("jamb")
      door_trns_m += edge[:length] if edge[:type].to_s.include?("transition")
    end

    # Again, 5x edges (instead of original 4x).
    expect(door_grade).to eq(1)
    expect(door_heads).to be_zero # now shared with transom (see transition)
    expect(door_sills).to be_zero # overriden as grade
    expect(door_jambs).to eq(2) # 1x full height + 1x partial height
    expect(door_trns ).to eq(2) # shared with sidelight + transom

    expect(door_jamb_m).to be_within(TOL).of(maxZ + 0.9)
    expect(door_trns_m).to be_within(TOL).of(maxZ - 0.9 + maxY - minY)

    io[:edges].each do |edge|
      expect(edge).to have_key(:surfaces)
      expect(edge[:surfaces]).to be_a(Array)
      expect(edge[:surfaces]).to_not be_empty
      next unless edge[:surfaces].include?(trnsom)

      expect(edge).to have_key(:type)
      expect(edge).to have_key(:length)

      trsm_heads += 1 if edge[:type].to_s.include?("head")
      trsm_sills += 1 if edge[:type].to_s.include?("sill")
      trsm_jambs += 1 if edge[:type].to_s.include?("jamb")
      trsm_trns  += 1 if edge[:type].to_s.include?("transition") # shared

      trsm_head_m += edge[:length] if edge[:type].to_s.include?("head")
      trsm_sill_m += edge[:length] if edge[:type].to_s.include?("sill")
      trsm_jamb_m += edge[:length] if edge[:type].to_s.include?("jamb")
      trsm_trns_m += edge[:length] if edge[:type].to_s.include?("transition")
    end

    # 5x edges (instead of original 4x).
    expect(trsm_heads).to eq(1)
    expect(trsm_sills).to be_zero # instead shared with door and sidelight
    expect(trsm_jambs).to eq(2)   # 1x full height + 1x partial height
    expect(trsm_trns ).to eq(2)   # shared with sidelight + door

    expect(trsm_jamb_m).to be_within(TOL).of(2 * 0.4          )
    expect(trsm_trns_m).to be_within(TOL).of(maxY - minY + 0.5)
    expect(trsm_head_m).to be_within(TOL).of(trsm_trns_m      )
  end

  it "validate (uprated) BTAP output" do
    translator = OpenStudio::OSVersion::VersionTranslator.new
    version    = OpenStudio.openStudioVersion.split(".").join.to_i
    TBD.clean!

    if version > 300
      file  = File.join(__dir__, "files/osms/in/resto.osm")
      path  = OpenStudio::Path.new(file)
      model = translator.loadModel(path)
      expect(model).to_not be_empty
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

      argh                = {}
      argh[:schema_path ] = File.join(__dir__, "../tbd.schema.json")
      argh[:io_path     ] = File.join(__dir__, "../json/tbd_resto_btap.json")
      argh[:uprate_walls] = true
      argh[:wall_option ] = "ALL wall constructions"
      argh[:wall_ut     ] = 0.210 # NECB CZ7 2017 (RSi 4.76 / R27)

      TBD.process(model, argh)
      expect(TBD.status).to be_zero
      expect(TBD.logs).to be_empty

      expect(argh).to have_key(:wall_uo)
      expect(argh[:wall_uo]).to be_within(TOL).of(0.00236) # RSi 423 (R2K)
    end
  end

  it "can process floorszone multipliers" do
    translator = OpenStudio::OSVersion::VersionTranslator.new
    TBD.clean!

    file  = File.join(__dir__, "files/osms/in/midrise.osm")
    path  = OpenStudio::Path.new(file)
    model = translator.loadModel(path)
    expect(model).to_not be_empty
    model = model.get

    argh = { option: "code (Quebec)" }

    TBD.process(model, argh)
    expect(TBD.status).to be_zero
    expect(TBD.logs).to be_empty
    expect(argh).to have_key(:io)
    expect(argh).to have_key(:surfaces)
    io       = argh[:io      ]
    surfaces = argh[:surfaces]
    expect(surfaces).to be_a(Hash)
    expect(surfaces.size).to eq(180)
    expect(io).to be_a(Hash)
    expect(io).to have_key(:edges)
    expect(io[:edges].size).to eq(282)

    model.getSurfaces.each do |surface|
      id = surface.nameString
      next unless surface.surfaceType.downcase == "floor"
      next     if surface.isGroundSurface

      facing = surface.outsideBoundaryCondition.downcase
      floor  = id.downcase.include?("floor")
      top    = id.downcase.include?("t ")
      mid    = id.downcase.include?("m ")
      expect(floor && (top || mid)).to be true
      expect(facing).to eq("adiabatic")

      io[:edges].each do |edge|
        next unless edge[:surfaces].include?(id)

        expect(edge[:type]).to eq(:rimjoist)
      end
    end
  end
end
