
function plotSankey(model_object, lang::String)

    if lang == "DE"
        # define german names for technologies
        model_object.graInfo.names["grid"] = "Netzbatterie"
        model_object.graInfo.names["home"] = "Heimbatterie"
        model_object.graInfo.names["pumpedHydro"] = "Pumpspeicher"
        model_object.graInfo.names["caes"] = "CAES"
        model_object.graInfo.names["biomassPlant"] = "Biomasseanlage"
        model_object.graInfo.names["ror"] = "Laufwasser"
        model_object.graInfo.names["rooftop"] = "Photovoltaik"
        model_object.graInfo.names["openspace"] = "Photovoltaik"
        model_object.graInfo.names["wind_offshore"] = "Wind offshore"
        model_object.graInfo.names["wind_onshore"] = "Wind onshore"
        model_object.graInfo.names["pv_agrar"] = "Photovoltaik"
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
        model_object.graInfo.names["electricity_decentral"] = "Prosumage"
        model_object.graInfo.names["heatResidental"] = "Raumwärme"
        model_object.graInfo.names["heatIndustry"] = "Prozesswärme"
        model_object.graInfo.names["gas"] = "Gas"
        model_object.graInfo.names["synthGas"] = "synthetisches Gas"
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
        model_object.graInfo.names["electricity_decentral"] = "prosumage"
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
    model_object.graInfo.colors["electricity_central"] = (1.0, 1.0, 187/255)
    model_object.graInfo.colors["electricity_decentral"] = (1.0, 1.0, 187/255)
    model_object.graInfo.colors["heatResidental"] = (1.0, 166/255, 133/255)
    model_object.graInfo.colors["heatIndustry"] = (175/255, 138/255, 126/255)
    model_object.graInfo.colors["mobility"] = (148/255, 241/255, 1.0)

    # plot sankey diagram and remove nodes that are not required
    if lang == "DE"
        plotEnergyFlow(
            :sankey,
            model_object,
            rmvNode = (
                "Nachfrage; Prozesswärme","Nachfrage; Raumwärme",
                "Nachfrage; E-Mobilität",
                "Import*; Biomasse",
                "Nachfrage; dezentrale Nachfrage",
                "Gas"
            ),
            #netExc = true
        );
        plotEnergyFlow(
            :sankey,
            model_object,
            rmvNode = (
                "Nachfrage; Prozesswärme",
                "Nachfrage; Raumwärme",
                "Nachfrage; E-Mobilität",
                "Import*; Biomasse",
                "Nachfrage; dezentrale Nachfrage",
                "Gas"
            ),
            dropDown = (:timestep,),
            # minVal = 2.0,
            # netExc = true
        );
    else
        plotEnergyFlow(:sankey,model_object, rmvNode = ("demand; process heat","demand; residental heat","demand; mobility","import*; biomass","demand; residental demand", "gas"));
        plotEnergyFlow(:sankey,model_object, rmvNode = ("demand; process heat","demand; residental heat","demand; mobility","import*; biomass","demand; residental demand", "gas"), dropDown = (:timestep,), minVal = 2.0, netExc = true);
    end
end
