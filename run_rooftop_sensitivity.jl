using Pkg
Pkg.activate(".")

using AnyMOD
using CSV, DataFrames, Chain
using Gurobi
include("functions.jl")

function main(limit)
    limit_int = round(Int, limit * 180) 
    file = joinpath("conditionalData", "rooftop_limit", "par_rooftop_fix.csv")
    path = joinpath("conditionalData", "rooftop_limit", "$(limit_int)")
    scen_file = joinpath(path, "par_rooftop_fix.csv")
    isdir(path) || mkpath(path)
    @chain file begin
        CSV.read(_)
        DataFrame
        @aside _[1,:value] = 180 * limit
        CSV.write(scen_file, _)
    end
        
    inDir = [
        "baseData",
        "scenarios/decentral",
        "conditionalData/lowerEE_DE",
        "timeSeries",
        "conditionalData/potentialBase",
        "conditionalData/fixEU_potentialBase_grid",
        path
    ]

    out_dir = joinpath("_results", "rooftop")
    isdir(out_dir) || mkpath(out_dir)

    model_object = anyModel(
        inDir,
        out_dir,
        objName="rooftop_$(limit_int)",
        bound=(capa = NaN, disp = NaN, obj = 2e7),
        decommExc=:decomm
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
    plotSankey(model_object, "DE");
    plotSankey(model_object, "ENG");

    println("Done")
end

println("Starting Job")
scen = ARGS[1]
limit = 1 - ((parse(Int, scen) - 1) * 0.05)

println("Limit is $(100 * limit) %")
println("Real limit is $(limit * 180)")

main(limit)