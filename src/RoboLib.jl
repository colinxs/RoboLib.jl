module RoboLib
using Requires

function __init__()
    #NOTE(cxs) delete if no projects
    push!(LOAD_PATH, joinpath(@__DIR__, "../projects"))
    @require RobotOS = "22415677-39a4-5241-a37a-00beabbbdae8" include("ROS/ROS.jl")
end

include("Compat.jl")
include("Util/Util.jl")
include("Geom/Geom.jl")
#include("Visualization/Visualization.jl")

end # module
