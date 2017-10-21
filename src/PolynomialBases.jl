module PolynomialBases


using Parameters
using FastGaussQuadrature


abstract type AbstractDomain{Dim} end
struct Line <: AbstractDomain{1} end

abstract type AbstractBasis{Domain} end
abstract type NodalBasis{Domain} <: AbstractBasis{Domain} end


include("interpolation.jl")
include("integration.jl")
include("derivative.jl")
include("nodal_bases.jl")
include("legendre.jl")
include("jacobi.jl")
include("hahn.jl")

# types
export LobattoLegendre, GaussLegendre, GaussJacobi

# interpolation
export interpolate, interpolate!, interpolation_matrix, interpolation_matrix!,
        change_basis, change_basis!

# derivative
export derivative_at, derivative_at!, derivative_matrix, derivative_matrix!

# integration
export integrate

# Continuous orthogonal polynomials: Legendre, Jacobi
export legendre, legendre_vandermonde, legendre_D, legendre_M,
       jacobi, jacobi_vandermonde, jacobi_M

# Discrete orthogonal polynomials: Hahn
export hahn

# other utilities
export utility_matrices


end # module
