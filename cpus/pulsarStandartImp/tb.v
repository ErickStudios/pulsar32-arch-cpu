module tb;

// ================= MACHINE REGISTERS =================
reg         clk = 0;
reg         reset = 1;
always #1   clk = ~clk;
wire        irq;
wire [31:0] irq_addr;
wire [7:0]  irq_data;
wire        irq_ack;
reg  [7:0]  selectec_dev;

// ================= CHIP BUS =================

cpu uut(
    .clk            (clk),
    .reset          (reset),
    .irq            (irq),
    .irq_addr       (irq_addr),
    .irq_data       (irq_data),
    .irq_ack        (irq_ack)
);

initial begin
    $display("pulsar5024XM_x32 chip debug");
    $readmemh("program.hex", uut.memory);

    #10 reset = 0;

    #100 $finish;
end

endmodule