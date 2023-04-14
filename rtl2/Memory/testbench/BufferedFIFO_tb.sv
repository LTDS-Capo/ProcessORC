`timescale 1ns / 1ps
module BufferedFIFO_tb ();
	localparam CYCLELIMIT = 30;
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
	end

	// Set to zero to disable rundown counter
	assign RundownTrigger = 1'b0;

	// Useful signals	
	wire clk_en = CycleCount > 1;
	wire sync_rst = CycleCount == 1;

	//               //
	// Module Tested //	
	//               //
    localparam DATABITWIDTH = 16;
    localparam FIFODEPTH = 4;
    wire                    InputREQ = (CycleCount > 8) && (CycleCount < 22);
    wire                    InputACK;
    wire [DATABITWIDTH-1:0] InputData = CycleCount[DATABITWIDTH-1:0];
    wire                    OutputREQ;
    wire                    OutputACK = (CycleCount > 16);
    wire [DATABITWIDTH-1:0] OutputData;
        BufferedFIFO #(
            .DATABITWIDTH(DATABITWIDTH),
            .FIFODEPTH(FIFODEPTH)
        ) FIFO (
            .clk       (clk),
            .clk_en    (clk_en),
            .sync_rst  (sync_rst),
            .InputREQ  (InputREQ),
            .InputACK  (InputACK),
            .InputData (InputData),
            .OutputREQ (OutputREQ),
            .OutputACK (OutputACK),
            .OutputData(OutputData)
        );
	//               //

	//                    //
	// Supporting Modules //	
	//                    //



	//                    //

endmodule