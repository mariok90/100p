using DataFrames, CSV, Chain
rp(x) = replace(x, "DE" => "EU")

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

    kk = rp(k)
    file = joinpath("..","demand",kk)
    if isfile(file)
        df = CSV.read(file, DataFrame)
        transform!(df, "value" => ByRow(x-> x*share) => "value")
        CSV.write(kk, df)
    end
end


methan_df = CSV.read(joinpath("..","demand","par_demand_gas_DE.csv"), DataFrame)
filter!(x-> x.carrier_2 == "synthGas", methan_df)
share = methan_demand / (sum(methan_df.value)*8760/1000)
transform!(methan_df, "value" => ByRow(x-> x*share) => "value")
CSV.write("par_demand_gas_DE.csv", methan_df)

methan_EU_df = CSV.read(joinpath("..","demand","par_demand_gas_EU.csv"), DataFrame)
filter!(x-> x.carrier_2 == "synthGas", methan_EU_df)
transform!(methan_EU_df, "value" => ByRow(x-> x*share) => "value")
CSV.write("par_demand_gas_EU.csv", methan_EU_df)