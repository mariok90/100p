
using Gurobi, AnyMOD, CSV

# ! run whole eu with investment to compute capacities

model_object = anyModel(["baseData","scenarios/copper","timeSeries"],"_results", objName = "eu");

# create rest of model
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
