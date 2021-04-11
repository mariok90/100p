using Gurobi, AnyMOD, CSV
using Chain
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
    "conditionalData/runEU_noGrid"
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

exclude_techs = [
    "gasStorage",
    "pumpedHydro",
    "electricIndustryHeating",
    "electricMobility",
    "electricResidentalHeating",
    "gasPlant",

]

summary_df = @chain reportResults(:summary,model_object, rtnOpt=(:csvDf,)) begin
    expand_col!("technology")
    expand_col!("region_dispatch")
    filter!(x-> x.variable in [:capaConv, :capaStOut, :capaStSize], _)
    select!(
        :region_dispatch_1 => :region_1,
        :technology_1,
        :variable,
        :value
    )
    groupby(["region_1","technology_1","variable"])
    combine("value" => sum => "value")
    filter!(x-> !(x.technology_1 in exclude_techs), _)
end

df_low = transform(summary_df, "value" => ByRow(x-> floor(x, digits=4)) => "value")
df_low = unstack(df_low, :variable, :value)
df_low[!,"parameter_1"] .= names(df_low)[3]*"Low"
df_low[!,"parameter_2"] .= names(df_low)[4]*"Low"
df_low[!,"parameter_3"] .= names(df_low)[5]*"Low"
select!(df_low,
    Not(names(df_low)[3:5]),
    names(df_low)[3] => "value_1",
    names(df_low)[4] => "value_2",
    names(df_low)[5] => "value_3"
)
transform!(
    df_low,
    ["parameter_1","value_1"] =>
     ByRow((a,b)-> ismissing(b) ? missing : a ) =>
    "parameter_1"
)
transform!(
    df_low,
    ["parameter_2","value_2"] =>
     ByRow((a,b)-> ismissing(b) ? missing : a ) =>
    "parameter_2"
)
transform!(
    df_low,
    ["parameter_3","value_3"] =>
     ByRow((a,b)-> ismissing(b) ? missing : a ) =>
    "parameter_3"
)


df_up = filter(x-> !(occursin("DE", x.region_1)), summary_df)
transform!(df_up, "value" => ByRow(x-> ceil(x, digits=4)) => "value")
df_up = unstack(df_up, :variable, :value)
df_up[!,"parameter_1"] .= names(df_up)[3]*"Up"
df_up[!,"parameter_2"] .= names(df_up)[4]*"Up"
df_up[!,"parameter_3"] .= names(df_up)[5]*"Up"
select!(df_up,
    Not(names(df_up)[3:5]),
    names(df_up)[3] => "value_1",
    names(df_up)[4] => "value_2",
    names(df_up)[5] => "value_3"
)
transform!(
    df_up,
    ["parameter_1","value_1"] =>
     ByRow((a,b)-> ismissing(b) ? missing : a ) =>
    "parameter_1"
)
transform!(
    df_up,
    ["parameter_2","value_2"] =>
     ByRow((a,b)-> ismissing(b) ? missing : a ) =>
    "parameter_2"
)
transform!(
    df_up,
    ["parameter_3","value_3"] =>
     ByRow((a,b)-> ismissing(b) ? missing : a ) =>
    "parameter_3"
)


# df_exc = @chain reportResults(:exchange,model_object, rtnOpt=(:csvDf,)) begin
#     expand_col!("region_from")
#     expand_col!("region_to")
#     expand_col!("carrier")
#     filter!(x-> contains(x.carrier_1, "electricity"), _)
#     filter!(x-> x.variable == :exc, _)
#     groupby(["region_from_1", "region_to_1", "carrier_1"])
#     combine("value" => sum => "value")
#     filter!(x-> (x.region_from_1 == "DE") || (x.region_to_1 == "DE"), _)
#     filter!(x-> !((x.region_from_1 == "DE") && (x.region_to_1 == "DE")), _)
#     transform!("value" => (x-> floor.(x)) => "value")
#     rename!("region_from_1" => "region_1", "region_to_1" => "region_1a")
# end
# df_exc[!,"parameter"] .= "excDirUp"

path = mkpath(joinpath("intermediate","reduced_demand"))
CSV.write(joinpath(path,"par_capalow.csv"), df_low)
CSV.write(joinpath(path,"par_capaup.csv"), df_up)
# CSV.write(joinpath(path,"par_excup.csv"), df_exc)


# df_string = read(joinpath(path,"par_excup.csv"), String)
# df_string = replace(df_string, "region_1a" =>  "region_1")
# write(joinpath(path,"par_excup.csv"), df_string)

scen = "reduced_demand"

inDir = [
    "baseData",
    "scenarios/decentral",
    "conditionalData/lowerEE_DE",
    "timeSeries/reduced_demand",
    "timeSeries/avail",
    "conditionalData/potentialBase",
    "conditionalData/fixEU_potentialBase_reduced_grid",
    path
]

result_path = joinpath("_results",scen)
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
reportTimeSeries(:electricity_decentral, model_object)
reportTimeSeries(:electricity_central, model_object)