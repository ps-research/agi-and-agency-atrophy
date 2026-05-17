# Atrophy of Popular Agency on the Path to AGI

Figure-reproduction code for the paper *Atrophy of Popular Agency on the Path to
AGI*, which traces **how public agency atrophies** as AI capability grows: the
sequential displacement of occupation clusters, the alignment-driven coalition
fracture mechanism, and the conditions under which the loss is reversible.

This repository contains the scripts that generate every figure in the paper from
the published dataset on Zenodo. It does **not** contain the simulation model itself
— that will be released as a Julia package (`TheDispensabilityGame.jl`) at paper
acceptance.

## Data

This work uses the **AGI Game — Grand Parameter Sweep Dataset**, archived on Zenodo
with a persistent DOI:

- **Concept DOI** (always latest): [10.5281/zenodo.20259914](https://doi.org/10.5281/zenodo.20259914)
- **Version DOI** (v1.0.0): [10.5281/zenodo.20259915](https://doi.org/10.5281/zenodo.20259915)
- License: CC-BY-4.0

The dataset (1.57 GB compressed) holds 31,944 per-configuration simulation outputs
plus derived analytical tables. Running `make data` (or `make all`) downloads and
unpacks it automatically.

## Quick start

```bash
git clone https://github.com/ps-research/agi-and-agency-atrophy.git
cd agi-and-agency-atrophy
julia --project=. -e 'using Pkg; Pkg.instantiate()'
make all
```

That downloads the dataset (~2 min), unpacks it (~30 s), and generates all 7
figures into `figures/<name>/` (PDF + 600 DPI PNG + JSON metadata). Total time
on a 32-thread machine: ~3 minutes.

## Per-figure commands

`make <stem>` regenerates a single figure. The stem is the experiment filename
without the `.jl` extension:

| Make target | Figure | Description |
|---|---|---|
| `01_fig2_1_OS_paradox_gantt` | Fig 2.1 | OS Paradox 14-cluster Gantt: first-crossing time of D ≥ 0.5 per cluster, by causing state |
| `02_fig2_2_OS_paradox_D_heatmap` | Fig 2.2 | D(t) heatmap per occupation cluster (S_BC and S_BS panels) |
| `03_fig2_3_gantt_small_multiples` | Fig 2.3 | 8-panel Gantt grid + max-D row tints — cross-trajectory comparison |
| `04_fig2_4_alignment_leverage_fracture` | Fig 2.4 | Alignment vs leverage co-evolution — the fracture mechanism |
| `05_fig2_5_decline_mode_contrast` | Fig 2.5 | Decline-mode contrast: coalition windows in accelerating vs decelerating exemplars |
| `06_fig2_6_crisis_onset_map` | Fig 2.6 | Mean t_first_cluster_displaced over (O, E) per M |
| `07_fig2_7_cluster_vulnerability` | Fig 2.7 | Cluster-vulnerability heatmap (14 clusters × 4 M values) |

## Repository layout

```
.
├── README.md                 (this file)
├── LICENSE                   (MIT — code)
├── Project.toml              (Julia dependencies)
├── Makefile                  (master runner)
├── data/
│   ├── fetch.sh              (downloads + verifies Zenodo dataset)
│   └── sweep_results/        (populated by fetch.sh — gitignored)
├── lib/
│   └── figures_lib.jl        (shared palette, theme, CSV/TS loaders)
├── experiments/
│   └── 0X_*.jl               (one script per figure)
└── figures/                  (generated output — gitignored)
```

## Reproducibility

Continuous integration runs `make all` on every push and uploads the regenerated
figures as a build artifact, so the green ✓ on the latest commit is evidence that
the dataset → figures pipeline still works on a clean Ubuntu machine. See the
[Actions tab](https://github.com/ps-research/agi-and-agency-atrophy/actions).

The simulation code that produced the dataset is currently held in a private
repository pending paper acceptance. Once accepted, it will be released as the
`TheDispensabilityGame.jl` Julia package; this repository will be updated to
declare a dependency on the published package version.

## License

- **Code** (this repository, Project.toml, Makefile, fetch.sh, experiments, lib):
  MIT (see `LICENSE`).
- **Figures and data**: CC-BY-4.0, inherited from the Zenodo dataset license.
  Cite the dataset DOI when reusing.

---

Built with [Claude Code](https://claude.ai/code) v2.1.143 using Claude Opus 4.7 (Max effort, 1M context).
