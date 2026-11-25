# Run independently: julia --project=. test/external_merge_tests.jl
# External Merge combines WHOLE components; indices refer to the input vector.
# Example: [1, 2, 3] -> [3, {1,2}] when components 1 and 2 are selected.
# The resulting forest is unordered, although its vector storage has an order.

module ExternalMergeTests
using Test
import MCBHopfAlgebra as mcb
import MCBHopfAlgebra.ExternalMerge: external_merge
import MCBHopfAlgebra.InternalMerge: is_full_binary_tree
const Node = mcb.Node

# Independent comparison for nonplanar trees, preserving label multiplicities.
function signature(t::Node)
    mcb.is_leaf(t) && return "L$(t.name);"
    "(" * join(sort(signature.(t.leaves)), ",") * ")"
end

snapshot(t::Node) = (t.name, Tuple(isnothing(c) ? nothing : snapshot(c) for c in t.leaves))

function nodes(t::Node)
    result = Node[t]
    for c in t.leaves
        isnothing(c) || append!(result, nodes(c))
    end
    result
end

function check_invariants(workspace, result)
    @test length(result) == length(workspace) - 1
    before = reduce(vcat, nodes.(workspace); init=Node[])
    after = reduce(vcat, nodes.(result); init=Node[])
    @test length(after) == length(before) + 1
    @test sort([n.name for n in before if mcb.is_leaf(n)]) ==
          sort([n.name for n in after if mcb.is_leaf(n)])
    @test all(t -> is_full_binary_tree(t) === nothing, result)
    @test all(n -> mcb.is_leaf(n) || n.name < 0, after)
    @test result[end].name < min(0, minimum(n.name for n in before))
    @test all(a -> all(b -> a !== b, before), after)
    identities = IdDict{Node,Nothing}()
    for n in after
        identities[n] = nothing
    end
    @test length(identities) == length(after)
end

@testset "External Merge" begin
    @testset "Singleton components and fresh root" begin
        workspace = Node[Node(1), Node(2), Node(3)]
        original = snapshot.(workspace)
        result = external_merge(workspace, 1, 2)
        @test mcb.as_str.(result) == ["3", "(1, 2)"]
        @test result[end].name == -1
        @test snapshot.(workspace) == original
        check_invariants(workspace, result)
        result[end].leaves[1].name = 99
        result[1].name = 88
        @test snapshot.(workspace) == original
    end

    @testset "Nontrivial components, ordering, and vector views" begin
        a = mcb.node_from(-1, Node(1), Node(2))
        b = mcb.node_from(-2, Node(3), Node(4))
        workspace = Node[a, Node(8), b, Node(9)]
        original = snapshot.(workspace)
        result = external_merge(workspace, 1, 3)
        @test mcb.as_str.(result) == ["8", "9", "((1, 2), (3, 4))"]
        @test result[end].name == -3
        check_invariants(workspace, result)
        reversed = external_merge(workspace, 3, 1)
        @test signature.(reversed) == signature.(result)
        @test mcb.as_str(reversed[end]) == "((3, 4), (1, 2))"
        @test snapshot.(workspace) == original
        subspace = view(workspace, 1:3)
        check_invariants(subspace, external_merge(subspace, 1, 3))
    end

    @testset "Repeated labels and shared input occurrences" begin
        shared = Node(1)
        workspace = Node[shared, shared]
        result = external_merge(workspace, 1, 2)
        @test mcb.as_str.(result) == ["(1, 1)"]
        check_invariants(workspace, result)
    end

    @testset "Repeated merging constructs a tree" begin
        workspace = Node[Node(1), Node(2), Node(3)]
        first = external_merge(workspace, 1, 2)
        second = external_merge(first, 1, 2)
        @test mcb.as_str.(second) == ["(3, (1, 2))"]
        check_invariants(first, second)
    end

    @testset "Invalid selections" begin
        workspace = Node[Node(1), Node(2)]
        original = snapshot.(workspace)
        for pair in ((1, 1), (0, 2), (-1, 2), (1, 3), (3, 1))
            @test_throws ArgumentError external_merge(workspace, pair...)
        end
        @test_throws ArgumentError external_merge(Node[], 1, 2)
        @test_throws ArgumentError external_merge(Node[Node(1)], 1, 2)
        @test snapshot.(workspace) == original
    end

    @testset "Validation and integer boundary" begin
        unary = mcb.node_from(-1, Node(1), nothing)
        malformed = Node(-1, Union{Node,Nothing}[nothing])
        cyclic = mcb.node_from(-1, Node(1), Node(2))
        cyclic.leaves[2] = cyclic
        for invalid in (unary, malformed, cyclic)
            # Even an unselected component must be valid.
            @test_throws ArgumentError external_merge(Node[Node(1), Node(2), invalid], 1, 2)
        end
        boundary = mcb.node_from(typemin(Int), Node(1), Node(2))
        @test_throws ArgumentError external_merge(Node[boundary, Node(3)], 1, 2)
    end
end
end # module ExternalMergeTests
