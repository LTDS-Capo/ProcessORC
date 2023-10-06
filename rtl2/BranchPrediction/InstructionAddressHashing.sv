// "not that great at all - but it works"
module InstructionAddressHashing #(
    parameter DATABITWIDTH = 16,
    // How many lower bits from the incoming address do you want to be included in the final Hash.
    parameter PRESERVEDBITCOUNT = 3, // Must be equal or less than HASHBITWIDTH - //! forced to minimum of 1
    parameter HASHBITWIDTH = 6
)(
    input  [DATABITWIDTH-1:0] InstructionAddress,
    output [HASHBITWIDTH-1:0] HashedAddress
);

    // Preserve the Lowest Bits
        wire       [PRESERVEDBITCOUNT-1:0] PreservedLowerBits = InstructionAddress[PRESERVEDBITCOUNT-1:0];
    //

    // Extract bits to be Hashed
        //* 1234 5678 9ABC DPPP - Input
        //* ooo1_2345 6789_ABCD - Padding Incomplete Upper Byte
        //! Going with this one - Better diversification on Upper bits [totally a hunch/theory, no idea if true lol]
        //* 1234 5678 9ABC Dooo - Padding Preserved Bits
        //!
        localparam HASHINPUTBITWIDTH = DATABITWIDTH - PRESERVEDBITCOUNT;
        localparam LOCALHASHBITWIDTH = HASHBITWIDTH - PRESERVEDBITCOUNT;
        wire       [HASHINPUTBITWIDTH-1:0] HashedUpperBits = InstructionAddress[DATABITWIDTH-1:PRESERVEDBITCOUNT];
        wire       [PRESERVEDBITCOUNT-1:0] HashPadding = 0;
        wire            [DATABITWIDTH-1:0] HashInput = {HashedUpperBits, HashPadding};
    //

    // Hash the bits
        // HashInput bytewise Addition
        wire [7:0] ByteChecksumResult;
        generate
            if (DATABITWIDTH == 8) begin
                assign ByteChecksumResult = HashInput;
            end
            else if (DATABITWIDTH == 16) begin
                assign ByteChecksumResult = HashInput[15:8] + HashInput[7:0];
            end
            else if (DATABITWIDTH == 32) begin
                wire   [7:0] Byte1_Byte0Addition = HashInput[15:8] + HashInput[7:0];
                wire   [7:0] Byte3_Byte2Addition = HashInput[31:24] + HashInput[23:16];
                assign       ByteChecksumResult = Byte3_Byte2Addition + Byte1_Byte0Addition;
            end
            else if (DATABITWIDTH == 64) begin
                wire   [7:0] Byte1_Byte0Addition = HashInput[15:8] + HashInput[7:0];
                wire   [7:0] Byte3_Byte2Addition = HashInput[31:24] + HashInput[23:16];
                wire   [7:0] Byte5_Byte4Addition = HashInput[47:40] + HashInput[39:32];
                wire   [7:0] Byte6_Byte7Addition = HashInput[63:56] + HashInput[55:48];
                wire   [7:0] UpperAddition = Byte3_Byte2Addition + Byte1_Byte0Addition;
                wire   [7:0] LowerAddition = Byte6_Byte7Addition + Byte5_Byte4Addition;
                assign       ByteChecksumResult = UpperAddition + LowerAddition;
            end
        endgenerate
        wire [LOCALHASHBITWIDTH-1:0] LocalUpperHash;
        generate
            if (LOCALHASHBITWIDTH < 5) begin
                wire [3:0] NibbleAddition = ByteChecksumResult[7:4] + ByteChecksumResult[3:0];
                assign LocalUpperHash = NibbleAddition[LOCALHASHBITWIDTH-1:0];
            end
            else if (LOCALHASHBITWIDTH < 9) begin
                assign LocalUpperHash = ByteChecksumResult[LOCALHASHBITWIDTH-1:0];
            end
            else begin
                assign LocalUpperHash = 0;
            end
        endgenerate
    //

    // Output Assignment
        assign HashedAddress = {LocalUpperHash, PreservedLowerBits};
    //


endmodule : InstructionAddressHashing