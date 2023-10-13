module StackCache #(
    parameter LINESIZE = 8,
    parameter DATABITWIDTH = 16,
    parameter CACHELINEBITWIDTH = LINESIZE*DATABITWIDTH,
    parameter PENDINGREADBITWIDTH = 8,
    //* Do Not Change During Instantiation
    parameter LINEADDRBITWIDTH = (LINESIZE == 1) ? 1 : $clog2(LINESIZE)
)(
    input clk,
    input clk_en,
    input sync_rst,

    output                            StackStall, // Stalls system
    output                            StackOverflowException, // Based on growth direction
    output                            StackUnderflowException, // Based on growth direction

    // TODO: Make a parameterizable Cache interface width
    output                            CacheLineInReadREQ,
    input                             CacheLineInReadACK,
    output                            CacheLineInReadEOT,
    output                     [31:0] CacheLineInReadMemLineAddr,

    input                             CacheLineInResponseREQ,
    output                            CacheLineInResponseACK,
    input                             CacheLineInResponseEOT,   
    input     [CACHELINEBITWIDTH-1:0] CacheLineInResponseData,

    output                            CacheLineOutREQ,
    input                             CacheLineOutACK,
    output                            CacheLineOutEOT,
    output                     [31:0] CacheLineOutMemLineAddr,
    output    [CACHELINEBITWIDTH-1:0] CacheLineOutData,

    input                             PrePop,
    input                             DirectionWE,
    input                             StackDirection, // 0 - Grows Down with Push, 1 - Grows Up with Push
    input                             UpperBoundWE,
    input                      [31:0] StackUpperBound, //* Always 32 bits due to CSRs
    input                             LowerBoundWE,
    input                      [31:0] StackLowerBound, //* Always 32 bits due to CSRs

    input                             StackPointerSwap, //! Initiate Stall for pending StackPointerWriteEn
    output                     [31:0] StackPointerOut, //* Always 32 bits due to CSRs

    // Runahead Interface
    input  [(LINEADDRBITWIDTH+2)-1:0] RunaheadSnoopIndex,
    output                            RunaheadIsDirty,

    //TODO: Stack Pick and Stack Place

    // Register Interface
    input                             InstructionValid, //! Uses ReadAddr
    input                             IsMove,
    input                             DirtyWrite,
    input                             DirtyIssue,
    input                             ToRunahead,
    input                             FromRunahead,
    input                             WritingTo,

    input                             Speculating,
    input                             EndSpeculationPulse,
    input                             MispredictedSpeculationPulse,

    input                             WritebackEn,
    input                             StackPointerWriteEn, // Force Cache Flush and Fetch
    input  [(LINEADDRBITWIDTH+2)-1:0] WritebackIndex,
    // input                      [31:0] StackPointerIn, //* Always 32 bits due to CSRs
    input          [DATABITWIDTH-1:0] WritebackData,

    input                             LoadWriteEn,
    input  [(LINEADDRBITWIDTH+2)-1:0] LoadWriteIndex,
    input          [DATABITWIDTH-1:0] LoadWriteData,

    input                             ReadEn,
    output         [DATABITWIDTH-1:0] ReadData
);

    //? Stack Pointer Behavior:
    //* 0 - SP Modify - *Pop*
        // Check if desired Cache Line is Valid
        // Increment Stack Pointer [Based on GrowthDirection] 
    //* 1 - SP Modify - *Push*
        // Check if desired Cache Line is Valid
        // Decrement Stack Pointer [Based on GrowthDirection]
    //* 2 - A Operand (Non-Move) - Peak & Replace 
        // Check if desired Cache Line is Valid
        // Check if desired Value is Not-Dirty
        // Read TOS
        // Assign Write Tag (Marks value dirty)
        // ~ Wait ~
        // Write value, clear Write Tag
    //* 3 - A Operand (Move)     - Push to Stack
        // Check if desired Cache Line is Valid
        // Check if desired Value is Not-Dirty
        // Assign Write Tag (Marks value dirty)
        // Decrement Stack Pointer [Based on GrowthDirection]
        // ~ Wait ~
        // Write value, clear Write Tag
//        // Check SP +1/-1 Line Status (Correct if not true)
    //* 4 - B Operand (Non-Move) - Pop
        // Check if desired Cache Line is Valid
        // Check if desired Value is Not-Dirty
        // Read TOS
        // Increment Stack Pointer [Based on GrowthDirection]
//        // Check SP +1/-1 Line Status (Correct if not true)
    //* 5 - B Operand (Move)     - Peak
        // Check if desired Cache Line is Valid
        // Check if desired Value is Not-Dirty
        // Read TOS
    //* 6 - Stack Pick           -
        // Check if desired Cache Line is Valid
        // Check if desired Value is Not-Dirty
        // Read desired Value
    //* 7 - Stack Place          -
        // Check if desired Cache Line is Valid
        // Check if desired Value is Not-Dirty
        // Assign Write Tag (Marks value dirty)
        // ~ Wait ~
        // Write value, clear Write Tag


    //? Required Functions
        //*  Key: X - Required, d - Dont Care
        //!  7, 6, 5, 4, 3, 2, 1, 0 : Order : Module : Task
        //   X, X, X, X, X, X, X, X :     1 :      A : Check Line Validity [Same as: Read, when ignoring the read output if not required]
        //   X, X, X, X, X, X, -, - :     1 :      B : Check Value Dirty Status
        //   -, X, X, X, d, X, d, d :     1 :      B : Read
        //   X, -, -, -, X, X, -, - : 1 ... :      B : Assign Write Tag & Mark Dirty [Same as: ~Wait AND Same as: Write, Clear Tag, & Mark Clean]
        //   -, -, -, X, -, -, -, X :     1 :      C : Increment Stack Pointer (Pop)
        //   -, -, -, -, X, -, X, - :     1 :      C : Decrement Stack Pointer (Push)
        //// X, -, -, -, X, X, -, - : ~ Wait
        //// X, -, -, -, X, X, -, - : Write, Clear Tag,b & Mark Clean

    //? Modules Needed:
    // Status: C - Complete, P - Pending, W - Work In Progress
    //  A: W - Line_StateMachine - For Line Validity
    //  B: C - Line              - To Read, Write, and Dirty Status Read/Modify
    //  C: C - Stack Pointer     - To generate Read and Write Addresses


endmodule : StackCache

