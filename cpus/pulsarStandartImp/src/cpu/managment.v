// ============== cpu mangment ==============
reg  [7:0]      memory                  [0:64000];  // the memory
reg  [31:0]     pc;                                 // the program counter
reg  [31:0]     sp;                                 // the stack pointer