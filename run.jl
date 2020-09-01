using Gurobi

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

tradeInbalance_fl = 0


# * alternative zu code oben: using AnyMOD, Gurobi (dev branch von AnyMOD muss installiert sein!)

#region # ! copperplate scenario

# * solve as copperplate
model_object = anyModel(["baseData","scenarios/testingCopper","timeSeries/daily"],"_results", objName = "copperFirstHigh");

createOptModel!(model_object);
setObjective!(:costs, model_object);

# limits the imbalance of the trade balance
deRegions_arr = vcat([6],model_object.sets[:R].nodes[6].down);

export_arr = filter(x -> x.R_from in deRegions_arr && !(x.R_to in deRegions_arr) && x.C == 7, model_object.parts.exc.var[:exc])[!,:var];
import_arr = filter(x -> x.R_to in deRegions_arr && !(x.R_from in deRegions_arr) && x.C == 7, model_object.parts.exc.var[:exc])[!,:var];

@constraint(model_object.optModel, tradebalance, sum(export_arr) + tradeInbalance_fl >= sum(import_arr));


set_optimizer(model_object.optModel,Gurobi.Optimizer);
set_optimizer_attribute(model_object.optModel, "Method", 2);
set_optimizer_attribute(model_object.optModel, "Crossover", 1);
optimize!(model_object.optModel);

reportResults(:summary,model_object);
reportResults(:exchange,model_object);
reportResults(:costs,model_object);
plotEnergyFlow(:sankey,model_object);

# * obtain capacities for technologies and write to parameter file
eeSym_arr = filter(x -> model_object.parts.tech[x].type == :mature &&  keys(model_object.parts.tech[x].carrier)  |> (y -> :gen in y && !(:use in y)), collect(keys(model_object.parts.tech)));
eeId_arr = map(x -> filter(y -> y.val == string(x),collect(values(model_object.sets[:Te].nodes)))[1].idx , eeSym_arr);
noEeSym_arr = filter(x -> !(x in eeSym_arr) && model_object.parts.tech[x].type == :mature, collect(keys(model_object.parts.tech)));
nonEeId_arr = map(x -> filter(y -> y.val == string(x),collect(values(model_object.sets[:Te].nodes)))[1].idx , noEeSym_arr);

allNuts3_arr = getfield.(filter(x -> x.lvl == 2 && model_object.sets[:R].up[x.idx] == 6, collect(values(model_object.sets[:R].nodes))),:idx);

# get share of total ee production per region
eeVlh_dic = Dict((filter(y -> y.val == string(x),collect(values(model_object.sets[:Te].nodes)))[1].idx,r) => sum(filter(x -> x.R_dis == r,model_object.parts.tech[x].par[:avaConv].data)[!,:val]) for x in eeSym_arr, r in allNuts3_arr);

eeGen_df = filter(x -> x.variable == :capaConv && x.Te in eeId_arr && x.R_dis in allNuts3_arr,reportResults(:summary,model_object, rtnOpt = (:rawDf,)));
eeGen_df[!,:gen] = map(x -> eeVlh_dic[(x.Te,x.R_dis)]*x.value,eachrow(eeGen_df));
eeReg_df = combine(groupby(eeGen_df,:R_dis),:gen => (x -> sum(x)) => :gen);
eeShare_dic = Dict(x.R_dis => x.gen/sum(eeReg_df[!,:gen]) for x in eachrow(eeReg_df));

# convert computed capacities into fixed limits in a parameter inputfile
eeCapa_df = filter(x -> x.variable == :capaConv && x.Te in eeId_arr && x.R_dis == 6,reportResults(:summary,model_object, rtnOpt = (:rawDf,)));

# for non-ee technologies, capacities are distributed among subregions proportional to ee generation
nonEECapa_df = filter(x -> x.variable in (:capaConv,:capaStIn,:capaStSize) && x.Te in nonEeId_arr && x.R_dis == 6,reportResults(:summary,model_object, rtnOpt = (:rawDf,)));
nonEECapa_df[!,:R_dis] = map(x -> model_object.sets[:R].nodes[x].down, nonEECapa_df[!,:R_dis]);
nonEECapa_df = flatten(nonEECapa_df,:R_dis)
nonEECapa_df[!,:value] = map(x -> eeShare_dic[x.R_dis]*x.value, eachrow(nonEECapa_df));


# write final csv file that is used as an input for the next computation
fixCapa_df = vcat(eeCapa_df,nonEECapa_df);
fixCapa_df[!,:Te] = map(x -> model_object.sets[:Te].nodes[x].val,fixCapa_df[!,:Te]);
fixCapa_df[!,:parameter] .= map(x -> x.Te == "ocgtHydrogen" ? Symbol(x.variable,:Low) : Symbol(x.variable,:Fix), eachrow(fixCapa_df));
fixCapa_df[!,:region_2] = map(x -> model_object.sets[:R].nodes[x].val,fixCapa_df[!,:R_dis]);
fixCapa_df[!,:technology_1] = map(x -> any(occursin.(["openspace_","rooftop_","onshore_","offshore_","home","grid"],x)) ? "" : x, fixCapa_df[!,:Te]);
fixCapa_df[!,:technology_2] = map(x -> !any(occursin.(["openspace_","rooftop_","onshore_","offshore_","home","grid"],x)) ? "" : x, fixCapa_df[!,:Te]);
select!(fixCapa_df, Not([:Ts_disSup,:R_dis,:C,:Te,:variable]));

CSV.write("conditionalData/intermediate/par_fixCapa.csv", fixCapa_df);

# * solve again with regions and exchange expansion, but with fixed capacities
model_object = anyModel(["baseData","scenarios/testingDecentral","conditionalData/intermediate","timeSeries/daily"],"_results", objName = "copperSecondHigh");

createOptModel!(model_object);
setObjective!(:costs, model_object);

# limits the imbalance of the trade balance
export_arr = filter(x -> x.R_from in deRegions_arr && !(x.R_to in deRegions_arr) && x.C == 7, model_object.parts.exc.var[:exc])[!,:var];
import_arr = filter(x -> x.R_to in deRegions_arr && !(x.R_from in deRegions_arr) && x.C == 7, model_object.parts.exc.var[:exc])[!,:var];

@constraint(model_object.optModel, tradebalance, sum(export_arr) + tradeInbalance_fl >= sum(import_arr));


set_optimizer(model_object.optModel, Gurobi.Optimizer);
set_optimizer_attribute(model_object.optModel, "Method", 2);
set_optimizer_attribute(model_object.optModel, "Crossover", 0);
optimize!(model_object.optModel);


reportResults(:summary,model_object);
reportResults(:exchange,model_object);
reportResults(:costs,model_object);
plotEnergyFlow(:sankey,model_object);

#endregion


#region # ! efficient scenario
model_object = anyModel(["baseData","scenarios/testingDecentral","timeSeries/daily"],"_results", objName = "efficientFirstHigh");

createOptModel!(model_object);
setObjective!(:costs, model_object);

# limits the imbalance of the trade balance
export_arr = filter(x -> x.R_from in deRegions_arr && !(x.R_to in deRegions_arr) && x.C == 7, model_object.parts.exc.var[:exc])[!,:var];
import_arr = filter(x -> x.R_to in deRegions_arr && !(x.R_from in deRegions_arr) && x.C == 7, model_object.parts.exc.var[:exc])[!,:var];

@constraint(model_object.optModel, tradebalance, sum(export_arr) + tradeInbalance_fl >= sum(import_arr));

set_optimizer(model_object.optModel, Gurobi.Optimizer);
set_optimizer_attribute(model_object.optModel, "Method", 2);
set_optimizer_attribute(model_object.optModel, "Crossover", 0);
optimize!(model_object.optModel);

reportResults(:summary,model_object);
reportResults(:exchange,model_object);
reportResults(:costs,model_object);
plotEnergyFlow(:sankey,model_object);

#endregion




model_object.graInfo.names["grid"] = "Netzbatterie"
model_object.graInfo.names["home"] = "Heimbatterie"
model_object.graInfo.names["pumpedHydro"] = "Pumpspeicher"
model_object.graInfo.names["caes"] = "CAES"
model_object.graInfo.names["biomassPlant"] = "Biomasseanlage"
model_object.graInfo.names["ror"] = "Laufwasser"
model_object.graInfo.names["rooftop"] = "PV-Dach"
model_object.graInfo.names["openspace"] = "PV-Freifläche"
model_object.graInfo.names["wind_offshore"] = "Wind offshore"
model_object.graInfo.names["wind_onshore"] = "Wind onshore"
model_object.graInfo.names["electrolysis"] = "Elektrolyse"
model_object.graInfo.names["ocgtHydrogen"] = "Wasserstoffturbine"
model_object.graInfo.names["electricMobility"] = "E-Mobilität"
model_object.graInfo.names["electricResidentalHeating"] = "Wärmepumpen"
model_object.graInfo.names["electricIndustryHeating"] = "E-Heizer"
model_object.graInfo.names["methanation"] = "Methanisierung"
model_object.graInfo.names["fermenter"] = "Fermenter"
model_object.graInfo.names["gasPlant"] = "CCGT"
model_object.graInfo.names["electricity"] = "Strom"

model_object.graInfo.names["electricity_central"] = "im Stromnetz"
model_object.graInfo.names["electricity_decentral"] = "dezentral genutzt"
model_object.graInfo.names["heatResidental"] = "Raumwärme"
model_object.graInfo.names["heatIndustry"] = "Prozesswärme"
model_object.graInfo.names["gas"] = "Gas"
model_object.graInfo.names["synthGas"] = "Methan"
model_object.graInfo.names["hydrogen"] = "Wasserstoff"
model_object.graInfo.names["biomass"] = "Biomasse"
model_object.graInfo.names["mobility"] = "Mobilität"


model_object.graInfo.colors["electricity_central"] = (1.0, 0.9215, 0.2313)
model_object.graInfo.colors["electricity_decentral"] = (1.0, 0.9215, 0.2313)

model_object.graInfo.colors["heatResidental"] = (0.769, 0.176, 0.29)
model_object.graInfo.colors["heatIndustry"] = (0.769, 0.176, 0.29)

model_object.graInfo.colors["mobility"] = (111/265, 200/265, 182/265)

plotEnergyFlow(:graph,model_object, scaDist = 20, initTemp = 2.0)