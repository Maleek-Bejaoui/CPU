module tt_um_top (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire ena,
    input  wire clk,
    input  wire rst_n
);

    wire [15:0] UT_data_out;
    wire [5:0] sig_adr;
    wire carry;
    wire clear_carry;
    wire enable_mem;
    wire load_R1;
    wire s_load_accu;
    wire load_carry;
    wire [2:0] sel_UAL_UT;
    wire [2:0] sel_UAL_UC;
    wire w_mem;

    wire [15:0] ram_data_in, ram_data_out;
    wire ram_enable;

    wire sig_rw;
    wire sig_ram_enable;
    wire [5:0] sig_ram_adr;
    wire [15:0] sig_ram_in;

    wire boot;
    wire [5:0] boot_ram_adr;
    wire [15:0] boot_ram_in, boot_ram_out;
    wire boot_ram_rw;
    wire boot_ram_enable;

    assign uio_out = 8'b00000000;
    assign uio_oe = 8'b00000000;
    assign uo_out[7:1] = 7'b0000000;
    /* verilator lint_off PINCONNECTEMPTY */

    Control_Unit UC (
        .clk(clk),
        .ce(ena),
        .rst(~rst_n),
        .carry(carry),
        .boot(boot),
        .data_in(ram_data_out),
        .adr(sig_adr),
        .clear_carry(clear_carry),
        .enable_mem(enable_mem),
        .load_R1(load_R1),
        .load_accu(s_load_accu),
        .load_carry(load_carry),
        .sel_UAL(sel_UAL_UC),
        .w_mem(w_mem)
    );
    /* verilator lint_on PINCONNECTEMPTY */

    assign sel_UAL_UT = sel_UAL_UC;
    /* verilator lint_off PINCONNECTEMPTY */

    UT UT1 (
        .data_in(ram_data_out),
        .clk(clk),
        .ce(ena),
        .rst(~rst_n),
        .load_R1(load_R1),
        .load_ACCU(s_load_accu),  
        .load_carry(load_carry),
        .init_carry(clear_carry),
        .sel_UAL(sel_UAL_UT),
        .data_out(UT_data_out),
        .carry(carry)
    );
    /* verilator lint_on PINCONNECTEMPTY */

    /* verilator lint_off PINCONNECTEMPTY */
    boot_loader BL (
        .rst(~rst_n),
        .clk(clk),
        .ce(ena),
        .rx(uio_in[0]),
        .tx(uo_out[0]),
        .boot(boot),
        .scan_memory(ui_in[0]),
        .ram_out(ram_data_out),
        .ram_rw(boot_ram_rw),
        .ram_enable(boot_ram_enable),
        .ram_adr(boot_ram_adr),
        .ram_in(boot_ram_in)
       
    );
    /* verilator lint_on PINCONNECTEMPTY */

    assign sig_rw = (boot) ? boot_ram_rw : w_mem;
    assign sig_ram_enable = (boot) ? boot_ram_enable : enable_mem;
    assign sig_ram_adr = (boot) ? boot_ram_adr : sig_adr;
    assign sig_ram_in = (boot) ? boot_ram_in : UT_data_out;

    RAM_SP_64_8 UM (
        .add(sig_ram_adr),
        .data_in(sig_ram_in),
        .r_w(sig_rw),
        .enable(sig_ram_enable),
        .clk(clk),
        .ce(ena),
        .data_out(ram_data_out)
    );

endmodule
