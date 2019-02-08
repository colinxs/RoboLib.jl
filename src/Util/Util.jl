module Util

using StaticArrays

# TODO(cxs): document
@inline img2grid(x, y) = y, x
@inline function img2grid(x, y, theta)
    x, y = img2grid(x, y)
    return x, y, pi/2 .- theta
end

@inline grid2img(x, y) = img2grid(x, y)
@inline function grid2img(x, y, theta)
    x, y = grid2img(x, y)
    return x, y, -(theta .- pi/2)
end

@inline function rangebearing2point(x0::Real, y0::Real, bearing::Real, range::Real)
    s, c = sincos(bearing)
    x1 = x0 + range * c
    y1 = y0 + range * s
    return x1, y1
end

@inline euclidean(x0, y0, x1, y1) = sqrt((y1-y0)^2 + (x1-x0)^2)

@inline wrap2minuspipi(theta) = mod((theta + pi), (2 * pi)) - pi

function binarize(arr, test::Function=(el)->el<1.0)
    bitarr = similar(arr, Bool)
    @inbounds @simd for i = eachindex(arr)
        bitarr[i] = test(arr[i])
    end
    return bitarr
end

macro debugtask(ex)
  quote
    try
      $(esc(ex))
    catch e
      bt = stacktrace(catch_backtrace())
      showerror(Base.stderr, e, bt)
      exit()
    end
  end
end

# subsample TODO(cxs): allow for arbitrary axis
takeN(a::AbstractArray, n::Integer) = @inbounds (a[round(Int,i)] for i in LinRange(firstindex(a), lastindex(a), n))

include("cuda.jl")
include("circularchannel.jl")

end # module