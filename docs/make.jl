using Documenter, LSODA

makedocs(
    modules=[LSODA],
    clean = false,
    format = :html,
    sitename = "LSODA.jl",
    pages = Any[
      "Home" => "index.md"
    ]
)

deploydocs(
    repo   = "github.com/rveltz/LSODA.jl.git",
    target = "build",
    deps   = nothing,
    make   = nothing,
    julia  = "release"
)
