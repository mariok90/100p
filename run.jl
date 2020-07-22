using AnyMOD
using Gurobi

#scen = ARGS[1]
#scen = "eu2"

#input = joinpath("data", "exp_raw", scen)
#output = joinpath("data", "sims","workshop")

anyM = anyModel(input, output, objName = "EU_1000_rooftop", decomm=:none)

createOptModel!(anyM)
setObjective!(:costs, anyM)
set_optimizer(anyM.optModel,
    optimizer_with_attributes(Gurobi.Optimizer,
        "Method" => 2,
        "Crossover" => 0,
        "BarConvTol" => 1e-5))

optimize!(anyM.optModel)

reportResults(:exchange,anyM, rtnOpt = (:csv,))
reportResults(:summary, anyM, rtnOpt = (:csv,))

reportTimeSeries(:Power, anyM)
#printIIS(anyM)

#
# plotEnergyFlow(:graph,anyM::anyModel; plotSize = (16.0,9.0),
#                               fontSize = 12, useTeColor = false,
#                                   replot = true, scaDist = 0.5, maxIter = 5000, initTemp = 2.0)

#plotEnergyFlow(:sankey,anyM::anyModel)
