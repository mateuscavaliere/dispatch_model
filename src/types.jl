#       ------------------------------------------------
#            Defining types to be used in the model
#       ------------------------------------------------

#--- Gencos: Struct to buffer the gencos config
mutable struct Case
    Name::String;
    nGen::Int
    nBus::Int
    nDem::Int
    nCir::Int
    Flag_Ang::Int
    Flag_Res::Int
    Flag_Cont::Int
    Case() = new();
end

#--- Gencos: Struct to buffer the gencos config
mutable struct Gencos
    Num::Array{Int};
    Name::Array{String};
    Bus::Array{Int}
    Pot::Array{Float64}
    CVU::Array{Float64}
    RUp::Array{Float64}
    RDown::Array{Float64}
    RUpCost::Array{Float64}
    RDownCost::Array{Float64}
    Gencos() = new();
end

#--- Demands: Struct to buffer the demands config
mutable struct Demands
    Num::Array{Int};
    Name::Array{String};
    Bus::Array{Int}
    Dem::Array{Float64}
    Demands() = new();
end


#--- Circuits: Struct to buffer the circuits config
mutable struct Circuits
    Num::Array{Int};
    Name::Array{String};
    Cap::Array{Float64}
    Reat::Array{Float64}
    BusFrom::Array{Int};
    BusTo::Array{Int};
    Circuits() = new();
end

#--- Circuits: Struct to buffer the circuits config
mutable struct Buses
    Num::Array{Int};
    Name::Array{String};
    Buses() = new();
end

#--- Circuits: Struct to buffer the optmization constranits
mutable struct Constr
    max_circ_cap::Array{JuMP.ConstraintRef,1}; 
    min_circ_cap::Array{JuMP.ConstraintRef,1};
    angle_lag::Array{JuMP.ConstraintRef,1};
    max_gen::Array{JuMP.ConstraintRef,1};
    min_gen::Array{JuMP.ConstraintRef,1};
    max_rup::Array{JuMP.ConstraintRef,1};
    max_rdown::Array{JuMP.ConstraintRef,1};
    load_balance::Array{JuMP.ConstraintRef,1};
    Constr() = new();
end