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
`include "pktchain.vh"
`timescale 1ns/1ps
module pktchain_clasp (
    input wire [0:0] prog_clk,
    input wire [0:0] prog_rst,

    // frame inputs
    input wire [0:0] frame_empty,
    output reg [0:0] frame_rd,
    input wire [`PRGA_PKTCHAIN_FRAME_SIZE - 1:0] frame_i,

    // extra control inputs
    input wire [0:0] ctrl_init,     // marks the input frame as the first frame
    input wire [0:0] ctrl_checksum, // marks the input frame as the last frame ending with CRC-8 CCITT prefix checksums

    // status outputs
    output reg [0:0] programming,
    output reg [0:0] echo_mismatch,
    output reg [0:0] checksum_mismatch,

    // chain inputs & outputs
    input wire [0:0] prog_we,
    input wire [`PRGA_PKTCHAIN_CHAIN_WIDTH-1:0] prog_din,

    output reg [0:0] prog_we_o,
    output reg [`PRGA_PKTCHAIN_CHAIN_WIDTH-1:0] prog_dout
    );

    // data registers
    // input buffering
    reg [`PRGA_PKTCHAIN_FRAME_SIZE - 1:0] frame_buf;
    reg prog_o_proceed;

    // checks
    reg [8 * `PRGA_PKTCHAIN_CHAIN_WIDTH - 1:0] echo_collected;              // echo collected
    reg [7:0] crc [`PRGA_PKTCHAIN_CHAIN_WIDTH - 1:0];                       // checksum
    
    always @(posedge prog_clk) begin
        if (~frame_empty && frame_rd) begin
            frame_buf <= frame_i;
        end else if (prog_o_proceed) begin
            frame_buf <= frame_buf << `PRGA_PKTCHAIN_CHAIN_WIDTH;
        end
    end

    always @(posedge prog_clk) begin
        if (~frame_empty && frame_rd && ctrl_init) begin
            
            crc[0] <= 'b0;
        end else if (prog_o_proceed) begin
            
            crc[0] <= (crc[0] << 1) ^ (crc[0][7] ^ prog_dout[0] ? 8'h07 : 8'b0);
        end
    end

    always @(posedge prog_clk) begin
        if (prog_we) begin
            echo_collected <= {echo_collected, prog_din};
        end
    end

    always @* begin
        prog_dout = frame_buf[`PRGA_PKTCHAIN_FRAME_SIZE - 1 -: `PRGA_PKTCHAIN_CHAIN_WIDTH];
    end

    

    localparam  STATE_RESET     = 3'h0,
                STATE_IDLE      = 3'h1,
                STATE_PROG      = 3'h2,
                STATE_PAUSE     = 3'h3,
                STATE_CHECKSUM  = 3'h4;
    localparam  STATE_PROG_LAST = 3'h7;     // this state is needed because `PRGA_PKTCHAIN_NUM_CHAINS_PER_FRAME > 8

    reg [2:0] state, state_next;
    reg [`PRGA_PKTCHAIN_NUM_CHAINS_PER_FRAME - 1:0] chain_cnt, chain_cnt_next;
    reg [7:0] break_counter;
    reg prog_we_o_prev, prog_we_i_prev;

    always @(posedge prog_clk) begin
        if (prog_rst) begin
            state <= STATE_RESET;
            chain_cnt <= 'b0;
            break_counter <= 'b0;
        end else begin
            state <= state_next;
            chain_cnt <= chain_cnt_next;

            case ({prog_we_o && ~prog_we_o_prev, ~prog_we && prog_we_i_prev})
                2'b10:  break_counter <= break_counter + 1;
                2'b01:  break_counter <= break_counter - 1;
            endcase
        end
    end

    always @(posedge prog_clk) begin
        prog_we_o_prev <= prog_we_o;
        prog_we_i_prev <= prog_we;
    end

    always @* begin
        state_next = state;
        chain_cnt_next = chain_cnt;

        frame_rd = 'b0;
        prog_we_o = 'b0;
        prog_o_proceed = 'b0;

        case (state)
            STATE_RESET: begin
                state_next = STATE_IDLE;
            end
            STATE_IDLE,
            STATE_PAUSE: begin
                frame_rd = 'b1;

                if (~frame_empty) begin
                    if (ctrl_checksum) begin
                        state_next = STATE_PROG_LAST;
                    end else begin
                        state_next = STATE_PROG;
                    end
                end
            end
            STATE_PROG: begin
                prog_we_o = 'b1;
                prog_o_proceed = 'b1;

                if (chain_cnt == `PRGA_PKTCHAIN_NUM_CHAINS_PER_FRAME - 1) begin
                    frame_rd = 'b1;
                    chain_cnt_next = 'b0;

                    if (frame_empty) begin
                        state_next = STATE_PAUSE;
                    end else if (ctrl_checksum) begin
                        state_next = STATE_PROG_LAST;
                    end
                end else begin
                    chain_cnt_next = chain_cnt + 1;
                end
            end
            STATE_PROG_LAST: begin
                prog_we_o = 'b1;
                prog_o_proceed = 'b1;
                chain_cnt_next = chain_cnt + 1;

                if (chain_cnt == `PRGA_PKTCHAIN_NUM_CHAINS_PER_FRAME - 9) begin
                    state_next = STATE_CHECKSUM;
                end
            end
            STATE_CHECKSUM: begin
                if (break_counter == 0) begin
                    chain_cnt_next = 0;
                    state_next = STATE_IDLE;
                end
            end
        endcase
    end

    always @* begin
        programming = !(state == STATE_RESET || state == STATE_IDLE);
        echo_mismatch = echo_collected != frame_buf[`PRGA_PKTCHAIN_FRAME_SIZE - 1 -: 8 * `PRGA_PKTCHAIN_CHAIN_WIDTH];
        checksum_mismatch = |{crc[0]};
    end

endmodule