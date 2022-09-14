`timescale 1ns / 1ps
module MemoryFlasher_tb ();
	localparam CYCLELIMIT = 1300;
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
			$display("IEn:DEn:SEn - %0b:%0b:%0b", InstFlashEn, DataFlashEn, SystemEn);
			$display("  Data:Addr - %04h:%03d", FlashData, FlashAddr);
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
        wire        FlashInit = CycleCount == 4;
        wire        InstFlashEn;
        wire        DataFlashEn;
        wire  [9:0] FlashAddr;
        wire [15:0] FlashData;
        wire        SystemEn;
        MemoryFlasher #(
            .MEMMAPSTARTADDR(384),
            .MEMMAPENDADDR(511)
        )Flasher (
            .clk         (clk),
            .clk_en      (clk_en),
            .sync_rst    (sync_rst),
            .FlashInit   (FlashInit),
            .InstFlashEn (InstFlashEn),
            .DataFlashEn (DataFlashEn),
            .FlashAddr   (FlashAddr),
            .FlashData   (FlashData),
            .SystemEnable(SystemEn)
        );
	//               //

	//                    //
	// Supporting Modules //	
	//                    //



	//                    //

endmodule