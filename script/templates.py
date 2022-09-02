parameters = []


def reset_parameter():
    parameters.clear()


def add_parameter(name, val):
    global parameters
    parameters.append([name, val])


def gen_parameter():
    global parameters
    lines = []

    for p in parameters:
        lines.append(f"\tparameter {p[0]} = {p[1]},\n")

    lines[-1] = lines[-1].rstrip().rstrip(',')

    return "".join(lines)


def sq(x):
    return x * x


def test_gen(a, b):
    add_parameter("a", a)
    add_parameter("b", b)
    return f"""\t\tmodule IOConfigROM (
            input  [{a}:0] ByteSelect,
            output [{b}:0] ConfigOut,
        );
            logic [{b}:0] LocalConfig;
            always_comb begin : ConfigSelectionROM
                case (ByteSelect)
                endcase
            end
            assign ConfigOut = LocalConfig;
        endmodule"""
