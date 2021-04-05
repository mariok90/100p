using Gurobi, AnyMOD, CSV
include("functions.jl")
include("anymod_postprocessing.jl")

scen = "reduced_demand_eu"

inDir = [
    "baseData",
    "scenarios/copper",
    "conditionalData/lowerEE_DE",
    "timeSeries/reduced_demand",
    "timeSeries/avail",
    "conditionalData/potentialBase",
    "conditionalData/runEU_noGrid",
]

result_path = joinpath("_results", scen)
mkpath(result_path)

model_object = anyModel(
    inDir,
    result_path,
    objName = scen
)

createOptModel!(model_object)
setObjective!(:costs, model_object);

set_optimizer(model_object.optModel, Gurobi.Optimizer);
set_optimizer_attribute(model_object.optModel, "Method", 2);
set_optimizer_attribute(model_object.optModel, "Crossover", 0);
optimize!(model_object.optModel);

summary_df = reportResults(:summary,model_object, rtnOpt=(:csvDf,))
expand_col!(summary_df, "technology")
expand_col!(summary_df, "region_dispatch")


filter!(x-> x.variable == :capaConv, summary_df)
filter!(x-> !(occursin("DE", x.region_dispatch_1)), summary_df)
tech_filter = ["wind_offshore", "wind_onshore", "pv"]
tech3 = ["facade","agrar_pv"]
filter!(x-> x.technology_1 in tech_filter, summary_df)
transform!(
    summary_df,
    "technology_3" => ByRow(x-> x in tech3 ? missing : x) => "technology_3"
)
select!(
    summary_df,
    :region_dispatch_2 => :region_2,
    :technology_1,
    :technology_2,
    :technology_3,
    :value
)

df_low = transform(summary_df, "value" => ByRow(x-> floor(x, digits=4)) => "value")
df_low[!,"parameter"] .= "capaConvLow"

df_up = transform(summary_df, "value" => ByRow(x-> ceil(x, digits=4)) => "value")
df_up[!,"parameter"] .= "capaConvUp"

CSV.write("intermediate/par_capalow.csv", df_low)
CSV.write("intermediate/par_capaup.csv", df_up)


scen = "reduced_demand"

inDir = [
    "baseData",
    "scenarios/decentral",
    "conditionalData/lowerEE_DE",
    "timeSeries/reduced_demand",
    "timeSeries/avail",
    "conditionalData/potentialBase",
    "conditionalData/fixEU_potentialBase_grid",
]

result_path = joinpath("_results", scen)
mkpath(result_path)

model_object = anyModel(
    inDir,
    result_path,
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
reportTimeSeries(:electricity_central, model_object)
reportTimeSeries(:electricity_decentral, model_object)
plotSankey(model_object, "DE");
plotSankey(model_object, "ENG");
