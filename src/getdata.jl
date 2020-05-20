using Glob, Format2DB, DungAnalyse, Serialization
import Base.Threads.@spawn

clean_before() = @sync foreach(readdir(glob"source_*", tempdir())) do d
    @spawn rm(d, force = true, recursive = true)
end

function format()
    path = "raw"
    todo = readdir(path)
    n = length(todo)
    sources = Vector{Any}(undef, n)
    @sync for i in 1:n
        @spawn sources[i] = Format2DB.main(joinpath(path, todo[i]))
    end
    push!(sources, "registered")
end

function clean_after(sources)
    pop!(sources)
    @sync foreach(sources) do d
        @spawn rm(d, force = true, recursive = true)
    end
end

function post_fetch_method(fs)
    unpack.(fs)
    clean_before()
    sources = format()
    source = DungAnalyse.joinsources(sources)
    clean_after(sources)
    data = DungAnalyse.main(source)
    serialize("data", data)
end

