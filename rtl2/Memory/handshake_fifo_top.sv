module handshake_fifo_top #(
    parameter WIDTH = 32,
    parameter DEPTH = 1024,
    parameter bit LIBERO = 1'b1
)(
    input clk,
    input clk_en,
    input sync_rst,

    input              InputREQ,
    output             InputACK,
    input  [WIDTH-1:0] InputData,

    output             OutputREQ,
    input              OutputACK,
    output [WIDTH-1:0] OutputData
);

generate 
    if(LIBERO) begin
        handshake_fifo_libero #(.WIDTH(WIDTH),.DEPTH(DEPTH)
        ) handshake_fifo_libero (
            .clk(clk),
            .clk_en(clk_en),
            .sync_rst(sync_rst),
            .InputREQ(InputREQ),
            .InputACK(InputACK),
            .InputData(InputData),
            .OutputREQ(OutputREQ),
            .OutputACK(OutputACK),
            .OutputData(OutputData),
            .CorrectedECC(),
            .DetectedECC ()
        );
    end
    else begin
        handshake_fifo #(.WIDTH(WIDTH),.DEPTH(DEPTH)
        ) handshake_fifo (
            .clk(clk),
            .clk_en(clk_en),
            .sync_rst(sync_rst),
            .InputREQ(InputREQ),
            .InputACK(InputACK),
            .InputData(InputData),
            .OutputREQ(OutputREQ),
            .OutputACK(OutputACK),
            .OutputData(OutputData)
        );
    end
endgenerate
endmodule : handshake_fifo_top
