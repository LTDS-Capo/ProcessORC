module StackCache #(
    parameter DATABITWIDTH = 16,
    parameter CACHELINEWIDTH = 8, //! Minimum 8
    parameter CACHELINEBITWIDTH = DATABITWIDTH * CACHELINEWIDTH
)(
    input clk,
    input clk_en,
    input sync_rst,

    input                          InstructionValid,
    input                          InstructionIsARunahead, // Already allocated to the Push Queue

    output                         ClearingSpeculationQueue, // Stalls system

    input                          CacheLineInREQ,
    output                         CacheLineInACK,
    input  [CACHELINEBITWIDTH-1:0] CacheLineInData,

    output                         CacheLineOutREQ,
    input                          CacheLineOutACK,
    output [CACHELINEBITWIDTH-1:0] CacheLineOutData,

    input                   [31:0] StackUpperBound, //* Always 32 bits due to CSRs
    input                   [31:0] StackLowerBound, //* Always 32 bits due to CSRs
    input                          StackDirection, // 0 - Grows Down with Push, 1 - Grows Up with Push

    input                   [31:0] StackPointerIn, //* Always 32 bits due to CSRs
    output                  [31:0] StackPointerOut, //* Always 32 bits due to CSRs
    input                          StackPointerSwap // Force Cache Flush and Fetch

);

    //? Cache Lines
        // Uses the same speculation roll-back system as the Register File
        StackCacheLines CacheLines (

        );
    //

    //? Write Tag Tracking
        StackCacheTagTracker TagTracking (

        );
    //

    // Have a mechanism to pre-write Pushes to Cache lines that are still being fetched
    // Check if new Stack Pointer is still within the cached range, only modify what is required

    //! CAN NOT EVICT ANY CACHE LINES WHEN SPECULATIONS!
    // Stall if an instructions requires a cache line that is not available when speculating

    // 4 bit tags
    //? Stack Pointer
        reg  [31:0] StackPointer;
        wire [31:0] StackPointerDelta = {{30{SOMECONDITION}}, 1'b1};
        wire [31:0] NextStackPointer = sync_rst ? 0 : (StackPointer + StackPointerDelta);
        wire StackPointerTrigger = sync_rst || (clk_en && );
        always_ff @(posedge clk) begin
            if (StackPointerTrigger) begin
                StackPointer <= NextStackPointer;
            end
        end
        wire [31:0] SPOffset = {{28{BOperandAddress[3]}}, BOperandAddress};
        wire [31:0] TrueStackPointer = PickOrPlace ? (StackPointer + SPOffset) : StackPointer;
    //

    //? Speculative Roll-Back Stack Pointer

    //


    //! Reads need to be tracked to, in case they are shifted into the Runahead Queue and the read happens at a later date
    

    //? Stack Pointer Behavior:
    //* SP Modify - *Pop*
        // Check if desired Cache Line is Valid
        // Increment Stack Pointer [Based on GrowthDirection] 
    //* SP Modify - *Push*
        // Check if desired Cache Line is Valid
        // Decrement Stack Pointer [Based on GrowthDirection]
    //* A Operand (Non-Move) - 
        // Check if desired Cache Line is Valid
        // Check if desired Value is Not-Dirty
        // Read TOS
        // Assign Write Tag (Marks value dirty)
        // ~ Wait ~
        // Write value, clear Write Tag
    //* A Operand (Move)     -
        // Check if desired Cache Line is Valid
        // Check if desired Value is Not-Dirty
        // Assign Write Tag (Marks value dirty)
        // Increment Stack Pointer [Based on GrowthDirection]
        // ~ Wait ~
        // Write value, clear Write Tag
        // Check SP +1/-1 Line Status (Correct if not true)
    //* B Operand (Non-Move) -
        // Check if desired Cache Line is Valid
        // Check if desired Value is Not-Dirty
        // Read TOS
        // Increment Stack Pointer [Based on GrowthDirection]
        // Check SP +1/-1 Line Status (Correct if not true)
    //* B Operand (Move)     -
        // Check if desired Cache Line is Valid
        // Check if desired Value is Not-Dirty
        // Read TOS
    //* Stack Pick           -
        // Check if desired Cache Line is Valid
        // Check if desired Value is Not-Dirty
        // Read desired Value
    //* Stack Place          -
        // Check if desired Cache Line is Valid
        // Check if desired Value is Not-Dirty
        // Assign Write Tag (Marks value dirty)
        // ~ Wait ~
        // Write value, clear Write Tag



endmodule : StackCache

