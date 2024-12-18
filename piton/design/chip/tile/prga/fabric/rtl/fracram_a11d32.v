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

// Automatically generated by PRGA's RTL generator
`timescale 1ns/1ps
module fracram_a11d32 #(
    parameter   ADDR_WIDTH = 11
    , parameter DATA_WIDTH = 32
) (
    input wire [0:0] clk

    , input wire [ADDR_WIDTH - 1:0] waddr
    , input wire [0:0]              we
    , input wire [DATA_WIDTH - 1:0] din

    , input wire [ADDR_WIDTH - 1:0] raddr
    , output reg [DATA_WIDTH - 1:0] dout

    , input wire [0:0] prog_done
    , input wire [1:0] prog_data
    );

    // non-fracturable memory core
    localparam  CORE_ADDR_WIDTH = 9;

    reg [CORE_ADDR_WIDTH - 1:0]     int_waddr, int_raddr;
    reg                             int_we, int_re;
    reg [DATA_WIDTH - 1:0]          int_din, int_bw;
    wire [DATA_WIDTH - 1:0]         int_dout;

    prga_ram_1r1w_byp #(
        .DATA_WIDTH (DATA_WIDTH)
        ,.ADDR_WIDTH (CORE_ADDR_WIDTH)
    )i_ram (
        .clk                        (clk)
        ,.rst                       (~prog_done)
        ,.waddr                     (int_waddr)
        ,.din                       (int_din)
        ,.we                        (int_we)
        ,.bw                        (int_bw)
        ,.raddr                     (int_raddr)
        ,.re                        (int_re)
        ,.dout                      (int_dout)
        );

    // sub-words
    localparam  DATA_WIDTH_SR0 = DATA_WIDTH;
    localparam  DATA_OFFSET_SR0_0 = 0;

    wire [DATA_WIDTH_SR0 - 1:0] dout_sr0 [0:0];
    assign dout_sr0[0] = int_dout;

    localparam  DATA_WIDTH_SR1 = DATA_WIDTH_SR0 >> 1;
    localparam  DATA_OFFSET_SR1_0 = DATA_OFFSET_SR0_0 + 0 * DATA_WIDTH_SR1;
    localparam  DATA_OFFSET_SR1_1 = DATA_OFFSET_SR0_0 + 1 * DATA_WIDTH_SR1;

    wire [DATA_WIDTH_SR1 - 1:0] dout_sr1 [0:1];
    assign dout_sr1[0] = dout_sr0[0][0 * DATA_WIDTH_SR1 +: DATA_WIDTH_SR1];
    assign dout_sr1[1] = dout_sr0[0][1 * DATA_WIDTH_SR1 +: DATA_WIDTH_SR1];

    localparam  DATA_WIDTH_SR2 = DATA_WIDTH_SR1 >> 1;
    localparam  DATA_OFFSET_SR2_0 = DATA_OFFSET_SR1_0 + 0 * DATA_WIDTH_SR2;
    localparam  DATA_OFFSET_SR2_1 = DATA_OFFSET_SR1_0 + 1 * DATA_WIDTH_SR2;
    localparam  DATA_OFFSET_SR2_2 = DATA_OFFSET_SR1_1 + 0 * DATA_WIDTH_SR2;
    localparam  DATA_OFFSET_SR2_3 = DATA_OFFSET_SR1_1 + 1 * DATA_WIDTH_SR2;

    wire [DATA_WIDTH_SR2 - 1:0] dout_sr2 [0:3];
    assign dout_sr2[0] = dout_sr1[0][0 * DATA_WIDTH_SR2 +: DATA_WIDTH_SR2];
    assign dout_sr2[1] = dout_sr1[0][1 * DATA_WIDTH_SR2 +: DATA_WIDTH_SR2];
    assign dout_sr2[2] = dout_sr1[1][0 * DATA_WIDTH_SR2 +: DATA_WIDTH_SR2];
    assign dout_sr2[3] = dout_sr1[1][1 * DATA_WIDTH_SR2 +: DATA_WIDTH_SR2];

    // modes
    reg [ADDR_WIDTH - CORE_ADDR_WIDTH - 1:0]     wr_offset, rd_offset, rd_offset_f;

    integer i;
    always @*
        for (i = 0; i < ADDR_WIDTH - CORE_ADDR_WIDTH; i = i + 1) begin
            wr_offset[i] = waddr[ADDR_WIDTH - 1 - i];
            rd_offset[i] = raddr[ADDR_WIDTH - 1 - i];
        end

    always @(posedge clk) begin
        if (~prog_done) begin
            rd_offset_f     <= {(ADDR_WIDTH - CORE_ADDR_WIDTH) {1'b0} };
        end else begin
            rd_offset_f     <= rd_offset;
        end
    end

    always @* begin
        if (~prog_done) begin
            int_waddr   = {CORE_ADDR_WIDTH {1'b0} };
            int_raddr   = {CORE_ADDR_WIDTH {1'b0} };
            int_we      = 1'b0;
            int_re      = 1'b0;
            int_din     = {DATA_WIDTH {1'b0} };
            int_bw      = {DATA_WIDTH {1'b0} };
            dout        = {DATA_WIDTH {1'b0} };
        end else begin
            int_waddr   = waddr[0 +: CORE_ADDR_WIDTH];
            int_raddr   = raddr[0 +: CORE_ADDR_WIDTH];
            int_we      = 1'b0;
            int_re      = 1'b0;
            int_din     = din;
            int_bw      = {DATA_WIDTH {1'b1} };
            dout        = int_dout;

            
            if (1 == {prog_data[0+:2]}) begin
                // mode: 512x32b
                int_we  = we;
                int_re  = 1'b1;

                
                int_din = din;
                int_bw  = {DATA_WIDTH {1'b1} };
                dout    = int_dout;
            end else if (2 == {prog_data[0+:2]}) begin
                // mode: 1K16b
                int_we  = we;
                int_re  = 1'b1;

                
                case (wr_offset[ADDR_WIDTH - CORE_ADDR_WIDTH - 1 -: 1])
                    1'd0: begin
                        int_din = din[0 +: DATA_WIDTH_SR1] << DATA_OFFSET_SR1_0;
                        int_bw = {DATA_WIDTH_SR1 {1'b1} } << DATA_OFFSET_SR1_0;
                    end
                    1'd1: begin
                        int_din = din[0 +: DATA_WIDTH_SR1] << DATA_OFFSET_SR1_1;
                        int_bw = {DATA_WIDTH_SR1 {1'b1} } << DATA_OFFSET_SR1_1;
                    end
                endcase

                case (rd_offset_f[ADDR_WIDTH - CORE_ADDR_WIDTH - 1 -: 1])
                    1'd0: dout = dout_sr1[0];
                    1'd1: dout = dout_sr1[1];
                endcase
            end else if (3 == {prog_data[0+:2]}) begin
                // mode: 2K8b
                int_we  = we;
                int_re  = 1'b1;

                
                case (wr_offset[ADDR_WIDTH - CORE_ADDR_WIDTH - 1 -: 2])
                    2'd0: begin
                        int_din = din[0 +: DATA_WIDTH_SR2] << DATA_OFFSET_SR2_0;
                        int_bw = {DATA_WIDTH_SR2 {1'b1} } << DATA_OFFSET_SR2_0;
                    end
                    2'd1: begin
                        int_din = din[0 +: DATA_WIDTH_SR2] << DATA_OFFSET_SR2_1;
                        int_bw = {DATA_WIDTH_SR2 {1'b1} } << DATA_OFFSET_SR2_1;
                    end
                    2'd2: begin
                        int_din = din[0 +: DATA_WIDTH_SR2] << DATA_OFFSET_SR2_2;
                        int_bw = {DATA_WIDTH_SR2 {1'b1} } << DATA_OFFSET_SR2_2;
                    end
                    2'd3: begin
                        int_din = din[0 +: DATA_WIDTH_SR2] << DATA_OFFSET_SR2_3;
                        int_bw = {DATA_WIDTH_SR2 {1'b1} } << DATA_OFFSET_SR2_3;
                    end
                endcase

                case (rd_offset_f[ADDR_WIDTH - CORE_ADDR_WIDTH - 1 -: 2])
                    2'd0: dout = dout_sr2[0];
                    2'd1: dout = dout_sr2[1];
                    2'd2: dout = dout_sr2[2];
                    2'd3: dout = dout_sr2[3];
                endcase
            end
        end
    end

endmodule