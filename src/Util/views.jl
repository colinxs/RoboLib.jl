struct RepeatedView{D<:AbstractVector}
  data::D
  len::Int
  RepeatedView(d::D) where D = new{D}(d, length(d))
end

@inline function Base.getindex(a::RepeatedView, i::Int)
    if Base.checkbounds(Bool, a.data, i)
      return @inbounds a.data[i]
    elseif i > a.len
      return last(a.data)
    else
      return first(a.data)
    end
end

struct MirroredView{D<:AbstractVector}
  data::D
  len::Int
  MirroredView(d::D) where D = new{D}(d, length(d))
end

@inline function Base.getindex(a::MirroredView, i::Int)
    if Base.checkbounds(Bool, a.data, i)
      return @inbounds a.data[i]
    elseif i > a.len
      return a[a.len - (i % a.len)]
    else
      return a[-i + 2]
    end
end

struct PaddedView{T, D<:AbstractVector{T}}
  data::D
  len::Int
  fillval::T
  PaddedView(fillval::T, d::D) where {T,D<:AbstractVector{T}} = new{T, D}(d, length(d), fillval)
end

@inline function Base.getindex(a::PaddedView, i::Int)
    if Base.checkbounds(Bool, a.data, i)
      return @inbounds a.data[i]
    else
      return a.fillval
    end
end