module Visualization

using StaticArrays, Makie
import AbstractPlotting: convert_arguments

# to make plotting easier
convert_arguments(::Type{<: Arrows}, xyuv::SVector{4}) = [Point2f0(xyuv[1], xyuv[2])], [Vec2f0(xyuv[3], xyuv[4])]
convert_arguments(::Type{<: BarPlot}, wc::Tuple) = (wc[1], wc[2])


#barplot!(s, wc::Tuple{<:Vector,<:Vector}; kwargs...) = barplot!(s, wc[1], wc[2]; kwargs...)

function addpose!(s::Scene, initdata::SVector{3, T}; arrowscale=10, kwargs...) where T <: Real
    pose = Node(initdata)
    posearrow = lift(pose) do p
        x, y, th = p
        u = arrowscale * cos(th)
        v = arrowscale * sin(th)
        SVector(x,y,u,v)
    end
    arrows!(
        s,
        posearrow;
        kwargs...,
    )
    return pose
end

function addweights!(s::Scene, weightcounts; kwargs...) where T <: Real
    wc = Node(weightcounts)
    barplot!(
        s,
        wc;
        color=rand(length(weightcounts[1])),
        kwargs...
    )
    return wc
end

function addpoints!(s::Scene, initdata::Vector{SVector{2, T}}; kwargs...) where T <: Real
    points = Node(initdata)
    scatter!(
        s,
        points;
        kwargs...
    )
    return points
end

function createviz(map::Matrix; scale=2)
    h, w = size(map)
    #scene = Scene(scale_plot=false, resolution=(scale*h, scale*w))
    scene=Scene()
    display(scene)
    # because of how makie plots
    plotmap = reverse(map', dims=2)
    image!(scene, plotmap)
    return scene
end

# TODO(cxs) figure out way to plot live w/o saving that doesn't grab cursor
runvizsave(f::Function, scene::Scene, iter; path="/tmp/vis.mp4") = record(f, scene, path, iter)
function runviz(f::Function, scene::Scene, iter; rate=30)
    for i in iter
        f(i)
        display(scene)
        sleep(1/rate)
    end
    scene
end


end # module