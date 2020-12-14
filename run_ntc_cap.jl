using Pkg
Pkg.activate(".")

using AnyMOD
using CSV, DataFrames, Chain
using Gurobi
include("functions.jl")

function main(ntc_limit)

    ntc_file = joinpath("conditionalData","upper_limit_ntc","par_exp_limit.csv")
    @chain ntc_file begin
        CSV.read(_)
        DataFrame
        @aside _[1,:value_1] = ntc_limit
        CSV.write(ntc_file,_)
    end
        
    inDir = [
        "baseData",
        "scenarios/decentral",
        "conditionalData/lowerEE_DE",
        "timeSeries",
        "conditionalData/potentialBase",
        "conditionalData/fixEU_potentialBase_grid"
    ]

    out_dir = joinpath("_results","ntc_limits")
    isdir(out_dir) || mkdir(out_dir)

    model_object = anyModel(
        inDir,
        out_dir,
        objName = "sensitivity_ntc_limit_$(ntc_limit)",
        bound = (capa = NaN, disp = NaN, obj = 2e7),
        decommExc  = :decomm
    )

    createOptModel!(model_object)
    setObjective!(:costs, model_object)
    set_optimizer(model_object.optModel, Gurobi.Optimizer)
    set_optimizer_attribute(model_object.optModel, "Method", 2)
    set_optimizer_attribute(model_object.optModel, "Crossover", 0)
    optimize!(model_object.optModel);
    reportResults(:exchange,model_object);
    reportResults(:costs,model_object);
    reportTimeSeries(:electricity, model_object)
    plotSankey(model_object, "DE");
    plotSankey(model_object, "ENG");

    println("Done")
end

println("Starting Job")
ntc_scen = ARGS[1]
ntc_limit = parse(Int, ntc_scen) * 25

println("NTC limit is $ntc_limit")

main(ntc_limit)