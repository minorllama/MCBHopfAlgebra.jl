using DataStructures


function  queued(t::T) where {T}
    q = Queue{T}()
    enqueue!(q, t)
    return q
end