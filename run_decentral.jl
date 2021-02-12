using Gurobi, AnyMOD, CSV

include("functions.jl")


inDir = [
    "baseData",
    "scenarios/decentral",
    "conditionalData/lowerEE_DE",
    "timeSeries",
    "conditionalData/potentialBase",
    "conditionalData/fixEU_potentialBase_grid"
]

model_object = anyModel(
    inDir,
    "_results",
    objName = "reference",
    bound = (capa = NaN, disp = NaN, obj = 2e7),
    decommExc  = :decomm
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
plotSankey(model_object, "DE");
plotSankey(model_object, "ENG");
