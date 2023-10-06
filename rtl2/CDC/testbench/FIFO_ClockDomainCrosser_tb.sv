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
            $display("Cycle[%0d] -  IN - REQ:ACK:Data - %0b:%0b:%0h", CycleCount, InputREQ, InputACK, InputData);
            $display("Cycle[%0d] - OUT - REQ:ACK:Data - %0b:%0b:%0h", CycleCount, OutputREQ, OutputACK, OutputData);
            $display(" ^ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ^");
	end

	// Set to zero to disable rundown counter
	assign RundownTrigger = 1'b0;

	// Useful signals	
	wire clk_en = CycleCount > 8;
	wire sync_rst = ((CycleCount > 1) && (CycleCount < 4));
    wire Init = CycleCount == 10;

	//               //
	// Module Tested //	
	//               //
        wire            InputClk = clk;
        // wire            InputClk = CycleCount[0];
        wire            InputREQ = ((CycleCount > 11) && (CycleCount < 96));
        wire            InputACK;
        wire      [7:0] InputData = CycleCount[7:0];

        wire            OutputClk = CycleCount[0];
        // wire            OutputClk = clk;
        wire            OutputREQ;
        wire            OutputACK = 1'b1;
        wire      [7:0] OutputData;
        FIFO_ClockDomainCrosser #(
            .BITWIDTH  (8),
            .DEPTH     (16),
            .TESTENABLE(0)
        ) CDC_FIFO (
            .rst    (sync_rst),
            .w_clk  (InputClk),
            .dInACK (InputREQ),
            .dInREQ (InputACK),
            .dIN    (InputData),
            .r_clk  (OutputClk),
            .dOutACK(OutputREQ),
            .dOutREQ(OutputACK),
            .dOUT   (OutputData)
        );
	//               //

	//                    //
	// Supporting Modules //	
	//                    //

	//                    //

endmodule