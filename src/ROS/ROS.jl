module ROS

using PyCall

const rosbag = PyNULL()

function __init__()
    copy!(rosbag, pyimport("rosbag"))
end

include("rosbag.jl")
include("util.jl")
include("transforms.jl")

end