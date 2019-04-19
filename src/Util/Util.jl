module Util
using Requires

# TODO add CuArrays to init
include("misc.jl")
function __init__()
    @require JuliaDB = "a93385a2-3734-596a-9a66-3cfbb77141e6" include("tables.jl")
    @require CUDAnative = "be33ccc6-a3ff-5ff2-a52e-74243cff1e17" include("cuda.jl")
end

end # module
