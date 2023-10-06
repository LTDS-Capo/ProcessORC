//* VALIDATED *//
module FIFO_ClockDomainCrosser #(
    parameter BITWIDTH = 5,
    parameter DEPTH = 64,
    parameter TESTENABLE = 0
)(
    input rst,

    input  w_clk,
    input  dInACK,
    output dInREQ,
    input  [BITWIDTH-1:0] dIN,

    input  r_clk,
    output dOutACK,
    input  dOutREQ,
    output [BITWIDTH-1:0] dOUT
);
    // always_ff @(posedge w_clk) begin
    //     if (TESTENABLE) begin
    //         $display("FIFOCDC - EmptyFlag:FullFlag:WritePointer:ReadPointer - %0b:%0b:%0h:%0h", EmptyFlag, FullFlag, WritePointer, ReadPointer);
    //         $display("FIFOCDC - ReadData:ReadEnable:WriteEnable             - %0h:%0b:%0b", Buffer[ReadPointer], ReadEnable, WriteEnable);
    //         $display("FIFOCDC - IN:Ack:Req-OUT:Ack:Req                      - %0b:%0b-%0b:%0b", dInACK, dInREQ, dOutACK, dOutREQ);
    //         $display("FIFOCDC - GreyWrite:PhasedWrite                       - %0h:%0h", GreyWrite, PhasedWrite);
    //         $display("FIFOCDC - GreyRead:PhasedRead                         - %0h:%0h", GreyRead, PhasedRead);
    //     end 
    // end

    // OutputBuffer
    localparam ADDRWIDTH = $clog2(DEPTH);
    
    wire [ADDRWIDTH-1:0] ReadPointer; //! Moved to make Modelsim Happy
    wire [ADDRWIDTH-1:0] WritePointer; //! Moved to make Modelsim Happy
    wire [ADDRWIDTH:0] PhasedRead; //! Moved to make Modelsim Happy

    // RAM Block Instantiation (For FIFO)
    reg [BITWIDTH-1:0] Buffer [DEPTH-1:0];
    always_ff @( posedge w_clk ) begin
        if (dInREQ && dInACK) begin
            Buffer[WritePointer] <= dIN;
        end
    end
    wire [BITWIDTH-1:0] ReadData = (dOutACK && dOutREQ) ? Buffer[ReadPointer] : 0;

    // Write Address and Grey Code control
    wire FullFlag;
    wire [ADDRWIDTH:0] GreyWrite;
    wire [ADDRWIDTH:0] PhasedWrite;
    wire WriteEnable = dInACK && dInREQ;
    CDCCounter #(
		.DEPTH    (DEPTH),
		.FULLCHECK(1)
        ) WritePointerControl (
		.clk              (w_clk),
		.rst              (rst),
		.Count_en         (WriteEnable),
		.ComparisonPointer(PhasedRead),
        .PointerMatch     (FullFlag),
        .GreyPointer      (GreyWrite),
		.BinaryPointer    (WritePointer)
	);

    wire [ADDRWIDTH:0] TempWrite;
    // Sequence the Greycode for the Read Pointer
    DataSequencer #(
        .BITWIDTH (ADDRWIDTH+1),
        .DEPTH    (1)
    ) wWriteSequencer (
        .clk (w_clk),
        .rst (rst),
        .dIN (GreyWrite),
        .dOUT(TempWrite)
    );


    // Sequence the Greycode for the Write Pointer
    DataSequencer #(
        .BITWIDTH (ADDRWIDTH+1),
        .DEPTH    (3)
    ) rWriteSequencer (
        //.clk (w_clk),
        .clk (r_clk),
        .rst (rst),
        // .dIN (GreyWrite),
        .dIN (TempWrite),
        .dOUT(PhasedWrite)
    );

    // Read Address and Grey Code control
    wire EmptyFlag;
    wire [ADDRWIDTH:0] GreyRead;
    wire ReadEnable = dOutREQ && dOutACK;
    CDCCounter #(
		.DEPTH    (DEPTH),
		.FULLCHECK(0)
    ) ReadPointerControl (
		.clk              (r_clk),
		.rst              (rst),
		.Count_en         (ReadEnable),
		.ComparisonPointer(PhasedWrite),
        .PointerMatch     (EmptyFlag),
        .GreyPointer      (GreyRead),
		.BinaryPointer    (ReadPointer)
	);

    wire [ADDRWIDTH:0] TempRead;
    // Sequence the Greycode for the Read Pointer
    DataSequencer #(
        .BITWIDTH (ADDRWIDTH+1),
        .DEPTH    (1)
    ) rReadSequencer (
        .clk (r_clk),
        .rst (rst),
        .dIN (GreyRead),
        .dOUT(TempRead)
    );

    // Sequence the Greycode for the Read Pointer
    DataSequencer #(
        .BITWIDTH (ADDRWIDTH+1),
        .DEPTH    (3)
    ) wReadSequencer (
        //.clk (r_clk),
        .clk (w_clk),
        .rst (rst),
        // .dIN (GreyRead),
        .dIN (TempRead),
        .dOUT(PhasedRead)
    );


    // Output Assignments
    assign dOUT = ReadData;
    assign dInREQ = ~FullFlag;
    assign dOutACK = ~EmptyFlag;

endmodule