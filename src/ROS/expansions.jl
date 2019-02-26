using LinearAlgebra: diag
using Rotations: Quat

using RoboLib.Geom: project2D
using RoboLib.Util: tuplecat, transform

function expand_header(msg)
    (stamp=robotostime2datetime(msg.stamp),
     seq=Int(msg.seq),
     frame_id=msg.frame_id)
end
export expand_header


function expand_pose2D(msg)
    p = msg.position
    q = msg.orientation
    (x=p.x, y=p.y, theta=project2D(Quat(q.w, q.x, q.y, q.z)).theta)
end
export expand_pose2D

function expand_posestamped2D(msg)
    h = expand_header(msg.header)
    p = expand_pose2D(msg.pose)
    tuplecat(h, p)
end
export expand_posestamped2D

function expand_variance2D(msg)
    var = diag(reshape(msg, (6,6)))
    sigx, sigy = var[1:2]
    sigtheta = last(var)
    (sigx=sigx, sigy=sigy, sigtheta=sigtheta)
end
export expand_variance2D

function expand_posewithcovarstamped2D(msg)
    h = expand_header(msg.header)
    p = expand_pose2D(msg.pose.pose)
    c = expand_variance2D(msg.pose.covariance)
    tuplecat(h, p, c)
end
export expand_posewithcovarstamped2D

const expand_map = Dict{String, Function}()
export expand_map
expand_map["geometry_msgs/PoseStamped"] = expand_posestamped2D
expand_map["geometry_msgs/PoseWithCovarianceStamped"] = expand_posewithcovarstamped2D
expand_map["std_msgs/Header"] = expand_header

function expand_bagtime(tbl)
    transform(tbl) do row
        (bagtime=robotostime2datetime(row.rosmsg.bagtime),)
    end
end
export expand_bagtime

function expand_msg(tbl)
    typestr = first(tbl).rosmsg.typestr
    if haskey(expand_map, typestr)
        expanfn = expand_map[typestr]
        tbl = transform(tbl, del=:rosmsg) do row
            expanfn(row.rosmsg.msg)
        end
    end
    tbl
end
export expand_msg