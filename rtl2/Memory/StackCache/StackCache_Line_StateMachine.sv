//! Header and Tail implementation notes
//* Situations:
// > New Stack Pointer
// > Pushing Out of a Line
// > Popping Out of a Line

//? Overflow/Underflow Checks
// NextPushValid - RoundDown8s(StackPointer) + 16 <= Stack Push Bounds //* Next Push Line on PushBounds
// PushValid     - RoundDown8s(StackPointer) + 8 <= Stack Push Bounds  //* Push Line on PushBounds
// OnPushBounds - RoundDown8s(StackPointer) == Stack Push Bounds      //* On Push/PopBounds
// NextPopValid  - RoundDown8s(StackPointer) - 16 >= Stack Pop Bounds //* Next Pop Line On PopBounds
// PopValid      - RoundDown8s(StackPointer) - 8 >= Stack Pop Bounds  //* Pop Line On PopBounds
// OnPopBounds - RoundDown8s(StackPointer) == Stack Pop Bounds      //* On Push/PopBounds

//? New Stack Pointer
//* IF PrePop is NOT Set in CSRs:
// Set StackCacheBusy
// Check PushValid
// > If True: Fetch Line Stack Pointer points to -1 [Place in Line 2'b11] //* Next Push
// > If False: Mark Line 2'b11 Invalid
// Fetch Line Stack Pointer points to               [Place in Line 2'b00] //* Active Line
// Check PopValid  
// > If True: Fetch Line Stack Pointer points to +1 [Place in Line 2'b01] //* Next Pop
// > If False: Mark Line 2'b01 Invalid
// Check NextPopValid  
// > If True: Fetch Line Stack Pointer points to +2 [Place in Line 2'b10] //* Pending Eviction
// > If False: Mark Line 2'b10 Invalid
// Set Head to 2'b00
// Set Tail to 2'b10
// Clear StackCacheBusy
//* IF PrePop is Set in CSRs:
// Set StackCacheBusy
// Check NextPushValid  
// > If True: Fetch Line Stack Pointer points to -2 [Place in Line 2'b10] //* Pending Eviction
// > If False: Mark Line 2'b10 Invalid
// Check PushValid
// > If True: Fetch Line Stack Pointer points to -1 [Place in Line 2'b11] //* Next Push
// > If False: Mark Line 2'b11 Invalid
// Fetch Line Stack Pointer points to               [Place in Line 2'b00] //* Active Line
// Check PopValid  
// > If True: Fetch Line Stack Pointer points to +1 [Place in Line 2'b01] //* Next Pop
// > If False: Mark Line 2'b01 Invalid
// Set Head to 2'b00
// Set Tail to 2'b10
// Clear StackCacheBusy













//? Pushing Out of a Line
// Increment Head
// Check if Tail is Valid AND StackLine+2
// > If True: Increment Tail
// > If False: Check if NextLinePushValid
//    :WaitLoop
//    > If True: Check if Line Clean
//      > If True: Mark Invalid
//      > If False: Wait
//          > If Line Gets Clean: GoTo WaitLoop
//          > If 
//    > If False: Do Nothing - On Bounds









//? Pushing Out of a Line
// Increment Head
// > Check if Tail is Valid AND StackLine+2
//   > If True: Increment Tail
//   > If False: Mark Invalid
//   > Check If (OnBounds || PushOnBounds)
//     > If True: //* END
//     > If False: Check For CleanStatus
//       > If Clean : Fetch StackLine+2
//         > Increment Tail
//         > Mark Valid when Fetch completes
//       > If Dirty : Wait Till Clean
//         > Fetch StackLine+2
//         > Increment Tail
//         > Mark Valid when Fetch completes

//? Popping Out of a Line
// Decrement Head
// > Check if Tail is Valid AND StackLine-2
//   > If True: Deccrement Tail
//   > If False: Mark Invalid
//     > Check If (OnBounds || PopOnBounds)
//       > If True: //* END
//     > If False: Check For CleanStatus
//       > If Clean : Fetch StackLine-2
//         > Increment Tail
//         > Mark Valid when Fetch completes
//       > If Dirty : Wait Till Clean
//         > Fetch StackLine-2
//         > Increment Tail
//         > Mark Valid when Fetch completes

module StackCache_Line_StateMachine (
    input  clk,
    input  clk_en,
    input  sync_rst,

    output StackBusy,
    
);

//? Head

//? Tail

//? Stack Bound Check Vector
// > Buffer the new status after each buffer updates

//? Status Vector
// > Tracks Valid and Pending-Fetch




endmodule : StackCache_Line_StateMachine


