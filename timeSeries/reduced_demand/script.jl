using DataFrames, CSV, Chain

methan_demand = 40

new_vals = Dict(
    "par_demand_central_DE.csv" => 240*0.75,
    "par_demand_decentral_DE.csv" => 240*0.25,
    "par_demand_heatIndustry_DE.csv" => 160,
    "par_demand_heatResidental_DE.csv" => 30,
    "par_demand_mobility_DE.csv" => 140
)

for (k,v) in new_vals
    df = CSV.read(joinpath("..","demand",k), DataFrame)
    share = v*1000 / sum(df.value)
    transform!(df, "value" => ByRow(x-> x*share) => "value")
    CSV.write(k, df)
end


methan_df = CSV.read(joinpath("..","demand","par_demand_gas_DE.csv"), DataFrame)
filter!(x-> x.carrier_2 == "synthGas", methan_df)
share = methan_demand / sum(methan_df.value)
transform!(methan_df, "value" => ByRow(x-> x*share) => "value")

CSV.write("par_demand_gas_DE.csv", methan_df)