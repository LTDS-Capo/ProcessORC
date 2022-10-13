`timescale 1ns / 1ps
module Example_tb ();
	localparam CYCLELIMIT = 32;
	localparam RUNDOWNCYCLECOUNT = 8;

	// clk and async_rst Initialization
	reg clk = 0;
	reg async_rst = 0;
	initial begin
		#10 async_rst = 1;
		#10 async_rst = 0;
	end
	always #50 clk = !clk;

	// Cycle Counter
	wire [63:0] CycleCount;
	tb_CycleCounter #(
		.CYCLELIMIT(CYCLELIMIT)
	) CycleCounter (
		.clk       (clk),
		.async_rst (async_rst),
		.CycleCount(CycleCount)
	);

	// Rundown System
	wire RundownTrigger;
	tb_RundownCounter #(
		.RUNDOWNCYCLECOUNT(RUNDOWNCYCLECOUNT)
	) RundownCounter (
		.clk		   (clk),
		.async_rst	   (async_rst),
		.RundownTrigger(RundownTrigger)
	);

	always_ff @(posedge clk) begin
		//                                    //
		// Toplevel debug $display statements //	
		//                                    //
		$display("PortACKVector:PortSelection - %013b:%0h", PortACKVector, PortSelection);
		//                                    //
		$display("<>><>><>><> CycleCount - Decimal (%0d) ", CycleCount);
		$display("^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^");
	end

	// Set to zero to disable rundown counter
	assign RundownTrigger = 1'b0;

	// Useful signals	
	wire clk_en = CycleCount > 1;
	wire sync_rst = CycleCount == 1;

	//               //
	// Module Tested //	
	//               //
	logic [12:0] DecodedCount;
	always_comb begin
		DecodedCount = '0;
		DecodedCount[CycleCount[3:0]] = 1'b1;
	end

	// wire [12:0] PortACKVector = DecodedCount;
	wire [12:0] PortACKVector = 13'h0010;
	wire  [3:0] PortSelection;
    RoundRobin #(
        .PORTCOUNT    (13),
        .PORTADDRWIDTH(4),
		.ROUNDROBINEN(1)
    ) RRPortPriority (
        .clk          (clk),
        .clk_en       (clk_en),
        .sync_rst     (sync_rst),
        .PortACKVector(PortACKVector),
        .PortSelection(PortSelection)
    );
	//               //

	//                    //
	// Supporting Modules //	
	//                    //



	//                    //

endmodule
