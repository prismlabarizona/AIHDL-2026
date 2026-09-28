/*
 * TinyTapeout top-level harness for the NeCRL AES-128 TinyQV peripheral.
 *
 * Adapted from the TinyTapeout TinyQV peripheral harness template
 * (Copyright (c) 2025 Michael Bell, Apache-2.0). The module is named to match
 * info.yaml `top_module` so LibreLane's DESIGN_NAME resolves. It presents the fixed
 * TinyTapeout pinout and bridges it, over the SPI register interface, to the AES
 * peripheral's TinyQV bus (address/data_in/data_out/data_read_n/data_write_n/
 * data_ready/user_interrupt).
 */

`default_nettype none

module tt_um_necrl_aes128 (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when powered
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // TinyQV register bus (driven by the SPI register interface below).
  wire [5:0]  address;
  wire [31:0] data_in;
  wire [31:0] data_out;
  wire [1:0]  data_write_n;
  wire [1:0]  data_read_n;
  wire        data_ready;
  wire        user_interrupt;

  // Peripherals get synchronized ui_in.
  reg [7:0] ui_in_sync;
  synchronizer #(.STAGES(2), .WIDTH(8)) synchronizer_ui_in_inst (.clk(clk), .data_in(ui_in), .data_out(ui_in_sync));

  // Register reset as in TinyQV.
  /* verilator lint_off SYNCASYNCNET */
  reg rst_reg_n;
  /* verilator lint_on SYNCASYNCNET */
  always @(negedge clk) rst_reg_n <= rst_n;

  // The AES-128 peripheral under test.
  tqvp_necrl_aes128 user_peripheral (
    .clk(clk),
    .rst_n(rst_reg_n),
    .ui_in(ui_in_sync),
    .uo_out(uo_out),
    .address(address),
    .data_in(data_in),
    .data_write_n(data_write_n),
    .data_read_n(data_read_n),
    .data_out(data_out),
    .data_ready(data_ready),
    .user_interrupt(user_interrupt)
  );

  // SPI register interface (shuttle test access), bridged to the TinyQV bus
  // exactly as in the upstream TinyQV peripheral harness. NOTE: the previous
  // revision paired an 8-bit-frame spi_reg with this 32-bit wrapper - its
  // R/W flag was decoded from a bit the 8-bit command phase never shifted
  // in, so NO WRITE could ever reach the AES core (key/plaintext/start all
  // unreachable: dead silicon). This uses the full 32-bit txn_width-based
  // spi_reg (Caio Alonso da Costa / Michael Bell, Apache-2.0).
  wire        addr_valid;
  wire        data_valid;
  wire        data_rw;
  wire [1:0]  txn_n;
  reg  [31:0] data_out_masked;

  // SPI interface pins.
  wire spi_cs_n  = uio_in[4];
  wire spi_clk   = uio_in[5];
  wire spi_mosi  = uio_in[6];
  wire spi_miso;

  wire spi_cs_n_sync, spi_clk_sync, spi_mosi_sync;
  synchronizer #(.STAGES(2), .WIDTH(1)) sync_spi_cs_n (.clk(clk), .data_in(spi_cs_n), .data_out(spi_cs_n_sync));
  synchronizer #(.STAGES(2), .WIDTH(1)) sync_spi_clk  (.clk(clk), .data_in(spi_clk),  .data_out(spi_clk_sync));
  synchronizer #(.STAGES(2), .WIDTH(1)) sync_spi_mosi (.clk(clk), .data_in(spi_mosi), .data_out(spi_mosi_sync));

  spi_reg #(.ADDR_W(6), .REG_W(32)) i_spi_reg (
    .clk(clk),
    .rstb(rst_reg_n),
    .ena(1'b1),
    .spi_mosi(spi_mosi_sync),
    .spi_miso(spi_miso),
    .spi_clk(spi_clk_sync),
    .spi_cs_n(spi_cs_n_sync),
    .reg_addr(address),
    .reg_data_i(data_out_masked),  // peripheral read data -> back to SPI master
    .reg_data_o(data_in),          // SPI master write data -> peripheral
    .reg_addr_v(addr_valid),
    .reg_data_i_dv(data_ready),
    .reg_data_o_dv(data_valid),
    .reg_rw(data_rw),
    .txn_width(txn_n)
  );

  reg [1:0] data_write_n_r, data_read_n_r;
  assign data_write_n = data_write_n_r;
  assign data_read_n  = data_read_n_r;

  always @(*) begin
      data_write_n_r = 2'b11;
      data_read_n_r  = 2'b11;

      if (data_valid && data_rw) begin
        data_write_n_r = txn_n;
      end
      if (addr_valid && !data_rw) begin
        data_read_n_r = txn_n;
      end

      data_out_masked = data_out;
      if (txn_n[1] == 1'b0) data_out_masked[31:16] = 0;
      if (txn_n == 2'b00) data_out_masked[15:8] = 0;
  end

  // Outputs.
  assign uio_out[0] = user_interrupt;
  assign uio_out[1] = data_ready;
  assign uio_out[3] = spi_miso;
  assign uio_oe[0]  = 1'b1;
  assign uio_oe[1]  = 1'b1;
  assign uio_oe[3]  = 1'b1;

  assign uio_out[2]   = 1'b0;
  assign uio_out[7:4] = 4'b0;
  assign uio_oe[2]    = 1'b0;
  assign uio_oe[7:4]  = 4'b0;

  // Ignore unused inputs.
  wire _unused = &{ena, uio_in[7], uio_in[3:0], 1'b0};

endmodule

`default_nettype wire
