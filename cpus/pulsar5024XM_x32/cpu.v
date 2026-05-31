module device #(
    parameter BASE_ADDR = 32'h3000
)(
    input               clk,
    input               enable,
    input               reset,
    input [7:0]         data_in,
    
    output reg          irq,
    output reg [31:0]   irq_addr,
    output reg [7:0]    irq_data,
    input               irq_ack,

    input               wrt_en,
    input [31:0]        wrt_addr,
    input [7:0]         wrt_val
);

reg  [7:0]              device_buffer;
reg                     active;

always @(posedge clk) begin
    if (reset) begin
        irq = 0;
        active = 0;
        irq_addr = 0;
        irq_data = 0;
        device_buffer <= 0;
    end else begin
        if (wrt_en && (wrt_addr == BASE_ADDR)) begin
            device_buffer <= wrt_val;
        end
        
        if (enable)
            active = 1;
        if (active && !irq) begin
            irq = 1;
            irq_addr = BASE_ADDR;
            irq_data = data_in;
        end

        if (irq && irq_ack) begin
            irq = 0;
            active = 0;
        end
    end
end
endmodule
module alu(
    input       [7:0]   opcode,
    input       [31:0]  a,
    input       [31:0]  b,
    input               aluActive,
    input               clk,
    output reg  [31:0]  result
);

always @(posedge clk) begin
    if (aluActive == 1) begin
        case(opcode)
            8'h01: result = a + b;
            8'h02: result = a - b;
            8'h03: result = a * b;
            8'h04: result = a / b;
            8'h05: result = a & b;
            8'h06: result = a | b;
            8'h07: result = a ^ b;
            8'h09: result = a << b;
            8'h0A: result = a >> b;
            default: result = 0;
        endcase
    end
end

endmodule
module cpu(
    input           clk,
    input           reset,
    input           irq,
    input [31:0]    irq_addr,
    input [7:0]     irq_data,
    output reg      irq_ack,

    input [7:0]     mem_wrt_val,
    input [31:0]    mem_wrt_addr,
    input           mem_wrt_bool,

    output reg [7:0] mem_rdr_val,
    input [31:0]    mem_rdr_addr,
    input           mem_rdr_bool,

    output reg      dev_wrt_en,
    output reg [31:0] dev_wrt_addr,
    output reg [7:0]  dev_wrt_val,

    output reg      mem_wrt_ene,
    output reg [31:0] mem_wrt_addre,
    output reg [7:0]  mem_wrt_vale
);

// ============== cpu variables ==============}
reg  [7:0]          memory [0:96000]; // 64K normal mem, 32K for MMIO
reg  [31:0]         pc;
reg  [31:0]         sp;
reg  [31:0]         currentPtrAddrs;
wire [7:0]          PXB1 = currentPtrAddrs  [31:24];
wire [7:0]          PXB2 = currentPtrAddrs  [23:16];
wire [7:0]          PXB3 = currentPtrAddrs  [15:8];
wire [7:0]          PXB4 = currentPtrAddrs  [7:0];
reg  [7:0]          OprOperator;
reg  [7:0]          OprOperationBytes;
reg  [7:0]          valueRegister;
reg  [7:0]          op_id;
reg  [31:0]         a, b, result;
reg  [7:0]          ir;
reg  [7:0]          opcode;
reg  [7:0]          mode;
reg  [7:0]          operationModes;
reg  [7:0]          flags;
reg [31:0]          vector_base;
reg [31:0]          offset;
reg [31:0]          irq_vector;
reg                 quiet = 0;
reg                 paused;
reg [1:0]           CWFDD;
reg [1:0]           CWFDM;

// ============== alu components ==============
reg  [31:0]         aluA;
reg  [31:0]         aluB;
wire [31:0]         aluResult;
reg  [1:0]          aluState;
reg                 aluActive;

alu                 alu0(
    .opcode         (OprOperator),
    .a              (aluA),
    .b              (aluB),
    .aluActive      (aluActive),
    .clk            (clk),
    .result         (aluResult)
);

// ============== temporaly ==============
`define         STR_INM  "INME"                 // operation mode
`define         STR_REG  "REGI"                 // register mode
`define         STR_STK  "STCK"                 // stack mode
`define         STR_UNK  "????"                 // unknown mode
integer i;

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
task operateInstant; 
input [3:0] modeOpr; 
input [7:0] bytesLen; 
output [31:0] val;
begin
    case (modeOpr)
        4'h0: begin
            val = readINM(bytesLen, pc);
            pc = pc + bytesLen;
        end
        4'h1: begin
            a = memory[pc];
            pc = pc + 1;

            case (a)
                0: val = result;
                1: val = valueRegister;
                2: val = currentPtrAddrs;
                default: val = 0;
            endcase
        end
        4'h2: begin
            val = readINM(bytesLen, sp);
            sp = sp + bytesLen;
        end
        default: val = 0;
    endcase
end endtask

task alu_check; begin
    if (aluState == 1) begin
        aluState = 2;
    end
    else if (aluState == 2) begin
        result = aluResult;
        aluActive = 0;
        aluState = 0;
    end
end endtask
task alu_reset; begin
    aluState = 0;
    aluActive = 0;
    aluA = 0;
    aluB = 0;
end endtask

task general_reset; begin
    pc <= {
        memory[0],
        memory[1],
        memory[2],
        memory[3]
    };
    sp = 95000;
    ir = 0;
    paused = 0;
end endtask
task save_dir; begin
    sp = sp - 4;
    memory[sp]     = pc[31:24];
    memory[sp + 1] = pc[23:16];
    memory[sp + 2] = pc[15:8];
    memory[sp + 3] = pc[7:0];
end endtask

task ex_lpx; begin
    mode = memory[pc];
    OprOperationBytes = memory[pc + 1];
    pc = pc + 2;

    if (!quiet) $write("ANONYMUS");
    if ((OprOperationBytes * 8) < 10) begin
        if (!quiet) $write("%0d ", OprOperationBytes * 8);
    end
    else begin
        if (!quiet) $write("%0d", OprOperationBytes * 8);
    end
    if (!quiet) $write(" LPX %s", castToDebug(mode[3:0]));
    operateInstant(mode[3:0],OprOperationBytes,a);
    if (!quiet) $write(" %0d\n", a);

    currentPtrAddrs = a;
end endtask

task write_mem_byte; 
input [31:0]    addr;
input [7:0]     val;
begin
    if (addr > 63999) begin
        CWFDD = 2;
        dev_wrt_en   = 1;
        dev_wrt_addr = addr - 64000;
        dev_wrt_val  = val;
    end
    CWFDM = 2;
    mem_wrt_ene   = 1;
    mem_wrt_addre = addr;
    mem_wrt_vale  = val;
    memory[addr] = val;
end endtask
task ex_ldx; begin
    if (!quiet) $display("REGISTER8  LDX");
    valueRegister = memory[currentPtrAddrs];
end endtask
task ex_pus; begin
    mode = memory[pc];
    OprOperationBytes = memory[pc + 1];
    pc = pc + 2;

    operateInstant(mode[3:0],OprOperationBytes,a);

    if (!quiet) $display("ANONYMUS   PUS %s %0d", castToDebug(mode[3:0]), a);

    for (i = 0; i < OprOperationBytes; i = i + 1) begin
        sp = sp - 1;
    end

    for (i = 0; i < OprOperationBytes; i = i + 1) begin
        memory[sp+i] = a >> (8*(OprOperationBytes-1-i));
    end
end endtask
task ex_opr; begin
    // fetch mode
    OprOperator = memory[pc];           // operator
    OprOperationBytes = memory[pc + 1]; // operation bytes len
    operationModes = memory[pc + 2];    // operation mode
    pc = pc + 3;                        // increment pc

    if (!quiet) $write("ANONYMUS");
    if ((OprOperationBytes * 8) < 10) begin
        if (!quiet) $write("%0d ", OprOperationBytes * 8);
    end
    else begin
        if (!quiet) $write("%0d", OprOperationBytes * 8);
    end
    if (!quiet) $write(" OPR ");

    if (!quiet) $write("%s ", castToDebug(operationModes[7:4]));
    if (!quiet) $write("%s %0d\n", castToDebug(operationModes[3:0]), OprOperator);

    if (OprOperator != 8'h08) operateInstant(operationModes[7:4],OprOperationBytes, a);
    if (OprOperator != 8'h08) operateInstant(operationModes[3:0],OprOperationBytes, b);

    case (OprOperator) 
        8'h08: begin
            result = readINM(OprOperationBytes, currentPtrAddrs); 
        end
        default: begin
            aluA = a;
            aluB = b;
            aluActive = 1;
            aluState = 1;
        end
    endcase

end endtask
task ex_cmp; begin
    // fetch mode
    OprOperationBytes = memory[pc]; // operation bytes len
    operationModes = memory[pc + 1];    // operation mode
    pc = pc + 2;                        // increment pc

    if (!quiet) $write("ANONYMUS");
    if ((OprOperationBytes * 8) < 10) begin
        if (!quiet) $write("%0d ", OprOperationBytes * 8);
    end
    else begin
        if (!quiet) $write("%0d", OprOperationBytes * 8);
    end
    if (!quiet) $write(" CMP ");

    if (!quiet) $write("%s ", castToDebug(operationModes[7:4]));
    if (!quiet) $write("%s\n", castToDebug(operationModes[3:0]));

    operateInstant(operationModes[7:4],OprOperationBytes,a);
    operateInstant(operationModes[3:0],OprOperationBytes,b);

    result = a - b;
    flags = 0;
    if (result == 0) flags[0] = 1;
    if (result[31] == 1) flags[1] = 1;
    if (result > 0 && result[31] == 0) flags[2] = 1;
end endtask
task ex_jmp; begin
    // fetch mode
    OprOperationBytes = memory[pc];     // operation bytes len
    operationModes = memory[pc + 1];    // operation mode
    mode = memory[pc + 2];              // jmp template
    pc = pc + 3;                        // increment pc

    if (!quiet) $write("ANONYMUS");
    if ((OprOperationBytes * 8) < 10) begin
        if (!quiet) $write("%0d ", OprOperationBytes * 8);
    end 
    else begin
        if (!quiet) $write("%0d", OprOperationBytes * 8);
    end
    if (!quiet) $write(" JMP ");
    if (!quiet) $write("%s ", castToDebug(operationModes[3:0]));

    operateInstant(operationModes[3:0],OprOperationBytes,a);
    if (!quiet) $write("%0d\n", a);
    case (mode)
        // normal jmp 
        8'h00: pc = a;
        // if equal jmp
        8'h01: begin if (flags[0]) pc = a;end
        // if less jmp
        8'h02: begin if (flags[1]) pc = a;end
        // if greater jmp
        8'h03: begin if (flags[2]) pc = a;end
        // call
        8'h04: begin save_dir(); pc = a; end
    endcase
end endtask
task ex_sdx; begin
    mode = memory[pc];
    OprOperationBytes = memory[pc + 1];
    pc = pc + 2;

    operateInstant(mode[3:0],OprOperationBytes, a);
    if (!quiet) $write("ANONYMUS");
    if ((OprOperationBytes * 8) < 10) begin
        if (!quiet) $write("%0d ", OprOperationBytes * 8);
    end 
    else begin
        if (!quiet) $write("%0d", OprOperationBytes * 8);
    end 
    if (!quiet) $write(" SDX %s %0d\n", castToDebug(mode[3:0]), a);

    for (i = 0; i < OprOperationBytes; i = i + 1) begin
        write_mem_byte(currentPtrAddrs + i, a >> (8*i));
    end
end endtask

task irq_check; begin
    if (!quiet) $write("%d (%8x) ",pc - 1, pc);
    if (!quiet) $display("HARDWARE   IRQ %0d %0d", irq_addr, irq_data);
    paused = 0;
    irq_ack <= 1; 
    save_dir();
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
end endtask

// ============== function for clock ==============
// | This functions keeps on the machine for make |
// | it makes things                              |
// |                                              |
// | #LOOP #NONDEBUG #DEBUG                       |
// ------------------------------------------------
always @(posedge clk) begin
    // reset signal power on/restart computer
    if (reset) begin        
        general_reset();
        alu_reset();
        CWFDD = 0;
    // tick of click
    end else begin
        if (CWFDD == 1) begin
            dev_wrt_en = 0;
            CWFDD = CWFDD - 1;
        end
        else if (CWFDD != 0) begin
            CWFDD = CWFDD - 1;
        end

        if (CWFDM == 1) begin
            mem_wrt_ene = 0;
            CWFDM = CWFDM - 1;
        end
        else if (CWFDM != 0) begin
            CWFDM = CWFDM - 1;
        end
                if (sp < 50000) begin
            if (!quiet) $display("HARDWARE   STACK OVERFLOW %0d %0d", irq_addr, irq_data);
            general_reset();
            alu_reset();
        end

        if (mem_wrt_bool) begin
            memory[mem_wrt_addr] <= mem_wrt_val;
        end

        if (mem_rdr_bool) begin 
            mem_rdr_val <= memory[mem_rdr_addr]; 
        end

        // check alu
        alu_check();

        if (irq && !irq_ack) begin
            irq_check();
        end else if (!paused && !aluState) begin
        irq_ack <= 0;

        // fetch instruction
        ir = memory[pc];                           // current instruction
        pc = pc + 1;                               // increment program counter

        if (!quiet) $write("%d (%8x) ",pc - 1, pc);
        case (ir)
            // LPX = Load Pointer eXpretion
            8'h01: ex_lpx();
            // LDX = Load From memory To Data RegiXter (Data Register = valueRegister beta name)
            8'h02: ex_ldx();
            // PUS = Push Unity or regiSter
            8'h03: ex_pus();
            // OPR = Operation Propurse with Result
            8'h04: ex_opr();
            // HLT = Halt main Tread
            8'h05: begin if (!quiet) $display("NULL0      HLT"); paused = 1; end
            // CMP = Compare Multi Parse
            8'h06: ex_cmp();
            // JMP = Jump Multi Templates
            8'h07: ex_jmp();
            // SDX = Save Data RegiXters to memory
            8'h08: ex_sdx();
        endcase
    end
    end
    $fflush();
end

endmodule
