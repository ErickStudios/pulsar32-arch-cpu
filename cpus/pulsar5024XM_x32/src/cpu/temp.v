// ============== temporaly ==============
assign          opModH = operationModes[7:4];       // operation mode high byte
assign          opModL  = operationModes[3:0];      // operation mode low byte
`define         STR_INM  "INM     "                 // operation mode
`define         STR_REG  "REGISTER"                 // register mode
`define         STR_STK  "STACK   "                 // stack mode
`define         STR_UNK  "????????"                 // unknown mode