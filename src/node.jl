using DataStructures

mutable struct Node
    name::Int
    leaves::Vector{Union{Node, Nothing}}
end
LeafType=Union{Node, Nothing}


function  node_from(name::Int, left::LeafType, right::LeafType)::Node
    leaves = Vector{LeafType}()
    push!(leaves, left)
    push!(leaves, right)
    Node(name, leaves)
end

function new_leaf(n::Int)::Node 
    leaves = Vector{LeafType}()
    push!(leaves, nothing)
    push!(leaves, nothing)
    return Node(n, leaves)
end

function is_leaf(n::Node)::Bool
    isnothing(n.leaves[1]) && isnothing(n.leaves[2])
end

@inline function tree_as_str(root::LeafType)::String
    if isnothing(root) return ""
    elseif is_leaf(root) return "$(root.name)"
    else return "($(tree_as_str(root.leaves[1])), $(tree_as_str(root.leaves[2])))"
    end
end

as_str(t::Node)::String = tree_as_str(t)

function is_empty_tree(t) 
    return isnothing(t) || (is_leaf(t) && t.name < 0)
end

function tree_equality(a::Node, b::Node, is_ordered::Bool)::Bool 
    a_is_leaf = is_leaf(a)
    b_is_leaf = is_leaf(b)
    if xor(a_is_leaf, b_is_leaf) 
        # only one of the tree has size one
        return false
    elseif a_is_leaf == true
        # Since xor is false, therefore both trees have size = 1 and for equality names must agree 
        # names of internal nodes are not compared for trees of size > 1
        return a.name == b.name
    else 
        # neither one is leaf, check that left and right trees agree 
        ordered_check = tree_equality(a.leaves[1], b.leaves[1], is_ordered) && tree_equality(a.leaves[2], b.leaves[2], is_ordered) 
        if is_ordered || ordered_check 
            return ordered_check
        else
            return tree_equality(a.leaves[1], b.leaves[2], is_ordered) && tree_equality(a.leaves[1], b.leaves[2], is_ordered) 
        end
    end
end

function tree_equality_unordered(a::Node, b::Node)::Bool  
    return tree_equality(a, b, false)
end

function tree_equality_ordered(a::Node, b::Node)::Bool  
    return tree_equality(a, b, true)
end

function update_subtree(root::LeafType, i::Int, node::LeafType)
    @assert i == 1 || i == 2
    root.leaves[i] = node
end


function tree_nodes(t)
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

function tree_clone(tree::LeafType)::LeafType
    if isnothing(tree) 
        return nothing
    else
        return node_from(tree.name,  tree_clone(tree.leaves[1]), tree_clone(tree.leaves[2])) 
    end
end


function tree_sort_min_node!(node::Node)::Int
    # cannot have only one child, because that would make the parent an interior node
    left_tree = node.leaves[1]
    right_tree = node.leaves[2]
    @assert !xor(isnothing(left_tree), isnothing(right_tree))
    if is_leaf(node)
        return node.name
    else
        left_min = tree_sort_min_node!(left_tree)
        right_min = tree_sort_min_node!(right_tree)
        if right_min < left_min
            node.leaves[1] = right_tree
            node.leaves[2] = left_tree
            return right_min
        else
            return left_min
        end
    end
end

function  tree_sort!(node::Node)
    tree_sort_min_node!(node)
    node
end



function tree_examples()
    t1 = node_from(-1, new_leaf(1), node_from(-2, new_leaf(2), new_leaf(3)))
    t2 = node_from(-1, new_leaf(1), node_from(-2, new_leaf(3), new_leaf(2)))
    [t1, t2]
end



function tree_nodes(root)::Vector{Int}
    nodes = Vector{Int}()
    if !isnothing(root)
        q = Queue{Node}()
        enqueue!(q, root)
        while !isempty(q)
            e = dequeue!(q)
            push!(nodes, e.name)
            if !is_leaf(e)
                enqueue!(q, e.leaves[1])
                enqueue!(q, e.leaves[2])
            end
        end
    end
    nodes 
end

function tree_node_index(root::Node)::Dict{Int,Int}
    nodes = tree_nodes(root)
    hashed = Dict{Int,Int}()
    for (i, e) in enumerate(nodes)
        @assert !haskey(hashed, e)
        hashed[e] = i
    end
    hashed
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


function tree_tests()
    (t1, t2) = tree_examples(); 
    t3 = tree_clone(t2)
    @assert tree_equality_ordered(t2, t3)
    @assert as_str(t1) ==  "(1, (2, 3))"
    @assert as_str(t2) == "(1, (3, 2))"
    @assert !tree_equality_ordered(t1, t2)
    @assert !tree_equality_ordered(t2, t3)
    @assert as_str(tree_sort!(t2)) == "(1, (2, 3))"
    @assert tree_equality_unordered(t1, t2)
    (t1, t2)
end



struct TreeCut
    trunk::LeafType
    branch::LeafType
    cut_point::Int
end

function as_str(t::TreeCut)
    as_str(t.trunk) * " ⨂ " * as_str(t.branch)
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

function tree_cut_above(tree::LeafType, cutting::Int)::TreeCut
    trunk = tree_clone(tree)
    if trunk.name == cutting
        TreeCut(trunk, nothing, cutting) # trunk is always the one that contains root named -1
    else
        TreeCut(trunk, tree_spliced(trunk, cutting), cutting)
    end
end

