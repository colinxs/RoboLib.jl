using JLD2, HDF5
using RecursiveArrayTools
using EllipsisNotation

include("../circularchannel.jl")

struct LogRequest{T<:NamedTuple}
    name::String
    data::T
end

mutable struct LogBuffer{T<:NamedTuple, G<:JLD2.Group}
    group::G
    idx::Int
    LogBuffer{T}(group::G) where {T,G} = new{T, G}(group, 1)
end

struct LogManager{F<:JLD2.JLDFile}
    file::F
    handles::Dict{String, LogBuffer}
    LogManager(file::F) where F = new{F}(file, Dict{String, LogBuffer}())
end

@inline function append!(lm::LogManager, req::LogRequest{T}) where T
    if !haskey(lm.handles, req.name)
        lm.handles[req.name] = LogBuffer{T}(JLD2.Group(lm.file, req.name))
    end
    append!(lm.handles[req.name], req)
end

@inline function append!(lb::LogBuffer{T}, req::LogRequest{T}) where T
    lb.group[string(lb.idx)] = req.data
    lb.idx += 1
end

Base.close(lm::LogManager) = close(lm.file)

function listen(lm::LogManager, ch::CircularChannel)
    try
        while isopen(ch) append!(lm, take!(ch)) end
    finally
        close(lm)
    end
end

function testarray(ch, n, dim, path="dim$dim/dset")
    size_ = ntuple(x->5, dim)
    testdata = []
    for i = 1:n
        data = (x=rand(size_...),)
        put!(ch, LogRequest(path, data))
        push!(testdata, data)
    end
    path, testdata
end

function compare(file, grouppath, testdata)
    testgroup = read(file, grouppath)
    for i in 1:length(testdata)
        if !(testgroup[string(i)] == testdata[i])
            return false
        end
    end
    true
end

function testscalar(ch, n, path="scalar/dset")
    testdata = []
    for d in rand(n)
        d = (x=d,)
        put!(ch, LogRequest(path, d))
        push!(testdata, d)
    end
    path, testdata
end

function test(path)
    jldopen(path, "w") do file
        ch = CircularChannel{LogRequest}(100)
        lm = LogManager(file)

        patharr1, testarr1 = testarray(ch, 3, 1)
        patharr2, testarr2 = testarray(ch, 10, 2)
        patharr3, testarr3 = testarray(ch, 10, 3)
        pathscalar, testscalardata = testscalar(ch, 10)
        task = @async listen(lm, ch)

        while isready(ch) sleep(0.01) end
        #close(lm)

        println(compare(file, patharr1, testarr1))
        println(compare(file, patharr2, testarr2))
        println(compare(file, patharr3, testarr3))
        println(compare(file, pathscalar, testscalardata))
    end
end







