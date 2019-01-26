using CoordinateTransformations, Rotations, StaticArrays
import CoordinateTransformations: compose
using LinearAlgebra

const T2d = SVector{2}
const R2d = Rotation{2}
const SE2{L, T} = AffineMap{L,T} where L <: R2d where T <: T2d

struct Pose2D{T<:SE2}
  affine::T
  function Pose2D(dtype::Type{T}, x::Number, y::Number, theta::Number) where T <: Real
    aff = AffineMap(Angle2d{T}(theta), SVector{2, T}(x, y))
    new{typeof(aff)}(aff)
  end
  function Pose2D(dtype::Type{T}, aff::SE2) where T <: Real
    aff = AffineMap(Angle2d{dtype}(aff.linear), SVector{2,dtype}(aff.translation))
    new{typeof(aff)}(aff)
  end
  function Pose2D(statev::SVector{3, T}) where T<:Real
    x, y, theta = statev
    Pose2D(T, x, y, theta)
  end
end
function Pose2D(aff::SE2{L, T}) where L where T
  C = promote_type(eltype(L), eltype(T))
  Pose2D(C, aff)
end
function Pose2D(x::Number, y::Number, theta::Number)
  Pose2D(Float64, x, y, theta)
end

# TODO(cxs): add warning if composing with non-SE2 type?
compose(p::Pose2D, t::AffineMap) = compose(p.affine, t)
compose(t::AffineMap, p::Pose2D) = compose(t, p.affine)
compose(p::Pose2D, t::SE2) = Pose2D(compose(p.affine, t))
compose(t::SE2, p::Pose2D) = Pose2D(compose(t, p.affine))
compose(p1::Pose2D, p2::Pose2D) = Pose2D(compose(p1.affine, p2.affine))

Base.inv(p::Pose2D) = Pose2D(inv(p.affine))
Base.eltype(p::Pose2D{SE2{L, T}}) where L where T = eltype(T)
Base.isapprox(p::Pose2D, t::SE2; kwargs...) = Base.isapprox(p.affine, t; kwargs...)
Base.isapprox(t::SE2, p::Pose2D; kwargs...) = Base.isapprox(t, p.affine; kwargs...)
Base.isapprox(p1::Pose2D, p2::Pose2D; kwargs...) = Base.isapprox(p1.affine, p2.affine; kwargs...)

function body2world(T_BP::Pose2D, T_WB::Pose2D)
  return Pose2D(T_WB.affine ∘ T_BP.affine)
end

function world2body(T_WP::Pose2D, T_WB::Pose2D)
  return Pose2D(inv(T_WB.affine) ∘ T_WP.affine)
end

# TODO(cxs): add setters
function Base.setproperty!(p::Pose2D, s::Symbol, val)
  if s === :theta
    p.affine.linear.theta = val
  else
    setfield!(p, s, val)
  end
end

function Base.getproperty(p::Pose2D, s::Symbol)
  if s === :x
    return p.affine.translation[1]
  elseif s === :y
    return p.affine.translation[2]
  elseif s === :theta
    return p.affine.linear.theta
  elseif s === :posv
    return p.affine.translation
  elseif s === :statev
    return SVector{3}(p.x, p.y, p.theta)
  else
    return getfield(p, s)
  end
end


# useful 2D transforms and utils

function get_axes(aff::AffineMap{L, T}) where L where T <: T2d
  axes = aff.linear * SMatrix{2,2}(I)
  xaxis, yaxis = axes[:, 1], axes[:, 2]
end
# TODO(cxs): add typing
function get_axes_angles(aff::AffineMap)
  xax, yax = get_axes(aff)
  sx, cx = vec_sincos([1,0], xax)
  sy, cy = vec_sincos([0,1], yax)
  return atan(sx, cx), atan(sy, cy)
end

function vec_sincos(v1, v2)
  n = norm(v1) * norm(v2)
  s = (v1[1] * v2[2] -  v1[2] * v2[1]) / n
  c = dot(v1, v2) / n
  return s, c
end

function Scale(T::DataType, sx::Number, sy::Number)
  z, o = zero(T), one(T)
  SMatrix{2,2,T}(sx,z,z,sy)
end

function ReflectXY(T::DataType)
  z, o = zero(T), one(T)
  SMatrix{2,2,T}(z,o,o,z)
end

function ReflectX(T::DataType)
  z, o = zero(T), one(T)
  SMatrix{2,2,T}(o,z,z,-o)
end

function ReflectY(T::DataType)
  z, o = zero(T), one(T)
  SMatrix{2,2,T}(-o,z,z,o)
end
