

module TreeCombinatorics
    using Combinatorics
    using DataStructures
    function n_catalan(n::Int64)::Int64
        # https://en.wikipedia.org/wiki/Catalan_number
        # nth Catalan number counts full binary rooted (ordered) trees on n+1 leaves
        return binomial(2*n, n)/ (n+1)
    end

    function double_factorial(n::Int64)::Int64 
        # for counting unordered trees on leaves: (2*n - 3)!!
        m = n
        r = 1
        while m > 0 
            r = r * m 
            m = m - 2
        end
        return r 
    end 

    function n_unordered_trees(n::Int)
        return double_factorial(2*n - 3)
    end

    function size_vertex_set_G_n_A(n)
        #= counts V(G_{n, A}) using lemma 2.2 Marcolli-Skigin, https://doi.org/10.48550/arXiv.2512.18861 =#
        function lemma_2_2_normalization(part)
            counts = counter(part)
            ai = [v for (k, v) in counts] # keep the counts: partition [1, 1, 1, 2] of 5 becomes [(1, 3), (2,1)]  
            return prod(factorial(e) for e in ai), counts, ai 
        end
        
        parts = [e for e in Combinatorics.partitions(n) if length(e) != n]
        Fn = 0
        for part in parts
            a, counts, ai = lemma_2_2_normalization(part)
            Mnk = Combinatorics.multinomial(part...)
            K = prod(double_factorial(2*size-3) for size in part) # so for [1, 1, 1, 2] there are 3 factors of (2k-3)!! when k = 1 and so on  
            Fn += Mnk * K / a
        end
        return Fn
    end
end



