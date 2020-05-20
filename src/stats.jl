meanstd(x) = (μ = mean(x); Ref(μ .± std(x, mean = μ)))

function descriptive_stats(df)
    d = stack(df, [:turning_point, :center_of_search], variable_name = :point_type, value_name = :point_xy)
    gd = groupby(d, [:point_type, :group, :nest_coverage])
    g = copy(combine(gd, :point_xy => meanstd => :point_xy, nrow))
    g.id = repeat(1:nrow(g)÷2, outer = 2)
    d = unstack(g, [:group, :nest_coverage, :nrow], :point_type, :point_xy)
    sort!(d, [:nest_coverage, :group])
    select!(d, [1,2,4,5,3])
    open("table1.txt", "w") do io
        pretty_table(io, d, ["Group" "Burrow coverage" "Turning point" "Gravity center" "n";
                               "" "" "μ ± σ" "μ ± σ" ""], 
                     hlines = [1,7],
                     alignment = [:l, :l, :c, :c, :r],
                     formatters = (v,i,j) -> 3 ≤ j ≤ 4  ? myformat(v) : v
                    )
    end
end


myformat(_::Missing) = "-"
myformat(x::Measurement) = string(round(Int, x.val), "±", round(Int, x.err))
myformat(xs::AbstractVector{String}) = string("(", xs[1], ",", xs[2], ")")
myformat(xs::AbstractVector{Float64}) = string("(", round(xs[1], digits = 2), ",", round(xs[2], digits = 2), ")")
myformat(xs::AbstractVector{Measurement{T}}) where {T <: Real} = myformat(myformat.(xs))


########### speed

speed(d) = (norm(p2.xy - p1.xy)/(p2.t - p1.t) for (p1, p2) in zip(d, lag(d, -1, default = d[end])) if p1.xy ≠ p2.xy)
function foo(d)
    length(d) < 10 && return missing
    s = speed(d)
    μ = mean(s)
    μ ± std(s, mean = μ)
end
function speeds!(df)
    df.homing_speed = [foo(track.rawcoords[1:track.tp]) for track in df.track]
    df.search_speed = [foo(track.rawcoords[track.tp:end]) for track in df.track]
    v = combine(groupby(df, :group), :homing_speed => mean ∘ skipmissing, :search_speed => mean ∘ skipmissing)
    println("speeds:")
    println(v)
    μ = mean(skipmissing(vcat(df.homing_speed, df.search_speed)))
    @printf "mean speed is %s cm/s\n" μ
end


################### displaced closed nest stats

roundsig(x) = x ≤ 0.05 ? @sprintf("%.2g", x) : "ns"

HypothesisTests.pvalue(t::StatsModels.TableRegressionModel) = GLM.coeftable(t).cols[4][2]

function displaced_stats(df)
    gdf = groupby(df, [:group, :nest_coverage])
    g = gdf[[(group = group, nest_coverage = "closed") for group in ("none", "right","left","towards", "away")]]

    n = 10^6
    tbls = map((:turning_point, :center_of_search)) do point
        data = combine(g, point => (x -> x .- Ref(mean(x))) => :centered)
        x1 = [r.centered for r in eachrow(data) if r.group == "none"]
        x2 = [r.centered for r in eachrow(data) if r.group ≠ "none"]
        tx = ApproximatePermutationTest(first.(x1), first.(x2), var, n)
        ty = ApproximatePermutationTest(last.(x1), last.(x2), var, n)
        @printf "%i permutations sampled at random from %i possible permutations\n" n factorial(big(length(x1)+length(x2)))
        σ = pvalue.([tx, ty], tail = :left)
        nσ = length(x1) + length(x2)
        @printf "Is the %s variance of the none group, (%i, %i) significantly smaller than the variancve of the displaced groups, (%i, %i)? P = (%.2g, %.2g) (n = %i)\n" replace(string(point), '_' => ' ') var(x1)... var(x2)... σ... nσ
        data = combine(g, point => (x -> first.(x)) => :x, point => (x -> last.(x)) => :y, :group => (x -> first.(intended.(x))) => :ix, :group => (x -> last.(intended.(x))) => :iy)
        tx = lm(@formula(ix ~ x), data)
        ty = lm(@formula(iy ~ y), data)
        nμ = nrow(data)
        @printf "Is the effect (%.2f, %.2f) of the displacement on the %s significant? P = (%.2g, %.2g) (n = %i)\n" coef(tx)[2] coef(ty)[2] replace(string(point), '_' => ' ') pvalue(tx) pvalue(ty) nμ
        combine(g, [:group, point] => ((g, x) -> myformat(roundsig.(pvalue.([
                                                                             OneSampleTTest(first.(x), first(intended(g[1]))), 
                                                                             OneSampleTTest(last.(x),   last(intended(g[1])))
                                                                            ])))) => point, nrow => :n)
    end
    tbl = hcat(tbls[1][!, Not(All(:n, :nest_coverage))], tbls[2][!, Not(All(:group, :nest_coverage))])
    m = Matrix(tbl)
    writedlm("table2.csv", m, ',')
end



############### transfer far stats

onesample(xy, g) = myformat([pvalue(OneSampleTTest(f.(xy), f(intended(g[1])))) for f in (first, last)])

function transfer_stats(df)
    gdf = groupby(df, :group)
    groups = ("far", "back")
    g = gdf[[(group = g,) for g in groups]]
    tbls = map((:turning_point, :center_of_search)) do point
        combine(g, [point, :group] => onesample => point, nrow)
    end
    tbl = hcat(tbls[1][:, Not(:nrow)], tbls[2][:, Not(:group)])
    m = Matrix(tbl)
    writedlm("table3.csv", m, ',')
end





