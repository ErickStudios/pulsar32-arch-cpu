module tb;

// ================= MACHINE REGISTERS =================
reg         clk = 0;
reg         reset = 1;
always #1   clk = ~clk;
wire        irq;
wire [31:0] irq_addr;
wire [7:0]  irq_data;
wire        irq1, irq2, irq3, irq4, irq5;
wire [31:0] addr1, addr2, addr3, addr4, addr5;
wire [7:0]  data1, data2, data3, data4, data5;
wire        irq_ack;
wire        irq_ack1, irq_ack2, irq_ack3, irq_ack4, irq_ack5;
reg  [7:0]  selectec_dev;
reg  [7:0]  firmware_status = 0;
reg  [7:0]  modifier_01 = 0;
reg  [7:0]  ohman = 0;

// ================= CASSETE READER =================
reg         anull_all_fs0 = 0;
reg  [15:0] fs0_sector_to_read = 0;
reg  [15:0] fs0_byte_to_read = 0;
reg  [3:0]  fs0_read_stage = 0;
reg  [1:0]  fs0_status_lh = 0;
reg  [15:0] fs0_byte_exactly = 0;

// ================= SIMULATED VIDEO ADAPTER =================
reg  [7:0]  pix_x;
reg  [7:0]  pix_y;

wire        mem_wrt_ene;
wire [31:0] mem_wrt_addre;
wire [7:0]  mem_wrt_vale;

// ================= NATIVE MMIO =================
wire        dev_wrt_en;
wire [31:0] dev_wrt_addr;
wire [7:0]  dev_wrt_val;

// ================= MEMORY EXTERNAL BUS =================
reg  [7:0]  mwv;
wire [7:0]  mrv;
wire [31:0] mwa;
wire [31:0] mra;
reg         mwb;
reg         mrb;
reg         mwx;

assign mwa =
    modifier_01 == 0 ?  32'h7FFF :
    modifier_01 == 1 ?  4095 :
    modifier_01 == 2 ?  4096 :
    modifier_01 == 3 ?  32'h2FFF :
    modifier_01 == 4 ?  32'h4FFF + fs0_byte_to_read :
                        32'h00000000;

assign mra = mwa;

// ================= CASSETE DISK PROPERTYS =================
reg  [3:0]  cassete_inserted = 1;
reg  [7:0]  disk0_cassete [0:64000];

// ================= CPU ASIGNATION IRQS =================
reg         dev1_enable = 0;
reg         dev2_enable = 0;
reg         dev3_enable = 0;
reg         dev4_enable = 0;
reg         cassete_enable = 0;
reg  [7:0]  dev1_data = 0;
reg  [7:0]  dev2_data = 0;
reg  [7:0]  dev3_data = 0;
reg  [7:0]  dev4_data = 0;
reg  [7:0]  cassete_data = 0;

// ================= SERIAL COM1 PORT =================
reg         com1_rdnxtch = 0;
reg  [7:0]  com1_mode = 0;
reg  [7:0]  com1_next_cmd = 0;
reg         com1_next_char_is_cmd = 0;
reg  [1:0]  com1_cmd_mrstage = 0;

// ================= CPU ASIGNATION IRQS =================
assign      irq =   irq1 |
                    irq2 |
                    irq3 |
                    irq4 |
                    irq5;
assign      irq_addr =
                    irq1 ? addr1 :
                    irq2 ? addr2 :
                    irq3 ? addr3 :
                    irq4 ? addr4 :
                    irq5 ? addr5 :
                    32'b0;
assign      irq_data =
                    irq1 ? data1 :
                    irq2 ? data2 :
                    irq3 ? data3 :
                    irq4 ? data4 :
                    irq5 ? data5 :
                    8'b0;
assign irq_ack1 = irq_ack & irq1;
assign irq_ack2 = irq_ack & irq2;
assign irq_ack3 = irq_ack & irq3;
assign irq_ack4 = irq_ack & irq4;
assign irq_ack5 = irq_ack & irq5;

// ================= CHIP BUS =================

cpu uut(
    .clk            (clk),
    .reset          (reset),

    .irq            (irq),
    .irq_addr       (irq_addr),
    .irq_data       (irq_data),
    .irq_ack        (irq_ack),

    .mem_wrt_val    (mwv),
    .mem_wrt_addr   (mwa),
    .mem_wrt_bool   (mwb),

    .mem_rdr_val    (mrv),
    .mem_rdr_addr   (mra),
    .mem_rdr_bool   (mrb),

    .dev_wrt_en     (dev_wrt_en),
    .dev_wrt_addr   (dev_wrt_addr),
    .dev_wrt_val    (dev_wrt_val),
    
    .mem_wrt_ene    (mem_wrt_ene),
    .mem_wrt_addre  (mem_wrt_addre),
    .mem_wrt_vale   (mem_wrt_vale)
);

// ================= DEVICES BUS =================

device #(.BASE_ADDR(32'h0)) alphaButton(
    .clk            (clk),
    .reset          (reset),
    .enable         (dev1_enable),
    .data_in        (dev1_data),

    .irq            (irq1),
    .irq_addr       (addr1),
    .irq_data       (data1),
    .irq_ack        (irq_ack1),

    .wrt_en         (dev_wrt_en),
    .wrt_addr       (dev_wrt_addr),
    .wrt_val        (dev_wrt_val)
);

device #(.BASE_ADDR(32'h1)) betaButton(
    .clk            (clk),
    .reset          (reset),
    .enable         (dev2_enable),
    .data_in        (dev2_data),

    .irq            (irq2),
    .irq_addr       (addr2),
    .irq_data       (data2),
    .irq_ack        (irq_ack2),

    .wrt_en         (dev_wrt_en),
    .wrt_addr       (dev_wrt_addr),
    .wrt_val        (dev_wrt_val)
);

device #(.BASE_ADDR(32'h2)) upButton(
    .clk            (clk),
    .reset          (reset),
    .enable         (dev3_enable),
    .data_in        (dev3_data),

    .irq            (irq3),
    .irq_addr       (addr3),
    .irq_data       (data3),
    .irq_ack        (irq_ack3),

    .wrt_en         (dev_wrt_en),
    .wrt_addr       (dev_wrt_addr),
    .wrt_val        (dev_wrt_val)
);

device #(.BASE_ADDR(32'h3)) downButton(
    .clk            (clk),
    .reset          (reset),
    .enable         (dev4_enable),
    .data_in        (dev4_data),

    .irq            (irq4),
    .irq_addr       (addr4),
    .irq_data       (data4),
    .irq_ack        (irq_ack4),

    .wrt_en         (dev_wrt_en),
    .wrt_addr       (dev_wrt_addr),
    .wrt_val        (dev_wrt_val)
);

device #(.BASE_ADDR(32'h4)) cassete(
    .clk            (clk),
    .reset          (reset),
    .enable         (cassete_enable),
    .data_in        (cassete_data),

    .irq            (irq5),
    .irq_addr       (addr5),
    .irq_data       (data5),
    .irq_ack        (irq_ack5),
    
    .wrt_en         (dev_wrt_en),
    .wrt_addr       (dev_wrt_addr),
    .wrt_val        (dev_wrt_val)
);

always @(posedge clk) begin

    if (mem_wrt_ene && mem_wrt_addre == 32'h7FFF) begin
        firmware_status = mem_wrt_vale;
    end

    if (dev_wrt_en && dev_wrt_addr == 5) begin
        if (!uut.quiet) $display("%d (%8x) HARDWARE   CM1 PUTPIX %0d %0d %0d",uut.pc - 1, uut.pc, pix_x, pix_y, dev_wrt_val);
    end
    else if (dev_wrt_en && dev_wrt_addr == 6) pix_x = dev_wrt_val;
    else if (dev_wrt_en && dev_wrt_addr == 7) pix_y = dev_wrt_val;
    else if (dev_wrt_en && dev_wrt_addr == 8) begin
        if (com1_next_char_is_cmd && com1_next_cmd == 8'h01) begin
            com1_mode = dev_wrt_val;
            com1_next_char_is_cmd = 0;
        end
        else begin     
            if (com1_mode == 1) begin 
                if (!uut.quiet) $display("%d (%8x) HARDWARE   CM1 PUTCHR %0d",uut.pc - 1, uut.pc, dev_wrt_val);
            end
        end
    end
    else if (dev_wrt_en && dev_wrt_addr == 10) begin
      if (fs0_status_lh == 0) begin
        fs0_status_lh <= 1;
        fs0_sector_to_read <= dev_wrt_val;
      end
      else if (fs0_status_lh == 1) begin
        fs0_status_lh <= 0;
        fs0_sector_to_read = (fs0_sector_to_read << 8) | dev_wrt_val;
        anull_all_fs0 <= 1;
        fs0_byte_to_read <= 0;
        if (!uut.quiet) $display("%d (%8x) HARDWARE   FS0 READBF %0d",uut.pc - 1, uut.pc, fs0_sector_to_read);
      end
    end
    else if (anull_all_fs0) begin
        if (fs0_byte_to_read >= 511) begin
            anull_all_fs0 <= 0;
            cassete_enable <= 1;
            fs0_read_stage <= 1;
        end
        else if (fs0_read_stage == 0) begin
            fs0_byte_exactly = (fs0_sector_to_read * 512) + fs0_byte_to_read;
            modifier_01 <= 4;
            mwb <= 1;
            mwv <= disk0_cassete[fs0_byte_exactly];
            fs0_read_stage <= 1;
        end
        else if (fs0_read_stage == 1) begin
            fs0_read_stage <= 2;
        end
        else if (fs0_read_stage == 2) begin
            fs0_read_stage <= 0;
            fs0_byte_to_read <= fs0_byte_to_read + 1;
        end
    end
    else if (fs0_read_stage == 1) begin
        fs0_read_stage <= 2;
    end
    else if (fs0_read_stage == 2) begin
        fs0_read_stage <= 0;
        cassete_enable <= 0;
    end
    else if (cassete_inserted == 1 && firmware_status == 1) begin
        cassete_inserted = 2;
        // se inserto un cassete o hay uno y se le pide al firmware que lo maneje
        modifier_01 = 3;
        mwv <= 24;
        mwb <= 1;
        cassete_enable <= 1;
    end
    else if (cassete_inserted == 2) begin
        cassete_inserted = 3;
    end
    else if (cassete_inserted == 3) begin
        cassete_enable <= 0;
        cassete_inserted = 0;
        ohman = 2;
        mwb <= 0;
    end
    else if (dev_wrt_en && dev_wrt_addr == 9) begin
        com1_cmd_mrstage <= 0;
        ohman = ohman + 1;
        com1_next_cmd = dev_wrt_val;
        modifier_01 = 2;
        com1_next_char_is_cmd = 1;
    end

    else begin
        ohman = ohman + 1;
    end

    // reseteo del puerto serial
    if (reset) begin
        com1_next_cmd = 8'hFF;
        com1_next_char_is_cmd = 0;
        com1_mode = 8'hFF;
        com1_rdnxtch = 0;
        cassete_inserted = 1;
    end
end

initial begin
    $display("pulsar5024XM_x32 chip debug");
    $readmemh("program.hex", uut.memory);
    $readmemh("cassete.hex", disk0_cassete);

    //uut.quiet = 1;

    #10 reset = 0;

    /*#20 cassete_data = 0;
    #1 cassete_enable = 1;
    #2 cassete_enable = 0;*/

    /*#20 dev1_data = 8'd23;
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
    #2  dev4_enable = 0;*/

    #1000000 $finish;
end

endmodule