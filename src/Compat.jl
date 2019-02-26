module Compat

# TODO: PR into compat.jl

if VERSION < v"1.1.0"
    eachrow(A::AbstractVecOrMat) = (view(A, i, :) for i in axes(A, 1))
    eachcol(A::AbstractVecOrMat) = (view(A, :, i) for i in axes(A, 2))
    @inline function eachslice(A::AbstractArray; dims)
        length(dims) == 1 || throw(ArgumentError("only single dimensions are supported"))
        dim = first(dims)
        dim <= ndims(A) || throw(DimensionMismatch("A doesn't have $dim dimensions"))
        idx1, idx2 = ntuple(d->(:), dim-1), ntuple(d->(:), ndims(A)-dim)
        return (view(A, idx1..., i, idx2...) for i in axes(A, dim))
    end
    export eachrow, eachcol, eachslice
end

if VERSION < v"1.1.0"
  isnothing(::Any) = false
  isnothing(::Nothing) = true
  export isnothing
end

if VERSION < v"1.1.0"
    fieldtypes(T::Type) = ntuple(i -> fieldtype(T, i), fieldcount(T))
    export fieldtypes
end



end