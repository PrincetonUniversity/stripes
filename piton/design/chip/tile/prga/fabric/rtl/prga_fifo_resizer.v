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
`include "prga_utils.vh"
`timescale 1ns/1ps
module prga_fifo_resizer #(
    parameter DATA_WIDTH = 32,
    parameter INPUT_MULTIPLIER = 1,
    parameter OUTPUT_MULTIPLIER = 1,
    parameter INPUT_LOOKAHEAD = 0,
    parameter OUTPUT_LOOKAHEAD = 0
) (
    input wire [0:0] clk,
    input wire [0:0] rst,

    input wire [0:0] empty_i,
    output wire [0:0] rd_i,
    input wire [DATA_WIDTH * INPUT_MULTIPLIER - 1:0] dout_i,

    output wire [0:0] empty,
    input wire [0:0] rd,
    output wire [DATA_WIDTH * OUTPUT_MULTIPLIER - 1:0] dout
    );

    generate if (INPUT_MULTIPLIER == 1 && OUTPUT_MULTIPLIER == 1) begin
        if (INPUT_LOOKAHEAD == OUTPUT_LOOKAHEAD) begin
            // Do nothing
            assign rd_i = rd;
            assign empty = empty_i;
            assign dout = dout_i;
        end else begin
            prga_fifo_lookahead_buffer #(
                .DATA_WIDTH         (DATA_WIDTH)
                ,.REVERSED          (INPUT_LOOKAHEAD)
            ) buffer (
                .clk                (clk)
                ,.rst               (rst)
                ,.empty_i           (empty_i)
                ,.rd_i              (rd_i)
                ,.dout_i            (dout_i)
                ,.empty             (empty)
                ,.rd                (rd)
                ,.dout              (dout)
                );
        end
    end else if ((INPUT_MULTIPLIER <= 0 || INPUT_MULTIPLIER > 1) && (OUTPUT_MULTIPLIER <= 0 || OUTPUT_MULTIPLIER > 1)) begin
        // At least one of INPUT_MULTIPLIER and OUTPUT_MULTIPLIER must be 1 and the other must be a positive integer.
        __PRGA_PARAMETERIZATION_ERROR__ __error__();
    end else begin
        // convert input to look-ahead
        wire empty_i_internal;
        wire [DATA_WIDTH * INPUT_MULTIPLIER - 1:0] dout_i_internal;
        wire rd_i_internal;

        if (INPUT_LOOKAHEAD) begin
            assign empty_i_internal = empty_i;
            assign dout_i_internal = dout_i;
            assign rd_i = rd_i_internal;
        end else begin
            prga_fifo_lookahead_buffer #(
                .DATA_WIDTH         (INPUT_MULTIPLIER * DATA_WIDTH)
                ,.REVERSED          (0)
            ) buffer (
                .clk                (clk)
                ,.rst               (rst)
                ,.empty_i           (empty_i)
                ,.rd_i              (rd_i)
                ,.dout_i            (dout_i)
                ,.empty             (empty_i_internal)
                ,.rd                (rd_i_internal)
                ,.dout              (dout_i_internal)
                );
        end

        // build shift pipeline
        localparam COUNTER_WIDTH = `PRGA_CLOG2(INPUT_MULTIPLIER + OUTPUT_MULTIPLIER);
        localparam BUF_WIDTH = DATA_WIDTH * (INPUT_MULTIPLIER + OUTPUT_MULTIPLIER - 1);

        reg [BUF_WIDTH - 1:0] pipebuf;
        reg [COUNTER_WIDTH:0] counter;

        always @(posedge clk) begin
            if (rst) begin
                pipebuf <= {BUF_WIDTH{1'b0}};
                counter <= 'b0;
            end else begin
                case ({~empty_i_internal && rd_i_internal, ~empty && rd})
                    2'b01: begin
                        pipebuf <= pipebuf << (DATA_WIDTH * OUTPUT_MULTIPLIER);
                        counter <= counter - OUTPUT_MULTIPLIER;
                    end
                    2'b10: begin
                        pipebuf <= {pipebuf, dout_i_internal};
                        counter <= counter + INPUT_MULTIPLIER;
                    end
                    2'b11: begin
                        pipebuf <= {pipebuf, dout_i_internal};
                        counter <= counter + INPUT_MULTIPLIER - OUTPUT_MULTIPLIER;
                    end
                endcase
            end
        end

        assign empty = counter < OUTPUT_MULTIPLIER;
        assign rd_i_internal = counter < OUTPUT_MULTIPLIER || (counter == OUTPUT_MULTIPLIER && rd);

        if (OUTPUT_LOOKAHEAD) begin
            assign dout = pipebuf[DATA_WIDTH * (INPUT_MULTIPLIER + OUTPUT_MULTIPLIER - 1) - 1 -: DATA_WIDTH * OUTPUT_MULTIPLIER];
        end else begin
            reg [DATA_WIDTH * OUTPUT_MULTIPLIER - 1:0] dout_f;

            always @(posedge clk) begin
                dout_f <= pipebuf[DATA_WIDTH * (INPUT_MULTIPLIER + OUTPUT_MULTIPLIER - 1) - 1 -: DATA_WIDTH * OUTPUT_MULTIPLIER];
            end

            assign dout = dout_f;
        end
    end endgenerate

endmodule