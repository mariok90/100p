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

    path_pot_base = joinpath("conditionalData", "potentialBase", "par_potential_DE.csv")
    if limit > 1
        rooftop_potential = @chain path_pot_base begin
            CSV.read(_)
            DataFrame
            filter(x-> x.parameter == "capaConvUp" && x.technology_1 == "rooftop", _)
            groupby(:region_2)
            combine("value" => sum => "value")
            zip(_.region_2, _.value)
            Dict
        end

        df_new_pot = @chain path_pot_base begin
            CSV.read(_)
            DataFrame
            filter(x-> x.parameter == "capaConvUp" && x.technology_2 == "rooftop_c", _)
            transform(["region_2","value"] => ByRow((r,v)-> (limit - 1) * rooftop_potential[r] + v) => "value")
        end

        df_orig = CSV.read(path_pot_base) |> DataFrame
        a = df_orig.parameter .== "capaConvUp"
        b = df_orig.technology_2 .== "rooftop_c"
        df_orig[a .& b, :] .= df_new_pot

        pot_path = joinpath(path, "par_potential_DE.csv")
        CSV.write(pot_path, df_orig)
    else
        pot_path = path_pot_base
    end
        
    inDir = [
        "baseData",
        "scenarios/decentral",
        "conditionalData/lowerEE_DE",
        "timeSeries",
        "conditionalData/fixEU_potentialBase_grid",
        path
    ]

    if pot_path == path_pot_base
        push!(inDir, pot_path)
    end

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
limit = parse(Int, scen) * 0.05

println("Limit is $(100 * limit) %")
println("Real limit is $(limit * 180)")

main(limit)
