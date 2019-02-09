using LoggingExtras, Logging, Dates

function oldlogs_datetime(dir::String, period::Period=Day(7); suffix::String="log")
  oldlogs = filter(readdir(abspath(dir))) do fname
    endswith(fname, suffix) && now() - DateTime(splitext(fname)[1]) > period
  end
  oldlogs = map(oldlogs) do old
    joinpath(abspath(dir), old)
  end
  oldlogs
end

function setupfilelogger(pkgfile; min_level=Logging.Info, append=false, always_flush=true, stamped=true, show_limited=false)
    pkgfile=abspath(pkgfile)
    pkgdir = dirname(pkgfile)
    projname = splitext(basename(pkgfile))[1]
    key = uppercase(projname) * "_LOGDIR"
    if haskey(ENV, key) && abspath(ENV[key])
      dir = abspath(ENV[key])
    else
      dir = joinpath(pkgdir, "logs")
      if !isdir(dir)
        println(dir)
        mkdir(dir)
      end
    end
    path = joinpath(dir, "$(now()).log")
    @info("$projname logging to $path")
    logger = FileLogger(path; min_level=min_level, append=append, always_flush=always_flush, stamped=stamped, show_limited=show_limited)
end
