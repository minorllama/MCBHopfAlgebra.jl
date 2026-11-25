module ExternalMerge

import ..MCBHopfAlgebra as mcb
import ..InternalMerge: is_full_binary_tree, _fresh_name

const Node = mcb.Node
export external_merge

"""
    external_merge(workspace::AbstractVector{Node}, first::Int, second::Int)

Join two distinct whole components S and T under a fresh negative root,
replacing them by M(S,T). Return a new Vector{Node} with the unselected
components in their original order followed by the merged tree. Child slots
follow argument order, but have no mathematical ordering significance.

All output nodes are copied, including unselected components; input trees
remain unchanged. Leaf labels and their multiplicities are preserved, while
the number of components decreases by one. Existing node names are preserved;
the new root's name is smaller than every input name. Repeated names do not
affect selection, which uses one-based component indices.

Inputs must be full binary trees without cycles. An invalid index, repeated
component index, or unavailable fresh name raises ArgumentError. Empty or
singleton workspaces admit no External Merge.

See Marcolli–Skigin, arXiv:2512.18861v1, §1.1, p. 5, below (1.5).

# Example
```julia
workspace = Node[Node(1), Node(2), Node(3)]
result = external_merge(workspace, 1, 2)
mcb.as_str.(result)  # ["3", "(1, 2)"]
```
"""
function external_merge(workspace::AbstractVector{Node}, first::Int, second::Int)
    first in eachindex(workspace) || throw(ArgumentError("first component index outside workspace"))
    second in eachindex(workspace) || throw(ArgumentError("second component index outside workspace"))
    first != second || throw(ArgumentError("External Merge requires two distinct components"))
    foreach(is_full_binary_tree, workspace)
    name = _fresh_name(workspace)
    merged = mcb.node_from(name, mcb.tree_clone(workspace[first]),
                                mcb.tree_clone(workspace[second]))
    result = Node[mcb.tree_clone(workspace[i]) for i in eachindex(workspace)
                  if i != first && i != second]
    push!(result, merged)
    result
end

end # module ExternalMerge
