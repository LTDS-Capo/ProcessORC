`timescale 1ns / 1ps
module GPRStateMachine_tb ();
	localparam CYCLELIMIT = 20;
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
            $display("Cycle[%0d] -  IN - dWr:dIs:tR:FR   - %0b:%0b:%0b:%0b", CycleCount, DirtyWrite, DirtyIssue, ToRunahead, FromRunahead);
            $display("Cycle[%0d] -  IN - Valid:WB:Wt:Rf  - %0b:%0b:%0b:%0b", CycleCount, InstructionValid, WritingBack, WritingTo, ReadingFrom);
            $display("Cycle[%0d] - OUT - Index:Dirty:pWr - %0h:%0b:%0b", CycleCount, TestCounter, IsDirty, HasPendingWrite);
            $display("~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ");
	end

	// Set to zero to disable rundown counter
	assign RundownTrigger = 1'b0;

	// Useful signals	
	wire clk_en = CycleCount > 1;
	wire sync_rst = CycleCount == 1;

	//               //
	// Module Tested //	
	//               //
        wire InstructionValid = RegisterTestVector[7];
        wire DirtyWrite = RegisterTestVector[6];
        wire DirtyIssue = RegisterTestVector[5];
        wire ToRunahead = RegisterTestVector[4];
        wire FromRunahead = RegisterTestVector[3];
        wire WritingBack = RegisterTestVector[2];
        wire WritingTo = RegisterTestVector[1];
        wire ReadingFrom = RegisterTestVector[0];
        wire IsDirty;
        wire HasPendingWrite;
        GPRStateMachine StateMachine (
            .clk             (clk),
            .clk_en          (clk_en),
            .sync_rst        (sync_rst),
            .InstructionValid(InstructionValid),
            .DirtyWrite      (DirtyWrite),
            .DirtyIssue      (DirtyIssue),
            .ToRunahead      (ToRunahead),
            .FromRunahead    (FromRunahead),
            .WritingBack     (WritingBack),
            .WritingTo       (WritingTo),
            .ReadingFrom     (ReadingFrom),
            .IsDirty         (IsDirty),
            .HasPendingWrite (HasPendingWrite)
        );
	//               //

	//                    //
	// Supporting Modules //	
	//                    //
    reg  [7:0] TestCounter;
    wire [7:0] NextTestCounter = sync_rst ? 0 : (TestCounter + 1);
    wire TestCounterTrigger = sync_rst || (clk_en);
    always_ff @(posedge clk) begin
        if (TestCounterTrigger) begin
            TestCounter <= NextTestCounter;
        end
    end
    logic [7:0] RegisterTestVector;
    always_comb begin : RegisterTestVectorMux
        case (TestCounter)
            //! EXAMPLE FOR r3
            //*                            Val - dWr - dIs - tR  - fR  - WB  - Wt  - Rf
            8'h00  : RegisterTestVector = {1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0}; // Load r1 r2
            8'h01  : RegisterTestVector = {1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b1}; // Add  r1 r3 [soiled with 1]
            8'h02  : RegisterTestVector = {1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b1, 1'b1}; // Sub  r3 r4
            8'h03  : RegisterTestVector = {1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1}; // Add  r3 r5 - Stalls
            8'h04  : RegisterTestVector = {1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1}; // Add  r3 r5 - Stalls (Load Writes)
            8'h05  : RegisterTestVector = {1'b1, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b1}; // Add  r1 r3 (From Runahead)
            8'h06  : RegisterTestVector = {1'b1, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1'b1}; // Sub  r3 r4 (From Runahead)
            8'h07  : RegisterTestVector = {1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1}; // Add  r3 r5 - Stalls
            8'h08  : RegisterTestVector = {1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1}; // Add  r3 r5 - Stall Ends

            
            8'h09  : RegisterTestVector = {1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0}; // Add  r6 r1 
            8'h0A  : RegisterTestVector = {1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0}; // Load r3 r6
            8'h0B  : RegisterTestVector = {1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0}; // Add  r7 r3
            8'h0C  : RegisterTestVector = {1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0}; // Add  r8 r3
            8'h0D  : RegisterTestVector = {1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0}; // Add  r8 r3
            8'h0E  : RegisterTestVector = {1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0}; // Sub  r1 r9 (Load Writes)
            8'h0F  : RegisterTestVector = {1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0}; 
            8'h10  : RegisterTestVector = {1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0}; 
            8'h11  : RegisterTestVector = {1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0}; 
            8'h12  : RegisterTestVector = {1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0}; 
            8'h13  : RegisterTestVector = {1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0}; 
            8'h14  : RegisterTestVector = {1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0}; 
            8'h15  : RegisterTestVector = {1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0}; 
            8'h16  : RegisterTestVector = {1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0}; 
            8'h17  : RegisterTestVector = {1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0}; 
            8'h18  : RegisterTestVector = {1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0}; 
            8'h19  : RegisterTestVector = {1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0}; 
            8'h1A  : RegisterTestVector = {1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0}; 
            8'h1B  : RegisterTestVector = {1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0}; 
            8'h1C  : RegisterTestVector = {1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0}; 
            8'h1D  : RegisterTestVector = {1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0}; 
            8'h1E  : RegisterTestVector = {1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0}; 
            8'h1F  : RegisterTestVector = {1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0}; 
            default: RegisterTestVector = 0;
        endcase
    end


	//                    //

endmodule