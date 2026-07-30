using Documenter

# ── Constants ───────────────────────────────────────────────────────────────

const DOCS_SRC = joinpath(@__DIR__, "src")
const GITHUB_BASE = "https://github.com/ProfLeao/glenn-pluto-notebooks"

const EN_FILES = [
    "01_getting_started.jl", "02_nasa_polynomials.jl", "03_property_curves.jl",
    "04_formation_enthalpy.jl", "05_reaction_enthalpies.jl", "06_adiabatic_flame_temperature.jl",
    "07_biofuel_comparison.jl", "08_equilibrium_gibbs.jl", "09_brayton_cycle.jl",
    "10_property_provider.jl", "11_comparing_sources.jl",
]
const EN_TITLES = [
    "Getting Started", "NASA Polynomials Under the Hood", "Property Curves",
    "Enthalpy of Formation", "Reaction Enthalpies", "Adiabatic Flame Temperature",
    "Comparing Fuels & Biofuels", "Chemical Equilibrium & Gibbs Free Energy",
    "Brayton Gas-Turbine Cycle", "Property Provider for CFD", "Comparing Data Sources",
]
const EN_DESCRIPTIONS = [
    "Connecting, searching species, Cp/H/S, error handling",
    "Manual 9-term NASA polynomials, validation against API",
    "Cp(T), H(T), S(T) curves, equipartition, DataFrames",
    "ΔfH° from h_relative, literature validation",
    "ΔrH°, LHV/HHV, Kirchhoff, Hess",
    "Energy balance for Tad, equivalence ratio, preheating",
    "Ethanol, methanol, gasoline: energy density, CO₂",
    "ΔrG°, K, water-gas shift, van't Hoff",
    "Real Cp(T) Brayton cycle, efficiency vs pressure ratio",
    "Batch tables, cached provider, CFD benchmark",
    "NASA vs NIST-JANAF vs conventional tables",
]

const PT_FILES = [
    "01_primeiros_passos.jl", "02_polinomios_nasa.jl", "03_propriedades_curvas.jl",
    "04_entalpia_formacao.jl", "05_entalpias_reacao.jl", "06_temperatura_chama_adiabatica.jl",
    "07_comparacao_combustiveis.jl", "08_equilibrio_quimico.jl", "09_ciclo_brayton.jl",
    "10_propriedades_cfd.jl", "11_comparacao_fontes.jl",
]
const PT_TITLES = [
    "Primeiros Passos", "Polinômios da NASA", "Curvas de Propriedades",
    "Entalpia de Formação", "Entalpias de Reação", "Temperatura de Chama Adiabática",
    "Comparação de Combustíveis", "Equilíbrio Químico e Energia Livre de Gibbs",
    "Ciclo Brayton", "Propriedades para CFD", "Comparação de Fontes de Dados",
]

const ES_FILES = [
    "01_primeros_pasos.jl", "02_polinomios_nasa.jl", "03_curvas_propiedades.jl",
    "04_entalpia_formacion.jl", "05_entalpias_reaccion.jl", "06_temperatura_llama_adiabatica.jl",
    "07_comparacion_biocombustibles.jl", "08_equilibrio_gibbs.jl", "09_ciclo_brayton.jl",
    "10_proveedor_propiedades.jl", "11_comparacion_fuentes.jl",
]
const ES_TITLES = [
    "Primeros Pasos", "Polinomios de la NASA", "Curvas de Propiedades",
    "Entalpía de Formación", "Entalpías de Reacción", "Temperatura de Llama Adiabática",
    "Comparación de Biocombustibles", "Equilibrio Químico y Energía Libre de Gibbs",
    "Ciclo Brayton", "Proveedor de Propiedades para CFD", "Comparación de Fuentes de Datos",
]

# ── Generate language index pages ──────────────────────────────────────────

function generate_index(lang_dir, files, titles, descriptions, lang_label, heading, description)
    index_path = joinpath(DOCS_SRC, lang_dir, "index.md")
    mkpath(dirname(index_path))
    open(index_path, "w") do io
        write(io, "# Glenn.jl — $lang_label\n\n")
        write(io, "$description\n\n")
        write(io, "---\n\n")
        write(io, "## $heading\n\n")
        for (i, (file, title)) in enumerate(zip(files, titles))
            raw_url = "$GITHUB_BASE/blob/main/notebooks/$lang_dir/$file"
            desc = i <= length(descriptions) ? descriptions[i] : ""
            write(io, "### $(lpad(i, 2, "0")) — $title\n\n")
            write(io, "$desc\n\n")
            write(io, "[📂 View source]($raw_url){.btn}\n\n")
        end
        write(io, "---\n\n")
        write(io, "**Author:** Dr. Reginaldo G. Leão Jr. — GESESC / IFMG\n\n")
        write(io, "**Repository:** [$GITHUB_BASE]($GITHUB_BASE)\n")
    end
end

generate_index("en", EN_FILES, EN_TITLES, EN_DESCRIPTIONS,
    "Pluto Notebooks (English)", "Notebooks",
    "A collection of **11 interactive Pluto.jl notebooks** demonstrating the [Glenn.jl](https://github.com/ProfLeao/Glenn.jl) thermochemical properties calculator.")

generate_index("pt-br", PT_FILES, PT_TITLES, [],
    "Cadernos Pluto (Português)", "Cadernos",
    "Coleção de **11 cadernos interativos Pluto.jl** demonstrando a biblioteca [Glenn.jl](https://github.com/ProfLeao/Glenn.jl).")

generate_index("es", ES_FILES, ES_TITLES, [],
    "Cuadernos Pluto (Español)", "Cuadernos",
    "Colección de **11 cuadernos interactivos Pluto.jl** que demuestran la biblioteca [Glenn.jl](https://github.com/ProfLeao/Glenn.jl).")

# ── Build the documentation ────────────────────────────────────────────────

makedocs(
    sitename = "Glenn.jl — Pluto Notebooks",
    authors = "Dr. Reginaldo G. Leão Jr.",
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", "false") == "true",
        canonical = "https://profleao.github.io/glenn-pluto-notebooks/stable/",
        edit_link = "main",
        repolink = GITHUB_BASE,
        assets = ["assets/custom.css"],
    ),
    pages = [
        "Home" => "index.md",
        "English" => ["en/index.md"],
        "Português (Brasil)" => ["pt-br/index.md"],
        "Español" => ["es/index.md"],
    ],
    warnonly = [:missing_docs, :cross_references],
)

deploydocs(
    repo = "github.com/ProfLeao/glenn-pluto-notebooks.git",
    target = "build",
    branch = "gh-pages",
    devbranch = "main",
    push_preview = true,
)
