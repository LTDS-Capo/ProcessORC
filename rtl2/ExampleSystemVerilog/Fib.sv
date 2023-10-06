module Fib #(
    parameter DATA_BITWIDTH = 32
)(
    input clk,
    input clk_en,
    input sync_rst,

    output [DATA_BITWIDTH-1:0] CurrentFib
);

//? Fibinachi buffer
    //                                                                       //
    //* Connections
    //                                                                       //
    //* Buffer Select
        reg  BufferSelect;
        wire NextBufferSelect = ~sync_rst && ~BufferSelect;
        wire BufferSelectTrigger = sync_rst || clk_en;
        always_ff @(posedge clk) begin
            if (BufferSelectTrigger) begin
                BufferSelect <= NextBufferSelect;
            end
        end
    //                                                                       //
    //* Buffer A
        reg  [DATA_BITWIDTH-1:0] FibBufferA;
        wire [DATA_BITWIDTH-1:0] NextFibBufferA = sync_rst ? {DATA_BITWIDTH{1'b0}} : (FibBufferA + FibBufferB);
        wire FibBufferATrigger = sync_rst || (clk_en && ~BufferSelect);
        always_ff @(posedge clk) begin
            if (FibBufferATrigger) begin
                FibBufferA <= NextFibBufferA;
            end
        end
    //                                                                       //
    //* Buffer B
        reg  [DATA_BITWIDTH-1:0] FibBufferB;
        wire [DATA_BITWIDTH-1:0] NextFibBufferB = sync_rst ? {{DATA_BITWIDTH-1{1'b0}}, 1'b1} : (FibBufferA + FibBufferB);
        wire FibBufferBTrigger = sync_rst || (clk_en && BufferSelect);
        always_ff @(posedge clk) begin
            if (FibBufferBTrigger) begin
                FibBufferB <= NextFibBufferB;
            end
        end
    //                                                                       //
//?

//? Output Assignments
    //                                                                       //
    //* Assignments
        assign CurrentFib = BufferSelect ? FibBufferB : FibBufferA;
    //                                                                       //
//?

endmodule : Fib
