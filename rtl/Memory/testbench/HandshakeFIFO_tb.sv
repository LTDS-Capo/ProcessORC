`timescale 1ns / 1ps
module HandshakeFIFO_tb ();
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
	    $display("In  - REQ:ACK:Data - %0b:%0b:%04h", dInREQ, dInACK, dIN);
	    $display("Out - REQ:ACK:Data - %0b:%0b:%04h", dOutREQ, dOutACK, dOUT);
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

        wire        dInREQ;
        wire        dInACK = 0;//CycleCount[0];
        wire [15:0] dIN = CycleCount[15:0];
        wire        dOutREQ = ~CycleCount[0];
        wire        dOutACK;
        wire [15:0] dOUT; 
        HandshakeFIFO #(
            .DATABITWIDTH     (16),
            .FIFODEPTH        (4),
            .FIFODEPTHBITWIDTH(2)
        ) FIFO (
            .clk     (clk),
            .clk_en  (clk_en),
            .sync_rst(sync_rst),
            .dInREQ  (dInREQ),
            .dInACK  (dInACK),
            .dIN     (dIN),
            .dOutREQ (dOutREQ),
            .dOutACK (dOutACK),
            .dOUT    (dOUT)
        );
	//               //

	//                    //
	// Supporting Modules //	
	//                    //



	//                    //

endmodule