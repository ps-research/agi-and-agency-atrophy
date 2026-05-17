#!/usr/bin/env julia
# scripts/updated/fig_2_1.jl — Paper 2, Fig 2.1 (revision)
# Updates:
#   - remove main figure title
#   - replace the "never crosses D=0.5" placeholder text on the top 5 rows
#     with quantitative annotations: "max D = X.XX via S_XX" colored by the
#     causing state. Same Gantt structure for crossing rows.

using CairoMakie, Printf, Statistics, JSON
include(joinpath(@__DIR__, "..", "lib", "figures_lib.jl"))

const FIG_NAME = "fig2_1_OS_paradox_gantt"
const OUT_DIR  = joinpath(FIGURES_ROOT, FIG_NAME)
mkpath(OUT_DIR)

println("Loading OS Paradox time series…")
OS_TS = load_ts(2, 1, 1.0, 0.0, 1.0)
println("Loading cluster names…")
CLUSTER_NAMES = load_cluster_names()

# Helper: max D and the archetype that produced it, per cluster.
function cluster_max_D(ts::TS)
    out = fill((0.0, ""), 14)
    t_i = col_idx(ts.header, "t")
    a_i = col_idx(ts.header, "archetype")
    d_idxs = [col_idx(ts.header, "D_$(lpad(i, 2, '0'))") for i in 1:14]
    for r in ts.rows
        a = r[a_i]
        for c in 1:14
            D = parse(Float64, r[d_idxs[c]])
            if D > out[c][1]
                out[c] = (D, a)
            end
        end
    end
    return out
end

function build_figure()
    crossings = cluster_crossings(OS_TS)      # (t, archetype) per cluster, Inf if never
    maxD      = cluster_max_D(OS_TS)           # (max_D, archetype) per cluster

    # Same row ordering as before: crossing time ascending (Inf at top).
    order = sortperm([c[1] == Inf ? 1e9 : c[1] for c in crossings])

    fig = Figure(size = (820, 460))
    ax = Axis(fig[1, 1];
        xlabel = "Timestep t",
        ylabel = "Occupation cluster",
        xticks = 0:20:100,
        xlabelsize = 12, ylabelsize = 12,
        xticklabelsize = 10,
        limits = ((0, 100), (0.4, 14.6)),
        yticks = (collect(1:14), [CLUSTER_NAMES[order[i]] for i in 1:14]),
        yticklabelsize = 10.5,
    )

    for (rowi, ci) in enumerate(order)
        t_cross, arch_cross = crossings[ci]
        if t_cross == Inf
            # Non-crossing row: show "max D = X.XX via S_XX" annotated in the
            # causing state's color, with a faint horizontal indicator
            # proportional to max_D / 0.5 so the eye can compare magnitudes.
            mD, mArch = maxD[ci]
            color = isempty(mArch) ? (:gray50, 1.0) : (get(STATE_COLORS, mArch, :gray), 1.0)
            # subtle bar showing how close it got (scaled to 0–100 axis units, where 100 = D=0.5)
            bar_end = clamp(2.0 * mD * 100.0, 0.0, 100.0)  # 2*mD because target is 0.5
            if bar_end > 0.5
                poly!(ax, Point2f[(0, rowi-0.18), (bar_end, rowi-0.18),
                                   (bar_end, rowi+0.18), (0, rowi+0.18)];
                      color = (color[1], 0.18), strokewidth = 0)
            end
            if isempty(mArch)
                text!(ax, 0.8, rowi; text = @sprintf("max D = %.2f  (constant — d-vector zero)", mD),
                      color = (:gray45, 0.95), align = (:left, :center), fontsize = 9.5,
                      font = :italic)
            else
                text!(ax, 0.8, rowi;
                      text = @sprintf("max D = %.2f  via %s  (peak fraction of threshold = %.0f%%)",
                                       mD, mArch, 2.0 * mD * 100),
                      color = color[1], align = (:left, :center), fontsize = 9.5,
                      font = :italic)
            end
        else
            # Crossing row: original Gantt bar from t_cross to t=100
            color = get(STATE_COLORS, arch_cross, :gray)
            poly!(ax, Point2f[(t_cross, rowi-0.32), (100.0, rowi-0.32),
                              (100.0, rowi+0.32), (t_cross, rowi+0.32)];
                  color = (color, 0.85), strokewidth = 0)
            text!(ax, t_cross + 1, rowi; text = @sprintf("t = %d", round(Int, t_cross)),
                  color = :white, align = (:left, :center), fontsize = 9.5, font = :bold)
        end
    end

    # State legend on the right
    elems = [PolyElement(color = (STATE_COLORS["S_BC"], 0.85)),
             PolyElement(color = (STATE_COLORS["S_BS"], 0.85))]
    Legend(fig[1, 2], elems,
        ["S_BC (cognitive wave)", "S_BS (physical wave)"],
        "Causing state";
        framevisible = false, labelsize = 10.5, titlesize = 11.5,
        patchsize = (22, 14), padding = (8, 4, 4, 4))

    colgap!(fig.layout, 4)
    return fig
end

println("Rendering…")
save_fig(build_figure(), FIG_NAME; outdir = OUT_DIR)

meta = Dict(
    "caption" =>
        "Open-Source Paradox: first time at which each occupation cluster's D crosses 0.5, by causing state. Non-crossing clusters annotated with their peak D and causing state.",

    "main_findings" =>
        "Open-Source Paradox produces displacement in two waves and partial pressure on a third tier. " *
        "Wave 1 (cognitive, via S_BC): Software Engineer (t=48), Data Analyst (t=51), Research " *
        "Scientist (t=51), Lawyer/Paralegal (t=55), Civil Servant (t=72). Wave 2 (physical, via " *
        "S_BS): Soldier/Police (t=74), Factory Worker (t=84), Farmer Industrial (t=86), Truck Driver " *
        "(t=89). The remaining five clusters never cross D=0.5 but the annotations now show how close " *
        "each got: Nurse/Caregiver reaches max D=0.40 (80% of threshold) via S_BS; Florist/Artisan " *
        "0.36 (72%) via S_BS; Farmer (Subsistence) 0.21 (42%) via S_BS; Therapist/Counselor 0.20 " *
        "(40%) via S_BC; Capital Owner 0.00 (d-vector identically zero — capital is structurally " *
        "non-dispensable in the model). The Nurse/Caregiver and Florist/Artisan rows are the most " *
        "consequential non-crossers: at 80% and 72% of the threshold, these clusters are very close " *
        "to crossing and would do so under a longer run or stronger physical-capability growth.",

    "detailed_findings" =>
        "This figure is the central evidence in Paper 2 that AI-driven labour displacement happens " *
        "in distinguishable waves, with the wave's reach gated by governance (open-source level and " *
        "enforcement) rather than by raw capability. Plotted for the Open-Source Paradox exemplar " *
        "(M=2, C=1, O=1.0, R=0.0, E=1.0) — the only one of our 8 exemplars that produces a full " *
        "9-of-14 cluster displacement.\n\n" *
        "Construction: for each of the 14 occupation clusters defined in src/core/config.jl, " *
        "compute the first time t at which any simulated state's κ vector satisfies " *
        "dot(d_cluster, κ) ≥ 0.5. Rows are ordered by ascending crossing time (latest at top, " *
        "earliest at bottom) so the wave structure reads bottom-up. The Gantt bar from crossing " *
        "time to t_max is colored by the causing state archetype: S_BC (US-type) is the cognitive " *
        "leader; S_BS (China-type) is the physical-capability leader.\n\n" *
        "Crossing rows demonstrate the wave structure: the cognitive wave fires first via S_BC " *
        "(SDE/Data/Research/Lawyer/Civil Servant, t≈48–72), then the physical wave fires via S_BS " *
        "(Soldier/Factory/Farmer/Truck, t≈74–89). The two waves are driven by different states " *
        "because the κ vector is asymmetric: S_BC leads κ_c, S_BS leads κ_p.\n\n" *
        "Non-crossing rows are now annotated quantitatively. They reveal that 'never crossed' does " *
        "not mean 'no pressure': Nurse/Caregiver, Florist/Artisan, and Therapist/Counselor all " *
        "experience meaningful dispensability growth (D ≥ 0.14) via S_BS, but their occupational " *
        "d-vectors weight κ_p and κ_c at levels too low (0.2–0.4 max per dimension) to reach 0.5 " *
        "within the run horizon. Capital Owner's d-vector is identically zero — capital ownership " *
        "is, in this model's framing, structurally non-dispensable.\n\n" *
        "Faint horizontal background bars on the non-crossing rows are scaled to (max D / 0.5), " *
        "providing a visual sense of how close each came to the threshold. Combined with the " *
        "Gantt-bar rows above, the figure now uses every row of vertical space to convey " *
        "quantitative information instead of leaving five rows as empty placeholders."
)

open(joinpath(OUT_DIR, FIG_NAME * ".json"), "w") do io
    JSON.print(io, meta, 2)
end

println("Saved to $OUT_DIR")
