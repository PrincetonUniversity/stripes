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
module pktchain_router (
    input wire [0:0] prog_clk,
    input wire [0:0] prog_rst,

    // noc inputs
    output wire [0:0] phit_i_full,
    input wire [0:0] phit_i_wr,
    input wire [`PRGA_PKTCHAIN_PHIT_WIDTH - 1:0] phit_i,

    // noc outputs
    input wire [0:0] phit_o_full,
    output wire [0:0] phit_o_wr,
    output wire [`PRGA_PKTCHAIN_PHIT_WIDTH - 1:0] phit_o,

    // chain inputs & outputs
    input wire [0:0] prog_we,
    input wire [`PRGA_PKTCHAIN_CHAIN_WIDTH-1:0] prog_din,

    output wire [0:0] prog_we_o,
    output wire [`PRGA_PKTCHAIN_CHAIN_WIDTH-1:0] prog_dout
    );

    // register reset signal
    reg prog_rst_f;

    always @(posedge prog_clk) begin
        prog_rst_f <= prog_rst;
    end

    // Physical-level protocol:
    //  phit size = PRGA_PKTCHAIN_PHIT_WIDTH
    //
    // Link-level protocol:
    //  frame size = 32b (e.g. 4 phits if PRGA_PKTCHAIN_PHIT_WIDTH == 8)
    //
    // Data-level protocol:
    //  header frame:
    //      8b: message type
    //      8b: branch ID
    //      8b: leaf ID
    //      8b: payload size (#frames)
    
    

    wire frame_i_empty, frame_o_full, frame_clasp_rd;
    wire [`PRGA_PKTCHAIN_FRAME_SIZE - 1:0] frame_i;
    reg [`PRGA_PKTCHAIN_FRAME_SIZE - 1:0] frame_o;
    reg frame_i_rd, frame_o_wr, frame_clasp_empty;
    reg clasp_init, clasp_checksum;
    wire clasp_programming, clasp_echo_mismatch, clasp_checksum_mismatch;

    pktchain_frame_assemble #(
        .DEPTH_LOG2                 (`PRGA_PKTCHAIN_ROUTER_FIFO_DEPTH_LOG2)
    ) ififo (
        .prog_clk       (prog_clk)
        ,.prog_rst      (prog_rst_f)
        ,.phit_full     (phit_i_full)
        ,.phit_wr       (phit_i_wr)
        ,.phit_i        (phit_i)
        ,.frame_empty   (frame_i_empty)
        ,.frame_rd      (frame_i_rd)
        ,.frame_o       (frame_i)
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

    pktchain_clasp clasp (
        .prog_clk           (prog_clk)
        ,.prog_rst          (prog_rst_f)
        ,.frame_empty       (frame_clasp_empty)
        ,.frame_rd          (frame_clasp_rd)
        ,.frame_i           (frame_i)
        ,.ctrl_init         (clasp_init)
        ,.ctrl_checksum     (clasp_checksum)
        ,.programming       (clasp_programming)
        ,.echo_mismatch     (clasp_echo_mismatch)
        ,.checksum_mismatch (clasp_checksum_mismatch)
        ,.prog_we           (prog_we)
        ,.prog_din          (prog_din)
        ,.prog_we_o         (prog_we_o)
        ,.prog_dout         (prog_dout)
        );

    localparam  STATE_RESET                     = 4'h0,
                STATE_IDLE                      = 4'h1,
                STATE_CLASP                     = 4'h2,
                STATE_FORWARDING                = 4'h3,
                STATE_DUMPING                   = 4'h4;

    reg [3:0] state, state_next;
    reg [`PRGA_PKTCHAIN_PAYLOAD_WIDTH - 1:0] payload;
    reg checksum_pending, checksum_checked;
    reg payload_rst, start_clasp_trx;

    always @(posedge prog_clk) begin
        if (prog_rst_f) begin
            state <= STATE_RESET;
            payload <= 'b0;
            checksum_pending <= 'b0;
            clasp_init <= 'b0;
        end else begin
            state <= state_next;

            if (payload_rst) begin
                payload <= frame_i[`PRGA_PKTCHAIN_PAYLOAD_INDEX];
            end else if (payload > 0 && !frame_i_empty && frame_i_rd) begin
                payload <= payload - 1;
            end

            if (start_clasp_trx) begin
                clasp_init <= (frame_i[`PRGA_PKTCHAIN_MSG_TYPE_INDEX] == `PRGA_PKTCHAIN_MSG_TYPE_DATA_INIT ||
                              frame_i[`PRGA_PKTCHAIN_MSG_TYPE_INDEX] == `PRGA_PKTCHAIN_MSG_TYPE_DATA_INIT_CHECKSUM);
            end else if (!frame_clasp_empty && frame_clasp_rd) begin
                clasp_init <= 'b0;
            end

            if (start_clasp_trx) begin
                checksum_pending <= (frame_i[`PRGA_PKTCHAIN_MSG_TYPE_INDEX] == `PRGA_PKTCHAIN_MSG_TYPE_DATA_CHECKSUM ||
                                    frame_i[`PRGA_PKTCHAIN_MSG_TYPE_INDEX] == `PRGA_PKTCHAIN_MSG_TYPE_DATA_INIT_CHECKSUM);
            end else if (checksum_checked) begin
                checksum_pending <= 'b0;
            end
        end
    end

    always @* begin
        state_next = state;
        frame_i_rd = 'b0;
        frame_o_wr = 'b0;
        frame_o = frame_i;
        frame_clasp_empty = 'b1;
        payload_rst = 'b0;
        clasp_checksum = 'b0;
        checksum_checked = 'b0;
        start_clasp_trx = 'b0;

        case (state)
            STATE_RESET: begin
                state_next = STATE_IDLE;
            end
            STATE_IDLE: begin
                if (checksum_pending && ~clasp_programming) begin
                    frame_o_wr = 'b1;
                    frame_o = 'b0;
                    frame_o[`PRGA_PKTCHAIN_MSG_TYPE_INDEX] = (
                            clasp_echo_mismatch ? `PRGA_PKTCHAIN_MSG_TYPE_ERROR_ECHO_MISMATCH :
                        clasp_checksum_mismatch ? `PRGA_PKTCHAIN_MSG_TYPE_ERROR_CHECKSUM_MISMATCH :
                                                  `PRGA_PKTCHAIN_MSG_TYPE_DATA_ACK );
                    checksum_checked = ~frame_o_full;
                end else if (~frame_i_empty) begin  // valid input frame
                    case (frame_i[`PRGA_PKTCHAIN_MSG_TYPE_INDEX])
                        `PRGA_PKTCHAIN_MSG_TYPE_DATA,
                        `PRGA_PKTCHAIN_MSG_TYPE_DATA_INIT,
                        `PRGA_PKTCHAIN_MSG_TYPE_DATA_CHECKSUM,
                        `PRGA_PKTCHAIN_MSG_TYPE_DATA_INIT_CHECKSUM: begin
                            if (frame_i[`PRGA_PKTCHAIN_LEAF_ID_INDEX] == 0) begin    // this message is for me
                                if (~checksum_pending) begin        // only react if I'm not waiting for the checksum
                                    state_next = STATE_CLASP;
                                    frame_i_rd = 'b1;               // discard message header
                                    payload_rst = 'b1;
                                    start_clasp_trx = 'b1;
                                end
                            end else begin                          // this message is not for me
                                if (~frame_o_full) begin
                                    frame_i_rd = 'b1;
                                    state_next = STATE_FORWARDING;
                                end

                                frame_o_wr = 'b1;
                                frame_o = frame_i - (1 << `PRGA_PKTCHAIN_LEAF_ID_BASE);
                                payload_rst = 'b1;
                            end
                        end
                        `PRGA_PKTCHAIN_MSG_TYPE_TEST,
                        `PRGA_PKTCHAIN_MSG_TYPE_DATA_ACK,
                        `PRGA_PKTCHAIN_MSG_TYPE_ERROR_UNKNOWN_MSG_TYPE,
                        `PRGA_PKTCHAIN_MSG_TYPE_ERROR_ECHO_MISMATCH,
                        `PRGA_PKTCHAIN_MSG_TYPE_ERROR_CHECKSUM_MISMATCH: begin
                            if (~frame_o_full) begin
                                frame_i_rd = 'b1;
                            end

                            frame_o_wr = 'b1;
                            frame_o = frame_i + (1 << `PRGA_PKTCHAIN_LEAF_ID_BASE);
                        end
                        default: begin
                            if (~frame_o_full) begin
                                frame_i_rd = 'b1;

                                if (frame_i[`PRGA_PKTCHAIN_PAYLOAD_INDEX] > 0) begin
                                    state_next = STATE_DUMPING;
                                end
                            end

                            frame_o_wr = 'b1;
                            frame_o = 'b0;
                            frame_o[`PRGA_PKTCHAIN_MSG_TYPE_INDEX] = `PRGA_PKTCHAIN_MSG_TYPE_ERROR_UNKNOWN_MSG_TYPE;
                            payload_rst = 'b1;
                        end
                    endcase
                end
            end
            STATE_CLASP: begin
                frame_i_rd = frame_clasp_rd;
                frame_clasp_empty = frame_i_empty;
                clasp_checksum = checksum_pending && payload == 1;

                if (payload == 1 && !frame_i_empty && frame_clasp_rd) begin
                    state_next = STATE_IDLE;
                end
            end
            STATE_FORWARDING: begin
                if (payload == 1 && !frame_i_empty && !frame_o_full) begin
                    state_next = STATE_IDLE;
                end

                frame_o_wr = !frame_i_empty;
                frame_i_rd = !frame_o_full;
            end
            STATE_DUMPING: begin
                if (payload == 1 && !frame_i_empty) begin
                    state_next = STATE_IDLE;
                end

                frame_i_rd = 'b1;
            end
        endcase
    end

endmodule