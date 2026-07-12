module TreePlot
    using DataStructures
    using Graphs, GraphPlot, Compose
    import ..MCBHopfAlgebra as mcb

    import ..MCBHopfAlgebra:Node,Adjacency,adjacency

    struct TreePlotter
        raw::mcb.Adjacency
    end

    function (plotter::TreePlotter)(g)
        maxdepth = length(plotter.raw.node_index)
        function layout_coords(t::Union{Node,Nothing}, x::Int, y::Int, coords::Dict{Int,Tuple{Int,Int}}, depth::Int)::Int
            if !isnothing(t)
                coords[t.name] = (x, y)
                spread = maxdepth - depth
                left_depth = layout_coords(t.leaves[1], x - spread, y + 1, coords, depth + 1)
                right_depth = layout_coords(t.leaves[2], x + spread, y + 1, coords, depth + 1)
                return max(left_depth, right_depth)
            end
            return depth
        end
        coords = Dict{Int,Tuple{Int,Int}}()
        depth = layout_coords(plotter.raw.root, 0, 0, coords, 1)
        locs_x = zeros(nv(g))
        locs_y = zeros(nv(g))
        for (k, v) in plotter.raw.node_index
            (x, y) = coords[v]
            locs_x[k] = x
            locs_y[k] = y
        end
        return locs_x, locs_y

    end

    function node_names(t::Adjacency)
        names = zeros(length(t.node_index))
        for (k, v) in t.node_index
            @assert names[k] == 0
            names[k] = v
        end
        return names
    end

    function plot(t::Node, title::String)
        adj = adjacency(t)
        g = SimpleDiGraph(adj.adjacency)
        layout = g -> TreePlotter(adj)(g)
        # saveplot(__gplot, fname)
        return gplot(g, nodelabel=node_names(adj), layout=layout, title=title)
    end

end