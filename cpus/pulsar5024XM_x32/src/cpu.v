module cpu(
    input           clk,
    input           reset,
    input           irq,
    input [31:0]    irq_addr,
    input [7:0]     irq_data,
    output reg      irq_ack
);

reg [31:0]          vector_base;
reg [31:0]          offset;
reg [31:0]          irq_vector;

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
        pc <= {
            memory[0],
            memory[1],
            memory[2],
            memory[3]
        };
        sp = 63000;
        ir = 0;
        paused = 0;
    // tick of click
    end else begin
        if (irq) begin
            paused = 0;
            irq_ack <= 1; 
            sp = sp - 4;
            memory[sp]     = pc[31:24];
            memory[sp + 1] = pc[23:16];
            memory[sp + 2] = pc[15:8];
            memory[sp + 3] = pc[7:0];
            valueRegister = irq_data;
            vector_base = 4;
            offset = irq_addr * 4;
            irq_vector = {
                memory[vector_base + offset],
                memory[vector_base + offset + 1],
                memory[vector_base + offset + 2],
                memory[vector_base + offset + 3]
            };
            pc = irq_vector;
        end else if (!paused) begin
        irq_ack <= 0;

        // fetch instruction
        ir = memory[pc];                           // current instruction
        pc = pc + 1;                               // increment program counter

        case (ir)
            // LPX = Load Pointer eXpretion
            8'h01: begin
                mode = memory[pc];
                OprOperationBytes = memory[pc + 1];
                pc = pc + 2;

                a = operateInstant(mode[7:4],OprOperationBytes);

                $write("ANONYMUS");
                if ((OprOperationBytes * 8) < 10)
                    $write("%0d ", OprOperationBytes * 8);
                else
                    $write("%0d", OprOperationBytes * 8);
                $write(" LPX %0d\n", a);

                currentPtrAddrs = a;
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

                a = operateInstant(mode[3:0],OprOperationBytes);

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

                if (OprOperator != 8'h08) a = operateInstant(operationModes[7:4],OprOperationBytes);
                if (OprOperator != 8'h08) b = operateInstant(operationModes[3:0],OprOperationBytes);

                case (OprOperator) 
                    8'h01: result = a + b;
                    8'h02: result = a - b;
                    8'h03: result = a * b;
                    8'h04: result = a / b;
                    8'h05: result = a & b;
                    8'h06: result = a | b;
                    8'h07: result = a ^ b;
                    // complex LDX
                    8'h08: begin
                        result = readINM(OprOperationBytes, currentPtrAddrs); 
                    end
                endcase

            end
            // HLT = Halt main Tread
            8'h05: begin 
                paused = 1;
            end
            // CMP = Operation Propurse with Result
            8'h06: begin
                // fetch mode
                OprOperationBytes = memory[pc]; // operation bytes len
                operationModes = memory[pc + 1];    // operation mode
                pc = pc + 2;                        // increment pc

                $write("ANONYMUS");
                if ((OprOperationBytes * 8) < 10)
                    $write("%0d ", OprOperationBytes * 8);
                else
                    $write("%0d", OprOperationBytes * 8);
                $write(" CMP ");

                $write("%s ", castToDebug(operationModes[7:4]));
                $write("%s\n", castToDebug(operationModes[3:0]));

                a = operateInstant(operationModes[7:4],OprOperationBytes);
                b = operateInstant(operationModes[3:0],OprOperationBytes);

                result = a - b;
                flags = 0;
                if (result == 0)
                    flags[0] = 1;
                if (result[31] == 1)
                    flags[1] = 1;
                if (result > 0 && result[31] == 0)
                    flags[2] = 1;
            end
            // JMP = Operation Propurse with Result
            8'h07: begin
                // fetch mode
                OprOperationBytes = memory[pc];     // operation bytes len
                operationModes = memory[pc + 1];    // operation mode
                mode = memory[pc + 2];              // jmp template
                pc = pc + 3;                        // increment pc

                $write("ANONYMUS");
                if ((OprOperationBytes * 8) < 10)
                    $write("%0d ", OprOperationBytes * 8);
                else
                    $write("%0d", OprOperationBytes * 8);
                $write(" JMP ");

                $write("%s ", castToDebug(operationModes[3:0]));

                a = operateInstant(operationModes[3:0],OprOperationBytes);
                $write("%0d\n", a);
                case (mode)
                    // normal jmp 
                    8'h00: pc = a;
                    // if equal jmp
                    8'h01: begin 
                        if (flags[0]) pc = a;
                    end
                    // if less jmp
                    8'h02: begin 
                        if (flags[1]) pc = a;
                    end
                    // if greater jmp
                    8'h03: begin 
                        if (flags[2]) pc = a;
                    end
                endcase

            end
            // SDX = Save Data RegiXters to memory
            8'h08: begin
                mode = memory[pc];
                OprOperationBytes = memory[pc + 1];
                pc = pc + 2;

                a = operateInstant(mode[3:0],OprOperationBytes);
                $write("ANONYMUS");
                if ((OprOperationBytes * 8) < 10)
                    $write("%0d ", OprOperationBytes * 8);
                else
                    $write("%0d", OprOperationBytes * 8);
                $write(" SDX %0d\n", a);

                for (i = 0; i < OprOperationBytes; i = i + 1) begin
                    memory[currentPtrAddrs + i] = a >> (8*i);
                end
            end
        endcase
    end
    end
end

endmodule