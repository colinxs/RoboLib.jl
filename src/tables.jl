using JuliaDB
using Dates

# --- JuliaDB Utility Functions

const AbstractTable = Union{JuliaDB.AbstractNDSparse, JuliaDB.AbstractIndexedTable}
export AbstractTable

# -- join_asof
function join_asof(tables::IndexedTable...; key::Symbol=:time, how::Symbol=:outer, presorted::Bool=false)
    # TODO wrap i# TODO: add testsn debug
    for tbl in tables
        if !(key in colnames(tbl))
           error("$key not in $(colnames(tbl))")
        end
    end

    tables = [tables...]

    # TODO(cxs) err if how != inner or outer
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

function _findrow(table::IndexedTable, columns, compkey, val)
    # TODO: do this in the body of join_asof (only needs to be done once)
    compcol = select(table, compkey)
    datacols = select(table, columns)
    # TODO: we can do better than naive search at every iteration
    bestidx = searchsortednearest(compcol, val)
    datacols[bestidx]
end

_findrow(tables, names, compkey, val) = (_findrow(t, n, compkey, val) for (t, n) in zip(tables, names))
# --

# -- misc
coltypes(tbl) = Tuple(eltype(c) for c in columns(tbl))
export coltypes

postfix(table, suffix; exclude=(), delim="_") = renamecol(table, (c=>Symbol(c, delim, suffix) for c in colnames(table) if !(c in exclude)))
prefix(table, prefix; exclude=(), delim="_") = renamecol(table, (c=>Symbol(prefix, delim, c) for c in colnames(table) if !(c in exclude)))
export postfix, prefix

# TODO: needed?
#function transform(f, t; del=())
#    newcols = map(f, t)
#    popcol(pushcol(t, pairs(columns(newcols))), del)
#end
#export transform

setpkey(tbl, pkey) = table(tbl, copy=false, pkey=pkey)
export setpkey

# Make the time column start from zero
function reltime(synced; timekey=:timestamp)
    timecol = select(synced, timekey)
    @assert eltype(timecol) <: Union{Dates.AbstractTime, Dates.AbstractDateTime}
    setcol(synced, timekey, timecol .- minimum(timecol))
end
export reltime

# TODO inplace
function dedup(tbl, colname)
    c = select(tbl, colname)
    uniqueidxs = Vector{Int}(indexin(unique(c), c))
    tbl[uniqueidxs]
end
export dedup
# --









