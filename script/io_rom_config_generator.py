out_file_path = "test.sv"
# dsdfdfd
config = [
    [1, 'SPI BOB'],
    [7, 'GPIO'],
    [8, ''],
    [9, ''],
]

template = """module IOConfigROM (
    input  [6:0] ByteSelect,
    output [7:0] ConfigOut,
);
    logic [7:0] LocalConfig;
    always_comb begin : ConfigSelectionROM
        case (ByteSelect)
{{CASE}}
        endcase
    end
    assign ConfigOut = LocalConfig;
endmodule"""


def generate_io_config_rom():
    accum = 0
    lines = []

    for i in range(0, len(config)):

        lines.append(
            f"\t\t\t8'd{accum + 128}  : LocalConfig = {{1'b1, 7'd{config[i][0]}}}; // {config[i][1]} [{accum}-{accum + config[i][0] - 1}]")

        accum += config[i][0]
        if accum > 128:
            print("Too meany ports!! :(")
            return
    lines.append(f"\t\t\tdefault: LocalConfig = {{1'b0,  7'd{len(config)}}};")
    content = template.replace("{{CASE}}", '\n'.join(lines))
    with open(out_file_path, "w") as f:
        f.write(content)


if __name__ == "__main__":
    generate_io_config_rom()
