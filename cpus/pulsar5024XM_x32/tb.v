module tb;

// ================= MACHINE REGISTERS =================
reg         clk = 0;
reg         reset = 1;
always #1   clk = ~clk;
wire        irq;
wire [31:0] irq_addr;
wire [7:0]  irq_data;
wire        irq1, irq2, irq3, irq4;
wire [31:0] addr1, addr2, addr3, addr4;
wire [7:0]  data1, data2, data3, data4;
wire        irq_ack;
wire        irq_ack1, irq_ack2, irq_ack3, irq_ack4;
reg  [7:0]  selectec_dev;

// ================= CPU ASIGNATION IRQS =================
reg         dev1_enable = 0;
reg         dev2_enable = 0;
reg         dev3_enable = 0;
reg         dev4_enable = 0;
reg  [7:0]  dev1_data = 0;
reg  [7:0]  dev2_data = 0;
reg  [7:0]  dev3_data = 0;
reg  [7:0]  dev4_data = 0;

// ================= SERIAL COM1 PORT =================
reg         com1_rdnxtch = 0;

// ================= CPU ASIGNATION IRQS =================
assign      irq =   irq1 |
                    irq2 |
                    irq3 |
                    irq4;
assign      irq_addr =  (selectec_dev == 1) ? addr1 :
                        (selectec_dev == 2) ? addr2 : 
                        (selectec_dev == 3) ? addr3 : 
                        (selectec_dev == 4) ? addr4 : 
                        32'b0;
assign      irq_data = (selectec_dev == 1) ? data1 :
                       (selectec_dev == 2) ? data2 : 
                       (selectec_dev == 3) ? data3 : 
                       (selectec_dev == 4) ? data4 : 
                       8'b0;
assign      irq_ack1 = irq_ack & (selectec_dev == 1);
assign      irq_ack2 = irq_ack & (selectec_dev == 2);
assign      irq_ack3 = irq_ack & (selectec_dev == 3);
assign      irq_ack4 = irq_ack & (selectec_dev == 4);

// ================= CHIP BUS =================

cpu uut(
    .clk            (clk),
    .reset          (reset),
    .irq            (irq),
    .irq_addr       (irq_addr),
    .irq_data       (irq_data),
    .irq_ack        (irq_ack)
);

// ================= DEVICES BUS =================

device #(.BASE_ADDR(32'h0)) alphaButton(
    .clk            (clk),
    .enable         (dev1_enable),
    .data_in        (dev1_data),
    .irq            (irq1),
    .irq_addr       (addr1),
    .irq_data       (data1),
    .irq_ack        (irq_ack1)
);

device #(.BASE_ADDR(32'h1)) betaButton(
    .clk            (clk),
    .enable         (dev2_enable),
    .data_in        (dev2_data),
    .irq            (irq2),
    .irq_addr       (addr2),
    .irq_data       (data2),
    .irq_ack        (irq_ack2)
);

device #(.BASE_ADDR(32'h2)) upButton(
    .clk            (clk),
    .enable         (dev3_enable),
    .data_in        (dev3_data),
    .irq            (irq3),
    .irq_addr       (addr3),
    .irq_data       (data3),
    .irq_ack        (irq_ack3)
);

device #(.BASE_ADDR(32'h3)) downButton(
    .clk            (clk),
    .enable         (dev4_enable),
    .data_in        (dev4_data),
    .irq            (irq4),
    .irq_addr       (addr4),
    .irq_data       (data4),
    .irq_ack        (irq_ack4)
);

always @(posedge clk) begin
    if (uut.cpg.memory[4095] == 0) begin 
        com1_rdnxtch <= 1;
    end
    else if (uut.cpg.memory[4095] != 0 && com1_rdnxtch) begin
        com1_rdnxtch <= 0;
        $write("%c", uut.cpg.memory[4095]);
        uut.cpg.memory[4095] <= 0;
    end
    if (irq1) 
        selectec_dev <= 1;
    else if (irq2) 
        selectec_dev <= 2;
    else if (irq3) 
        selectec_dev <= 3;
    else if (irq4) 
        selectec_dev <= 4;
    else 
        selectec_dev <= 0;
end

initial begin
    $display("pulsar5024XM_x32 chip debug");
    $readmemh("program.hex", uut.cpg.memory);
    uut.quiet = 1;
    //$dumpfile("wave.vcd");
    //$dumpvars(0, tb);

    #10 reset = 0;
    /*
    #20 dev1_data = 8'd23;
    #1  dev1_enable = 1;
    #2  dev1_enable = 0;

    #30 dev2_data = 8'd46;
    #1  dev2_enable = 1;
    #2  dev2_enable = 0;

    #40 dev3_data = 8'd46;
    #1  dev3_enable = 1;
    #2  dev3_enable = 0;

    #50 dev4_data = 8'd46;
    #1  dev4_enable = 1;
    #2  dev4_enable = 0;
*/
    #100 $finish;
end

endmodule