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
//* IF PrePop is NOT Set in CSRs:
// Set StackCacheBusy
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
//* Pointers
// > Wait to replace the lines at the front of the Queue until they are Clean.
// > Head - Where to write next Entry
// > Body - Newest Entry being Actively Fetched
// > Tail - Oldest Entry being Actively Fetched
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


//? Status Vector
// > Tracks Valid and Pending-Fetch



endmodule : StackCache_Line_StateMachine
