// ================= PULSAR5024XM X32 =================
// la primera placa base portable SBC con la arquitectura
// pulsar de 32 bits como arquitectura principal del core
// 
// con solo 1 nucleo de procesador, 4 botones de mando
// integrados en la SBC y un puerto externo para el teclado

// configurar maquina
`default_nettype none
`timescale 1ns/1ns
`define simSimi 1

// ================= MACHINE START =================
`ifdef simSimi
module tb;
`else
module top(
    // las cosas del cpu
    input wire          clk,
    input wire          reset,
    // teclado externo conectable
    input wire [7:0]    hw_key_data,
    input wire          hw_key_strobe,
    // botones del mando fundamental integrado
    input wire          dev1_enable,
    input wire          dev2_enable,
    input wire          dev3_enable,
    input wire          dev4_enable
);
`endif

// ================= MACHINE REGISTERS =================
`ifdef simSimi
reg         clk = 0;
reg         reset = 1;
always #1   clk = ~clk;
`endif
reg         ready = 1;
reg         flag_first_time = 0;
reg [7:0]   flash_space [0:96000];
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
reg         debug_show_events = 0;
reg         last_dev_wrt_en;

// ================= INITIAL RAM LOADER =================
reg  [31:0] iflash_ptr = 0;
reg        boot_loading = 1;
reg [2:0]  boot_state = 0;
reg [7:0]  bar_progress_x = 0;

// ================= CASSETE READER =================
reg         anull_all_fs0 = 0;
reg  [15:0] fs0_sector_to_read;
reg  [15:0] fs0_mmfs_to_read = 0;
reg  [15:0] fs0_byte_to_read = 0;
reg  [3:0]  fs0_read_stage = 0;
reg  [1:0]  fs0_status_lh = 0;
reg  [31:0] fs0_byte_exactly = 0;
reg  [1:0]  fs0_count_quedread = 0;

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
    boot_loading ? iflash_ptr :
    modifier_01 == 0 ?  32'h7FFF :
    modifier_01 == 1 ?  4095 :
    modifier_01 == 2 ?  4096 :
    modifier_01 == 3 ?  32'h2FFF :
    modifier_01 == 4 ?  32'h4FFF + fs0_byte_to_read :
                        32'h00000000;

assign mra = mwa;

// ================= CASSETE DISK PROPERTYS =================
reg  [3:0]  cassete_inserted = 1;
reg  [7:0]  disk0_cassete [0:786432];

// ================= CPU ASIGNATION IRQS =================
`ifdef simSimi
reg         dev1_enable = 0;
reg         dev2_enable = 0;
reg         dev3_enable = 0;
reg         dev4_enable = 0;
`endif
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
// el procesador uninucleo de la pc que procesa
// las instrucciones y otras cosas en la SBC
// que es el cerebro

cpu uut(
    // principales
    .clk            (clk),              // relog
    .reset          (reset | boot_loading), // boton de reset
    // interrupciones externas
    .irq            (irq),              // booleano
    .irq_addr       (irq_addr),         // direccion
    .irq_data       (irq_data),         // datos
    .irq_ack        (irq_ack),          // ack
    // escritura de memoria
    .mem_wrt_val    (mwv),              // valor
    .mem_wrt_addr   (mwa),              // direccion
    .mem_wrt_bool   (mwb),              // booleano
    // lectura de memoria de memoria
    .mem_rdr_val    (mrv),              // valor
    .mem_rdr_addr   (mra),              // direccion
    .mem_rdr_bool   (mrb),              // booleano
    // escritura de memoria pero solo los MMIO notificados
    .dev_wrt_en     (dev_wrt_en),       // booleano
    .dev_wrt_addr   (dev_wrt_addr),     // direccion
    .dev_wrt_val    (dev_wrt_val),      // valor
    // escritura de memoria en general incluidos MMIO
    .mem_wrt_ene    (mem_wrt_ene),      // booleano
    .mem_wrt_addre  (mem_wrt_addre),    // direccion
    .mem_wrt_vale   (mem_wrt_vale)      // valor
);

// ================= DEVICES BUS =================
// dispositivos integrados y su sistema de interrupciones
// que estan conectados al cpu principal

device #(.BASE_ADDR(32'h0)) alphaButton
    (.clk(clk),.reset(reset),.enable(dev1_enable),.data_in(dev1_data),.irq(irq1),.irq_addr(addr1),.irq_data(data1),.irq_ack(irq_ack1),.wrt_en(dev_wrt_en),.wrt_addr(dev_wrt_addr),.wrt_val(dev_wrt_val));
device #(.BASE_ADDR(32'h1)) betaButton
    (.clk(clk),.reset(reset),.enable(dev2_enable),.data_in(dev2_data),.irq(irq2),.irq_addr(addr2),.irq_data(data2),.irq_ack(irq_ack2),.wrt_en(dev_wrt_en),.wrt_addr(dev_wrt_addr),.wrt_val(dev_wrt_val));
device #(.BASE_ADDR(32'h2)) upButton
    (.clk(clk),.reset(reset),.enable(dev3_enable),.data_in(dev3_data),.irq(irq3),.irq_addr(addr3),.irq_data(data3),.irq_ack(irq_ack3),.wrt_en(dev_wrt_en),.wrt_addr(dev_wrt_addr),.wrt_val(dev_wrt_val));
device #(.BASE_ADDR(32'h3)) downButton
    (.clk(clk),.reset(reset),.enable(dev4_enable),.data_in(dev4_data),.irq(irq4),.irq_addr(addr4),.irq_data(data4),.irq_ack(irq_ack4),.wrt_en(dev_wrt_en),.wrt_addr(dev_wrt_addr),.wrt_val(dev_wrt_val));
device #(.BASE_ADDR(32'h4)) cassete
    (.clk(clk),.reset(reset),.enable(cassete_enable),.data_in(cassete_data),.irq(irq5),.irq_addr(addr5),.irq_data(data5),.irq_ack(irq_ack5),.wrt_en(dev_wrt_en),.wrt_addr(dev_wrt_addr),.wrt_val(dev_wrt_val));

always @(posedge clk) begin

    if (reset) begin
        ready <= 1;
        flag_first_time <= 0;
        fs0_status_lh <= 0;
        boot_loading <= 1;     // Al resetear, volvemos a activar la carga
        boot_state <= 0;
        iflash_ptr <= 0;
        bar_progress_x <= 10;  // La barra inicia en la columna X = 10
        com1_next_cmd = 8'hFF;
        com1_next_char_is_cmd = 0;
        com1_mode = 8'hFF;
        com1_rdnxtch = 0;
        cassete_inserted = 1;
    end
    else if (ready == 1 && !flag_first_time) begin
        flag_first_time <= 1;
    end
    else if (boot_loading) begin
        case (boot_state)
            
            0: begin
                mwb <= 1; 
                mwv <= flash_space[iflash_ptr];
                modifier_01 <= 1;                
                boot_state <= 1;
            end

            1: begin
                boot_state <= 2;
            end
            2: begin
                mwb <= 0;

                iflash_ptr <= iflash_ptr + 1;
                if (iflash_ptr > 95999) begin                    
                    boot_loading <= 0;
                end

                boot_state <= 0;
            end

            3: begin

                pix_y <= 8'd220;
                boot_state <= 4;
            end

            4: begin
                if (!uut.quiet | debug_show_events) 
                    $display("BOOTLOADER: Dibujando barra de progreso en X:%0d Y:220", iflash_ptr);
                
                bar_progress_x <= bar_progress_x + 1;
                iflash_ptr <= iflash_ptr + 1;
                boot_state <= 1;
            end

        endcase
    end
    else begin
    last_dev_wrt_en <= dev_wrt_en;

    // proceso principal de paralelo de la SBC
    // para procesar los dispositivos

    if (mem_wrt_ene && mem_wrt_addre == 32'h7FFF)
        firmware_status = mem_wrt_vale; // estado de la pc

    // MMIO de el COM1, la consola serial y similares
    // que se encarga de depurar en simulacion solamente pero no se necesita en runtime

    if ((dev_wrt_en && dev_wrt_addr == 5) && (!uut.quiet | debug_show_events))
        $display("%d (%8x) HARDWARE   CM1 PUTPIX %0d %0d %0d",uut.pc - 1, uut.pc, pix_x, pix_y, dev_wrt_val);
    else if (dev_wrt_en && dev_wrt_addr == 9) begin
        com1_cmd_mrstage <= 0;
        ohman = ohman + 1;
        com1_next_cmd = dev_wrt_val;
        modifier_01 = 2;
        com1_next_char_is_cmd = 1;
    end

    // display y dispositivos MMIO de la pantalla principal que se tiene que conectar por
    // separado

    else if (dev_wrt_en && dev_wrt_addr == 6) 
        pix_x = dev_wrt_val; // pixel en x
    else if (dev_wrt_en && dev_wrt_addr == 7) 
        pix_y = dev_wrt_val; // pixel en y
    else if (dev_wrt_en && dev_wrt_addr == 8) begin
        if (com1_next_char_is_cmd && com1_next_cmd == 8'h01) begin
            com1_mode = dev_wrt_val;
            com1_next_char_is_cmd = 0;
        end
        else begin     
            if (com1_mode == 1) begin 
                if (!uut.quiet | debug_show_events) $display("%d (%8x) HARDWARE   CM1 PUTCHR %0d",uut.pc - 1, uut.pc, dev_wrt_val);
            end
        end
    end

    // sistema de disquetes y los mounted/maped FileSystems (mmfs)
    // administrandolos, cargando sectores de ellos, seleccionandolos,
    // etc

    else if (dev_wrt_en && dev_wrt_addr == 10) begin
      if (fs0_status_lh == 0) begin
        fs0_status_lh <= 1;
        fs0_sector_to_read = dev_wrt_val;
      end
      else if (fs0_status_lh == 1) begin
        fs0_status_lh <= 0;
        fs0_sector_to_read = (fs0_sector_to_read << 8) | dev_wrt_val;
        fs0_read_stage <= 0;
        fs0_byte_to_read <= 0;
        fs0_count_quedread <= 2;
        if (!uut.quiet | debug_show_events) $display("%d (%8x) HARDWARE   FS0 READBF %0d:%0d",uut.pc, uut.pc, fs0_mmfs_to_read, fs0_sector_to_read);
      end
    end
    else if (dev_wrt_en && dev_wrt_addr == 11) begin
      if (fs0_status_lh == 0) begin
        fs0_status_lh <= 1;
        fs0_mmfs_to_read = dev_wrt_val;
      end
      else if (fs0_status_lh == 1) begin
        fs0_status_lh <= 0;
        fs0_mmfs_to_read = (fs0_mmfs_to_read << 8) | dev_wrt_val;
      end
    end
    else if (fs0_count_quedread != 0) begin
      if (fs0_count_quedread == 1) begin
        anull_all_fs0 <= 1;
      end
      fs0_count_quedread = fs0_count_quedread - 1;
    end
    else if (anull_all_fs0) begin
        if (fs0_byte_to_read >= 511) begin
            anull_all_fs0 <= 0;
            cassete_enable <= 1;
            fs0_read_stage <= 1;
        end
        else if (fs0_read_stage == 0) begin
            fs0_byte_exactly = (((fs0_mmfs_to_read * 512) + fs0_sector_to_read) * 512) + fs0_byte_to_read;
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

    else begin
        ohman = ohman + 1;
    end

    end
end

initial begin
    // load all the programs and ROMs
    $display("pulsar5024XM_x32 chip debug");
    $readmemh("program.hex", flash_space);
    $readmemh("mmbootfs.hex", disk0_cassete, 0);
    $readmemh("mmfs1.hex", disk0_cassete, 262144);
    $readmemh("mmfs2.hex", disk0_cassete, 524120);

    // config the cpu
    `ifdef simSimi
    uut.quiet = 1;
    debug_show_events = 1;
    #10 reset = 0;
    `endif

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

    #200000000 $finish;

end
`ifdef simSimi
endmodule
`else
endmodule
`endif