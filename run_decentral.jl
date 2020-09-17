using Gurobi, AnyMOD, CSV

tradeInbalance_fl = 0
pvPot = ARGS[1]

model_object = anyModel(["baseData","conditionalData/fixEU","scenarios/decentral","timeSeries",""],"_results", objName = "efficientFirst");

deRegions_arr = vcat([6],model_object.sets[:R].nodes[6].down);

#openspace: 21, 20; rooftop: 22, 23, 24
if pvPot == "breyer"
    sca_dic = Dict(21 => 4.89, 20 => 4.89, 22 => 4.89,23 => 4.89, 24 => 4.89)
    model_object.parts.lim.par[:capaConvUp].data  |>  (y -> y[!,:val] = map(x -> x.val * ((x.R_exp in deRegions_arr && x.Te in collect(keys(sca_dic))) ?  sca_dic[x.Te] : 1.0),eachrow(y)))
end

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

changeObj!(model_object,deRegions_arr)
optimize!(model_object.optModel);

reportResults(:summary,model_object);
reportResults(:exchange,model_object);
reportResults(:costs,model_object);