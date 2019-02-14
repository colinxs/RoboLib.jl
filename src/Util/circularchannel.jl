using DataStructures: CircularBuffer

export CircularChannel

mutable struct CircularChannel{T} <: AbstractChannel{T}
    buf::CircularBuffer{T}
    cond_take::Condition
    open::Bool
end

function CircularChannel{T}(capacity::Int) where T
    buf = CircularBuffer{T}(capacity)
    cond = Condition()
    CircularChannel{T}(buf, cond, true)
end

@inline function Base.put!(cb::CircularChannel, val)
    push!(cb.buf, val)
    notify(cb.cond_take, nothing, true, false)
    cb
end

@inline Base.take!(cb::CircularChannel) = (wait(cb); popfirst!(cb.buf))
@inline Base.fetch(cb::CircularChannel) = (wait(cb); cb.buf[1])
@inline Base.wait(cb::CircularChannel) = while isempty(cb.buf) wait(cb.cond_take) end
@inline Base.isready(cb::CircularChannel) = !isempty(cb.buf) && isopen(cb)
@inline Base.isopen(cb::CircularChannel) = cb.open
@inline Base.close(cb::CircularChannel) = cb.open = false

