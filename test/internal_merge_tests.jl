# Internal Merge: documented examples and behavioral tests.
# Run from the repository root:
#     julia --project=. test/internal_merge_tests.jl
# Dependencies must already be installed. This file runs independently of the
# existing test/runtests.jl; that entry point is left unchanged.
#
# In Marcolli–Skigin (arXiv:2512.18861v1), see §1.1, pp. 4–5,
# equation (1.2) and the paragraph below (1.5), and Proposition 2.3,
# proof (3), p. 11. For a selected accessible occurrence S in component T,
# Internal Merge replaces T by M(S,T/S). Deletion removes S and suppresses
# unary vertices; grafting joins S and its remainder under a new root.
# Other workspace components retain their mathematical structure.
#
# Example: T = {1,{2,3}}, path (2,1) selects leaf 2.
# The remainder is {1,3}, and the result is {2,{1,3}}.
# A root-child selection gives the same nonplanar tree. The implementation
# accepts it, although the paper excludes it when counting nonidentity arrows.
#
# SubtreePath(component, path) uses one-based component/child indices.
# Paths refer to the original workspace, and distinguish repeated labels.
# Node names on leaves represent lexical labels. Internal names are bookkeeping.
# These tests compare nonplanar structures independently of existing package
# equality routines, and also check copying, leaf multiplicities, and errors.
# Execution status: generated for review; not executed in the authoring session.

module InternalMergeTests

using Test
import MCBHopfAlgebra as mcb
import MCBHopfAlgebra.InternalMerge as im

const Node = mcb.Node
const SubtreePath = im.SubtreePath
const merge = im.internal_merge

# Canonical structural signature: ignore internal names and child order,
# but preserve tree topology and repeated leaf labels. No mutation is needed.
function signature(t::Node)
    mcb.is_leaf(t) && return "L$(t.name);"
    children = sort([signature(t.leaves[1]), signature(t.leaves[2])])
    "(" * join(children, ",") * ")"
end

function leaf_labels(t::Node)
    mcb.is_leaf(t) && return [t.name]
    vcat(leaf_labels(t.leaves[1]), leaf_labels(t.leaves[2]))
end

# Preserve both names and child order when checking input immutability.
snapshot(t::Node) = (t.name, Tuple(isnothing(c) ? nothing : snapshot(c) for c in t.leaves))

function nodes(t::Node)
    result = Node[t]
    for c in t.leaves
        isnothing(c) || append!(result, nodes(c))
    end
    result
end

function check_invariants(before, after)
    @test length(after) == length(before)
    for (source, target) in zip(before, after)
        @test sort(leaf_labels(source)) == sort(leaf_labels(target))
        @test im.is_full_binary_tree(target) === nothing
        @test all(n -> mcb.is_leaf(n) || n.name < 0, nodes(target))
    end
    source_nodes = reduce(vcat, nodes.(before); init=Node[])
    target_nodes = reduce(vcat, nodes.(after); init=Node[])
    @test all(a -> all(b -> a !== b, source_nodes), target_nodes)
    identities = IdDict{Node,Nothing}()
    for n in target_nodes
        identities[n] = nothing
    end
    @test length(identities) == length(target_nodes)
end

example_tree() = mcb.node_from(-1, Node(1), mcb.node_from(-2, Node(2), Node(3)))

@testset "Internal Merge" begin
    @testset "Selectors and subtree lookup" begin
        t = example_tree()
        selector = SubtreePath(1, [2, 1])
        @test selector.component == 1
        @test selector.path == (2, 1)
        @test im.get_subtree(Node[t], selector) === t.leaves[2].leaves[1]
        @test im.get_subtree(Node[t], SubtreePath(1)) === t
        @test_throws ArgumentError SubtreePath(0)
        @test_throws ArgumentError SubtreePath(-1)
        @test_throws ArgumentError SubtreePath(1, (3,))
        @test_throws ArgumentError SubtreePath(1, (1.0,))
    end

    @testset "Promote a leaf; preserve other components" begin
        t = example_tree()
        workspace = Node[Node(9), t, mcb.node_from(-10, Node(4), Node(5))]
        original = snapshot.(workspace)
        result = merge(workspace, SubtreePath(2, (2, 1)))
        @test mcb.as_str(result[2]) == "(2, (1, 3))"
        @test signature(result[1]) == signature(workspace[1])
        @test signature(result[3]) == signature(workspace[3])
        @test result[2].name < minimum(n.name for component in workspace for n in nodes(component))
        @test snapshot.(workspace) == original
        check_invariants(workspace, result)
        # Mutating an output leaf must not affect the selected input leaf.
        result[2].leaves[1].name = 99
        @test im.get_subtree(workspace, SubtreePath(2, (2, 1))).name == 2
        @test snapshot.(workspace) == original
    end

    @testset "Promote a non-leaf subtree; accept vector views" begin
        # {1,{{2,3},4}} -> {{2,3},{1,4}}
        t = mcb.node_from(-1, Node(1),
            mcb.node_from(-2, mcb.node_from(-3, Node(2), Node(3)), Node(4)))
        storage = Node[t, Node(8)]
        workspace = view(storage, 1:1)
        original = snapshot.(workspace)
        result = merge(workspace, SubtreePath(1, (2, 1)))
        @test mcb.as_str(result[1]) == "((2, 3), (1, 4))"
        @test snapshot.(workspace) == original
        check_invariants(workspace, result)
    end

    @testset "Root-child selections are nonplanar identities" begin
        for path in ((1,), (2,))
            workspace = Node[example_tree()]
            result = merge(workspace, SubtreePath(1, path))
            @test signature(result[1]) == signature(workspace[1])
            check_invariants(workspace, result)
        end
    end

    @testset "Repeated labels select occurrences" begin
        t = mcb.node_from(-1, Node(1), mcb.node_from(-2, Node(1), Node(2)))
        workspace = Node[t]
        result = merge(workspace, SubtreePath(1, (2, 1)))
        @test mcb.as_str(result[1]) == "(1, (1, 2))"
        @test sort(leaf_labels(result[1])) == [1, 1, 2]
        check_invariants(workspace, result)
        # Shared source storage is still treated as separate occurrences.
        shared = Node(7)
        aliased = Node[mcb.node_from(-1, shared, shared)]
        copied = merge(aliased, SubtreePath(1, (1,)))
        check_invariants(aliased, copied)
    end

    @testset "Invalid selections leave inputs unchanged" begin
        workspace = Node[example_tree()]
        original = snapshot.(workspace)
        @test_throws ArgumentError merge(workspace, SubtreePath(1))
        @test_throws ArgumentError merge(workspace, SubtreePath(2, (1,)))
        @test_throws ArgumentError merge(workspace, SubtreePath(1, (1, 1)))
        @test_throws ArgumentError merge(Node[], SubtreePath(1, (1,)))
        @test_throws ArgumentError merge(Node[Node(1)], SubtreePath(1, (1,)))
        @test snapshot.(workspace) == original
    end

    @testset "Malformed trees and cycles" begin
        unary = mcb.node_from(-1, Node(1), nothing)
        malformed = Node(-1, Union{Node,Nothing}[nothing])
        cyclic = mcb.node_from(-1, Node(1), Node(2))
        cyclic.leaves[2] = cyclic
        for t in (unary, malformed, cyclic)
            @test_throws ArgumentError im.is_full_binary_tree(t)
            @test_throws ArgumentError merge(Node[t], SubtreePath(1, (1,)))
        end
    end

    @testset "Fresh negative names and integer boundary" begin
        @test im._fresh_name(Node[Node(1), Node(2)]) == -1
        @test im._fresh_name(Node[example_tree()]) == -3
        boundary = mcb.node_from(typemin(Int), Node(1), Node(2))
        @test_throws ArgumentError merge(Node[boundary], SubtreePath(1, (1,)))
    end
end

end # module InternalMergeTests
