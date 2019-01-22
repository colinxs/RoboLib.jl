module Util

using StaticArrays

# take (x,y[,theta]) in cartesian coordinate centered at lower left
# corner of image with x, y axes aligned with width and height of image, respectively,
# and transform them to matrix (not image) coordinates
to_grid(m::AbstractMatrix, x, y) = size(m,1) .- y, x
function to_grid(m::AbstractMatrix, x, y, theta)
    x, y = to_grid(m, x, y)
    return x, y, theta .+ pi/2
end
from_grid(m::AbstractMatrix, x, y) = y, size(m, 1) .- x
function from_grid(m::AbstractMatrix, x, y, theta)
    x, y = from_grid(m, x, y)
    return x, y, theta .- pi/2
end
function from_grid!(xy::Vector{SVector{2, T}}, m::AbstractMatrix) where T<:Real
    for i=eachindex(xy)
        x, y = xy[i]
        xy[i] = from_grid(m, x, y)
    end
end




@inline euclidean(x0, y0, x1, y1) = @. sqrt((y1-y0)^2 + (x1-x0)^2)

@inline wrap_negpi2pi(theta) = (theta + pi) % (2 * pi) - pi
@inline function heading2point(x, y, heading; mag=1)
    @fastmath x1 = x + mag * cos(heading)
    @fastmath y1 = y + mag * sin(heading)
    return x1, y1
end


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