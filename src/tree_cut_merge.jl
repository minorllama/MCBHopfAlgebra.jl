struct FirstCut
    trunk::LeafType
    branch::LeafType
    cut_point::Int
end

function tree_spliced(root::LeafType, cutting::Int)
    nodes = Queue{Node}()
    enqueue!(nodes, root)
    while !isempty(nodes)
        current = dequeue!(nodes)
        for i= [1, 2]
            e = current.leaves[i]
            if !isnothing(e)
                if e.name == cutting
                    current.leaves[i] = new_leaf(0::Int)
                    return node_from(0, e, nothing)
                end
                enqueue!(nodes, e)
            end
        end
    end
    return nothing
end

function tree_cut_above(tree::LeafType, cutting::Int)::FirstCut
    trunk = tree_clone(tree)
    if trunk.name == cutting
        FirstCut(trunk, nothing, cutting) # trunk is always the one that contains root named -1
    else
        FirstCut(trunk, tree_spliced(trunk, cutting), cutting)
    end
end

function shears_prune_leaf(s, prune_this)
    if isnothing(s)
        return
    end
    for idx in [1, 2]
        if !isnothing(s.leaves[idx]) && prune_this(s.leaves[idx])
            @assert is_leaf(s.leaves[idx])
            s.left = nothing
        end
    end
    prune_leaf(s.leaves[1], prune_this)
    prune_leaf(s.leaves[2], prune_this)
end
function shears_prune_degree1(s)
    if isnothing(s)
        return
    elseif is_leaf(s)
        return
    end
    offspring = [e for e in s.leaves if !isnothing(e)]
    if length(offspring) == 1
        # delete this node and replace it with it's lone offspring
        e = offspring[1]
        s.name = e.name
        s.leaves[1] = e.leaves[1]
        s.leaves[2] = e.leaves[2]
        prune_degree1(s)
    else
        prune_degree1(offspring[1])
        prune_degree1(offspring[2])
    end
end

function prune_trunk(t)
    if isnothing(t)
        return t
    end
    @assert t.name != 0  # root is non-zero since t is trunk
    s = clone(t)
    prune_zero(x) = x.name == 0
    prune_interior(x) = x.name < 0 && is_leaf(x)
    shears_prune_leaf(s, prune_zero)  # cut off any leaf labeled 0. 
    shears_prune_leaf(s, prune_interior)  # cut off any leaf that used to be an interior node. 
    shears_prune_degree1(s) # delete any degree 1 interior vertex
    return s
end

function prune_branch(t)
    @assert isnothing(t.leaves[1]) ⊻ isnothing(t.leaves[2])
    @assert t.name == 0
    if isnothing(t.leaves[1])
        return t.leaves[2]
    else
        return t.leaves[1]
    end
end

struct PrunedCut
    trunk::LeafType
    branch::LeafType
    unpruned::FirstCut
end

function cut_and_prune(tree::LeafType, cut_point::Int)::PrunedCut
    cut = cut_above(tree, cut_point)
    pruned_trunk = prune_trunk(cut.trunk)
    pruned_branch = prune_branch(cut.branch)
    return PrunedCut(pruned_trunk, pruned_branch, cut)
end

function as_str(t::FirstCut)
    as_str(t.trunk) * " ⨂ " * as_str(t.branch)
end

function as_str(t::PrunedCut)
    Main.TreeNode.as_str(t.trunk) * " ⨂ " * Main.TreeNode.as_str(t.branch)
end