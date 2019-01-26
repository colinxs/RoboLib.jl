module Util

using StaticArrays

# take (x,y[,theta]) in cartesian coordinate centered at lower left
# corner of image with x, y axes aligned with width and height of image, respectively,
# and transform them to matrix (not image) coordinates
to_grid(nrows, x, y) = nrows .- y, x
function to_grid(nrows, x, y, theta)
    x, y = to_grid(nrows, x, y)
    return x, y, theta .+ pi/2
end
from_grid(nrows, x, y) = y, nrows .- x
function from_grid(nrows, x, y, theta)
    x, y = from_grid(nrows, x, y)
    return x, y, theta .- pi/2
end

@inline function rangebearing2point(x0::Real, y0::Real, bearing::Real, range::Real)
    s, c = sincos(bearing)
    x1 = x0 + range * c
    y1 = y0 + range * s
    return x1, y1
end

@inline euclidean(x0, y0, x1, y1) = @. sqrt((y1-y0)^2 + (x1-x0)^2)

@inline wraptheta(theta) = (theta + pi) % (2 * pi) - pi

function binarize(arr::Matrix, test::Function=(el)->el<1.0)
    bitarr = similar(arr, Bool)
    @inbounds @simd for i = eachindex(arr)
        bitarr[i] = test(arr[i])
    end
    return bitarr
end

function mul!(vecs, t)
  @simd for i in 1:length(vecs)
    vecs[i] = t(vecs[i])
  end
end

end # module