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
    nCont::Int
    nContScen::Int
    nStages::Int
    ag::Array{Int,2}
    al::Array{Int,2}
    Flag_Ang::Int
    Flag_Res::Int
    Flag_Cont::Int
    Flag_nCont::Int
    Case() = new();
end

#--- Gencos: Struct to buffer the gencos config
mutable struct Gencos
    Num::Array{Int};
    Name::Array{String};
    Bus::Array{Int}
    
    PotMin::Array{Float64}
    PotMax::Array{Float64}
    PotPat1::Array{Float64}
    PotPat2::Array{Float64}
    
    StartUpRamp::Array{Float64}
    RampUp::Array{Float64}
    ShutdownRamp::Array{Float64}
    RampDown::Array{Float64}
    ReserveUp::Array{Float64}
    ReserveDown::Array{Float64}

    UpTime::Array{Int}
    DownTime::Array{Int}

    CVU::Array{Float64}
    CVUPat1::Array{Float64}
    CVUPat2::Array{Float64}
    CVUPat3::Array{Float64}

    StartUpCost_1::Array{Float64}
    StartUpCost_2::Array{Float64}
    StartUpCost_3::Array{Float64}
    ShutdownCost::Array{Float64}
    ReserveUpCost::Array{Float64}
    ReserveDownCost::Array{Float64}

    Gencos() = new();
end

#--- Demands: Struct to buffer the demands config
mutable struct Demands
    Num::Array{Int};
    Name::Array{String};
    Bus::Array{Int}
    Dem::Array{Float64}
    Profile::Array{Float64}
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