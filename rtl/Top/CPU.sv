module CPU #(
    parameter DATABITWIDTH = 16
)(
    input clk,
    input clk_en,
    input sync_rst,

    // Control and Status
    input        SystemEn,
    output       HaltOut,
    output       SoftwareResetOut,
    output [3:0] ResetVector,
    input        ResetResponse,

    // Memory Flashing
    input                    InstFlashEn,
    input                    DataFlashEn,
    input              [9:0] FlashAddr,
    input [DATABITWIDTH-1:0] FlashData,


    // IO Out Handshake
    output                    IOOutACK,
    input                     IOOutREQ,
    output              [3:0] IOMinorOpcode,
    output [DATABITWIDTH-1:0] IOOutAddress,
    output [DATABITWIDTH-1:0] IOOutData,
    output              [3:0] IOOutDestReg,

    // IO In Handshake
    input                     IOInACK,
    output                    IOInREQ,
    input               [3:0] IOInDestReg,
    input  [DATABITWIDTH-1:0] IOInData,

    // Test Outputs
    output [DATABITWIDTH-1:0] RegisterWriteData_OUT,
    output                    RegisterWriteEn_OUT,
    output              [3:0] RegisterWriteAddr_OUT    
);
    localparam REGISTERCOUNT = 16;
    localparam REGADDRBITWIDTH = (REGISTERCOUNT == 1) ? 1 : $clog2(REGISTERCOUNT);
    localparam TAGADDRESSPADDING = 2;
    localparam TAGBITWIDTH = REGADDRBITWIDTH + TAGADDRESSPADDING;
    localparam MEMWB_INPUTPORTCOUNT = 4;
    localparam MEMWB_PORTADDRWIDTH = (MEMWB_INPUTPORTCOUNT == 1) ? 1 : $clog2(MEMWB_INPUTPORTCOUNT);
    localparam MEMWB_COMPLEXALUPORT = 0;
    localparam MEMWB_FIXEDMEMPORT = 1;
    localparam MEMWB_CACHEPORT = 2;
    localparam MEMWB_IOPORT = 3;

    assign RegisterWriteData_OUT = Write_Data;
    assign RegisterWriteEn_OUT = Write_En;
    assign RegisterWriteAddr_OUT = Write_Address;


    // Debug output
        always_ff @(posedge clk) begin
            // $display("CPU - WBSource:AAddr  - %0h:%0h", WritebackSource, RegAAddr);
            $display("CPU - Minor:DataA:B   - %0h:%0h:%0h", s2_MinorOpcode, s2_Data_A, s2_Data_B);
            // $display("CPU - WBEn:Addr:Src   - %0b:%0h:%0h", WBMux_RegAWriteEn, WBMux_RegWriteAddr, WBMux_WritebackSource);
            $display("CPU - RegEn:Addr:Data - %0b:%0h:%0h", Write_En, Write_Address, Write_Data);
            // $display("CPU - DecodedImm      - %0h", ImmediateOut);
            // $display("CPU - ImmBDataIn:ImEn     - %0h:%0b", BDataIn, ImmediateEn);
            // $display("CPU - ImmADataIn:UpEn - %0h:%0b", ADataIn, UpperImmediateEn);
            // $display("CPU - MuxedImm            - %0h", BDataOut);
            // // $display("CPU - RegAAddr       - %0b", s1_RegWriteAddrOut);ImmediateOut
            // $display("CPU - Compare:DestB:J     - %0h:%0h:%0h", ComparisonValue, BranchDest, PC_JumpDest);
            // $display("---------------------------------------------");
            // $display("CPU - LSREQ:ACK:Op:Dest   - %0b:%0b:%0h:%0h", s1_LoadStoreFIFO_dOutREQ, s1_LoadStoreFIFO_dOutACK, s2_LoadStore_MinorOpcode, s2_LoadStore_DestinationRegister);
            // $display("CPU - LSMemAddr:Data      - %0h:%0h", s2_LoadStore_MemoryAddress, s2_LoadStore_StoreValue);
            // $display("- - - - - - - - - - - - - - - - - - - - - - -");
            // $display("CPU - FMiREQ:ACK:Op:Dest  - %0b:%0b:%0h:%0h", FixedMemory_REQ, FixedMemory_ACK, FixedMemory_MinorOpcode, FixedMemory_DestinationRegister);
            // $display("CPU - FMiMemAddr:Data     - %0h:%0h", FixedMemory_MemoryAddress, FixedMemory_StoreValue);
            // $display("- - - - - - - - - - - - - - - - - - - - - - -");
            // $display("CPU - FMoMemREQ:ACK       - %0h:%0h", FixedMem_Writeback_REQ, FixedMem_Writeback_ACK);
            // $display("CPU - FMoMemAddr:Data     - %0h:%0h", FixedMem_DestRegisterOut, FixedMem_DataOut);
            // $display("- - - - - - - - - - - - - - - - - - - - - - -");
            // $display("CPU - FIFI1iREQ:ACK:Data  - %0b:%0b:%0h", s3_FixedMemoryFIFO_dInREQ, s3_FixedMemoryFIFO_dInACK, s3_FixedMemoryFIFO_dIN);
            // $display("---------------------------------------------");
            // $display("CPU - FIFO1oREQ:ACK:Data  - %0b:%0b:%0h", s3_FixedMemoryFIFO_dOutREQ, s3_FixedMemoryFIFO_dOutACK, s3_FixedMemoryFIFO_dOUT);
            // $display("---------------------------------------------");
            $display("CPU - StallReg:Issue      - %0b:%0b", RegisterStallIn, IssueCongestionStallIn);
            $display("CPU - PCEn:Stl:Br:Jmp     - %0b:%0b:%0b:%0b", PCEn, PC_StallEn, BranchEn, PC_JumpEn); 
        end
    //

    // Stage 0 (Ready for testing)
    // Notes: Fetch
    // Inputs: SystemEn, StallEn, InstructionAddress
    // Output Buffer: s1_InstructionValid, s1_InstructionOut
        // Instruction ROM
            wire [15:0] InstructionAddress = InstructionAddrOut[15:0];
            wire [15:0] s0_InstructionOut;
            InstructionMemory InstMem (
                .clk          (clk),
                .clk_en       (clk_en),
                .FlashEn      (InstFlashEn),
                .FlashAddr    (FlashAddr),
                .FlashData    (FlashData),
                .ReadAddressIn(InstructionAddress),
                .DataOut      (s0_InstructionOut)
            );
            // InstructionROM InstROM (
            //     .InstructionAddress(InstructionAddress),
            //     .InstructionOut    (s0_InstructionOut)
            // );
        //

        // Instruction Valid Generation
            wire s0_InstructionValid = SystemEn && ~StallEn;

            reg  StallDelayBuffer;
            wire StallDelayBufferTrigger = clk_en || sync_rst;
            wire NextStallDelayBuffer = RegisterStall && ~sync_rst;
            always_ff @(posedge clk) begin
                if (StallDelayBufferTrigger) begin
                    StallDelayBuffer <= NextStallDelayBuffer;
                end
            end
        //

        // Pipeline Buffer - Stage 0
            reg  [16:0] Stage0Buffer;
            // wire        Stage0BufferTrigger = (SystemEn && clk_en) || sync_rst;
            wire        Stage0BufferTrigger = (SystemEn && ~RegisterStall && ~StallDelayBuffer && clk_en) || sync_rst;
            wire [16:0] NextStage0Buffer = (sync_rst) ? 0 : {s0_InstructionValid, s0_InstructionOut};
            always_ff @(posedge clk) begin
                if (Stage0BufferTrigger) begin
                    Stage0Buffer <= NextStage0Buffer;
                end
            end
            // wire        s1_InstructionValid = (Stage0Buffer[16] && ~StallDelayBuffer) || (~Stage0Buffer[16] && StallDelayBuffer);
            wire        s1_InstructionValid = (Stage0Buffer[16] && ~StallDelayBuffer);
            wire [15:0] s1_InstructionOut = Stage0Buffer[15:0];
        //

        // Debug output
            always_ff @(posedge clk) begin
                $display("State 0 Buffer - PC(d/h):InstValid:Inst - %0d/%0h:%0b:%0h", InstructionAddress, InstructionAddress, s0_InstructionValid, s0_InstructionOut);
            end
        //
    //

    // Stage 1  (Ready For Testing)
    // Notes: Decode
    // Inputs: s1_InstructionValid, s1_InstructionOut,
    // Output Buffer: s2_FunctionalUnitEnable, s2_MetaDataIssue, s2_RegWriteIssue
        // Instruction Decoder (Ready For Testing)
            wire                [15:0] InstructionIn = s1_InstructionOut;
            wire                       InstructionInValid = s1_InstructionValid;
            wire                       DirtyBitTrigger;
            wire                 [4:0] FunctionalUnitEnable;
            wire                 [1:0] WritebackSource;
            wire                 [3:0] MinorOpcodeOut;
            wire                       ImmediateEn;
            wire                       UpperImmediateEn;
            wire    [DATABITWIDTH-1:0] ImmediateOut;
            wire                       RegAReadEn;
            wire                       RegAWriteEn;
            wire [REGADDRBITWIDTH-1:0] RegAAddr;
            wire                       RegBReadEn;
            wire [REGADDRBITWIDTH-1:0] RegBAddr;
            wire                       BranchStall;
            wire                       s1_RelativeEn;
            wire    [DATABITWIDTH-1:0] s1_BranchOffset;
            wire                       JumpEn;
            wire                       s1_JumpAndLinkEn;
            wire                       HaltEn;
            InstructionDecoder #(
                .DATABITWIDTH(DATABITWIDTH)
            ) InstDecoder (
                .clk                 (clk),
                .InstructionIn       (InstructionIn),
                .InstructionInValid  (InstructionInValid),
                .DirtyBitTrigger     (DirtyBitTrigger),
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
                .BranchStall         (BranchStall),
                .RelativeEn          (s1_RelativeEn),
                .BranchOffset        (s1_BranchOffset),
                .JumpEn              (JumpEn),
                .JumpAndLinkEn       (s1_JumpAndLinkEn),
                .HaltEn              (HaltEn)
            );
        //

        // Stall Control (Ready For Testing)
            wire InstructionValid = s1_InstructionValid;
            wire BranchStallIn = BranchStall;
            wire RegisterStallIn = RegisterStall;
            wire IssueCongestionStallIn = IssueCongestionStallOut;
            wire BranchStallDisable;
            wire Halted;
            wire LoadStoreStallEn;
            wire StallEn;
            SystemControl SysCtl (
                .clk                   (clk),
                .clk_en                (clk_en),
                .sync_rst              (sync_rst),
                .InstructionValid      (InstructionValid),

                .BAddrIn              (RegBAddr),
                .MinorOpcodeIn        (MinorOpcodeOut),
                .FunctionalUnitEnable (FunctionalUnitEnable),
                .SoftwareResetOut     (SoftwareResetOut),
                .ResetVectorOut       (ResetVector),
                .ResetResponseIn      (ResetResponse),

                .BranchStallIn         (BranchStallIn),
                .RegisterStallIn       (RegisterStallIn),
                .IssueCongestionStallIn(IssueCongestionStallIn),
                .HaltStallIn           (HaltEn),
                .BranchStallDisable    (BranchStallDisable),
                .Halted                (Halted),
                .LoadStoreStallEn      (LoadStoreStallEn),
                .StallEn               (StallEn)
            );
        //

        // Regsiters (Ready For Testing)
            wire                       Reg_DirtyBitTrigger = DirtyBitTrigger;
            wire [REGADDRBITWIDTH-1:0] ReadA_Address = RegAAddr;
            wire                       ReadA_En = RegAReadEn;
            wire    [DATABITWIDTH-1:0] ReadA_Data;
            wire [REGADDRBITWIDTH-1:0] ReadB_Address = RegBAddr;
            wire                       ReadB_En = RegBReadEn;
            wire    [DATABITWIDTH-1:0] ReadB_Data;
            wire [REGADDRBITWIDTH-1:0] Mem_Write_Address = MemWBMux_RegWriteAddr;
            wire                       Mem_Write_En = MemWBMux_RegWriteEn;
            wire    [DATABITWIDTH-1:0] Mem_Write_Data = MemWBMux_RegWriteData;
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
                .DirtyBitTrigger  (Reg_DirtyBitTrigger),
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
            assign HaltOut = RegistersSync && StallEn && Halted;
        //

        // Forwarding (Ready For Testing)
            wire                       RegAWriteEnIn = RegAWriteEn;
            wire                       Fwd_RegAReadEn = RegAReadEn;
            wire [REGADDRBITWIDTH-1:0] Fwd_RegAAddr = RegAAddr;
            wire    [DATABITWIDTH-1:0] RegAData = ReadA_Data;
            wire                       Fwd_RegBReadEn = RegBReadEn;
            wire [REGADDRBITWIDTH-1:0] Fwd_RegBAddr = RegBAddr;
            wire    [DATABITWIDTH-1:0] RegBData = ReadB_Data;
            wire    [DATABITWIDTH-1:0] Forward0Data = WritebackResultOut;
            wire                       Forward1Valid = MemWBMux_RegWriteEn;
            wire    [DATABITWIDTH-1:0] Forward1Data = MemWBMux_RegWriteData;
            wire [REGADDRBITWIDTH-1:0] Forward1RegAddr = MemWBMux_RegWriteAddr;
            wire    [DATABITWIDTH-1:0] FwdADataOut;
            wire    [DATABITWIDTH-1:0] FwdBDataOut;
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
                .FwdBDataOut    (FwdBDataOut)
            );
        //

        // Immediates (Ready For Testing)
            wire                    Imm_ImmediateEn = ImmediateEn;
            wire                    Imm_UpperImmediateEn = UpperImmediateEn;
            wire [DATABITWIDTH-1:0] BDataIn = FwdBDataOut;
            wire [DATABITWIDTH-1:0] ADataIn = FwdADataOut;
            wire [DATABITWIDTH-1:0] ImmediateIn = ImmediateOut;
            wire [DATABITWIDTH-1:0] BDataOut;
            ImmediateMux #(
                .DATABITWIDTH(DATABITWIDTH)
            ) ImmMux (
                .ImmediateEn     (Imm_ImmediateEn),
                .UpperImmediateEn(Imm_UpperImmediateEn),
                .ADataIn         (ADataIn),
                .BDataIn         (BDataIn),
                .ImmediateIn     (ImmediateIn),
                .BDataOut        (BDataOut)
            );
        //

        // Instruction Issue (Ready For Testing)
            wire                 [3:0] MinorOpcode = MinorOpcodeOut;
            wire                 [4:0] FunctionalUnitEnableIn = FunctionalUnitEnable;
            wire                 [1:0] WriteBackSourceIn = WritebackSource;
            wire                       WritebackEnIn = RegAWriteEn;
            wire [REGADDRBITWIDTH-1:0] WritebackRegAddrIn = RegAAddr;
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
            wire                       s1_LoadStore_REQ = s1_LoadStoreFIFO_dInREQ;
            wire                       s1_LoadStore_ACK;
            wire                       IssueCongestionStallOut;
            wire                       s1_RegWriteEn;
            wire                 [1:0] s1_WriteBackSourceOut;
            wire [REGADDRBITWIDTH-1:0] s1_RegWriteAddrOut;
            InstructionIssue #(
                .DATABITWIDTH   (DATABITWIDTH),
                .TAGBITWIDTH    (TAGBITWIDTH),
                .REGADDRBITWIDTH(REGADDRBITWIDTH)
            ) InstIssue (
                .clk                    (clk),
                .clk_en                 (clk_en),
                .sync_rst               (sync_rst),
                .StallIn                (LoadStoreStallEn),
                .MinorOpcode            (MinorOpcode),
                .FunctionalUnitEnable   (FunctionalUnitEnableIn),
                .WriteBackSourceIn      (WriteBackSourceIn),
                .WritebackEnIn          (WritebackEnIn),
                .WritebackRegAddr       (WritebackRegAddrIn),
                .RegADataIn             (RegADataIn),
                .RegBDataIn             (RegBDataIn),
                .BranchEn               (s1_BranchEn),
                .ALU0_Enable            (s1_ALU0_Enable),
                .ALU1_Enable            (s1_ALU1_Enable),
                .ALU_MinorOpcode        (s1_MinorOpcode),
                .Data_A                 (s1_Data_InA),
                .Data_B                 (s1_Data_InB),
                .LoadStore_REQ          (s1_LoadStore_REQ),
                .LoadStore_ACK          (s1_LoadStore_ACK),
                .IssueCongestionStallOut(IssueCongestionStallOut),
                .RegWriteEn             (s1_RegWriteEn),
                .WriteBackSourceOut     (s1_WriteBackSourceOut),
                .RegWriteAddrOut        (s1_RegWriteAddrOut)
            );
        //

        // Pipeline Buffer - Stage 1 (Ready For Testing)
            localparam S1BUFFERINBITWIDTH_FUE = DATABITWIDTH + 4;
            localparam S1BUFFERINBITWIDTH_META = (DATABITWIDTH * 2) + 4;
            localparam S1BUFFERINBITWIDTH_WRITEBACK = REGADDRBITWIDTH + 4;

            wire [S1BUFFERINBITWIDTH_FUE-1:0]s1_FunctionalUnitEnable = {s1_BranchEn, s1_ALU0_Enable, s1_ALU1_Enable, s1_RelativeEn, s1_BranchOffset};
            wire [S1BUFFERINBITWIDTH_META-1:0]s1_MetaDataIssue = {s1_MinorOpcode, s1_Data_InA, s1_Data_InB};
            wire [S1BUFFERINBITWIDTH_WRITEBACK-1:0] s1_RegWriteIssue = {s1_JumpAndLinkEn, s1_RegWriteEn, s1_WriteBackSourceOut, s1_RegWriteAddrOut};

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

        // Load Store Issue FIFO  (Ready For Testing)
            localparam S1LSUFIFOBITWIDTH = 4 + (DATABITWIDTH*2) + REGADDRBITWIDTH;
            wire                         s1_LoadStoreFIFO_dInREQ;
            wire                         s1_LoadStoreFIFO_dInACK = s1_LoadStore_ACK;
            wire [S1LSUFIFOBITWIDTH-1:0] s1_LoadStoreFIFO_dIN = {s1_MinorOpcode, s1_Data_InB, s1_Data_InA, s1_RegWriteAddrOut};   
            wire                         s1_LoadStoreFIFO_dOutREQ = s2_LoadStore_REQ;
            wire                         s1_LoadStoreFIFO_dOutACK;
            wire [S1LSUFIFOBITWIDTH-1:0] s1_LoadStoreFIFO_dOUT;

            HandshakeFIFO #(
                .DATABITWIDTH     (S1LSUFIFOBITWIDTH),
                .FIFODEPTH        (4),
                .FIFODEPTHBITWIDTH(2)
            ) s1_LoadStoreFIFO (
                .clk     (clk),
                .clk_en  (clk_en),
                .sync_rst(sync_rst),
                .dInREQ  (s1_LoadStoreFIFO_dInREQ),
                .dInACK  (s1_LoadStoreFIFO_dInACK),
                .dIN     (s1_LoadStoreFIFO_dIN),
                .dOutREQ (s1_LoadStoreFIFO_dOutREQ),
                .dOutACK (s1_LoadStoreFIFO_dOutACK),
                .dOUT    (s1_LoadStoreFIFO_dOUT)
            );
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
            wire                    s2_BranchEn = s2_FunctionalUnitEnable[DATABITWIDTH+3];
            wire                    s2_ALU0_Enable = s2_FunctionalUnitEnable[DATABITWIDTH+2];
            wire                    s2_ALU1_Enable = s2_FunctionalUnitEnable[DATABITWIDTH+1];
            wire                    s2_RelativeEn = s2_FunctionalUnitEnable[DATABITWIDTH];
            wire [DATABITWIDTH-1:0] s2_BranchOffset = s2_FunctionalUnitEnable[DATABITWIDTH-1:0];

            wire              [3:0] s2_MinorOpcode = s2_MetaDataIssue[((DATABITWIDTH*2)+4)-1:(DATABITWIDTH*2)];
            wire [DATABITWIDTH-1:0] s2_Data_A = s2_MetaDataIssue[(DATABITWIDTH*2)-1:DATABITWIDTH];
            wire [DATABITWIDTH-1:0] s2_Data_B = s2_MetaDataIssue[DATABITWIDTH-1:0];

            wire                       s2_JumpAndLinkEn = s2_RegWriteIssue[REGADDRBITWIDTH+3];
            wire                       s2_RegWriteEn = s2_RegWriteIssue[REGADDRBITWIDTH+2];
            wire                 [1:0] s2_WriteBackSourceOut = s2_RegWriteIssue[(REGADDRBITWIDTH+2)-1:REGADDRBITWIDTH];
            wire [REGADDRBITWIDTH-1:0] s2_RegWriteAddrOut = s2_RegWriteIssue[REGADDRBITWIDTH-1:0];

        //

        // Program Counter (Ready for testing)
            wire                    PCEn = SystemEn;
            wire                    PC_StallEn = (StallEn || StallDelayBuffer) && ~BranchStallDisable;
            wire                    BranchEn = s2_BranchEn;
            wire [DATABITWIDTH-1:0] ComparisonValue = s2_Data_A;
            wire [DATABITWIDTH-1:0] BranchDest = s2_Data_B;
            wire                    PC_JumpEn = JumpEn;
            wire [DATABITWIDTH-1:0] PC_JumpDest = s1_Data_InB;
            wire [DATABITWIDTH-1:0] InstructionAddrOut;
            wire [DATABITWIDTH-1:0] JumpAndLinkAddrOut;
            ProgramCounter #(
                .DATABITWIDTH(DATABITWIDTH)
            ) PC (
                .clk               (clk),
                .clk_en            (clk_en),
                .sync_rst          (sync_rst),
                .PCEn              (PCEn),
                .StallEn           (PC_StallEn),
                .BranchEn          (BranchEn),
                .RelativeEn        (s2_RelativeEn),
                .BranchOffset      (s2_BranchOffset),
                .ComparisonValue   (ComparisonValue),
                .BranchDest        (BranchDest),
                .JumpEn            (PC_JumpEn),
                .JumpRelativeEn    (s1_RelativeEn),
                .JumpOffset        (s1_BranchOffset),
                .JumpDest          (PC_JumpDest),
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

        // Register Writeback Mux (Ready for testing)
            // wire                       WBMux_RegAWriteEn = s2_RegWriteEn && ~(StallEn && ~BranchStallIn);
            wire                       WBMux_RegAWriteEn = s2_RegWriteEn && ~RegisterStall;
            wire                       WBMux_JumpAndLinkEn = s2_JumpAndLinkEn;
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
                .JumpAndLinkEn      (WBMux_JumpAndLinkEn),
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

        // Complex ALU
            // TODO:
        //

        // Load Store Unit (Ready for testing)
            localparam S2LSUMAUPPERLIMIT = REGADDRBITWIDTH + (DATABITWIDTH*2);
            localparam S2LSUSVUPPERLIMIT = REGADDRBITWIDTH + DATABITWIDTH;
            wire s2_LoadStore_REQ;
            wire s2_LoadStore_ACK = s1_LoadStoreFIFO_dOutACK;
            wire                  [3:0] s2_LoadStore_MinorOpcode = s1_LoadStoreFIFO_dOUT[S1LSUFIFOBITWIDTH-1:S2LSUMAUPPERLIMIT];
            wire     [DATABITWIDTH-1:0] s2_LoadStore_MemoryAddress = s1_LoadStoreFIFO_dOUT[S2LSUMAUPPERLIMIT-1:S2LSUSVUPPERLIMIT];
            wire     [DATABITWIDTH-1:0] s2_LoadStore_StoreValue = s1_LoadStoreFIFO_dOUT[S2LSUSVUPPERLIMIT-1:REGADDRBITWIDTH];
            wire  [REGADDRBITWIDTH-1:0] s2_LoadStore_DestinationRegister = s1_LoadStoreFIFO_dOUT[REGADDRBITWIDTH-1:0];
            wire                       Cache_REQ = 1'b0;
            wire                       Cache_ACK;
            wire                 [3:0] Cache_MinorOpcode;
            wire    [DATABITWIDTH-1:0] Cache_MemoryAddress;
            wire    [DATABITWIDTH-1:0] Cache_StoreValue;
            wire [REGADDRBITWIDTH-1:0] Cache_DestinationRegister;
            wire                       FixedMemory_REQ = FixedMem_LoadStore_REQ;
            wire                       FixedMemory_ACK;
            wire                 [3:0] FixedMemory_MinorOpcode;
            wire    [DATABITWIDTH-1:0] FixedMemory_MemoryAddress;
            wire    [DATABITWIDTH-1:0] FixedMemory_StoreValue;
            wire [REGADDRBITWIDTH-1:0] FixedMemory_DestinationRegister;
            LoadStoreUnit #(
                .DATABITWIDTH   (DATABITWIDTH),
                .REGADDRBITWIDTH(REGADDRBITWIDTH)
            ) LSUnit (
                .clk                            (clk),
                .clk_en                         (clk_en),
                .sync_rst                       (sync_rst),
                .LoadStore_REQ                  (s2_LoadStore_REQ),
                .LoadStore_ACK                  (s2_LoadStore_ACK),
                .LoadStore_MinorOpcode          (s2_LoadStore_MinorOpcode),
                .LoadStore_MemoryAddress        (s2_LoadStore_MemoryAddress),
                .LoadStore_StoreValue           (s2_LoadStore_StoreValue),
                .LoadStore_DestinationRegister  (s2_LoadStore_DestinationRegister),
                .IOManager_REQ                  (IOOutREQ),
                .IOManager_ACK                  (IOOutACK),
                .IOManager_MinorOpcode          (IOMinorOpcode),
                .IOManager_MemoryAddress        (IOOutAddress),
                .IOManager_StoreValue           (IOOutData),
                .IOManager_DestinationRegister  (IOOutDestReg),
                .Cache_REQ                      (Cache_REQ),
                .Cache_ACK                      (Cache_ACK),
                .Cache_MinorOpcode              (Cache_MinorOpcode),
                .Cache_MemoryAddress            (Cache_MemoryAddress),
                .Cache_StoreValue               (Cache_StoreValue),
                .Cache_DestinationRegister      (Cache_DestinationRegister),
                .FixedMemory_REQ                (FixedMemory_REQ),
                .FixedMemory_ACK                (FixedMemory_ACK),
                .FixedMemory_MinorOpcode        (FixedMemory_MinorOpcode),
                .FixedMemory_MemoryAddress      (FixedMemory_MemoryAddress),
                .FixedMemory_StoreValue         (FixedMemory_StoreValue),
                .FixedMemory_DestinationRegister(FixedMemory_DestinationRegister)
            );

        //

        // Fixed Memory (Ready for testing)
            wire                       FixedMem_LoadStore_REQ;
            wire                       FixedMem_LoadStore_ACK = FixedMemory_ACK;
            wire                 [3:0] FixedMem_MinorOpcodeIn = FixedMemory_MinorOpcode;
            wire [REGADDRBITWIDTH-1:0] FixedMem_DestRegisterIn = FixedMemory_DestinationRegister;
            wire    [DATABITWIDTH-1:0] FixedMem_DataAddrIn = FixedMemory_MemoryAddress;
            wire    [DATABITWIDTH-1:0] FixedMem_DataIn = FixedMemory_StoreValue;
            wire                       FixedMem_Writeback_REQ = s3_FixedMemoryFIFO_dInREQ;
            wire                       FixedMem_Writeback_ACK;
            wire [REGADDRBITWIDTH-1:0] FixedMem_DestRegisterOut;
            wire    [DATABITWIDTH-1:0] FixedMem_DataOut;
            FixedMemory #(
                .DATABITWIDTH   (DATABITWIDTH),
                .REGADDRBITWIDTH(REGADDRBITWIDTH)
            ) FixedMem (
                .clk            (clk),
                .clk_en         (clk_en),
                .sync_rst       (sync_rst),
                .FlashEn        (DataFlashEn),
                .FlashAddr      (FlashAddr),
                .FlashData      (FlashData),
                .LoadStore_REQ  (FixedMem_LoadStore_REQ),
                .LoadStore_ACK  (FixedMem_LoadStore_ACK),
                .MinorOpcodeIn  (FixedMem_MinorOpcodeIn),
                .DestRegisterIn (FixedMem_DestRegisterIn),
                .DataAddrIn     (FixedMem_DataAddrIn),
                .DataIn         (FixedMem_DataIn),
                .Writeback_REQ  (FixedMem_Writeback_REQ),
                .Writeback_ACK  (FixedMem_Writeback_ACK),
                .DestRegisterOut(FixedMem_DestRegisterOut),
                .DataOut        (FixedMem_DataOut)
            );
        //
    //

    // Stage 3+ 
    // Notes: Execute - Long
    // In:
    // Out:
        // Cache Controller
            // TODO:

        //

        // ComplexALU Output FIFO
            // TODO:

        //

        // Fixed Memory FIFO (Ready for testing)
            localparam S3FMFIFOBITWIDTH = REGADDRBITWIDTH + DATABITWIDTH;
            wire                        s3_FixedMemoryFIFO_dInREQ;
            wire                        s3_FixedMemoryFIFO_dInACK = FixedMem_Writeback_ACK;
            wire [S3FMFIFOBITWIDTH-1:0] s3_FixedMemoryFIFO_dIN = {FixedMem_DestRegisterOut, FixedMem_DataOut};   
            wire                        s3_FixedMemoryFIFO_dOutREQ = MemWritebackREQ[MEMWB_FIXEDMEMPORT];
            wire                        s3_FixedMemoryFIFO_dOutACK;
            wire [S3FMFIFOBITWIDTH-1:0] s3_FixedMemoryFIFO_dOUT;
            HandshakeFIFO #(
                .DATABITWIDTH     (S3FMFIFOBITWIDTH),
                .FIFODEPTH        (4),
                .FIFODEPTHBITWIDTH(2)
            ) s3_FixedMemoryFIFO (
                .clk     (clk),
                .clk_en  (clk_en),
                .sync_rst(sync_rst),
                .dInREQ  (s3_FixedMemoryFIFO_dInREQ),
                .dInACK  (s3_FixedMemoryFIFO_dInACK),
                .dIN     (s3_FixedMemoryFIFO_dIN),
                .dOutREQ (s3_FixedMemoryFIFO_dOutREQ),
                .dOutACK (s3_FixedMemoryFIFO_dOutACK),
                .dOUT    (s3_FixedMemoryFIFO_dOUT)
            );
            wire [REGADDRBITWIDTH-1:0] s3_FixedMemory_AddrOut = s3_FixedMemoryFIFO_dOUT[S3FMFIFOBITWIDTH-1:DATABITWIDTH];
            wire    [DATABITWIDTH-1:0] s3_FixedMemory_dOut = s3_FixedMemoryFIFO_dOUT[DATABITWIDTH-1:0];
        //

        // Cache FIFO
            // TODO:

        //
        
        // IO FIFO
            // TODO:

        //

        // Memory Writeback Mux (Ready for testing)
            wire   [MEMWB_INPUTPORTCOUNT-1:0] MemWritebackREQ;
            wire   [MEMWB_INPUTPORTCOUNT-1:0] MemWritebackACK;
            assign                            MemWritebackACK[MEMWB_COMPLEXALUPORT] = 1'b0;
            assign                            MemWritebackACK[MEMWB_FIXEDMEMPORT] = s3_FixedMemoryFIFO_dOutACK;
            assign                            MemWritebackACK[MEMWB_CACHEPORT] = 1'b0;
            assign                            MemWritebackACK[MEMWB_IOPORT] = IOInACK;
            wire   [MEMWB_INPUTPORTCOUNT-1:0] [DATABITWIDTH-1:0] MemWritebackDataIn;
            assign                            MemWritebackDataIn[MEMWB_COMPLEXALUPORT] = '0;
            assign                            MemWritebackDataIn[MEMWB_FIXEDMEMPORT] = s3_FixedMemory_dOut;
            assign                            MemWritebackDataIn[MEMWB_CACHEPORT] = '0;
            assign                            MemWritebackDataIn[MEMWB_IOPORT] = IOInData;
            wire   [MEMWB_INPUTPORTCOUNT-1:0] [REGADDRBITWIDTH-1:0] MemWritebackAddrIn;
            assign                            MemWritebackAddrIn[MEMWB_COMPLEXALUPORT] = '0;
            assign                            MemWritebackAddrIn[MEMWB_FIXEDMEMPORT] = s3_FixedMemory_AddrOut;
            assign                            MemWritebackAddrIn[MEMWB_CACHEPORT] = '0;
            assign                            MemWritebackAddrIn[MEMWB_IOPORT] = IOInDestReg;
            wire                              MemWBMux_RegWriteEn;
            wire           [DATABITWIDTH-1:0] MemWBMux_RegWriteData;
            wire        [REGADDRBITWIDTH-1:0] MemWBMux_RegWriteAddr;
            MemWritebackMux #(
                .DATABITWIDTH   (DATABITWIDTH),
                .INPUTPORTCOUNT (MEMWB_INPUTPORTCOUNT),
                .PORTADDRWIDTH  (MEMWB_PORTADDRWIDTH),
                .REGADDRBITWIDTH(REGADDRBITWIDTH)
            ) MemWBMux (
                .clk     (clk),
                .clk_en  (clk_en),
                .sync_rst(sync_rst),
                .MemWritebackREQ   (MemWritebackREQ),
                .MemWritebackACK   (MemWritebackACK),
                .MemWritebackDataIn(MemWritebackDataIn),
                .MemWritebackAddrIn(MemWritebackAddrIn),
                .RegWriteEn        (MemWBMux_RegWriteEn),
                .RegWriteData      (MemWBMux_RegWriteData),
                .RegWriteAddr      (MemWBMux_RegWriteAddr)
            );
            assign IOInREQ = MemWritebackREQ[MEMWB_IOPORT];
        //
    //

endmodule