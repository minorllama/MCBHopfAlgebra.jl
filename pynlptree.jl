using PythonCall

function tupled_tree_parser(node_data::Int, current_id::Ref{Int})
    return Node(node_data)
end

function tupled_tree_parser(node_data::Tuple, current_id::Ref{Int})
    internal_id = current_id[]
    current_id[] -= 1 
    offspring = [tupled_tree_parser(child, current_id) for child in node_data]
    return Node(internal_id, offspring)
end

const syntactic_tree = Ref{Py}()

function __init__()
    # Set the environment variable safely before PythonCall starts up
    ENV["JULIA_PYTHONCALL_EXE"] = pwd() * "/nlpenv/bin/python" 
    try
        sys = pyimport("sys")
        sys.path.append(".")
        syntactic_tree[] = pyimport("syntactic_tree")
    catch e
        @warn "Python environment or 'syntactic_tree' module not found. `labelled_trees` unavailable." exception=e
    end
end

function labelled_trees(text; loglevel=0)
    py_forest = syntactic_tree[].tupled_synactic_trees(text, loglevel)
    forest = pyconvert(Vector, py_forest)
    return map(forest) do tree_tuple
        root = Ref(-1)
        return tupled_tree_parser(tree_tuple, root)
    end
end



