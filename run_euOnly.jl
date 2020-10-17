using Gurobi, AnyMOD, CSV

include("functions.jl")

eePot = ARGS[1]
gridExp = ARGS[2]

model_object = anyModel(["baseData","scenarios/copper_euOnly","conditionalData/lowerEE_DE","timeSeries","conditionalData/" * eePot, "conditionalData/runEU_" * gridExp],"_results", objName = "eu_" * eePot * "_" * gridExp);

# create rest of model
createOptModel!(model_object);
setObjective!(:costs, model_object);

set_optimizer(model_object.optModel,Gurobi.Optimizer);
set_optimizer_attribute(model_object.optModel, "Method", 2);
set_optimizer_attribute(model_object.optModel, "Crossover", 0);
optimize!(model_object.optModel);


changeObj!(model_object,unique(model_object.parts.bal.cns[:electricity][!,:R_dis]))
optimize!(model_object.optModel);

reportResults(:summary,model_object);
reportResults(:exchange,model_object);
reportResults(:costs,model_object);

plotSankey(model_object, "DE");
plotSankey(model_object, "ENG");

reportTimeSeries(:electricity, model_object)

printObject(model_object.parts.tech[:gasStorage].var[:stLvl], model_object, fileName = "gasStorage")
printObject(model_object.parts.tech[:grid].var[:stLvl], model_object, fileName = "grid")
printObject(model_object.parts.tech[:home].var[:stLvl], model_object, fileName = "home")
printObject(model_object.parts.tech[:caes].var[:stLvl], model_object, fileName = "caes")
printObject(model_object.parts.tech[:pumpedHydro].var[:stLvl], model_object, fileName = "pumpedHydro")


