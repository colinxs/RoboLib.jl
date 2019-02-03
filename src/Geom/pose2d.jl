using CoordinateTransformations, Rotations, StaticArrays
import CoordinateTransformations: compose
using LinearAlgebra
import Distributions, Statistics

#const T3D = Union{SVector{3}, Translation{3}}
const T2D = Union{SVector{2}, Translation{2}}
const R2D = Rotation{2}
const SE2{L, T} = AffineMap{L,T} where L <: R2D where T <: T2D
const T3D = Union{SVector{3}, Translation{3}}
const R3D = Rotation{3}
const SE3{L, T} = AffineMap{L,T} where L <: R3D where T <: T3D


@inline project2D(r::R3D) = Angle2d(RotXYZ(r).theta3)
@inline project2D(t::T3D) = SVector(t[1], t[2])
@inline project2D(r::R3D, t::T3D) = project2D(r), project2D(t)
@inline project2D(a::SE3) = AffineMap(project2D(a.linear), project2D(a.translation))

@inline project3D(r::R2D) = Quat(RotXYZ(0,0,r.theta))
@inline project3D(t::T2D) = SVector(t[1], t[2], 0)
@inline project3D(r::R2D, t::T2D) = project3D(r), project3D(t)
@inline project3D(a::SE2) = AffineMap(project3D(a.linear), project3D(a.translation))

struct Pose2D{T}
  affine::AffineMap{Angle2d{T}, SVector{2, T}}

  @inline Pose2D{T}() where T = new{T}(AffineMap(Angle2d{T}(0), zero(SVector{2, T})))
  @inline Pose2D{T}(x::Real, y::Real, theta::Real) where T = new{T}(AffineMap(Angle2d{T}(theta), SVector{2, T}(x, y)))
  @inline Pose2D{T}(r::R2D, t::T2D) where T = new{T}(AffineMap(Angle2d{T}(r), SVector{2, T}(t[1], t[2])))
  @inline Pose2D{T}(aff::SE2) where T = Pose2D{T}(Angle2d(aff.linear), aff.translation)
  @inline Pose2D{T}(sv::SVector{3}) where T = Pose2D{T}(sv[1],sv[2],sv[3])
  @inline function Pose2D{T}(aff::AffineMap) where T
    l = aff.linear ./ norm(aff.linear[:, 1])
    # TODO: revisit later
    #if isrotation(l)
      return Pose2D{T}(Angle2d(l), aff.translation)
    #else
    #  error("LinearMap does not contain valid rotation: $l")
    #end
  end
end
@inline Pose2D(args...) = Pose2D{Float64}(args...) # default to Float64

# TODO(cxs): add warning if composing with non-SE2 type?
@inline compose(p::Pose2D{T}, t::AffineMap) where T = Pose2D{T}(compose(p.affine, t))
@inline compose(t::AffineMap, p::Pose2D{T}) where T = Pose2D{T}(compose(t, p.affine))
@inline compose(p1::Pose2D{T1}, p2::Pose2D{T2}) where {T1,T2} = Pose2D{promote_type(T1, T2)}(compose(p1.affine, p2.affine))

@inline Base.inv(p::Pose2D) = Pose2D(inv(p.affine))
@inline Base.isapprox(p::Pose2D, t::AffineMap; kwargs...) = Base.isapprox(p.affine, t; kwargs...)
@inline Base.isapprox(t::AffineMap, p::Pose2D; kwargs...) = Base.isapprox(t, p.affine; kwargs...)
@inline Base.isapprox(p1::Pose2D, p2::Pose2D; kwargs...) = Base.isapprox(p1.affine, p2.affine; kwargs...)

@inline function Base.getproperty(p::Pose2D{T}, s::Symbol) where T
  @inbounds begin
    if s === :x
      return getfield(p, :affine).translation[1]
    elseif s === :y
      return getfield(p, :affine).translation[2]
    elseif s === :theta
      return getfield(p, :affine).linear.theta
    elseif s === :posv
      #todo this should always be length 2
      return SVector{2,T}(getfield(p, :affine).translation[1:2])
    elseif s === :statev
      th = getfield(p, :affine).linear.theta
      x, y = getfield(p, :affine).translation
      return SVector{3, T}(x, y, th)
    else
      return getfield(p, s)
    end
  end
end
#TODO(cxs): propertynames to match above

function mean(poses::AbstractVector{<:Pose2D{T}}, weights::AbstractVector{<:Real}) where T
    Tbar = zeros(SVector{2, Float64})
    sinsum = Float64(0)
    cossum = Float64(0)
    @assert eachindex(poses) == eachindex(weights)
    @inbounds @simd for i in eachindex(poses)
      p, w = poses[i], weights[i]
      Tbar += p.posv * w
      s, c = sincos(p.theta)
      sinsum += s * w
      cossum += c * w
    end
    Rbar = atan(sinsum / length(poses), cossum / length(poses))
    Tbar /= length(poses)
    return Pose2D{T}(Angle2d(Rbar), Tbar)
end

function mean(poses::AbstractVector{<:Pose2D{T}}) where T
    Tbar = zeros(SVector{2, Float64})
    sinsum = Float64(0)
    cossum = Float64(0)
    @inbounds @simd for p in poses
      Tbar += p.posv
      s, c = sincos(p.theta)
      sinsum += s
      cossum += c
    end
    Rbar = atan(sinsum / length(poses), cossum / length(poses))
    Tbar /= length(poses)
    return Pose2D{T}(Angle2d(Rbar), Tbar)
end

#TODO: check type stabil on Type param
#@inline Scale3D(t::Type, sx, sy, sz) = LinearMap(SMatrix{3,3,t}(sx,0,0,0,sy,0,0,0,sz))
#@inline Scale3D(sx, sy, sz) = Scale3D(Float64, sx, sy, sz)
@inline Scale2D(t::Type, s) = LinearMap(SMatrix{2,2,t}(s,0,0,s))
@inline Scale2D(s) = Scale2D(Float64, s)

Statistics.mean(p::AbstractVector{<:Pose2D}) = mean(p)

#TODO(cxs) clean up and verify w/ test before uncommenting
# useful 2D transforms and utils
#@inline function get_axes(aff::SE2)
#  axes = aff.linear * SMatrix{2,2}(I)
#  xaxis, yaxis = axes[:, 1], axes[:, 2]
#end
#
## TODO(cxs): add typing
#@inline function get_axes_angles(aff::SE2)
#  xax, yax = get_axes(aff)
#  sx, cx = vec_sincos([1,0], xax)
#  sy, cy = vec_sincos([0,1], yax)
#  return atan(sx, cx), atan(sy, cy)
#end
#
#@inline function vec_sincos(v1, v2)
#  n = norm(v1) * norm(v2)
#  s = (v1[1] * v2[2] -  v1[2] * v2[1]) / n
#  c = dot(v1, v2) / n
#  return s, c
#end
#
#function Scale(T::DataType, sx::Number, sy::Number)
#  z, o = zero(T), one(T)
#  SMatrix{2,2,T}(sx,z,z,sy)
#end
#
#function ReflectXY(T::DataType)
#  z, o = zero(T), one(T)
#  SMatrix{2,2,T}(z,o,o,z)
#end
#
function ReflectX(T::DataType)
  z, o = zero(T), one(T)
  SMatrix{2,2,T}(o,z,z,-o)
end
#
#function ReflectY(T::DataType)
#  z, o = zero(T), one(T)
#  SMatrix{2,2,T}(-o,z,z,o)
#end
