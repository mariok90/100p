using Gurobi, AnyMOD, CSV
include("functions.jl")
include("anymod_postprocessing.jl")


scen = "integriert_eu"

inDir = [
    "baseData",
    "scenarios/copper",
    "conditionalData/lowerEE_DE",
    "timeSeries/demand",
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
reportResults(:summary,model_object);

summary_df = reportResults(:summary,model_object, rtnOpt=(:csvDf,))
expand_col!(summary_df, "technology")
expand_col!(summary_df, "region_dispatch")

filter!(x-> x.variable == :capaConv, summary_df)
filter!(x-> !(occursin("DE", x.region_dispatch_1)), summary_df)
tech_filter = ["wind_offshore", "wind_onshore", "pv"]
filter!(x-> x.technology_1 in tech_filter, summary_df)
select!(
    summary_df,
    :region_dispatch_1 => :region_1,
    :technology_1,
    :technology_2,
    :technology_3,
    :value
)

df_low = transform(summary_df, "value" => ByRow(x-> floor(x, digits=4)) => "value")
df_low[!,"parameter"] .= "capaConvLow"

df_up = transform(summary_df, "value" => ByRow(x-> ceil(x, digits=4)) => "value")
df_up[!,"parameter"] .= "capaConvUp"

path = mkpath(joinpath("intermediate","integriert_eu"))
CSV.write(joinpath(path,"par_capalow.csv"), df_low)
CSV.write(joinpath(path,"par_capaup.csv"), df_up)


scen = "integriert"

inDir = [
    "baseData",
    "scenarios/decentral",
    "conditionalData/lowerEE_DE",
    "timeSeries/demand",
    "timeSeries/avail",
    "conditionalData/potentialBase",
    "conditionalData/disable_eu_inv",
    path
]

result_path = joinpath("_results","integriert")
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
plotSankey(model_object, "DE");
plotSankey(model_object, "ENG");
