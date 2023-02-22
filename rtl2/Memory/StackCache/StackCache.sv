// Cache lines are 256bit (32Byte)
module StackCache #(
    parameter DATABITWIDTH = 32,
    parameter CACHELINEBYTESIZE = 32,
    parameter CACHELINEBITWIDTH = CACHELINEBYTESIZE*8
)(
    input clk,
    input clk_en,
    input sync_rst,

    input                          CacheLineInREQ,
    input                          CacheLineInACK,
    input  [CACHELINEBITWIDTH-1:0] CacheLineInData,

    input                          CacheLineOutREQ,
    input                          CacheLineOutACK,
    input  [CACHELINEBITWIDTH-1:0] CacheLineOutData,

    input                   [31:0] StackUpperBound,
    input                   [31:0] StackLowerBound,
    input                          StackDirection, // 0 - Grows Down with Push, 1 - Grows Up with Push

    input                   [31:0] StackPointerIn,
    output                  [31:0] StackPointerOut,
    input                          StackPointerSwap, // Force Cache Flush and Fetch

    output      [DATABITWIDTH-1:0] GPR14DataOut,
    output                         GPR14Dirty,
    output                         GPR14ForwardEnable,
    output                         GPR14CacheMissStall, // Write Side stall vs Read side stall (Dirty)
    input                          InstructionValid,
    input                          VariableTimedInstruction, // Set when the incoming instruction has a Major Opcode of 2, 3, or 6
    input                          StackPop, // When GPR14 is use as Operand B
    input                          StackPeak, // When GPR14 is used as an A operand (Except Move) - Marked Dirty until write
    input                          StackPush, // When GPR14 is used as A operand of a Move - Mark Dirty until write (Disable Forwards)

    input       [DATABITWIDTH-1:0] GPR14LoopDataIn,
    input                          DataLoopWriteEn,
    
    input       [DATABITWIDTH-1:0] GPR14LoadDataIn,
    input                          LoadWriteEn,
);

    // Holds upto 4 Cache Lines at once. Starts with 2 when fetching a new Stack, current Line

    // Push/Pop/Peak Queue, shows the last 2 cycles actions
    // Always mark Dirty if an access will cause a Cache Miss

    // Stack Pointer [Head]
        // Stack Pointer Queue (Write Address Queue that matches forward depth)

    //                                       //
    // Example Stack Pointers all start at 10 (Assume Push goes Down)
    //! 1st,  2nd,  3rd
    // Enable Forward when Ever you have a Pop or Peak within 2 operations of the last.
    //                                       //
    // Push, Push, Push - 10,  9,  8,  7
    // Push, Push,  Pop - 10,  9,  8,  9*
    // Push,  Pop, Push - 10,  9, 10*,  9
    // Push,  Pop,  Pop - 10,  9, 10*, 11*
    //  Pop,  Pop, Push - 10, 11, 12, 11
    //  Pop, Push,  Pop - 10, 11, 10, 11
    //  Pop, Push, Push - 10, 11, 10,  9
    //  Pop,  Pop,  Pop - 10, 11, 12, 13
    //                                       //
    //  Pop,  Pop,  Pop - 10, 11, 12, 13
    //  Pop,  Pop, Peak - 10, 11, 12, 12*
    //  Pop, Peak,  Pop - 10, 
    //  Pop, Peak, Peak - 
    // Peak, Peak,  Pop - 
    // Peak,  Pop, Peak - 
    // Peak,  Pop,  Pop - 
    // Peak, Peak, Peak - 
    //                                       //
    // Push, Push, Push - 
    // Push, Push, Peak - 
    // Push, Peak, Push - 
    // Push, Peak, Peak - 
    // Peak, Peak, Push - 
    // Peak, Push, Peak - 
    // Peak, Push, Push - 
    // Peak, Peak, Peak - 
    //                                       //

    // GPR 14 State
        // Short Delay - For Major Opcodes that are NOT 2, 3, or 6
        // Needs support for two deep forwarding/Address Checking


        // ToDo: Change ShortDirty to CacheMissWait
        wire GPR14ShortDirty = ; // Conditionally on
        // Long Delay - For Major Opcodes that are 2, 3, or 6
        reg  GPR14LongDirty;
        wire NextGPR14LongDirty = ~sync_rst && (StackPeak || StackPush);
        wire GPR14LongDirtyTrigger = sync_rst || (clk_en && InstructionValid) || (clk_en && LoadWriteEn);
        always_ff @(posedge clk) begin
            if (GPR14LongDirtyTrigger) begin
                GPR14LongDirty <= NextGPR14LongDirty;
            end
        end
        assign GPR14Dirty = GPR14LongDirty || GPR14ShortDirty;
    //


    // Cache State
        reg  [31:0] StackPointer;
        wire [31:0] NextStackPointer = sync_rst ? '0 : +-1; // todo
        wire StackPointerTrigger = sync_rst || (clk_en && );
        always_ff @(posedge clk) begin
            if (StackPointerTrigger) begin
                StackPointer <= NextStackPointer;
            end
        end
        




endmodule : StackCache