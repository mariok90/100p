using AnyMOD
using CSV, DataFrames, Chain
using Gurobi
include("functions.jl")

function main(limit)

    file = joinpath("conditionalData", "offshore_limits", "par_windoffshore_limit.csv")
    path = joinpath("conditionalData", "offshore_limits", "$limit")
    scen_file = joinpath(path, "par_offshore_limit.csv")
    isdir(path) || mkpath(path)
    @chain file begin
        CSV.read(_)
        DataFrame
        @aside _[1,:value] = limit
        CSV.write(scen_file, _)
    end
        
    inDir = [
        "baseData",
        "scenarios/decentral",
        "conditionalData/lowerEE_DE",
        "timeSeries/demand",
        "timeSeries/avail",
        "conditionalData/potentialBase",
        "conditionalData/fixEU_potentialBase_grid",
        path
    ]

    out_dir = joinpath("_results", "offshore")
    isdir(out_dir) || mkpath(out_dir)

    model_object = anyModel(
        inDir,
        out_dir,
        objName="offshore_$(limit)"
    )

    createOptModel!(model_object)
    setObjective!(:costs, model_object)
    set_optimizer(model_object.optModel, Gurobi.Optimizer)
    set_optimizer_attribute(model_object.optModel, "Method", 2)
    set_optimizer_attribute(model_object.optModel, "Crossover", 0)
    optimize!(model_object.optModel);
    reportResults(:summary, model_object);
    reportResults(:exchange, model_object);
    reportResults(:costs, model_object);
    reportTimeSeries(:electricity, model_object)
    # plotSankey(model_object, "DE");
    # plotSankey(model_object, "ENG");

    println("Done")
end

println("Starting Job")
scen = ARGS[1]
limit = (parse(Int, scen)-1) * 5 + 10

println("Offshore capacity is $limit")

main(limit)