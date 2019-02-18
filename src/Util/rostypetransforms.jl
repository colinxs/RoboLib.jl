using JuliaDB
using StaticArrays

# TODO: put this + typegen in @requires statement so we don't always have to generate types

# for Vector3, Point, etc...
vec_xyz(x) = SVector(x.x, x.y, x.z)

# for Quaternion
vec_xyzw(x) = SVector(x.x, x.y, x.z, x.w)

## for PoseWithCovariance, TwistWithCovaraince, etc...




