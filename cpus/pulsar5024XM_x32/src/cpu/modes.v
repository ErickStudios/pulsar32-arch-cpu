// ============== modes ==============
reg             paused;                             // if the cpu is paused
reg  [7:0]      ir;                                 // current opcode instruction
reg  [7:0]      opcode;                             // current opcode
reg  [7:0]      mode;                               // mode of the operation
reg  [7:0]      operationModes;                     // operation mode
wire [3:0]      opModH;                             // operation mode high
wire [3:0]      opModL;                             // operation mode low
reg  [7:0]      flags;                              // the flags of the cpu
