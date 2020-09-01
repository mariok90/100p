

using CSV, DataFrames, Statistics

days_dic = Dict("h$(lpad(i,4,"0"))" => "d$(lpad(Int(floor(i/24+23/24)),3,"0"))" for i in 1:8760)

for x in filter(x -> x[1:3] == "par", readdir("dailyTimeSeries"))

    inData_df = CSV.read(joinpath("dailyTimeSeries",x))
    inData_df[!,:timestep_2] = map(x -> days_dic[x],inData_df[!,:timestep_4])

    grp_arr = filter(x -> !(x in (:value, :timestep_4)) ,Symbol.(names(inData_df)))

    newData_df = combine(groupby(select(inData_df,Not([:timestep_4])),grp_arr),:value => (x -> mean(x)) => :value)

    CSV.write(joinpath("dailyTimeSeries","new",x),newData_df)
end

x = "par_demand_central_DE"





Int(floor(2.323))
