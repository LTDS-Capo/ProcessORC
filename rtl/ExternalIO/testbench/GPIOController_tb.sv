`timescale 1ns / 1ps
module GPIOController_tb ();
	localparam CYCLELIMIT = 17;
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
			$display("  IO - ACK:REQ:CMD:Reg:Mem - %0b:%0b:%0b:%0b:%0b", IO_ACK, IO_REQ, IO_CommandResponse, IO_RegResponseFlag, IO_MemResponseFlag);
			$display("  IO -           Dest:Data - %0h:%08b", IO_DestRegOut, IO_DataOut);
			$display("GPIO -              Out:En - %08b:%8b", GPIO_DOut, GPIO_DOutEn);
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
        wire        IO_ACK;
        wire        IO_REQ = (CycleCount > 7) &&  (CycleCount < 16);
        wire        IO_CommandEn = 1'b1;
        wire        IO_ResponseRequested = 1'b1;
        wire        IO_CommandResponse;
        wire        IO_RegResponseFlag;
        wire        IO_MemResponseFlag;
        wire  [3:0] IO_DestRegIn = 4'hF;
        wire  [3:0] IO_DestRegOut;
		// wire  [2:0] IOOperation = (CycleCount == 8) ? 3'h1 : 3'h6;
		wire  [2:0] IOOperation = 3'h7;
        wire [15:0] IO_DataIn = {CycleCount[2:0], IOOperation, 10'b00_0000_0011};
        wire [15:0] IO_DataOut;
        wire  [7:0] GPIO_DIn = 8'hA5;
        wire  [7:0] GPIO_DOut;
        wire  [7:0] GPIO_DOutEn;
        GPIOController GPIOInterface(
            .clk                 (clk),
            .clk_en              (clk_en),
            .sync_rst            (sync_rst),
            .IO_ACK              (IO_ACK),
            .IO_REQ              (IO_REQ),
            .IO_CommandEn        (IO_CommandEn),
            .IO_ResponseRequested(IO_ResponseRequested),
            .IO_CommandResponse  (IO_CommandResponse),
            .IO_RegResponseFlag  (IO_RegResponseFlag),
            .IO_MemResponseFlag  (IO_MemResponseFlag),
            .IO_DestRegIn        (IO_DestRegIn),
            .IO_DestRegOut       (IO_DestRegOut),
            .IO_DataIn           (IO_DataIn),
            .IO_DataOut          (IO_DataOut),
            .GPIO_DIn            (GPIO_DIn),
            .GPIO_DOut           (GPIO_DOut),
            .GPIO_DOutEn         (GPIO_DOutEn)
        );
	//               //

	//                    //
	// Supporting Modules //	
	//                    //



	//                    //

endmodule