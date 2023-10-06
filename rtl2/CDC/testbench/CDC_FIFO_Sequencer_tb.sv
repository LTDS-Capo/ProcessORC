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
            $display("Cycle[%0d] -  IN - Clk:Data - %0b:%0h", CycleCount, InputClk, InputData);
            $display("Cycle[%0d] - OUT - Clk:Data - %0b:%0h", CycleCount, OutputClk, OutputData);
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
        wire      [7:0] InputData = CycleCount[7:0];

        wire            OutputClk = CycleCount[0];
        wire      [7:0] OutputData;
        CDC_FIFO_Sequencer #(
            .DATA_BITWIDTH    (8),
            .INPUT_DEPTH      (1),
            .OUTPUT_DEPTH     (3)
        ) CDC_FIFO (
            .async_rst (sync_rst),
            .InputClk  (InputClk),
            .InputData (InputData),
            .OutputClk (OutputClk),
            .OutputData(OutputData)
        );
	//               //

	//                    //
	// Supporting Modules //	
	//                    //

	//                    //

endmodule