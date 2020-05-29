import Pkg
Pkg.Registry.add("General") # you may skip this line if this is not a fresh instalation of Julia and you've updated/added a packge before
Pkg.Registry.add(Pkg.RegistrySpec(url = "https://github.com/yakir12/DackeLab")) # you need to do this only once for each instalation of Julia
Pkg.add(["Format2DB", "DungAnalyse"]) # you need to do this only once for each environment

path = "." # change this to the directory that contains all your experiments

using Format2DB, Glob, DungAnalyse, Serialization
import Base.Threads.@spawn
@sync foreach(readdir(glob"source_*", tempdir())) do d
    @spawn rm(d, force = true, recursive = true)
end
todo = readdir(path)
n = length(todo)
sources = Vector{Any}(undef, n)
@sync for i in 1:n
    @spawn sources[i] = Format2DB.main(joinpath(path, todo[i]))
end
source = DungAnalyse.joinsources(sources)
@sync foreach(sources) do d
    @spawn rm(d, force = true, recursive = true)
end
data = DungAnalyse.main(source)
serialize("data", data)

