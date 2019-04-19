module RoboLib
using Requires

# To make loading RoboLib as fast as possible, we using Requires for chunks of code that
# supplement functionality of an existing module (i.e. you'd only ever include("tables.jl") if
# working with JuliaDB)

# For standalone things (like Geom), we borrow from Plots.jl and provide a function
# load_xxx() to load that thing

# Always loaded
include("misc.jl")
include("Compat.jl")

# Loaded if required module present
function __init__()
    #NOTE(cxs) delete if no projects
    push!(LOAD_PATH, joinpath(@__DIR__, "../projects"))
    @require RobotOS = "22415677-39a4-5241-a37a-00beabbbdae8" include("ROS/ROS.jl")
    @require JuliaDB = "a93385a2-3734-596a-9a66-3cfbb77141e6" include("tables.jl")
    @require CUDAnative = "be33ccc6-a3ff-5ff2-a52e-74243cff1e17" include("cuda.jl")
end

# loaded only when called for
load_geom() = include("Geom/Geom.jl")

end # module
