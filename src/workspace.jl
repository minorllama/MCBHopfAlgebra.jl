module Workspace

import ..MCBHopfAlgebra as mcb

const Node = mcb.Node
const _leaf = mcb.is_leaf
const _clone = mcb.tree_clone
_graft(a::mcb.Node, b::mcb.Node, name::Int) = mcb.node_from(name, a, b)

function _fresh_name(workspace)
    lowest = minimum(_min_name(t) for t in workspace)
    lowest == typemin(Int) && throw(ArgumentError("cannot allocate a smaller root name"))
    lowest - 1
end

function _min_name(t::Node)
    result = min(0, t.name)
    for c in t.leaves
        isnothing(c) || (result = min(result, _min_name(c)))
    end
    result
end

# Simultaneous deletion avoids path shifts. Empty internal vertices disappear;
# unary vertices are suppressed. Remaining occurrences are independently copied.
function _delete(t::Node, paths, here::Tuple=())
    any(p -> p == here, paths) && return nothing
    _leaf(t) && return _clone(t)
    left = _delete(t.leaves[1]::Node, paths, (here..., 1))
    right = _delete(t.leaves[2]::Node, paths, (here..., 2))
    isnothing(left) && return right
    isnothing(right) && return left
    _graft(left, right, t.name)
end


# validation functions
function is_full_binary_tree(t::Node, ancestors=IdDict{Node,Nothing}())
    haskey(ancestors, t) && throw(ArgumentError("cyclic Node graph"))
    length(t.leaves) == 2 || throw(ArgumentError("Node needs two child slots"))
    count(isnothing, t.leaves) in (0, 2) || throw(ArgumentError("input must be full binary (no unary vertices)"))
    ancestors[t] = nothing
    for c in t.leaves
        isnothing(c) || is_full_binary_tree(c, ancestors)
    end
    delete!(ancestors, t)
    nothing
end

# A workspace is a collection of trees, so it has type: workspace::AbstractVector{Node}

"""Select an a subtree in wokrspace by one-based component and child path (1 or 2).
an empty path selects the whole component. Paths refer to the original input."""
struct SubtreePath
    component::Int
    path::Tuple{Vararg{Int}}
    function SubtreePath(component, path=())
        p = Tuple(path)
        # validate that path in workspace 
        component > 0 || throw(ArgumentError("tree index must be more than zero"))
        all(x -> x isa Integer && x in (1, 2), p) || throw(ArgumentError("path entries must be 1 or 2"))
        new(Int(component), Tuple(Int(x) for x in p))
    end
end

""" Follow the selector:SubtreePath and returns the existing node at there """
function get_subtree(workspace, occurrence::SubtreePath)
    1 <= occurrence.component <= length(workspace) || throw(ArgumentError("component index outside workspace"))
    t = workspace[occurrence.component]
    for i in occurrence.path
        _leaf(t) && throw(ArgumentError("path descends below a leaf"))
        t = t.leaves[i]::Node
    end
    t
end

end # Workspace