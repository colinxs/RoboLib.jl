using JLD2
using JuliaDB
using Tables

# To support the Tables.jl interface
_values(g) = (g[k] for k in keys(g))
_isleaf(g) = !any(isa.(_values(g), JLD2.Group))
_isnode(g) = all(isa.(_values(g), JLD2.Group))

abstract type AbstractLogTable end

function JuliaDB.table(gf::Union{JLD2.Group, JLD2.JLDFile})
    if _isleaf(gf)
        #table(LogTableLeaf(gf))
        table(LogTableLeaf(gf))
    elseif _isnode(gf)
        table(LogTable(gf))
    else
        error("$gf not a valid group!")
    end
end

struct LogTable{G<:Union{JLD2.Group, JLD2.JLDFile}} <: AbstractLogTable
    group::G
end

Tables.istable(::Type{<:LogTable})= true
Tables.columnaccess(::Type{<:LogTable})= true
_columns(lt::LogTable) = (table(v) for v in _values(lt.group))
_getsymbols(lt) = (Symbol.(keys(lt.group)))
function Tables.columns(lt::LogTable)
    NamedTuple{(_getsymbols(lt)...,)}(((c,) for c in _columns(lt)))
end
# ---- Leaf/Dataset

# children are not groups
struct LogTableLeaf{G<:JLD2.Group} <: AbstractLogTable
    group::G
end

Tables.istable(::Type{<:LogTableLeaf})= true
Tables.rowaccess(::Type{<:LogTableLeaf})= true
Tables.rows(lt::LogTableLeaf) = (lt.group[string(i)] for i in 1:length(keys(lt.group)))


# arrow transforms
getarrow(x::StaticArray) = getarrow(convert(Array, x))