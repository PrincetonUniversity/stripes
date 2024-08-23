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
`include "pktchain.vh"

module prga_fifo_buf #(
    parameter DATA_WIDTH = `PRGA_PKTCHAIN_PHIT_WIDTH
) (
    input wire [0:0] clk,
    input wire [0:0] rst,

    output reg [0:0] full_o,
    input wire [0:0] wr_i,
    input wire [DATA_WIDTH - 1:0] data_i,

    output reg [0:0] wr_o,
    input wire [0:0] full_i,
    output reg [DATA_WIDTH - 1:0] data_o
    );

    reg [1:0]               wr_ptr, rd_ptr;
    reg [DATA_WIDTH - 1:0]  data [0:1];

    always @(posedge clk) begin
        if (rst) begin
            wr_ptr      <= 2'b0;
            rd_ptr      <= 2'b0;

            data[0]     <= {DATA_WIDTH {1'b0} };
            data[1]     <= {DATA_WIDTH {1'b0} };
        end else begin
            if (wr_i && !full_o) begin
                data[wr_ptr[0]] <=  data_i;
                wr_ptr          <=  wr_ptr + 1;
            end

            if (wr_o && !full_i) begin
                rd_ptr          <=  rd_ptr + 1;
            end
        end
    end

    always @* begin
        full_o = rd_ptr == {~wr_ptr[1], wr_ptr[0]};
        wr_o = rd_ptr != wr_ptr;
        data_o = data[rd_ptr[0]];
    end

endmodule
