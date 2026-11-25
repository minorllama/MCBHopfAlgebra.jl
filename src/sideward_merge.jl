module SidewardMerge

import ..MCBHopfAlgebra as mcb
import ..InternalMerge: SubtreePath, get_subtree, is_full_binary_tree, _delete, _fresh_name

const Node = mcb.Node
export sideward_merge

_prefix(p, q) = length(p) <= length(q) && all(p[i] == q[i] for i in eachindex(p))

"""
    sideward_merge(workspace::AbstractVector{Node}, first::SubtreePath,
                   second::SubtreePath; minimal=false, allow_sisters=true)

"""
function sideward_merge(workspace::AbstractVector{Node}, first::SubtreePath,
                        second::SubtreePath;
                        minimal::Bool=false, allow_sisters::Bool=true)
    foreach(is_full_binary_tree, workspace)
    a = get_subtree(workspace, first)
    b = get_subtree(workspace, second)
    isempty(first.path) && isempty(second.path) &&
        throw(ArgumentError("two whole components are External Merge"))
    minimal && !(mcb.is_leaf(a) && mcb.is_leaf(b)) &&
        throw(ArgumentError("minimal Sideward Merge requires two leaves"))
    same_source = first.component == second.component
    if same_source
        p, q = first.path, second.path
        (_prefix(p, q) || _prefix(q, p)) &&
            throw(ArgumentError("selected occurrences overlap"))
        sisters = length(p) == length(q) && p[1:end-1] == q[1:end-1]
        !allow_sisters && sisters &&
            throw(ArgumentError("sister extraction is disabled"))
    end
    name = _fresh_name(workspace)
    result = Node[]
    for (i, t) in enumerate(workspace)
        paths = Tuple{Vararg{Int}}[]
        i == first.component && push!(paths, first.path)
        i == second.component && push!(paths, second.path)
        remainder = isempty(paths) ? mcb.tree_clone(t) : _delete(t, paths)
        same_source && i == first.component && isnothing(remainder) &&
            throw(ArgumentError("same-source extraction must leave a nonempty remainder"))
        isnothing(remainder) || push!(result, remainder)
    end
    push!(result, mcb.node_from(name, mcb.tree_clone(a), mcb.tree_clone(b)))
    result
end

end # module SidewardMerge
