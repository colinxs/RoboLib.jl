using StaticArrays

#export SharedBuffer

#struct SharedBuffer{T, N, CH}
#    s::SharedArray{T, N}
#    ch::CH
#end
#
#function SharedBuffer{T, N}(n::Integer; pids=Int[]) where {T,N}
#    ch = RemoteChannel(()->Channel{Nothing}(1))
#    SharedBuffer{T,N,typeof(ch)}(SharedArray{T, N}(n; pids=pids), ch)
#end
#
#put!(D::SharedBuffer) = put!(D.ch, nothing)
#put!(D::SharedBuffer, v) = (!isready(D.ch); put!(D.ch, nothing))
#take!(D::SharedBuffer) = (take!(D.ch); D.s[myid()]=myid())

export CircularArray, capacity, isfull

mutable struct CircularArray{V, C} <: AbstractChannel{V}
    capacity::Int
    first::Int
    length::Int
    arr::V
    col::C
    cond_take::Condition
end

function CircularArray(arr::AbstractArray)
    lastdim = ndims(arr)
    capacity = size(arr, lastdim)
    col=ntuple(x->:, lastdim - 1)
    CircularArray{typeof(arr), typeof(col)}(capacity, 1, 0, arr, col, Condition())
end

function Base.empty!(cb::CircularArray)
    cb.length = 0
    cb
end

Base.@propagate_inbounds @inline function _arr_index_checked(cb::CircularArray, i::Int)
    @boundscheck if i < 1 || i > cb.length
        throw(BoundsError(cb, i))
    end
    _arr_index(cb, i)
end

@inline function _arr_index(cb::CircularArray, i::Int)
    n = cb.capacity
    idx = cb.first + i - 1
    ifelse(idx > n, idx - n, idx)
end

@inline Base.@propagate_inbounds function Base.put!(cb::CircularArray, data)
    # if full, increment and overwrite, otherwise push
    if cb.length == cb.capacity
        cb.first = (cb.first == cb.capacity ? 1 : cb.first + 1)
    else
        cb.length += 1
    end
    cb.arr[cb.col..., _arr_index(cb, cb.length)] = data
    notify(cb.cond_take, nothing, true, false)
    cb
end

@inline Base.@propagate_inbounds function Base.take!(cb::CircularArray, out::AbstractArray)
    fetch(cb, out)
    cb.first = ifelse(cb.first + 1 > cb.capacity, 1, cb.first + 1)
    cb.length -= 1
    nothing
end
@inline Base.@propagate_inbounds function Base.take!(cb::CircularArray)
    v = fetch(cb)
    cb.first = ifelse(cb.first + 1 > cb.capacity, 1, cb.first + 1)
    cb.length -= 1
    v
end

@inline Base.@propagate_inbounds function Base.getindex(cb::CircularArray, i::Int)
    cb.arr[cb.col..., _arr_index_checked(cb, i)]
end

@inline Base.@propagate_inbounds function Base.setindex!(cb::CircularArray, data, i::Int)
    cb.arr[cb.col..., _arr_index_checked(cb, i)] = data
    cb
end

@inline Base.fetch(cb::CircularArray) = (wait(cb); cb.arr[cb.col..., cb.first])
@inline function Base.fetch(cb::CircularArray, out::AbstractArray)
    wait(cb);
    copyto!(out, view(cb.arr, cb.col..., cb.first))
    nothing
end
@inline Base.wait(cb::CircularArray) = while isempty(cb) wait(cb.cond_take) end
@inline Base.isready(cb::CircularArray) = !isempty(cb)
@inline Base.length(cb::CircularArray) = cb.length
@inline Base.size(cb::CircularArray) = (length(cb),)
#@inline Base.convert(::Type{Array}, cb::CircularArray{T}) where {T} = T[x for x in cb]
@inline Base.isempty(cb::CircularArray) = cb.length == 0
@inline capacity(cb::CircularArray) = cb.capacity
@inline isfull(cb::CircularArray) = length(cb) == cb.capacity
