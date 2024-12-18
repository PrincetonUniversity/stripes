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
module pktchain_gatherer (
    input wire [0:0] prog_clk,
    input wire [0:0] prog_rst,

    // noc inputs
    output wire [0:0] phit_ix_full,
    input wire [0:0] phit_ix_wr,
    input wire [`PRGA_PKTCHAIN_PHIT_WIDTH - 1:0] phit_ix,

    output wire [0:0] phit_iy_full,
    input wire [0:0] phit_iy_wr,
    input wire [`PRGA_PKTCHAIN_PHIT_WIDTH - 1:0] phit_iy,

    // noc outputs
    input wire [0:0] phit_o_full,
    output wire [0:0] phit_o_wr,
    output wire [`PRGA_PKTCHAIN_PHIT_WIDTH - 1:0] phit_o
    );

    // register reset signal
    reg prog_rst_f;

    always @(posedge prog_clk) begin
        prog_rst_f <= prog_rst;
    end

    wire frame_ix_empty, frame_iy_empty, frame_o_full;
    wire [`PRGA_PKTCHAIN_FRAME_SIZE - 1:0] frame_ix, frame_iy;
    reg [`PRGA_PKTCHAIN_FRAME_SIZE - 1:0] frame_o;
    reg frame_ix_rd, frame_iy_rd, frame_o_wr;

    pktchain_frame_assemble ix (
        .prog_clk       (prog_clk)
        ,.prog_rst      (prog_rst_f)
        ,.phit_full     (phit_ix_full)
        ,.phit_wr       (phit_ix_wr)
        ,.phit_i        (phit_ix)
        ,.frame_empty   (frame_ix_empty)
        ,.frame_rd      (frame_ix_rd)
        ,.frame_o       (frame_ix)
        );

    pktchain_frame_assemble iy (
        .prog_clk       (prog_clk)
        ,.prog_rst      (prog_rst_f)
        ,.phit_full     (phit_iy_full)
        ,.phit_wr       (phit_iy_wr)
        ,.phit_i        (phit_iy)
        ,.frame_empty   (frame_iy_empty)
        ,.frame_rd      (frame_iy_rd)
        ,.frame_o       (frame_iy)
        );

    pktchain_frame_disassemble ofifo (
        .prog_clk       (prog_clk)
        ,.prog_rst      (prog_rst_f)
        ,.frame_full    (frame_o_full)
        ,.frame_wr      (frame_o_wr)
        ,.frame_i       (frame_o)
        ,.phit_full     (phit_o_full)
        ,.phit_wr       (phit_o_wr)
        ,.phit_o        (phit_o)
        );

    localparam  STATE_RESET                         = 4'h0,
                STATE_IDLE                          = 4'h1,
                STATE_FORWARD_X                     = 4'h2,
                STATE_FORWARD_Y                     = 4'h3,
                STATE_DUMP_Y                        = 4'h4;

    reg [3:0] state, state_next;
    reg [`PRGA_PKTCHAIN_PAYLOAD_WIDTH - 1:0] payload, payload_next;

    always @(posedge prog_clk) begin
        if (prog_rst_f) begin
            state <= STATE_RESET;
            payload <= 'b0;
        end else begin
            state <= state_next;
            payload <= payload_next;
        end
    end

    always @* begin
        frame_o = frame_ix;
        frame_ix_rd = 'b0;
        frame_iy_rd = 'b0;
        frame_o_wr = 'b0;
        state_next = state;
        payload_next = 'b0;

        case (state)
            STATE_RESET: begin
                state_next = STATE_IDLE;
            end
            STATE_IDLE: begin
                if (!frame_ix_empty) begin
                    frame_o = frame_ix + (1 << `PRGA_PKTCHAIN_BRANCH_ID_BASE);
                    frame_o_wr = 'b1;
                    payload_next = frame_ix[`PRGA_PKTCHAIN_PAYLOAD_INDEX];
                    
                    if (!frame_o_full) begin
                        frame_ix_rd = 'b1;

                        if (frame_ix[`PRGA_PKTCHAIN_PAYLOAD_INDEX] > 0) begin
                            state_next = STATE_FORWARD_X;
                        end
                    end
                end else if (!frame_iy_empty) begin
                    case (frame_iy[`PRGA_PKTCHAIN_MSG_TYPE_INDEX])
                        `PRGA_PKTCHAIN_MSG_TYPE_TEST,
                        `PRGA_PKTCHAIN_MSG_TYPE_DATA_ACK,
                        `PRGA_PKTCHAIN_MSG_TYPE_ERROR_UNKNOWN_MSG_TYPE,
                        `PRGA_PKTCHAIN_MSG_TYPE_ERROR_ECHO_MISMATCH,
                        `PRGA_PKTCHAIN_MSG_TYPE_ERROR_CHECKSUM_MISMATCH,
                        `PRGA_PKTCHAIN_MSG_TYPE_ERROR_FEEDTHRU_PACKET: begin
                            frame_o = frame_iy;
                            frame_o_wr = 'b1;
                            payload_next = frame_iy[`PRGA_PKTCHAIN_PAYLOAD_INDEX];

                            if (!frame_o_full) begin
                                frame_iy_rd = 'b1;

                                if (frame_iy[`PRGA_PKTCHAIN_PAYLOAD_INDEX] > 0) begin
                                    state_next = STATE_FORWARD_Y;
                                end
                            end
                        end
                        `PRGA_PKTCHAIN_MSG_TYPE_DATA,
                        `PRGA_PKTCHAIN_MSG_TYPE_DATA_INIT,
                        `PRGA_PKTCHAIN_MSG_TYPE_DATA_CHECKSUM,
                        `PRGA_PKTCHAIN_MSG_TYPE_DATA_INIT_CHECKSUM: begin
                            frame_o = 'b0;
                            frame_o[`PRGA_PKTCHAIN_MSG_TYPE_INDEX] = `PRGA_PKTCHAIN_MSG_TYPE_ERROR_FEEDTHRU_PACKET;
                            frame_o_wr = 'b1;
                            payload_next = frame_iy[`PRGA_PKTCHAIN_PAYLOAD_INDEX];

                            if (!frame_o_full) begin
                                frame_iy_rd = 'b1;

                                if (frame_iy[`PRGA_PKTCHAIN_PAYLOAD_INDEX] > 0) begin
                                    state_next = STATE_DUMP_Y;
                                end
                            end
                        end
                        default: begin
                            frame_o = 'b0;
                            frame_o[`PRGA_PKTCHAIN_MSG_TYPE_INDEX] = `PRGA_PKTCHAIN_MSG_TYPE_ERROR_UNKNOWN_MSG_TYPE;
                            frame_o_wr = 'b1;
                            payload_next = frame_iy[`PRGA_PKTCHAIN_PAYLOAD_INDEX];

                            if (!frame_o_full) begin
                                frame_iy_rd = 'b1;

                                if (frame_iy[`PRGA_PKTCHAIN_PAYLOAD_INDEX] > 0) begin
                                    state_next = STATE_DUMP_Y;
                                end
                            end
                        end
                    endcase
                end
            end
            STATE_FORWARD_X: begin
                frame_o = frame_ix;
                frame_ix_rd = !frame_o_full;
                frame_o_wr = !frame_ix_empty;

                if (!frame_ix_empty && !frame_o_full) begin
                    payload_next = payload - 1;

                    if (payload == 1) begin
                        state_next = STATE_IDLE;
                    end
                end
            end
            STATE_FORWARD_Y: begin
                frame_o = frame_iy;
                frame_iy_rd = !frame_o_full;
                frame_o_wr = !frame_iy_empty;

                if (!frame_iy_empty && !frame_o_full) begin
                    payload_next = payload - 1;

                    if (payload == 1) begin
                        state_next = STATE_IDLE;
                    end
                end
            end
            STATE_DUMP_Y: begin
                frame_iy_rd = 'b1;

                if (!frame_iy_empty) begin
                    payload_next = payload - 1;

                    if (payload == 1) begin
                        state_next = STATE_IDLE;
                    end
                end
            end
        endcase
    end

endmodule