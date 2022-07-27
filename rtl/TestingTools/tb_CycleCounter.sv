module tb_CycleCounter #(
	parameter CYCLELIMIT = 256
)(
    input clk,
    input async_rst,

    output [63:0] CycleCount
);
    reg  [63:0] CycleCount;
	wire  CycleLimitReached = CycleCount == CYCLELIMIT;
	wire [63:0] NextCycleCount = CycleCount + 1;
	always_ff @(posedge clk or posedge async_rst) begin
		if (async_rst) begin
			CycleCount <= 0;
		end
		else begin
			CycleCount <= NextCycleCount;
		end
		if (CycleLimitReached) begin
			$display("><><><><><><><>< CYCLECOUNT ELAPSED! ><><><><><><><><");
			$finish;
		end
	end

endmodule

