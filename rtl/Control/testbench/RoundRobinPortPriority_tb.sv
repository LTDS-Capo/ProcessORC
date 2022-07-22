`timescale 1ns / 1ps
module RoundRobinPortPriority_tb ();
	// Put dem localparams here bois
	//          |
	//        \ | /
	//         \|/
	localparam CycleLimit = 22;
	
	// Clock and reset initalization shiz
	reg clk = 0;
	reg rst = 0;
	initial begin
		#100 rst = 1;
		#100 rst = 0;
	end
	always #50 clk = !clk;


	// Dis be your cycle limit counter, this will force stop the test
	// after your cycle count hits your CycleLimit
	//          |
	//        \ | /
	//         \|/	
	always_comb begin
		if (CycleCount == CycleLimit) begin
			$display("><><><><><><><>< CYCLECOUNT ELAPSED! ><><><><><><><><");
			$finish;
		end
	end
	wire [31:0] CycleCount;
	tbCounter #(
		.BITWIDTH(32)
	) CycleCounter (
		.clk   (clk),
		.clk_en(1),
		.rst   (rst),
		.dOUT  (CycleCount)
	);
	
	RundownCounter #(
		.WAITTIME(8)
	) DragoutStop (
		.clk       (clk),
		.clk_en	   (Advance),
		.rst	   (rst),
		.StartCount(1'b0)
	);

	reg init = 1;
	reg Advance = 0;
	reg Tic = 0;
	always_ff @(posedge clk) begin : proc_TicTokerson
		if (Advance) begin

			// This is a half clock, Tic spends 1 cycle on, 1 cycle off
			//          |
			//        \ | /
			//         \|/	
			Tic = !Tic;
			// Dis be dat display stuff dem kids talk 'bout
			//          |
			//        \ | /
			//         \|/
			if (1'b1) begin
                $display("ACKVec:Sel - %04b:%02b", PortACKVector, PortSelection);
            	$display(">>>>>>> Count (%0d) <<<<<<<", Count);
				$display("^^^^^^^^^^^^^^^^^^^^^^^^^^^");
			end				
	    end
	    else if (init) begin
			init <= 0;
			Advance <= 1;
			// Put dat init stuffs her'
			//          |
			//        \ | /
			//         \|/
		end
	end

	
	// Put dat shit chu wanna test here
	//          |
	//        \ | /
	//         \|/

	wire [31:0] Count;
	tbCounter #(
		.BITWIDTH(32)
	) County (
		.clk     (clk),
		.clk_en  (Advance),
		.rst     (rst),
		.dOUT    (Count)
	);

    wire clk_en = Count > 4;
    wire sync_rst = Count == 1;
    
    wire [3:0] PortACKVector = Count[3:0];
    wire [1:0] PortSelection;

    RoundRobinPortPriority #(
        .PORTCOUNT    (4),
        .PORTADDRWIDTH(2),
    ) RRPortPriority (
        .clk          (clk),
        .clk_en       (clk_en),
        .sync_rst     (sync_rst),
        .PortACKVector(PortACKVector),
        .PortSelection(PortSelection)
    );


// localparam ADDRBITWIDTH = (BITWIDTH == 1) ? 1 : $clog2(BITWIDTH);














endmodule

///////////////////////////////////////////////////////////////////////////////
////// IGNORE BELOW THIS ///// IGNORE BELOW THIS ///// IGNORE BELOW THIS //////
///////////////////////////////////////////////////////////////////////////////

// Modules used above are created below

module tbCounter #(
    parameter BITWIDTH = 64
)(
	input clk,                   // Clock
	input clk_en,                // Clock Enable
	input rst,                   // Asynchronous reset active high -
	                               // Sets Counter Register to b'0
	output [BITWIDTH-1:0] dOUT  // Current Counter Value
);


reg [BITWIDTH-1:0] Count = '0;
assign dOUT = Count;
always_ff @(posedge clk or posedge rst) begin : proc_Count
	if(rst) begin
		Count <= '0;
	end 
    else if(clk_en) begin
		Count <= Count + 1'b1;
	end
end
endmodule

module tbCounterWLoad #(
    parameter BITWIDTH = 64
)(
	input clk,                   // Clock
	input clk_en,                // Clock Enable
	input rst,                   // Asynchronous reset active high -
	                               // Sets Counter Register to b'0
    input load_en,              // Loads value dIN into Counter when;
                                  // load_en is high.
    input  [BITWIDTH-1:0] dIN,
    output [BITWIDTH-1:0] dOUT  // Current Counter Value

);

	reg [BITWIDTH-1:0] Count = '0;
	assign dOUT = Count;
	always_ff @(posedge clk or posedge rst) begin : proc_Count
		if(rst) begin
			Count <= '0;
		end 
	    else if(clk_en) begin
			if (!load_en) begin
				Count <= Count + 1'b1;
			end
			else begin
	        	Count <= dIN;
	        end
	    end	
	end
endmodule

module RundownCounter #(
	parameter WAITTIME = 8
)(
	input clk,
	input clk_en,
	input rst,
	input StartCount
);
	localparam COUNT_BITWIDTH = $clog2(WAITTIME);
	// Active Regsiter
	reg  Active;
	wire ActiveTrigger = StartCount && clk_en;
	wire NextActive = StartCount;
	always_ff @(posedge clk) begin
		if (rst) begin
			Active <= 0;
		end
		else if (ActiveTrigger) begin
			Active <= NextActive;
		end
		//$display("Active:CycleCount - %0b:%0h", Active, CycleCount);
	end
	// CycleCount
	reg  [COUNT_BITWIDTH:0] CycleCount;
	wire       				CycleCountTrigger = (Active && clk_en) || (StartCount && clk_en);
	wire [COUNT_BITWIDTH:0] NextCycleCount = ~StartCount ? (CycleCount - 1) : WAITTIME;
	always_ff @(posedge clk) begin
		if (rst) begin
			CycleCount <= 0;
		end
		else if (CycleCountTrigger) begin
			CycleCount <= NextCycleCount;
		end
		if (FinishTrigger) begin
			$display("><><><><><><>< DRAGOUT CYCLE TIME OF: %0d CYCLES HAS ELAPASED ><><><><><><>< ", WAITTIME);
			$finish;
		end
	end

	wire FinishTrigger = (CycleCount == 0) && Active;

endmodule