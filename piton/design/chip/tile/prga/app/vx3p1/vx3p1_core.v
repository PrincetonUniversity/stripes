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

module vx3p1_core #(
    parameter   DATA_WIDTH = 32
) (
    input wire                          clk
    , input wire                        rst_n

    , input wire                        iq_empty
    , input wire [DATA_WIDTH-1:0]       iq_data
    , output reg                        iq_rd

    , input wire                        oq_full
    , output reg [DATA_WIDTH:0]         oq_data
    , output reg                        oq_wr
    );

    // -- Stage: Output --
    reg                         val_o, val_o_next, stall_o;
    reg [DATA_WIDTH-1:0]        data_o, data_o_next;

    always @(posedge clk) begin
        if (~rst_n) begin
            val_o   <=  1'b0;
            data_o  <=  {DATA_WIDTH {1'b0} };
        end else begin
            val_o   <=  val_o_next;
            data_o  <=  data_o_next;
        end
    end

    always @* begin
        oq_data = data_o;
        oq_wr = val_o;
        stall_o = val_o && oq_full;
    end

    // -- Stage: eXecute --
    reg                         val_x, val_x_next, stall_x;
    reg [DATA_WIDTH-1:0]        data_x, data_x_next;

    always @(posedge clk) begin
        if (~rst_n) begin
            val_x   <=  1'b0;
            data_x  <=  {DATA_WIDTH {1'b0} };
        end else begin
            val_x   <=  val_x_next;
            data_x  <=  data_x_next;
        end
    end

    always @* begin
        val_o_next = val_x;
        data_o_next = data_x * 3 + 1;   // x3p1
        stall_x = stall_o;
    end

    // -- Stage: Input --
    reg                         val_i, val_i_next;
    reg [DATA_WIDTH-1:0]        data_i, data_i_next;

    always @(posedge clk) begin
        if (~rst_n) begin
            val_i           <=  1'b0;
            data_i          <=  {DATA_WIDTH {1'b0} };
        end else begin
            val_i           <=  val_i_next;
            data_i          <=  data_i_next;
        end
    end

    always @* begin
        val_x_next = val_i;
        data_x_next = data_i;
        val_i_next = stall_x ? val_i : ~iq_empty;
        data_i_next = stall_x ? data_i : iq_data;
        iq_rd = ~stall_x;
    end

endmodule
