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
            default: result = 0;
        endcase
    end
end

endmodule