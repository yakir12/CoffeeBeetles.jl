module CoffeeBeetles

export main

using Serialization, DungBase

using DataStructures, CoordinateTransformations, Rotations, DataFrames, Missings, Distributions, AngleBetweenVectors, LinearAlgebra, StatsBase, OnlineStats, Colors, PrettyTables, Measurements, HypothesisTests, GLM, DelimitedFiles, Printf

using CairoMakie, MakieLayout, FileIO, AbstractPlotting
import AbstractPlotting:px
CairoMakie.activate!()

include("generate_artifacts.jl")
include("preparedata.jl")
include("stats.jl")
include("plot.jl")

"""
    main()
Create all the tables and figures included in the manuscript.
"""
function main()
    data = deserialize(datafile)
    df = getdf(data)
    speeds!(df)
    descriptive_stats(df)
    displaced_stats(df) 
    save_figures(df)
end


end # module
