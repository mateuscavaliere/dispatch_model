#       ------------------------------------------------
#                  Defining general functions 
#       ------------------------------------------------

#--- w_Log: Function to write the log ---
function w_Log( msg::String, path::String , flagConsole::Int = 1, flagLog::Int = 1 , logName = "dispatch.log" , wType = "a" )
    
    if flagLog == 1
        logFile = open( joinpath( path , logName ) , wType )
        write( logFile , string( msg , "\n" ) )
        Base.close( logFile )
    end

    if flagConsole == 1
        Base.print( string( msg , "\n" ) )
    end

    return nothing
end

#--- stringConv: Function to convert read strings to another type ---
function string_converter( self::String , tipo::Type , msg::String ) 
    try
        parse( tipo , self )
    catch
        @show self
        error( msg )
    end
end;
function string_converter( self::SubString{String} , tipo::Type , msg::String ) 
    try
        parse( tipo , self )
    catch
        @show self
        error( msg )
    end
end;

#--- getPaths: Function to get paths ---
function get_paths( path::String = pwd() )
    
    local aux_path::String
    local path_case::String
    
    try
        aux_path = readlines( joinpath( path , "path.dat" ) )[2][27:end]
    catch
        Base.print("  ERROR: File not found (path.dat)")
        exit()
    end
    
    if is_windows()
        path_case  = normpath( string( aux_path, "\\") ) ;
    else    
        path_case  = normpath( string( aux_path, "/") );
    end

    if isdir( path_case ) == false
        Base.print("  ERROR: Directory doesnt exist $(path_case)")
        exit()
    end

    return path_case
end

#--- getvalue: Function to get value from model and symbol ---
function getvalue( model::JuMP.Model, s::Symbol )
    JuMP.getvalue(JuMP.getindex(model, s))
end

#--------------------------------------------------------
#----           Functions to read data base          ----
#--------------------------------------------------------

#--- read_options: Function to read model options ---
function read_options( path::String , file_name::String = "dispatch.dat" )
    
    #---------------------------
    #---  Defining variables ---
    #---------------------------

    local iofile::IOStream                  # Local variable to buffer connection to gencos.dat file
    local iodata::Array{String,1}           # Local variable to buffer information from read gencos.dat file
    local i::Int                            # Local variable to loop over informations
    local flag_res::Int                     # Local variable to buffer reserve option
    local flag_ang::Int                     # Local variable to buffer angular diff option
    local flag_cont::Int                 # Local variable to buffer contingency option

    #---------------------------------
    #--- Reading file (gencos.dat) ---
    #---------------------------------

    iofile = open( joinpath( path , file_name ) , "r" )
    iodata = readlines( iofile );
    Base.close( iofile )

    #-----------------------
    #--- Assigning data  ---
    #-----------------------
    
    flag_ang  = string_converter( iodata[1][27:30]  , Int , "Invalid entry for angular diff option")
    flag_res  = string_converter( iodata[2][27:30]  , Int , "Invalid entry for reserve option")
    flag_cont = string_converter( iodata[3][27:30]  , Int , "Invalid entry for contingency option")
    cont_crit = string_converter( iodata[4][27:30]  , Int , "Invalid entry for contingency criteria option")

    #- Checking user input consistency

    #- Reserve option
    if (flag_res != 0) & (flag_res != 1)

        exit()
    end

    #- Angular diff option
    if (flag_ang != 0) & (flag_ang != 1)

        exit()
    end

    #- Contingency option
    if (flag_cont != 0) & (flag_cont != 1) & (flag_cont != 2) & (flag_cont != 3)

        exit()
    end

    return( flag_res , flag_ang , flag_cont, cont_crit )
end 

#--- read_gencos: Function to read generators configuration ---
function read_gencos( path::String , file_name::String = "gencos.dat")

    #---------------------------
    #---  Defining variables ---
    #---------------------------

    local iofile::IOStream                  # Local variable to buffer connection to gencos.dat file
    local u::Int                            # Local variable to loop over gencos 
    local nGen::Int                         # Local variable to buffer the number of gencos
    local gencos::Gencos                    # Local variable to buffer gencos information
    local class_format::Bool =false         # Local variable to check file format
    
    #---------------------------------
    #--- Reading file (gencos.dat) ---
    #---------------------------------
    iofile = open( joinpath( path , file_name ) , "r" )
    iodata = readlines( iofile );
    Base.close( iofile )

    #- Removing header
    iodata = iodata[2:end]

    if endswith(file_name, "csv")
        class_format = true
        iodata = map(x -> split(x, ","), iodata)
    end

    #-----------------------
    #--- Assigning data  ---
    #-----------------------

    #- Get the number of simulated gencos
    nGen = length( iodata )

    #- Create struct to buffer gencos information

    gencos           = Gencos()
    gencos.Num       = Array{Int}(nGen)
    gencos.Name      = Array{String}(nGen)
    gencos.Bus       = Array{Int}(nGen)
    gencos.Pot       = Array{Float64}(nGen)
    gencos.CVU       = Array{Float64}(nGen)
    gencos.RUp       = Array{Float64}(nGen)
    gencos.RDown     = Array{Float64}(nGen)
    gencos.RUpCost   = Array{Float64}(nGen)
    gencos.RDownCost = Array{Float64}(nGen)

    #- Looping over the read information from gencos.dat 
    for u in 1:nGen
        if class_format
            
            gencos.Num[u]       = u
            gencos.Name[u]      = string( u )
            gencos.Bus[u]       = string_converter( iodata[u][3]  , Int     , "Invalid entry for the GENCO bus")
            gencos.Pot[u]       = string_converter( iodata[u][1]  , Float64 , "Invalid entry for the max pot of GENCO")
            gencos.CVU[u]       = string_converter( iodata[u][2]  , Float64 , "Invalid entry for the GENCO CVU")
            gencos.RUp[u]       = string_converter( iodata[u][6]  , Float64 , "Invalid entry for the GENCO reserve up")
            gencos.RDown[u]     = string_converter( iodata[u][7]  , Float64 , "Invalid entry for the GENCO reserve down")
            gencos.RUpCost[u]   = string_converter( iodata[u][4]  , Float64 , "Invalid entry for the GENCO reserve up cost")
            gencos.RDownCost[u] = string_converter( iodata[u][5]  , Float64 , "Invalid entry for the GENCO reserve down cost")
        else
            gencos.Num[u]       = string_converter( iodata[u][1:4]  , Int , "Invalid entry for the number of GENCO")
            gencos.Name[u]      = strip( iodata[u][6:17] )
            gencos.Bus[u]       = string_converter( iodata[u][19:22]  , Int     , "Invalid entry for the GENCO bus")
            gencos.Pot[u]       = string_converter( iodata[u][24:31]  , Float64 , "Invalid entry for the max pot of GENCO")
            gencos.CVU[u]       = string_converter( iodata[u][33:40]  , Float64 , "Invalid entry for the GENCO CVU")
            gencos.RUp[u]       = string_converter( iodata[u][42:49]  , Float64 , "Invalid entry for the GENCO reserve up")
            gencos.RDown[u]     = string_converter( iodata[u][51:58]  , Float64 , "Invalid entry for the GENCO reserve down")
            gencos.RUpCost[u]   = string_converter( iodata[u][60:71]  , Float64 , "Invalid entry for the GENCO reserve up cost")
            gencos.RDownCost[u] = string_converter( iodata[u][73:84]  , Float64 , "Invalid entry for the GENCO reserve down cost")
        end

    end

    return( nGen , gencos )

end

#--- read_demands: Function to read demands configuration ---
function read_demands( path::String , file_name::String = "demand.dat")

    #---------------------------
    #---  Defining variables ---
    #---------------------------

    local iofile::IOStream                  # Local variable to buffer connection to demands.dat file
    local iodata::Array{String,1}           # Local variable to buffer information from read demands.dat file
    local d::Int                            # Local variable to loop over loads 
    local nDem::Int                         # Local variable to buffer the number of demands
    local demands::Demands                  # Local variable to buffer demands information
    local class_format::Bool =false         # Local variable to check file format
    
    #---------------------------------
    #--- Reading file (demand.dat) ---
    #---------------------------------

    iofile = open( joinpath( path , file_name ) , "r" )
    iodata = readlines( iofile );
    Base.close( iofile )

    #- Removing header
    iodata = iodata[2:end]

    if endswith(file_name, "csv")
        class_format = true
    end

    #-----------------------
    #--- Assigning data  ---
    #-----------------------

    #- Get the number of simulated gencos
    nDem = length( iodata )

    #- Create struct to buffer gencos information

    demands      = Demands()
    demands.Num  = Array{Int}(nDem)
    demands.Name = Array{String}(nDem)
    demands.Bus  = Array{Int}(nDem)
    demands.Dem  = Array{Float64}(nDem)

    #- Looping over the read information from gencos.dat 
    for d in 1:nDem
        if class_format
            demands.Num[d]  = d 
            demands.Name[d] = string( d ) 
            demands.Bus[d]  = d
            demands.Dem[d]  = string_converter( string(iodata[d])  , Float64 , "Invalid entry for the load of DEMAND") 
        else
            demands.Num[d]  = string_converter( iodata[d][1:4]  , Int , "Invalid entry for the number of DEMAND")  
            demands.Name[d] = strip( iodata[d][6:17] ) 
            demands.Bus[d]  = string_converter( iodata[d][19:22]  , Int     , "Invalid entry for the DEMAND bus") 
            demands.Dem[d]  = string_converter( iodata[d][24:31]  , Float64 , "Invalid entry for the load of DEMAND") 
        end
    end

    return( nDem , demands )
end

#--- read_circuits: Function to read circuits configuration ---
function read_circuits( path::String , file_name::String = "circs.dat")

    #---------------------------
    #---  Defining variables ---
    #---------------------------

    local iofile::IOStream                  # Local variable to buffer connection to circs.dat file
    local l::Int                            # Local variable to loop over circuits 
    local nGen::Int                         # Local variable to buffer the number of circuits
    local circuits::Circuits                # Local variable to buffer circuits information
    local class_format::Bool =false         # Local variable to check file format
    
    #---------------------------------
    #--- Reading file (gencos.dat) ---
    #---------------------------------

    iofile = open( joinpath( path , file_name ) , "r" )
    iodata = readlines( iofile );
    Base.close( iofile )

    #- Removing header
    iodata = iodata[2:end]

    if endswith(file_name, "csv")
        class_format = true
        iodata = map(x -> split(x, ","), iodata)
    end

    #-----------------------
    #--- Assigning data  ---
    #-----------------------

    #- Get the number of simulated gencos
    nCir = length( iodata )

    #- Create struct to buffer gencos information

    circuits         = Circuits()
    circuits.Num     = Array{Int}(nCir)
    circuits.Name    = Array{String}(nCir)
    circuits.Cap     = Array{Float64}(nCir)
    circuits.Reat    = Array{Float64}(nCir)
    circuits.BusFrom = Array{Int}(nCir)
    circuits.BusTo   = Array{Int}(nCir)
    

    #- Looping over the read information from circs.dat 
    for l in 1:nCir
        if class_format    
            circuits.Num[l]      = l
            circuits.Name[l]     = string( l )
            circuits.Cap[l]      = string_converter( string(iodata[l][1])  , Float64 , "Invalid entry for the CIRCUIT capacity" )
            circuits.Reat[l]     = string_converter( string(iodata[l][2])  , Float64 , "Invalid entry for the CIRCUIT reactance" )
            circuits.BusFrom[l]  = string_converter( string(iodata[l][3])  , Int     , "Invalid entry for the CIRCUIT bus from" )
            circuits.BusTo[l]    = string_converter( string(iodata[l][4])  , Int     , "Invalid entry for the CIRCUIT bus to" )
        
        else
            circuits.Num[l]      = string_converter( iodata[l][1:4]  , Int , "Invalid entry for the number of CIRCUIT")
            circuits.Name[l]     = strip( iodata[l][6:17] )
            circuits.Cap[l]      = string_converter( iodata[l][19:26]  , Float64 , "Invalid entry for the CIRCUIT capacity" )
            circuits.Reat[l]     = string_converter( iodata[l][28:35]  , Float64 , "Invalid entry for the CIRCUIT reactance" )
            circuits.BusFrom[l]  = string_converter( iodata[l][37:40]  , Int     , "Invalid entry for the CIRCUIT bus from" )
            circuits.BusTo[l]    = string_converter( iodata[l][42:45]  , Int     , "Invalid entry for the CIRCUIT bus to" )
        end

    end

    return( nCir , circuits )

end

#--- read_buses: Function to read buses configuration ---
function read_buses( path::String , file_name::String = "buses.dat")

    #---------------------------
    #---  Defining variables ---
    #---------------------------

    local iofile::IOStream                  # Local variable to buffer connection to buses.dat file
    local iodata::Array{String,1}           # Local variable to buffer information from read buses.dat file
    local b::Int                            # Local variable to loop over buses 
    local nGen::Int                         # Local variable to buffer the number of buses
    local buses::Buses                      # Local variable to buffer buses information
   
    #---------------------------------
    #--- Reading file (gencos.dat) ---
    #---------------------------------

    iofile = open( joinpath( path , file_name ) , "r" )
    iodata = readlines( iofile );
    Base.close( iofile )

    #- Removing header
    iodata = iodata[2:end]

    #-----------------------
    #--- Assigning data  ---
    #-----------------------

    #- Get the number of simulated gencos
    nBus = length( iodata )

    #- Create struct to buffer gencos information

    buses         = Buses()
    buses.Num     = Array{Int}(nBus)
    buses.Name    = Array{String}(nBus)

    #- Looping over the read information from circs.dat 
    for b in 1:nBus

        buses.Num[b]      = string_converter( iodata[b][1:4]  , Int , "Invalid entry for the number of BUS")
        buses.Name[b]     = strip( iodata[b][6:17] )
    
    end

    return( nBus , buses )

end

#--- read_data_base: Function to load all data base ---
function read_data_base( path::String )

    CASE = Case();

    #---- Loading case configuration ----
    w_Log("     SDDP configuration", path );
    CASE.Flag_Res , CASE.Flag_Ang , CASE.Flag_Cont , CASE.nCont = read_options(  path );

    #---- Loading generators configuration ----
    w_Log("     Generators configuration", path );
    CASE.nGen , GENCOS                             = read_gencos(   path );

    #---- Loading loads configuration ----
    w_Log("     Loads configuration", path );
    CASE.nDem , DEMANDS                            = read_demands(  path );

    #---- Loading circuits configuration ----
    w_Log("     Circuits configuration", path );
    CASE.nCir , CIRCUITS                           = read_circuits( path );

    #---- Loading buses configuration ----
    w_Log("     Buses configuration", path );
    CASE.nBus , BUSES                              = read_buses(    path );
    
    #---- set number of contingency scenarios
    if CASE.Flag_Cont == 0 
        CASE.nContScen, CASE.ag, CASE.al = 0, ones(CASE.nGen, 1), ones(CASE.nCir, 1)
    else

        CASE.nContScen, CASE.ag, CASE.al = get_contingency_scenarios(CASE.nCir, CASE.nGen, CASE.nCont, CASE.Flag_Cont)
    end
    
    return ( CASE , GENCOS , DEMANDS , CIRCUITS , BUSES )
end

function read_data_base_class_format( path::String )

    CASE = Case();

    #---- Loading case configuration ----
    w_Log("     SDDP configuration", path );
    CASE.Flag_Res , CASE.Flag_Ang , CASE.Flag_Cont = read_options(  path );

    #---- Loading generators configuration ----
    w_Log("     Generators configuration", path );
    CASE.nGen , GENCOS                             = read_gencos(   path, "INPUT_GEN.csv" );

    #---- Loading loads configuration ----
    w_Log("     Loads configuration", path );
    CASE.nDem , DEMANDS                            = read_demands(  path, "INPUT_BUS.csv" );

    #---- Loading circuits configuration ----
    w_Log("     Circuits configuration", path );
    CASE.nCir , CIRCUITS                           = read_circuits( path, "INPUT_LIN.csv" );

    #---- Loading buses configuration ----
    w_Log("     Buses configuration", path );
    CASE.nBus = CASE.nDem
    BUSES = Buses()
    BUSES.Num     = collect(1:CASE.nBus)
    BUSES.Name    = map(string, collect(1:CASE.nBus))
    
     #---- set number of contingencies
     CASE.nCont = CASE.Flag_Res

     #---- set number of contingency scenarios
     if CASE.Flag_Cont == 0 
        CASE.nContScen, CASE.ag, CASE.al = 0, ones(CASE.nGen, 1), ones(CASE.nCir, 1)
    else

        CASE.nContScen, CASE.ag, CASE.al = get_contingency_scenarios(CASE.nCir, CASE.nGen, CASE.nCont, CASE.Flag_Cont)
    end

    return ( CASE , GENCOS , DEMANDS , CIRCUITS , BUSES )
end

#--- calculates number of contingency scenarios
function get_contingency_scenarios(nCir::Int64, nGen::Int64, nCont::Int64, criteria::Int)
    local nCen::Int64 = 0 # number of contingency scenarios
    local nTotal::Int64 = 0 #nCir + nGen 
   
    if criteria == 1
        nTotal += nCir + nGen  
    elseif criteria == 2
        nTotal += nGen  
    elseif  criteria == 3
        nTotal += nCir  
    end

    for c in 1:nCont
        nCen += binomial(nTotal, c)
    end

    ag = ones(Int, nCen+1,nGen)
    al = ones(Int, nCen+1,nCir)
    # build array of permutation vectors for each scenario  
    linha = 0
    for c in 0:nCont  
        #--- reset contingencies to match criteria G+T, T or G
        
        if criteria == 1 # G+T
            n_zeros = c
            n_ones = nTotal - c
            v = [ones(Int64, n_ones); zeros(Int64, n_zeros)]
            per = unique(permutations(v))
            for (idx,i) in enumerate(per)
                linha += 1
                ag[linha,:] = i[1:nGen]
                al[linha,:] = i[nGen+1:nTotal]
            end
        elseif criteria == 2 # G
            n_zeros = c
            n_ones = nGen - c
            v = [ones(Int64, n_ones); zeros(Int64, n_zeros)]
            per = unique(permutations(v))
            for (idx,i) in enumerate(per)
                linha += 1
                ag[linha,:] = i[1:nGen]
            end
        elseif criteria == 3 # T
            n_zeros = c
            n_ones = nCir - c
            v = [ones(Int64, n_ones); zeros(Int64, n_zeros)]
            per = unique(permutations(v))
            for (idx,i) in enumerate(per)
                linha += 1
                al[linha,:] = i[1:nCir]
            end
        end
    end

    return nCen, ag', al'
end


# todo parsing street
#-----------------------------------------------------
#----           Functions to build model          ----
#-----------------------------------------------------

#--- create_model: This function creates the JuMP model and its variables ---
function create_model( case::Case )
    
    #---------------------------
    #---  Defining variables ---
    #---------------------------

    local myModel::JuMP.Model                  # Local variable to create optmization model

    #-----------------------
    #---  Creating model ---
    #-----------------------

    myModel = Model( solver = ClpSolver( ) );

    @variable(myModel, f[1:case.nCir, 1:(case.nContScen+1)] );
    @variable(myModel, g[1:case.nGen, 1:(case.nContScen+1)] >= 0);
    @variable(myModel, delta[1:case.nBus, 1:(case.nContScen+1)] >= 0);

    if case.Flag_Ang == 1
        @variable(myModel, theta[1:case.nBus, 1:(case.nContScen+1)]);
        # @constraint( myModel , theta[1] == 0 )
    end

    if case.Flag_Res == 1
        @variable(myModel, rup[1:case.nGen] >= 0);
        @variable(myModel, rdown[1:case.nGen] >= 0);
    end

    return( myModel)
end

#--- add_grid_constraint!: This function creates the maximum and minimum flow constraint ---
function add_grid_constraint!( model::JuMP.Model , case::Case , circuits::Circuits )

    #---------------------------
    #---  Defining variables ---
    #---------------------------

    local l::Int                                        # Local variable to loop over lines
    
    local f::Array{JuMP.Variable,2}                     # Local variable to represent flow decision variable
    # local al::Array{Int,2}                          # Local variable to represent contingency
 
    #- Assigning values

    f = model[:f]
    al = case.al

    #-----------------------------------------
    #---  Adding constraints in the model  ---
    #-----------------------------------------
    @constraint( model , max_circ_cap[l=1:case.nCir,c=1:(case.nContScen+1)], f[l,c]  <= circuits.Cap[l] * al[l,c])
    @constraint( model, min_circ_cap[l=1:case.nCir,c=1:(case.nContScen+1)], -circuits.Cap[l] * al[l,c] <= f[l,c]  )
end

#--- add_angle_constraint!: This function creates the angle diff constraint ---
function add_angle_constraint!( model::JuMP.Model , case::Case , circuits::Circuits )

    #---------------------------
    #---  Defining variables ---
    #---------------------------

    local l::Int                                    # Local variable to loop over lines

    local f::Array{JuMP.Variable,2}                 # Local variable to represent flow decision variable of model
    local theta::Array{JuMP.Variable,2}                 # Local variable to represent angle decision variable of model
    local al::Array{Int,2}                          # Local variable to represent contingency

    local angle_lag::Array{JuMP.ConstraintRef,2}    # Local variable to represent angle lag constraint reference
    
    #- Assigning values

    f = model[:f]
    theta = model[:theta]
    al = case.al

    #-----------------------------------------
    #---  Adding constraints in the model  ---
    #-----------------------------------------
    @constraint( model , angle_lag[l=1:case.nCir, c=1:(case.nContScen+1)], f[l,c] == ( al[l,c] / circuits.Reat[l] ) * ( theta[circuits.BusFrom[l],c] - theta[circuits.BusTo[l],c] ) )
end

#--- add_gen_constraint!: This function creates the maximum and minimum generation constraint ---
function add_gen_constraint!( model::JuMP.Model , case::Case , generators::Gencos )

    #---------------------------
    #---  Defining variables ---
    #---------------------------

    local u::Int                                    # Local variable to loop over generators
    
    local g::Array{JuMP.Variable,2}                 # Local variable to represent generation decision variable
    local rup::Array{JuMP.Variable,1}               # Local variable to represent reserve up decision variable
    local rdown::Array{JuMP.Variable,1}             # Local variable to represent reserve down decision variable
     
    local max_gen::Array{JuMP.ConstraintRef,1}      # Local variable to represent maximum generation constraint reference
    local min_gen::Array{JuMP.ConstraintRef,1}      # Local variable to represent minimum generation constraint reference

    #- Assigning values

    g = model[:g]

    if case.Flag_Res == 1
        rup   = model[:rup]
        rdown = model[:rdown]
    end
    
    #-----------------------------------------
    #---  Adding constraints in the model  ---
    #-----------------------------------------
    
    if case.Flag_Res == 1
        @constraint(model, max_gen[u=1:case.nGen],   g[u,1] + rup[u] <= generators.Pot[u] )

        @constraint(model, min_gen[u=1:case.nGen],  0 <=  g[u,1] - rdown[u] )
    else
        @constraint(model, max_gen[u=1:case.nGen],   g[u,1] <= generators.Pot[u] )
        # @constraint(model, min_gen[u=1:case.nGen],  0 <= g[u])
    end
end

#--- add_reserve_constraint!: This function creates the maximum and minimum reserve constraint ---
function add_reserve_constraint!( model::JuMP.Model , case::Case , generators::Gencos )

    #---------------------------
    #---  Defining variables ---
    #---------------------------

    local u::Int                                    # Local variable to loop over generators
    
    local rup::Array{JuMP.Variable,1}               # Local variable to represent reserve up decision variable
    local rdown::Array{JuMP.Variable,1}             # Local variable to represent reserve down decision variable
    
    local max_rup::Array{JuMP.ConstraintRef,1}      # Local variable to represent maximum reserve up constraint reference
    local max_rdown::Array{JuMP.ConstraintRef,1}    # Local variable to represent maximum reserve down constraint reference

    #- Assigning values

    rup   = model[:rup]
    rdown = model[:rdown]
    
    #-----------------------------------------
    #---  Adding constraints in the model  ---
    #-----------------------------------------

    @constraint(model, max_rup[u=1:case.nGen],  rup[u] <= generators.RUp[u] )
    @constraint(model, max_rdown[u=1:case.nGen], rdown[u] <= generators.RDown[u] )
end

#--- add_load_balance_constraint!: This function creates the load balance constraint ---
function add_load_balance_constraint!( model::JuMP.Model , case::Case , generators::Gencos , circuits::Circuits , demands::Demands )

    #---------------------------
    #---  Defining variables ---
    #---------------------------

    local u::Int                                                    # Local variable to loop over generators
    local l::Int                                                    # Local variable to loop over lines
    local b::Int                                                    # Local variable to loop over buses
    local d::Int                                                    # Local variable to loop over demands

    local g::Array{JuMP.Variable,2}                                 # Local variable to represent generation decision variable
    local f::Array{JuMP.Variable,2}                                 # Local variable to represent flow decision variable
    local delta::Array{JuMP.Variable,2}                                 # Local variable to represent deficit variable

    local load_balance::Array{JuMP.ConstraintRef,2}                 # Local variable to represent load balance constraint reference

    #- Assigning values

    g = model[:g]
    f = model[:f]
    delta = model[:delta]

    #-----------------------------------------
    #---  Adding constraints in the model  ---
    #-----------------------------------------    
    @constraint(model, load_balance[b=1:case.nBus, c=1:(case.nContScen+1)], 
    + sum(g[u,c] for u in 1:case.nGen if generators.Bus[u] == b) 
    + sum(f[l,c] for l in 1:case.nCir if circuits.BusTo[l] == b)
    - sum(f[l,c] for l in 1:case.nCir if circuits.BusFrom[l] == b)
    + delta[b,c]
    ==  sum(demands.Dem[d] for d in 1:case.nDem if demands.Bus[d] == b) 
    )
    
end

#--- add_contingency_constraint!: this function creates the contingency constraint
function add_contingency_constraint!( model::JuMP.Model , case::Case , generators::Gencos )
    
    #---------------------------
    #---  Defining variables ---
    #---------------------------

    local u::Int                                    # Local variable to loop over generators
    
    local g::Array{JuMP.Variable,2}                 # Local variable to represent generation decision variable
    local rup::Array{JuMP.Variable,1}               # Local variable to represent reserve up decision variable
    local rdown::Array{JuMP.Variable,1}             # Local variable to represent reserve down decision variable
     local ag::Array{Int,2}                          # Local variable to represent contingency variable
    
    #- Assigning values

    g = model[:g]
    ag = case.ag

    if case.Flag_Res == 1
        rup   = model[:rup]
        rdown = model[:rdown]
    end
    
    #-----------------------------------------
    #---  Adding constraints in the model  ---
    #-----------------------------------------
    @constraint(model, cont_max_gen[u=1:case.nGen,c=2:(case.nContScen+1)],   g[u,c] <= (g[u,1] + rup[u])*ag[u,c])
    
    @constraint(model, cont_min_gen[u=1:case.nGen,c=2:(case.nContScen+1)], (g[u,1] - rdown[u])*ag[u,c] <= g[u,c]) 
end
#--- add_obj_fun!: This function creates and append the objective function to the model ---
function add_obj_fun!( model::JuMP.Model , case::Case , generators::Gencos )

    #---------------------------
    #---  Defining variables ---
    #---------------------------

    local u::Int                                                    # Local variable to loop over generators
    
    local g::Array{JuMP.Variable,2}                                 # Local variable to represent generation decision variable
    local delta::Array{JuMP.Variable,2}                                 # Local variable to represent deficit decision variable
    local deltacost::Float64                                 # Local variable to represent deficit cost variable
    local rup::Array{JuMP.Variable,1}                               # Local variable to represent reserve up decision variable
    local rdown::Array{JuMP.Variable,1}                             # Local variable to represent reserve down decision variable

    local obj_fun::JuMP.GenericAffExpr{Float64,JuMP.Variable}       # Local variable to represent objective function
    local syst_cost::JuMP.GenericAffExpr{Float64,JuMP.Variable}     # Local variable to represent system total cost
    
    #- Assigning values

    g = model[:g]
    delta = model[:delta]
    deltacost = 10 * maximum(generators.CVU)

    if case.Flag_Res == 1
        rup   = model[:rup]
        rdown = model[:rdown]
    end

    #-----------------------------------
    #---  Adding objective function  ---
    #-----------------------------------

    obj_fun = 0

    if case.Flag_Res == 1
        @objective(  model , Min       , 
        + sum(g[u,1] * generators.CVU[u] for u in 1:case.nGen)
        + sum(rup[u] * generators.RUpCost[u] for u in 1:case.nGen)
        + sum(rdown[u] * generators.RDownCost[u] for u in 1:case.nGen)
        + sum(delta[b,c] * deltacost for b in 1:case.nBus, c in 1:case.nContScen)
        )
    else
        @objective(  model , Min       , 
        + sum(delta[b,c] * deltacost for b in 1:case.nBus, c in 1:case.nContScen)
        + sum(g[u,1] * generators.CVU[u] for u in 1:case.nGen)
        + sum(delta[b,c] * deltacost for b in 1:case.nBus, c in 1:case.nContScen)
        )
    end

    nothing
end

#--- solve_dispatch: This function calls the solver and write output into .log file ---
function solve_dispatch( path::String , model::JuMP.Model , case::Case , circuits::Circuits , generators::Gencos , buses::Buses )

    #---------------------------
    #---  Defining variables ---
    #---------------------------

    local b::Int                            # Local variable to loop over buses
    local u::Int                            # Local variable to loop over generators
    local l::Int                            # Local variable to loop over lines

    local status::Symbol                    # Local variable to represent optmization status

    local prices::Array{Float64}            # Local variable to buffer dual variable (prices) after optmization
    local generation::Array{Float64}        # Local variable to buffer optimal generation
    local cir_flow::Array{Float64}          # Local variable to buffer optimal circuit flow
    local res_up_gen::Array{Float64}        # Local variable to buffer optimal up reserve
    local res_down_gen::Array{Float64}      # Local variable to buffer optimal down reserve
    local bus_ang::Array{Float64}           # Local variable to buffer optimal angle diff


    #--- Creating optmization problem
    JuMP.build( model );

    #--- Solving optmization problem
    status = JuMP.solve( model );

    #--- Reporting results
    if status  == :Optimal

        prices = getdual(getindex(model, :load_balance))
        generation = getvalue( model, :g )
        cir_flow   = getvalue( model, :f )

        if case.Flag_Res == 1
            res_up_gen   = getvalue( model, :rup )
            res_down_gen = getvalue( model, :rdown )
        end
        
        if case.Flag_Ang == 1
            bus_ang = getvalue( model, :theta )
        end

        #--- Writing to log the optimal solution

        w_Log("\n     Optimal solution found!\n" , path )

        for b in 1:case.nBus
            w_Log("     Marginal cost for the bus $(buses.Name[b]): $(round(prices[b,1],2)) R\$/MWh" , path )
        end

        w_Log( " " , path )

        for u in 1:case.nGen
            w_Log("     Optimal generation of $(generators.Name[u]): $(round(generation[u,1],2)) MWh" , path )
        end

        w_Log( " " , path )

        for l in 1:case.nCir
            w_Log("     Optimal flow in line $(circuits.Name[l]): $(round(cir_flow[l,1],2)) MW" , path )
        end

        if case.Flag_Res == 1

            w_Log( " " , path )

            for u in 1:case.nGen
                w_Log("     Optimal Reserve Up of $(generators.Name[u]): $(round(res_up_gen[u],2)) MWh" , path )
            end

            w_Log( " " , path )

            for u in 1:case.nGen
                w_Log("     Optimal Reserve Down of $(generators.Name[u]): $(round(res_down_gen[u],2)) MWh" , path )
            end

        end

        if case.Flag_Ang == 1
            
            w_Log( " " , path )

            for b in 1:case.nBus
                w_Log("     Optimal bus angle $(buses.Name[b]): $(round(bus_ang[b,1],2)) grad" , path )
            end
        end
    

    defcit = getvalue( model, :delta )
    w_Log("\n    Total cost = $(round(getobjectivevalue(model),2))" ,  path)
    w_Log("\n    Total deficit = $(sum(defcit[:,1]))" ,  path)

    elseif status == :Infeasible
        
        w_Log("\n     No solution found!\n\n     This problem is Infeasible!" , path )
        w_Log("\n     $(case.ag)" , path )
        w_Log("\n     $(case.al)" , path )
    end

end

#--- build_dispatch: This function call all other functions associate with the dispatch optmization problem ---
function build_dispatch( path::String , case:: Case, circuits::Circuits , generators::Gencos , demands::Demands , buses::Buses )
    
    #--- Creating constraint ref
    CONSTR = Constr()

    #--- Creating optmization problem
    MODEL = create_model( case )

    #- Add grid constraints
    add_grid_constraint!(  MODEL , case , circuits )

    #- Add angle lag constraints

    if case.Flag_Ang == 1
        add_angle_constraint!( MODEL , case , circuits )
    end

    #- Add maximum and minimum generation constraints
    add_gen_constraint!( MODEL , case , generators )

    #- Add maximum and minimum reserve constraints

    if case.Flag_Res == 1
        add_reserve_constraint!( MODEL , case , generators )
    end

    #- Add load balance constraints
    add_load_balance_constraint!( MODEL , case , generators , circuits , demands )

    if case.Flag_Cont!=0
        add_contingency_constraint!(  MODEL , case , generators)
    end
    #- Add objetive function
    add_obj_fun!( MODEL , case , generators )

    #- Writing LP
    writeLP(MODEL, joinpath( path , "dispatch.lp") , genericnames = false)

    #- Build and solve optmization problem
    solve_dispatch( path , MODEL , case , circuits , generators , buses )
end

#------------------------------------------
#----           Main function          ----
#------------------------------------------

function dispatch( path::String, class_format::Bool )
    
    PATH_CASE = get_paths( path );

    #--- Remove preveous log file ---
    if isfile( joinpath( PATH_CASE , "dispatch.log" ) )
        rm( joinpath( PATH_CASE , "dispatch.log" ) )
    else
        w_Log( "" , PATH_CASE , 0 , 1 , "dispatch.log" , "w" )
    end

    w_Log( "\n  #-----------------------------------------#"            , PATH_CASE );
    w_Log( "  #              DISPATCH MODEL             #"              , PATH_CASE );
    w_Log( "  #-----------------------------------------#\n"            , PATH_CASE );
    w_Log( "  Execution date: $(Dates.format(now(),"dd-u-yyyy HH:MM"))" , PATH_CASE );
    w_Log( "  Directory:      $PATH_CASE \n"                            , PATH_CASE );

    #--------------------------------
    #----     Loading inputs     ----
    #--------------------------------

    w_Log( "  Loading inputs" , PATH_CASE );

    time_counter = @elapsed ( CASE , GENCOS , DEMANDS , CIRCUITS , BUSES ) = 
    
    if class_format
        read_data_base_class_format(PATH_CASE)
    else
        read_data_base( PATH_CASE );
    end

    w_Log( "\n  Loading data took $(round(time_counter,3)) seconds\n" , PATH_CASE );

    #--------------------------------------------------
    #----     Solving optimal dispatch problem     ----
    #--------------------------------------------------

    w_Log( "  Solving dispatch problem" , PATH_CASE );

    time_counter = @elapsed build_dispatch( PATH_CASE , CASE , CIRCUITS , GENCOS , DEMANDS , BUSES );

    w_Log( "\n  Optmization process took $(round(time_counter,3)) seconds" , PATH_CASE );

end