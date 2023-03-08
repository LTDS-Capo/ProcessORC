

    genvar SomeGenVar;
    generate
        for (SomeGenVar = 0; SomeGenVar < ; SomeGenVar = SomeGenVar + 1) begin : 
            
        end
    endgenerate


    reg  SomeRepeaterLock;
    wire NextSomeRepeaterLock = ~sync_rst && (ALUOutput[3]);
    wire SomeRepeaterLockTrigger = sync_rst || (clk_en && (WriteAddress == 4'h7));
    always_ff @(posedge clk) begin
        if (SomeRepeaterLockTrigger) begin
            SomeRepeaterLock <= NextSomeRepeaterLock;
        end
    end


    // Decoder Example
    logic [7:0] OneHotVector;
    wire  [2:0] SomeBitIndex;
    always_comb begin
        OneHotVector = 0;
        OneHotVector[SomeBitIndex] = 1'b1;
    end
    // In:  3'h3
    // Out: 8'b0000_1000



    logic [7:0] SomeMuxOutput;
    always_comb begin : SomeMuxOutputMux
        case (TwoBitMuxCondition)
            2'b00  : SomeMuxOutput = ;
            2'b01  : SomeMuxOutput = ;
            2'b10  : SomeMuxOutput = ;
            2'b11  : SomeMuxOutput = ;
            default: SomeMuxOutput = 0;
        endcase
    end


    wire SomeWire = SomeLogic;

    wire   SomeWire;
    assign SomeWire = SomeLogic;

    wire   [1:0] SomeBitVector;
    assign       SomeBitVector[0] = SomeLogic;
    assign       SomeBitVector[1] = SomeOtherLogic;

    wire       SomeWire;
    wire [7:0] SomeByte;
    SomeModule ModuleName (
        .SomeModuleBitPin(SomeWire),
        .SomeModuleBytePin(SomeByte)
    );