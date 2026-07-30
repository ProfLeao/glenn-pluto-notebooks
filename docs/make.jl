using Documenter

const DOCS_SRC = joinpath(@__DIR__, "src")
const BUILD_DIR = joinpath(@__DIR__, "build")
const GITHUB_BASE = "https://github.com/ProfLeao/glenn-pluto-notebooks"

# ══════════════════════════════════════════════════════════════════════════════
#  Language data
# ══════════════════════════════════════════════════════════════════════════════

const LANGS = Dict(
    "en" => Dict(
        "sitename" => "Glenn.jl — PlutoLab",
        "label"    => "English",
        "heading"  => "Notebooks",
        "desc"     => "A collection of **11 interactive Pluto.jl notebooks** demonstrating the [Glenn.jl](https://github.com/ProfLeao/Glenn.jl) thermochemical properties calculator.",
        "files" => [
            "01_getting_started.jl", "02_nasa_polynomials.jl", "03_property_curves.jl",
            "04_formation_enthalpy.jl", "05_reaction_enthalpies.jl", "06_adiabatic_flame_temperature.jl",
            "07_biofuel_comparison.jl", "08_equilibrium_gibbs.jl", "09_brayton_cycle.jl",
            "10_property_provider.jl", "11_comparing_sources.jl",
        ],
        "titles" => [
            "Getting Started", "NASA Polynomials Under the Hood", "Temperature-Dependent Property Curves",
            "Enthalpy of Formation", "Reaction Enthalpies & Heats of Combustion", "Adiabatic Flame Temperature",
            "Comparing Fuels & Biofuels", "Chemical Equilibrium & Gibbs Free Energy",
            "Brayton Gas-Turbine Cycle", "Property Provider for CFD & Chemical Kinetics",
            "Comparing Thermodynamic Data Sources",
        ],
        "descriptions" => [
            "Connecting, searching species, computing Cp/H/S, error handling",
            "Manual 9-term NASA polynomials, validation against API",
            "Cp(T), H(T), S(T) curves, equipartition, DataFrames tables",
            "ΔfH° from h_relative, literature validation",
            "ΔrH°, LHV/HHV, Kirchhoff, Hess",
            "Energy balance for Tad, equivalence ratio, preheating",
            "Ethanol, methanol, gasoline: energy density, CO₂ intensity",
            "ΔrG°, K, water-gas shift, van't Hoff, dissociation",
            "Real Cp(T) Brayton cycle, efficiency vs rp",
            "Batch tables, cached provider, CFD benchmark",
            "NASA vs NIST-JANAF vs conventional tables",
        ],
    ),
    "pt-br" => Dict(
        "sitename" => "Glenn.jl — PlutoLab",
        "label"    => "Português",
        "heading"  => "Cadernos",
        "desc"     => "Coleção de **11 cadernos interativos Pluto.jl** demonstrando a biblioteca [Glenn.jl](https://github.com/ProfLeao/Glenn.jl).",
        "files" => [
            "01_primeiros_passos.jl", "02_polinomios_nasa.jl", "03_propriedades_curvas.jl",
            "04_entalpia_formacao.jl", "05_entalpias_reacao.jl", "06_temperatura_chama_adiabatica.jl",
            "07_comparacao_combustiveis.jl", "08_equilibrio_quimico.jl", "09_ciclo_brayton.jl",
            "10_propriedades_cfd.jl", "11_comparacao_fontes.jl",
        ],
        "titles" => [
            "Primeiros Passos", "Polinômios da NASA", "Curvas de Propriedades",
            "Entalpia de Formação", "Entalpias de Reação", "Temperatura de Chama Adiabática",
            "Comparação de Combustíveis", "Equilíbrio Químico e Energia Livre de Gibbs",
            "Ciclo Brayton", "Propriedades para CFD", "Comparação de Fontes de Dados",
        ],
        "descriptions" => [],
    ),
    "es" => Dict(
        "sitename" => "Glenn.jl — PlutoLab",
        "label"    => "Español",
        "heading"  => "Cuadernos",
        "desc"     => "Colección de **11 cuadernos interactivos Pluto.jl** que demuestran la biblioteca [Glenn.jl](https://github.com/ProfLeao/Glenn.jl).",
        "files" => [
            "01_primeros_pasos.jl", "02_polinomios_nasa.jl", "03_curvas_propiedades.jl",
            "04_entalpia_formacion.jl", "05_entalpias_reaccion.jl", "06_temperatura_llama_adiabatica.jl",
            "07_comparacion_biocombustibles.jl", "08_equilibrio_gibbs.jl", "09_ciclo_brayton.jl",
            "10_proveedor_propiedades.jl", "11_comparacion_fuentes.jl",
        ],
        "titles" => [
            "Primeros Pasos", "Polinomios de la NASA", "Curvas de Propiedades",
            "Entalpía de Formación", "Entalpías de Reacción", "Temperatura de Llama Adiabática",
            "Comparación de Biocombustibles", "Equilibrio Químico y Energía Libre de Gibbs",
            "Ciclo Brayton", "Proveedor de Propiedades para CFD", "Comparación de Fuentes de Datos",
        ],
        "descriptions" => [],
    ),
)

# ══════════════════════════════════════════════════════════════════════════════
#  Language switcher widget
# ══════════════════════════════════════════════════════════════════════════════

function lang_switcher_html(current_lang)
    parts = String[]
    for (code, data) in LANGS
        flag = Dict("en" => "🇬🇧", "pt-br" => "🇧🇷", "es" => "🇪🇸")[code]
        path = code == "en" ? "" : "/$code"
        if code == current_lang
            push!(parts, "<span class=\"lang-active\">$flag $(data["label"])</span>")
        else
            push!(parts, "<a href=\"$path/\">$flag $(data["label"])</a>")
        end
    end
    return """<div class="lang-switcher">$(join(parts, " "))</div>"""
end

# ══════════════════════════════════════════════════════════════════════════════
#  Generate index page for a language
# ══════════════════════════════════════════════════════════════════════════════

function generate_lang_index(lang_code)
    data = LANGS[lang_code]
    index_path = joinpath(DOCS_SRC, "index.md")
    mkpath(dirname(index_path))

    # Build notebook list
    nb_items = String[]
    files = data["files"]
    titles = data["titles"]
    descs = data["descriptions"]

    for i in 1:length(files)
        raw_url = "https://raw.githubusercontent.com/ProfLeao/glenn-pluto-notebooks/main/rendered/$lang_code/$(replace(files[i], ".jl" => ".html"))"
        preview_url = "https://htmlpreview.github.io/?$raw_url"
        desc = i <= length(descs) && !isempty(descs) ? descs[i] : ""
        desc_html = isempty(desc) ? "" : "<p>$desc</p>"
        push!(nb_items, """
        <a href="$preview_url" class="nb-card">
            <h4><span class="num">$(lpad(i, 2, "0"))</span> $(titles[i])</h4>
            $desc_html
        </a>""")
    end

    switcher = lang_switcher_html(lang_code)

    open(index_path, "w") do io
        write(io, """# Glenn.jl — PlutoLab

```@raw html
$switcher
```

$(data["desc"])

from **NASA (Glenn) polynomial coefficients** stored in a bundled SQLite
database (~2030 species, 3772 temperature intervals).

---

## Quick Start

```bash
git clone https://github.com/ProfLeao/glenn-pluto-notebooks.git
cd glenn-pluto-notebooks
julia --project -e 'using Pluto; Pluto.run()'
```

---

## Installation

```julia
using Pkg
Pkg.add("Glenn")
Pkg.add("Pluto")
Pkg.add("Plots")
Pkg.add("DataFrames")
Pkg.add("Roots")
```

---

## About the Data

- `Glenn.jl`'s `h_relative` already includes the enthalpy of formation.
  Reference-state elements read \$H^\\circ(298.15\\,\\text{K}) \\approx 0\$,
  compounds read their \$\\Delta_f H^\\circ\$.

- Notebook 04 shows how to obtain \$\\Delta_f H^\\circ\$ from `h_relative`
  at 298.15 K.

---

## $(data["heading"])

```@raw html
<div class="nb-grid">
$(join(nb_items, "\n"))
</div>
```

---

## Reproducing

```bash
julia --project -e 'using Pluto; Pluto.run()'
```

Generate static HTML:

```bash
julia --project scripts/render.jl
```

---

## Author

**Dr. Reginaldo G. Leão Jr.** — GESESC / IFMG

- GitHub: [@ProfLeao](https://github.com/ProfLeao)
- Glenn.jl: [github.com/ProfLeao/Glenn.jl](https://github.com/ProfLeao/Glenn.jl)
""")
    end

## About the Data

- `Glenn.jl`'s `h_relative` already includes the enthalpy of formation.
  Reference-state elements read \$H^\\circ(298.15\\,\\text{K}) \\approx 0\$,
  compounds read their \$\\Delta_f H^\\circ\$.

- Notebook 04 shows how to obtain \$\\Delta_f H^\\circ\$ from `h_relative`
  at 298.15 K.

---

## $(data["heading"])

<div class="nb-grid">
$(join(nb_items, "\n"))
</div>

---

## Reproducing

```bash
julia --project -e 'using Pluto; Pluto.run()'
```

Generate static HTML:

```bash
julia --project scripts/render.jl
```

---

## Author

**Dr. Reginaldo G. Leão Jr.** — GESESC / IFMG

- GitHub: [@ProfLeao](https://github.com/ProfLeao)
- Glenn.jl: [github.com/ProfLeao/Glenn.jl](https://github.com/ProfLeao/Glenn.jl)
""")
    end
end

# ══════════════════════════════════════════════════════════════════════════════
#  Build each language
# ══════════════════════════════════════════════════════════════════════════════

const CANONICAL_BASE = "https://profleao.github.io/glenn-pluto-notebooks/stable"

# --- Build English (root) ---
println("=== Building English (root) ===")
generate_lang_index("en")
makedocs(
    sitename = LANGS["en"]["sitename"],
    authors = "Dr. Reginaldo G. Leão Jr.",
    build = joinpath(BUILD_DIR),
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", "false") == "true",
        canonical = "$CANONICAL_BASE/",
        edit_link = "main",
        repolink = GITHUB_BASE,
        assets = ["assets/custom.css"],
    ),
    pages = ["Home" => "index.md"],
    warnonly = [:missing_docs, :cross_references],
)

# --- Build Portuguese (pt-br/) ---
println("=== Building Portuguese (pt-br/) ===")
generate_lang_index("pt-br")
makedocs(
    sitename = LANGS["pt-br"]["sitename"],
    authors = "Dr. Reginaldo G. Leão Jr.",
    build = joinpath(BUILD_DIR, "pt-br"),
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", "false") == "true",
        canonical = "$CANONICAL_BASE/pt-br/",
        edit_link = "main",
        repolink = GITHUB_BASE,
        assets = ["assets/custom.css"],
    ),
    pages = ["Home" => "index.md"],
    warnonly = [:missing_docs, :cross_references],
)

# --- Build Spanish (es/) ---
println("=== Building Spanish (es/) ===")
generate_lang_index("es")
makedocs(
    sitename = LANGS["es"]["sitename"],
    authors = "Dr. Reginaldo G. Leão Jr.",
    build = joinpath(BUILD_DIR, "es"),
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", "false") == "true",
        canonical = "$CANONICAL_BASE/es/",
        edit_link = "main",
        repolink = GITHUB_BASE,
        assets = ["assets/custom.css"],
    ),
    pages = ["Home" => "index.md"],
    warnonly = [:missing_docs, :cross_references],
)

# ══════════════════════════════════════════════════════════════════════════════
#  Deploy
# ══════════════════════════════════════════════════════════════════════════════

println("=== Build complete ===")
println("  EN:     $(BUILD_DIR)/")
println("  PT-BR:  $(BUILD_DIR)/pt-br/")
println("  ES:     $(BUILD_DIR)/es/")

deploydocs(
    repo = "github.com/ProfLeao/glenn-pluto-notebooks.git",
    target = "build",
    branch = "gh-pages",
    devbranch = "main",
    push_preview = true,
)
