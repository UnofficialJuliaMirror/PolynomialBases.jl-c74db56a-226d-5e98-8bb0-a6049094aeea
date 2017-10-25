"""
    laguerre(x, p::Integer)

Evaluate the Laguerre polynomial of degree `p` at `x` using the three term recursion.
"""
function laguerre(x, p::Integer)
    T = typeof( 1-x )
    p₀ = one(T)
    p₁ = 1-x

    if p <= 0
        return p₀
    elseif p == 1
        return p₁
    end

    for n in 2:p
        p₀, p₁ = p₁, ( (2n-1-x)*p₁ - (n-1)*p₀ ) / n
    end

    p₁
end
