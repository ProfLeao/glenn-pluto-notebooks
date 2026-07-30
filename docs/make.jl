using Documenter

# ── Generate index pages (Literate.jl does NOT support Pluto .jl format) ──

const GITHUB_RAW = "https://github.com/ProfLeao/glenn-pluto-notebooks/blob/main/notebooks"

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

const EN_FILES = [
    "01_getting_started.jl", "02_nasa_polynomials.jl", "03_property_curves.jl",
    "04_formation_enthalpy.jl", "05_reaction_enthalpies.jl", "06_adiabatic_flame_temperature.jl",
    "07_biofuel_comparison.jl", "08_equilibrium_gibbs.jl", "09_brayton_cycle.jl",
    "10_property_provider.jl", "11_comparing_sources.jl",
]
const EN_TITLES = [
    "Getting Started", "NASA Polynomials Under the Hood", "Temperature-Dependent Property Curves",
    "Enthalpy of Formation", "Reaction Enthalpies", "Adiabatic Flame Temperature",
    "Comparing Fuels & Biofuels", "Chemical Equilibrium & Gibbs Free Energy",
    "Brayton Gas-Turbine Cycle", "Property Provider for CFD", "Comparing Thermodynamic Data Sources",
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

const DOCS_SRC = joinpath(@__DIR__, "src")

function generate_index(lang_dir, files, titles, lang_label, heading, description)
    index_path = joinpath(DOCS_SRC, lang_dir, "index.md")
    mkpath(dirname(index_path))  # ensure directory exists
    open(index_path, "w") do io
        write(io, "# Glenn.jl — $lang_label\n\n")
        write(io, "$description\n\n")
        write(io, "> Abra estes arquivos com [Pluto.jl](https://plutojl.org):\n")
        write(io, "> `julia -e 'using Pluto; Pluto.run(notebook=\"$GITHUB_RAW/$lang_dir/...\")'`\n\n")
        write(io, "---\n\n")
        write(io, "## $heading\n\n")
        for (file, title) in zip(files, titles)
            url = "$GITHUB_RAW/$lang_dir/$file"
            write(io, "- [$title]($url)\n")
        end
        write(io, "\n---\n\n")
        write(io, "**Autor:** Dr. Reginaldo G. Leão Jr. — GESESC / IFMG\n\n")
        write(io, "**Repositório:** [ProfLeao/glenn-pluto-notebooks](https://github.com/ProfLeao/glenn-pluto-notebooks)\n")
    end
end

generate_index("pt-br", PT_FILES, PT_TITLES,
    "Cadernos Pluto (Português)", "Cadernos",
    "Coleção de cadernos interativos **Pluto.jl** demonstrando a biblioteca [**Glenn.jl**](https://github.com/ProfLeao/Glenn.jl).")

generate_index("en", EN_FILES, EN_TITLES,
    "Pluto Notebooks (English)", "Notebooks",
    "A collection of interactive **Pluto.jl** notebooks demonstrating the [**Glenn.jl**](https://github.com/ProfLeao/Glenn.jl) library.")

generate_index("es", ES_FILES, ES_TITLES,
    "Cuadernos Pluto (Español)", "Cuadernos",
    "Colección de cuadernos interactivos **Pluto.jl** que demuestran la biblioteca [**Glenn.jl**](https://github.com/ProfLeao/Glenn.jl).")

# ── Build the documentation ────────────────────────────────────────────────

makedocs(
    sitename = "Glenn.jl — Pluto Notebooks",
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", "false") == "true",
        canonical = "https://profleao.github.io/glenn-pluto-notebooks/stable/",
    ),
    pages = [
        "Home" => "index.md",
        "Português (Brasil)" => ["pt-br/index.md"],
        "English" => ["en/index.md"],
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
