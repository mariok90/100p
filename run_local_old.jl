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

include("functions.jl")

tradeInbalance_fl = 0

eePot = "potentialBase"
gridExp = "grid"

#region # ! solve for whole EU
model_object = anyModel(["baseData","scenarios/testingCopper","conditionalData/" * eePot,"timeSeries_daily","conditionalData/" * gridExp],"_results", objName = "computeEU");

createOptModel!(model_object);
setObjective!(:costs, model_object);

set_optimizer(model_object.optModel,Gurobi.Optimizer);
set_optimizer_attribute(model_object.optModel, "Method", 2);
set_optimizer_attribute(model_object.optModel, "Crossover", 1);
optimize!(model_object.optModel);

reportResults(:summary,model_object);
reportResults(:exchange,model_object);
reportResults(:costs,model_object);
plotSankey(model_object);

# write parameter file fixing capacity data
fixEU_df = select(filter(x -> !(split(x.region_dispatch," < ")[1] == "DE") && x.variable in (:capaConv,:capaStIn,:capaStOut,:capaStSize), reportResults(:summary,model_object, rtnOpt = (:csvDf,))),[:region_dispatch,:technology,:variable,:value])
fixEU_df[!,:region_1] = map(x -> split(x," < ")[1], fixEU_df[!,:region_dispatch])
fixEU_df[!,:region_2] = fixEU_df[!,:region_1]
fixEU_df[!,:parameter] = string.(fixEU_df[!,:variable]) .* "Resi"
fixEU_df[!,:technology_1] = map(x -> split(x," < ")[1], fixEU_df[!,:technology])
fixEU_df[!,:technology_2] = map(x -> split(x," < ") |> (x ->length(x) > 1 ? x[2] : ""), fixEU_df[!,:technology])
fixEU_df[!,:value] = floor.(fixEU_df[!,:value],digits = 2)

CSV.write("conditionalData/fixEU_" * eePot * "_" * gridExp * "/par_fixTech.csv", select(fixEU_df,[:region_1,:region_2,:technology_1,:technology_2,:parameter,:value,]));


fixEU2_df = filter(x -> x.variable == :capaExc && x.carrier != "gas", reportResults(:exchange,model_object, rtnOpt = (:csvDf,)))
fixEU2_df[!,:carrier_1] = map(x -> split(x," < ")[1], fixEU2_df[!,:carrier])
fixEU2_df[!,:carrier_2] = map(x -> split(x," < ") |> (x ->length(x) > 1 ? x[2] : ""), fixEU2_df[!,:carrier])
fixEU2_df[!,:parameter] = string.(fixEU2_df[!,:variable]) .* "ResiDir"
fixEU2_df[!,:region_1] = fixEU2_df[!,:region_from]
fixEU2_df[!,:region_2] = fixEU2_df[!,:region_from]
fixEU2_df[!,:region_1_a] = fixEU2_df[!,:region_to]
fixEU2_df[!,:region_2_a] = fixEU2_df[!,:region_to]

CSV.write("conditionalData/fixEU_" * eePot * "_" * gridExp * "/par_fixExc.csv", select(fixEU2_df,[:region_1,:region_2,:region_1_a,:region_2_a,:carrier_1,:carrier_2,:parameter,:value,]));
#endregion

# * alternative zu code oben: using AnyMOD, Gurobi (dev branch von AnyMOD muss installiert sein!)

#region # ! copperplate scenario

# ! solve as copperplate
model_object = anyModel(["baseData","scenarios/testingCopper","timeSeries_daily","conditionalData/" * eePot, "conditionalData/fixEU_" * eePot * "_" * gridExp],"_results", objName = "central1" * eePot * "_" * gridExp);

createOptModel!(model_object);
setObjective!(:costs, model_object);

# limits the imbalance of the trade balance
#deRegions_arr = vcat([6],model_object.sets[:R].nodes[6].down);

#export_arr = filter(x -> x.R_from in deRegions_arr && !(x.R_to in deRegions_arr) && x.C == 7, model_object.parts.exc.var[:exc])[!,:var];
#import_arr = filter(x -> x.R_to in deRegions_arr && !(x.R_from in deRegions_arr) && x.C == 7, model_object.parts.exc.var[:exc])[!,:var];

#@constraint(model_object.optModel, tradebalance, sum(export_arr) + tradeInbalance_fl >= sum(import_arr));

set_optimizer(model_object.optModel,Gurobi.Optimizer);
set_optimizer_attribute(model_object.optModel, "Method", 2);
set_optimizer_attribute(model_object.optModel, "Crossover", 0);
optimize!(model_object.optModel);

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
eeCapa_df = filter(x -> x.variable == :capaConv && x.Te in eeId_arr && x.R_dis in allNuts3_arr,reportResults(:summary,model_object, rtnOpt = (:rawDf,)));

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
filter!(x -> x.value > 1.00E-04,fixCapa_df)
select!(fixCapa_df, Not([:Ts_disSup,:R_dis,:C,:Te,:variable]));

CSV.write("conditionalData/intermediate_" * eePot * "_" * gridExp * "/par_fixCapa.csv", fixCapa_df);

# * solve again with regions and exchange expansion, but with fixed capacities
model_object = anyModel(["baseData","scenarios/testingDecentral","timeSeries_daily","conditionalData/" * eePot, "conditionalData/fixEU_" * eePot * "_" * gridExp,"conditionalData/intermediate_" * eePot * "_" * gridExp],"_results", objName = "central2" * eePot * "_" * gridExp);

createOptModel!(model_object);
setObjective!(:costs, model_object);

# limits the imbalance of the trade balance
#export_arr = filter(x -> x.R_from in deRegions_arr && !(x.R_to in deRegions_arr) && x.C == 7, model_object.parts.exc.var[:exc])[!,:var];
#import_arr = filter(x -> x.R_to in deRegions_arr && !(x.R_from in deRegions_arr) && x.C == 7, model_object.parts.exc.var[:exc])[!,:var];

#@constraint(model_object.optModel, tradebalance, sum(export_arr) + tradeInbalance_fl >= sum(import_arr));

set_optimizer(model_object.optModel, Gurobi.Optimizer);
set_optimizer_attribute(model_object.optModel, "Method", 2);
set_optimizer_attribute(model_object.optModel, "Crossover", 1);
optimize!(model_object.optModel);

# changes to objective to maximize decentral generation and fixed all cost-relevant variables and variables outside of Germany
changeObj!(model_object,deRegions_arr)

optimize!(model_object.optModel);
reportResults(:summary,model_object);
reportResults(:exchange,model_object);
reportResults(:costs,model_object);
plotSankey(model_object);

#endregion


#region # ! efficient scenario
model_object = anyModel(["baseData","scenarios/testingDecentral","timeSeries_daily","conditionalData/" * eePot, "conditionalData/fixEU_" * eePot * "_" * gridExp],"_results", objName = "decentral"  * eePot * "_" * gridExp );

createOptModel!(model_object);
setObjective!(:costs, model_object);

#model_object.parts.tech[:ocgtHydrogen].var[:capaConv]

# limits the imbalance of the trade balance
#export_arr = filter(x -> x.R_from in deRegions_arr && !(x.R_to in deRegions_arr) && x.C == 7, model_object.parts.exc.var[:exc])[!,:var];
#import_arr = filter(x -> x.R_to in deRegions_arr && !(x.R_from in deRegions_arr) && x.C == 7, model_object.parts.exc.var[:exc])[!,:var];

#@constraint(model_object.optModel, tradebalance, sum(export_arr) + tradeInbalance_fl >= sum(import_arr));


set_optimizer(model_object.optModel, Gurobi.Optimizer);
set_optimizer_attribute(model_object.optModel, "Method", 2);
set_optimizer_attribute(model_object.optModel, "Crossover", 0);
optimize!(model_object.optModel);

changeObj!(model_object,deRegions_arr)
optimize!(model_object.optModel);

reportResults(:summary,model_object);
reportResults(:exchange,model_object);
reportResults(:costs,model_object);
plotSankey(model_object);

#endregion


a = filter(x -> x.R_exp in (4,34), model_object.parts.tech[:rooftop_a].var[:capaConv])
b = filter(x -> x.R_exp in (4,34), model_object.parts.tech[:rooftop_b].var[:capaConv])
c = filter(x -> x.R_exp in (4,34), model_object.parts.tech[:rooftop_c].var[:capaConv])

model_object.parts.tech[:ocgtHydrogen].var[:use]

model_object.parts.bal.cns[:hydrogen][2,end]

anyM.parts.bal.cns[:electricity_central][40,end]