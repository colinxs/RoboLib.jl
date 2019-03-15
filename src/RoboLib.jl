module RoboLib
using Requires

function __init__()
    push!(LOAD_PATH, joinpath(@__DIR__, "../projects"))
end

include("Compat.jl")
include("Util/Util.jl")
include("Geom/Geom.jl")
include("ROS/ROS.jl")
#include("Visualization/Visualization.jl")

end # module
