# Glenn.jl — Pluto Notebooks

```@raw html
<style>
.install-block { background: #f8f9fa; border: 1px solid #dee2e6; border-radius: 6px; padding: 1em; margin: 1em 0; }
.install-block pre { margin: 0; }
.nb-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(320px, 1fr)); gap: 0.8em; margin: 1.5em 0; }
.nb-card { border: 1px solid #dee2e6; border-radius: 8px; padding: 1em; transition: box-shadow 0.2s; }
.nb-card:hover { box-shadow: 0 2px 8px rgba(0,0,0,0.1); }
.nb-card h4 { margin: 0 0 0.3em 0; }
.nb-card .num { color: #6c757d; font-size: 0.85em; }
.nb-card p { margin: 0.2em 0; font-size: 0.9em; color: #495057; }
</style>
```

A collection of **11 interactive Pluto.jl notebooks** demonstrating the
[**Glenn.jl**](https://github.com/ProfLeao/Glenn.jl) thermochemical
properties calculator for Julia. `Glenn.jl` reconstructs the standard-state
molar properties

$$C_p^\circ(T), \qquad H^\circ(T), \qquad S^\circ(T)$$

from **NASA (Glenn) polynomial coefficients** stored in a bundled SQLite
database (~2030 species, 3772 temperature intervals).

The topics follow the applications outlined in the package's `ideias.md`
(Dr. Reginaldo G. Leão Jr., GESESC / IFMG): combustion, biofuels,
thermodynamic cycles, chemical equilibrium, and property provision for CFD
and chemical kinetics.

---

## Quick Start

Open any notebook directly in Pluto:

```bash
# Clone the repository
git clone https://github.com/ProfLeao/glenn-pluto-notebooks.git
cd glenn-pluto-notebooks

# Start Pluto
julia --project -e 'using Pluto; Pluto.run()'
```

Then browse to a notebook from `notebooks/en/`, `notebooks/pt-br/`, or
`notebooks/es/`.

---

## Installation

<div class="install-block">

**Install Glenn.jl and companion packages:**

```julia
using Pkg
Pkg.add("Glenn")
Pkg.add("Pluto")
Pkg.add("Plots")
Pkg.add("DataFrames")
Pkg.add("Roots")
```

</div>

Or instantiate from the repository's `Project.toml`:

```bash
julia --project -e 'import Pkg; Pkg.instantiate()'
```

---

## About the Data

- `Glenn.jl`'s `h_relative` (`calculate_properties(...).h_relative`) is the
  standardized molar enthalpy on the NASA scale — it already includes the
  enthalpy of formation. Consequently reference-state elements read
  $H^\circ(298.15\,\text{K}) \approx 0$, compounds read their
  $\Delta_f H^\circ$, and reaction enthalpies are simple stoichiometric sums.

- In the bundled database the dedicated `heat_of_formation_298K` column may
  not be populated, so `calculate_formation_enthalpy()` may return `nothing`.
  Notebook 04 shows how to obtain $\Delta_f H^\circ$ from `h_relative` at
  298.15 K instead.

---

## The Notebooks

### English

<div class="nb-grid">

<div class="nb-card">
<h4><span class="num">01</span> Getting Started</h4>
<p>Connecting, searching species, computing Cp/H/S, error handling</p>
</div>

<div class="nb-card">
<h4><span class="num">02</span> NASA Polynomials Under the Hood</h4>
<p>Manual implementation of 9-term polynomials, API validation</p>
</div>

<div class="nb-card">
<h4><span class="num">03</span> Temperature-Dependent Property Curves</h4>
<p>Cp(T), H(T), S(T) curves, equipartition, DataFrames tables</p>
</div>

<div class="nb-card">
<h4><span class="num">04</span> Enthalpy of Formation</h4>
<p>ΔfH° via h_relative, validation against literature</p>
</div>

<div class="nb-card">
<h4><span class="num">05</span> Reaction Enthalpies</h4>
<p>ΔrH°, LHV/HHV, Kirchhoff's Law, Hess's Law</p>
</div>

<div class="nb-card">
<h4><span class="num">06</span> Adiabatic Flame Temperature</h4>
<p>Energy balance for Tad, equivalence ratio, preheating</p>
</div>

<div class="nb-card">
<h4><span class="num">07</span> Comparing Fuels & Biofuels</h4>
<p>Ethanol, methanol, gasoline: energy density, CO₂ intensity</p>
</div>

<div class="nb-card">
<h4><span class="num">08</span> Chemical Equilibrium & Gibbs Free Energy</h4>
<p>ΔrG°, K, water-gas shift, van't Hoff, dissociation</p>
</div>

<div class="nb-card">
<h4><span class="num">09</span> Brayton Gas-Turbine Cycle</h4>
<p>Air-standard Brayton with real Cp(T), efficiency vs rp</p>
</div>

<div class="nb-card">
<h4><span class="num">10</span> Property Provider for CFD</h4>
<p>Batch tables, cached coefficient provider, benchmark</p>
</div>

<div class="nb-card">
<h4><span class="num">11</span> Comparing Thermodynamic Data Sources</h4>
<p>NASA polynomials vs NIST vs conventional tables</p>
</div>

</div>

> 🇧🇷 [Português (Brasil)](pt-br/index.md) &nbsp;|&nbsp; 🇪🇸 [Español](es/index.md)

---

## Pre-Rendered Outputs

Pre-executed static HTML versions with visible outputs are available in the
[`rendered/`](https://github.com/ProfLeao/glenn-pluto-notebooks/tree/main/rendered)
directory for quick browsing without opening Pluto.

---

## Reproducing

Open a notebook interactively:

```bash
julia --project -e 'using Pluto; Pluto.run()'
```

Generate static HTML:

```bash
julia --project scripts/render.jl
```

---

## Citing

If you use this repository in your research or teaching, please cite it via
Zenodo:

> Gonçalves Leão Junior, R. (2026). *glenn-pluto-notebooks*. Zenodo.

---

## Author

**Dr. Reginaldo G. Leão Jr.** — GESESC / IFMG

- GitHub: [@ProfLeao](https://github.com/ProfLeao)
- Glenn.jl: [github.com/ProfLeao/Glenn.jl](https://github.com/ProfLeao/Glenn.jl)
