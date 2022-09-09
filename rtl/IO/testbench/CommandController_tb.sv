`timescale 1ns / 1ps
module CommandController_tb ();
	localparam CYCLELIMIT = 32;
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
    // CommandACKTestBuffer, CommandREQ, WritebackACK, WritebackDestReg, WritebackDataOut, IOClk, IOACKTestBuffer, IOREQ, IOCommandEn, IOResponseRequested, IODestRegOut, IODataOut
		$display("CMD -                 ACK:REQ - %0b:%0b", CommandACKTestBuffer, CommandREQ);
		$display("WB  -           ACK:Dest:Data - %0b:%0h:%0h", WritebackACK, WritebackDestReg, WritebackDataOut);
		$display("IO  - CLK:ACK:REQ:CMD:RespREQ - %0b:%0b:%0b:%0b:%0b", IOClk, IOACKTestBuffer, IOREQ, IOCommandEn, IOResponseRequested);
		$display("IO  -               Dest:Data - %0b:%0b", IODestRegOut, IODataOut);

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
        wire sys_clk = clk;
        wire src_clk0 = CycleCount[0];
        wire src_clk1 = CycleCount[0];
        wire src_clk2 = CycleCount[0];
        wire [7:0]      divided_clks = {CycleCount[1], CycleCount[1], CycleCount[1], CycleCount[1], CycleCount[1], CycleCount[1], CycleCount[1], CycleCount[1]};
        wire      [1:0] clk_sel_0 = 2'b00;
        wire      [1:0] clk_sel_1 = 2'b01;
        wire      [1:0] clk_sel_2 = 2'b10;
        wire      [1:0] clk_sel_3 = 2'b11;
        wire [3:0][1:0] divided_clk_sels = {clk_sel_3, clk_sel_2, clk_sel_1, clk_sel_0};
        wire            CommandACK = CommandACKTestBuffer;
        wire            CommandREQ;
        wire      [3:0] MinorOpcodeIn = 4'b0101;
        wire     [15:0] CommandAddressIn_Offest = 16'h0000;
        wire     [15:0] CommandDataIn = 16'hA5A5;
        wire      [3:0] CommandDestReg = 4'hF;
        wire            WritebackACK;
        wire            WritebackREQ = 1'b1;
        wire      [3:0] WritebackDestReg;
        wire     [15:0] WritebackDataOut;
        wire            IOClk;
        wire            IOACK = IOACKTestBuffer;
        wire            IOREQ;
        wire            IOCommandEn;
        wire            IOResponseRequested;
        wire            IOCommandResponse = IOCommandEn;
        wire            IORegResponseFlag = IOResponseRequested;
        wire            IOMemResponseFlag = 1'b0;
        wire      [3:0] IODestRegIn = 4'h7;
        wire     [15:0] IODataIn = 16'hF00F;
        wire      [3:0] IODestRegOut;
        wire     [15:0] IODataOut;

        localparam GPIO_PORTBYTEWIDTH = 2;
        localparam GPIO_CLOCKCOMMAND_LSB = 0;
        localparam GPIO_CLOCKCOMMAND_MSB = 12;
        localparam GPIO_CLOCKCOMMAND_OPCODE = 13'h1C00; // 1_1100_0000_0000
        localparam GPIO_CLOCKCOMMAND_CLKSELLSB = 13;
        CommandController #(
            .PORTBYTEWIDTH         (GPIO_PORTBYTEWIDTH),
            .CLOCKCOMMAND_LSB      (GPIO_CLOCKCOMMAND_LSB),
            .CLOCKCOMMAND_MSB      (GPIO_CLOCKCOMMAND_MSB),
            .CLOCKCOMMAND_OPCODE   (GPIO_CLOCKCOMMAND_OPCODE),
            .CLOCKCOMMAND_CLKSELLSB(GPIO_CLOCKCOMMAND_CLKSELLSB),
            .DATABITWIDTH          (16)
        ) GPIO_PortController (
            .sys_clk                (sys_clk),
            .clk_en                 (clk_en),
            .sync_rst               (sync_rst),
            .async_rst              (async_rst),
            .src_clk0               (src_clk0),
            .src_clk1               (src_clk1),
            .src_clk2               (src_clk2),
            .divided_clks           (divided_clks),
            .divided_clk_sels       (divided_clk_sels),
            .CommandACK             (CommandACK),
            .CommandREQ             (CommandREQ),
            .MinorOpcodeIn          (MinorOpcodeIn),
            .CommandAddressIn_Offest(CommandAddressIn_Offest),
            .CommandDataIn          (CommandDataIn),
            .CommandDestReg         (CommandDestReg),
            .WritebackACK           (WritebackACK),
            .WritebackREQ           (WritebackREQ),
            .WritebackDestReg       (WritebackDestReg),
            .WritebackDataOut       (WritebackDataOut),
            .IOClk                  (IOClk),
            .IOACK                  (IOACK),
            .IOREQ                  (IOREQ),
            .IOCommandEn            (IOCommandEn),
            .IOResponseRequested    (IOResponseRequested),
            .IOCommandResponse      (IOCommandResponse),
            .IORegResponseFlag      (IORegResponseFlag),
            .IOMemResponseFlag      (IOMemResponseFlag),
            .IODestRegIn            (IODestRegIn),
            .IODataIn               (IODataIn),
            .IODestRegOut           (IODestRegOut),
            .IODataOut              (IODataOut)
        );
	//               //

	//                    //
	// Supporting Modules //	
	//                    //
        reg  CommandACKTestBuffer;
        wire CommandACKTestBufferTrigger = (CommandREQ && CommandACK) || ((CycleCount == 8)) || sync_rst;
        wire NextCommandACKTestBuffer = (CycleCount == 8) && ~sync_rst;
        always_ff @(posedge clk) begin
            if (CommandACKTestBufferTrigger) begin
                CommandACKTestBuffer <= NextCommandACKTestBuffer;
            end
        end

        reg  IOACKTestBuffer;
        wire IOACKTestBufferTrigger = (IOREQ && IOACK) || (IOREQ && ~IOACK);
        wire NextIOACKTestBuffer = IOREQ && ~IOACK;
        always_ff @(posedge IOClk or posedge async_rst) begin
            if (async_rst) begin
                IOACKTestBuffer <= 0;
            end
            else if (IOACKTestBufferTrigger) begin
                IOACKTestBuffer <= NextIOACKTestBuffer;
            end
        end



	//                    //

endmodule