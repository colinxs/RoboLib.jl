using Rotations: Quat
using Dates: Nanosecond, Second, unix2datetime
using RoboLib.Geom: project2D

rosquat2theta(rq) = project2D(Quat(rq.w, rq.x, rq.y, rq.z)).theta
export rosquat2theta

robotostime2datetime(t) = unix2datetime(t.secs) + Nanosecond(t.nsecs)
export robotostime2datetime

robotosduration2time(t) = Second(t.secs) + Nanosecond(t.nsecs)
export robotosduration2time
