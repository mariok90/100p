
using Gurobi, AnyMOD, CSV

tradeInbalance_fl = 0
pvPot = ARGS[1]

# ! solve as copperplate

model_object = anyModel(["baseData","scenarios/copper","conditionalData/fixEU","timeSeries/hourly"],"_results", objName = "copperFirst", decommExc = :decomm);

deRegions_arr = vcat([6],model_object.sets[:R].nodes[6].down);
#openspace: 21, 20; rooftop: 22, 23, 24
if pvPot == "breyer" # scale pv potential to breyer values
    sca_dic = Dict(21 => 4.89, 20 => 4.89, 22 => 4.89,23 => 4.89, 24 => 4.89)
    model_object.parts.lim.par[:capaConvUp].data  |>  (y -> y[!,:val] = map(x -> x.val * ((x.R_exp in deRegions_arr && x.Te in collect(keys(sca_dic))) ?  sca_dic[x.Te] : 1.0),eachrow(y)))
end

# create rest of model
createOptModel!(model_object);
setObjective!(:costs, model_object);

# limits the imbalance of the trade balance
export_arr = filter(x -> x.R_from in deRegions_arr && !(x.R_to in deRegions_arr) && x.C == 7, model_object.parts.exc.var[:exc])[!,:var];
import_arr = filter(x -> x.R_to in deRegions_arr && !(x.R_from in deRegions_arr) && x.C == 7, model_object.parts.exc.var[:exc])[!,:var];

@constraint(model_object.optModel, tradebalance, sum(export_arr) + tradeInbalance_fl >= sum(import_arr));

set_optimizer(model_object.optModel,Gurobi.Optimizer);
set_optimizer_attribute(model_object.optModel, "Method", 2);
set_optimizer_attribute(model_object.optModel, "Crossover", 1);
optimize!(model_object.optModel);

# ! obtain capacities for technologies and write to parameter file
eeSym_arr = filter(x -> model_object.parts.tech[x].type == :mature &&  keys(model_object.parts.tech[x].carrier)  |> (y -> :gen in y && !(:use in y)), collect(keys(model_object.parts.tech)));
eeId_arr = map(x -> filter(y -> y.val == string(x),collect(values(model_object.sets[:Te].nodes)))[1].idx , eeSym_arr);
noEeSym_arr = filter(x -> !(x in eeSym_arr) && model_object.parts.tech[x].type == :mature, collect(keys(model_object.parts.tech)));
nonEeId_arr = map(x -> filter(y -> y.val == string(x),collect(values(model_object.sets[:Te].nodes)))[1].idx , noEeSym_arr);

allNuts3_arr = getfield.(filter(x -> x.lvl == 2 && model_object.sets[:R].up[x.idx] == 6, collect(values(model_object.sets[:R].nodes))),:idx);

# get share of total ee production per region
eeVlh_dic = Dict((filter(y -> y.val == string(x),collect(values(model_object.sets[:Te].nodes)))[1].idx,r) => sum(filter(x -> x.R_dis == r,model_object.parts.tech[x].par[:avaConv].data)[!,:val]) for x in eeSym_arr, r in allNuts3_arr);

eeGen_df = filter(x -> x.variable == :capaConv && x.Te in eeId_arr && x.R_dis in allNuts3_arr,reportResults(:summary,model_object, rtnOpt = (:rawDf,)));
eeGen_df[!,:gen] = map(x -> eeVlh_dic[(x.Te,x.R_dis)]*x.value,eachrow(eeGen_df));
eeReg_df = combine(groupby(eeGen_df,:R_dis),:gen => (x -> sum(x)) => :gen);
eeShare_dic = Dict(x.R_dis => x.gen/sum(eeReg_df[!,:gen]) for x in eachrow(eeReg_df));

# convert computed capacities into fixed limits in a parameter inputfile
eeCapa_df = filter(x -> x.variable == :capaConv && x.Te in eeId_arr && x.R_dis in allNuts3_arr,reportResults(:summary,model_object, rtnOpt = (:rawDf,)));

# for non-ee technologies, capacities are distributed among subregions proportional to ee generation
nonEECapa_df = filter(x -> x.variable in (:capaConv,:capaStIn,:capaStSize) && x.Te in nonEeId_arr && x.R_dis == 6,reportResults(:summary,model_object, rtnOpt = (:rawDf,)));
nonEECapa_df[!,:R_dis] = map(x -> model_object.sets[:R].nodes[x].down, nonEECapa_df[!,:R_dis]);
nonEECapa_df = flatten(nonEECapa_df,:R_dis)
nonEECapa_df[!,:value] = map(x -> eeShare_dic[x.R_dis]*x.value, eachrow(nonEECapa_df));


# write final csv file that is used as an input for the next computation
fixCapa_df = vcat(eeCapa_df,nonEECapa_df);
fixCapa_df[!,:Te] = map(x -> model_object.sets[:Te].nodes[x].val,fixCapa_df[!,:Te]);
fixCapa_df[!,:parameter] .= map(x -> x.Te == "ocgtHydrogen" ? Symbol(x.variable,:Low) : Symbol(x.variable,:Fix), eachrow(fixCapa_df));
fixCapa_df[!,:region_2] = map(x -> model_object.sets[:R].nodes[x].val,fixCapa_df[!,:R_dis]);
fixCapa_df[!,:technology_1] = map(x -> any(occursin.(["openspace_","rooftop_","onshore_","offshore_","home","grid"],x)) ? "" : x, fixCapa_df[!,:Te]);
fixCapa_df[!,:technology_2] = map(x -> !any(occursin.(["openspace_","rooftop_","onshore_","offshore_","home","grid"],x)) ? "" : x, fixCapa_df[!,:Te]);
select!(fixCapa_df, Not([:Ts_disSup,:R_dis,:C,:Te,:variable]));

CSV.write("conditionalData/intermediate/par_fixCapa.csv", fixCapa_df);

# ! solve again with regions and exchange expansion, but with fixed capacities
model_object = anyModel(["baseData","scenarios/decentral","conditionalData/fixEU","conditionalData/intermediate","conditionalData/importHydro","timeSeries"],"_results", objName = "copperSecond");

if pvPot == "breyer" # scale pv potential to breyer values
    sca_dic = Dict(21 => 4.89, 20 => 4.89, 22 => 4.89,23 => 4.89, 24 => 4.89)
    model_object.parts.lim.par[:capaConvUp].data  |>  (y -> y[!,:val] = map(x -> x.val * ((x.R_exp in deRegions_arr && x.Te in collect(keys(sca_dic))) ?  sca_dic[x.Te] : 1.0),eachrow(y)))
end

createOptModel!(model_object);
setObjective!(:costs, model_object);

# limits the imbalance of the trade balance
export_arr = filter(x -> x.R_from in deRegions_arr && !(x.R_to in deRegions_arr) && x.C == 7, model_object.parts.exc.var[:exc])[!,:var];
import_arr = filter(x -> x.R_to in deRegions_arr && !(x.R_from in deRegions_arr) && x.C == 7, model_object.parts.exc.var[:exc])[!,:var];

@constraint(model_object.optModel, tradebalance, sum(export_arr) + tradeInbalance_fl >= sum(import_arr));

set_optimizer(model_object.optModel, Gurobi.Optimizer);
set_optimizer_attribute(model_object.optModel, "Method", 2);
set_optimizer_attribute(model_object.optModel, "Crossover", 1);
optimize!(model_object.optModel);

# ! change objective to maximize decentral generation and fixed all cost-relevant variables and variables outside of Germany
changeObj!(model_object,deRegions_arr)

optimize!(model_object.optModel);
reportResults(:summary,model_object);
reportResults(:exchange,model_object);
reportResults(:costs,model_object);
plotSankey(model_object);
