#       ------------------------------------------------
#                      Defining functions 
#       ------------------------------------------------

include( joinpath( dirname(@__FILE__) , "read_database.jl" ) )
include( joinpath( dirname(@__FILE__) , "build_model.jl"   ) )

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
    JuMP.getvalue( JuMP.getindex( model , s ) )
end

#--- get_contingency_scenarios: Function to create arrays with contingencies scenarios based on users input ----
function get_contingency_scenarios( case::Case )
    
    #---------------------------
    #---  Defining variables ---
    #---------------------------

    local k::Int            # Local variable to loop over contingency scenarios
    local nCen::Int         # Local variable to buffer the number of contingency scenarios
    local nElements::Int    # Local variable to buffer number of elements that are in the contingency arrays
    local n_zeros::Int      # Auxiliar variable
    local n_ones::Int       # Auxiliar variable
    local linha::Int        # Auxiliar variable

    local ag::Array{Int}    # Local variable to buffer the array with contingency scenarios for generators
    local al::Array{Int}    # Local variable to buffer the array with contingency scenarios for circuits

    #-------------------------------
    #--- Interpreting the inputs ---
    #-------------------------------

    #--- Checking if there is no contingency to test
    if case.Flag_Cont == 0
        return( 0 , ones( case.nGen , 1 ) , ones( case.nCir , 1 ) )
    end

    #--- Get the number of elements to create contingency arrays
    if case.Flag_Cont == 1
        nElements = case.nCir + case.nGen  
    elseif case.Flag_Cont == 2
        nElements = case.nGen          
    elseif case.Flag_Cont == 3
        nElements = case.nCir
    end

    #--- Get the number of possible combinations
    for k in 1:case.Flag_nCont
        nCen = binomial(nElements, k)
    end

    #-------------------------------------------------------------
    #--- Build array of permutation vectors for each scenario  ---
    #-------------------------------------------------------------

    ag = ones( Int, nCen+1 , case.nGen )
    al = ones( Int, nCen+1 , case.nCir )
    
    linha = 0

    for k in 0:case.Flag_nCont  
        
        #- Reset contingencies to match criteria G+T, T or G
        
        if case.Flag_Cont == 1 # G+T
            
            n_zeros = k
            n_ones  = nElements - k
            v       = [ ones( Int , n_ones ) ; zeros( Int , n_zeros ) ]
            per     = unique( multiset_permutations( v , nElements ) )

            for ( idx , i ) in enumerate( per )
                linha += 1
                ag[linha,:] = i[1:case.nGen]
                al[linha,:] = i[case.nGen+1:nElements]
            end

        elseif case.Flag_Cont == 2 # G

            n_zeros = k
            n_ones  = case.nGen - k
            v       = [ ones( Int , n_ones ) ; zeros( Int , n_zeros ) ]
            per     = unique(multiset_permutations(v, nElements))

            for ( idx , i ) in enumerate(per)
                linha += 1
                ag[linha,:] = i[1:case.nGen]
            end

        elseif case.Flag_Cont == 3 # T

            n_zeros = k
            n_ones  = case.nCir - k
            v       = [ ones( Int , n_ones ) ; zeros( Int , n_zeros )]
            per     = unique( multiset_permutations( v , nElements ) )

            for ( idx , i ) in enumerate( per )
                linha += 1
                al[linha,:] = i[1:case.nCir]
            end

        end
    end

    return( nCen , ag' , al' )
end

#--- write_outputs: Function to write output as .csv ----
function write_outputs(file_name::String, file_path::String, values::Array{Float64}, agents::Array{String})
    file_full_path = joinpath(file_path, file_name)

    # open file stream
    fstream = open(file_full_path, "w")

    # writes file header
    write(fstream, "Hour," * join(agents, ",") * "\n")
    
    # get number of lines
    n_agents, n_lines = size(values)
    for line in 1:n_lines
        for agent in 1:n_agents
            write(fstream,  "$(line),$(values[agent,line]),")
        end
        # goto next line
        write(fstream, "\n")
    end

    # closes file stream
    close(fstream)
end

#--- read_data_base: Function to load all data base ---
function read_data_base( path::String )

    CASE = Case();

    #---- Loading case configuration ----
    w_Log("     Case configuration", path );
    CASE.Flag_Res , CASE.Flag_Ang , CASE.Flag_Cont , CASE.Flag_nCont , CASE.nStages = read_options(  path );

    #---- Loading buses configuration ----
    w_Log("     Buses configuration", path );
    CASE.nBus , BUSES                              = read_buses(    path );

    #---- Loading generators configuration ----
    w_Log("     Generators configuration", path );
    CASE.nGen , GENCOS                                                          = read_gencos(      path , CASE , BUSES );
    GENCOS.InitCommit , GENCOS.InitGen , GENCOS.InitOffTime , GENCOS.InitOnTime = read_init_commit( path , CASE         );

    #---- Loading loads configuration ----
    w_Log("     Loads configuration", path );
    CASE.nDem , DEMANDS = read_demands(  path , CASE , BUSES );

    #---- Loading circuits configuration ----
    w_Log("     Circuits configuration", path );
    CASE.nCir , CIRCUITS                           = read_circuits( path , BUSES );

    return ( CASE , GENCOS , DEMANDS , CIRCUITS , BUSES )
end

#--- build_dispatch: This function call all other functions associate with the dispatch optmization problem ---
function build_dispatch( path::String , case:: Case, circuits::Circuits , generators::Gencos , demands::Demands , buses::Buses )
    
    #--- Creating constraint ref
    CONSTR = Constr()

    #---- Set number of contingency scenarios ----
    case.nContScen, case.ag, case.al = get_contingency_scenarios( case )

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

    add_unit_commitment( MODEL , case , generators )
    add_ramping_constraint( MODEL , case , generators )
    add_updowntime_constraint( MODEL , case , generators )
    add_startupcost_shutdowncost_constraint( MODEL , case , generators)

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

function main( path::String )
    
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

    time_counter = @elapsed ( CASE , GENCOS , DEMANDS , CIRCUITS , BUSES ) = read_data_base( PATH_CASE );

    w_Log( "\n  Loading data took $(round(time_counter,3)) seconds\n" , PATH_CASE );

    #--------------------------------------------------
    #----     Solving optimal dispatch problem     ----
    #--------------------------------------------------

    w_Log( "  Solving dispatch problem" , PATH_CASE );

    time_counter = @elapsed build_dispatch( PATH_CASE , CASE , CIRCUITS , GENCOS , DEMANDS , BUSES );

    w_Log( "\n  Optmization process took $(round(time_counter,3)) seconds" , PATH_CASE );

end