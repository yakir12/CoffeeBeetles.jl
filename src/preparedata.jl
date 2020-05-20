############# data preparation ###################

function parsetitle(title, r)
    run = r.data
    d = Dict{Symbol, Any}(k => missing for k in (:displace_location, :displace_direction , :nest_coverage, :transfer))
    d[:nest_coverage] = "open"
    d[:nest] = run.originalnest
    d[:feeder] = run.feeder
    d[:fictive_nest] = run.nest
    d[:track] = run.track
    d[:title] = title
    d[:comment] = r.metadata.comment
    for kv in split(title, ' ')
        k, v = split(kv, '#')
        if k ∉ ("person", "pellet")
            if k == "nest"
                d[:nest_coverage] = v
            else
                d[Symbol(k)] = v
            end
        end
    end
    return (; pairs(d)...)
end

function getdf(data)
    data["nest#closed person#therese displace_direction#none displace_location#feeder"] = data["nest#closed person#therese"]
    delete!(data, "nest#closed person#therese")
    df = DataFrame(parsetitle(k, r) for (k, v) in data for r in v.runs)

    @. df[!, :displace_direction] = switchdirections.(df.displace_direction)
    @. df[!, :group] .= getgroup(df.displace_location, df.transfer, df.displace_direction)
    @. df[!, :set] = getset(df.transfer, df.group)

    categorical!(df, [:group, :set, :displace_direction, :displace_location, :nest_coverage, :transfer])
    levels!(df.group, ["none", "left", "right", "away", "towards", "zero", "back", "far"])

    filter!(r -> r.group ≠ "far" || r.title == "transfer#far person#therese", df)

    df[!, :direction_deviation]  = [angle(r.fictive_nest - r.feeder, turningpoint(r.track) - r.feeder) for r in eachrow(df)]
    max_direction_deviation = maximum(r.direction_deviation for r in eachrow(df) if r.group ∉ ("far", "zero"))
    mean_direction_deviation = mean(r.direction_deviation for r in eachrow(df) if r.group ∉ ("far", "zero"))
    filter!(r -> r.group ≠ "far" || r.direction_deviation < 4mean_direction_deviation, df)

    df[!, :turning_point] .= zero.(df.feeder)
    df[!, :center_of_search] .= zero.(df.feeder)
    for r in eachrow(df)
        trans = createtrans(r.nest, r.displace_location, r.fictive_nest, r.feeder)
        @. r.track.coords = trans(r.track.coords)
        @. r.track.rawcoords.xy .= trans(r.track.rawcoords.xy)
        r.feeder = trans(r.feeder)
        r.fictive_nest = trans(r.fictive_nest)
        r.nest = trans(r.nest)
        Δ = intended(r.group) - r.fictive_nest
        r.turning_point = turningpoint(r.track) + Δ
        r.center_of_search = searchcenter(r.track) + Δ
    end

    groups = levels(df.group)
    nc = length(groups)
    colors = OrderedDict(zip(groups, [colorant"black"; distinguishable_colors(nc - 1, [colorant"white", colorant"black"], dropseed = true)]))

    gdf = groupby(df, :group)
    DataFrames.transform!(gdf, :group => (g -> colors[g[1]]) => :groupcolor)
    DataFrames.transform!(gdf, :groupcolor => getcolor => :color)

    df
end

switchdirections(_::Missing) = missing
switchdirections(d) =   d == "left" ? "right" :
                        d == "right" ? "left" :
                        d

getgroup(displace_location::Missing, transfer, displace_direction) = transfer
getgroup(displace_location, transfer, displace_direction) = displace_location == "nest" ? "zero" : displace_direction
getset(_::Missing, d) = d == "none" ? "Closed" : "Displacement"
getset(_, __) = "Transfer"


intended(d::AbstractString) =  d == "none" ? DungAnalyse.Point(0,0) :
                d == "away" ? DungAnalyse.Point(0, -50) :
                d == "towards" ? DungAnalyse.Point(0, 50) :
                d == "right" ? DungAnalyse.Point(50, 0) :
                d == "left" ? DungAnalyse.Point(-50, 0) :
                d == "zero" ? DungAnalyse.Point(0, -130) :
                d == "back" ? DungAnalyse.Point(0,0) :
                d == "far" ? DungAnalyse.Point(0,0) :
                error("unknown displacement")
intended(d) = intended(string(d))

_get_rotation_center(displace_location::Missing, nest, fictive_nest) = fictive_nest
_get_rotation_center(displace_location, nest, fictive_nest) = displace_location == "feeder" ? fictive_nest : nest
_get_zeroing(nest::Missing, fictive_nest) = fictive_nest
_get_zeroing(nest, fictive_nest) = nest
function createtrans(nest, displace_location, fictive_nest, feeder)
    v = feeder - _get_rotation_center(displace_location, nest, fictive_nest)
    α = atan(v[2], v[1])
    rot = LinearMap(Angle2d(-π/2 - α))
    trans = Translation(-_get_zeroing(nest, fictive_nest))
    passmissing(rot ∘ trans)
end


function highlight(c, i, n)
    h = HSL(c)
    HSL(h.h, h.s, i/(n + 1))
end
function getcolor(g)
    n = length(g)
    [highlight(c, i, n) for (i, c) in enumerate(g)]
end


