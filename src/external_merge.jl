module ExternalMerge

import ..MCBHopfAlgebra as mcb
import ..Workspace: _fresh_name, is_full_binary_tree, Node

export external_merge

"""
    external_merge(workspace::AbstractVector{Node}, first::Int, second::Int)


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
