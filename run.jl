using Gurobi, AnyMOD, CSV

# include("functions.jl")


scens = ["zentral", "dezentral"]
scen = scens[parse(Int, ARGS[1])]

println("Running $scen")

inDir = [
    "baseData",
    "scenarios/decentral",
    "conditionalData/lowerEE_DE",
    "timeSeries/demand",
    "timeSeries/avail",
    "conditionalData/potentialBase",
    "conditionalData/fixEU_potentialBase_grid",
    "conditionalData/scenarios/$scen"
]

model_object = anyModel(
    inDir,
    "_results",
    objName = scen
)

createOptModel!(model_object)
setObjective!(:costs, model_object);

set_optimizer(model_object.optModel, Gurobi.Optimizer);
set_optimizer_attribute(model_object.optModel, "Method", 2);
set_optimizer_attribute(model_object.optModel, "Crossover", 0);
optimize!(model_object.optModel);
reportResults(:summary,model_object);
reportResults(:exchange,model_object);
reportResults(:costs,model_object);
reportTimeSeries(:electricity, model_object)
plotEnergyFlow(:sankey, model_object);


