module cpu(
    input       clk,
    input       reset
);

// machine variables use for the runtime
// def section

// ============== cpu mangment ==============
`include "src/cpu/managment.v"
// ============== modes ==============
`include "src/cpu/modes.v"
// ============== general registers ==============
`include "src/cpu/generalRegisters.v"
// ============== temporaly ==============
`include "src/cpu/temp.v"
integer i;

`include "src/cpu/debugger.v"
`include "src/cpu/inms.v"
`include "src/cpu/operateInstant.v"

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