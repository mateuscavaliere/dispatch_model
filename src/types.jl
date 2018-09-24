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