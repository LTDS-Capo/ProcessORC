`timescale 1ns / 1ps
module TopLevelReset_tb ();
	localparam CYCLELIMIT = 160;
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
		$display("FlagGen   - En:Rst:Init  - %0b:%0b:%0b", clk_en_out, sync_rst_out, init_out);
		//                                    //
		$display("<>><>><>><> CycleCount - Hex     (%0h) ", CycleCount);
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



	//               //

	//                    //
	// Supporting Modules //	
	//                    //



	//                    //


endmodule