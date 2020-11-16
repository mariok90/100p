
using CSV, DataFrames, Dates, JuMP, Statistics, LinearAlgebra, Base.Threads
using PyCall, SparseArrays, Gurobi

# pyimport_conda("networkx","networkx")
# pyimport_conda("matplotlib.pyplot","matplotlib")
# pyimport_conda("plotly","plotly")

include("C:/Users/pacop/.julia/dev/AnyMOD.jl/src/objects.jl")
include("C:/Users/pacop/.julia/dev/AnyMOD.jl/src/tools.jl")
include("C:/Users/pacop/.julia/dev/AnyMOD.jl/src/modelCreation.jl")

include("C:/Users/pacop/.julia/dev/AnyMOD.jl/src/optModel/exchange.jl")
include("C:/Users/pacop/.julia/dev/AnyMOD.jl/src/optModel/objective.jl")
include("C:/Users/pacop/.julia/dev/AnyMOD.jl/src/optModel/other.jl")
include("C:/Users/pacop/.julia/dev/AnyMOD.jl/src/optModel/tech.jl")

include("C:/Users/pacop/.julia/dev/AnyMOD.jl/src/dataHandling/mapping.jl")
include("C:/Users/pacop/.julia/dev/AnyMOD.jl/src/dataHandling/parameter.jl")
include("C:/Users/pacop/.julia/dev/AnyMOD.jl/src/dataHandling/readIn.jl")
include("C:/Users/pacop/.julia/dev/AnyMOD.jl/src/dataHandling/tree.jl")
include("C:/Users/pacop/.julia/dev/AnyMOD.jl/src/dataHandling/util.jl")


model_object = anyModel(["baseData","scenarios/testingCopper","timeSeries/daily"],"_results", objName = "copperFirst");


model_object.graInfo.names["grid"] = "grid battery"
model_object.graInfo.names["home"] = "home battery"
model_object.graInfo.names["pumpedHydro"] = "pumped Hydro"
model_object.graInfo.names["caes"] = "CAES"
model_object.graInfo.names["biomassPlant"] = "biomass plant"
model_object.graInfo.names["ror"] = "run-of-river"
model_object.graInfo.names["rooftop"] = "PV, rooftop"
model_object.graInfo.names["openspace"] = "PV, open-space"
model_object.graInfo.names["wind_offshore"] = "wind offshore"
model_object.graInfo.names["wind_onshore"] = "wind onshore"
model_object.graInfo.names["electrolysis"] = "electrolysis"
model_object.graInfo.names["ocgtHydrogen"] = "hydrogen turbine"
model_object.graInfo.names["electricMobility"] = "electric vehicles"
model_object.graInfo.names["electricResidentalHeating"] = "electric heater"
model_object.graInfo.names["electricIndustryHeating"] = "electric furnace"
model_object.graInfo.names["methanation"] = "methanation"
model_object.graInfo.names["fermenter"] = "fermenter"
model_object.graInfo.names["gasPlant"] = "ccgt plant"
model_object.graInfo.names["electricity"] = "electricity"

# define german names for carriers
model_object.graInfo.names["electricity_central"] = "central"
model_object.graInfo.names["electricity_decentral"] = "decentral"
model_object.graInfo.names["heatResidental"] = "residential heat"
model_object.graInfo.names["heatIndustry"] = "process heat"
model_object.graInfo.names["gas"] = "gas"
model_object.graInfo.names["synthGas"] = "methane"
model_object.graInfo.names["hydrogen"] = "hydrogen"
model_object.graInfo.names["biomass"] = "biomass"
model_object.graInfo.names["mobility"] = "e-mobility"

# define german names for other labels
model_object.graInfo.names["demand"] = "demand"
model_object.graInfo.names["netImport"] = "Netto-Import"
model_object.graInfo.names["netExport"] = "Netto-Export"
model_object.graInfo.names["trdBuy"] = "Import*"

 # define colors of carriers
model_object.graInfo.colors["electricity_central"] = (1.0, 0.9215, 0.2313)
model_object.graInfo.colors["electricity_decentral"] = (1.0, 0.9215, 0.2313)
model_object.graInfo.colors["heatResidental"] = (0.769, 0.176, 0.29)
model_object.graInfo.colors["heatIndustry"] = (0.769, 0.176, 0.29)
model_object.graInfo.colors["mobility"] = (111/265, 200/265, 182/265)




#plotEnergyFlow(:graph,model_object,replot = true, initTemp = 6.0, scaDist = 3.0, maxIter = 50000, fontSize = 12)


#moveNode!(model_object,[("electricity",[-0.05,-0.05]),("electricity_central",[0.0,0.0]),("electricity_decentral",[0.0,0.0])])

moveNode!(model_object,[("electricity",[0.0,0.0]),("electricMobility",[0.0,0.0]),("rooftop",[0.0,-0.01])])
moveNode!(model_object,[("home",[-0.03,-0.03]),("electricResidentalHeating",[0.0,0.0]),("electricity_central",[0.0,0.0])])

#moveNode!(model_object,[("electricResidentalHeating",[0.0,0.0]),("grid",[0.0,0.01]),("electricMobility",[0.0,0.0])])
moveNode!(model_object,[("fermenter",[0.0,0.0]),("biomass",[-0.01,-0.01]),("biomass plant",[0.0,0.0])])
plotEnergyFlow(:graph,model_object,replot = false, fontSize = 12)

