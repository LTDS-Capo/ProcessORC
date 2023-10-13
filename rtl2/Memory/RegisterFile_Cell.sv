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
    output                    CurrentlySpeculative,

    input                     WritebackEn,
    input  [DATABITWIDTH-1:0] WritebackData,

    input                     LoadWriteEn,
    input  [DATABITWIDTH-1:0] LoadWriteData,

    output [DATABITWIDTH-1:0] ReadData
);
    // TODO: Make the Load ports fully disabled via a generate block

    //? Notes
        // Write Priority:
            // ShadowCopy > Load > Writeback
        // Shadow State
            // Write To Shadow:
            // - Write Issued Post-Speculation
            // Copy From Shadow:
            // - Mispredicted Speculation
    //

    //? Register Cell
        reg   [DATABITWIDTH-1:0] RegisterCell;
        logic [DATABITWIDTH-1:0] NextRegisterCell;
        wire               [1:0] NextRegsiterCondition = {(WritebackEn || sync_rst), (LoadWriteEn || sync_rst)};
        always_comb begin : NextRegisterCellMux
            case (NextRegsiterCondition)
                2'b00  : NextRegisterCell = ShadowRegister[DATABITWIDTH-1:0];
                2'b01  : NextRegisterCell = LoadWriteData;
                2'b10  : NextRegisterCell = WritebackData;
                2'b11  : NextRegisterCell = {DATABITWIDTH{1'b0}};
                default: NextRegisterCell = 0;
            endcase
        end
        wire RegisterCellTrigger = sync_rst || (clk_en && WritebackEn) || (clk_en && LoadWriteEn) || (clk_en && MispredictedSpeculationPulse &&CurrentlySpeculative);
        always_ff @(posedge clk) begin
            if (RegisterCellTrigger) begin
                RegisterCell <= NextRegisterCell;
            end
        end
        assign ReadData = RegisterCell;
    //

    //? Shadow Register Cell
        reg  [DATABITWIDTH:0] ShadowRegister;
        wire [DATABITWIDTH:0] NextShadowRegister = (sync_rst || EndSpeculationPulse) ? 0 : {1'b1, RegisterCell};
        wire ShadowRegisterTrigger = sync_rst || (clk_en && Speculating && WillBeWritingToA && ~CurrentlySpeculative) || (clk_en && EndSpeculationPulse);
        always_ff @(posedge clk) begin
            if (ShadowRegisterTrigger) begin
                ShadowRegister <= NextShadowRegister;
            end
        end
        assign CurrentlySpeculative = ShadowRegister[DATABITWIDTH];
    //


endmodule : RegisterFile_Cell