
function plotSankey(model_object, lang::String)

    if lang == "DE"
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
        model_object.graInfo.names["electricMobility"] = ""
        model_object.graInfo.names["electricResidentalHeating"] = ""
        model_object.graInfo.names["electricIndustryHeating"] = ""
        model_object.graInfo.names["methanation"] = "Methanisierung"
        model_object.graInfo.names["fermenter"] = "Fermenter"
        model_object.graInfo.names["gasPlant"] = "CCGT"
        model_object.graInfo.names["electricity"] = "dezentrale Nachfrage"
        model_object.graInfo.names["gasStorage"] = "Gas-Speicher"

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
        model_object.graInfo.names["import"] = "Import"
        model_object.graInfo.names["netExport"] = "Netto-Export"
        model_object.graInfo.names["export"] = "Export"
        model_object.graInfo.names["exchangeLoss"] = "Leistungverluste"
        model_object.graInfo.names["trdBuy"] = "Import*"
    else
        # define german names for technologies
        model_object.graInfo.names["grid"] = "grid battery"
        model_object.graInfo.names["home"] = "home battery"
        model_object.graInfo.names["pumpedHydro"] = "(pumped) hydro"
        model_object.graInfo.names["caes"] = "caes"
        model_object.graInfo.names["biomassPlant"] = "biomass plant"
        model_object.graInfo.names["ror"] = "run-of-river"
        model_object.graInfo.names["rooftop"] = "PV, rooftop"
        model_object.graInfo.names["openspace"] = "PV, openspace"
        model_object.graInfo.names["wind_offshore"] = "wind, offshore"
        model_object.graInfo.names["wind_onshore"] = "wind, onshore"
        model_object.graInfo.names["electrolysis"] = "electrolysis"
        model_object.graInfo.names["ocgtHydrogen"] = "hydrogen turbine"
        model_object.graInfo.names["electricMobility"] = ""
        model_object.graInfo.names["electricResidentalHeating"] = ""
        model_object.graInfo.names["electricIndustryHeating"] = ""
        model_object.graInfo.names["methanation"] = "methanation"
        model_object.graInfo.names["fermenter"] = "fermenter"
        model_object.graInfo.names["gasPlant"] = "ccgt plant"
        model_object.graInfo.names["electricity"] = "residental demand"
        model_object.graInfo.names["gasStorage"] = "gas storage"

        # define german names for carriers
        model_object.graInfo.names["electricity_central"] = "grid"
        model_object.graInfo.names["electricity_decentral"] = ""
        model_object.graInfo.names["heatResidental"] = "residental heat"
        model_object.graInfo.names["heatIndustry"] = "process heat"
        model_object.graInfo.names["gas"] = "gas"
        model_object.graInfo.names["synthGas"] = "methan"
        model_object.graInfo.names["hydrogen"] = "hydrogen"
        model_object.graInfo.names["biomass"] = "biomass"
        model_object.graInfo.names["mobility"] = "mobility"

        # define german names for other labels
        model_object.graInfo.names["demand"] = "demand"
        model_object.graInfo.names["netImport"] = "net-import"
        model_object.graInfo.names["import"] = "import"
        model_object.graInfo.names["netExport"] = "net-export"
        model_object.graInfo.names["export"] = "export"
        model_object.graInfo.names["exchangeLoss"] = "exchange losses"
        model_object.graInfo.names["trdBuy"] = "import*"
    end

     # define colors of carriers
    model_object.graInfo.colors["electricity_central"] = (1.0, 0.9215, 0.2313)
    model_object.graInfo.colors["electricity_decentral"] = (1.0, 0.9215, 0.2313)
    model_object.graInfo.colors["heatResidental"] = (0.769, 0.176, 0.29)
    model_object.graInfo.colors["heatIndustry"] = (0.769, 0.176, 0.29)
    model_object.graInfo.colors["mobility"] = (111/265, 200/265, 182/265)

    # plot sankey diagram and remove nodes that are not required
    if lang == "DE"
        plotEnergyFlow(:sankey,model_object, rmvNode = ("Nachfrage; Prozesswärme","Nachfrage; Raumwärme","Nachfrage; E-Mobilität","Import*; Biomasse","Nachfrage; dezentrale Nachfrage", "Gas"), name = lang);
        plotEnergyFlow(:sankey,model_object, rmvNode = ("Nachfrage; Prozesswärme","Nachfrage; Raumwärme","Nachfrage; E-Mobilität","Import*; Biomasse","Nachfrage; dezentrale Nachfrage", "Gas"), dropDown = (:timestep,), minVal = 2.0, netExc = true, name = lang);
    else
        plotEnergyFlow(:sankey,model_object, rmvNode = ("demand; process heat","demand; residental heat","demand; mobility","import*; biomass","demand; residental demand", "gas"), name = lang);
        plotEnergyFlow(:sankey,model_object, rmvNode = ("demand; process heat","demand; residental heat","demand; mobility","import*; biomass","demand; residental demand", "gas"), dropDown = (:timestep,), minVal = 2.0, netExc = true, name = lang);
    end
end

function changeObj!(model_object::anyModel,deRegions_arr)
    # fix variables of technologies
    for t in collect(keys(model_object.parts.tech)), v in collect(keys(model_object.parts.tech[t].var))

        if any(occursin.(["exp","capa","Capa"],string(v))) # fix all capacity and expansion variables
            vcat(map(x -> collect(keys(x.terms)),model_object.parts.tech[t].var[v][!,:var])...) |> (y -> fix.(y,value.(y), force = true))
        else # only fix dispatch variables outside of germany
            #vcat(map(x -> collect(keys(x.terms)), filter(x -> !(x.R_dis in deRegions_arr), model_object.parts.tech[t].var[v])[!,:var])...) |> (y -> fix.(y,value.(y), force = true))
        end

    end

    # fix loss of load variables
    for v in collect(keys(model_object.parts.bal.var))
        vcat(map(x -> collect(keys(x.terms)),model_object.parts.bal.var[v][!,:var])...) |> (y -> fix.(y,value.(y), force = true))
    end

    # fix capacity variables of exchange
    for v in filter(x -> any(occursin.(["exp","capa"],string(x))), collect(keys(model_object.parts.exc.var)))
        if any(occursin.(["exp","capa"],string(v))) # fix all capacity and expansion variable
            vcat(map(x -> collect(keys(x.terms)) ,model_object.parts.exc.var[v][!,:var])...) |> (y -> fix.(y,value.(y), force = true))
        else # only fix dispatch variables outside of germany
           #vcat(map(x -> collect(keys(x.terms)), filter(x -> !(x.R_to in deRegions_arr) && !(x.R_from in deRegions_arr), model_object.parts.exc.var[v])[!,:var])...) |> (y -> fix.(y,value.(y), force = true))
        end
    end

    # fix trade variables
    vcat(map(x -> collect(keys(x.terms)),model_object.parts.trd.var[:trdBuy][!,:var])...) |> (y -> fix.(y,value.(y), force = true))      

    # change objective function
    @objective(model_object.optModel, Max, sum(vcat([filter(x -> x.R_dis in deRegions_arr && x.C == 8, model_object.parts.tech[z].var[:gen])[!,:var] for z in [:rooftop_a,:rooftop_b,:rooftop_c]]...)))

end