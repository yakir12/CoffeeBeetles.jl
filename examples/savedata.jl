import Pkg
# Pkg.Registry.add("General") # you may skip this line if this is not a fresh instalation of Julia and you've updated/added a packge before
# Pkg.Registry.add(Pkg.RegistrySpec(url = "https://github.com/yakir12/DackeLab")) # you need to do this only once for each instalation of Julia
Pkg.add(["Format2DB", "DungAnalyse", "Glob"]) # you need to do this only once for each environment

path = "/home/yakir/downloads/raw" # change this to the directory that contains all your experiments

using Format2DB, Glob, DungAnalyse, Serialization
foreach(readdir(glob"source_*", tempdir())) do d
    rm(d, force = true, recursive = true)
end
todo = readdir(path, join = true)
goodpath(x) = isdir(x) && !startswith(x, '.') && !isempty(readdir(x))
filter!(goodpath, todo)
sources = Format2DB.main.(todo)
source = DungAnalyse.joinsources(sources)
foreach(sources) do d
    rm(d, force = true, recursive = true)
end
data = DungAnalyse.main(source)
serialize("data", data)
