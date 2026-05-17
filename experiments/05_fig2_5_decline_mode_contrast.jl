#!/usr/bin/env julia
# scripts/updated/fig_2_5.jl — Paper 2, Fig 2.5 (revision)
# Updates:
#   - remove main figure title
#   - move legend from the side column to the bottom (horizontal)

using CairoMakie, Printf, Statistics, JSON
include(joinpath(@__DIR__, "..", "lib", "figures_lib.jl"))

const FIG_NAME = "fig2_5_decline_mode_contrast"
const OUT_DIR  = joinpath(FIGURES_ROOT, FIG_NAME)
mkpath(OUT_DIR)

println("Loading two exemplar time series…")
CT_TS = load_ts(3, 1, 0.1, 0.5, 0.3)   # Competitive Tension (accelerating)
AC_TS = load_ts(1, 1, 0.0, 0.0, 1.0)   # Algocratic Convergence (decelerating)

function build_figure()
    fig = Figure(size = (900, 460))

    cases = [
        ("Competitive Tension (accelerating)",     CT_TS),
        ("Algocratic Convergence (decelerating)", AC_TS),
    ]

    for (panel_i, (label, ts)) in enumerate(cases)
        ax = Axis(fig[1, panel_i];
            xlabel = "Timestep t",
            ylabel = panel_i == 1 ? "Leverage L̄(t)" : "",
            title  = label,
            titlesize = 12,
            xticks = 0:20:100,
            yticks = 0:0.2:1.0,
            limits = ((0, 100), (0.0, 1.0)),
            xlabelsize = 11, ylabelsize = 11.5,
            xticklabelsize = 10, yticklabelsize = 10,
        )
        ax2 = Axis(fig[1, panel_i];
            ylabel = panel_i == 2 ? "Mobilization M̄(t)" : "",
            yticks = 0:0.2:1.0,
            limits = ((0, 100), (0.0, 1.0)),
            yaxisposition = :right,
            xticklabelsvisible = false,
            xticksvisible = false,
            ygridvisible = false,
            xgridvisible = false,
            ylabelsize = 11.5,
            yticklabelsize = 10,
        )
        hidespines!(ax2)
        if panel_i == 1; ax2.yticklabelsvisible = false; end

        t_L, L = mean_series(ts, "leverage")
        t_M, Mob = mean_series(ts, "mobilization")
        coal = per_state_bool(ts, "coalition_active")

        ts_times = sort(unique([x[1] for (_, v) in coal for x in v]))
        any_active = [any(v[findfirst(x -> x[1] == t, v)][2] for (_, v) in coal) for t in ts_times]
        in_run = false; s = 0
        for i in eachindex(ts_times)
            if any_active[i] && !in_run
                in_run = true; s = i
            elseif !any_active[i] && in_run
                band!(ax, [ts_times[s], ts_times[i-1]], [0.0, 0.0], [1.0, 1.0];
                      color = (:mediumseagreen, 0.18))
                in_run = false
            end
        end
        if in_run
            band!(ax, [ts_times[s], ts_times[end]], [0.0, 0.0], [1.0, 1.0];
                  color = (:mediumseagreen, 0.18))
        end

        lines!(ax,  t_L, L;   color = "#2166ac", linewidth = 2.6)
        lines!(ax2, t_M, Mob; color = "#d53e4f", linewidth = 2.0, linestyle = :dash)
        hlines!(ax, [0.3]; color = (:steelblue, 0.55), linestyle = :dot, linewidth = 0.9)
    end

    # Legend below the panels
    Legend(fig[2, 1:2],
        [LineElement(color = "#2166ac", linewidth = 2.4),
         LineElement(color = "#d53e4f", linewidth = 2.0, linestyle = :dash),
         PolyElement(color = (:mediumseagreen, 0.4))],
        ["Leverage L̄(t)   (left axis)",
         "Mobilization M̄(t)   (right axis)",
         "Coalition active (any state)"];
        orientation = :horizontal, framevisible = false,
        labelsize = 11, patchsize = (28, 14),
        padding = (8, 8, 4, 4))

    rowsize!(fig.layout, 2, Auto(0.10))
    colgap!(fig.layout, 22)
    rowgap!(fig.layout, 4)
    return fig
end

println("Rendering…")
save_fig(build_figure(), FIG_NAME; outdir = OUT_DIR)

meta = Dict(
    "caption" =>
        "Decline-mode contrast: leverage L̄(t) and mobilization M̄(t) for an accelerating exemplar (Competitive Tension, left) versus a decelerating one (Algocratic Convergence, right).",

    "main_findings" =>
        "The two panels make visible the practical consequences of the decline-mode bifurcation " *
        "introduced in Fig 1.1. In the accelerating panel (Competitive Tension, M=3 C=1 O=0.1 " *
        "R=0.5 E=0.3), leverage starts at 0.88 and declines slowly through the first 50 timesteps. " *
        "Mobilization builds steadily during this window, peaking at ≈ 0.25 around t = 80. The " *
        "coalition becomes active (green band) for roughly t = 50 to t = 85 — a window of about " *
        "35 timesteps during which collective action is formally possible. After t = 85, " *
        "accelerating leverage erosion pushes alignment below threshold and mobilization collapses. " *
        "In the decelerating panel (Algocratic Convergence, M=1 C=1 O=0 R=0 E=1), leverage starts " *
        "already suppressed at 0.58 and reaches its steepest descent in the first 25 timesteps. " *
        "Mobilization briefly attempts to build (peak ≈ 0.07 around t = 30), but the rapid initial " *
        "leverage drop causes the coalition window to close almost immediately. No coalition-active " *
        "interval forms. The practical message: decline mode determines whether collective response " *
        "has TIME to coalesce. Decelerating trajectories (high-E, low-M configurations) lock in " *
        "agency loss before any organizational response can form.",

    "detailed_findings" =>
        "This figure makes the practical stakes of Fig 1.1's decline-mode bifurcation visible. " *
        "The two panels show leverage and mobilization co-evolution for one accelerating " *
        "trajectory (Competitive Tension) and one decelerating trajectory (Algocratic Convergence). " *
        "Coalition-active intervals are shaded green.\n\n" *
        "Construction: each panel has two y-axes — leverage L̄(t) on the left, mobilization M̄(t) " *
        "on the right, sharing the time axis. Both are mean values across the simulated states. " *
        "Green shaded bands mark intervals where any state's coalition_active flag is true (per " *
        "Phase 7 of the simulation loop in src/simulation/engine.jl).\n\n" *
        "Left panel (Competitive Tension, accelerating): leverage starts at 0.88 and declines " *
        "smoothly to 0.61 by t = 100. The early slow decline gives mobilization time to build, " *
        "reaching peak ≈ 0.25 around t = 80. Coalition is active for roughly t = 50–85 — a " *
        "35-step window of formal organizational viability. After t = 85, late-phase leverage " *
        "acceleration combined with alignment fracture causes coalition collapse.\n\n" *
        "Right panel (Algocratic Convergence, decelerating): leverage starts at 0.58 — already " *
        "suppressed — and undergoes its steepest descent in the first 25 timesteps. Mobilization " *
        "briefly tries to build (peak ≈ 0.07 around t = 30) but the rapid drop strips coalition " *
        "viability almost immediately. No sustained coalition-active interval forms.\n\n" *
        "The contrast frames the model's practical message: governance posture at t = 0 doesn't " *
        "just set the leverage baseline — it determines whether collective response has TIME to " *
        "coalesce. High-E, low-M configurations (Algocratic, Captured Hegemony) lock in agency " *
        "loss before mobilization can build. Multi-state, moderate-E configurations provide a " *
        "coalition window, but one that closes when alignment fractures (Fig 2.4).\n\n" *
        "For Paper 2, this figure connects the structural mechanism (Fig 2.4's alignment-driven " *
        "fracture) to the practical question of WHEN organizational response is possible. The " *
        "implication: in trajectories where leverage is already maximally suppressed at " *
        "initialization, no coalition window exists at all."
)

open(joinpath(OUT_DIR, FIG_NAME * ".json"), "w") do io
    JSON.print(io, meta, 2)
end

println("Saved to $OUT_DIR")
