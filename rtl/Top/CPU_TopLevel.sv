module CPU_TopLevel #(
    parameter DATABITWIDTH = 16
)(
    input clk,
    input clk_en,
    input sync_rst,

    input  SystemEn,
    output HaltOut, // TODO:
);
    localparam REGISTERCOUNT = 16;
    localparam REGADDRBITWIDTH = $clog2(REGISTERCOUNT);
    localparam TAGADDRESSPADDING = 2;
    localparam TAGBITWIDTH = REGADDRBITWIDTH + TAGADDRESSPADDING;

    // Stage 0 (Ready for testing)
    // Notes: Fetch
    // Inputs: SystemEn, StallEn, InstructionAddress
    // Output Buffer: s1_InstructionValid, s1_InstructionOut
        // Instruction ROM
            wire [15:0] InstructionAddress;
            wire [15:0] s0_InstructionOut;
            InstructionROM InstROM (
                .InstructionAddress(InstructionAddress),
                .InstructionOut    (s0_InstructionOut)
            );
        //

        // Instruction Valid Generation
            wire s0_InstructionValid = SystemEn && ~StallEn;
        //

        // Pipeline Buffer - Stage 0
            reg  [16:0] Stage0Buffer;
            wire        Stage0BufferTrigger = clk_en || sync_rst;
            wire [16:0] NextStage0Buffer = (sync_rst) ? 0 : {s0_InstructionValid, s0_InstructionOut};
            always_ff @(posedge clk) begin
                if (Stage0BufferTrigger) begin
                    Stage0Buffer <= NextStage0Buffer;
                end
            end
            wire        s1_InstructionValid = Stage0Buffer[16];
            wire [15:0] s1_InstructionOut = Stage0Buffer[15:0];
        // 
    //

    // Stage 1 
    // Notes: Decode
    // Inputs: s1_InstructionValid, s1_InstructionOut,
    // Output Buffer: s2_BranchIssue, s2_ALU0Issue, s2_ALU1Issue, s2_RegWriteIssue
        // Instruction Decoder (Ready For Testing)
            wire             [15:0] InstructionIn = s1_InstructionOut;
            wire                    InstructionInValid = s1_InstructionValid;
            wire                    TagRequest;
            wire              [4:0] FunctionalUnitEnable;
            wire              [1:0] WritebackSource;
            wire              [3:0] MinorOpcodeOut;
            wire                    ImmediateEn;
            wire                    UpperImmediateEn;
            wire [DATABITWIDTH-1:0] ImmediateOut;
            wire                    RegAReadEn;
            wire                    RegAWriteEn;
            wire              [3:0] RegAAddr;
            wire                    RegBReadEn;
            wire              [3:0] RegBAddr;
            wire                    BranchStall;
            InstructionDecoder #(
                .DATABITWIDTH(DATABITWIDTH)
            ) InstDecoder (
                .InstructionIn       (InstructionIn),
                .InstructionInValid  (InstructionInValid),
                .TagRequest          (TagRequest),
                .FunctionalUnitEnable(FunctionalUnitEnable),
                .WritebackSource     (WritebackSource), 
                .MinorOpcodeOut      (MinorOpcodeOut),
                .ImmediateEn         (ImmediateEn),
                .UpperImmediateEn    (UpperImmediateEn),
                .ImmediateOut        (ImmediateOut),
                .RegAReadEn          (RegAReadEn),
                .RegAWriteEn         (RegAWriteEn),
                .RegAAddr            (RegAAddr),
                .RegBReadEn          (RegBReadEn),
                .RegBAddr            (RegBAddr),
                .BranchStall         (BranchStall)
            );
        //

        // Stall Control (Ready For Testing)
            wire InstructionValid = s1_InstructionValid;
            wire BranchStallIn = BranchStall;
            wire RegisterStallIn = RegisterStallOut;
            wire IssueCongestionStallIn = IssueCongestionStallOut;
            wire StallEn;
            StallControl StallCtl (
                .clk                   (clk),
                .clk_en                (clk_en),
                .sync_rst              (sync_rst),
                .InstructionValid      (InstructionValid),
                .BranchStallIn         (BranchStallIn),
                .RegisterStallIn       (RegisterStallIn),
                .IssueCongestionStallIn(IssueCongestionStallIn),
                .StallEn               (StallEn)
            );
        //

        // Tagging (Ready For Testing)
            wire                   TagREQ = TagRequest;
            wire [TAGBITWIDTH-1:0] TagOut;
            TaggingSystem #(
                .TAGBITWIDTH(TAGBITWIDTH)
            ) TaggingSys (
                .clk     (clk),
                .clk_en  (clk_en),
                .sync_rst(sync_rst),
                .TagREQ  (TagREQ),
                .TagOut  (TagOut)
            );
        //

        // Regsiters
            wire                       Tag_Request = TagRequest;
            wire [REGADDRBITWIDTH-1:0] ReadA_Address = RegAAddr;
            wire                       ReadA_En = RegAReadEn;
            wire    [DATABITWIDTH-1:0] ReadA_Data;
            wire [REGADDRBITWIDTH-1:0] ReadB_Address = RegBAddr;
            wire                       ReadB_En = RegBReadEn;
            wire    [DATABITWIDTH-1:0] ReadB_Data;
            wire [REGADDRBITWIDTH-1:0] Mem_Write_Address = '0; // TEMPORARY 0s
            wire                       Mem_Write_En = '0; // TEMPORARY 0s
            wire    [DATABITWIDTH-1:0] Mem_Write_Data = '0; // TEMPORARY 0s
            wire [REGADDRBITWIDTH-1:0] Write_Address = ;
            wire                       Write_En = ;
            wire    [DATABITWIDTH-1:0] Write_Data = ;
            wire                       RegistersSync;
            wire                       RegisterStallOut;
            RegisterFile #(
                .DATABITWIDTH(DATABITWIDTH),
                .REGISTERCOUNT(REGISTERCOUNT),
                .REGADDRBITWIDTH(REGADDRBITWIDTH)
            ) RegFile (
                .clk              (clk),
                .clk_en           (clk_en),
                .sync_rst         (sync_rst),
                .Tag_Request      (Tag_Request),
                .ReadA_Address    (ReadA_Address),
                .ReadA_En         (ReadA_En),
                .ReadA_Data       (ReadA_Data),
                .ReadB_Address    (ReadB_Address),
                .ReadB_En         (ReadB_En),
                .ReadB_Data       (ReadB_Data),
                .Mem_Write_Address(Mem_Write_Address),
                .Mem_Write_En     (Mem_Write_En),
                .Mem_Write_Data   (Mem_Write_Data),
                .Write_Address    (Write_Address),
                .Write_En         (Write_En),
                .Write_Data       (Write_Data),
                .RegistersSync    (RegistersSync),
                .RegisterStallOut (RegisterStallOut)
            );
        //
        
        // Forwarding
            wire RegAWriteEnIn = RegAWriteEn;
            wire Fwd_RegAReadEn = RegAReadEn;
            wire Fwd_RegAAddr = RegAAddr;
            wire RegAData = ReadA_Data;
            wire Fwd_RegBReadEn = RegBReadEn;
            wire Fwd_RegBAddr = RegBAddr;
            wire RegBData = ReadB_Data;
            wire Forward0Data = ;
            wire Forward1Valid = '0;
            wire Forward1Data = '0;
            wire Forward1RegAddr = '0;
            wire FwdADataOut;
            wire FwdBDataOut;
            ForwardingSystem #(
                .DATABITWIDTH   (DATABITWIDTH),
                .REGISTERCOUNT  (REGISTERCOUNT),
                .REGADDRBITWIDTH(REGADDRBITWIDTH)
            ) ForwardingSys (
                .clk            (clk),
                .clk_en         (clk_en),
                .sync_rst       (sync_rst),
                .RegAWriteEn    (RegAWriteEnIn),
                .RegAReadEn     (Fwd_RegAReadEn),
                .RegAAddr       (Fwd_RegAAddr),
                .RegAData       (RegAData),
                .RegBReadEn     (Fwd_RegBReadEn),
                .RegBAddr       (Fwd_RegBAddr),
                .RegBData       (RegBData),
                .Forward0Data   (Forward0Data),
                .Forward1Valid  (Forward1Valid),
                .Forward1Data   (Forward1Data),
                .Forward1RegAddr(Forward1RegAddr),
                .FwdADataOut    (FwdADataOut),
                .FwdBDataOut    (FwdBDataOut),
            );
        //

        // Immediates (Ready For Testing)
            wire                    Imm_ImmediateEn = ImmediateEn;
            wire                    Imm_UpperImmediateEn = UpperImmediateEn;
            wire [DATABITWIDTH-1:0] BDataIn = FwdBDataOut;
            wire [DATABITWIDTH-1:0] ImmediateIn = ImmediateOut;
            wire [DATABITWIDTH-1:0] BDataOut;
            ImmediateMux #(
                .DATABITWIDTH(DATABITWIDTH)
            ) ImmMux (
                .ImmediateEn     (Imm_ImmediateEn),
                .UpperImmediateEn(Imm_UpperImmediateEn),
                .BDataIn         (BDataIn),
                .ImmediateIn     (ImmediateIn),
                .BDataOut        (BDataOut)
            );
        //

        // Instruction Issue (Ready For Testing)
            wire                 [3:0] MinorOpcode = MinorOpcodeOut;
            wire                 [4:0] FunctionalUnitEnableIn = FunctionalUnitEnable;
            wire                 [1:0] WriteBackSourceIn = WritebackSource;
            wire                       RegAWriteEnIn = RegAWriteEn;
            wire                       InstructionTagValid = TagRequest;
            wire     [TAGBITWIDTH-1:0] InstructionTagIn = TagOut;
            wire                       WritebackEnIn = RegAWriteEn;
            wire     [TAGBITWIDTH-1:0] WritebackRegAddrIn = RegAAddr;
            wire    [DATABITWIDTH-1:0] RegADataIn = FwdADataOut;
            wire    [DATABITWIDTH-1:0] RegBDataIn = BDataOut;
            wire                       s1_BranchEn;
            wire    [DATABITWIDTH-1:0] s1_BranchComparisonValue;
            wire    [DATABITWIDTH-1:0] s1_BranchDest;
            wire                       s1_ALU0_Enable;
            wire                 [3:0] s1_ALU0_MinorOpcode;
            wire    [DATABITWIDTH-1:0] s1_ALU0_Data_InA;
            wire    [DATABITWIDTH-1:0] s1_ALU0_Data_InB;
            wire                       s1_ALU1_Enable;
            wire                 [3:0] s1_ALU1_MinorOpcode;
            wire    [DATABITWIDTH-1:0] s1_ALU1_Data_InA;
            wire    [DATABITWIDTH-1:0] s1_ALU1_Data_InB;
            wire                       IssueCongestionStallOut;
            wire                       s1_RegWriteEn;
            wire                 [1:0] s1_WriteBackSourceOut,
            wire [REGADDRBITWIDTH-1:0] s1_RegWriteAddrOut;
            InstructionIssue #(
                .DATABITWIDTH   (DATABITWIDTH),
                .TAGBITWIDTH    (TAGBITWIDTH),
                .REGADDRBITWIDTH(REGADDRBITWIDTH)
            ) InstIssue (
                .MinorOpcode            (MinorOpcode),
                .FunctionalUnitEnable   (FunctionalUnitEnableIn),
                .WriteBackSourceIn      (WriteBackSourceIn),
                .RegAWriteEnIn          (RegAWriteEnIn),
                .InstructionTagValid    (InstructionTagValid),
                .InstructionTagIn       (InstructionTagIn),
                .WritebackRegAddr       (WritebackRegAddr),
                .RegADataIn             (RegADataIn),
                .RegADataIn             (RegADataIn),
                .RegBDataIn             (RegBDataIn),
                .BranchEn               (s1_BranchEn),
                .ALU0_Enable            (s1_ALU0_Enable),
                .ALU1_Enable            (s1_ALU1_Enable),
                .MinorOpcode       (s1_ALU1_MinorOpcode),
                .Data_A          (s1_ALU1_Data_InA),
                .Data_B          (s1_ALU1_Data_InB),
                .IssueCongestionStallOut(IssueCongestionStallOut),
                .RegWriteEn             (s1_RegWriteEn),
                .WriteBackSourceOut     (s1_WriteBackSourceOut),
                .RegWriteAddrOut        (s1_RegWriteAddrOut)
            );
        //

        // Pipeline Buffer - Stage 0 (Ready For Testing)
            localparam S1BUFFERINBITWIDTH_FUE = 3;
            localparam S1BUFFERINBITWIDTH_META = (DATABITWIDTH * 2) + 4;
            localparam S1BUFFERINBITWIDTH_WRITEBACK = REGADDRBITWIDTH + 3;

            wire [S1BUFFERINBITWIDTH_FUE-1:0]s1_FunctionalUnitEnable = {s1_BranchEn, s1_ALU0_Enable, s1_ALU1_Enable};
            wire [S1BUFFERINBITWIDTH_META-1:0]s1_MetaDataIssue = {s1_MinorOpcode, s1_Data_A, s1_Data_B};
            wire [S1BUFFERINBITWIDTH_WRITEBACK-1:0] s1_RegWriteIssue = {s1_RegWriteEn, s1_WriteBackSourceOut, s1_RegWriteAddrOut};

            localparam S1BUFFERBITWIDTH = S1BUFFERINBITWIDTH_FUE + S1BUFFERINBITWIDTH_META + S1BUFFERINBITWIDTH_WRITEBACK;
            reg  [S1BUFFERBITWIDTH-1:0] Stage1Buffer;
            wire                        Stage1BufferTrigger = clk_en || sync_rst;
            wire [S1BUFFERBITWIDTH-1:0] NextStage1Buffer = (sync_rst) ? 0 : {s1_FunctionalUnitEnable, s1_MetaDataIssue,s1_RegWriteIssue};
            always_ff @(posedge clk) begin
                if (Stage1BufferTrigger) begin
                    Stage1Buffer <= NextStage1Buffer;
                end
            end
            
            localparam S1BUFFEROUTBITWIDTH_METAUPPER = S1BUFFERINBITWIDTH_META + S1BUFFERINBITWIDTH_WRITEBACK;

            wire [S1BUFFERINBITWIDTH_FUE-1:0]s2_FunctionalUnitEnable = Stage1Buffer[S1BUFFERBITWIDTH-1:S1BUFFEROUTBITWIDTH_METAUPPER];
            wire [S1BUFFERINBITWIDTH_META-1:0]s2_MetaDataIssue = Stage1Buffer[S1BUFFEROUTBITWIDTH_METAUPPER-1:S1BUFFERINBITWIDTH_WRITEBACK];
            wire [S1BUFFERINBITWIDTH_WRITEBACK-1:0]s2_RegWriteIssue = Stage1Buffer[S1BUFFERINBITWIDTH_WRITEBACK-1:0];
        //

    //

    // Stage 2 
    // Notes: Execute - Short
    // In:
    // Out:
        // OLD:
        // s2_BranchIssue = {s1_BranchEn, s1_BranchComparisonValue, s1_BranchDest};
        // s2_ALU0Issue = {s1_ALU0_Enable, s1_ALU0_MinorOpcode, s1_ALU0_Data_InA, s1_ALU0_Data_InB};
        // s2_ALU1Issue = {s1_ALU1_Enable, s1_ALU1_MinorOpcode, s1_ALU1_Data_InA, s1_ALU1_Data_InB};
        // s2_RegWriteIssue = {s1_RegWriteEn, s1_WriteBackSourceOut, s1_RegWriteAddrOut};

        // NEW:
        // s1_FunctionalUnitEnable = {s1_BranchEn, s1_ALU0_Enable, s1_ALU1_Enable};
        // s1_MetaDataIssue = {s1_MinorOpcode, s1_Data_A, s1_Data_B};
        // s1_RegWriteIssue = {s1_RegWriteEn, s1_WriteBackSourceOut, s1_RegWriteAddrOut};

    //

    // Stage 3+ 
    // Notes: Execute - Long
    // In:
    // Out:
    
    //

endmodule