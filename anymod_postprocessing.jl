
function split_into_cols(df::AbstractDataFrame, col)
    new_cols =  map(x -> anymod_split(x), df[!,col])
    cols_len = map(length, new_cols)
    return new_cols, cols_len
end

function convert_splitted_cols_to_tuple_of_arrays(col, lens)
    Tuple(
        map(x -> i <= lens[x] ? col[x][i] : col[x][lens[x]], 1:length(col))
        for i in 1:maximum(lens)
    )
end

function expand_col!(df::T, col) where T <: AbstractDataFrame
    cols, lens = split_into_cols(df, col)
    tup_of_arr = convert_splitted_cols_to_tuple_of_arrays(cols, lens)
    for (i, c) in enumerate(tup_of_arr)
        df[!, col * "_$i"] = c
    end
    return df
end

anymod_split(x::AbstractString) = split(x, " < ")
anymod_split(x::AbstractString, i::Int) = split(x, " < ")[i]