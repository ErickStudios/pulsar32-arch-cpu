module cpu(
    input           clk,
    input           reset,
    input           irq,
    input [31:0]    irq_addr,
    input [7:0]     irq_data,
    output reg      irq_ack
);

// ============== cpu components ==============
cpug                cpg();
cpum                cpm();
generalRegisters    gr();
cpuv                cpv();
reg                 quiet = 0;

// ============== alu components ==============
reg  [31:0]         aluA;
reg  [31:0]         aluB;
wire [31:0]         aluResult;
reg  [1:0]          aluState;
reg                 aluActive;

alu                 alu0(
    .opcode         (gr.OprOperator),
    .a              (aluA),
    .b              (aluB),
    .aluActive      (aluActive),
    .clk            (clk),
    .result         (aluResult)
);

// ============== temporaly ==============
`define         STR_INM  "INME"                 // operation cpm.mode
`define         STR_REG  "REGI"                 // register cpm.mode
`define         STR_STK  "STCK"                 // stack cpm.mode
`define         STR_UNK  "????"                 // unknown cpm.mode
integer i;

// ============== function for inms  ==============
// | read a inmediate in the text of the program  |
// |                                              |
// | #NONDEBUG #INM #FUNCTION                     |
// ------------------------------------------------
function [31:0] readINM; input [7:0] bytesLen; input [31:0] baseAddr; begin
    case (bytesLen)
        1: readINM = cpg.memory[baseAddr];
        2: readINM = {cpg.memory[baseAddr],cpg.memory[baseAddr + 1]};
        4: readINM = {cpg.memory[baseAddr],cpg.memory[baseAddr + 1],cpg.memory[baseAddr + 2],cpg.memory[baseAddr + 3]
        };
        default: readINM = 0;
    endcase
end endfunction

// ============== function for debug ==============
// | the function for convert operation modes to  |
// | human readable words for identific the opera-|
// | tions                                        |
// |                                              |
// | #DEBUG #CASTING #HUMANREADABLE               |
// ------------------------------------------------
function [31:0] castToDebug; input [3:0] modeOpr; begin 
    case (modeOpr)
        4'h0: castToDebug = `STR_INM;               // str inm
        4'h1: castToDebug = `STR_REG;               // str reg
        4'h2: castToDebug = `STR_STK;               // str stack
        default: castToDebug = `STR_UNK;            // str unknown
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
            operateInstant = readINM(bytesLen, cpg.pc);
            cpg.pc = cpg.pc + bytesLen;
        end
        4'h1: begin
            gr.a = cpg.memory[cpg.pc];
            cpg.pc = cpg.pc + 1;

            case (gr.a)
                0: operateInstant = gr.result;
                1: operateInstant = gr.valueRegister;
                2: operateInstant = gr.currentPtrAddrs;
                default: operateInstant = 0;
            endcase
        end
        4'h2: begin
            operateInstant = readINM(bytesLen, cpg.sp);
            cpg.sp = cpg.sp + bytesLen;
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
        cpg.pc <= {
            cpg.memory[0],
            cpg.memory[1],
            cpg.memory[2],
            cpg.memory[3]
        };
        cpg.sp = 63000;
        cpm.ir = 0;
        cpm.paused = 0;
        
        aluActive <= 0;
        aluA <= 0;
        aluB <= 0;
    // tick of click
    end else begin
        // alu disabling
        if (aluState == 1) begin
            aluState = 2;
        end
        else if (aluState == 2) begin
            gr.result = aluResult;
            aluActive = 0;
            aluState = 0;
        end

        if (irq && !irq_ack) begin
            if (!quiet) $display("HARDWARE   IRQ %0d %0d", irq_addr, irq_data);
            cpm.paused = 0;
            irq_ack <= 1; 
            cpg.sp = cpg.sp - 4;
            cpg.memory[cpg.sp]     = cpg.pc[31:24];
            cpg.memory[cpg.sp + 1] = cpg.pc[23:16];
            cpg.memory[cpg.sp + 2] = cpg.pc[15:8];
            cpg.memory[cpg.sp + 3] = cpg.pc[7:0];
            gr.valueRegister = irq_data;
            cpv.vector_base = 4;
            cpv.offset = irq_addr * 4;
            cpv.irq_vector = {
                cpg.memory[cpv.vector_base + cpv.offset],
                cpg.memory[cpv.vector_base + cpv.offset + 1],
                cpg.memory[cpv.vector_base + cpv.offset + 2],
                cpg.memory[cpv.vector_base + cpv.offset + 3]
            };
            cpg.pc = cpv.irq_vector;
        end else if (!cpm.paused) begin
        irq_ack <= 0;

        // fetch instruction
        cpm.ir = cpg.memory[cpg.pc];                           // current instruction
        cpg.pc = cpg.pc + 1;                               // increment program counter

        case (cpm.ir)
            // LPX = Load Pointer eXpretion
            8'h01: begin
                cpm.mode = cpg.memory[cpg.pc];
                gr.OprOperationBytes = cpg.memory[cpg.pc + 1];
                cpg.pc = cpg.pc + 2;

                if (!quiet) $write("ANONYMUS");
                if ((gr.OprOperationBytes * 8) < 10) begin
                    if (!quiet) $write("%0d ", gr.OprOperationBytes * 8);
                end
                else begin
                    if (!quiet) $write("%0d", gr.OprOperationBytes * 8);
                end
                if (!quiet) $write(" LPX %s", castToDebug(cpm.mode[3:0]));
                gr.a = operateInstant(cpm.mode[3:0],gr.OprOperationBytes);
                if (!quiet) $write(" %0d\n", gr.a);

                gr.currentPtrAddrs = gr.a;
            end
            // LDX = Load From cpg.memory To Data RegiXter (Data Register = valueRegister beta name)
            8'h02: begin
                if (!quiet) $display("REGISTER8  LDX");
                gr.valueRegister = cpg.memory[gr.currentPtrAddrs];
            end
            // PUS = Push Unity or regiSter
            8'h03: begin
                cpm.mode = cpg.memory[cpg.pc];
                gr.OprOperationBytes = cpg.memory[cpg.pc + 1];
                cpg.pc = cpg.pc + 2;

                gr.a = operateInstant(cpm.mode[3:0],gr.OprOperationBytes);

                if (!quiet) $display("ANONYMUS   PUS %s %0d", castToDebug(cpm.mode[3:0]), gr.a);

                for (i = 0; i < gr.OprOperationBytes; i = i + 1) begin
                    cpg.sp = cpg.sp - 1;
                    cpg.memory[cpg.sp] = gr.a >> (8*i);
                end
            end
            // OPR = Operation Propurse with Result
            8'h04: begin
                // fetch cpm.mode
                gr.OprOperator = cpg.memory[cpg.pc];           // operator
                gr.OprOperationBytes = cpg.memory[cpg.pc + 1]; // operation bytes len
                cpm.operationModes = cpg.memory[cpg.pc + 2];    // operation cpm.mode
                cpg.pc = cpg.pc + 3;                        // increment cpg.pc

                if (!quiet) $write("ANONYMUS");
                if ((gr.OprOperationBytes * 8) < 10) begin
                    if (!quiet) $write("%0d ", gr.OprOperationBytes * 8);
                end
                else begin
                    if (!quiet) $write("%0d", gr.OprOperationBytes * 8);
                end
                if (!quiet) $write(" OPR ");

                if (!quiet) $write("%s ", castToDebug(cpm.operationModes[7:4]));
                if (!quiet) $write("%s %0d\n", castToDebug(cpm.operationModes[3:0]), gr.OprOperator);

                if (gr.OprOperator != 8'h08) gr.a = operateInstant(cpm.operationModes[7:4],gr.OprOperationBytes);
                if (gr.OprOperator != 8'h08) gr.b = operateInstant(cpm.operationModes[3:0],gr.OprOperationBytes);

                case (gr.OprOperator) 
                    8'h08: begin
                        gr.result = readINM(gr.OprOperationBytes, gr.currentPtrAddrs); 
                    end
                    default: begin
                        aluA <= gr.a;
                        aluB <= gr.b;
                        aluActive <= 1;
                        aluState <= 1;
                    end
                endcase

            end
            // HLT = Halt main Tread
            8'h05: begin 
                cpm.paused = 1;
            end
            // CMP = Operation Propurse with Result
            8'h06: begin
                // fetch cpm.mode
                gr.OprOperationBytes = cpg.memory[cpg.pc]; // operation bytes len
                cpm.operationModes = cpg.memory[cpg.pc + 1];    // operation cpm.mode
                cpg.pc = cpg.pc + 2;                        // increment cpg.pc

                if (!quiet) $write("ANONYMUS");
                if ((gr.OprOperationBytes * 8) < 10) begin
                    if (!quiet) $write("%0d ", gr.OprOperationBytes * 8);
                end
                else begin
                    if (!quiet) $write("%0d", gr.OprOperationBytes * 8);
                end
                if (!quiet) $write(" CMP ");

                if (!quiet) $write("%s ", castToDebug(cpm.operationModes[7:4]));
                if (!quiet) $write("%s\n", castToDebug(cpm.operationModes[3:0]));

                gr.a = operateInstant(cpm.operationModes[7:4],gr.OprOperationBytes);
                gr.b = operateInstant(cpm.operationModes[3:0],gr.OprOperationBytes);

                gr.result = gr.a - gr.b;
                cpm.flags = 0;
                if (gr.result == 0)
                    cpm.flags[0] = 1;
                if (gr.result[31] == 1)
                    cpm.flags[1] = 1;
                if (gr.result > 0 && gr.result[31] == 0)
                    cpm.flags[2] = 1;
            end
            // JMP = Operation Propurse with Result
            8'h07: begin
                // fetch cpm.mode
                gr.OprOperationBytes = cpg.memory[cpg.pc];     // operation bytes len
                cpm.operationModes = cpg.memory[cpg.pc + 1];    // operation cpm.mode
                cpm.mode = cpg.memory[cpg.pc + 2];              // jmp template
                cpg.pc = cpg.pc + 3;                        // increment cpg.pc

                if (!quiet) $write("ANONYMUS");
                if ((gr.OprOperationBytes * 8) < 10) begin
                    if (!quiet) $write("%0d ", gr.OprOperationBytes * 8);
                end 
                else begin
                    if (!quiet) $write("%0d", gr.OprOperationBytes * 8);
                end
                if (!quiet) $write(" JMP ");

                if (!quiet) $write("%s ", castToDebug(cpm.operationModes[3:0]));

                gr.a = operateInstant(cpm.operationModes[3:0],gr.OprOperationBytes);
                if (!quiet) $write("%0d\n", gr.a);
                case (cpm.mode)
                    // normal jmp 
                    8'h00: cpg.pc = gr.a;
                    // if equal jmp
                    8'h01: begin 
                        if (cpm.flags[0]) cpg.pc = gr.a;
                    end
                    // if less jmp
                    8'h02: begin 
                        if (cpm.flags[1]) cpg.pc = gr.a;
                    end
                    // if greater jmp
                    8'h03: begin 
                        if (cpm.flags[2]) cpg.pc = gr.a;
                    end
                endcase

            end
            // SDX = Save Data RegiXters to cpg.memory
            8'h08: begin
                cpm.mode = cpg.memory[cpg.pc];
                gr.OprOperationBytes = cpg.memory[cpg.pc + 1];
                cpg.pc = cpg.pc + 2;

                gr.a = operateInstant(cpm.mode[3:0],gr.OprOperationBytes);
               if (!quiet) $write("ANONYMUS");
                if ((gr.OprOperationBytes * 8) < 10) begin
                    if (!quiet) $write("%0d ", gr.OprOperationBytes * 8);
                end 
                else begin
                    if (!quiet) $write("%0d", gr.OprOperationBytes * 8);
                end 
                if (!quiet) $write(" SDX %s %0d\n", castToDebug(cpm.mode[3:0]), gr.a);

                for (i = 0; i < gr.OprOperationBytes; i = i + 1) begin
                    cpg.memory[gr.currentPtrAddrs + i] = gr.a >> (8*i);
                end
            end
        endcase
    end
    end
end

endmodule