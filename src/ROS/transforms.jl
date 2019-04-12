using Rotations: Quat
using RoboLib.Util: tuplecat, transform
using RoboLib.ROS: robotostime2datetime, robotosduration2time, ROSBag
using StaticArrays: SVector
import RobotOS

const TRANSFORM_MAP = Dict{String, Function}()

# util
function expandstruct(s)
    propertynames(s), (getproperty(s, p) for p in propertynames(s))
end

covar(c) = reshape(c, (6,6))

isstdtype(m) = (t=typeof(m); isprimitivetype(t) || t === String)

# --

# for JuliaDB tbls
function expand_tbl(tbl; msgprop=:rosmsg, bagtimeprop=:bagtime)
    tbl = transform(tbl, del=:rosmsg) do row
        rosmsg = getproperty(row, msgprop)
        bagtime = getproperty(rosmsg, bagtimeprop)
        bagtimecol = (bagtime=robotostime2datetime(bagtime),)
        tuplecat(bagtimecol, transform_msg(rosmsg.msg))
    end
    tbl
end
export expand_msg

# rostype2jltype transformations
function transform_header(msg)
    (stamp=robotostime2datetime(msg.stamp),
     seq=Int(msg.seq),
     frame_id=msg.frame_id)
end
TRANSFORM_MAP["std_msgs/Header"] = transform_header

transform_vector3(m) = SVector(m.x, m.y, m.z)
TRANSFORM_MAP["geometry_msgs/Vector3"] = transform_vector3

transform_point(m) = transform_vector3(m)
TRANSFORM_MAP["geometry_msgs/Point"] = transform_point

transform_quaternion(m) = Quat(m.w, m.x, m.y, m.z)
TRANSFORM_MAP["geometry_msgs/Quaternion"] = transform_quaternion

function transform_posewithcovariance(m)
    (pose=transform_msg(m.pose), covariance=covar(m.covariance))
end
TRANSFORM_MAP["geometry_msgs/PoseWithCovariance"] = transform_posewithcovariance

transform_empty(m) = nothing
TRANSFORM_MAP["std_msgs/Empty"] = transform_empty

# Recursively transform a message
function transform_msg(m, propname)
    if m === nothing
        return nothing
    elseif isstdtype(m)
        return m
    elseif propname===:data && isa(m, Vector{Int8})
        return m # heuristic for raw byte arrays
    elseif isa(m, RobotOS.Time)
        return robotostime2datetime(m)
    elseif isa(m, RobotOS.Duration)
        return robotosduration2time(m)
    elseif isa(m, Vector)
        return [transform_msg(el, propname) for el in m]
    else
        # is a compound type
        try
            # throws error if not ROS type
            typestr = RobotOS._typerepr(typeof(m))

            if haskey(TRANSFORM_MAP, typestr)
                #  type we know how to handle
                return TRANSFORM_MAP[typestr](m)
            else
                # Compound ROS msg
                names, props = expandstruct(m)
                return NamedTuple{names}(transform_msg(p, n) for (n, p) in zip(names, props))
            end
        catch e
            if isa(e, ErrorException) && e.msg == "Not a ROS type"
                @warn "Unable to handle type $(typeof(m)), falling back to no-op"
                return m
            else
                rethrow(e)
            end
        end
    end
end
function transform_msg(m::ROSMsg)
    msg = transform_msg(m.msg)
    bagtime = transform_msg(m.bagtime)
    ROSMsg(m.topic, msg, bagtime, m.typestr)
end
transform_msg(m) = transform_msg(m, nothing)


# -- end rostype2jltype transformations
