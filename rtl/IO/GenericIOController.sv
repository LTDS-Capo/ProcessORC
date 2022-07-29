module GenericIOController (
    input clk2p5,
    input clk_en,
    input sync_rst,

    input         PortREQ,
    output        PortACK,
    input   [3:0] Command,
    input  [15:0] RemoteAddress,
    input  [15:0] WriteData,
    output [15:0] ResultData,

    output [31:0] IO_Output,
    output [31:0] IO_OutputEnable,
    input  [31:0] IO_Input,

    output TESTBIT
);

    // Commands
    //  Load  [4'b0100] -
    //  Store [4'b0010] -

    // Use 16bit Remote Address as Port Address + Operations.
    // [4:0] - Port Address
    // Operations
    //     3'b001 Set to DataIn [Set to r0 to clear]
    //     3'b010 Pulse: Inverse Polarity 
    //     3'b100 Read Input State [Copy Input Buffer to Op]
    //            PWM: [Need Cycle and Duty] // DO LATER

    wire   [2:0] PortCommand = RemoteAddress[10:8];
    logic [15:0] PortDecodeVector;
    wire   [3:0] PortAddress = RemoteAddress[3:0];
    always_comb begin : PortDecoder
        case (PortAddress)
            4'b0001: PortDecodeVector = 16'b0000_0000_0000_0010;
            4'b0010: PortDecodeVector = 16'b0000_0000_0000_0100;
            4'b0011: PortDecodeVector = 16'b0000_0000_0000_1000;
            4'b0100: PortDecodeVector = 16'b0000_0000_0001_0000;
            4'b0101: PortDecodeVector = 16'b0000_0000_0010_0000;
            4'b0110: PortDecodeVector = 16'b0000_0000_0100_0000;
            4'b0111: PortDecodeVector = 16'b0000_0000_1000_0000;
            4'b1000: PortDecodeVector = 16'b0000_0001_0000_0000;
            4'b1001: PortDecodeVector = 16'b0000_0010_0000_0000;
            4'b1010: PortDecodeVector = 16'b0000_0100_0000_0000;
            4'b1011: PortDecodeVector = 16'b0000_1000_0000_0000;
            4'b1100: PortDecodeVector = 16'b0001_0000_0000_0000;
            4'b1101: PortDecodeVector = 16'b0010_0000_0000_0000;
            4'b1110: PortDecodeVector = 16'b0100_0000_0000_0000;
            4'b1111: PortDecodeVector = 16'b1000_0000_0000_0000;
            default: PortDecodeVector = 16'b0000_0000_0000_0001;
        endcase
    end

    wire LowerCellSelect = PortREQ && ~RemoteAddress[4];
    wire UpperCellSelect = PortREQ && RemoteAddress[4];
    wire ResultVector [31:0];
    generate
        genvar i;
        for (i = 0; i < 32; i = i + 1) begin : IOCellGeneration
            if (i < 16) begin
                wire CellSelectLower = PortDecodeVector[i] && LowerCellSelect;
                GenericIOCell LowerGenericIOCellTest (
                    .clk2p5       (clk2p5),
                    .clk_en       (clk_en),
                    .sync_rst     (sync_rst),
                    .CellSelect   (CellSelectLower),
                    .CellOperation(PortCommand),
                    .DataIn       (WriteData[0]),
                    .CellState    (ResultVector[i]),
                    .CellIn       (IO_Input[i]),
                    .CellOut      (IO_Output[i]),
                    .CellOutEnable(IO_OutputEnable[i]),
                    .ADDRTEST     (i)
                ); 
            end
            else begin
                wire CellSelectUpper = PortDecodeVector[i-16] && UpperCellSelect;
                GenericIOCell UpperGenericIOCellTest (
                    .clk2p5       (clk2p5),
                    .clk_en       (clk_en),
                    .sync_rst     (sync_rst),
                    .CellSelect   (CellSelectUpper),
                    .CellOperation(PortCommand),
                    .DataIn       (WriteData[0]),
                    .CellState    (ResultVector[i]),
                    .CellIn       (IO_Input[i]),
                    .CellOut      (IO_Output[i]),
                    .CellOutEnable(IO_OutputEnable[i]),
                    .ADDRTEST     (i)
                ); 
            end
        end
    endgenerate

    wire [4:0] ReadAddress = RemoteAddress[4:0];
    logic SelectedResult;
    always_comb begin : ReadDecoder
        case (ReadAddress)
            5'b00001: SelectedResult = ResultVector[1];
            5'b00010: SelectedResult = ResultVector[2];
            5'b00011: SelectedResult = ResultVector[3];
            5'b00100: SelectedResult = ResultVector[4];
            5'b00101: SelectedResult = ResultVector[5];
            5'b00110: SelectedResult = ResultVector[6];
            5'b00111: SelectedResult = ResultVector[7];
            5'b01000: SelectedResult = ResultVector[8];
            5'b01001: SelectedResult = ResultVector[9];
            5'b01010: SelectedResult = ResultVector[10];
            5'b01011: SelectedResult = ResultVector[11];
            5'b01100: SelectedResult = ResultVector[12];
            5'b01101: SelectedResult = ResultVector[13];
            5'b01110: SelectedResult = ResultVector[14];
            5'b01111: SelectedResult = ResultVector[15];
            5'b10000: SelectedResult = ResultVector[16];
            5'b10001: SelectedResult = ResultVector[17];
            5'b10010: SelectedResult = ResultVector[18];
            5'b10011: SelectedResult = ResultVector[19];
            5'b10100: SelectedResult = ResultVector[20];
            5'b10101: SelectedResult = ResultVector[21];
            5'b10110: SelectedResult = ResultVector[22];
            5'b10111: SelectedResult = ResultVector[23];
            5'b11000: SelectedResult = ResultVector[24];
            5'b11001: SelectedResult = ResultVector[25];
            5'b11010: SelectedResult = ResultVector[26];
            5'b11011: SelectedResult = ResultVector[27];
            5'b11100: SelectedResult = ResultVector[28];
            5'b11101: SelectedResult = ResultVector[29];
            5'b11110: SelectedResult = ResultVector[30];
            5'b11111: SelectedResult = ResultVector[31];
            default : SelectedResult = ResultVector[0];
        endcase
    end

    reg  [1:0] OutputFlagBuffer;
    wire       OutputFlagBufferTrigger = clk_en || sync_rst;
    wire       CellReadEnable = RemoteAddress[10] && PortREQ && Command[2];
    wire [1:0] NextOutputFlagBuffer;
    assign     NextOutputFlagBuffer[0] = PortREQ && ~sync_rst;
    assign     NextOutputFlagBuffer[1] = CellReadEnable && ~sync_rst;
    always_ff @(posedge clk2p5) begin
        if (OutputFlagBufferTrigger) begin
            OutputFlagBuffer <= NextOutputFlagBuffer;
        end

    //$display("Select Lower:Upper - %0b:%0b", LowerCellSelect, UpperCellSelect);

    end
    assign PortACK = OutputFlagBuffer[0];
    assign ResultData = OutputFlagBuffer[1] ? {15'b0, SelectedResult} : 0;

endmodule