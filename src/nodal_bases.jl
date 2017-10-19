
Base.@pure degree(basis::NodalBasis{Line}) = length(basis.nodes)-1

function change_basis{Domain<:AbstractDomain}(dest_basis::NodalBasis{Domain},
                                                values, src_basis::NodalBasis{Domain})
    @boundscheck begin
        @assert length(dest_basis.nodes) == length(src_basis.nodes) == length(values)
    end
    ret = similar(values)
    @inbounds change_basis!(ret, dest_basis, values, src_basis)
    ret
end

function change_basis!{Domain<:AbstractDomain}(ret, dest_basis::NodalBasis{Domain},
                                                values, src_basis::NodalBasis{Domain})
    @boundscheck begin
        @assert length(dest_basis.nodes) == length(src_basis.nodes) == length(values)
        @assert length(values) == length(ret)
    end
    interpolate!(ret, dest_basis.nodes, values, src_basis)
    nothing
end



"""
    LobattoLegendre{T<:Real}

The nodal basis corresponding to Legendre Gauss Lobatto quadrature in [-1,1]
with scalar type `T`.
"""
struct LobattoLegendre{T<:Real} <: NodalBasis{Line}
    nodes::Vector{T}
    weights::Vector{T}
    baryweights::Vector{T}
    D::Matrix{T}

    function LobattoLegendre(nodes::Vector{T}, weights::Vector{T}, baryweights::Vector{T}, D::Matrix{T}) where T
        @assert length(nodes) == length(weights) == length(baryweights) == size(D,1) == size(D,2)
        new{T}(nodes, weights, baryweights, D)
    end
end

"""
    LobattoLegendre(p::Int, T=Float64)

Generate the `LobattoLegendre` basis of degree `p` with scalar type `T`.
"""
function LobattoLegendre(p::Int, T=Float64)
    if p == 0
        nodes = T[0]
        weights = T[2]
    else
        nodes, weights = map(Vector{T}, gausslobatto(p+1))
    end
    baryweights = barycentric_weights(nodes)
    D = derivative_matrix(nodes, baryweights)
    LobattoLegendre(nodes, weights, baryweights, D)
end

function Base.show{T}(io::IO, basis::LobattoLegendre{T})
  print(io, "LobattoLegendre{", T, "}: Nodal Lobatto Legendre basis of degree ",
            degree(basis))
end


"""
    GaussLegendre{T<:Real}

The nodal basis corresponding to Legendre Gauss quadrature in [-1,1]
with scalar type `T`.
"""
struct GaussLegendre{T<:Real} <: NodalBasis{Line}
    nodes::Vector{T}
    weights::Vector{T}
    baryweights::Vector{T}
    D::Matrix{T}

    function GaussLegendre(nodes::Vector{T}, weights::Vector{T}, baryweights::Vector{T}, D::Matrix{T}) where T
        @assert length(nodes) == length(weights) == length(baryweights) == size(D,1) == size(D,2)
        new{T}(nodes, weights, baryweights, D)
    end
end

"""
    GaussLegendre(p::Int, T=Float64)

Generate the `GaussLegendre` basis of degree `p` with scalar type `T`.
"""
function GaussLegendre(p::Int, T=Float64)
    nodes, weights = map(Vector{T}, gausslegendre(p+1))
    baryweights = barycentric_weights(nodes)
    D = derivative_matrix(nodes, baryweights)
    GaussLegendre(nodes, weights, baryweights, D)
end

function Base.show{T}(io::IO, basis::GaussLegendre{T})
  print(io, "GaussLegendre{", T, "}: Nodal Gauss Legendre basis of degree ",
            degree(basis))
end
