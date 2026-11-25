module InternalMerge

import ..Workspace: _delete, _fresh_name, _graft, _clone, Node, SubtreePath, get_subtree, is_full_binary_tree

"""Replace component T by M(S,T/S) for a selected proper subtree S.
Returns fresh storage without mutating inputs. Root-child selections are allowed
and are identity operations up to nonplanar equality."""
function internal_merge(workspace::AbstractVector{Node}, occurrence::SubtreePath)
    foreach(is_full_binary_tree, workspace)
    selected = get_subtree(workspace, occurrence)
    isempty(occurrence.path) && throw(ArgumentError("Internal Merge requires a proper subtree"))
    result = Node[]
    for (i, t) in enumerate(workspace)
        if i == occurrence.component
            remainder = _delete(t, [occurrence.path])::Node
            push!(result, _graft(_clone(selected), remainder, _fresh_name(workspace)))
        else
            push!(result, _clone(t))
        end
    end
    result
end


end