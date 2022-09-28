module IOConfigROM (
    input  [7:0] ByteSelect,
    output [7:0] ConfigOut,
);
    logic [7:0] LocalConfig;
    always_comb begin : ConfigSelectionROM
        case (ByteSelect)
            8'h00  : LocalConfig = {1'b1, 7'd00}; // 8
            8'h08  : LocalConfig = {1'b1, 7'd00}; // 
            default: LocalConfig = 0; // Default is also case 0
        endcase
    end
    assign ConfigOut = LocalConfig;
endmodule
