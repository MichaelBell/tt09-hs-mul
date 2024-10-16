/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_MichaelBell_hs_mul (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // Bidi output enable based on ui_in[7]
  assign uio_oe  = {{8{ui_in[7]}}};

  // Shift registers for inputs
  /* verilator lint_off SYNCASYNCNET */
  wire [15:0] sr_a;
  shift_reg #(.WIDTH(16)) i_sr_a (
    .clk(clk),
    .data_in(ui_in[0]),
    .data_out(sr_a)
  );
  
  wire [15:0] sr_b;
  shift_reg #(.WIDTH(16)) i_sr_b (
    .clk(clk),
    .data_in(ui_in[1]),
    .data_out(sr_b)
  );

  // Latch gate
  wire latch_gate;
  assign latch_gate = ui_in[4] ? !ui_in[3] : ui_in[2];

  // Latched multiplier inputs
  reg [15:0] mul_a;
  always @(latch_gate or sr_a) begin
    if (latch_gate) mul_a <= sr_a;
  end
  reg [15:0] mul_b;
  always @(latch_gate or sr_b) begin
    if (latch_gate) mul_b <= sr_b;
  end
  /* verilator lint_on SYNCASYNCNET */

  // Multiplier
  wire [25:0] result;
  assign result = mul_a[12:0] * mul_b[12:0];

  // Outputs
  assign uo_out = !rst_n ? ui_in :
                  ui_in[5] ? (ui_in[6] ? mul_b[7:0] : mul_a[7:0]) :
                  ui_in[6] ? result[23:16] :
                  result[7:0];
  assign uio_out = !rst_n ? ui_in :
                  ui_in[5] ? (ui_in[6] ? mul_b[15:8] : mul_a[15:8]) :
                  ui_in[6] ? {6'b000000, result[25:24]} :
                  result[15:8];

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, uio_in, 1'b0};

endmodule
