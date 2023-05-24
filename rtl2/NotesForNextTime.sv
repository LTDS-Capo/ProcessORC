//! Check on the ToBeWritten and when it was supposed to be used... never integrated it
//! - ToBeWritten was to prevent a 2nd level of write hazards to a given register backing up, system should stall if this bit is raised for an operand


//! Update ToBeRead and Dirty Logic
//! Review what happens to register status bits during the exit of a misprediction [Have a rollback state]
//! Finish update to RunaheadOperandValidation
//! Work on what the stack cache should do with its Register Status stuff....

//! Continue work on refactoring Register Status
//! maybe.. finally.. get to Stack Cache

//? ToBeWritten Stall can also cover for if you try and access the stack and it causes it to go out of range with no free space in the cache