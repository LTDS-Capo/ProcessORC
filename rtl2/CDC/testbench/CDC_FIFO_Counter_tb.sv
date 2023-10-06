`timescale 1ns / 1ps
module CDC_FIFO_TopLevel_tb ();
	localparam CYCLELIMIT = 140;
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
            $display("Cycle[%0d] - Handshake -      REQ:ACK - %0b:%0b", CycleCount, CountREQ, CountACK);
            $display("Cycle[%0d] -    Counts - Opp:Bin:Grey - %0d:%0d:%05b", CycleCount, OpposingGreyCounter, CountBinary, CountGrey);
            $display(" ^ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ^");
	end

	// Set to zero to disable rundown counter
	assign RundownTrigger = 1'b0;

	// Useful signals	
	wire clk_en = CycleCount > 1;
	wire sync_rst = CycleCount == 1;
    wire Init = CycleCount == 3;

	//               //
	// Module Tested //	
	//               //
        wire            CountREQ = ((CycleCount > 3) && (CycleCount < 96));
        wire            CountACK;

        parameter DEPTH_BITWIDTH = $clog2(16);
        wire   [DEPTH_BITWIDTH:0] OpposingGreyCounter = 0;
        wire [DEPTH_BITWIDTH-1:0] CountBinary;
        wire   [DEPTH_BITWIDTH:0] CountGrey;

        CDC_FIFO_Counter #(
            .DEPTH            (16),
            .FULL_EN          (1)
        ) CDC_Counter (
            .clk                (clk),
            .async_rst          (sync_rst),
            .CountREQ           (CountREQ),
            .CountACK           (CountACK),
            .OpposingGreyCounter(OpposingGreyCounter),
            .CountBinary        (CountBinary),
            .CountGrey          (CountGrey)
        );
	//               //

	//                    //
	// Supporting Modules //	
	//                    //

	//                    //

endmodule