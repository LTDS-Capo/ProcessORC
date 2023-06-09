module StackCache_EvictionControl #(
    parameter 
)(
    input clk,
    input clk_en,
    input sync_rst,

    
);

    //? 

    //? Types of evictions
    // -> Prefectching
    // -> Cache Miss (Running faster than prefetcher)
    // -> Stack Pointer Swap (FulL Flush)

endmodule : StackCache_EvictionControl