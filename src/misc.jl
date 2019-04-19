using Interpolations # for applywin
using Dates: Second, TimePeriod, CompoundPeriod # for tosecond

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

# theta -> [-pi, pi]
@inline wrap2minuspipi(theta) = mod((theta + pi), (2 * pi)) - pi
export wrap2minuspipi

# N-dim array to boolean mask
function binarize(a::AbstractArray, binfn)
    bitarr = similar(a, Bool)
    @inbounds @simd for i = eachindex(a)
        bitarr[i] = binfn(a[i])
    end
    bitarr
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
# ---

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
mapvalues!(f, d::AbstractDict) = (for (k,v) in d d[k] = f(v) end; d)
export mapvalues!

# convert any period to seconds
# TODO make work for other periods
function converttime(totype::Type{<:TimePeriod}, t::T) where T<:TimePeriod
  factor = convert(totype, Second(1)).value / convert(T, Second(1)).value
  t.value * factor
end
function converttime(totype::Type{<:TimePeriod}, t::T) where T<:CompoundPeriod
  sum(converttime(totype, p) for p in t.periods)
end
tosecond(t) = converttime(Second, t)
export tosecond, converttime

# do "expr" if test is defined
macro ifdefined(test::Symbol, expr::Expr)
  @isdefined(test) ? esc(expr) : nothing
end
macro ifdefined(test::Expr, expr::Expr)
  deepisdefined(test) ? esc(expr) : nothing
end
export @ifdefined
# ---

"Check if a nested module/symbol (i.e. Base.Iterators.Take) is defined"
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


"""
    applywin(f, datas...; hwin=0, extrapmode=Reflect())

Apply `f` to `d[i-hwin:i+hwin]` for each index of `d`
, for each `d` in `datas`. Requires all `d` in `datas` to have
the same length.

See Interpolations.jl for valid options for extrapmode.
"""
function applywin(f, datas::AbstractArray...; hwin::Integer=0, extrapmode=Reflect())
  l = unique(length.(datas))
  @assert length(l) == 1
  l = first(l)
  _applywin(f, l, extrapmode, hwin, datas...)
end
_slicewin(i, hwin, datas...) = Tuple(d(i-hwin:i+hwin) for d in datas)
function _applywin(f, l, extrapmode, hwin, datas...)
  exdatas = Tuple(extrapolate(interpolate(x, BSpline(Constant())), extrapmode) for x in datas)
  [f(_slicewin(i, hwin, exdatas...)...) for i in 1:l]
end
export applywin

"Compute the pair-wise difference between adject elements in `x`"
delta(x) = x[2:end] .- x[1:end-1]
export delta
