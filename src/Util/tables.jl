# ----- Tables.jl interfaces and utility functions -----
using Tables

# --- Tables.jl Interfaces

# -- Vector-of-Struct

@inline _vos_row(row, props) = NamedTuple{props}(Tuple(getproperty(row, p) for p in props))
@inline _vos_colname(row) = propertynames(row)

struct VOSSource{NT, A<:AbstractVector, P, R}
    arr::A
    colnamefn::P
    rowfn::R
end

function VOSSource(arr::A, colnamefn::P=_vos_colname, rowfn::R=_vos_row) where {A<:AbstractArray, P, R}
    el1 = first(arr)
    colnames = colnamefn(el1)
    coltypes = (typeof(col) for col in rowfn(el1, colnames))
    schema = NamedTuple{colnames, Tuple{coltypes...}}
    VOSSource{schema, A, P, R}(arr, colnamefn, rowfn)
end

Tables.istable(::Type{<:VOSSource})= true
Tables.rowaccess(::Type{<:VOSSource})= true
Tables.rows(s::VOSSource{<:NamedTuple{props}}) where props = (s.rowfn(row, props) for row in s.arr)

# -- Dict-like

struct DictSource{NT, D, R, C}
    dict::D
    rowfn::R
    colfn::C
end

@inline _dict_row(dict) = Tuple(values(dict))
@inline _dict_colnames(dict) = Tuple(keys(dict))

function DictSource(dictlike::D, rowfn::R=_dict_row, colnamefn::C=_dict_colnames) where {D,R,C}
    colnames = colnamefn(dictlike)
    coltypes = (typeof(col) for col in rowfn(dictlike))
    schema = NamedTuple{colnames, Tuple{coltypes...}}
    DictSource{schema, D, R, C}(dictlike, rowfn, colnamefn)
end

Tables.istable(::Type{<:Union{<:DictSource, <:AbstractDict}})= true
Tables.columnaccess(::Type{<:Union{<:DictSource, <:AbstractDict}})= true
Tables.columns(s::DictSource{<:NamedTuple{names}}) where names = NamedTuple{names}(s.rowfn(s.dict))
Tables.columns(s::AbstractDict) = NamedTuple{Tuple(keys(s))}(Tuple(values(s)))

# --- table operations

# -- Join multiple tables by finding the best match along a common column (similar to Panda's merge_asof)
using JuliaDB
function synchronize(tables::AbstractVector{<:IndexedTable}; key::Symbol=:time, how::Symbol=:outer, presorted::Bool=true)
    sort!(tables, by=(el)->length(el), rev=(how===:outer))

    if !presorted
        for t in tables
            sort!(t, key)
        end
    end

    flatnames = (key, Tuple(n for t in tables for n in colnames(t) if !(n===key))...)
    master = popfirst!(tables)
    names = Tuple(Tuple(n for n in colnames(t) if !(n===key)) for t in tables)
    _synchronize(tables, names, flatnames, master, key)
end

function _synchronize(tables, names, flatnames, master, compkey)
    mastertime = select(master, compkey)
    (NamedTuple{flatnames}(tuplecat(master[i], _findrow(tables, names, compkey, t)...)) for (i, t) in enumerate(mastertime))
end

_findrow(tables, names, compkey, val) = (_findrow(t, n, compkey, val) for (t, n) in zip(tables, names))

function _findrow(table::IndexedTable, columns, compkey, val)
    compcol = select(table, compkey)
    datacols = select(table, columns)
    bestidx = searchsortednearest(compcol, val)
    datacols[bestidx]
end





