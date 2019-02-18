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

tuplecat(t1::Tuple, t2::Tuple, t3...) = tuplecat((t1..., t2...), t3...)
tuplecat(t::Tuple) = t

# run func while redirecting it's stdout to /dev/null
# works only on POSIX systems
macro squashstdout(func)
    quote
        open("/dev/null", "w") do io
            redirect_stdout($(esc(func)), io)
        end
    end
end

# --- Tables.jl interface for vector-of-structs
using Tables

@inline generic_row(row, props) = NamedTuple{props}(Tuple(getproperty(row, p) for p in props))
@inline generic_properties(row) = propertynames(row)

struct Source{NT, A<:AbstractArray, P, R}
    arr::A
    propfn::P
    rowfn::R
end

function Source(arr::A, propfn::P=generic_properties, rowfn::R=generic_row) where {A<:AbstractArray, P, R}
    el = first(arr)
    colnames = propfn(el)
    coltypes = Tuple(typeof(getproperty(el, p)) for p in colnames)
    schema = NamedTuple{colnames, Tuple{coltypes...}}
    Source{schema, A, P, R}(arr, propfn, rowfn)
end

Tables.istable(::Type{<:Source})= true
Tables.rowaccess(::Type{<:Source})= true
Tables.rows(s::Source{<:NamedTuple{props}}) where props = (s.rowfn(row, props) for row in s.arr)
