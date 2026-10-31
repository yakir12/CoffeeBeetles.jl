# CoffeeBeetles
A [Julia](https://julialang.org/) package for generating all the tables and figures from the manuscript.

[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://yakir12.github.io/CoffeeBeetles.jl/dev)
[![Build Status](https://travis-ci.com/yakir12/CoffeeBeetles.jl.svg?branch=master)](https://travis-ci.com/yakir12/CoffeeBeetles.jl)
[![Build Status](https://ci.appveyor.com/api/projects/status/github/yakir12/CoffeeBeetles.jl?svg=true)](https://ci.appveyor.com/project/yakir12/CoffeeBeetles.jl)
[![Codecov](https://codecov.io/gh/yakir12/CoffeeBeetles.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/yakir12/CoffeeBeetles.jl)

## How to reproduce the results

This reproduces every table and figure of the manuscript. The data ships inside this
repository (`data`), so nothing else needs downloading. The steps below pin **every**
package to the exact version that produced the published results, via the repository's
`Manifest.toml`.

It takes about 15 minutes from scratch, mostly precompiling; `main()` itself takes about 3 minutes.

### What you need

| Thing | Version |
|---|---|
| Julia | **1.4.2** exactly (newer versions will not work) |
| git | any |
| DungBase.jl | 1.0.3, commit `ba74847`, fetched automatically |
| everything else | pinned in `Manifest.toml`, installed automatically |

Key pinned versions, for reference: AbstractPlotting 0.10.11, CairoMakie 0.2.6,
MakieLayout 0.9.8, GeometryBasics 0.2.7, DataFrames 0.21.0, StaticArrays 0.12.3,
StatsBase 0.33.0, Distributions 0.23.2, GLM 1.3.9, HypothesisTests 0.10.0.

### 1. Install Julia 1.4.2 (via juliaup)

juliaup lets several Julia versions live side by side, so this won't disturb any Julia
you already have.

- **Linux / macOS:** `curl -fsSL https://install.julialang.org | sh`, then open a new terminal.
- **Windows:** `winget install julia -s msstore`

Then:

```
juliaup add 1.4.2
```

On an Apple-silicon Mac, if that fails, use `juliaup add 1.4.2~x64` and write
`+1.4.2~x64` instead of `+1.4.2` below. It runs under Rosetta.

### 2. Get the code

```
git clone https://github.com/yakir12/CoffeeBeetles.jl
cd CoffeeBeetles.jl
```

### 3. Use a separate package folder (important)

Julia 1.4 can't read the package registry that modern Julia keeps in `~/.julia`. Give it
its own folder. Run this in the same terminal you'll use for steps 4–5:

- **Linux / macOS:** `export JULIA_DEPOT_PATH="$PWD/../coffeebeetles-depot"`
- **Windows (PowerShell):** `$env:JULIA_DEPOT_PATH = "$PWD\..\coffeebeetles-depot"`

### 4. Install the exact packages (once)

```
julia +1.4.2 --project=. -e 'using Pkg; Pkg.Registry.add("General"); Pkg.instantiate()'
```

On Windows PowerShell, use the same line with the inner quotes swapped:
`julia +1.4.2 --project=. -e "using Pkg; Pkg.Registry.add(\"General\"); Pkg.instantiate()"`

Pkg should report `Installed …` lines only. If it also prints
`Updating Manifest.toml` followed by a long list of `+` entries, the pinned versions were
**not** used; see Troubleshooting.

### 5. Run it

Make an output folder and run from inside it. The results are written to the
current directory.

```
mkdir results
cd results
julia +1.4.2 --project=.. -e 'using CoffeeBeetles; main()'
```

The first run spends a few minutes precompiling and caching fonts. Deprecation warnings
about `sort(d::Dict)` are harmless.

**Result:** `table1.txt`, `table2.csv`, `figure4.pdf`, `figure5.pdf`, `figure6.pdf`, `figure7.pdf`.

To run again later, repeat step 3 (the `JULIA_DEPOT_PATH` line) and step 5.

## Troubleshooting

- **`UndefVarError: Histogram`, or a `convert_arguments` MethodError in `figure4`:** the
  pinned versions weren't used. You probably used `Pkg.add(url=…)` (which ignores
  `Manifest.toml`), or `Manifest.toml` is missing from your clone. Start again from step 2,
  in a new empty folder.
- **`curl: (22) … 404` for `coffeebeetle.s3.eu-central-1.amazonaws.com`:** your copy of the
  code is older than this README and still tries the old download location. Clone again.
- **Errors reading the registry, or `git@github.com` / SSH errors:** `JULIA_DEPOT_PATH`
  wasn't set in that terminal (step 3).
- **`git status` shows `Artifacts.toml`:** that's expected. The package writes it the first
  time it loads.

## Citing

See `CITATION.bib` for the relevant reference(s).
