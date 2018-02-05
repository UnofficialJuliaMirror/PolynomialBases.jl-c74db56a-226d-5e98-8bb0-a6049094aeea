using Base.Test, PolynomialBases
import StaticArrays

ufunc₁(x) = sinpi(x)
ufunc₂(x) = exp(sinpi(x))
ufunc₃(x) = cospi(x^2)^5

ufunc_svector(x) = StaticArrays.SVector(ufunc₁(x), ufunc₃(x))

function tolerance(p, ufunc::typeof(ufunc₁))
    if p <= 4
        1.
    elseif p <= 6
        0.03
    elseif p <= 8
        2.e-3
    elseif p <= 10
        5.e-5
    else
        2.e-7
    end
end
function tolerance(p, ufunc::typeof(ufunc₂))
    if p <= 4
        2.
    elseif p <= 6
        0.7
    elseif p <= 8
        0.2
    elseif p <= 10
        0.06
    else
        6.e-3
    end
end
function tolerance(p, ufunc::typeof(ufunc₃))
    if p <= 2
        2.
    elseif p <= 6
        0.75
    elseif p <= 8
        0.7
    elseif p <= 10
        0.4
    else
        0.06
    end
end

# some regression tests
for basis_type in subtypes(PolynomialBases.NodalBasis{PolynomialBases.Line})
    for ufc in (ufunc₁, ufunc₂, ufunc₃), p in 3:10, T in (Float32, Float64)
        basis = basis_type(p, T)
        u = ufc.(basis.nodes)
        u2 = compute_coefficients(ufc, basis)
        @test maximum(abs, u-u2) < 10*eps(T)
        xplot = linspace(-1, 1, 100)
        uplot = interpolate(xplot, u, basis)
        @test norm(ufc.(xplot) - uplot, Inf) < tolerance(p, ufc)
        xplot2, uplot2 = evaluate_coefficients(u, basis, length(xplot))
        @test maximum(abs, xplot-xplot2) < 10*eps(T)
        @test maximum(abs, uplot-uplot2) < 10*eps(T)
    end
end

# compare direct interpolation and matrix
for basis_type in subtypes(PolynomialBases.NodalBasis{PolynomialBases.Line})
    for ufc in (ufunc₁, ufunc₂, ufunc₃), p in 3:10, T in (Float32, Float64)
        basis = basis_type(p, T)
        u = ufc.(basis.nodes)
        xplot = linspace(-1, 1, 100)
        u1 = interpolate(xplot, u, basis)
        u2 = interpolation_matrix(xplot, basis) * u
        @test norm(u1 - u2) < 1.e-14
    end
end

# compare direct interpolation and interpolation vectors for GaussLegendre
for ufc in (ufunc₁, ufunc₂, ufunc₃), p in 1:10, T in (Float32, Float64)
    basis = GaussLegendre(p, T)
    u = ufc.(basis.nodes)
    x = T[-1, 1]
    u1 = interpolate(x, u, basis)
    u2 = similar(u1); u2[1] = dot(basis.interp_left, u); u2[2] = dot(basis.interp_right, u)
    @test norm(u1 - u2) < 5*eps(T)
end

# change of bases
for ufc in (ufunc₁, ufunc₂, ufunc₃), p in 3:10, T in (Float32, Float64)
    basis1 = LobattoLegendre(p, T)
    basis2 = GaussLegendre(p, T)

    u1 = ufc.(basis1.nodes)
    u2 = ufc.(basis2.nodes)

    u12 = change_basis(basis1, u2, basis2)
    u21 = change_basis(basis2, u1, basis1)

    xplot = linspace(-1, 1, 100)

    @test norm(interpolate(xplot,u1,basis1) - interpolate(xplot,u12,basis1), Inf) < tolerance(p, ufc)
    @test norm(interpolate(xplot,u2,basis2) - interpolate(xplot,u21,basis2), Inf) < tolerance(p, ufc)
end

# interpolate SVector
for T in (Float32,Float64)
    basis = GaussLegendre(5, T)
    u = compute_coefficients(ufunc_svector, basis)
    @inferred evaluate_coefficients(u, basis)
end
