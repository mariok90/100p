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

# XXX alternative zu code oben: using AnyMOD, Gurobi (dev branch von AnyMOD muss installiert sein!)


# XXX copperplate scenario

# TODO ziehe demand daten de, teste, sende run.jl auf server
# TODO erweitere skript
# TODO mache option für sankey mit net-export und net-import

# solve as copperplate
model_object = anyModel(["baseData","testingCopper"],"results", objName = "copperFirst")

createOptModel!(model_object)
setObjective!(:costs, model_object)

set_optimizer(model_object.optModel, Gurobi.Optimizer)
optimize!(model_object.optModel)

plotEnergyFlow(:sankey,model_object)
plotEnergyFlow(:sankey,model_object, dropDown = (:timestep,))
reportResults(:summary,model_object)
reportResults(:exchange,model_object)



tSym = :rooftop_b
tInt = techInt(tSym,anyM.sets[:Te])
part = anyM.parts.tech[tSym]
prepTech_dic = prepTech_dic[tSym]
parDef_dic = copy(parDef_dic)
ts_dic = ts_dic
r_dic = r_dic

anyM.sets[:C].nodes[7]
