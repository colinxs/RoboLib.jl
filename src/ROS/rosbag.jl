import RobotOS
using RobotOS: Time, _nameconflicts, _jl_safe_name, _rosimport, rostypegen, AbstractMsg, rostypereset

using Tables

using RoboLib.Util: VOSSource

export ROSMsg, ROSBag, read_messages, read_messages_dict

struct ROSMsg{M<:AbstractMsg}
    topic::String
    msg::M
    bagtime::Time
    typestr::String
    type::DataType
end

struct ROSBag
    bag::PyObject
    typemap::Dict{String, DataType}
    typeinfo::Dict{String, String}
    topicinfo::Dict{String, Tuple{String, Int64, Int64, Union{Float64, Nothing}}}
    bagname::String
    function ROSBag(bagpath, types=[]; kwargs...)
        bag = rosbag[:Bag](bagpath, kwargs...)
        typeinfo, topicinfo = bag[:get_type_and_topic_info]()
        typemap = _load_types(topicinfo, types)
        name = basename(bagpath)
        new(bag, typemap, typeinfo, topicinfo, name)
    end
end

# TODO: cache
Base.getindex(b::ROSBag, t::String) = read_messages_dict(b, topics=t)[t]

_parsetypestr(t) = convert.(String, split(t, "/"))

function _load_types(topicinfo, typestrs)
    # if unspecified, default to all types in bag
    if length(typestrs) == 0
        typestrs = (tup[1] for tup in values(topicinfo))
    end

    # rosimport all types
    toeval = Dict{String, Expr}()
    #rostypereset()
    for t in typestrs
        pkg, msgtype = _parsetypestr(t)
        _rosimport(pkg, true, msgtype)
        msgtype = _nameconflicts(msgtype) ? _jl_safe_name(msgtype, "Msg") : msgtype
        toeval[t] = Meta.parse("RobotOS.$pkg.msg.$msgtype")
    end
    # reset first to avoid "method too new" error
    rostypegen(RobotOS)
    Dict(tstr=>eval(expr) for (tstr, expr) in toeval)
end

# TODO Python iterator is slow (not convert), try batch reading in python
# then pass data
function read_messages(b::ROSBag; kwargs...)
    filt = Base.Iterators.filter(b.bag[:read_messages](;kwargs...)) do (_, msg, _)
        haskey(b.typemap, msg[:_type])
    end
    Base.Iterators.map(filt) do (topic, msg, t)
        typestr = msg[:_type]
        type = b.typemap[typestr]
        msg = convert(type, msg)
        t = convert(RobotOS.Time, t)
        ROSMsg(topic, msg, t, typestr, type)
    end
end

# TODO prealloc
function read_messages_dict(b::ROSBag; kwargs...)
    d = Dict{String, Vector{<:ROSMsg}}()
    for m in read_messages(b; kwargs...)
        if haskey(d, m.topic)
            push!(d[m.topic], m)
        else
            d[m.topic] = [m]
        end
    end
    d
end

# --- Tables.jl interface
#_rosmsg_row(m, colnames) = NamedTuple{colnames}((m.time, (getproperty(m.msg, n) for n in colnames[2:end])...))
#_rosmsg_colnames(m) = (:time, propertynames(m.msg)...)
#
#struct Source{M, T}
#    topic::T
#    Source(topic::T) where {M<:ROSMsg, T<:AbstractVector{M}} = Source{M, T}(topic)
#end
#
#function Tables.rows(s::Source{M, T}) where {M<:ROSMsg, T<:AbstractVector{M}}
#    (_bag_row(row, names) for row in s.topic)
#end
#
#Tables.istable(::Type{<:Source})= true
#Tables.rowaccess(::Type{<:Source})= true
#Tables.rows(s::Source) = Tables.rows(s.source)






