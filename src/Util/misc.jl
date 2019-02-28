using StaticArrays
using StructArrays

# image coordinate to array indices (and vice-versa)
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
export img2grid, grid2img
# ---

@inline function rangebearing2point(x0::Real, y0::Real, bearing::Real, range::Real)
    s, c = sincos(bearing)
    x1 = x0 + range * c
    y1 = y0 + range * s
    return x1, y1
end
export rangebearing2point

@inline euclidean(x0, y0, x1, y1) = sqrt((y1-y0)^2 + (x1-x0)^2)
export euclidean

@inline wrap2minuspipi(theta) = mod((theta + pi), (2 * pi)) - pi
export wrap2minuspipi

# N-dim matrix to boolean mask
function binarize(arr, test::Function=(el)->el<1.0)
    bitarr = similar(arr, Bool)
    @inbounds @simd for i = eachindex(arr)
        bitarr[i] = test(arr[i])
    end
    return bitarr
end
export binarize

# force tasks/coroutines to raise exceptions
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
export @debugtask

# Grab N evenly-spaced elements from an array
# subsample TODO(cxs): allow for arbitrary axis
takeN(a::AbstractArray, n::Integer) = @inbounds (a[round(Int,i)] for i in LinRange(firstindex(a), lastindex(a), n))
export takeN

# concatenate tuples (with zero allocations!)
tuplecat(t1, t2, t3...) = tuplecat((t1..., t2...), t3...)
# NamedTuples need special handling
function tuplecat(t1::NamedTuple, t2::NamedTuple, t3::NamedTuple...)
    tuplecat(NamedTuple{tuple(keys(t1)..., keys(t2)...)}(tuple(t1..., t2...)), t3...)
end
tuplecat(t) = t
export tuplecat

# run func while redirecting it's stdout to /dev/null
# works only on POSIX systems
macro squashstdout(func)
    quote
        open("/dev/null", "w") do io
            redirect_stdout($(esc(func)), io)
        end
    end
end
export @squashstdout

# find idx such that abs(a[idx] - x) <= abs(a[i] - x)
# for 1 <= i <= length(a). Breaks ties by returniGng
# the first tie
function searchsortednearest(a, x)
   idx = searchsortedfirst(a,x)
   if (idx==1); return idx; end
   if (idx>length(a)); return length(a); end
   if (a[idx]==x); return idx; end
   if (abs(a[idx]-x) < abs(a[idx-1]-x))
      return idx
   else
      return idx-1
   end
end
export searchsortednearest

# apply f to the values of d
function mapvalues!(f, d::AbstractDict)
    for (k,v) in d
        d[k] = f(v)
    end
    d
end
export mapvalues!

# convert any period to seconds
# TODO make work for other periods
using Dates: Second
tosecond(t::T) where T = t / convert(T, Second(1))
export tosecond

macro ifdefined(test::Symbol, expr::Expr)
  @isdefined(test) ? esc(expr) : nothing
end
macro ifdefined(test::Expr, expr::Expr)
  deepisdefined(test) ? esc(expr) : nothing
end
export @ifdefined

macro deepisdefined(test::Expr)
  deepisdefined(test)
end
function deepisdefined(test::Expr)
  base, s = test.args
  try
    return isdefined(eval(base), eval(s))
  catch
  end
  false
end
export @deepisdefined

