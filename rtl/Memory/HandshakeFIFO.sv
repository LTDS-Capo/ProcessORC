//                                  //
//* VALIDATED: HandshakeFIFO_tb.sv *//
//                                  //
module HandshakeFIFO #(
	parameter DATABITWIDTH = 16,
	parameter FIFODEPTH = 4,
	parameter FIFODEPTHBITWIDTH = 2
)(
	input clk,
    input clk_en,
	input sync_rst,

	output 				      dInREQ,
	input  				      dInACK,
	input  [DATABITWIDTH-1:0] dIN,

	input  					  dOutREQ,
	output 					  dOutACK,
	output [DATABITWIDTH-1:0] dOUT
);

	// Head Counter
	reg  [FIFODEPTHBITWIDTH:0] Head;
	wire 					   FIFOWriteEn = dInREQ && dInACK;
	wire       				   HeadTrigger = FIFOWriteEn || sync_rst;
	wire [FIFODEPTHBITWIDTH:0] NextHead = (sync_rst) ? 0 : Head + 1;
	always_ff @(posedge clk) begin
		if (HeadTrigger) begin
			Head <= NextHead;
		end
	end

	// Tail Counter
	reg  [FIFODEPTHBITWIDTH:0] Tail;
	wire					   FIFOReadEn = dOutREQ && dOutACK;
	wire       				   TailTrigger = FIFOReadEn || sync_rst;
	wire [FIFODEPTHBITWIDTH:0] NextTail = (sync_rst) ? 0 : Tail + 1;
	always_ff @(posedge clk) begin
		if (TailTrigger) begin
			Tail <= NextTail;
		end
	end

	// Full/Empty Checks
	wire HeadTailLowerCompare = Head[FIFODEPTHBITWIDTH-1:0] == Tail[FIFODEPTHBITWIDTH-1:0];
	wire HeadTailUpperCompare = Head[FIFODEPTHBITWIDTH] ^ Tail[FIFODEPTHBITWIDTH];
	wire FIFOFullCheck = HeadTailLowerCompare && HeadTailUpperCompare;
	wire FIFOEmtpyCheck = HeadTailLowerCompare && ~HeadTailUpperCompare;

	// FIFO Memory Instantiation
	reg  [DATABITWIDTH-1:0] FIFOMem [FIFODEPTH-1:0];
	always_ff @(posedge clk) begin
		if (FIFOWriteEn) begin
			FIFOMem[Head[FIFODEPTHBITWIDTH-1:0]] <= dIN;
		end
	end
	assign dOUT = ~FIFOEmtpyCheck ? FIFOMem[Tail[FIFODEPTHBITWIDTH-1:0]] : 0;

	// Handshake Outputs
	assign dInREQ = ~FIFOFullCheck && clk_en;
	assign dOutACK = ~FIFOEmtpyCheck && clk_en;


endmodule