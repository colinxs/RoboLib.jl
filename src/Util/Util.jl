module Util

using StaticArrays

# take (x,y[,theta]) in cartesian coordinate centered at lower left
# corner of image with x, y axes aligned with width and height of image, respectively,
# and transform them to matrix (not image) coordinates
#img2grid(nrows, x, y) = nrows .- y, x
#function img2grid(nrows, x, y, theta)
#    x, y = img2grid(nrows, x, y)
#    return x, y, theta .+ pi/2
#end
#grid2img(nrows, x, y) = y, nrows .- x
#function grid2img(nrows, x, y, theta)
#    x, y = grid2img(nrows, x, y)
#    return x, y, theta .- pi/2
#end

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

@inline euclidean(x0, y0, x1, y1) = @. sqrt((y1-y0)^2 + (x1-x0)^2)

@inline wraptheta(theta) = mod((theta + pi), (2 * pi)) - pi

function binarize(arr, test::Function=(el)->el<1.0)
    bitarr = similar(arr, Bool)
    @simd for i = eachindex(arr)
        bitarr[i] = test(arr[i])
    end
    return bitarr
end

function mul!(vecs, t)
  @simd for i in 1:length(vecs)
    vecs[i] = t(vecs[i])
  end
end

function noisefunc(dist, rng=Random.GLOBAL_RNG)
    let dist=dist, rng=rng, n=length(dist)
        function noise()
            SVector{n}(rand(rng, dist))
        end
    end
end

macro debugtask(ex)
  quote
    try
      $(esc(ex))
    catch e
      bt = catch_backtrace()
      showerror(Base.stderr, e, bt)
      exit()
    end
  end
end

# subsample TODO(cxs): allow for arbitrary axis
subsamplefactor(a::AbstractArray, n::Integer) = (a[i] for i in first(a):n:last(a))
subsampleN(a::AbstractArray, n::Integer) = (a[round(Int,i)] for i in LinRange(firstindex(a), lastindex(a), n))

#function propnoisefunc(dist, rng=Random.GLOBAL_RNG)
#    let dist=dist, rng=rng, n=length(dist)
#        function noise()
#            SVector{n}(rand(rng, dist))
#        end
#    end
#end

include("cuda.jl")

end # module