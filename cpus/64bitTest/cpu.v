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

// ================= FPU A =================
reg             fpu_a_sig;
reg  [7:0]      fpu_a_exp;
reg  [22:0]     fpu_a_mat;

// ================= FPU B =================
reg             fpu_b_sig;
reg  [7:0]      fpu_b_exp;
reg  [22:0]     fpu_b_mat;

// ================= FPU R =================
reg             fpu_r_sig;
reg  [7:0]      fpu_r_exp;
reg  [22:0]     fpu_r_mat;

// ================= FPU MORE =================
reg  [7:0]      exp_diff;
reg  [24:0]     mat_a_ext;
reg  [24:0]     mat_b_ext;
reg  [24:0]     sum_mat;
reg  [47:0]     mul_mat;
reg  [47:0]     div_mat;

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
            8'h0B: begin
                if (a[30:0] == 31'b0) begin result = b; end 
                else if (b[30:0] == 31'b0) begin result = a; end 
                else begin
                    fpu_a_sig = a[31];
                    fpu_a_exp = a[30:23];
                    fpu_a_mat = a[22:0];

                    fpu_b_sig = b[31];
                    fpu_b_exp = b[30:23];
                    fpu_b_mat = b[22:0];

                    mat_a_ext = {2'b01, fpu_a_mat};
                    mat_b_ext = {2'b01, fpu_b_mat};

                    if (fpu_a_exp >= fpu_b_exp) begin
                        exp_diff  = fpu_a_exp - fpu_b_exp;
                        mat_b_ext = mat_b_ext >> exp_diff;
                        fpu_r_exp = fpu_a_exp;
                    end else begin
                        exp_diff  = fpu_b_exp - fpu_a_exp;
                        mat_a_ext = mat_a_ext >> exp_diff;
                        fpu_r_exp = fpu_b_exp;
                    end

                    if (fpu_a_sig == fpu_b_sig) begin
                        sum_mat   = mat_a_ext + mat_b_ext;
                        fpu_r_sig = fpu_a_sig;
                    end else begin
                        if (mat_a_ext >= mat_b_ext) begin
                            sum_mat   = mat_a_ext - mat_b_ext;
                            fpu_r_sig = fpu_a_sig;
                        end else begin
                            sum_mat   = mat_b_ext - mat_a_ext;
                            fpu_r_sig = fpu_b_sig;
                        end
                    end

                    if (sum_mat[24]) begin 
                        sum_mat   = sum_mat >> 1;
                        fpu_r_exp = fpu_r_exp + 1;
                    end else begin
                        if (sum_mat[23] == 0 && sum_mat[22] == 1) begin sum_mat = sum_mat << 1; fpu_r_exp = fpu_r_exp - 1; end
                        else if (sum_mat[23] == 0 && sum_mat[21] == 1) begin sum_mat = sum_mat << 2; fpu_r_exp = fpu_r_exp - 2; end
                        else if (sum_mat[23] == 0 && sum_mat[20] == 1) begin sum_mat = sum_mat << 3; fpu_r_exp = fpu_r_exp - 3; end
                        else if (sum_mat[23] == 0 && sum_mat[19] == 1) begin sum_mat = sum_mat << 4; fpu_r_exp = fpu_r_exp - 4; end
                        else if (sum_mat[23] == 0 && sum_mat[18] == 1) begin sum_mat = sum_mat << 5; fpu_r_exp = fpu_r_exp - 5; end
                    end

                    fpu_r_mat = sum_mat[22:0];

                    result = {fpu_r_sig, fpu_r_exp, fpu_r_mat};
                end
            end
            8'h0C: begin
                if (a[30:0] == 31'b0) begin 
                    result = {~b[31], b[30:0]};
                end else if (b[30:0] == 31'b0) begin 
                    result = a; 
                end else begin
                    fpu_a_sig = a[31];
                    fpu_a_exp = a[30:23];
                    fpu_a_mat = a[22:0];

                    fpu_b_sig = ~b[31];
                    fpu_b_exp = b[30:23];
                    fpu_b_mat = b[22:0];

                    mat_a_ext = {2'b01, fpu_a_mat};
                    mat_b_ext = {2'b01, fpu_b_mat};

                    if (fpu_a_exp >= fpu_b_exp) begin
                        exp_diff  = fpu_a_exp - fpu_b_exp;
                        mat_b_ext = mat_b_ext >> exp_diff;
                        fpu_r_exp = fpu_a_exp;
                    end else begin
                        exp_diff  = fpu_b_exp - fpu_a_exp;
                        mat_a_ext = mat_a_ext >> exp_diff;
                        fpu_r_exp = fpu_b_exp;
                    end

                    if (fpu_a_sig == fpu_b_sig) begin
                        sum_mat   = mat_a_ext + mat_b_ext;
                        fpu_r_sig = fpu_a_sig;
                    end else begin
                        if (mat_a_ext >= mat_b_ext) begin
                            sum_mat   = mat_a_ext - mat_b_ext;
                            fpu_r_sig = fpu_a_sig;
                        end else begin
                            sum_mat   = mat_b_ext - mat_a_ext;
                            fpu_r_sig = fpu_b_sig;
                        end
                    end

                    if (sum_mat[24]) begin 
                        sum_mat   = sum_mat >> 1;
                        fpu_r_exp = fpu_r_exp + 1;
                    end else begin
                        if (sum_mat[23] == 0 && sum_mat[22] == 1) begin sum_mat = sum_mat << 1; fpu_r_exp = fpu_r_exp - 1; end
                        else if (sum_mat[23] == 0 && sum_mat[21] == 1) begin sum_mat = sum_mat << 2; fpu_r_exp = fpu_r_exp - 2; end
                        else if (sum_mat[23] == 0 && sum_mat[20] == 1) begin sum_mat = sum_mat << 3; fpu_r_exp = fpu_r_exp - 3; end
                        else if (sum_mat[23] == 0 && sum_mat[19] == 1) begin sum_mat = sum_mat << 4; fpu_r_exp = fpu_r_exp - 4; end
                        else if (sum_mat[23] == 0 && sum_mat[18] == 1) begin sum_mat = sum_mat << 5; fpu_r_exp = fpu_r_exp - 5; end
                    end

                    fpu_r_mat = sum_mat[22:0];
                    result = {fpu_r_sig, fpu_r_exp, fpu_r_mat};
                end
            end
            8'h0D: begin
                if (a[30:0] == 31'b0 || b[30:0] == 31'b0) begin
                    result = 32'b0;
                end else begin
                    fpu_a_sig = a[31];
                    fpu_a_exp = a[30:23];
                    fpu_a_mat = a[22:0];

                    fpu_b_sig = b[31];
                    fpu_b_exp = b[30:23];
                    fpu_b_mat = b[22:0];
                    fpu_r_sig = fpu_a_sig ^ fpu_b_sig;
                    fpu_r_exp = (fpu_a_exp + fpu_b_exp) - 8'd127;
                    mul_mat = {1'b1, fpu_a_mat} * {1'b1, fpu_b_mat};

                    if (mul_mat[47]) begin
                        mul_mat = mul_mat >> 1;
                        fpu_r_exp = fpu_r_exp + 1;
                    end
                    fpu_r_mat = mul_mat[45:23];

                    result = {fpu_r_sig, fpu_r_exp, fpu_r_mat};
                end
            end
            8'h0E: begin
                if (b[30:0] == 31'b0) begin
                    result = 32'h7FC00000;
                end else if (a[30:0] == 31'b0) begin
                    result = 32'b0;
                end else begin
                    fpu_a_sig = a[31];
                    fpu_a_exp = a[30:23];
                    fpu_a_mat = a[22:0];

                    fpu_b_sig = b[31];
                    fpu_b_exp = b[30:23];
                    fpu_b_mat = b[22:0];

                    fpu_r_sig = fpu_a_sig ^ fpu_b_sig;
                    fpu_r_exp = (fpu_a_exp - fpu_b_exp) + 8'd127;

                    div_mat = ({1'b1, fpu_a_mat} << 23) / {1'b1, fpu_b_mat};

                    if (div_mat[23] == 0) begin
                        div_mat = div_mat << 1;
                        fpu_r_exp = fpu_r_exp - 1;
                    end

                    fpu_r_mat = div_mat[22:0];
                    result = {fpu_r_sig, fpu_r_exp, fpu_r_mat};
                end
            end
            8'h0F: result = a % b;
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
reg  [7:0]          memory [0:960000]; // 64K normal mem, 32K for MMIO
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
reg  [31:0]         a, b, tempReg, result, r0, r1, r2, r3, r4, r5, r6, r7, r8;
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

// ============== 64 Bit Behavior ==============
reg                 in64Bit;
reg [63:0]          inms64 [0:15];
reg [7:0]           selectedinm64;
reg [63:0]          i64CpuTbl, i64a, i64b, i64memre, i64temp, xsp, x0, x1, x2, x3, x4, x5, x6, x7;
reg [7:0]           i64bytes [0:3];
reg                 i64pend = 0;
reg [3:0]           i64inmba = 0;
reg [3:0]           i64bysiz = 0;
reg [3:0]           i64opr = 0;
reg                 i64runinbg = 0;

reg [63:0]          i64proMemStart;
reg [63:0]          i64proMemEnd;

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
            tempReg = memory[pc];
            pc = pc + 1;

            // register
            case (tempReg)
                0: val =        result; // Out
                1: val =        valueRegister; // [[Obsolete]]
                2: val =        currentPtrAddrs;// Px
                3: val =        r0;     // Ax (a regiXter)
                4: val =        r1;     // Bx (b regiXter)
                5: val =        r2;     // Cx (c/cycles regiXter)
                6: val =        r3;     // Dx (d/dataBackup regiXter)
                7: val =        r4;     // Ah (extra a0 regiXter)
                8: val =        r5;     // Al (extra a1 regiXter)   
                9: val =        r6;     // Bh (extra b1 regiXter)   
                10:val =        r7;     // Bl (extra b2 regiXter)   
                11:val =        sp;     // Ss (Stack regiSter)   
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
    i64runinbg <= 0;
    i64perms = 64'hFFFFFFFFFFFFFFFF;
    in64Bit <= 0;
    sp = 95000;
    xsp = 0;

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

task write_mem_byte; 
input [31:0]    addr;
input [7:0]     val;
begin
    if (i64runinbg ? !checIfMemkBoundles64Exepction(addr, 0) : 1) begin
        if (addr > 63999) begin
            CWFDD = 1;
            dev_wrt_en   = 1;
            dev_wrt_addr = addr - 64000;
            dev_wrt_val  = val;
        end
        CWFDM = 2;
        mem_wrt_ene   = 1;
        mem_wrt_addre = addr;
        mem_wrt_vale  = val;
        memory[addr] = val;
    end
    else begin
        irqJmp64(32'h00000000); // segmentation fault
    end
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
    if (!quiet) $write("%s %0d", castToDebug(operationModes[3:0]), OprOperator);

    if (OprOperator != 8'h08) operateInstant(operationModes[7:4],OprOperationBytes, a);
    if (OprOperator != 8'h08) operateInstant(operationModes[3:0],OprOperationBytes, b);
    if (!quiet) $write(" %0d %0d\n", a,b);

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
    if (!quiet) $write("%s", castToDebug(operationModes[3:0]));
    operateInstant(operationModes[7:4],OprOperationBytes,a);
    operateInstant(operationModes[3:0],OprOperationBytes,b);
    if (!quiet) $write(" %0d %0d\n", a,b);

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
        write_mem_byte(currentPtrAddrs + i, (a >> (8 * (OprOperationBytes - 1 - i))) & 8'hFF);
    end
end endtask
task ex_int; begin
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
    if (!quiet) $write(" INT %s %0d\n", castToDebug(mode[3:0]), a);
    int_launch(a);
end endtask
task ex_wrx; begin
    mode = memory[pc];
    OprOperationBytes = memory[pc + 1];
    b = memory[pc + 2];
    pc = pc + 3;

    if (!quiet) $write("ANONYMUS");
    if ((OprOperationBytes * 8) < 10) begin
        if (!quiet) $write("%0d ", OprOperationBytes * 8);
    end
    else begin
        if (!quiet) $write("%0d", OprOperationBytes * 8);
    end
    if (!quiet) $write(" WRX ");
    operateInstant(mode[3:0],OprOperationBytes,a);
    if (!quiet) $write("SET REGI %0d TO %s %0d\n",b, castToDebug(mode[3:0]), a);

    // register
    case (b)
        0: result =         a; // Out
        1: valueRegister =  a; // [[Obsolete]]
        2: currentPtrAddrs =a;  // Px
        3: r0 =             a;  // Ax (a regiXter)
        4: r1 =             a;  // Bx (b regiXter)
        5: r2 =             a;  // Cx (c/cycles regiXter)
        6: r3 =             a;  // Dx (d/dataBackup regiXter)
        7: r4 =             a;  // Ah (extra a0 regiXter)
        8: r5 =             a;  // Al (extra a1 regiXter)   
        9: r6 =             a;  // Bh (extra b1 regiXter)   
        10:r7 =             a;  // Bl (extra b2 regiXter)   
        11:sp =             a;  // Ss (Stack regiSter)   
        default: valueRegister = 0;
    endcase

end endtask

task int_launch; input [31:0] abn; begin
    if (!quiet) $write("%d (%8x) ",pc - 1, pc);
    if (!quiet) $display("SOFTWARE   IRQ %0d", abn);
    save_dir();
    vector_base = 4;
    offset = abn * 4;
    irq_vector = {
        memory[vector_base + offset],
        memory[vector_base + offset + 1],
        memory[vector_base + offset + 2],
        memory[vector_base + offset + 3]
    };
    pc = irq_vector;
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

// ================= 64 bit ISA mode in action =================
// el procesador al entrar al modo de 64 bits arregla todas sus
// equivocaciones y hace lo que siempre quiso ser pero, no lo puede
// hacer en el modo de 32 bits por que romperia compatibilidad

task solveReg64bit;
input [3:0] regCode;
output [63:0] regVal;
begin 
    case (regCode)
    2: regVal = xsp;
    3: regVal = x0;
    4: regVal = x1;
    5: regVal = x2;
    6: regVal = x3;
    7: regVal = x4;
    8: regVal = x5;
    9: regVal = x6;
    endcase
end endtask

task set64BitReg;
input [3:0] regCode;
input [63:0] regVal;
begin 
    case (regCode)
    2: xsp  = regVal;
    3: x0   = regVal;
    4: x1   = regVal;
    5: x2   = regVal;
    6: x3   = regVal;
    7: x4   = regVal;
    8: x5   = regVal;
    9: x6   = regVal;
    endcase
end
endtask

function [63:0] readInm64Max; 
input [7:0] bytesLen; 
input [63:0] baseAddr; 
begin
    case (bytesLen)
        1: readInm64Max = memory[baseAddr];
        2: readInm64Max = {
            memory[baseAddr],
            memory[baseAddr + 1]
            };
        4: readInm64Max = {
            memory[baseAddr],
            memory[baseAddr + 1],
            memory[baseAddr + 2],
            memory[baseAddr + 3]
            };
        8: readInm64Max = {
            memory[baseAddr],
            memory[baseAddr + 1],
            memory[baseAddr + 2],
            memory[baseAddr + 3],
            memory[baseAddr + 4],
            memory[baseAddr + 5],
            memory[baseAddr + 6],
            memory[baseAddr + 7]
            };
        default: readInm64Max = 0;
    endcase
end endfunction

task readInm64MaxNonRoot; 
input [7:0] bytesLen; 
input [63:0] baseAddr; 
output [63:0] result;
begin
    if (!checIfMemkBoundles64Exepction(baseAddr,1) && !checIfMemkBoundles64Exepction(baseAddr + bytesLen,1)) begin
        case (bytesLen)
            1: result = memory[baseAddr];
            2: result = {
                memory[baseAddr],
                memory[baseAddr + 1]
                };
            4: result = {
                memory[baseAddr],
                memory[baseAddr + 1],
                memory[baseAddr + 2],
                memory[baseAddr + 3]
                };
            8: result = {
                memory[baseAddr],
                memory[baseAddr + 1],
                memory[baseAddr + 2],
                memory[baseAddr + 3],
                memory[baseAddr + 4],
                memory[baseAddr + 5],
                memory[baseAddr + 6],
                memory[baseAddr + 7]
                };
            default: result = 0;
        endcase
    end
    else begin
        irqJmp64(32'h00000000); // segmentation fault
    end
end endtask

localparam CpuIntDescIInTbl = 0;
localparam CpuLvlSetsIInTbl = 1;
localparam CpuIOMIInTbl     = 2;

localparam IdtDescPartSize  = 16;
localparam LevelPrivSize    = 16;

localparam IdtDescIsaOffset = 0;
localparam IdtDescPrivOffset= 4;
localparam IdtDescFuncOffset= 8;

localparam LvlDescSizeField = 8;
localparam LvlDescNField    = 2;
localparam LvlDescPermsOff  = LvlDescSizeField * 1;
localparam LvlDescSize      = LvlDescSizeField * LvlDescNField;

localparam MemMapDescSize   = 8;
localparam MemMapDescEndOff = MemMapDescSize * 1;
localparam MemMapDescEntry  = MemMapDescSize * 2;

reg  [63:0] i64irqsft     = 64'hFFFFFFFFFFFFFFFF;
reg  [63:0] i64perms      = 64'hFFFFFFFFFFFFFFFF;
reg  [63:0] xpc           = 0;

`define i64intTable     CpuTableEntry(CpuIntDescIInTbl)
`define i64levelTable   CpuTableEntry(CpuLvlSetsIInTbl)
`define i64permTable    CpuTableEntry(CpuIOMIInTbl)

`define i64ihrdptr      (`i64intTable + (irq_addr * IdtDescPartSize))
`define i64isrdptr      (`i64intTable + (i64irqsft * IdtDescPartSize))

`define i64ihisau       readInm64Max(4, `i64ihrdptr + IdtDescIsaOffset)
`define i64ihpriv       readInm64Max(4, `i64ihrdptr + IdtDescPrivOffset)
`define i64ihfunc       readInm64Max(8, `i64ihrdptr + IdtDescFuncOffset)
`define i64ihprivInd    `i64levelTable + (`i64ihpriv * LevelPrivSize)

`define i64isisau       readInm64Max(4, `i64isrdptr + IdtDescIsaOffset)
`define i64ispriv       readInm64Max(4, `i64isrdptr + IdtDescPrivOffset)
`define i64isfunc       readInm64Max(8, `i64isrdptr + IdtDescFuncOffset)
`define i64isprivInd    `i64levelTable + (`i64ispriv * LevelPrivSize)

`define i64iprivmem     readInm64Max(LvlDescSizeField,`i64isprivInd)
`define i64privmema     `i64permTable + (`i64iprivmem * MemMapDescEntry)

`define i64privmemstart readInm64Max(MemMapDescSize, `i64privmema)
`define i64privmemend   readInm64Max(MemMapDescSize, `i64privmema + MemMapDescEndOff)

function [63:0] CpuTableEntry;
input [31:0] index;
begin
    CpuTableEntry = readInm64Max(8, i64CpuTbl + (index * 8));
end
endfunction

task saveThingInStack64;
input [63:0] data;
begin
    xsp = xsp - 8;
    memory[xsp]     = data[63:56];
    memory[xsp + 1] = data[55:48];
    memory[xsp + 2] = data[47:40];
    memory[xsp + 3] = data[39:32];
    memory[xsp + 4] = data[31:24];
    memory[xsp + 5] = data[23:16];
    memory[xsp + 6] = data[15:8];
    memory[xsp + 7] = data[7:0];
end endtask

task saveDir64; begin
    xsp = xsp - 8;
    memory[xsp]     = xpc[63:56];
    memory[xsp + 1] = xpc[55:48];
    memory[xsp + 2] = xpc[47:40];
    memory[xsp + 3] = xpc[39:32];
    memory[xsp + 4] = xpc[31:24];
    memory[xsp + 5] = xpc[23:16];
    memory[xsp + 6] = xpc[15:8];
    memory[xsp + 7] = xpc[7:0];
end endtask

task irqJmp64;
input [31:0] irqId;
begin
    i64a = (
        (i64perms[23:0] << 9) |
        (flags << 1) |
        in64Bit
        );
    saveThingInStack64(i64a);
    saveDir64();
    i64irqsft = irqId;
    i64proMemStart = `i64privmemstart;
    i64proMemEnd   = `i64privmemend;
    i64perms =  readInm64Max(LvlDescSizeField,`i64isprivInd + LvlDescPermsOff);
    xpc      = `i64isfunc;
    pc       = xpc[31:0];
    i64temp  = `i64isisau;
    in64Bit  = i64temp[0];
end
endtask

function checIfMemkBoundles64Exepction;
input [63:0] addr;
input        action; // 0: write, 1:read
begin

    // Bit 0 de perms: se puede escribir en lo permitido
    // Bit 1 de perms: se puede leer en lo permitido
    // Bit 2 de perms: se puede escribir en lo no permitido
    // Bit 3 de perms: se puede leer en lo no permitido

    checIfMemkBoundles64Exepction = 0;

    // verificar si es valida la region de memoria
    if (i64proMemStart > i64proMemEnd) 
        checIfMemkBoundles64Exepction = 1;
    else if (i64proMemEnd < i64proMemStart) 
        checIfMemkBoundles64Exepction = 1;

    // si se hizo la operacion dentro de la descripcion
    else if (addr >= i64proMemStart && addr <= i64proMemEnd) begin
        if (action == 0 && !i64perms[0]) 
            checIfMemkBoundles64Exepction = 1; // no tiene el permiso de escribir en lo permitido
        if (action == 1 && !i64perms[1]) 
            checIfMemkBoundles64Exepction = 1; // no tiene el permiso de leer en lo permitido
    end

    // los permisos de lo no permitido
    else begin
        if (action == 0 && !i64perms[2]) 
            checIfMemkBoundles64Exepction = 1; // no tiene el permiso de escribir en lo permitido
        if (action == 1 && !i64perms[3]) 
            checIfMemkBoundles64Exepction = 1; // no tiene el permiso de leer en lo permitido
    end
end
endfunction

task WriteMem64; 
input [63:0]    addr;
input [7:0]     val;
begin
    if (!checIfMemkBoundles64Exepction(addr, 0)) begin
        if (addr > 63999) begin
            CWFDD = 1;
            dev_wrt_en   = 1;
            dev_wrt_addr = (addr[31:0]) - 64000;
            dev_wrt_val  = val;
        end
        CWFDM = 2;
        mem_wrt_ene   = 1;
        mem_wrt_addre = addr[31:0];
        mem_wrt_vale  = val;
        memory[addr] = val;
    end
    else begin
        irqJmp64(32'h00000000); // segmentation fault
    end
end endtask

task irqRet64;
begin
    xpc = readInm64Max(8, xsp);
    pc = xpc[31:0];
    xsp = xsp + 8;
    i64a = readInm64Max(8, xsp);
    xsp = xsp + 8;

    i64perms = i64a[23:9];
    flags = i64a[8:1];
    in64Bit = i64a[0];
end
endtask

task irqHandler64; 
begin
    if (!quiet) $write("%d (%8x) ",xpc[31:0] - 4, xpc[31:0]);
    if (!quiet) $display("HRD I64 %0d %0d", irq_addr, irq_data);
    paused = 0;
    irq_ack <= 1; 
    irqJmp64(irq_addr + 32'h0F);
end 
endtask

// ============== function for clock ==============
// | This functions keeps on the machine for make |
// | it makes things                              |
// |                                              |
// | #LOOP #NONDEBUG #DEBUG                       |
// ------------------------------------------------
always @(posedge clk) begin
    if (mem_wrt_bool) 
        memory[mem_wrt_addr] <= mem_wrt_val;

    if (mem_rdr_bool) 
        mem_rdr_val <= memory[mem_rdr_addr]; 
    if (CWFDD == 1) begin
        dev_wrt_en <= 0;
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
    // reset signal power on/restart computer
    if (reset) begin        
        general_reset();
        alu_reset();
        CWFDD = 0;
        CWFDM = 0;
    // tick of click
    end else begin
        
        if (mem_wrt_bool) begin
            memory[mem_wrt_addr] <= mem_wrt_val;
        end

        if (mem_rdr_bool) begin 
            mem_rdr_val <= memory[mem_rdr_addr]; 
        end

        // check alu
        alu_check();

        if (irq && !irq_ack) begin
            if (in64Bit) irqHandler64();
            else irq_check();
        end else if (!paused && !aluState) begin
        irq_ack <= 0;

        // fetch instruction
        ir = memory[pc];                           // current instruction

        if (in64Bit) begin
            if (!i64pend) begin
                i64bytes[0] <= memory[xpc];
                i64bytes[1] <= memory[xpc + 1];
                i64bytes[2] <= memory[xpc + 2];
                i64bytes[3] <= memory[xpc + 3];
                xpc <= xpc + 4;
                pc <= xpc[31:0];
                i64pend <= 1;
            end
            else begin
                if (!quiet) $write("%d (%8x) ",xpc[31:0] - 4, xpc[31:0] - 4);
                i64pend <= 0;

                if ((i64bytes[0] & 8'hF0) == 8'h20) begin
                    i64opr = i64bytes[0][3:0];
                    case (i64bytes[1][3:2])
                    0: solveReg64bit(i64bytes[2][3:0], i64a);
                    1: i64a = inms64[i64bytes[2]];
                    2: i64a = i64bytes[2];
                    endcase
                    case (i64bytes[1][1:0])
                    0: solveReg64bit(i64bytes[3][3:0], i64b);
                    1: i64b = inms64[i64bytes[3]];
                    2: i64b = i64bytes[3];
                    endcase
                    case (i64opr)
                        0: i64temp = i64a + i64b;
                        1: i64temp = i64a - i64b;
                        2: i64temp = i64a * i64b;
                        3: i64temp = i64a / i64b;
                    endcase
                    set64BitReg(i64bytes[1][7:4], i64temp);
                    solveReg64bit(i64bytes[1][7:4], i64temp);
                    $display("OPERATION%0d %0d ((%0d)%0d (%0d)%0d) = %0d", i64opr, i64bytes[0][7:4], i64bytes[1][3:2], i64a, i64bytes[1][1:0], i64b, i64temp); 
                end // operations
                else begin case (i64bytes[0]) 
                8'h01: begin
                    if (i64bytes[1] == 8'hFF) begin
                        if (i64bytes[2] == 8'h1) begin
                            selectedinm64 <= i64bytes[3];
                            if (!quiet) $display("INM SLT %0d", i64bytes[3]);
                        end // select inm id
                        else if (i64bytes[2] == 8'h2) begin
                            solveReg64bit(i64bytes[3][3:0],i64CpuTbl);
                            if (!quiet) $display("SETCPUTBL %0d", i64CpuTbl);
                        end // set cpu table
                        else if ((i64bytes[2] & 8'hF0) == 8'h30) begin
                            i64a = flags[i64bytes[2][3:0]];
                            i64opr = i64bytes[3][7:4];
                            case (i64opr)
                                0: solveReg64bit(i64bytes[3][3:0], i64temp);
                                1: i64temp = inms64[i64bytes[3][3:0]];
                            endcase
                            if (!quiet) $display("JMP TO %0d IF FLAG %0d", i64temp, i64bytes[2][3:0]);

                            if (i64a) begin 
                                xpc = i64temp;
                                pc <= xpc[31:0];
                             end
                        end // jmp if a condition is true
                        else if (i64bytes[2] == 8'h03) begin
                            $display("INT %0d", i64bytes[3]);
                            irqJmp64(i64bytes[3]);
                        end // interruption
                        else if (i64bytes[2] == 8'hFF) begin
                            if (i64bytes[3] == 8'h01) begin
                                inms64[selectedinm64] <= 0;
                                if (!quiet) $display("INM RST %0d", selectedinm64);
                            end // reset inm
                            else if ((i64bytes[3] & 8'hF0) == 8'h20) begin
                                solveReg64bit(i64bytes[3][3:0], i64a);

                                flags = 0;
                                if (i64a == 0) flags[0] = 1;
                                if (i64a[63] == 1) flags[1] = 1;
                                if (i64a > 0 && i64a[63] == 0) flags[2] = 1;
                                flags[3] = 1;

                                if (!quiet) $display("CALC %0d NEW FLAGS %0d", i64a, flags);
                            end // calculate thing
                            if (i64bytes[3] == 8'h02) begin
                                irqRet64();
                                if (!quiet) $display("IRET");
                            end // interruption return
                        end // extend ins to pad
                    end // extend ins to pad
                    else if ((i64bytes[1] & 8'hF0) == 8'h10) begin
                        i64inmba = i64bytes[1][3:0];
                        if (!quiet) $write("INM BLD %0d TO %0d [", i64inmba , selectedinm64);

                        inms64[selectedinm64] = (
                            (inms64[selectedinm64] << 8) | i64bytes[2]
                        );
                        if (!quiet) $write("%0d",i64bytes[2]);
                        if (i64inmba == 2) begin
                            inms64[selectedinm64] = (
                                (inms64[selectedinm64] << 8) | i64bytes[3]
                            );
                            if (!quiet) $write(",%0d", i64bytes[3]);
                        end // extend to more
                        if (!quiet) $write("]\n");
                    end // add bytes
                    else if (((i64bytes[1] & 8'hF0) == 8'h40)) begin
                        if (!quiet) $display("INM LDX %0d FROM %0d", i64bytes[2][3:0] , inms64[i64bytes[3]]);
                        set64BitReg(i64bytes[2][3:0], inms64[i64bytes[3]]);
                    end // load to reg
                    else if (((i64bytes[1] & 8'hF0) == 8'h30)) begin
                        i64bysiz = i64bytes[1][3:0];
                        i64opr = i64bytes[2][7:4];
                        case (i64opr)
                            0: solveReg64bit(i64bytes[2][3:0], i64temp);
                            1: i64temp = inms64[i64bytes[2][3:0]];
                        endcase
                        readInm64MaxNonRoot(i64bysiz, i64temp, inms64[i64bytes[3]]);

                        if (!quiet) $display("INM LFM STEPS %0d OF %0d TO %0d (%0d)", i64bysiz , i64temp, i64bytes[3], inms64[i64bytes[3]]);
                    end // load from mem
                end // inms manager
                8'h02: begin
                    if ((i64bytes[1] & 8'hF0) == 8'h10) begin
                        solveReg64bit(i64bytes[1][3:0], i64memre);
                        i64bysiz = i64bytes[2][7:4];
                        i64opr   = i64bytes[2][3:0];
                        case (i64opr)
                            0: solveReg64bit(i64bytes[3][3:0], i64temp);
                            1: i64temp = inms64[i64bytes[3][3:0]];
                        endcase
                        if (!quiet) $display("MEM WRT AT %0d STEPS %0d DATA %0d", i64memre ,i64bysiz, i64temp);
                        for (i = 0; i < i64bysiz; i = i + 1) begin
                            WriteMem64(i64memre + i, (i64temp >> (8 * (i64bysiz - 1 - i))) & 8'hFF);
                        end
                    end // mem write
                end // mem 
                endcase end // other
            end
            
        end
        else begin
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
                // INT = software INTerruption
                8'h09: ex_int();
                // WRX = WRite regiXter
                8'h0A: ex_wrx();
                // DBGAC64
                8'h0B: begin 
                    $display("NULL0      CH64");
                    xpc = pc;
                    in64Bit <= 1; 
                    i64runinbg <= 1;
                end
                // IRET
                8'h0C: begin
                    $display("NULL0      IRET");
                    irqRet64();
                end
            endcase
        end
    end
    end
    $fflush();
end

endmodule
