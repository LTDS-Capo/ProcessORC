module GPIOController (
    input clk,
    input clk_en,
    input sync_rst,

    output        IO_ACK,
    input         IO_REQ,
    input         IO_CommandEn,
    input         IO_ResponseRequested,
    output        IO_CommandResponse,
    output        IO_RegResponseFlag,
    output        IO_MemResponseFlag,
    input   [3:0] IO_DestRegIn,
    output  [3:0] IO_DestRegOut,
    input  [15:0] IO_DataIn,
    output [15:0] IO_DataOut,

    input   [7:0] GPIO_DIn,
    output  [7:0] GPIO_DOut,
    output  [7:0] GPIO_DOutEn
);
    // Pulse of Length 0 Selects clock.
    // GPIO (WriteBit[0], WriteByte[1], ClearBit[2], ReadStatus[3], ReadPin[4], ReadStatusByte[5], ReadPinByte[6], PulseBit(Length)[7]) - In, Out, OutEn
    // >> NonPulse
    //   [15:13] IOAddr
    //   [12:10] Command
    //     [9:1] *Ignore*
    //       [0] WriteValue
    // >> Pulse
    //   [15:13] IOAddr
    //   [12:10] Command
    //     [9:0] PulseLength

    // wire [15:0] TestValue = LocalDataOutArray;
    // always_ff @(posedge clk) begin
	// 	$display("> GPIOCTL -  DataOutCondition - %02b", DataOutCondition);
	// 	$display("> GPIOCTL - LocalDataOutArray - %08b", LocalDataOutArray);
	// 	$display("> GPIOCTL -       CellDecoder - %0b", CellDecoder);
    // end

    logic [7:0] Command;
    always_comb begin
        Command = '0;
        Command[IO_DataIn[12:10]] = (IO_CommandEn && IO_REQ);
    end

    logic [7:0] CellDecoder;
    always_comb begin
        CellDecoder = '0;
        CellDecoder[IO_DataIn[15:13]] = 1'b1;
    end

    wire [7:0] LocalDataOutArray;
    wire [7:0] PinDataOutArray;
    genvar CellIndex;
    generate
        for (CellIndex = 0; CellIndex < 8; CellIndex = CellIndex + 1) begin : GPIOCellGeneration
            wire        Local_Set = (Command[0] && CellDecoder[CellIndex]) || Command[1];
            wire        Local_Clear = Command[2] && CellDecoder[CellIndex];
            wire        Local_PulseInit = Command[7] && CellDecoder[CellIndex];
            logic [9:0] LocalDataIn;
            wire  [1:0] DataInCondition = {Command[7], Command[1]};
            always_comb begin : LocalDataInMux
                case (DataInCondition)
                    2'b01  : LocalDataIn = IO_DataIn[CellIndex];
                    2'b10  : LocalDataIn = IO_DataIn[9:0];
                    2'b11  : LocalDataIn = IO_DataIn[9:0];
                    default: LocalDataIn = IO_DataIn[0]; // Default is also case 0
                endcase
            end
            GPIO_Cell #(
                .TEST_CELLADDR(CellIndex)
            )GPIOCell (
                .clk         (clk),
                .clk_en      (clk_en),
                .sync_rst    (sync_rst),
                .Set         (Local_Set),
                .Clear       (Local_Clear),
                .PulseInit   (Local_PulseInit),
                .LocalDataIn (LocalDataIn),
                .LocalDataOut(LocalDataOutArray[CellIndex]),
                .PinDataOut  (PinDataOutArray[CellIndex]),
                .IODataIn    (GPIO_DIn[CellIndex]),
                .IODataOut   (GPIO_DOut[CellIndex]),
                .IODataOutEn (GPIO_DOutEn[CellIndex])
            );
        end
    endgenerate
    
    assign        IO_ACK = clk_en;
    assign        IO_CommandResponse = IO_CommandEn;
    assign        IO_RegResponseFlag = IO_ResponseRequested && (|(Command[3:6]));
    assign        IO_MemResponseFlag = '0;
    assign        IO_DestRegOut = IO_DestRegIn;
    logic  [15:0] IO_DataOut_Tmp;
    wire    [1:0] DataOutCondition = {(Command[6] || Command[5]), (Command[4] || Command[5])};
    always_comb begin : NextDataOutMux
        case (DataOutCondition)
            2'b01  : IO_DataOut_Tmp = {'0, PinDataOutArray[IO_DataIn[15:13]]};
            2'b10  : IO_DataOut_Tmp = {'0, PinDataOutArray};
            2'b11  : IO_DataOut_Tmp = {'0, LocalDataOutArray};
            default: IO_DataOut_Tmp = {'0, LocalDataOutArray[IO_DataIn[15:13]]}; // Default is also case 0
        endcase
    end
    assign IO_DataOut = IO_DataOut_Tmp;

endmodule