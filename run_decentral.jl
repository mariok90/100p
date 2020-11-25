using Gurobi, AnyMOD, CSV

include("functions.jl")

eePot = ARGS[1]
gridExp = ARGS[2]
engTech = ARGS[3]

if engTech != "none"
    inDir = ["baseData","scenarios/decentral","conditionalData/lowerEE_DE","timeSeries","conditionalData/" * eePot, "conditionalData/fixEU_" * eePot * "_" * gridExp]
else
    inDir = ["baseData","scenarios/decentral","conditionalData/lowerEE_DE","timeSeries","conditionalData/" * eePot, "conditionalData/fixEU_" * eePot * "_" * gridExp, "conditionalData/noGrid_DE"]
end

model_object = anyModel(inDir,"_results", objName = "decentral_"  * eePot * "_" * gridExp, bound = (capa = NaN, disp = NaN, obj = 2e7), decommExc  = :decomm);

createOptModel!(model_object);
setObjective!(:costs, model_object);

deRegions_arr = vcat([6],model_object.sets[:R].nodes[6].down);

set_optimizer(model_object.optModel, Gurobi.Optimizer);
set_optimizer_attribute(model_object.optModel, "Method", 2);
set_optimizer_attribute(model_object.optModel, "Crossover", 0);
optimize!(model_object.optModel);
reportResults(:summary,model_object);
reportResults(:exchange,model_object);
reportResults(:costs,model_object);
plotSankey(model_object, "DE");
plotSankey(model_object, "ENG");

changeObj!(model_object,deRegions_arr)
optimize!(model_object.optModel);

reportResults(:summary,model_object);
reportResults(:exchange,model_object);
reportResults(:costs,model_object);
reportTimeSeries(:electricity, model_object)
plotSankey(model_object, "DE");
plotSankey(model_object, "ENG");