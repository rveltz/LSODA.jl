push!(LOAD_PATH,"../src")

using Documenter, LSODA

makedocs(
    modules=[LSODA],
    format = :html,
    sitename = "LSODA",
    pages = [
      "index.md"
    ]
)

deploydocs(
    repo   = "github.com/rveltz/LSODA.jl.git",
    target = "build",
    deps   = nothing,
    make   = nothing,
    julia  = "0.5"
)
