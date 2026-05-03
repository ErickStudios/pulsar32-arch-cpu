module cpu(
    input       clk,
    input       reset
);

// machine variables use for the runtime
// def section

// ============== cpu mangment ==============
reg  [7:0]      memory                  [0:64000];  // the memory
reg  [31:0]     pc;                                 // the program counter
reg  [31:0]     sp;                                 // the stack pointer
// ============== registers categories ==============
reg  [7:0]      reg8                    [0:15];     // registers8
reg  [15:0]     reg16                   [0:15];     // registers16
reg  [31:0]     reg32                   [0:15];     // registers32
// ============== modes ==============
reg  [7:0]      ir;                                 // current opcode instruction
reg  [7:0]      opcode;                             // current opcode
reg  [7:0]      mode;                               // mode of the operation
reg  [7:0]      operationModes;                     // operation mode
wire [3:0]      opModH;                             // operation mode high
wire [3:0]      opModL;                             // operation mode low
// ============== general registers ==============
reg  [31:0]     currentPtrAddrs;                    // register of the current uint8_t* ptr
wire [7:0]      PXB1 = currentPtrAddrs  [31:24];    // byte 1 of PX
wire [7:0]      PXB2 = currentPtrAddrs  [23:16];    // byte 2 of PX
wire [7:0]      PXB3 = currentPtrAddrs  [15:8];     // byte 3 of PX
wire [7:0]      PXB4 = currentPtrAddrs  [7:0];      // byte 4 of PX
reg  [7:0]      OprOperator;                        // operator operation
reg  [7:0]      OprOperationBytes;                  // operation bytes length
reg  [7:0]      valueRegister;                      // DX = *(uint8_t*)PX
reg  [7:0]      op_id;                              // operation id
reg  [31:0]     a, b, result;                       // result
// ============== temporaly ==============
assign          opModH = operationModes[7:4];       // operation mode high byte
assign          opModL  = operationModes[3:0];      // operation mode low byte
`define         STR_INM  "INM     "                 // operation mode
`define         STR_REG  "REGISTER"                 // register mode
`define         STR_STK  "STACK   "                 // stack mode
`define         STR_UNK  "????????"                 // unknown mode
integer i;

// ============== function for debug ==============
// | the function for convert operation modes to  |
// | human readable words for identific the opera-|
// | tions                                        |
// |                                              |
// | #DEBUG #CASTING #HUMANREADABLE               |
// ------------------------------------------------
function [63:0] castToDebug; input [3:0] modeOpr; begin 
    case (modeOpr)
        4'h0: castToDebug = `STR_INM;               // str inm
        4'h1: castToDebug = `STR_REG;               // str reg
        4'h2: castToDebug = `STR_STK;               // str stack
        default: castToDebug = `STR_UNK;            // str unknown
    endcase 
end endfunction

// ============== function for inms  ==============
// | read a inmediate in the text of the program  |
// |                                              |
// | #NONDEBUG #INM #FUNCTION                     |
// ------------------------------------------------
function [31:0] readINM; input [7:0] bytesLen; input [31:0] baseAddr; begin
    case (bytesLen)
        1: readINM = memory[baseAddr];
        2: readINM = {memory[baseAddr],memory[baseAddr + 1]};
        4: readINM = {memory[baseAddr],memory[baseAddr + 1],memory[baseAddr + 2],memory[baseAddr + 3]
        };
        default: readINM = 0;
    endcase
end endfunction

// ============== function for opers ==============
// | A instant function for the operations regs   |
// | , inms, stack and other modes                |
// |                                              |
// | #FASTER #STARTER                             |
// ------------------------------------------------
function [31:0] operateInstant; input [3:0] modeOpr; input [7:0] bytesLen; begin
    case (modeOpr)
        4'h0: begin
            operateInstant = readINM(bytesLen, pc);
            pc = pc + bytesLen;
        end
        4'h1: begin
            a = memory[pc];
            pc = pc + 1;

            case (a)
                0: operateInstant = result;
                1: operateInstant = valueRegister;
                2: operateInstant = currentPtrAddrs;
                default: operateInstant = 0;
            endcase
        end
        4'h2: begin
            operateInstant = readINM(bytesLen, sp);
            sp = sp + bytesLen;
        end
        default: begin while (1); end
    endcase
end endfunction

// ============== function for clock ==============
// | This functions keeps on the machine for make |
// | it makes things                              |
// |                                              |
// | #LOOP #NONDEBUG #DEBUG                       |
// ------------------------------------------------
always @(posedge clk) begin
    // reset signal power on/restart computer
    if (reset) begin
        pc = 0;
        sp = 63000;
        ir = 0;
    // tick of click
    end else begin
        // fetch instruction
        ir = memory[pc];                           // current instruction
        pc = pc + 1;                               // increment program counter

        case (ir)
            // LPX = Load Pointer eXpretion
            8'h01: begin
                // fetch mode
                mode = memory[pc];
                pc = pc + 1;
                // mode of operation
                case (mode)
                    // from inmediate
                    8'h20: begin
                        currentPtrAddrs = {
                            memory      [pc],       // blk1
                            memory      [pc+1],     // blk2
                            memory      [pc+2],     // blk3
                            memory      [pc+3]      // blk4
                        };
                        pc = pc + 4;                // increment pc
                        $display("INM32      LPX 0x%x", currentPtrAddrs);
                        pc = pc + 1;                // increment pc         
                    end
                    // from stack
                    8'h1A: begin
                        $display("STACK32    LPX");
                        currentPtrAddrs = {
                            memory      [sp],       // blk1
                            memory      [sp+1],     // blk2
                            memory      [sp+2],     // blk3
                            memory      [sp+3]      // blk4
                        };
                         sp = sp + 4;               // increment pc 
                    end
                endcase
            end
            // LDX = Load From Memory To Data RegiXter (Data Register = valueRegister beta name)
            8'h02: begin
                $display("REGISTER8  LDX");
                valueRegister = memory[currentPtrAddrs];
            end
            // PUS = Push Unity or regiSter
            8'h03: begin
                mode = memory[pc];
                OprOperationBytes = memory[pc + 1];
                pc = pc + 2;

                a = operateInstant(mode[7:4],OprOperationBytes);

                $display("ANONYMUS   PUS %0d", a);

                for (i = 0; i < OprOperationBytes; i = i + 1) begin
                    sp = sp - 1;
                    memory[sp] = a >> (8*i);
                end
            end
            // OPR = Operation Propurse with Result
            8'h04: begin
                // fetch mode
                OprOperator = memory[pc];           // operator
                OprOperationBytes = memory[pc + 1]; // operation bytes len
                operationModes = memory[pc + 2];    // operation mode
                pc = pc + 3;                        // increment pc

                $write("ANONYMUS");
                if ((OprOperationBytes * 8) < 10)
                    $write("%0d ", OprOperationBytes * 8);
                else
                    $write("%0d", OprOperationBytes * 8);
                $write(" OPR %0d ", OprOperator);

                $write("%s ", castToDebug(operationModes[7:4]));
                $write("%s\n", castToDebug(operationModes[3:0]));

                a = operateInstant(operationModes[7:4],OprOperationBytes);
                b = operateInstant(operationModes[3:0],OprOperationBytes);

                case (OprOperator) 
                    8'h01: result = a + b;
                    8'h02: result = a - b;
                    8'h03: result = a * b;
                    8'h04: result = a / b;
                endcase

            end

        endcase
    end
end

endmodule