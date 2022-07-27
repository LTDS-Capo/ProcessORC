module DataSequencer #(
    parameter BITWIDTH = 4,
    parameter DEPTH = 2
)(
    input  clk,
    input  rst,
    input  [BITWIDTH-1:0] dIN,
    output [BITWIDTH-1:0] dOUT
);
    generate
        reg [BITWIDTH-1:0] SequenceBuffer [DEPTH-1:0];
        // Generate a number of buffers equal to DEPTH.
        genvar Step;
        for (Step = 0; Step < DEPTH; Step = (Step + 1)) begin : TheShitThatNeededAName
            // The first Buffer takes the data from the input.
            if (Step == 0) begin
                always_ff @( posedge clk or posedge rst ) begin
                    if (rst) begin
                        SequenceBuffer[Step] <= 0;
                    end
                    else begin
                        SequenceBuffer[Step] <= dIN;
                    end
                end
            end
            // All Buffers but the first one take data from the prior data.
            else begin
                always_ff @( posedge clk or posedge rst ) begin
                    if (rst) begin
                        SequenceBuffer[Step] <= 0;
                    end
                    else begin
                        SequenceBuffer[Step] <= SequenceBuffer[Step-1];
                    end
                end                
            end
        end
    endgenerate
    // The last buffer has its data out assigned to dOUT.
    assign dOUT = SequenceBuffer[DEPTH-1];
endmodule : DataSequencer