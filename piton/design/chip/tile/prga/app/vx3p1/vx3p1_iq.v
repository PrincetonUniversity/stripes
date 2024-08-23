// Copyright (c) 2024 Princeton University
// All rights reserved.
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above copyright
//       notice, this list of conditions and the following disclaimer in the
//       documentation and/or other materials provided with the distribution.
//     * Neither the name of the copyright holder nor the
//       names of its contributors may be used to endorse or promote products
//       derived from this software without specific prior written permission.

// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY
// DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

`timescale 1ns/1ps
`include "prga_axi4.vh"

module vx3p1_iq #(
    parameter   AXSIZE = `PRGA_AXI4_AXSIZE_4B,

    // deducted from AXSIZE
    parameter   DATA_WIDTH = 32
) (
    input wire                                      clk,
    input wire                                      rst_n,

    // == Configuration Signals ==
    input wire                                      start,
    input wire [`PRGA_AXI4_ADDR_WIDTH-1:0]          src_base_addr,
    input wire [`PRGA_CREG_DATA_WIDTH-1:0]          vlen,
    output wire                                     done,

    // == Input FIFO interface ==
    input wire                                      iq_rd,
    output wire                                     iq_empty,
    output wire [DATA_WIDTH-1:0]                    iq_dout,

    // == AXI4 (AR & R channels) ==
    // -- AR channel --
    input wire                                      arready,
    output reg                                      arvalid,
    output wire [`PRGA_AXI4_ID_WIDTH-1:0]           arid,
    output reg [`PRGA_AXI4_ADDR_WIDTH-1:0]          araddr,
    output reg [`PRGA_AXI4_AXLEN_WIDTH-1:0]         arlen,
    output wire [`PRGA_AXI4_AXSIZE_WIDTH-1:0]       arsize,
    output wire [`PRGA_AXI4_AXBURST_WIDTH-1:0]      arburst,

    // non-standard use of ARLOCK: indicates an atomic operation.
    // Type of the atomic operation is specified in the ARUSER field
    output wire                                     arlock,

    // non-standard use of ARCACHE: Only |ARCACHE[3:2] is checked: 1'b1: cacheable; 1'b0: non-cacheable
    output wire [`PRGA_AXI4_AXCACHE_WIDTH-1:0]      arcache,

    // ATOMIC operation type, data & ECC:
    //      aruser[`PRGA_CCM_ECC_WIDTH + `PRGA_CCM_AMO_OPCODE_WIDTH +: `PRGA_CCM_DATA_WIDTH]        amo_data
    //      aruser[`PRGA_CCM_ECC_WIDTH                              +: `PRGA_CCM_AMO_OPCODE_WIDTH]  amo_opcode
    //      aruser[0                                                +: `PRGA_CCM_ECC_WIDTH]         ecc
    output wire [`PRGA_CCM_AMO_OPCODE_WIDTH - 1:0]  aramo_opcode,
    output wire [`PRGA_CCM_DATA_WIDTH - 1:0]        aramo_data,

    // -- R channel --
    output reg                                      rready,
    input wire                                      rvalid,
    input wire [`PRGA_AXI4_XRESP_WIDTH-1:0]         rresp,
    input wire [`PRGA_AXI4_ID_WIDTH-1:0]            rid,
    input wire [`PRGA_AXI4_DATA_WIDTH-1:0]          rdata,
    input wire                                      rlast
    );

    reg                                 iq_wr;
    reg [DATA_WIDTH-1:0]                iq_din;
    wire                                iq_full;

    prga_fifo #(
        .DEPTH_LOG2     (8)     // max. 256 elements
        ,.DATA_WIDTH    (DATA_WIDTH)
        ,.LOOKAHEAD     (1)
    ) iq (
        .clk            (clk)
        ,.rst           (~rst_n)
        ,.full          (iq_full)
        ,.wr            (iq_wr)
        ,.din           (iq_din)
        ,.empty         (iq_empty)
        ,.rd            (iq_rd)
        ,.dout          (iq_dout)
        );

    reg started;

    always @(posedge clk) begin
        if (~rst_n) begin
            started         <= 1'b0;
        end else if (start) begin
            started         <= 1'b1;
        end else if (done) begin
            started         <= 1'b0;
        end
    end

    // == Stage: R ==
    reg [`PRGA_CREG_DATA_WIDTH-1:0]     rcnt;

    always @(posedge clk) begin
        if (~rst_n || start) begin
            rcnt <= {`PRGA_CREG_DATA_WIDTH {1'b0} };
        end else if (rready && rvalid) begin
            rcnt <= rcnt + 1;
        end
    end

    always @* begin
        iq_wr = rvalid && rresp == `PRGA_AXI4_XRESP_OKAY;
        iq_din = rdata[0 +: DATA_WIDTH];
        rready = ~iq_full;
    end

    assign done = rcnt == vlen;

    // == Stage: AR ==
    reg [`PRGA_CREG_DATA_WIDTH-1:0]     rcnt_expected;

    always @(posedge clk) begin
        if (~rst_n) begin
            rcnt_expected   <=  {`PRGA_CREG_DATA_WIDTH {1'b0} };
            araddr          <=  {`PRGA_AXI4_ADDR_WIDTH {1'b0} };
        end else if (start) begin
            rcnt_expected   <=  {`PRGA_CREG_DATA_WIDTH {1'b0} };
            araddr          <=  src_base_addr;
        end else if (arready && arvalid) begin
            rcnt_expected   <=  rcnt_expected + arlen + 1;

            case (AXSIZE)
                `PRGA_AXI4_AXSIZE_1B: araddr <= araddr + (arlen + 1);
                `PRGA_AXI4_AXSIZE_2B: araddr <= araddr + ((arlen + 1) << 1);
                `PRGA_AXI4_AXSIZE_4B: araddr <= araddr + ((arlen + 1) << 2);
                `PRGA_AXI4_AXSIZE_8B: araddr <= araddr + ((arlen + 1) << 3);
            endcase
        end
    end

    always @* begin
        arvalid = started && rcnt_expected == rcnt && rcnt < vlen;
        arlen = (vlen - rcnt_expected > 16) ? 15 : (vlen - rcnt_expected - 1);
    end

    assign arid = {`PRGA_AXI4_ID_WIDTH {1'b0} };
    assign arsize = AXSIZE;
    assign arburst = `PRGA_AXI4_AXBURST_INCR;
    assign arlock = 1'b0;
    assign arcache = `PRGA_AXI4_ARCACHE_WB_ALCT;
    assign aramo_opcode = `PRGA_CCM_AMO_OPCODE_NONE;
    assign aramo_data = {`PRGA_CCM_DATA_WIDTH {1'b0} };

endmodule
