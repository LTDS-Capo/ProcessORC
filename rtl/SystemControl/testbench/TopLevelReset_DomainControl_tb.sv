`timescale 1ns / 1ps
module TopLevelReset_DomainControl_tb ();
	localparam CYCLELIMIT = 165;
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
        $display("DomFlag   - syncrsttrig  - %0b", sync_rst_trigger);
        $display("DomainIn  - Clk:SyncTrig - %0b:%0b", target_clk, target_sync_rst_trigger);
        $display("Domain    - SyncResponse - %0b", sync_response);
        $display("DomainOut - En:Rst:Init  - %0b:%0b:%0b", target_clk_en, target_sync_rst, target_init);

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
        wire sync_rst_trigger;
        wire sync_response;
        wire target_clk = CycleCount[0];
        wire target_sync_rst_trigger = (CycleCount == 100) || (CycleCount == 101);
        wire target_clk_en;
        wire target_sync_rst;
        wire target_init;
        TopLevelReset_DomainControl #(
            .RESETCYCLELENGTH(4)
        ) DomainControl (
            .sys_clk                (clk),
            .clk_en                 (clk_en),
            .async_rst_in           (async_rst),
            .clk_en_sys             (clk_en_out),
            .sync_rst_sys           (sync_rst_out),
            .init_sys               (init_out),
            .sync_rst_trigger       (sync_rst_trigger),
            .sync_response          (sync_response),
            .target_clk             (target_clk),
            .target_sync_rst_trigger(target_sync_rst_trigger),
            .target_clk_en          (target_clk_en),
            .target_sync_rst        (target_sync_rst),
            .target_init            (target_init)
        );

	//               //

	//                    //
	// Supporting Modules //	
	//                    //

        wire clk_en_out;
        wire sync_rst_out;
        wire init_out;

        TopLevelReset_FlagGen #(
            .RESETWAITCYCLES      (6),
            .OPERATIONALWAITCYCLES(8),
            .INITIALIZEWAITCYCLES (8),
            .CLOCKDOMAINS         (2)
        ) FlagGen (
            .clk             (clk),
            .clk_en          (clk_en),
            .async_rst_in    (async_rst),
            .sync_rst_Trigger(sync_rst_trigger),
            .SyncIn          (sync_response),
            .clk_en_out      (clk_en_out),
            .sync_rst_out    (sync_rst_out),
            .init_out        (init_out)
        );

	//                    //


endmodule