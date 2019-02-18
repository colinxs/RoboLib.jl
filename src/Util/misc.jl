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
_getrow(x, i, fields) = NamedTuple{fields}(Tuple(getfield(x[i], f) for f in fields))

struct VecOfStructSource{NT, A<:AbstractArray}
    arr::A
end

function VecOfStructSource(arr::A) where A
    el = first(arr)
    colnames = propertynames(el)
    coltypes = Tuple(typeof(getfield(el, f)) for f in colnames)

    schema = NamedTuple{colnames, Tuple{coltypes...}}
    VecOfStructSource{schema, A}(arr)
end

Tables.istable(::Type{<:VecOfStructSource})= true
Tables.rowaccess(::Type{<:VecOfStructSource})= true

function Tables.rows(s::VecOfStructSource{<:NamedTuple{names, T}}) where {names, T}
    (_getrow(s.arr, i, names) for i in 1:length(s.arr))
end
