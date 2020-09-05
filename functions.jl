
function plotSankey(model_object)

    # define german names for technologies
    model_object.graInfo.names["grid"] = "Netzbatterie"
    model_object.graInfo.names["home"] = "Heimbatterie"
    model_object.graInfo.names["pumpedHydro"] = "Pumpspeicher"
    model_object.graInfo.names["caes"] = "CAES"
    model_object.graInfo.names["biomassPlant"] = "Biomasseanlage"
    model_object.graInfo.names["ror"] = "Laufwasser"
    model_object.graInfo.names["rooftop"] = "PV-Dach"
    model_object.graInfo.names["openspace"] = "PV-Freifläche"
    model_object.graInfo.names["wind_offshore"] = "Wind offshore"
    model_object.graInfo.names["wind_onshore"] = "Wind onshore"
    model_object.graInfo.names["electrolysis"] = "Elektrolyse"
    model_object.graInfo.names["ocgtHydrogen"] = "Wasserstoffturbine"
    model_object.graInfo.names["electricMobility"] = "Elektrofahrzeuge"
    model_object.graInfo.names["electricResidentalHeating"] = "Wärmepumpe"
    model_object.graInfo.names["electricIndustryHeating"] = "E-Heizer"
    model_object.graInfo.names["methanation"] = "Methanisierung"
    model_object.graInfo.names["fermenter"] = "Fermenter"
    model_object.graInfo.names["gasPlant"] = "CCGT"
    model_object.graInfo.names["electricity"] = "dezentrale Nachfrage"

    # define german names for carriers
    model_object.graInfo.names["electricity_central"] = "ins Netz eingespeist"
    model_object.graInfo.names["electricity_decentral"] = ""
    model_object.graInfo.names["heatResidental"] = "Raumwärme"
    model_object.graInfo.names["heatIndustry"] = "Prozesswärme"
    model_object.graInfo.names["gas"] = "Gas"
    model_object.graInfo.names["synthGas"] = "Methan"
    model_object.graInfo.names["hydrogen"] = "Wasserstoff"
    model_object.graInfo.names["biomass"] = "Biomasse"
    model_object.graInfo.names["mobility"] = "E-Mobilität"

    # define german names for other labels
    model_object.graInfo.names["demand"] = "Nachfrage"
    model_object.graInfo.names["netImport"] = "Netto-Import"
    model_object.graInfo.names["netExport"] = "Netto-Export"
    model_object.graInfo.names["trdBuy"] = "Import*"

     # define colors of carriers
    model_object.graInfo.colors["electricity_central"] = (1.0, 0.9215, 0.2313)
    model_object.graInfo.colors["electricity_decentral"] = (1.0, 0.9215, 0.2313)
    model_object.graInfo.colors["heatResidental"] = (0.769, 0.176, 0.29)
    model_object.graInfo.colors["heatIndustry"] = (0.769, 0.176, 0.29)
    model_object.graInfo.colors["mobility"] = (111/265, 200/265, 182/265)

    # plot sankey diagram and remove nodes that are not required
    plotEnergyFlow(:sankey,model_object, rmvNode = ("Nachfrage; Prozesswärme","Nachfrage; Raumwärme","Nachfrage; E-Mobilität","Import*; Biomasse","Nachfrage; dezentrale Nachfrage", "Gas"));
end

function changeObj!(model_object::anyModel,deRegions_arr)
    # fix variables of technologies
    for t in collect(keys(model_object.parts.tech)), v in collect(keys(model_object.parts.tech[t].var))
        if any(occursin.(["exp","capa"],string(v))) # fix all capacity and expansion variables
            vcat(map(x -> collect(keys(x.terms)),model_object.parts.tech[t].var[v][!,:var])...) |> (y -> fix.(y,value.(y), force = true))
        else # only fix dispatch variables outside of germany
            vcat(map(x -> collect(keys(x.terms)), filter(x -> !(x.R_dis in deRegions_arr), model_object.parts.tech[t].var[v])[!,:var])...) |> (y -> fix.(y,value.(y), force = true))
        end

    end

    # fix capacity variables of exchange
    for v in filter(x -> any(occursin.(["exp","capa"],string(x))), collect(keys(model_object.parts.exc.var)))
        if any(occursin.(["exp","capa"],string(v))) # fix all capacity and expansion variable
            vcat(map(x -> collect(keys(x.terms)) ,model_object.parts.exc.var[v][!,:var])...) |> (y -> fix.(y,value.(y), force = true))
        else # only fix dispatch variables outside of germany
            vcat(map(x -> collect(keys(x.terms)), filter(x -> !(x.R_to in deRegions_arr) && !(x.R_from in deRegions_arr), model_object.parts.exc.var[v])[!,:var])...) |> (y -> fix.(y,value.(y), force = true))
        end
    end

    # fix trade variables
    vcat(map(x -> collect(keys(x.terms)),model_object.parts.trd.var[:trdBuy][!,:var])...) |> (y -> fix.(y,value.(y), force = true))      

    # change objective function
    @objective(model_object.optModel, Max, sum(vcat([filter(x -> x.R_dis in deRegions_arr && x.C == 8, model_object.parts.tech[z].var[:gen])[!,:var] for z in [:rooftop_a,:rooftop_b,:rooftop_c]]...)))

end