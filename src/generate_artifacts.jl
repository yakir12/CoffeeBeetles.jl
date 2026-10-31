using Pkg.Artifacts

artifact_toml = joinpath(@__DIR__, "..", "Artifacts.toml")
data_hash = artifact_hash("data", artifact_toml)

if data_hash == nothing || !artifact_exists(data_hash)
    data_hash = create_artifact() do artifact_dir
        cp(joinpath(@__DIR__, "..", "data"), joinpath(artifact_dir, "data"))
    end
    bind_artifact!(artifact_toml, "data", data_hash)
end

datafile = joinpath(artifact"data", "data")
