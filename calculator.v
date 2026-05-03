module calculator;

reg clk = 0;
reg reset = 1;

always #1 clk = ~clk;

integer i;

cpu uut(
    .clk(clk),
    .reset(reset)
);

initial begin
    
    $readmemh("program.hex", uut.memory);
    $display("pulsar5024XM_x32 chip debug");

    #10 reset = 0;
end

endmodule