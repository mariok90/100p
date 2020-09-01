using Gurobi

using CSV, DataFrames, Dates, JuMP, Statistics, LinearAlgebra, Base.Threads
using PyCall, SparseArrays, Gurobi

# pyimport_conda("networkx","networkx")
# pyimport_conda("matplotlib.pyplot","matplotlib")
# pyimport_conda("plotly","plotly")

include("C:/Users/lgo/.julia/dev/AnyMOD/src/objects.jl")
include("C:/Users/lgo/.julia/dev/AnyMOD/src/tools.jl")
include("C:/Users/lgo/.julia/dev/AnyMOD/src/modelCreation.jl")

include("C:/Users/lgo/.julia/dev/AnyMOD/src/optModel/exchange.jl")
include("C:/Users/lgo/.julia/dev/AnyMOD/src/optModel/objective.jl")
include("C:/Users/lgo/.julia/dev/AnyMOD/src/optModel/other.jl")
include("C:/Users/lgo/.julia/dev/AnyMOD/src/optModel/tech.jl")

include("C:/Users/lgo/.julia/dev/AnyMOD/src/dataHandling/mapping.jl")
include("C:/Users/lgo/.julia/dev/AnyMOD/src/dataHandling/parameter.jl")
include("C:/Users/lgo/.julia/dev/AnyMOD/src/dataHandling/readIn.jl")
include("C:/Users/lgo/.julia/dev/AnyMOD/src/dataHandling/tree.jl")
include("C:/Users/lgo/.julia/dev/AnyMOD/src/dataHandling/util.jl")

# * alternative zu code oben: using AnyMOD, Gurobi (dev branch von AnyMOD muss installiert sein!)

# TODO lss ganz vermeiden in copperSecond, am besten "Engpass"kraftwerke zulassen
# TODO Verschiebung ee-zubau erreichen

# TODO vermeide lss in copperSecond, ermögliche Speicher und mehr Offshore,
# TODO stelle sicher, dass in copperSecond nicht einfach massiv importiert wird

# TODO solve a third time with all cost related variables fixed just to maximize the share of decentralised electricity
# TODO mache option für sankey mit net-export und net-import, ggf. auch übergabe funktion für kapazitäten

# * copperplate scenario

#region copperplate scenario

# * solve as copperplate
model_object = anyModel(["baseData","testingCopper","dailyTimeSeries"],"results", objName = "copperFirst")

createOptModel!(model_object)
setObjective!(:costs, model_object)

set_optimizer(model_object.optModel, Gurobi.Optimizer)
optimize!(model_object.optModel)

reportResults(:summary,model_object)
reportResults(:exchange,model_object)
reportResults(:costs,model_object)
plotEnergyFlow(:sankey,model_object)

# * obtain capacities for technologies and write to parameter file
eeSym_arr = filter(x -> model_object.parts.tech[x].type == :mature &&  keys(model_object.parts.tech[x].carrier)  |> (y -> :gen in y && !(:use in y)), collect(keys(model_object.parts.tech)))
eeId_arr = map(x -> filter(y -> y.val == string(x),collect(values(model_object.sets[:Te].nodes)))[1].idx , eeSym_arr)
noEeSym_arr = filter(x -> !(x in eeSym_arr) && model_object.parts.tech[x].type == :mature, collect(keys(model_object.parts.tech)))
nonEeId_arr = map(x -> filter(y -> y.val == string(x),collect(values(model_object.sets[:Te].nodes)))[1].idx , noEeSym_arr)

allNuts3_arr = getfield.(filter(x -> x.lvl == 2 && model_object.sets[:R].up[x.idx] == 6, collect(values(model_object.sets[:R].nodes))),:idx)

# get share of total ee production per region
eeVlh_dic = Dict((filter(y -> y.val == string(x),collect(values(model_object.sets[:Te].nodes)))[1].idx,r) => sum(filter(x -> x.R_dis == r,model_object.parts.tech[x].par[:avaConv].data)[!,:val]) for x in eeSym_arr, r in allNuts3_arr)

eeGen_df = filter(x -> x.variable == :capaConv && x.Te in eeId_arr && x.R_dis in allNuts3_arr,reportResults(:summary,model_object, rtnOpt = (:rawDf,)))
eeGen_df[!,:gen] = map(x -> eeVlh_dic[(x.Te,x.R_dis)]*x.value,eachrow(eeGen_df))
eeReg_df = combine(groupby(eeGen_df,:R_dis),:gen => (x -> sum(x)) => :gen)
eeShare_dic = Dict(x.R_dis => x.gen/sum(eeReg_df[!,:gen]) for x in eachrow(eeReg_df))

# convert computed capacities into fixed limits in a parameter inputfile
eeCapa_df = filter(x -> x.variable == :capaConv && x.Te in eeId_arr,reportResults(:summary,model_object, rtnOpt = (:rawDf,)))

# for non-ee technologies, capacities are distributed among subregions proportional to ee generation
nonEECapa_df = filter(x -> x.variable in (:capaConv,:capaStIn,:capaStSize) && x.Te in nonEeId_arr && x.R_dis == 6,reportResults(:summary,model_object, rtnOpt = (:rawDf,)))
nonEECapa_df[!,:R_dis] = map(x -> model_object.sets[:R].nodes[x].down, nonEECapa_df[!,:R_dis])
nonEECapa_df = flatten(nonEECapa_df,:R_dis)
nonEECapa_df[!,:value] = map(x -> eeShare_dic[x.R_dis]*x.value, eachrow(nonEECapa_df))

# write final csv file that is used as an input for the next computation
fixCapa_df = vcat(eeCapa_df,nonEECapa_df)
fixCapa_df[!,:parameter] = Symbol.(fixCapa_df[:,:variable],:Fix)
fixCapa_df[!,:Te] = map(x -> model_object.sets[:Te].nodes[x].val,fixCapa_df[!,:Te])
fixCapa_df[!,:region_2] = map(x -> model_object.sets[:R].nodes[x].val,fixCapa_df[!,:R_dis])
fixCapa_df[!,:technology_1] = map(x -> any(occursin.(["openspace_","rooftop_","onshore_","offshore_","home","grid"],x)) ? "" : x, fixCapa_df[!,:Te])
fixCapa_df[!,:technology_2] = map(x -> !any(occursin.(["openspace_","rooftop_","onshore_","offshore_","home","grid"],x)) ? "" : x, fixCapa_df[!,:Te])
select!(fixCapa_df, Not([:Ts_disSup,:R_dis,:C,:Te,:variable]))

CSV.write("intermediate/par_fixCapa.csv", fixCapa_df)

# * solve again with regions and exchange expansion, but with fixed capacities
model_object = anyModel(["baseData","testingDecentral","intermediate","dailyTimeSeries"],"results", objName = "copperSecond")

createOptModel!(model_object)
setObjective!(:costs, model_object)

set_optimizer(model_object.optModel, Gurobi.Optimizer)
optimize!(model_object.optModel)


reportResults(:summary,model_object)
reportResults(:exchange,model_object)
reportResults(:costs,model_object)
plotEnergyFlow(:sankey,model_object)

#endregion


#region efficient scenario
model_object = anyModel(["baseData","testingDecentral","dailyTimeSeries"],"results", objName = "efficientFirst")

createOptModel!(model_object)
setObjective!(:costs, model_object)

set_optimizer(model_object.optModel, Gurobi.Optimizer)
optimize!(model_object.optModel)

reportResults(:summary,model_object)
reportResults(:exchange,model_object)
reportResults(:costs,model_object)
plotEnergyFlow(:sankey,model_object)

#endregion
