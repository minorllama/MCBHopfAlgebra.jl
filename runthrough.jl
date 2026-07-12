addPkg = false
revise = true
if addPkg
    using Pkg
    Pkg.add(["ElectronDisplay", "DataStructures", "Combinatorics"])
end

if revise
    using Revise
    includet("src/MCBHopfAlgebra.jl")
else
    include("src/MCBHopfAlgebra.jl")
end


import .MCBHopfAlgebra as mcb
import .MCBHopfAlgebra.TreePlot: plot as treeplot

using ElectronDisplay: display as display


function example(;console=true)
    function show(t)
        display(t)
        if console
            print("...") 
            readline()
        end
    end
    t1, t2 = mcb.tree_examples();
    show(treeplot(t1, "t1"))

    t1_adj = mcb.adjacency(t1)
    println("t1:node_index ", t1_adj.node_index)
    println("t1:adjacency ",  t1_adj.adjacency)

    t = mcb.tree_cut_above(t1, 1)

    show(treeplot(t.branch, "t1:branch"))
    show(treeplot(t.trunk, "t1:trunk"))
end