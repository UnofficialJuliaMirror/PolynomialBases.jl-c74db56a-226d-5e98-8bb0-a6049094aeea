"""
    SavedValues{tType<:Real, savevalType}

A struct used to save values of the time in `t::Vector{tType}` and
additional values in `saveval::Vector{savevalType}`.
"""
struct SavedValues{tType<:Real, savevalType}
    t::Vector{tType}
    saveval::Vector{savevalType}
end

"""
    SavedValues(tType::DataType, savevalType::DataType)

Return `SavedValues{tType, savevalType}` with empty storage vectors.
"""
function SavedValues(tType::DataType, savevalType::DataType)
    SavedValues{tType, savevalType}(Vector{tType}(), Vector{savevalType}())
end

function Base.show(io::IO, saved_values::SavedValues)
    tType = eltype(saved_values.t)
    savevalType = eltype(saved_values.saveval)
    print(io, "SavedValues{tType=", tType, ", savevalType=", savevalType, "}",
                "\nt:\n", saved_values.t, "\nsaveval:\n", saved_values.saveval)
end

@recipe function plot(saved_values::SavedValues)
    DiffEqArray(saved_values.t, saved_values.saveval)
end


mutable struct SavingAffect{SaveFunc, tType, savevalType, saveatType}
    save_func::SaveFunc
    saved_values::SavedValues{tType, savevalType}
    saveat::saveatType
    save_everystep::Bool
    saveiter::Int
end

function (affect!::SavingAffect)(integrator)
    # see OrdinaryDiffEq.jl -> integrator_utils.jl, function savevalues!
    while !isempty(affect!.saveat) && integrator.tdir*top(affect!.saveat) <= integrator.tdir*integrator.t # Perform saveat
        affect!.saveiter += 1
        curt = pop!(affect!.saveat) # current time
        if curt != integrator.t # If <t, interpolate
            ode_addsteps!(integrator)
            Θ = (curt - integrator.tprev)/integrator.dt
            curu = ode_interpolant(Θ, integrator, nothing, Val{0}) # out of place, but no force copy later
            copyat_or_push!(affect!.saved_values.t, affect!.saveiter, curt)
            copyat_or_push!(affect!.saved_values.saveval, affect!.saveiter, affect!.save_func(curt, curu, integrator))
        else # ==t, just save
            copyat_or_push!(affect!.saved_values.t, affect!.saveiter, integrator.t)
            copyat_or_push!(affect!.saved_values.saveval, affect!.saveiter, affect!.save_func(integrator.t, integrator.u, integrator))
        end
    end
    if affect!.save_everystep
        affect!.saveiter += 1
        copyat_or_push!(affect!.saved_values.t, affect!.saveiter, integrator.t)
        copyat_or_push!(affect!.saved_values.saveval, affect!.saveiter, affect!.save_func(integrator.t, integrator.u, integrator))
    end
    u_modified!(integrator, false)
end

function saving_initialize(cb, t, u, integrator)
  cb.affect!(integrator)
end


"""
    SavingCallback(save_func, saved_values::SavedValues;
                    saveat=Vector{eltype(saved_values.t)}(),
                    save_everystep=isempty(saveat),
                    tdir=1)

A `DiscreteCallback` applied after every step, saving the time `t` and the value
of `save_func(t, u, integrator)` in `saved_values`.

If `save_everystep`, every step of the integrator is saved.
If `saveat` is specified, the values are saved at the given times, using
interpolation if necessary.
If the time `tdir` direction is not positive, i.e. `tspan[1] > tspan[2]`,
`tdir = -1` has to be specified.
"""
function SavingCallback(save_func, saved_values::SavedValues;
                        saveat=Vector{eltype(saved_values.t)}(),
                        save_everystep=isempty(saveat),
                        tdir=1)
    # saveat conversions, see OrdinaryDiffEq.jl -> integrators/type.jl
    saveat_vec = collect(saveat)
    if tdir > 0
        saveat_internal = binary_minheap(saveat_vec)
    else
        saveat_internal = binary_maxheap(saveat_vec)
    end
    affect! = SavingAffect(save_func, saved_values, saveat_internal, save_everystep, 0)
    condtion = (t, u, integrator) -> true
    DiscreteCallback(condtion, affect!;
                     initialize = saving_initialize,
                     save_positions=(false,false))
end


export SavingCallback, SavedValues
