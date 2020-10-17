using Gurobi, AnyMOD, CSV

include("functions.jl")

eePot = ARGS[1]
gridExp = ARGS[2]

model_object = anyModel(["baseData","scenarios/copper","conditionalData/lowerEE_DE","timeSeries","conditionalData/" * eePot, "conditionalData/runEU_" * gridExp],"_results", objName = "eu_" * eePot * "_" * gridExp);

# create rest of model
createOptModel!(model_object);
setObjective!(:costs, model_object);

set_optimizer(model_object.optModel,Gurobi.Optimizer);
set_optimizer_attribute(model_object.optModel, "Method", 2);
set_optimizer_attribute(model_object.optModel, "Crossover", 0);
optimize!(model_object.optModel);

reportResults(:summary,model_object);
reportResults(:exchange,model_object);
reportResults(:costs,model_object);


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

plotSankey(model_object, "DE");
plotSankey(model_object, "ENG");
