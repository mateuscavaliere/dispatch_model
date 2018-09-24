


#--- w_Log: Function to write the log ---
function w_Log( msg::String, path::String , flagConsole::Int = 1, flagLog::Int = 1 , logName = "cmgdem_pld.log" , wType = "a" )
    
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

#--- read_gencos: Function to read generators configuration ---
function read_gencos( path::String , file_name::String = "gencos.dat")

    #---------------------------
    #---  Defining variables ---
    #---------------------------

    local iofile::IOStream                  # Local variable to buffer connection to gencos.dat file
    local iodata::Array{String,1}           # Local variable to buffer information from read gencos.dat file
    local u::Int                            # Local variable to loop over gencos 
    local nGen::Int                         # Local variable to buffer the number of gencos
    local gencos::Gencos                    # Local variable to buffer gencos information

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

    #---------------------------------
    #--- Reading file (demand.dat) ---
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
    nDem = length( iodata )

    #- Create struct to buffer gencos information

    demands      = Demands()
    demands.Num  = Array{Int}(nDem)
    demands.Name = Array{String}(nDem)
    demands.Bus  = Array{Int}(nDem)
    demands.Dem  = Array{Float64}(nDem)

    #- Looping over the read information from gencos.dat 
    for d in 1:nDem

        demands.Num[d]  = string_converter( iodata[d][1:4]  , Int , "Invalid entry for the number of DEMAND")  
        demands.Name[d] = strip( iodata[d][6:17] ) 
        demands.Bus[d]  = string_converter( iodata[d][19:22]  , Int     , "Invalid entry for the DEMAND bus") 
        demands.Dem[d]  = string_converter( iodata[d][24:31]  , Float64 , "Invalid entry for the load of DEMAND") 

    end

    return( nDem , demands )

end

#--- read_circuits: Function to read circuits configuration ---
function read_circuits( path::String , file_name::String = "circs.dat")

    #---------------------------
    #---  Defining variables ---
    #---------------------------

    local iofile::IOStream                  # Local variable to buffer connection to circs.dat file
    local iodata::Array{String,1}           # Local variable to buffer information from read circs.dat file
    local l::Int                            # Local variable to loop over circuits 
    local nGen::Int                         # Local variable to buffer the number of circuits
    local circuits::Circuits                # Local variable to buffer circuits information

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

        circuits.Num[l]      = string_converter( iodata[l][1:4]  , Int , "Invalid entry for the number of CIRCUIT")
        circuits.Name[l]     = strip( iodata[l][6:17] )
        circuits.Cap[l]      = string_converter( iodata[l][19:26]  , Float64 , "Invalid entry for the CIRCUIT capacity" )
        circuits.Reat[l]     = string_converter( iodata[l][28:35]  , Float64 , "Invalid entry for the CIRCUIT reactance" )
        circuits.BusFrom[l]  = string_converter( iodata[l][37:40]  , Int     , "Invalid entry for the CIRCUIT bus from" )
        circuits.BusTo[l]    = string_converter( iodata[l][42:45]  , Int     , "Invalid entry for the CIRCUIT bus to" )

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

    CASE.nGen , GENCOS   = read_gencos(   path );
    CASE.nDem , DEMANDS  = read_demands(  path );
    CASE.nCir , CIRCUITS = read_circuits( path );
    CASE.nBus , BUSES    = read_buses(    path );

    return ( CASE , GENCOS , DEMANDS , CIRCUITS , BUSES )

end