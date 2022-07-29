`timescale 1ns / 1ps
module TopLevelReset_FlagGen_tb ();
	localparam CYCLELIMIT = 70;
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
        $display("In  - SyncIn:RstTrig - %0b:%0b", SyncIn, sync_rst_Trigger);
		$display("Out - En:Rst:Init    - %0b:%0b:%0b", clk_en_out, sync_rst_out, init_out);
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

        wire sync_rst_Trigger = CycleCount == 38;
        wire SyncIn = SyncDelay;
        wire clk_en_out;
        wire sync_rst_out;
        wire init_out;

        reg  SyncDelay;
        wire SyncDetect = clk_en_out || sync_rst_out || init_out;
        wire SyncDelayTrigger = clk_en || sync_rst;
        wire NextSyncDelay = SyncDetect && ~sync_rst;
        always_ff @(posedge clk) begin
            if (SyncDelayTrigger) begin
                SyncDelay <= NextSyncDelay;
            end
        end

        TopLevelReset_FlagGen #(
            .RESETWAITCYCLES      (6),
            .OPERATIONALWAITCYCLES(8),
            .INITIALIZEWAITCYCLES (8),
            .CLOCKDOMAINS         (2)
        ) FlagGen (
            .clk             (clk),
            .clk_en          (clk_en),
            .async_rst_in     (sync_rst),
            .sync_rst_Trigger(sync_rst_Trigger),
            .SyncIn          (SyncIn),
            .clk_en_out      (clk_en_out),
            .sync_rst_out    (sync_rst_out),
            .init_out        (init_out)
        );
        
	//               //

endmodule