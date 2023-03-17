module RegisterFile_Cell #(
    parameter DATABITWIDTH = 16
)(
    input clk,
    input clk_en,
    input sync_rst,

    input                     Speculating,
    input                     WillBeWritingToA,
    input                     EndSpeculationPulse,
    input                     MispredictedSpeculationPulse,

    input                     WritebackEn,
    input  [DATABITWIDTH-1:0] WritebackData,

    input                     LoadWriteEn,
    input  [DATABITWIDTH-1:0] LoadWriteData,

    output [DATABITWIDTH-1:0] ReadData
);

    // THE Notes
        // Write Priority:
            // ShadowCopy > Load > Writeback
        // Shadow State
            // Write To Shadow:
            // - Write Issued Post-Speculation
            // Copy From Shadow:
            // - Mispredicted Speculation
    //

    // Register Cell
        reg   [DATABITWIDTH-1:0] RegisterCell;
        logic [DATABITWIDTH-1:0] NextRegisterCell;
        wire                     NextRegsiterCondition = {(MispredictedSpeculationPulse && ShadowRegister[DATABITWIDTH]), LoadWriteEn};
        always_comb begin : NextRegisterCellMux
            case (NextRegsiterCondition)
                2'b00  : NextRegisterCell = WritebackData;
                2'b01  : NextRegisterCell = LoadWriteData;
                2'b10  : NextRegisterCell = ShadowRegister;
                2'b11  : NextRegisterCell = ShadowRegister;
                default: NextRegisterCell = 0;
            endcase
        end
        wire RegisterCellTrigger = sync_rst || (clk_en && WritebackEn) || (clk_en && LoadWriteEn) || (clk_en && MispredictedSpeculationPulse && ShadowRegister[DATABITWIDTH]);
        always_ff @(posedge clk) begin
            if (RegisterCellTrigger) begin
                RegisterCell <= NextRegisterCell;
            end
        end
        assign ReadData = RegisterCell;
    //

    // Shadow Register Cell
        reg  [DATABITWIDTH:0] ShadowRegister;
        wire [DATABITWIDTH:0] NextShadowRegister = sync_rst ? 0 : {1'b1, RegisterCell};
        wire ShadowRegisterTrigger = sync_rst || (clk_en && Speculating && WillBeWritingToA);
        always_ff @(posedge clk) begin
            if (ShadowRegisterTrigger) begin
                ShadowRegister <= NextShadowRegister;
            end
        end
    //


endmodule : RegisterFile_Cell