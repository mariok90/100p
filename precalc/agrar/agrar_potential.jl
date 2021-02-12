using DataFrames, CSV, Chain

# agrar pv potential 1,7 TW
#https://www.ise.fraunhofer.de/content/dam/ise/de/documents/publications/studies/aktuelle-fakten-zur-photovoltaik-in-deutschland.pdf
#p.38

agrar_pot = 1700

regions = CSV.read(joinpath("..", "..", "baseData","set_region.csv")).region_2
regions = filter(x-> occursin("DE", x), regions)
agrar_area = "uua.csv"
df = filter(x-> x.nuts2 in regions ,CSV.read(agrar_area))
total = sum(df.total)
transform!(df, "total" => ByRow(x-> agrar_pot*x/total) => "total")
missing_regions = setdiff(regions, df.nuts2)

for x in missing_regions
    push!(df, (nuts2=x, total=0))
end
rename!(df, "total" => "value", "nuts2" => "region_2")
df[!, "technology_1"] .= "agrar_pv"
df[!, "parameter"] .= "capaConvUp"

CSV.write(
    joinpath(
        "..",
        "..",
        "conditionalData",
        "potentialBase",
        "par_potential_agrar.csv"
    )
)