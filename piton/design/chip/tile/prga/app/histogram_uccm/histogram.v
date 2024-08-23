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

`include "prga_system.vh"

module histogram_uccm (
    input wire                                      clk,
    input wire                                      rst_n,

    // == UREG Interface ==
    output wire                                     ureg_req_rdy,
    input wire                                      ureg_req_val,
    input wire [`PRGA_CREG_ADDR_WIDTH-1:0]          ureg_req_addr,
    input wire [`PRGA_CREG_DATA_BYTES-1:0]          ureg_req_strb,
    input wire [`PRGA_CREG_DATA_WIDTH-1:0]          ureg_req_data,

    input wire                                      ureg_resp_rdy,
    output reg                                      ureg_resp_val,
    output reg [`PRGA_CREG_DATA_WIDTH-1:0]          ureg_resp_data,
    output reg [`PRGA_ECC_WIDTH-1:0]                ureg_resp_ecc,

    // == Coherent Memory Interface ==
    input wire                                      uccm_req_rdy,
    output reg                                      uccm_req_val,
    output reg [`PRGA_CCM_REQTYPE_WIDTH-1:0]        uccm_req_type,
    output reg [`PRGA_CCM_ADDR_WIDTH-1:0]           uccm_req_addr,
    output reg [`PRGA_CCM_DATA_WIDTH-1:0]           uccm_req_data,
    output reg [`PRGA_CCM_SIZE_WIDTH-1:0]           uccm_req_size,
    output reg [`PRGA_CCM_THREADID_WIDTH-1:0]       uccm_req_threadid,
    output reg [`PRGA_CCM_AMO_OPCODE_WIDTH-1:0]     uccm_req_amo_opcode,
    output reg [`PRGA_ECC_WIDTH-1:0]                uccm_req_ecc,

    output reg                                      uccm_resp_rdy,
    input wire                                      uccm_resp_val,
    input wire [`PRGA_CCM_RESPTYPE_WIDTH-1:0]       uccm_resp_type,
    input wire [`PRGA_CCM_THREADID_WIDTH-1:0]       uccm_resp_threadid,
    input wire [`PRGA_CCM_CACHETAG_INDEX]           uccm_resp_addr,
    input wire [`PRGA_CCM_CACHELINE_WIDTH-1:0]      uccm_resp_data
    );

    // ========================================================
    // -- Input Buffer ----------------------------------------
    // ========================================================
    reg ureg_req_rdy_f;
    wire ureg_req_val_f;
    wire [`PRGA_CREG_ADDR_WIDTH-1:0] ureg_req_addr_f;
    wire [`PRGA_CREG_DATA_WIDTH-1:0] ureg_req_data_f;
    wire [`PRGA_CREG_DATA_BYTES-1:0] ureg_req_strb_f;

    prga_valrdy_buf #(
        .REGISTERED         (1)
        ,.DECOUPLED         (1)
        ,.DATA_WIDTH        (`PRGA_CREG_ADDR_WIDTH + `PRGA_CREG_DATA_WIDTH + `PRGA_CREG_DATA_BYTES)
    ) i_req_buf (
        .clk                (clk)
        ,.rst               (~rst_n)
        ,.rdy_o             (ureg_req_rdy)
        ,.val_i             (ureg_req_val)
        ,.data_i            ({ureg_req_addr, ureg_req_strb, ureg_req_data})
        ,.rdy_i             (ureg_req_rdy_f)
        ,.val_o             (ureg_req_val_f)
        ,.data_o            ({ureg_req_addr_f, ureg_req_strb_f, ureg_req_data_f})
        );

    // ========================================================
    // -- Core Control ----------------------------------------
    // ========================================================
    localparam  HIST_LOOKUP_BOUNDS      =   8;

    localparam  HIST_BASE_ADDR          =   12'h000,
                HIST_BIN_COUNT          =   12'h008,
                HIST_BIN_MIN            =   12'h010,
                HIST_BIN_WIDTH          =   12'h018,
                DATA_BASE_ADDR          =   12'h020,
                DATA_COUNT              =   12'h028,
                DATA_STRIDE             =   12'h030,
                START                   =   12'h038,
                RUNNING                 =   12'h040;

    reg [`PRGA_CCM_ADDR_WIDTH-1:0]  hist_base_addr, data_base_addr;

    reg [`PRGA_CREG_DATA_WIDTH-1:0] hist_bin_min, hist_bin_count, hist_bin_width, data_stride, data_count;
    reg [`PRGA_CREG_DATA_WIDTH-1:0] hist_bounds [0:HIST_LOOKUP_BOUNDS-1];

    reg finish, running;

    always @(posedge clk) begin
        if (~rst_n) begin
            running <= 1'b0;
        end else if (finish) begin
            running <= 1'b0;
        end else if (ureg_req_val_f && ureg_req_rdy_f && |ureg_req_strb_f && ureg_req_addr_f == START) begin
            running <= 1'b1;
        end
    end

    // ========================================================
    // -- Register Implementation -----------------------------
    // ========================================================

    always @(posedge clk) begin
        if (~rst_n) begin
            ureg_resp_val   <= 1'b0;
            ureg_resp_data  <= {`PRGA_CREG_DATA_WIDTH {1'b0} };

            hist_base_addr  <= {`PRGA_CCM_ADDR_WIDTH {1'b0} };
            data_base_addr  <= {`PRGA_CCM_ADDR_WIDTH {1'b0} };
            hist_bin_min    <= {`PRGA_CREG_DATA_WIDTH {1'b0} };
            hist_bin_count  <= {`PRGA_CREG_DATA_WIDTH {1'b0} };
            hist_bin_width  <= {`PRGA_CREG_DATA_WIDTH {1'b0} };
            data_stride     <= `PRGA_CREG_DATA_WIDTH'd1;
            data_count      <= {`PRGA_CREG_DATA_WIDTH {1'b0} };

            hist_bounds[0]  <= {`PRGA_CREG_DATA_WIDTH {1'b0} };
            hist_bounds[1]  <= {`PRGA_CREG_DATA_WIDTH {1'b0} };
            hist_bounds[2]  <= {`PRGA_CREG_DATA_WIDTH {1'b0} };
            hist_bounds[3]  <= {`PRGA_CREG_DATA_WIDTH {1'b0} };
            hist_bounds[4]  <= {`PRGA_CREG_DATA_WIDTH {1'b0} };
            hist_bounds[5]  <= {`PRGA_CREG_DATA_WIDTH {1'b0} };
            hist_bounds[6]  <= {`PRGA_CREG_DATA_WIDTH {1'b0} };
            hist_bounds[7]  <= {`PRGA_CREG_DATA_WIDTH {1'b0} };
        end else if (ureg_req_rdy_f && ureg_req_val_f) begin
            ureg_resp_val <= 1'b1;
            if (|ureg_req_strb_f) begin
                case (ureg_req_addr_f)
                    HIST_BASE_ADDR: begin
                        hist_base_addr <= ureg_req_data_f;
                    end
                    HIST_BIN_COUNT: begin
                        hist_bin_count <= ureg_req_data_f;
                    end
                    HIST_BIN_MIN: begin
                        hist_bin_min <= ureg_req_data_f;
                    end
                    HIST_BIN_WIDTH: begin
                        hist_bin_width <= ureg_req_data_f;

                        hist_bounds[0] <= hist_bin_min +                                                   ureg_req_data_f;
                        hist_bounds[1] <= hist_bin_min +                          (ureg_req_data_f << 1);
                        hist_bounds[2] <= hist_bin_min +                          (ureg_req_data_f << 1) + ureg_req_data_f;
                        hist_bounds[3] <= hist_bin_min + (ureg_req_data_f << 2);
                        hist_bounds[4] <= hist_bin_min + (ureg_req_data_f << 2) +                          ureg_req_data_f;
                        hist_bounds[5] <= hist_bin_min + (ureg_req_data_f << 2) + (ureg_req_data_f << 1);
                        hist_bounds[6] <= hist_bin_min + (ureg_req_data_f << 2) + (ureg_req_data_f << 1) + ureg_req_data_f;
                        hist_bounds[7] <= hist_bin_min + (ureg_req_data_f << 3);
                    end
                    DATA_BASE_ADDR: begin
                        data_base_addr <= ureg_req_data_f;
                    end
                    DATA_STRIDE: begin
                        data_stride <= ureg_req_data_f;
                    end
                    DATA_COUNT: begin
                        data_count <= ureg_req_data_f;
                    end
                endcase
            end else begin
                case (ureg_req_addr_f)
                    HIST_BASE_ADDR: begin
                        ureg_resp_data <= { {`PRGA_CREG_DATA_WIDTH {1'b0}}, hist_base_addr};
                    end
                    HIST_BIN_COUNT: begin
                        ureg_resp_data <= hist_bin_count;
                    end
                    HIST_BIN_MIN: begin
                        ureg_resp_data <= hist_bin_min;
                    end
                    HIST_BIN_WIDTH: begin
                        ureg_resp_data <= hist_bin_width;
                    end
                    DATA_BASE_ADDR: begin
                        ureg_resp_data <= data_base_addr;
                    end
                    DATA_STRIDE: begin
                        ureg_resp_data <= data_stride;
                    end
                    DATA_COUNT: begin
                        ureg_resp_data <= data_count;
                    end
                    RUNNING: begin
                        ureg_resp_data <= { {`PRGA_CREG_DATA_WIDTH {1'b0}}, running};
                    end
                endcase
            end
        end else if (ureg_resp_rdy) begin
            ureg_resp_val <= 1'b0;
        end
    end

    always @* begin
        ureg_req_rdy_f = ~ureg_resp_val || ureg_resp_rdy;
        ureg_resp_ecc = ~^ureg_resp_data;
    end

    // ========================================================
    // -- Memory Access ---------------------------------------
    // ========================================================

    localparam  MEMTHREAD_Q = `PRGA_CCM_THREADID_WIDTH'h1,
                MEMTHREAD_A = `PRGA_CCM_THREADID_WIDTH'h0;

    // == Request ==
    reg req_val_q, req_ack_q, req_val_a, req_ack_a;
    reg [`PRGA_CCM_ADDR_WIDTH-1:0] addr_q, addr_a;

    always @* begin
        uccm_req_val = 1'b0;
        uccm_req_type = {`PRGA_CCM_REQTYPE_WIDTH {1'b0} };
        uccm_req_addr = {`PRGA_CCM_ADDR_WIDTH {1'b0} };
        uccm_req_data = {`PRGA_CCM_DATA_WIDTH {1'b0} };;
        uccm_req_size = `PRGA_CCM_SIZE_8B;
        uccm_req_threadid = MEMTHREAD_A;
        uccm_req_amo_opcode = `PRGA_CCM_AMO_OPCODE_NONE;
        req_ack_q = 1'b0;
        req_ack_a = 1'b0;

        if (req_val_a) begin
            uccm_req_val = 1'b1;
            uccm_req_type = `PRGA_CCM_REQTYPE_AMO;
            uccm_req_addr = addr_a;
            uccm_req_data = `PRGA_CCM_DATA_WIDTH'h01000000_00000000;
            // uccm_req_data = `PRGA_CCM_DATA_WIDTH'h1;
            uccm_req_amo_opcode = `PRGA_CCM_AMO_OPCODE_ADD;

            req_ack_a = uccm_req_rdy;
        end else if (req_val_q) begin
            uccm_req_val = 1'b1;
            uccm_req_type = `PRGA_CCM_REQTYPE_LOAD;
            uccm_req_addr = addr_q;
            uccm_req_threadid = MEMTHREAD_Q;

            req_ack_q = uccm_req_rdy;
        end
    end

    always @* begin
        uccm_req_ecc = ~^{uccm_req_type, uccm_req_addr, uccm_req_data, uccm_req_size, uccm_req_threadid, uccm_req_amo_opcode};
    end

    // == Response ==
    reg resp_val_d, resp_rdy_d, resp_val_c, resp_rdy_c, resp_data_qword_sel_d;
    reg [`PRGA_CCM_DATA_WIDTH-1:0] resp_data_d;

    always @(posedge clk) begin
        if (~rst_n) begin
            resp_val_d <= 1'b0;
            resp_data_d <= 1'b0;
            resp_data_qword_sel_d <= 1'b0;
            resp_val_c <= 1'b0;
        end else begin
            if (uccm_req_rdy && uccm_req_val && uccm_req_threadid == MEMTHREAD_Q) begin
                resp_data_qword_sel_d <= uccm_req_addr[3];
            end

            if (uccm_resp_rdy && uccm_resp_val && uccm_resp_threadid == MEMTHREAD_Q) begin
                resp_val_d <= 1'b1;

                if (resp_data_qword_sel_d) begin
                    resp_data_d <= {uccm_resp_data[64+:8], uccm_resp_data[72+:8], uccm_resp_data[80+:8], uccm_resp_data[88+:8],
                        uccm_resp_data[96+:8], uccm_resp_data[104+:8], uccm_resp_data[112+:8], uccm_resp_data[120+:8]};
                end else begin
                    resp_data_d <= {uccm_resp_data[0+:8], uccm_resp_data[8+:8], uccm_resp_data[16+:8], uccm_resp_data[24+:8],
                        uccm_resp_data[32+:8], uccm_resp_data[40+:8], uccm_resp_data[48+:8], uccm_resp_data[56+:8]};
                end
                // resp_data_d <= uccm_resp_data;
            end else if (resp_rdy_d) begin
                resp_val_d <= 1'b0;
            end

            if (uccm_resp_rdy && uccm_resp_val && uccm_resp_threadid == MEMTHREAD_A) begin
                resp_val_c <= 1'b1;
            end else if (resp_rdy_c) begin
                resp_val_c <= 1'b0;
            end
        end
    end

    always @* begin
        uccm_resp_rdy = 1'b1;

        if (uccm_resp_threadid == MEMTHREAD_Q) begin
            uccm_resp_rdy = ~resp_val_d || resp_rdy_d;
        end else if (uccm_resp_threadid == MEMTHREAD_A) begin
            uccm_resp_rdy = ~resp_val_c || resp_rdy_c;
        end
    end

    // ========================================================
    // -- Histogram Sorting Pipeline --------------------------
    // ========================================================

    // == Forward declaration ==
    reg stall_q, stall_d, stall_x, stall_a, stall_c;

    // == Stage Q: data reQuest ==
    reg val_d_next, last_q;
    reg [`PRGA_CREG_DATA_WIDTH-1:0] data_index_q;

    always @(posedge clk) begin
        if (~rst_n) begin
            data_index_q <= {`PRGA_CREG_DATA_WIDTH {1'b0} };
            addr_q <= {`PRGA_CCM_ADDR_WIDTH {1'b0} };
        end else if (running) begin
            if (data_index_q < data_count && ~stall_q) begin
                data_index_q <= data_index_q + 1;
                addr_q <= addr_q + (data_stride << 3);
            end
        end else begin
            data_index_q <= {`PRGA_CREG_DATA_WIDTH {1'b0} };
            addr_q <= data_base_addr;
        end
    end

    always @* begin
        val_d_next = 1'b0;
        stall_q = 1'b1;

        req_val_q = 1'b0;
        last_q = data_index_q + 1 == data_count;

        if (running && data_index_q < data_count && ~stall_d) begin
            req_val_q = 1'b1;
            val_d_next = req_ack_q;
            stall_q = ~req_ack_q;
        end
    end

    // == Stage D: Data response ==
    reg val_d, last_d, val_x_next;
    reg [`PRGA_CREG_DATA_WIDTH-1:0] data_x_next;

    always @(posedge clk) begin
        if (~rst_n) begin
            val_d <= 1'b0;
            last_d <= 1'b0;
        end else if (~(stall_x || (val_d && ~resp_val_d))) begin
            val_d <= val_d_next;
            last_d <= last_q;
        end
    end

    reg val_x, val_a, val_c;

    always @* begin
        stall_d = stall_x || (val_d && ~resp_val_d) || val_d || val_x || val_a || val_c;
        resp_rdy_d = val_d && ~stall_x;
        val_x_next = val_d && resp_val_d;
        data_x_next = resp_data_d;
    end

    // == Stage X: eXecute ==
    reg last_x, val_a_next, done_x;
    reg [`PRGA_CREG_DATA_WIDTH-1:0] data_x, hist_index_a_next, hist_index_a_next_f;

    always @(posedge clk) begin
        if (~rst_n) begin
            val_x <= 1'b0;
            last_x <= 1'b0;
            data_x <= {`PRGA_CREG_DATA_WIDTH {1'b0} };
            hist_index_a_next_f <= {`PRGA_CREG_DATA_WIDTH {1'b0} };
        end else if (~stall_x) begin
            val_x <= val_x_next;
            last_x <= last_d;
            data_x <= data_x_next;
            hist_index_a_next_f <= {`PRGA_CREG_DATA_WIDTH {1'b0} };
        end else if (val_x && ~done_x) begin
            data_x <= data_x - (hist_bin_width << 3);
            hist_index_a_next_f <= hist_index_a_next_f + 8;
        end
    end

    always @* begin
        stall_x = stall_a;
        done_x = 1'b0;
        val_a_next = 1'b0;
        hist_index_a_next = {`PRGA_CREG_DATA_WIDTH {1'b0} };

        if (val_x) begin
            if (data_x < hist_bin_min) begin
                stall_x = stall_a;
                done_x = 1'b1;
            end
            else if (data_x < hist_bounds[0]) begin
                stall_x = stall_a;
                done_x = 1'b1;
                val_a_next = 1'b1;
                hist_index_a_next = hist_index_a_next_f;
            end
            else if (data_x < hist_bounds[1]) begin
                stall_x = stall_a;
                done_x = 1'b1;
                val_a_next = 1'b1;
                hist_index_a_next = hist_index_a_next_f + 1;
            end
            else if (data_x < hist_bounds[2]) begin
                stall_x = stall_a;
                done_x = 1'b1;
                val_a_next = 1'b1;
                hist_index_a_next = hist_index_a_next_f + 2;
            end
            else if (data_x < hist_bounds[3]) begin
                stall_x = stall_a;
                done_x = 1'b1;
                val_a_next = 1'b1;
                hist_index_a_next = hist_index_a_next_f + 3;
            end
            else if (data_x < hist_bounds[4]) begin
                stall_x = stall_a;
                done_x = 1'b1;
                val_a_next = 1'b1;
                hist_index_a_next = hist_index_a_next_f + 4;
            end
            else if (data_x < hist_bounds[5]) begin
                stall_x = stall_a;
                done_x = 1'b1;
                val_a_next = 1'b1;
                hist_index_a_next = hist_index_a_next_f + 5;
            end
            else if (data_x < hist_bounds[6]) begin
                stall_x = stall_a;
                done_x = 1'b1;
                val_a_next = 1'b1;
                hist_index_a_next = hist_index_a_next_f + 6;
            end
            else if (data_x < hist_bounds[7]) begin
                stall_x = stall_a;
                done_x = 1'b1;
                val_a_next = 1'b1;
                hist_index_a_next = hist_index_a_next_f + 7;
            end else begin
                stall_x = 1'b1;
                done_x = 1'b0;
            end
        end
    end

    // == Stage A: Atomic Addition ==
    reg last_a, val_c_next;
    reg [`PRGA_CREG_DATA_WIDTH-1:0] hist_index_a;

    always @(posedge clk) begin
        if (~rst_n) begin
            val_a <= 1'b0;
            last_a <= 1'b0;
            hist_index_a <= {`PRGA_CREG_DATA_BYTES {1'b0} };
        end else if (~stall_a) begin
            val_a <= val_a_next;
            last_a <= last_x;
            hist_index_a <= hist_index_a_next;
        end
    end

    always @* begin
        req_val_a = 1'b0;
        addr_a = hist_base_addr + (hist_index_a << 3);
        stall_a = stall_c;
        val_c_next = 1'b0;

        if (val_a && ~stall_c) begin
            req_val_a = 1'b1;
            stall_a = ~req_ack_a;
            val_c_next = req_ack_a;
        end
    end

    // == Stage C: Commit ==
    reg last_c;

    always @(posedge clk) begin
        if (~rst_n) begin
            val_c <= 1'b0;
            last_c <= 1'b0;
        end else if (~stall_c) begin
            val_c <= val_c_next;
            last_c <= last_a;
        end
    end

    always @* begin
        stall_c = val_c && ~resp_val_c;
        resp_rdy_c = val_c;
        finish = val_c && last_c && resp_val_c;
    end

endmodule
