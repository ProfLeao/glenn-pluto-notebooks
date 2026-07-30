# Glenn.jl — PlutoLab

[![CI](https://github.com/ProfLeao/glenn-pluto-notebooks/actions/workflows/ci.yml/badge.svg)](https://github.com/ProfLeao/glenn-pluto-notebooks/actions/workflows/ci.yml)
[![Docs](https://img.shields.io/badge/docs-stable-blue.svg)](https://profleao.github.io/glenn-pluto-notebooks/stable/)

📖 **Documentation:** [profleao.github.io/glenn-pluto-notebooks](https://profleao.github.io/glenn-pluto-notebooks/)

A collection of **11 interactive Pluto.jl notebooks** demonstrating the
capabilities of the [**Glenn.jl**](https://github.com/ProfLeao/Glenn.jl)
library — a thermochemical properties calculator for Julia that reconstructs

$$C_p^\circ(T), \qquad H^\circ(T), \qquad S^\circ(T)$$

from **NASA (Glenn) polynomial coefficients** stored in a bundled SQLite
database (~2030 species, 3772 temperature intervals).

The topics follow the applications outlined in the package's `ideias.md`
(Dr. Reginaldo G. Leão Jr., GESESC / IFMG): combustion, biofuels,
thermodynamic cycles, chemical equilibrium, and property provision for CFD
and chemical kinetics.

---

## 🚀 Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/ProfLeao/glenn-pluto-notebooks.git
cd glenn-pluto-notebooks

# 2. Start Pluto
julia --project -e 'using Pluto; Pluto.run()'

# 3. In the browser, open a notebook from notebooks/pt-br/, notebooks/en/ or notebooks/es/
```

---

## 📦 Requirements

```bash
# Via Julia REPL
using Pkg
Pkg.add("Glenn")
Pkg.add("Pluto")
Pkg.add("Plots")
Pkg.add("DataFrames")
Pkg.add("Roots")
```

Or install from `Project.toml`:

```bash
julia --project -e 'import Pkg; Pkg.instantiate()'
```

---

## 📓 The Notebooks

### 🌐 Available in Portuguese (Brazil), English, and Spanish

| # | Português | English | Español | Content |
|---|-----------|---------|---------|---------|
| 01 | Primeiros Passos | Getting Started | Primeros Pasos | Connecting to the database, searching species, $C_p$, $H^\circ$, $S^\circ$, error handling |
| 02 | Polinômios da NASA | NASA Polynomials Under the Hood | Polinomios de la NASA | Manual implementation of 9-term polynomials, API validation |
| 03 | Curvas de Propriedades | Temperature-Dependent Property Curves | Curvas de Propiedades | $C_p(T)$, $H(T)$, $S(T)$ curves, DataFrames tables |
| 04 | Entalpia de Formação | Enthalpy of Formation | Entalpía de Formación | $\Delta_f H^\circ$ via `h_relative`, literature validation |
| 05 | Entalpias de Reação | Reaction Enthalpies | Entalpías de Reacción | $\Delta_r H^\circ$, LHV/HHV, Kirchhoff's Law, Hess's Law |
| 06 | Temperatura de Chama Adiabática | Adiabatic Flame Temperature | Temperatura de Llama Adiabática | Energy balance for $T_{ad}$, equivalence ratio |
| 07 | Comparação de Combustíveis | Comparing Fuels & Biofuels | Comparación de Biocombustibles | Ethanol, methanol, gasoline: energy density, CO₂ |
| 08 | Equilíbrio Químico | Chemical Equilibrium & Gibbs Free Energy | Equilibrio Químico y Energía Libre de Gibbs | $\Delta_r G^\circ$, $K$, water-gas shift, van't Hoff |
| 09 | Ciclo Brayton | Brayton Gas-Turbine Cycle | Ciclo Brayton | Brayton cycle with real $C_p(T)$, efficiency vs $r_p$ |
| 10 | Propriedades para CFD | Property Provider for CFD | Proveedor de Propiedades para CFD | Batch tables, *cached provider*, benchmark |
| 11 | Comparação de Fontes | Comparing Thermodynamic Data Sources | Comparación de Fuentes de Datos | NASA vs NIST-JANAF vs conventional tables |

---

## 🧪 Reproducibility

Pluto notebooks are interactive by nature. To run them:

```bash
# Start the Pluto server
julia --project -e 'using Pluto; Pluto.run()'
```

In the browser (http://localhost:1234), open the desired `.jl` file from the
`notebooks/pt-br/`, `notebooks/en/`, or `notebooks/es/` folder.

For batch (headless) execution:

```bash
julia --project -e '
    using Pluto
    Pluto.activate_notebook_environment("notebooks/en/01_getting_started.jl")
    html = Pluto.generate_html(Pluto.load_notebook("notebooks/en/01_getting_started.jl"))
'
```

---

## � Pre-Rendered Outputs

For quick browsing **without opening Pluto**, pre-rendered static HTML versions
with visible outputs are available in the [`rendered/`](rendered/) directory.

Regenerate after editing notebooks:

```bash
julia --project scripts/render.jl
```

---

## �📖 Documentation

Full documentation generated with **Documenter.jl** + **Literate.jl** available at:
[profleao.github.io/glenn-pluto-notebooks](https://profleao.github.io/glenn-pluto-notebooks/stable/)

---

##  Repository Structure

```
glenn-pluto-notebooks/
├── notebooks/
│   ├── pt-br/                    # Portuguese version (11 topics)
│   ├── en/                        # English version (11 topics)
│   └── es/                        # Spanish version (11 topics)
├── rendered/                      # Pre-rendered static HTML with visible outputs
│   ├── pt-br/
│   ├── en/
│   └── es/
├── scripts/
│   └── render.jl                  # Pluto → HTML render script
├── data/                          # Auxiliary data
├── images/                        # README figures
├── docs/
│   ├── make.jl                    # Documentation build (Documenter + Literate)
│   ├── Project.toml               # Documentation dependencies
│   └── src/
│       ├── index.md               # Landing page
│       ├── pt-br/                 # Portuguese docs
│       ├── en/                    # English docs
│       └── es/                    # Spanish docs
├── .github/workflows/ci.yml       # CI: test notebooks + build docs
├── Project.toml                   # Pluto + Glenn.jl environment
├── .gitignore
├── LICENSE
└── README.md
```

---

## 👤 Author

**Dr. Reginaldo G. Leão Jr.** — GESESC / IFMG

- GitHub: [@ProfLeao](https://github.com/ProfLeao)
- Glenn.jl package: [github.com/ProfLeao/Glenn.jl](https://github.com/ProfLeao/Glenn.jl)

---

## 📜 License

MIT — see [LICENSE](LICENSE)
