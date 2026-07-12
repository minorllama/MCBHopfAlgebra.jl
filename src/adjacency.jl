struct Adjacency
    adjacency::Matrix{Int8}
    node_index::Dict{Int,Int}
    root::Node
end

function tree_node_index(root)
    function node_list(e, ns)
        if !isnothing(e)
            push!(ns, e.name)
            if !is_leaf(e)
                node_list(e.leaves[1], ns)
                node_list(e.leaves[2], ns)
            end
        end
    end
    nodes = Vector{Int}()
    node_list(root, nodes)
    node_index_r = Dict{Int,Int}()
    for (i, e) in enumerate(nodes)
        @assert !haskey(node_index_r, e)
        node_index_r[e] = i
    end
    return node_index_r
end

function adjacency(node::Node)::Adjacency
    node_index_r = tree_node_index(node)
    function hashed(node::Node, parent_name::Int, adjacency::Matrix{Int8}, node_index::Dict{Int,Int})
        if parent_name != node.name
            adjacency[node_index[parent_name], node_index[node.name]] = 1
        end
        if !isnothing(node.leaves[1])
            hashed(node.leaves[1], node.name, adjacency, node_index)
        end
        if !isnothing(node.leaves[2])
            hashed(node.leaves[2], node.name, adjacency, node_index)
        end
    end
    n = length(node_index_r)
    adj = zeros(Int8, n, n)
    hashed(node, node.name, adj, node_index_r)
    node_index = Dict{Int,Int}()
    for (k, v) in node_index_r
        @assert !haskey(node_index, v)
        node_index[v] = k
    end
    return Adjacency(adj, node_index, node)
end


function  queued(t::T) where {T}
    q = Queue{T}()
    enqueue!(q, t)
    return q
end


function relabel_internal(t::Node)
    index = -1
    descend = queued(t)
    while length(descend) > 0
        current = dequeue!(descend)
        if current.name < 0
            current.name = index
            index = index - 1
            enqueue!(descend, current.left) # left and right cannot be empty as the node is an interior node because node.name < 0
            enqueue!(descend, current.right)
        end
    end
end