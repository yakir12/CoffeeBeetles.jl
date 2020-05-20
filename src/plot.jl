######################## common traits for the plots 

max_width = 493.228346

set_theme!(
    font = "Helvetica", # 
    fontsize = 10,
    resolution = (max_width, 500.0),
    linewidth = 0.3,
    strokewidth = 1px, 
    markersize = 3px, 
    rowgap = Fixed(10), 
    colgap = Fixed(10),
    LLegend = (markersize = 10px, markerstrokewidth = 1, patchsize = (10, 10), rowgap = Fixed(2), titlegap = Fixed(5), groupgap = Fixed(10), titlehalign = :left, gridshalign = :left, framecolor = :transparent, padding = 0, linewidth = 0.3), 
    LAxis = (xticklabelsize = 8, yticklabelsize = 8, xlabel = "X (cm)", ylabel = "Y (cm)", autolimitaspect = 1, xtickalign = 1, xticksize = 3, ytickalign = 1, yticksize = 3, xticklabelpad = 4)
)
markers = Dict("turning_point" => '•', "center_of_search" => '■')
brighten(c, p = 0.5) = weighted_color_mean(p, c, colorant"white")
mydecompose(origin, radii) = [origin + radii .* Iterators.reverse(sincos(t)) for t in range(0, stop = 2π, length = 51)]
mydecompose(x) = mydecompose(x.origin, x.radii)
legendmarkers = OrderedDict(
                            "track" => (linestyle = nothing, linewidth = 0.3, color = :black),
                            "burrow" => (color = :black, marker = '⋆', strokecolor = :black, markerstrokewidth = 0.5, strokewidth = 0.5, markersize = 15px),
                            "fictive burrow" => (color = :white, marker = '⋆', strokecolor = :black, markerstrokewidth = 0.5, strokewidth = 0.5, markersize = 15px),
                            "turning point" => (color = :black, marker = markers["turning_point"], strokecolor = :transparent, markersize = 15px),
                            "center of search" => (color = :black, marker = markers["center_of_search"], strokecolor = :transparent, markersize = 5px),
                            "mean ± FWHM" => [(color = brighten(colorant"black", 0.75), strokecolor = :transparent, polypoints = mydecompose(Point2f0(0.5, 0.5), Vec2f0(0.75, 0.5))),
                                           (color = :white, marker = '+', strokecolor = :transparent, markersize = 10px), 
                                          ])
function getellipse(xy)
    n = length(xy)
    X = Array{Float64}(undef, 2, n)
    for i in 1:n
        X[:,i] = xy[i]
    end
    dis = fit(DiagNormal, X)
    radii = sqrt(2log(2))*sqrt.(var(dis)) # half the FWHM
    (origin = Point2f0(mean(dis)), radii = Vec2f0(radii))
end
function distance2nest(track)
    length(searching(track)) < 10 && return Inf
    t = homing(track)
    i = findfirst(>(0) ∘ last, t)
    isnothing(i) ? Inf : abs(first(t[i]))
end
apply_element(xs) = apply_element.(xs)
apply_element(x::NamedTuple) =  :marker ∈ keys(x) ? MarkerElement(; x...) :
                                :linestyle ∈ keys(x) ? LineElement(; x...) :
                                PolyElement(; x...)

label!(scene, ax, letter) = LText(scene, letter, fontsize = 12, padding = (10, 0, 0, 10), halign = :left, valign = :top, bbox = lift(FRect2D, ax.scene.px_area), font ="Noto Sans Bold")
function plottracks!(ax, g::GroupedDataFrame)
    for gg in g
        for r in eachrow(gg)
            lines!(ax, r.track.coords; legendmarkers["track"]..., color = r.color)
        end
    end
end
function plottracks!(ax, g::DataFrame)
    for r in eachrow(g)
        lines!(ax, r.track.coords; legendmarkers["track"]..., color = r.color)
    end
end
function plotpoints!(ax, g, point_type)
    if !ismissing(g[1].nest[1])
        scatter!(ax, [zero(Point2f0)]; legendmarkers["burrow"]...)
    end
    for (k, gg) in pairs(g)
        xy = gg[!, point_type]
        ellipse = getellipse(xy)
        c = gg.groupcolor[1]
        poly!(ax, mydecompose(ellipse), color = RGBA(brighten(c, 0.5), 0.5))
        scatter!(ax, [ellipse.origin]; legendmarkers["mean ± FWHM"][2]...)
        scatter!(ax, xy; legendmarkers[replace(point_type, "_" => " ")]..., color = RGBA(c, 0.75))
        if k.group ≠ "none"
            scatter!(ax, [Point2f0(intended(k.group))]; legendmarkers["fictive burrow"]..., strokecolor = gg.groupcolor[1])
        end
    end
end

######################## Figure 5 ################


function figure5(df)
    gdf = groupby(df, [:group, :nest_coverage])
    g = gdf[[(group = group, nest_coverage = "closed") for group in ("right","left","towards", "away")]]
    polys = OrderedDict(string(k.group) => (color = v.groupcolor[1], strokecolor = :transparent) for (k, v) in pairs(g))
    scene, layout = layoutscene(0, resolution = (max_width, 600.0))
    ax = layout[1,1] = LAxis(scene)
    plottracks!(ax, g)
    hidexdecorations!(ax, grid = false, ticklabels = false, ticks = false)
    hideydecorations!(ax, grid = false, ticklabels = false, ticks = false)
    label!(scene, ax, "a")
    axs = [LAxis(scene) for _ in 1:2]
    for (i, point_type) in enumerate(("turning_point", "center_of_search"))
        plotpoints!(axs[i], g, point_type)
    end
    layout[2,1:2] = axs
    hideydecorations!(axs[1], grid = false, ticklabels = false, ticks = false)
    hideydecorations!(axs[2], grid = false)
    hidexdecorations!.(axs, grid = false, ticklabels = false, ticks = false)
    layout[3, 1:2] = LText(scene, "X (cm)");
    linkaxes!(axs...)
    label!(scene, axs[1], "c")
    label!(scene, axs[2], "d")
    g = DataFrame(gdf[(group = "towards", nest_coverage = "open")], copycols = false)
    sort!(g, :track, by = distance2nest)
    d = g[1:3,:]
    c = d.groupcolor[1]
    ax = layout[1,2] = LAxis(scene)
    scatter!(ax, [zero(Point2f0)]; legendmarkers["burrow"]...)
    plottracks!(ax, d)
    scatter!(ax, turningpoint.(d.track); legendmarkers["turning point"]..., color = RGBA(c, 0.75))
    hidexdecorations!(ax, grid = false)
    hideydecorations!(ax, grid = false, ticklabels = false, ticks = false)
    linkxaxes!(ax, axs[2])
    label!(scene, ax, "b")
    layout[1:2, 0] = LText(scene, "Y (cm)", rotation = π/2);
    layout[4, 2:3] = LLegend(scene, apply_element.(values.([polys, legendmarkers])), collect.(keys.([polys, legendmarkers])), ["Direction of displacements", " "], orientation = :horizontal, nbanks = 2, tellheight = true, height = Auto(), groupgap = 30);
    scene
end
# FileIO.save("a.pdf", scene)





######################## Figure 6 ################
function figure6(df)
    gdf = groupby(df, :group)
    g = gdf[[(group = "zero",)]]
    polys = OrderedDict(string(k.group) => (color = v.groupcolor[1], strokecolor = :transparent) for (k, v) in pairs(g))
    scene, layout = layoutscene(0, resolution = (max_width, 400.0))
    ax = layout[1,1] = LAxis(scene)
    plottracks!(ax, g)
    hidexdecorations!(ax, grid = false, ticklabels = false, ticks = false)
    # hideydecorations!(ax, grid = false, ticklabels = false, ticks = false)
    label!(scene, ax, "a")
    axs = [LAxis(scene) for _ in 1:2]
    for (i, point_type) in enumerate(("turning_point", "center_of_search"))
        plotpoints!(axs[i], g, point_type)
    end
    layout[1,2:3] = axs
    hideydecorations!(axs[1], grid = false, ticklabels = false, ticks = false)
    hideydecorations!(axs[2], grid = false)
    hidexdecorations!.(axs, grid = false, ticklabels = false, ticks = false)
    layout[2, 1:3] = LText(scene, "X (cm)");
    linkaxes!(axs...)
    # linkyaxes!(ax, axs...)
    label!(scene, axs[1], "b")
    label!(scene, axs[2], "c")
    layout[3, 1:3] = LLegend(scene, apply_element(values(legendmarkers)), collect(keys(legendmarkers)), orientation = :horizontal, nbanks = 2, tellheight = true, height = Auto(), groupgap = 30);
    scene
end
# FileIO.save("a.pdf", scene)


######################## Figure 7 ################
function figure7(df)
    gdf = groupby(df, :group)
    g = gdf[[(group = "far",)]]
    polys = OrderedDict(string(k.group) => (color = v.groupcolor[1], strokecolor = :transparent) for (k, v) in pairs(g))
    scene, layout = layoutscene(0, resolution = (max_width, 300.0))
    ax = layout[1,1] = LAxis(scene)
    plottracks!(ax, g)
    hidexdecorations!(ax, grid = false, ticklabels = false, ticks = false)
    # hideydecorations!(ax, grid = false, ticklabels = false, ticks = false)
    label!(scene, ax, "a")
    axs = [LAxis(scene) for _ in 1:2]
    for (i, point_type) in enumerate(("turning_point", "center_of_search"))
        plotpoints!(axs[i], g, point_type)
    end
    layout[1,2:3] = axs
    hideydecorations!(axs[1], grid = false, ticklabels = false, ticks = false)
    hideydecorations!(axs[2], grid = false)
    hidexdecorations!.(axs, grid = false, ticklabels = false, ticks = false)
    layout[2, 1:3] = LText(scene, "X (cm)");
    linkaxes!(axs...)
    # linkaxes!(ax, axs...)
    label!(scene, axs[1], "b")
    label!(scene, axs[2], "c")
    x = copy(legendmarkers);
    delete!(x, "burrow")
    layout[3,1:3] = LLegend(scene, apply_element(values(x)), collect(keys(x)), orientation = :horizontal, nbanks = 2, tellheight = true, height = Auto(), groupgap = 30);
    scene
end
# FileIO.save("a.pdf", scene)





######################## Figure 4 ################

function binit(track, h, nbins, m, M)
    o = Union{Variance, Missing}[Variance() for _ in 1:nbins]
    d = track.rawcoords
    to = findfirst(x -> x.xy[2] > 0, d) - 1
    for (p1, p2) in Iterators.take(zip(d, lag(d, -1, default = d[to])), to)
        y = -(p2.xy[2] + p1.xy[2])/2
        if m < y < M
            i = StatsBase.binindex(h, y)
            v = norm(p2.xy - p1.xy)/(p2.t - p1.t)
            fit!(o[i], v)
        end
    end
    replace!(x -> nobs(x) < 2 ? missing : x, o)
end
function figure4(df)
    gdf = groupby(df, :group)
    g = gdf[[(group = "none",)]]
    polys = OrderedDict(string(k.group) => (color = v.groupcolor[1], strokecolor = :transparent) for (k, v) in pairs(g))
    scene = Scene(resolution = (max_width, 500.0), camera=campixel!);
    sz = round(Int, max_width/4)
    lo = GridLayout(
                    scene, 4, 3,
                    # colsizes = [Auto(), Fixed(sz), Auto(), Auto()],
                    # rowsizes = [Auto(), Auto(), Fixed(sz), Auto()],
                    alignmode = Outside(0, 0, 0, 0)
    )
    lo[2, 1:3] = LText(scene, "X (cm)", tellheight = true);
    ax1 = lo[1,1] = LAxis(scene, autolimitaspect = 1)
    # ax1 = lo[2,2] = LAxis(scene, xaxisposition = :top, xticklabelalign = (:center, :bottom), autolimitaspect = 1)
    # lo[1:2, 1] = LText(scene, "Y (cm)", rotation = π/2);
    plottracks!(ax1, g)
    rect = FRect2D(-10,-10,20,20)
    spinecolor = RGB(only(distinguishable_colors(1, [colorant"white"; g[1].color], dropseed = true))) #:yellow
    lines!(ax1, rect, color = spinecolor);
    hidexdecorations!(ax1, grid = false, ticklabels = false, ticks = false);
    # hideydecorations!(ax1, grid = false, ticklabels = false, ticks = false);
    # hideydecorations!(ax1, grid = false, ticklabels = false, ticks = false)
    label!(scene, ax1, "a")
    axs = [LAxis(scene, autolimitaspect = 1) for _ in 1:2]
    # axs = [LAxis(scene, xaxisposition = :top, xticklabelalign = (:center, :bottom), autolimitaspect = 1) for _ in 1:2]
    for (i, point_type) in enumerate(("turning_point", "center_of_search"))
        plotpoints!(axs[i], g, point_type)
    end
    lo[1,2:3] = axs
    hideydecorations!(axs[1], grid = false, ticklabels = false, ticks = false)
    hideydecorations!(axs[2], grid = false)
    hidexdecorations!.(axs, grid = false, ticklabels = false, ticks = false)
    linkaxes!(axs...)
    label!(scene, axs[1], "b")
    label!(scene, axs[2], "c")
    d = DataFrame(g[1], copycols = false)
    sort!(d, :turning_point, by = norm)
    d.color .= getcolor(d.groupcolor)
    d = d[1:3,:]
    # postTP = 25
    ax2 = lo[3,1] = LAxis(scene, 
                          aspect = DataAspect(),
                          autolimitaspect = 1,
                          bottomspinecolor = spinecolor,
                          topspinecolor = spinecolor,
                          leftspinecolor = spinecolor,
                          rightspinecolor = spinecolor,
                          # xaxisposition = :top, xticklabelalign = (:center, :bottom)
                         )
    for r in eachrow(d)
        lines!(ax2, homing(r.track); legendmarkers["track"]..., color = r.color)
        postTP = findfirst(xy -> any(>(10)∘abs, xy), searching(r.track))
        lines!(ax2, searching(r.track)[1:postTP]; legendmarkers["track"]..., color = r.color)
        # lines!(ax2, searching(r.track)[1:postTP]; legendmarkers["track"]..., color = 1:postTP, colormap = [r.color, colorant"white"])
        scatter!(ax2, [r.turning_point]; legendmarkers["turning point"]..., color = RGBA(r.color, 0.75))
    end
    scatter!(ax2, [zero(Point2f0)]; legendmarkers["burrow"]...)
    ax2.targetlimits[] = rect
    hidexdecorations!(ax2, grid = false, ticklabels = false, ticks = false)
    # hideydecorations!(ax2, grid = false, ticklabels = false, ticks = false)
    label!(scene, ax2, "d")
    m, M = (0, 120)
    nbins = 6
    bins = range(m, stop = M, length = nbins + 1)
    mbins = StatsBase.midpoints(bins)
    h = Histogram(bins)
    g = DataFrame(g[1], copycols = false)
    g[!, :id] .= 1:nrow(g)
    DataFrames.transform!(g, :id, :track => ByRow(x -> binit(x, h, nbins, m, M)) => :yv)
    μ = [Variance() for _ in 1:nbins]
    for i in 1:nbins
        reduce(merge!, skipmissing(yv[i] for yv in g.yv), init = μ[i])
    end
    bandcolor = RGB(only(distinguishable_colors(1, [colorant"white"; g.color; spinecolor], dropseed = true))) #:yellow
    ax = lo[3,2:3] = LAxis(scene, 
                           aspect = nothing, 
                           autolimitaspect = nothing,
                           xlabel = "Distance to burrow (cm)",
    ylabel = "Speed (cm/s)",
    xticks = mbins,
    xreversed = true,
    yaxisposition = :right,
    yticklabelalign = (:left, :center)
   )
    bh = band!(ax, mbins, mean.(μ) .- std.(μ), mean.(μ) .+ std.(μ), color = RGBA(bandcolor, 0.25))
    lh = lines!(ax, mbins, mean.(μ), color = :white, linewidth = 5)
    for r in eachrow(g)
        xy = [Point2f0(x, mean(y)) for (x,y) in zip(mbins, r.yv) if !ismissing(y)]
        lines!(ax, xy; legendmarkers["track"]..., color = r.color)
        scatter!(ax, xy; legendmarkers["turning point"]..., color = r.color)
    end
    ylims!(ax, 0, ax.limits[].origin[2] + ax.limits[].widths[2])
    xlims!(ax, Iterators.reverse(extrema(mbins))...)
    label!(scene, ax, "e")
    x = copy(legendmarkers)
    delete!(x, "fictive burrow")
    x["mean speed ± std"] = [(color = RGBA(bandcolor, 0.25), strokecolor = :transparent), (linestyle = nothing, linewidth = 3, color = :white)]
    x["individual speed"] = [x["track"], x["turning point"]]
    lo[4, 1:3] = LLegend(scene, apply_element(values(x)), collect(keys(x)), orientation = :horizontal, nbanks = 2, tellheight = true, height = Auto(), groupgap = 30);
    tight_ticklabel_spacing!(ax)
    colsize!(lo, 2, Relative(1/3))
    rowsize!(lo, 3, Aspect(2, 1))
    overlay = Scene(scene, camera = campixel!, raw = true)
    for (x, corner) in zip((-10.0, 10.0), (:topleft, :topright))
        point = Node(Point(x, -10.0))
        topleft_ax2 = lift(getfield(MakieLayout, corner), ax2.scene.px_area)
        point_screenspace = lift(ax1.scene.camera.projectionview, ax1.scene.camera.pixel_space, point) do pv, pspace, point
            projected = Point(AbstractPlotting.project(inv(pspace) * pv, point)[1:2]...) .+ AbstractPlotting.origin(ax1.scene.px_area[])
        end
        lines!(overlay, @lift([$point_screenspace, $topleft_ax2]), color = spinecolor)
    end
    scene
end

function save_figures(df)
    # mkpath("figures")
    for figure in (:figure4, :figure5, :figure6, :figure7)
        @eval FileIO.save($("$figure.pdf"), $figure(df))
    end
end
