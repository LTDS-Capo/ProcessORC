//! Header and Tail implementation notes
//* Situations:
// > New Stack Pointer
// > Pushing Out of a Line
// > Popping Out of a Line

//? Overflow/Underflow Checks
// NextPushValid - RoundDown8s(StackPointer) + 16 <= Stack Push Bounds //* Next Push Line on PushBounds
// PushValid     - RoundDown8s(StackPointer) + 8 <= Stack Push Bounds  //* Push Line on PushBounds
// OnPushBounds - RoundDown8s(StackPointer) == Stack Push Bounds       //* On Push/PopBounds
// NextPopValid  - RoundDown8s(StackPointer) - 16 >= Stack Pop Bounds  //* Next Pop Line On PopBounds
// PopValid      - RoundDown8s(StackPointer) - 8 >= Stack Pop Bounds   //* Pop Line On PopBounds
// OnPopBounds - RoundDown8s(StackPointer) == Stack Pop Bounds         //* On Push/PopBounds

//? New Stack Pointer - Begin Init
//! The Checks below check for Line Bound Validity and if the value is already in the cache.
//* IF PrePop is NOT Set in CSRs:
// Set StackCacheBusy
// Check Active Line
// > If in-range: Continue
// > If out-of-bounds: Seg Fault
// Check PushValid
// > If True: Fetch Line Stack Pointer points to -1 [Place in Line 2'b01] //* Next Push
// > If False: Mark Line 2'b11 Invalid
// Fetch Line Stack Pointer points to               [Place in Line 2'b00] //* Active Line
// Check PopValid  
// > If True: Fetch Line Stack Pointer points to +1 [Place in Line 2'b11] //* Next Pop
// > If False: Mark Line 2'b01 Invalid
// Check NextPopValid  
// > If True: Fetch Line Stack Pointer points to +2 [Place in Line 2'b10] //* Pending Eviction
// > If False: Mark Line 2'b10 Invalid
// Set Active to 2'b00
// Clear StackCacheBusy
//* IF PrePop is Set in CSRs:
// Set StackCacheBusy
// Check Active Line
// > If in-range: Continue
// > If out-of-bounds: Seg Fault
// Check NextPushValid
// > If True: Fetch Line Stack Pointer points to -2 [Place in Line 2'b10] //* Pending Eviction
// > If False: Mark Line 2'b10 Invalid
// Check PushValid
// > If True: Fetch Line Stack Pointer points to -1 [Place in Line 2'b01] //* Next Push
// > If False: Mark Line 2'b11 Invalid
// Fetch Line Stack Pointer points to               [Place in Line 2'b00] //* Active Line
// Check PopValid  
// > If True: Fetch Line Stack Pointer points to +1 [Place in Line 2'b11] //* Next Pop
// > If False: Mark Line 2'b01 Invalid
// Set Active to 2'b00
// Clear StackCacheBusy

//? Init sequence
    //* Check NextPushValid << Start Here if PrePop
    //* Check PushValid << Start Here if ~PrePop
    //* Fetch Active Line
    //* Check PopValid << Jump to 'Set Active' if PrePop
    //* Check NextPopValid
    //* Set Active - to 2'b00
    //* Initialized
    //* < The rest of the state machine >

//? Pushing Out of a Line
    // Add 2 to Active Index to find the Pending Eviction Line and respective index
    // - Is the Pending Line already 'Next Push Valid - 11000'?
    //   > Yes: Update Line States
    //   >      goto EXIT
    // - Is Pending Index NextPushValid?
    //   > No:  Update Line States [Mark Pending Index as Invalid]
    //   >      goto EXIT
    // - Not already 'Next Push Valid - 11000' && NextPushValid?
    //   > Yes: Push Pending Index and NextPushValid to ReplacementQueue
    //   >      Update Line States
    //   >      goto EXIT
    // :EXIT
    // Increment Active

//? Popping Out of a Line
    // Add 2 to Active Index to find the Pending Eviction Line and respective index
    // - Is the Pending Line already 'Next Pop Valid - 10001'?
    //   > Yes: Update Line States
    //   >      goto EXIT
    // - Is Pending Index NextPopValid?
    //   > No:  Update Line States [Mark Pending Index as Invalid]
    //   >      goto EXIT
    // - Not already 'Next Pop Valid - 10001' && NextPopValid?
    //   > Yes: Push Pending Index and NextPopValid to ReplacementQueue
    //   >      Update Line States
    //   >      goto EXIT
    // :EXIT
    // Increment Active

//? Core Questions:
    // When updating Line States... do you mark the Pending Line Invalid?
    // Do you fetch a replacment for the Pending Line?

//! Have a Cache Line 'ReplacementQueue'
//* Entry
// > {Line Index, Fetch Address}
//  > Generate Fetch Address by masking the lowest 3 bits of the current stack pointer to 3'b000,
//    Subtract 16 for NextPushIndex
//    OR
//    Add 16 for NextPopIndex
//* Memory Load Register Dest
// > For Register Loads > 0xxxx
//    xxxx: Register Address
// > For Stack Line Loads > 100xx
//    xx: Stack Cache Line Index
//* Pointers
// > Wait to replace the lines at the front of the Queue until they are Clean.
// >      Head - Where to write next Entry
// > StoreTail - Newest Entry being Actively Stored
// >  LoadTail - Newest Entry being Actively Fetched
// >      Tail - Oldest Entry being Actively Fetched
//* If the Line the Tail points to is Valid, Store the contents before Fetching.
//* If the Line the Tail points to is Not Valid, Ignore Contents and Immediately Fetch.
//* If Target Line Address matches the current Line Address, instantly mark complete.

//! Each Line has a 5 bit One Hot that says what status it was loaded as...
//! Also store the base memory address... this will aid in eliminating false-replacements when updating stack pointers
//* 0xxxx - Invalid
//* 10000 - Active Line
//* 10001 - Next Pop Valid
//* 10010 - Pop Valid
//* 10100 - Push Valid
//* 11000 - Next Push Valid

module StackCache_Line_StateMachine (
    input  clk,
    input  clk_en,
    input  sync_rst,

    output StackBusy,
     
);

//? State Machine
    //! The Checks below check for Line Bound Validity and if the value is already in the cache.
    //* Name                      - Bin  - Trigger                                 - Trigger Source  - Next           - Next Calc
    //  Start Up/Fault            - 0000 - SwapValid                               - PointerTracking - 0001           - 4'b0001
    //  Fault Check               - 0001 - 1'b1                                    -                 - 0000/0010/0101 - {2'b00, ~PointerFault, (~PointerFault && ~PrePop)}
    //  NextPushValid Check&Fetch - 0010 - 1'b1                                    -                 - 0101           - 4'b0011
    //  PushValid Check&Fetch     - 0101 - 1'b1                                    -                 - 0100           - 4'b0100
    //  Active Line Check         - 0100 - 1'b1                                    -                 - 0111           - 4'b0101
    //  PopValid Check&Fetch      - 0111 - 1'b1                                    -                 - 0110           - 4'b0110
    //  NextPopValid Check&Fetch  - 0110 - 1'b1                                    -                 - 1000           - 4'b1000
    //  Initialized               - 1000 - PushingOut || PoppingOut || PointerSwap - PointerTracking - 1001/1010/0001 - {2'b10, PoppingOut, PushingOut}
    //? The below may not need to be states... could just be reactionary responses... allowing for back to back PopOut>PushOut or PushOut>PopOut...
    //?    For timing reasons, do all supporting logic for the PushOut/PopOut before ANDing with PushingOut/PoppingOut (respectively)
    ////  Push Out Check/Inc Active - 1001 - 1'b1                                    -                 - 1100           - 4'b1100
    ////  Pop Out Check/Inc Active  - 1010 - 1'b1                                    -                 - 1100           - 4'b1100
    ////  +Default+                 - xxxx - 1'b1                                    -                 - 0000           - 4'b0000


//? Status Vector
// > Tracks Valid and Pending-Fetch



endmodule : StackCache_Line_StateMachine