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

module vx3p1_oq #(
    parameter   AXSIZE = `PRGA_AXI4_AXSIZE_4B,

    // deducted from AXSIZE
    parameter   DATA_WIDTH = 32
) (
    input wire                                      clk,
    input wire                                      rst_n,

    // == Configuration Signals ==
    input wire                                      start,
    input wire [`PRGA_AXI4_ADDR_WIDTH-1:0]          dst_base_addr,
    input wire [`PRGA_CREG_DATA_WIDTH-1:0]          vlen,
    output reg                                      done,

    // == Output FIFO interface ==
    output wire                                     oq_full,
    input wire                                      oq_wr,
    input wire [DATA_WIDTH-1:0]                     oq_din,

    // == AXI4 (AW, W & B channels) ==
    // -- AW channel --
    input wire                                      awready,
    output reg                                      awvalid,
    output wire [`PRGA_AXI4_ID_WIDTH-1:0]           awid,
    output reg  [`PRGA_AXI4_ADDR_WIDTH-1:0]         awaddr,
    output reg  [`PRGA_AXI4_AXLEN_WIDTH-1:0]        awlen,
    output wire [`PRGA_AXI4_AXSIZE_WIDTH-1:0]       awsize,
    output wire [`PRGA_AXI4_AXBURST_WIDTH-1:0]      awburst,

    // non-standard use of AWCACHE: Only |AWCACHE[3:2] is checked: 1'b1: cacheable; 1'b0: non-cacheable
    output wire [`PRGA_AXI4_AXCACHE_WIDTH-1:0]      awcache,

    // -- W channel --
    input wire                                      wready,
    output reg                                      wvalid,
    output reg [`PRGA_AXI4_DATA_WIDTH-1:0]          wdata,
    output reg [`PRGA_AXI4_DATA_BYTES-1:0]          wstrb,
    output wire                                     wlast,

    // -- B channel --
    output reg                                      bready,
    input wire                                      bvalid,
    input wire [`PRGA_AXI4_XRESP_WIDTH-1:0]         bresp,
    input wire [`PRGA_AXI4_ID_WIDTH-1:0]            bid
    );

    reg                                 oq_rd;
    wire [DATA_WIDTH-1:0]               oq_dout;
    wire                                oq_empty;

    prga_fifo #(
        .DEPTH_LOG2     (8)     // max. 256 elements
        ,.DATA_WIDTH    (DATA_WIDTH)
        ,.LOOKAHEAD     (1)
    ) oq (
        .clk            (clk)
        ,.rst           (~rst_n)
        ,.full          (oq_full)
        ,.wr            (oq_wr)
        ,.din           (oq_din)
        ,.empty         (oq_empty)
        ,.rd            (oq_rd)
        ,.dout          (oq_dout)
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

    // == Stage: W ==
    reg [2:0]                           woffset, woffset_init;
    reg [`PRGA_CREG_DATA_WIDTH-1:0]     wcnt, wcnt_expected;

    always @(posedge clk) begin
        if (~rst_n) begin
            woffset <= 3'h0;
            wcnt    <= {`PRGA_CREG_DATA_WIDTH {1'b0} };
        end else if (start) begin
            woffset <= dst_base_addr[2:0];
            wcnt    <= {`PRGA_CREG_DATA_WIDTH {1'b0} };
        end else if (wready && wvalid) begin
            wcnt    <= wcnt + 1;

            case (AXSIZE)
                `PRGA_AXI4_AXSIZE_1B: woffset <= woffset + 1;
                `PRGA_AXI4_AXSIZE_2B: woffset <= woffset + 2;
                `PRGA_AXI4_AXSIZE_4B: woffset <= woffset + 4;
                `PRGA_AXI4_AXSIZE_8B: woffset <= woffset + 8;
            endcase
        end
    end

    always @* begin
        wvalid = ~oq_empty && wcnt < wcnt_expected;
        oq_rd = wready && wcnt < wcnt_expected;

        wdata = {`PRGA_AXI4_DATA_WIDTH {1'b0} };
        wstrb = {`PRGA_AXI4_DATA_BYTES {1'b0} };

        case (AXSIZE)
            `PRGA_AXI4_AXSIZE_1B: begin
                wdata = {8 {oq_dout} };
                wstrb = 8'h1 << woffset[2:0];
            end
            `PRGA_AXI4_AXSIZE_2B: begin
                wdata = {4 {oq_dout} };
                wstrb = 8'h3 << {woffset[2:1], 1'b0};
            end
            `PRGA_AXI4_AXSIZE_4B: begin
                wdata = {2 {oq_dout} };
                wstrb = 8'hf << {woffset[2:2], 2'b0};
            end
            `PRGA_AXI4_AXSIZE_8B: begin
                wdata = oq_dout;
                wstrb = 8'hff;
            end
        endcase
    end

    assign wlast = wcnt + 1 == wcnt_expected;

    // == Stage: AW & B ==
    always @(posedge clk) begin
        if (~rst_n) begin
            done            <= 1'b0;
            wcnt_expected   <= {`PRGA_CREG_DATA_WIDTH {1'b0} };
            awaddr          <= {`PRGA_AXI4_ADDR_WIDTH {1'b0} };
            bready          <= 1'b0;
        end else if (start) begin
            done            <= 1'b0;
            wcnt_expected   <= {`PRGA_CREG_DATA_WIDTH {1'b0} };
            awaddr          <= dst_base_addr;
            bready          <= 1'b0;
        end else begin
            if (wcnt == vlen && bready && bvalid) begin
                done        <= 1'b1;
            end

            if (awready && awvalid) begin
                wcnt_expected   <= wcnt_expected + awlen + 1;
                bready          <= 1'b1;

                case (AXSIZE)
                    `PRGA_AXI4_AXSIZE_1B: awaddr <= awaddr + (awlen + 1);
                    `PRGA_AXI4_AXSIZE_2B: awaddr <= awaddr + ((awlen + 1) << 1);
                    `PRGA_AXI4_AXSIZE_4B: awaddr <= awaddr + ((awlen + 1) << 2);
                    `PRGA_AXI4_AXSIZE_8B: awaddr <= awaddr + ((awlen + 1) << 3);
                endcase
            end else if (bready && bvalid) begin
                bready          <= 1'b0;
            end
        end
    end

    always @* begin
        awvalid = started && ~oq_empty && wcnt_expected == wcnt && wcnt < vlen && ~bready || bvalid;
        awlen = (vlen - wcnt_expected > 16) ? 15 : (vlen - wcnt_expected - 1);
    end

    assign awid = {`PRGA_AXI4_ID_WIDTH {1'b0} };
    assign awsize = AXSIZE;
    assign awburst = `PRGA_AXI4_AXBURST_INCR;
    assign awcache = `PRGA_AXI4_AWCACHE_WB_ALCT;

endmodule
