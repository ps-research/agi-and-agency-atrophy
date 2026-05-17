#!/usr/bin/env julia
# scripts/updated/fig_2_4.jl — Paper 2, Fig 2.4 (revision)
# Updates:
#   - remove main figure title
#   - move the T_leverage label BELOW its blue threshold line so it no longer
#     clashes with the red alignment line that sits just 0.05 above
#   - bump legend / axis / footnote font sizes

using CairoMakie, Printf, Statistics, JSON
include(joinpath(@__DIR__, "..", "lib", "figures_lib.jl"))

const FIG_NAME = "fig2_4_alignment_leverage_fracture"
const OUT_DIR  = joinpath(FIGURES_ROOT, FIG_NAME)
mkpath(OUT_DIR)

println("Loading Bipolar Standoff time series…")
BS_TS = load_ts(2, 1, 0.5, 0.3, 0.5)

function build_figure()
    fig = Figure(size = (820, 460))
    ax = Axis(fig[1, 1];
        xlabel = "Timestep t",
        ylabel = "Value (0 – 1)",
        xticks = 0:20:100,
        yticks = 0:0.1:1.0,
        limits = ((0, 100), (0.0, 1.0)),
        xlabelsize = 12, ylabelsize = 12,
        xticklabelsize = 10, yticklabelsize = 10,
    )

    t_L, L = mean_series(BS_TS, "leverage")
    t_A, A = mean_series(BS_TS, "alignment")

    T_lev = 0.30
    T_ali = 0.35

    # Coalition-viable shaded intervals: where BOTH L > T_lev AND A > T_ali
    viable = [L[i] >= T_lev && A[i] >= T_ali for i in eachindex(t_L)]
    starts = Int[]; ends = Int[]
    in_run = false
    for i in eachindex(viable)
        if viable[i] && !in_run
            push!(starts, i); in_run = true
        elseif !viable[i] && in_run
            push!(ends, i-1); in_run = false
        end
    end
    in_run && push!(ends, length(viable))
    for (s, e) in zip(starts, ends)
        band!(ax, [t_L[s], t_L[e]], [0.0, 0.0], [1.0, 1.0];
              color = (:mediumseagreen, 0.13))
    end

    # Main lines
    lines!(ax, t_L, L; color = "#2166ac", linewidth = 2.4, label = "Mean leverage L̄(t)")
    lines!(ax, t_A, A; color = "#d53e4f", linewidth = 2.4, linestyle = :dash,
           label = "Mean alignment A(t)")

    # Threshold lines
    hlines!(ax, [T_lev]; color = (:steelblue, 0.75), linestyle = :dot, linewidth = 1.1)
    hlines!(ax, [T_ali]; color = (:firebrick, 0.75), linestyle = :dot, linewidth = 1.1)

    # T_alignment label: ABOVE its red dotted line (existing behaviour, fine).
    text!(ax, 99, T_ali + 0.012; text = "T_alignment = $(T_ali)",
        color = (:firebrick, 0.95), align = (:right, :bottom), fontsize = 10)
    # T_leverage label: BELOW its blue dotted line so it doesn't crowd the
    # alignment line/label above it.
    text!(ax, 99, T_lev - 0.012; text = "T_leverage = $(T_lev)",
        color = (:steelblue, 0.95), align = (:right, :top), fontsize = 10)

    # Mark fracture point: first time alignment dips below T_alignment.
    frac_idx = findfirst(A .< T_ali)
    if !isnothing(frac_idx)
        t_frac = t_A[frac_idx]
        scatter!(ax, [t_frac], [A[frac_idx]];
            color = "#d53e4f", strokecolor = :black, strokewidth = 1.2,
            markersize = 12, marker = :diamond)
        text!(ax, t_frac + 1.5, A[frac_idx] - 0.02;
            text = "fracture (t = $(round(Int, t_frac)))",
            color = :firebrick, fontsize = 10, align = (:left, :top), font = :italic)
    end

    # Bottom strip: footnote on the left, legend on the right (both below the axis).
    bottom = fig[2, 1] = GridLayout()
    Label(bottom[1, 1],
        "Green band: interval where BOTH thresholds are satisfied (coalition formally viable).\n" *
        "Fracture occurs when either curve crosses below its threshold while the other is still adequate.";
        fontsize = 10, color = :black, halign = :left, tellwidth = false)
    Legend(bottom[1, 2], ax;
        orientation = :horizontal, halign = :right,
        framevisible = false, labelsize = 10.5,
        patchsize = (26, 14), padding = (4, 4, 4, 4),
        tellwidth = false)
    colsize!(bottom, 1, Relative(0.62))
    colsize!(bottom, 2, Relative(0.38))

    rowsize!(fig.layout, 2, Auto(0.22))
    rowgap!(fig.layout, 4)
    return fig
end

println("Rendering…")
save_fig(build_figure(), FIG_NAME; outdir = OUT_DIR)

meta = Dict(
    "caption" =>
        "Coalition viability for the Bipolar Standoff exemplar: mean leverage L̄(t) and alignment A(t) over time, with threshold lines and the coalition-viable window shaded green.",

    "main_findings" =>
        "For the Bipolar Standoff exemplar (M=2, C=1, O=0.5, R=0.3, E=0.5), the leverage curve L̄(t) " *
        "starts at 0.81 and declines smoothly to 0.48 by t=100, staying above the T_leverage = 0.30 " *
        "threshold throughout. The alignment curve A(t) starts at 0.43 — already only marginally " *
        "above the T_alignment = 0.35 threshold — and decays gradually as κ asymmetry grows. The " *
        "green shaded band marks the interval where BOTH thresholds are satisfied (coalition is " *
        "formally viable per the collective-action mechanics). For this exemplar, the coalition " *
        "window closes around t ≈ 52 as alignment crosses below 0.35, even though leverage remains " *
        "comfortably above its threshold. After that, leverage continues to be sufficient but " *
        "coalition formation is impossible due to misaligned interests across occupation strata. " *
        "This is the canonical 'sequential displacement fracture' pattern Paper 2 names: the public " *
        "has enough collective bargaining power but lacks the unity of interest needed to organize. " *
        "The fracture is not driven by capability shortage — it is driven by the differential " *
        "dispensability of cognitive vs. physical labor causing their interests to diverge.",

    "detailed_findings" =>
        "This figure shows the central coalition-fracture mechanism in Paper 2: alignment-driven " *
        "failure of collective action despite adequate leverage. Plotted for the Bipolar Standoff " *
        "exemplar (M=2, C=1, O=0.5, R=0.3, E=0.5), chosen because its parameters make the fracture " *
        "point visible mid-run rather than at the start or end.\n\n" *
        "The two lines show mean values aggregated across the simulated states (S_BC and S_BS):\n" *
        "  • L̄(t) (blue solid): aggregate public leverage, computed in src/dynamics/collective_" *
        "action.jl as the population-weighted sum of (1 − D_i) across all clusters. Starts at " *
        "0.81; declines smoothly to 0.48 by t=100; stays above T_leverage = 0.30 throughout.\n" *
        "  • A(t) (red dashed): aggregate alignment, computed as population-weighted pairwise " *
        "cosine similarity of d-vectors weighted by current dispensability gap. Starts at 0.43; " *
        "decays gradually to ≈0.30 by t=100.\n\n" *
        "Two horizontal threshold lines mark the coalition-viability conditions:\n" *
        "  • T_leverage = 0.30 (steel-blue dotted): below this, the public has insufficient " *
        "collective bargaining power. Label placed BELOW the line to avoid crowding the " *
        "alignment label above.\n" *
        "  • T_alignment = 0.35 (firebrick dotted): below this, the public has insufficient unity " *
        "of interest.\n\n" *
        "The green shaded interval marks where BOTH thresholds are satisfied. Coalition is " *
        "formally viable only in this window (≈t = 0 to t ≈ 52). After t ≈ 52, A(t) crosses below " *
        "0.35 even though L̄(t) is still ≈ 0.65 — the fracture happens because differential " *
        "dispensability of cognitive vs. physical labor causes their interests to diverge, not " *
        "because the public lacks leverage. The fracture point is marked with a red diamond.\n\n" *
        "As κ evolves, cognitive clusters experience high D first (Software Engineer crosses " *
        "D=0.5 around t=48; see Fig 2.1). Their interests now align with capital owners against " *
        "the model evolution, while physical clusters are still relatively safe and don't see the " *
        "threat. The cluster-by-cluster D divergence shows up as falling alignment.\n\n" *
        "For Paper 2, this is the figure that names the mechanism: coalition failure is driven by " *
        "alignment, not leverage. It is a structural feature of how AI capability disperses across " *
        "occupational tiers — not a contingent failure of will or organization."
)

open(joinpath(OUT_DIR, FIG_NAME * ".json"), "w") do io
    JSON.print(io, meta, 2)
end

println("Saved to $OUT_DIR")
