function tree_nodes_dfs(t)
    nodes = []
    if isnothing(t)
        return nodes
    end 
    @assert t.name == -1 || (isnothing(t.leaves[1]) && isnothing(t.leaves[2])) # root must be named -1
    function __descend(t, nodes)
        if isnothing(t) 
            return nodes
        else
            if is_leaf(t)
                @assert t.name > 0 
            else 
                @assert t.name < 1
            end
            push!(nodes, t.name)
            __descend(t.leaves[1], nodes)
            __descend(t.leaves[2], nodes)
        end
    end
    __descend(t, nodes)
    return nodes
end 

# avoid the recursive version for performance
function tree_node_index_dfs(root)
    function node_list_dfs(e, ns)
        if !isnothing(e)
            push!(ns, e.name)
            if !is_leaf(e)
                node_list_dfs(e.leaves[1], ns)
                node_list_dfs(e.leaves[2], ns)
            end
        end
    end
    nodes = Vector{Int}()
    node_list_dfs(root, nodes)
    hashed = Dict{Int,Int}()
    for (i, e) in enumerate(nodes)
        @assert !haskey(hashed, e)
        hashed[e] = i
    end
    hashed
end