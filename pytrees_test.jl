

include("src/MCBHopfAlgebra.jl")
text = "The quick brown fox jumps over the lazy dog. And we make a syntactic tree."
x = MCBHopfAlgebra.labelled_trees(text, loglevel=1);
MCBHopfAlgebra.as_str(x[1])