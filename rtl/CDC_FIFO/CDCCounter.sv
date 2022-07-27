//* VALIDATED *//
module CDCCounter #(
    parameter DEPTH = 4,

    // If 1; do modified comparison to check for a Full condition.
    // If 0; do normal comparison to check for a Empty condition. 
        // Modified Comparison is .
    parameter FULLCHECK = 1
)(
    input  clk,
    input  rst,
    input  Count_en,
    input  [($clog2(DEPTH)):0] ComparisonPointer,
    output PointerMatch,
    output [($clog2(DEPTH)):0] GreyPointer,
    output [(($clog2(DEPTH))-1):0] BinaryPointer
);
    // Calculate local parameters
    localparam ADDRWIDTH = $clog2(DEPTH);

    // Binary Counter and Update procedure
    reg  [ADDRWIDTH:0] Count = 0;
    wire [ADDRWIDTH:0] NextCount = Count + 1;

    // Grey Counter and Update procedure
    reg  [ADDRWIDTH:0] GreyCount;
    wire [ADDRWIDTH:0] NextGreyCount = (NextCount >> 1) ^ NextCount;

    // Conditionaly invert upper bit of Comparison pointer
        // This makes the system check for FIFO Full rather than Empty.
    wire [ADDRWIDTH:0] ComparisonValue = FULLCHECK ? {(~ComparisonPointer[ADDRWIDTH:ADDRWIDTH-1]),ComparisonPointer[ADDRWIDTH-2:0]}: ComparisonPointer;

    // Define latch behavior
    wire Advance = Count_en;
    always_ff @( posedge clk or posedge rst ) begin
            if (rst) begin
            Count <= 0;
            GreyCount <= 0;
        end
        else if (Advance) begin
            Count <= NextCount;
            GreyCount <= NextGreyCount;
        end
    end

    // Assign outputs
    assign PointerMatch = (GreyPointer == ComparisonValue);
    assign BinaryPointer = Count[ADDRWIDTH-1:0];
    assign GreyPointer = GreyCount;

endmodule