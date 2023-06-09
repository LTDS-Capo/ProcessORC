//? Nth Fib requirements
//! NOTE: During juding you will be given 3 N values, your score will be the avg across those 3 Ns.
//!       You will not know which N values we give until the start of judging.
// 1. Must take in the specified N input from either an IO port or preloaded in RAM
// 2. Must start by taking the given N and using a Jump-And-Link (Or equivalent) instruction to jump into your Fib Function
// 3. Must return (Jump to the PC value stored into your registers by the Jump-And-Link) back with the target N value in a Register/Accumulator/Equivalent AND be in Memory [At Addr 0, 1, or F].
// 4. The target N value is defined as the value at the Nth step of Fibonacci, where step 0 being defined as having the register states 0, 1.

//? Strlen() - C String Length
//! NOTE: During juding you will be given 3 Strings, your score will be the avg across those 3 Strings.
//!       You will not know which Strings we give until the start of judging.
// 1. Must take in a pointer via a Load Immediate that points to the start of a string in memory.
// 2. The string will have a delimiter of 00 [Meaning, the last value will be a 00 and will mark the end of the string]
// 3. The string plus delimieter wont take up more than 16 bytes of RAM [You do not need more than this for the competition as a whole]
// 2. Must start by using a Jump-And-Link (Or equivalent) to jump into the primary Strlen() function
// 3. Must Return (Jump to the PC value stored into your registers by the Jump-And-Link) back with the Length of the string a Register/Accumulator/Equivalent AND be in Memory [At Addr 0, 1, or F].
// 4. The Length returned should be the actual length, not 1 less... so a string that has 8 bytes + a 00 delimiter, will result in a Length of 8.


//? Strcmp() - C String Compare
//! NOTE: During juding you will be given 3 String Pairs, your score will be the avg across those 3 String Pairs.
//!       You will not know which String Pairs we give until the start of judging.
// 1. Must take in a pointer via a Load Immediate that points to the start of a string in memory.
// 2. The strings will have a delimiter of 00 [Meaning, the last value will be a 00 and will mark the end of each string]
// 3. The strings plus delimieter wont take up more than 16 bytes of RAM [You do not need more than this for the competition as a whole]
// 2. Must start by using a Jump-And-Link (Or equivalent) to jump into the primary Strcmp() function
// 3. Must Return (Jump to the PC value stored into your registers by the Jump-And-Link) back with the Length of the string a Register/Accumulator/Equivalent AND be in Memory [At Addr 0, 1, or F].
// 4. If the strings match, the result should be 0.
// 5. If the strings do not match, then at the first byte where they begin to differ;
//      -> Return a value >0 (Positive) if the byte in String A is GREATER than the byte in String B.
//      -> Return a value <0 (Negative) if the byte in String A is LESS than the byte in String B.

//? ISA Notes and hints
// It may be easier to make all the Branch and Jump instructions use Register B as it's jump destination, as this would give all branches and jumps the ability to be RETURN instructions.
// If a full Jump-And-Link instruction is too much, you can add an instruction to copy the PC into a register.
//   Then add an immediate to the resulting register to point it passed the following Branch/Jump instruction.
// The D flag in the Accumulator ISA, it may be more useful at times to allow the D flag to swap operands for Subtract, so instead of the current B = Acc - B, you could do B = B - Acc.

//! Note about JAL (Jump-and-Link) and RET (Return)...
// The JAL can be accomplished by attaching an additional register to you PC where you store what would 
//   be your next PC (So Current PC+1, the result after your +1 logic) at the same time you do a jump.
// The RET can be accomplished by replacing the current PC value with whatever is in the JAL register.
// Normally the JAL register is mapped to one of your CPUs primary registers... however, that is not required here. 
//   We just want to have the idea of a JAL and RET.
// I will provice a sample Program counter by the end of next weekend that will have a dedicated JAL register on it and is fully functional.
//  You are welcome to use the sample Program Counter in your builds then study it later.
//* This behavior can also be done by having a command to store the PC to a register and having your Jump instruction use a Register as a destination.
//*   You can do the +1 with code.
//* For JAL:  [rL = PC], [rL = rL + 3], [Jump to Imm (or IMM loaded into a register)].
//* For RET:  [Jump to rL]


//! Accumulator
    //* Register Map:
    // -> r0: Zero Register
    // -> r1:
    // -> r2:
    // -> r3:
    // -> r4:
    // -> r5:
    // -> r6:
    // -> r7:

    //* Code:
    // -> 

//! 2 Operand
    //* Register Map:
    // -> r0: Zero Register
    // -> r1:
    // -> r2:
    // -> r3:
    // -> r4:
    // -> r5:
    // -> r6:
    // -> r7:

    //* Code:
    // -> 

    //! Accumulator
    //* Register Map:
    // -> r0: Zero Register
    // -> r1:
    // -> r2:
    // -> r3:
    // -> r4:
    // -> r5:
    // -> r6:
    // -> r7:

    //* Code:
    // -> 

//! 3 Operand
    //* Register Map:
    // -> r0: Zero Register
    // -> r1:
    // -> r2:
    // -> r3:
    // -> r4:
    // -> r5:
    // -> r6:
    // -> r7:

    //* Code:
    // -> 