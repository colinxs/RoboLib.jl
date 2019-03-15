using Rotations: Quat
using RoboLib.Util: tuplecat, transform
using RoboLib.ROS: robotosduration2time, robotostime2datetime
using StaticArrays: SVector
import RobotOS

const PARSE_MAP = Dict{String, Function}()

function expandstruct(s)
    propertynames(s), (getproperty(s, p) for p in propertynames(s))
end

covar(c) = reshape(c, (6,6))

isstdtype(m) = (t=typeof(m); isprimitivetype(t) || t === String)

function expand_tbl(tbl)
    tbl = transform(tbl, del=:rosmsg) do row
        bagtimecol = (bagtime=robotostime2datetime(row.rosmsg.bagtime),)
        tuplecat(bagtimecol, expand(row.rosmsg.msg))
    end
    tbl
end
export expand_msg

function parse_header(msg)
    (stamp=robotostime2datetime(msg.stamp),
     seq=Int(msg.seq),
     frame_id=msg.frame_id)
end
PARSE_MAP["std_msgs/Header"] = parse_header

parse_vector3(m) = SVector(m.x, m.y, m.z)
PARSE_MAP["geometry_msgs/Vector3"] = parse_vector3

parse_point(m) = parse_vector3(m)
PARSE_MAP["geometry_msgs/Point"] = parse_point

parse_quaternion(m) = Quat(m.w, m.x, m.y, m.z)
PARSE_MAP["geometry_msgs/Quaternion"] = parse_quaternion

function parse_posewithcovariance(m)
    (pose=expand(m.pose), covariance=covar(m.covariance))
end
PARSE_MAP["geometry_msgs/PoseWithCovariance"] = parse_posewithcovariance

parse_empty(m) = nothing
PARSE_MAP["std_msgs/Empty"] = parse_empty

expand(m) = expand(m, nothing)
function expand(m, propname)
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
        return [expand(el, propname) for el in m]
    else
        # is a compound type
        try
            # throws error if not ROS type
            typestr = RobotOS._typerepr(typeof(m))

            if haskey(PARSE_MAP, typestr)
                # A type we know how to handle
                return PARSE_MAP[typestr](m)
            else
                # Compound ROS msg
                names, props = expandstruct(m)
                return NamedTuple{names}(expand(p, n) for (n, p) in zip(names, props))
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
