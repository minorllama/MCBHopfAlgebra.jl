# Run: julia --project=. test/sideward_merge_tests.jl
# Select occurrences with InternalMerge.SubtreePath. Both paths are measured
# before deletion. Tests cover the three minimal cases in Proposition 2.3(5),
# general subtree extraction, and rejection of overlapping/inadmissible cuts.
module SidewardMergeTests
using Test
import MCBHopfAlgebra as mcb
import MCBHopfAlgebra.InternalMerge: SubtreePath, is_full_binary_tree
import MCBHopfAlgebra.SidewardMerge: sideward_merge
const Node = mcb.Node

snapshot(t::Node) = (t.name, Tuple(isnothing(c) ? nothing : snapshot(c) for c in t.leaves))
function signature(t::Node)
    mcb.is_leaf(t) && return "L$(t.name);"
    "(" * join(sort(signature.(t.leaves)), ",") * ")"
end
function nodes(t::Node)
    result = Node[t]
    for c in t.leaves
        isnothing(c) || append!(result, nodes(c))
    end
    result
end
function check_invariants(workspace, result)
    before = reduce(vcat, nodes.(workspace); init=Node[])
    after = reduce(vcat, nodes.(result); init=Node[])
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
example_tree() = mcb.node_from(-1, Node(1), mcb.node_from(-2, Node(2), Node(3)))

@testset "Sideward Merge" begin
    @testset "Leaves from different components" begin
        workspace = Node[mcb.node_from(-1, Node(1), Node(2)),
                         mcb.node_from(-2, Node(3), Node(4)), Node(9)]
        original = snapshot.(workspace)
        p, q = SubtreePath(1, (2,)), SubtreePath(2, (1,))
        result = sideward_merge(workspace, p, q; minimal=true)
        @test mcb.as_str.(result) == ["1", "4", "9", "(2, 3)"]
        @test length(result) == length(workspace) + 1
        @test snapshot.(workspace) == original
        check_invariants(workspace, result)
        reversed = sideward_merge(workspace, q, p; minimal=true)
        @test signature.(reversed) == signature.(result)
        result[end].leaves[1].name = 99
        result[3].name = 88
        @test snapshot.(workspace) == original
    end

    @testset "Two leaves from the same component" begin
        workspace = Node[example_tree()]
        original = snapshot.(workspace)
        result = sideward_merge(workspace, SubtreePath(1, (2, 1)),
                                SubtreePath(1, (2, 2)); minimal=true)
        @test mcb.as_str.(result) == ["1", "(2, 3)"]
        @test length(result) == 2
        check_invariants(workspace, result)
        @test_throws ArgumentError sideward_merge(workspace, SubtreePath(1, (2, 1)),
            SubtreePath(1, (2, 2)); allow_sisters=false)
        # Non-sister paths survive the stricter admissibility condition.
        other = sideward_merge(workspace, SubtreePath(1, (1,)),
            SubtreePath(1, (2, 1)); minimal=true, allow_sisters=false)
        @test mcb.as_str.(other) == ["3", "(1, 2)"]
        check_invariants(workspace, other)
        @test snapshot.(workspace) == original
    end

    @testset "Whole singleton and proper leaf; vector views" begin
        storage = Node[example_tree(), Node(4), Node(9)]
        workspace = view(storage, 1:2)
        p, q = SubtreePath(1, (2, 1)), SubtreePath(2)
        result = sideward_merge(workspace, p, q; minimal=true)
        @test mcb.as_str.(result) == ["(1, 3)", "(2, 4)"]
        @test length(result) == length(workspace)
        check_invariants(workspace, result)
        reversed = sideward_merge(workspace, q, p; minimal=true)
        @test signature.(reversed) == signature.(result)
    end

    @testset "General subtrees" begin
        workspace = Node[example_tree(), Node(4)]
        p, q = SubtreePath(1, (2,)), SubtreePath(2)
        result = sideward_merge(workspace, p, q)
        @test mcb.as_str.(result) == ["1", "((2, 3), 4)"]
        check_invariants(workspace, result)
        @test_throws ArgumentError sideward_merge(workspace, p, q; minimal=true)
        # Two non-leaf subtrees, simultaneously extracted from a shared source.
        t = mcb.node_from(-1, mcb.node_from(-2, Node(1), Node(2)),
            mcb.node_from(-3, mcb.node_from(-4, Node(3), Node(4)), Node(5)))
        workspace = Node[t]
        result = sideward_merge(workspace, SubtreePath(1, (1,)),
            SubtreePath(1, (2, 1)); allow_sisters=false)
        @test mcb.as_str.(result) == ["5", "((1, 2), (3, 4))"]
        check_invariants(workspace, result)
    end

    @testset "Repeated labels and shared storage" begin
        shared = Node(1)
        workspace = Node[mcb.node_from(-1, shared, mcb.node_from(-2, shared, Node(2)))]
        result = sideward_merge(workspace, SubtreePath(1, (1,)),
            SubtreePath(1, (2, 1)); minimal=true)
        @test mcb.as_str.(result) == ["2", "(1, 1)"]
        check_invariants(workspace, result)
    end

    @testset "Invalid selections" begin
        workspace = Node[example_tree(), Node(4)]
        original = snapshot.(workspace)
        for (p, q) in ((SubtreePath(1), SubtreePath(2)),
                       (SubtreePath(1, (2,)), SubtreePath(1, (2,))),
                       (SubtreePath(1, (2,)), SubtreePath(1, (2, 1))),
                       (SubtreePath(1), SubtreePath(1, (1,))),
                       (SubtreePath(1, (1,)), SubtreePath(1, (2,))),
                       (SubtreePath(3), SubtreePath(1, (1,))),
                       (SubtreePath(1, (1, 1)), SubtreePath(2)))
            @test_throws ArgumentError sideward_merge(workspace, p, q)
        end
        @test_throws ArgumentError sideward_merge(Node[], SubtreePath(1), SubtreePath(2))
        cherry = Node[mcb.node_from(-1, Node(1), Node(2))]
        @test_throws ArgumentError sideward_merge(cherry, SubtreePath(1, (1,)), SubtreePath(1, (2,)))
        @test snapshot.(workspace) == original
    end

    @testset "Malformed inputs and name boundary" begin
        unary = mcb.node_from(-1, Node(1), nothing)
        malformed = Node(-1, Union{Node,Nothing}[nothing])
        cyclic = mcb.node_from(-1, Node(1), Node(2))
        cyclic.leaves[2] = cyclic
        for invalid in (unary, malformed, cyclic)
            workspace = Node[example_tree(), Node(4), invalid]
            @test_throws ArgumentError sideward_merge(workspace, SubtreePath(1, (1,)), SubtreePath(2))
        end
        boundary = mcb.node_from(typemin(Int), Node(1), Node(2))
        @test_throws ArgumentError sideward_merge(Node[boundary, Node(3)],
            SubtreePath(1, (1,)), SubtreePath(2))
    end
end
end # module SidewardMergeTests
