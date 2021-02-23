using Gurobi, AnyMOD
using DataFrames, CSV
include("anymod_postprocessing.jl")

indir = [
    "baseData",
    "scenarios/copper",
    "conditionalData/lowerEE_DE",
    "timeSeries/demand",
    "timeSeries/avail",
    "conditionalData/potentialBase",
    "conditionalData/fixEU_potentialBase_grid",
]

# * solve as copperplate
model_object = anyModel(
    indir,
    "_results/intermediate",
    objName = "desintegriert_intermediate"
);

createOptModel!(model_object);
setObjective!(:costs, model_object);

set_optimizer(model_object.optModel,Gurobi.Optimizer);
set_optimizer_attribute(model_object.optModel, "Method", 2);
set_optimizer_attribute(model_object.optModel, "Crossover", 0);
optimize!(model_object.optModel);

reportResults(:summary,model_object);
reportResults(:exchange,model_object);
reportResults(:costs,model_object);

summary_df = reportResults(:summary,model_object, rtnOpt=(:csvDf,))
expand_col!(summary_df, "technology")
expand_col!(summary_df, "region_dispatch")

filter!(x-> x.variable == :capaConv, summary_df)
filter!(x-> occursin("DE", x.region_dispatch_1), summary_df)
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


indir = [
    "baseData",
    "scenarios/decentral",
    "intermediate",
    "timeSeries/demand",
    "timeSeries/avail",
    "conditionalData/fixEU_potentialBase_grid",
]

model_object = anyModel(
    indir,
    "_results/desintegriert",
    objName = "desintegriert"
);


createOptModel!(model_object);
setObjective!(:costs, model_object);

set_optimizer(model_object.optModel,Gurobi.Optimizer);
set_optimizer_attribute(model_object.optModel, "Method", 2);
set_optimizer_attribute(model_object.optModel, "Crossover", 0);
optimize!(model_object.optModel);

reportResults(:summary,model_object);
reportResults(:exchange,model_object);
reportResults(:costs,model_object);