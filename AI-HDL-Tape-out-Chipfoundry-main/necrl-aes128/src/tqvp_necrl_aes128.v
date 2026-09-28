/*
 * tqvp_necrl_aes128 — TinyQV peripheral wrapper for the NeCRL AES-128 core.
 *
 * Bridges the AES core's four submodules to the TinyQV register bus. This module was
 * missing from the original submission (info.yaml named a top that no file defined and
 * the integration testbench drove an undefined `tqvp_necrl_spi`); it is authored here
 * from the documented register map (docs/info.md, 0x00-0x0D) and the submodule ports.
 *
 * AES_memory is itself the bus front-end (control/status + key/plaintext/ciphertext
 * registers, auto_start/key_lock, 32-bit-only access, write-only key). This module only
 * wires memory <-> control <-> key-engine <-> encryption-engine and adapts reset.
 *
 * Notes / caveats (carried from the original RTL, documented for sign-off):
 *  - AES_control_unit.reset_n is ACTIVE-HIGH internally (posedge reset_n), so the
 *    active-low bus rst_n is inverted here.
 *  - No boot self-test module was included in the source; selftest_done/selftest_fail
 *    are tied to done/pass so the status bits [3:2] read 2'b01. The real FIPS datapath
 *    is unaffected — encryption still produces the true ciphertext.
 */

`default_nettype none

module tqvp_necrl_aes128 (
    input  wire        clk,
    input  wire        rst_n,           // active-low (TinyQV convention)
    input  wire [7:0]  ui_in,           // unused by this peripheral
    output wire [7:0]  uo_out,
    input  wire [5:0]  address,
    input  wire [31:0] data_in,
    input  wire [1:0]  data_write_n,    // 2'b10 = 32-bit write, 2'b11 = idle
    input  wire [1:0]  data_read_n,     // 2'b10 = 32-bit read,  2'b11 = idle
    output wire [31:0] data_out,
    output wire        data_ready,
    output wire        user_interrupt
);

    // Internal interconnect (matches the DP4 block diagram / submodule ports).
    wire         start;
    wire         done;
    wire         fault;
    wire         stall;
    wire         reset_s;        // soft reset (control_reg bit 1), memory -> control
    wire         core_reset;     // datapath reset, control -> key/enc engines
    wire         key_engine_start;
    wire [4:0]   count;
    wire [127:0] plaintext;      // AES_memory.encryption_engine_data
    wire [127:0] original_key;   // AES_memory.original_key
    wire [127:0] round_key;      // AES_key_engine.round_key
    wire [127:0] cipher;         // AES_encryption_engine.cipher

    // AES_control_unit.reset_n is active-HIGH despite its name — invert bus rst_n.
    wire reset_h = ~rst_n;

    // The harness captures rst_n on NEGEDGE (TinyQV convention), leaving only
    // half a clock period from its flop to any posedge sink. AES_memory's
    // synchronous reset fans out to >500 flops, which cannot close in half a
    // period at the ss corner - so re-register it on posedge here (reset is
    // quasi-static; assertion/release one cycle later is behaviorally inert).
    reg rst_n_q;
    always @(posedge clk) rst_n_q <= rst_n;

    // Bus front-end: control/status + key/plaintext/ciphertext register file.
    AES_memory aes_memory_inst (
        .clk            (clk),
        .rst_n          (rst_n_q),
        .data_read_n    (data_read_n),
        .data_write_n   (data_write_n),
        .data_in        (data_in),
        .address        (address),
        .ciphertext     (cipher),
        .done           (done),
        .fault          (fault),
        .selftest_done  (1'b1),        // self-test module absent — status stubbed pass
        .selftest_fail  (1'b0),
        .data_out       (data_out),
        .start          (start),
        .encryption_engine_data (plaintext),
        .original_key   (original_key),
        .reset_s        (reset_s)
    );

    AES_control_unit aes_control_inst (
        .clk                    (clk),
        .start                  (start),
        .reset_n                (reset_h),
        .reset_s                (reset_s),
        .done                   (done),
        .reset                  (core_reset),
        .fault                  (fault),
        .stall                  (stall),
        .encryption_engine_count(count),
        .key_engine_start       (key_engine_start)
    );

    AES_key_engine aes_key_inst (
        .clk             (clk),
        .reset           (core_reset),
        .stall           (stall),
        .count           (count),
        .key_engine_start(key_engine_start),
        .original_key    (original_key),
        .round_key       (round_key)
    );

    AES_encryption_engine aes_enc_inst (
        .clk                    (clk),
        .reset                  (core_reset),
        .stall                  (stall),
        .count                  (count),
        .encryption_engine_data (plaintext),
        .round_key              (round_key),
        .cipher                 (cipher)
    );

    // AES_memory reads are combinational; ready is always high.
    assign data_ready     = 1'b1;
    // one-cycle pulse on done's rising edge, as docs/info.md describes.
    // (done itself stays high until the next start, so a level here kept
    // the interrupt line stuck asserted after every encryption)
    reg done_d;
    always @(posedge clk) begin
        if (!rst_n_q)
            done_d <= 1'b0;
        else
            done_d <= done;
    end
    assign user_interrupt = done && !done_d;
    assign uo_out         = 8'h00;   // dedicated output lane unused

    // Silence unused-input lint (ui_in lane is not used by this peripheral).
    wire _unused = &{ui_in, 1'b0};

endmodule

`default_nettype wire
