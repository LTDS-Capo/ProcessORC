module HandshakeFIFOBuffer #(
	parameter DATABITWIDTH = 32
)(
	input clk,
    input clk_en,
	input sync_rst,

	output dInREQ,	
	input  dInACK,
	input  [DATABITWIDTH-1:0] dIN,

	output dOutACK,
	input  dOutREQ,
	output [DATABITWIDTH-1:0] dOUT
);


endmodule