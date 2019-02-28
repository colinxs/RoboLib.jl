# ----- Tables.jl interfaces and utility functions -----
using Tables
using JuliaDB

# --- Tables.jl Interfaces

# -- Vector-of-Struct (VOS)
# TODO: condense
@inline _vos_row(row, colnames) = NamedTuple{colnames}(Tuple(getproperty(row, p) for p in colnames))
@inline _vos_colname(row) = propertynames(row)

struct VOSSource{NT, A<:AbstractVector, P, R}
    arr::A
    colnamefn::P
    rowfn::R
end

function VOSSource(arr::A; colnamefn::P=_vos_colname, rowfn::R=_vos_row) where {A<:AbstractArray, P, R}
    el1 = first(arr)
    colnames = colnamefn(el1)
    coltypes = (typeof(col) for col in rowfn(el1, colnames))
    schema = NamedTuple{colnames, Tuple{coltypes...}}
    VOSSource{schema, A, P, R}(arr, colnamefn, rowfn)
end
export VOSSource

Tables.istable(::Type{<:VOSSource})= true
Tables.rowaccess(::Type{<:VOSSource})= true
Tables.rows(s::VOSSource{<:NamedTuple{colnames}}) where colnames = (s.rowfn(row, colnames) for row in s.arr)

# -- Dict-like

struct DictSource{NT, D, R, C}
    dict::D
    rowfn::R
    colfn::C
end

@inline _dict_row(dict) = Tuple(values(dict))
@inline _dict_colnames(dict) = Tuple(keys(dict))

function DictSource(dictlike::D; rowfn::R=_dict_row, colnamefn::C=_dict_colnames) where {D,R,C}
    colnames = colnamefn(dictlike)
    coltypes = (typeof(col) for col in rowfn(dictlike))
    schema = NamedTuple{colnames, Tuple{coltypes...}}
    DictSource{schema, D, R, C}(dictlike, rowfn, colnamefn)
end
export DictSource

Tables.istable(::Type{<:Union{<:DictSource, <:AbstractDict}})= true
Tables.columnaccess(::Type{<:Union{<:DictSource, <:AbstractDict}})= true
Tables.columns(s::DictSource{<:NamedTuple{names}}) where names = NamedTuple{names}(s.rowfn(s.dict))
Tables.columns(s::AbstractDict) = NamedTuple{Tuple(keys(s))}(Tuple(values(s)))


# --- table operations


# -- Join multiple tables by finding the best match along a common column (similar to Panda's merge_asof)

# TODO: add tests
function join_asof(tables::IndexedTable...; key::Symbol=:time, how::Symbol=:outer, presorted::Bool=true)
    # TODO wrap in debug
    for tbl in tables
        if !(key in colnames(tbl))
           error("$key not in $(colnames(tbl))")
        end
    end

    tables = [tables...]

    sort!(tables, by=(el)->length(el), rev=(how===:outer))

    # TODO: make copy?
    if !presorted
        for t in tables
            sort!(t, key)
        end
    end

    flatnames = (key, Tuple(n for t in tables for n in colnames(t) if !(n===key))...)
    master = popfirst!(tables)
    names = Tuple(Tuple(n for n in colnames(t) if !(n===key)) for t in tables)
    table(_join_asof(tables, names, flatnames, master, key))
end
export join_asof

function _join_asof(tables, names, flatnames, master, compkey)
    mastertime = select(master, compkey)
    master = popcol(master, compkey) #TODO...
    # TODO: prettier iterator?
    i=1
    t=mastertime[i]
    (tuplecat(NamedTuple{(compkey,)}(tuple(mastertime[i])), master[i], _findrow(tables, names, compkey, t)...) for (i, t) in enumerate(mastertime))
end

_findrow(tables, names, compkey, val) = (_findrow(t, n, compkey, val) for (t, n) in zip(tables, names))

function _findrow(table::IndexedTable, columns, compkey, val)
    # TODO: do this in the body of join_asof (only needs to be done once)
    compcol = select(table, compkey)
    datacols = select(table, columns)
    # TODO: we can do better than naive search at every iteration
    bestidx = searchsortednearest(compcol, val)
    datacols[bestidx]
end

#TODO revisit
#function splitapplycombine(f, tbl, selection; rev=false, pkey=nothing)
#    selection = isa(selection, Tuple) ? selection : (selection,)
#    within = map(f, tbl, select=selection)
#    without = select(tbl, Not(selection))
#    if rev
#        if !(pkey === nothing)
#            table(pushcol(without, pairs(columns(within))), copy=false, pkey=pkey)
#        else
#            table(pushcol(without, pairs(columns(within))), copy=false)
#        end
#    else
#        if !(pkey === nothing)
#            table(pushcol(within, pairs(columns(without))), copy=false, pkey=pkey)
#        else
#            table(pushcol(within, pairs(columns(without))), copy=false)
#        end
#    end
#end

# -- misc
coltypes(tbl) = Tuple(eltype(c) for c in columns(tbl))
export coltypes

postfix(table, suffix, exclude=(); delim="_") = renamecol(table, (c=>Symbol(c, delim, suffix) for c in colnames(table) if !(c in exclude)))
prefix(table, prefix, exclude=(); delim="_") = renamecol(table, (c=>Symbol(prefix, delim, c) for c in colnames(table) if !(c in exclude)))
export postfix, prefix

function transform(f, t; del=())
    newcols = map(f, t)
    popcol(pushcol(t, pairs(columns(newcols))), del)
end
export transform

setpkey(tbl, pkey) = table(tbl, copy=false, pkey=pkey)
export setpkey

# Make the time column start from zero
function reltime(synced; timekey=:timestamp)
    timecol = select(synced, timekey)
    startt = minimum(timecol)
    @assert isa(startt, DateTime)
    setcol(synced, timekey, Dates.Time.(Nanosecond.((timecol .- startt))))
end
export reltime

# TODO inplace
function dedup(tbl, colname)
    c = select(tbl, colname)
    uniqueidxs = Vector{Int}(indexin(unique(c), c))
    tbl[uniqueidxs]
end
export dedup









