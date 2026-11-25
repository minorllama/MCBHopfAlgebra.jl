using MCBHopfAlgebra
using Test

@testset "MCBHopfAlgebra.jl" begin
    include("internal_merge_tests.jl")
    include("external_merge_tests.jl")
    include("sideward_merge_tests.jl")
end
