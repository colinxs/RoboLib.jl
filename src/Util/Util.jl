module Util
using Requires

# TODO add CuArrays to init
include("misc.jl")
include("tables.jl")
function __init__()
    @require CUDAnative = "be33ccc6-a3ff-5ff2-a52e-74243cff1e17" include("cuda.jl")
end
include("savgol.jl")
include("views.jl")
#include("circulararray.jl")
#include("logging.jl")

end # module
