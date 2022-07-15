module CPU_TopLevel #(
    parameter DATABITWIDTH = 16
)(
    input clk,
    input clk_en,
    input sync_rst,

    input  SystemEn,
    output HaltOut, // TODO:

    // Test Outputs
    output [DATABITWIDTH-1:0] RegisterWriteData_OUT,
    output                    RegisterWriteEn_OUT,
    output              [3:0] RegisterWriteAddr_OUT
);
    localparam REGISTERCOUNT = 16;
    localparam REGADDRBITWIDTH = $clog2(REGISTERCOUNT);
    localparam TAGADDRESSPADDING = 2;
    localparam TAGBITWIDTH = REGADDRBITWIDTH + TAGADDRESSPADDING;

    assign RegisterWriteData_OUT = Write_Data;
    assign RegisterWriteEn_OUT = Write_En;
    assign RegisterWriteAddr_OUT = Write_Address;

    assign HaltOut = 1'b0;


    // Debug output
        always_ff @(posedge clk) begin
            $display("CPU - RegEn:Addr:Data - %0b:%0h:%0h", RegisterWriteEn, s2_RegWriteAddrOut, WritebackResultOut);
            $display("CPU - RegAAddr       - %0b", RegAAddr);
        end
    //


    // Stage 0 (Ready for testing)
    // Notes: Fetch
    // Inputs: SystemEn, StallEn, InstructionAddress
    // Output Buffer: s1_InstructionValid, s1_InstructionOut
        // Instruction ROM
            wire [15:0] InstructionAddress = InstructionAddrOut[15:0];
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
            wire        Stage0BufferTrigger = (SystemEn && clk_en) || sync_rst;
            wire [16:0] NextStage0Buffer = (sync_rst) ? 0 : {s0_InstructionValid, s0_InstructionOut};
            always_ff @(posedge clk) begin
                if (Stage0BufferTrigger) begin
                    Stage0Buffer <= NextStage0Buffer;
                end
            end
            wire        s1_InstructionValid = Stage0Buffer[16];
            wire [15:0] s1_InstructionOut = Stage0Buffer[15:0];
        //

        // Debug output
            always_ff @(posedge clk) begin
                $display("SystemEn:StallEn - %0b:%0b", SystemEn, StallEn);
                $display("State 0 Buffer - PC(d/h):InstValid:Inst - %0d/%0h:%0b:%0h", InstructionAddress, InstructionAddress, s0_InstructionValid, s0_InstructionOut);
            end
        //
    //

    // Stage 1  (Ready For Testing)
    // Notes: Decode
    // Inputs: s1_InstructionValid, s1_InstructionOut,
    // Output Buffer: s2_FunctionalUnitEnable, s2_MetaDataIssue, s2_RegWriteIssue
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
            wire RegisterStallIn = RegisterStall;
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

        // Regsiters (Ready For Testing)
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
            wire [REGADDRBITWIDTH-1:0] Write_Address = WritebackRegAddr;
            wire                       Write_En = RegisterWriteEn;
            wire    [DATABITWIDTH-1:0] Write_Data = WritebackResultOut;
            wire                       RegistersSync;
            wire                       RegisterStall;
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
                .RegisterStallOut (RegisterStall)
            );
        //
        
        // Forwarding (Ready For Testing)
            wire RegAWriteEnIn = RegAWriteEn;
            wire Fwd_RegAReadEn = RegAReadEn;
            wire Fwd_RegAAddr = RegAAddr;
            wire RegAData = ReadA_Data;
            wire Fwd_RegBReadEn = RegBReadEn;
            wire Fwd_RegBAddr = RegBAddr;
            wire RegBData = ReadB_Data;
            wire Forward0Data = WritebackResultOut;
            wire Forward1Valid = '0; // TEMPORARY 0s
            wire Forward1Data = '0; // TEMPORARY 0s
            wire Forward1RegAddr = '0; // TEMPORARY 0s
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
            wire                       Issue_RegAWriteEnIn = RegAWriteEn;
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
            wire                       s1_ALU1_Enable;
            wire                 [3:0] s1_MinorOpcode;
            wire    [DATABITWIDTH-1:0] s1_Data_InA;
            wire    [DATABITWIDTH-1:0] s1_Data_InB;
            wire                       IssueCongestionStallOut;
            wire                       s1_RegWriteEn;
            wire                 [1:0] s1_WriteBackSourceOut;
            wire [REGADDRBITWIDTH-1:0] s1_RegWriteAddrOut;
            InstructionIssue #(
                .DATABITWIDTH   (DATABITWIDTH),
                .TAGBITWIDTH    (TAGBITWIDTH),
                .REGADDRBITWIDTH(REGADDRBITWIDTH)
            ) InstIssue (
                .MinorOpcode            (MinorOpcode),
                .FunctionalUnitEnable   (FunctionalUnitEnableIn),
                .WriteBackSourceIn      (WriteBackSourceIn),
                .RegAWriteEnIn          (Issue_RegAWriteEnIn),
                .InstructionTagValid    (InstructionTagValid),
                .InstructionTagIn       (InstructionTagIn),
                .WritebackEnIn          (WritebackEnIn),
                .WritebackRegAddr       (WritebackRegAddr),
                .RegADataIn             (RegADataIn),
                .RegBDataIn             (RegBDataIn),
                .BranchEn               (s1_BranchEn),
                .ALU0_Enable            (s1_ALU0_Enable),
                .ALU1_Enable            (s1_ALU1_Enable),
                .ALU_MinorOpcode        (s1_MinorOpcode),
                .Data_A                 (s1_Data_A),
                .Data_B                 (s1_Data_B),
                .IssueCongestionStallOut(IssueCongestionStallOut),
                .RegWriteEn             (s1_RegWriteEn),
                .WriteBackSourceOut     (s1_WriteBackSourceOut),
                .RegWriteAddrOut        (s1_RegWriteAddrOut)
            );
        //

        // Pipeline Buffer - Stage 1 (Ready For Testing)
            localparam S1BUFFERINBITWIDTH_FUE = 3;
            localparam S1BUFFERINBITWIDTH_META = (DATABITWIDTH * 2) + 4;
            localparam S1BUFFERINBITWIDTH_WRITEBACK = REGADDRBITWIDTH + 3;

            wire [S1BUFFERINBITWIDTH_FUE-1:0]s1_FunctionalUnitEnable = {s1_BranchEn, s1_ALU0_Enable, s1_ALU1_Enable};
            wire [S1BUFFERINBITWIDTH_META-1:0]s1_MetaDataIssue = {s1_MinorOpcode, s1_Data_A, s1_Data_B};
            wire [S1BUFFERINBITWIDTH_WRITEBACK-1:0] s1_RegWriteIssue = {s1_RegWriteEn, s1_WriteBackSourceOut, s1_RegWriteAddrOut};

            localparam S1BUFFERBITWIDTH = S1BUFFERINBITWIDTH_FUE + S1BUFFERINBITWIDTH_META + S1BUFFERINBITWIDTH_WRITEBACK;
            reg  [S1BUFFERBITWIDTH-1:0] Stage1Buffer;
            wire                        Stage1BufferTrigger = (SystemEn && clk_en) || sync_rst;
            wire [S1BUFFERBITWIDTH-1:0] NextStage1Buffer = (sync_rst) ? 0 : {s1_FunctionalUnitEnable, s1_MetaDataIssue, s1_RegWriteIssue};
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

    // Stage 2 (Ready for testing)
    // Notes: Execute - Short
    // In:
    // Out:
        // Stage 2 wire breakout (Ready for testing)
            // s2_FunctionalUnitEnable = {s1_BranchEn, s1_ALU0_Enable, s1_ALU1_Enable};
            // s2_MetaDataIssue = {s1_MinorOpcode, s1_Data_A, s1_Data_B};
            // s2_RegWriteIssue = {s1_RegWriteEn, s1_WriteBackSourceOut, s1_RegWriteAddrOut};
            wire s2_BranchEn = s2_FunctionalUnitEnable[2];
            wire s2_ALU0_Enable = s2_FunctionalUnitEnable[1];
            wire s2_ALU1_Enable = s2_FunctionalUnitEnable[0];

            wire              [3:0] s2_MinorOpcode = s2_MetaDataIssue[((DATABITWIDTH*2)+4)-1:(DATABITWIDTH*2)];
            wire [DATABITWIDTH-1:0] s2_Data_A = s2_MetaDataIssue[(DATABITWIDTH*2)-1:DATABITWIDTH];
            wire [DATABITWIDTH-1:0] s2_Data_B = s2_MetaDataIssue[DATABITWIDTH-1:0];

            wire                       s2_RegWriteEn = s2_RegWriteIssue[REGADDRBITWIDTH+2];
            wire                 [1:0] s2_WriteBackSourceOut = s2_RegWriteIssue[(REGADDRBITWIDTH+2)-1:REGADDRBITWIDTH];
            wire [REGADDRBITWIDTH-1:0] s2_RegWriteAddrOut = s2_RegWriteIssue[REGADDRBITWIDTH-1:0];
        //

        // Program Counter (Ready for testing)
            wire                    PCEn = SystemEn;
            wire                    PC_StallEn = BranchStall;
            wire                    BranchEn = s2_BranchEn;
            wire [DATABITWIDTH-1:0] ComparisonValue = s2_Data_A;
            wire [DATABITWIDTH-1:0] BranchDest = s2_Data_B;
            wire [DATABITWIDTH-1:0] InstructionAddrOut;
            wire [DATABITWIDTH-1:0] JumpAndLinkAddrOut;
            ProgramCounter #(
                .DATABITWIDTH(16)
            ) PC (
                .clk               (clk),
                .clk_en            (clk_en),
                .sync_rst          (sync_rst),
                .PCEn              (PCEn),
                .StallEn           (PC_StallEn),
                .BranchEn          (BranchEn),
                .ComparisonValue   (ComparisonValue),
                .BranchDest        (BranchDest),
                .InstructionAddrOut(InstructionAddrOut),
                .JumpAndLinkAddrOut(JumpAndLinkAddrOut)
            );
        //

        // Simple ALU 0 (Ready for testing)
            wire [DATABITWIDTH-1:0] ALU0_Data_InA = s2_Data_A;
            wire [DATABITWIDTH-1:0] ALU0_Data_InB = s2_Data_B;
            wire                    ALU0_Enable = s2_ALU0_Enable;
            wire              [3:0] ALU0_Opcode = s2_MinorOpcode;
            wire [DATABITWIDTH-1:0] ALU0_ResultOut;
            ALU_Simple0 #(
                .BITWIDTH(16)
            ) ALU_0 (
                .Data_InA  (ALU0_Data_InA),
                .Data_InB  (ALU0_Data_InB),
                .ALU_Enable(ALU0_Enable),
                .Opcode    (ALU0_Opcode),
                .ResultOut (ALU0_ResultOut)
            );
        //  

        // Simple ALU 1 (Ready for testing)
            wire [DATABITWIDTH-1:0] ALU1_Data_InA = s2_Data_A;
            wire [DATABITWIDTH-1:0] ALU1_Data_InB = s2_Data_B;
            wire                    ALU1_Enable = s2_ALU1_Enable;
            wire              [3:0] ALU1_Opcode = s2_MinorOpcode;
            wire [DATABITWIDTH-1:0] ALU1_ResultOut;
            ALU_Simple1 #(
                .BITWIDTH(16)
            ) ALU_1 (
                .Data_InA  (ALU1_Data_InA),
                .Data_InB  (ALU1_Data_InB),
                .ALU_Enable(ALU1_Enable),
                .Opcode    (ALU1_Opcode),
                .ResultOut (ALU1_ResultOut)
            );
        //

        // Complex ALU
            // TODO:
        //

        // Load Store Unit
            // TODO:
        //

        // Writeback Mux (Ready for testing)
            wire                       WBMux_RegAWriteEn = s2_RegWriteEn;
            wire [REGADDRBITWIDTH-1:0] WBMux_RegWriteAddr = s2_RegWriteAddrOut;
            wire                 [1:0] WBMux_WritebackSource = s2_WriteBackSourceOut;
            wire    [DATABITWIDTH-1:0] JumpAndLinkResultIn = JumpAndLinkAddrOut;
            wire    [DATABITWIDTH-1:0] ALU0ResultIn = ALU0_ResultOut;
            wire    [DATABITWIDTH-1:0] ALU1ResultIn = ALU1_ResultOut;
            wire    [DATABITWIDTH-1:0] WritebackResultOut;
            wire [REGADDRBITWIDTH-1:0] WritebackRegAddr;
            wire                       RegisterWriteEn;
            WritebackMux #(
                .DATABITWIDTH(16)
            ) WBMux (
                .RegAWriteEn        (WBMux_RegAWriteEn),
                .RegWriteAddr       (WBMux_RegWriteAddr),
                .WritebackSource    (WBMux_WritebackSource),
                .JumpAndLinkResultIn(JumpAndLinkResultIn),
                .ALU0ResultIn       (ALU0ResultIn),
                .ALU1ResultIn       (ALU1ResultIn),
                .WritebackResultOut (WritebackResultOut),
                .WritebackRegAddr   (WritebackRegAddr),
                .RegisterWriteEn    (RegisterWriteEn)
            );
        //
    //

    // Stage 3+ 
    // Notes: Execute - Long
    // In:
    // Out:
    
    //

endmodule