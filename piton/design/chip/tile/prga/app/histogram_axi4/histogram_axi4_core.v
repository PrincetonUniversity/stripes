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

module histogram_axi4_core (
    input wire                                      clk,
    input wire                                      rst_n,

    // == UREG Interface ==
    output reg                                      ureg_req_rdy,
    input wire                                      ureg_req_val,
    input wire [`PRGA_CREG_ADDR_WIDTH-1:0]          ureg_req_addr,
    input wire [`PRGA_CREG_DATA_BYTES-1:0]          ureg_req_strb,
    input wire [`PRGA_CREG_DATA_WIDTH-1:0]          ureg_req_data,

    input wire                                      ureg_resp_rdy,
    output reg                                      ureg_resp_val,
    output reg [`PRGA_CREG_DATA_WIDTH-1:0]          ureg_resp_data,

    // == AXI4 Master Interface ==
    // -- AW channel --
    input wire                                      awready,
    output wire                                     awvalid,
    output wire [`PRGA_AXI4_ID_WIDTH-1:0]           awid,
    output wire [`PRGA_AXI4_ADDR_WIDTH-1:0]         awaddr,
    output wire [`PRGA_AXI4_AXLEN_WIDTH-1:0]        awlen,
    output wire [`PRGA_AXI4_AXSIZE_WIDTH-1:0]       awsize,
    output wire [`PRGA_AXI4_AXBURST_WIDTH-1:0]      awburst,

    // non-standard use of AWCACHE: Only |AWCACHE[3:2] is checked: 1'b1: cacheable; 1'b0: non-cacheable
    output wire [`PRGA_AXI4_AXCACHE_WIDTH-1:0]      awcache,

    // -- W channel --
    input wire                                      wready,
    output wire                                     wvalid,
    output wire [`PRGA_AXI4_DATA_WIDTH-1:0]         wdata,
    output wire [`PRGA_AXI4_DATA_BYTES-1:0]         wstrb,
    output wire                                     wlast,

    // -- B channel --
    output wire                                     bready,
    input wire                                      bvalid,
    input wire [`PRGA_AXI4_XRESP_WIDTH-1:0]         bresp,
    input wire [`PRGA_AXI4_ID_WIDTH-1:0]            bid,

    // -- AR channel --
    input wire                                      arready,
    output reg                                      arvalid,
    output reg [`PRGA_AXI4_ID_WIDTH-1:0]            arid,
    output reg [`PRGA_AXI4_ADDR_WIDTH-1:0]          araddr,
    output reg [`PRGA_AXI4_AXLEN_WIDTH-1:0]         arlen,
    output reg [`PRGA_AXI4_AXSIZE_WIDTH-1:0]        arsize,
    output reg [`PRGA_AXI4_AXBURST_WIDTH-1:0]       arburst,

    // non-standard use of ARLOCK: indicates an atomic operation.
    // Type of the atomic operation is specified in the ARUSER field
    output reg                                      arlock,

    // non-standard use of ARCACHE: Only |ARCACHE[3:2] is checked: 1'b1: cacheable; 1'b0: non-cacheable
    output reg [`PRGA_AXI4_AXCACHE_WIDTH-1:0]       arcache,

    // ATOMIC operation type, data:
    output reg [`PRGA_CCM_AMO_OPCODE_WIDTH-1:0]     aramo_opcode,
    output reg [`PRGA_CCM_DATA_WIDTH-1:0]           aramo_data,

    // -- R channel --
    output reg                                      rready,
    input wire                                      rvalid,
    input wire [`PRGA_AXI4_XRESP_WIDTH-1:0]         rresp,
    input wire [`PRGA_AXI4_ID_WIDTH-1:0]            rid,
    input wire [`PRGA_AXI4_DATA_WIDTH-1:0]          rdata,
    input wire                                      rlast
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

    reg [`PRGA_AXI4_ADDR_WIDTH-1:0] hist_base_addr, data_base_addr;

    reg [`PRGA_CREG_DATA_WIDTH-1:0] hist_bin_min, hist_bin_count, hist_bin_width, data_stride, data_count;
    reg [`PRGA_CREG_DATA_WIDTH-1:0] hist_bounds [0:HIST_LOOKUP_BOUNDS-1];

    reg finish, running;

    always @(posedge clk) begin
        if (~rst_n) begin
            running <= 1'b0;
        end else if (finish) begin
            running <= 1'b0;
        end else if (ureg_req_val && ureg_req_rdy && |ureg_req_strb && ureg_req_addr == START) begin
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

            hist_base_addr  <= {`PRGA_AXI4_ADDR_WIDTH {1'b0} };
            data_base_addr  <= {`PRGA_AXI4_ADDR_WIDTH {1'b0} };
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
        end else if (ureg_req_rdy && ureg_req_val) begin
            ureg_resp_val <= 1'b1;

            if (|ureg_req_strb) begin
                case (ureg_req_addr)
                    HIST_BASE_ADDR: begin
                        hist_base_addr <= ureg_req_data;
                    end
                    HIST_BIN_COUNT: begin
                        hist_bin_count <= ureg_req_data;
                    end
                    HIST_BIN_MIN: begin
                        hist_bin_min <= ureg_req_data;

                        hist_bounds[0] <= ureg_req_data +                                                 hist_bin_width;
                        hist_bounds[1] <= ureg_req_data +                         (hist_bin_width << 1);
                        hist_bounds[2] <= ureg_req_data +                         (hist_bin_width << 1) + hist_bin_width;
                        hist_bounds[3] <= ureg_req_data + (hist_bin_width << 2);
                        hist_bounds[4] <= ureg_req_data + (hist_bin_width << 2) +                         hist_bin_width;
                        hist_bounds[5] <= ureg_req_data + (hist_bin_width << 2) + (hist_bin_width << 1);
                        hist_bounds[6] <= ureg_req_data + (hist_bin_width << 2) + (hist_bin_width << 1) + hist_bin_width;
                        hist_bounds[7] <= ureg_req_data + (hist_bin_width << 3);
                    end
                    HIST_BIN_WIDTH: begin
                        hist_bin_width <= ureg_req_data;

                        hist_bounds[0] <= hist_bin_min +                                               ureg_req_data;
                        hist_bounds[1] <= hist_bin_min +                        (ureg_req_data << 1);
                        hist_bounds[2] <= hist_bin_min +                        (ureg_req_data << 1) + ureg_req_data;
                        hist_bounds[3] <= hist_bin_min + (ureg_req_data << 2);
                        hist_bounds[4] <= hist_bin_min + (ureg_req_data << 2) +                        ureg_req_data;
                        hist_bounds[5] <= hist_bin_min + (ureg_req_data << 2) + (ureg_req_data << 1);
                        hist_bounds[6] <= hist_bin_min + (ureg_req_data << 2) + (ureg_req_data << 1) + ureg_req_data;
                        hist_bounds[7] <= hist_bin_min + (ureg_req_data << 3);
                    end
                    DATA_BASE_ADDR: begin
                        data_base_addr <= ureg_req_data;
                    end
                    DATA_STRIDE: begin
                        data_stride <= ureg_req_data;
                    end
                    DATA_COUNT: begin
                        data_count <= ureg_req_data;
                    end
                endcase
            end else begin
                case (ureg_req_addr)
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
        ureg_req_rdy = ~ureg_resp_val || ureg_resp_rdy;
    end

    // ========================================================
    // -- AXI4 Channels ---------------------------------------
    // ========================================================
    // AW, W, and B are unused
    assign awvalid = 1'b0;
    assign awid = {`PRGA_AXI4_ID_WIDTH {1'b0} };
    assign awaddr = {`PRGA_AXI4_ADDR_WIDTH {1'b0} };
    assign awlen = {`PRGA_AXI4_AXLEN_WIDTH {1'b0} };
    assign awsize = {`PRGA_AXI4_AXSIZE_WIDTH {1'b0} };
    assign awburst = {`PRGA_AXI4_AXBURST_WIDTH {1'b0} };
    assign awcache = {`PRGA_AXI4_AXCACHE_WIDTH {1'b0} };
    assign wvalid = 1'b0;
    assign wdata = {`PRGA_AXI4_DATA_WIDTH {1'b0} };
    assign wstrb = {`PRGA_AXI4_DATA_BYTES {1'b0} };
    assign wlast = 1'b0;
    assign bready = 1'b0;

    localparam  MEMTHREAD_Q = `PRGA_AXI4_ID_WIDTH'h1,
                MEMTHREAD_A = `PRGA_AXI4_ID_WIDTH'h0;

    // == Request ==
    reg req_val_q, req_ack_q, req_val_a, req_ack_a;
    reg [`PRGA_AXI4_ADDR_WIDTH-1:0] addr_q, addr_a;

    always @* begin
        arvalid = 1'b0;
        arid = MEMTHREAD_A;
        araddr = addr_a;
        arlen = {`PRGA_AXI4_AXLEN_WIDTH {1'b0} };
        arsize = `PRGA_AXI4_AXSIZE_8B;
        arburst = `PRGA_AXI4_AXBURST_INCR;
        arlock = 1'b1;
        arcache = `PRGA_AXI4_AXCACHE_DEV_NB;
        aramo_opcode = `PRGA_CCM_AMO_OPCODE_ADD;
        aramo_data = `PRGA_CCM_DATA_WIDTH'h00000000_00000001;

        req_ack_q = 1'b0;
        req_ack_a = 1'b0;

        if (req_val_a) begin
            arvalid = 1'b1;
            req_ack_a = arready;
        end else if (req_val_q) begin
            arvalid = 1'b1;
            arid = MEMTHREAD_Q;
            araddr = addr_q;
            arlock = 1'b0;
            arcache = `PRGA_AXI4_ARCACHE_WB_ALCT;
            req_ack_q = arready;
        end
    end

    // == Response ==
    reg resp_val_d, resp_rdy_d, resp_val_c, resp_rdy_c;
    reg [`PRGA_AXI4_DATA_WIDTH-1:0] resp_data_d;

    always @(posedge clk) begin
        if (~rst_n) begin
            resp_val_d <= 1'b0;
            resp_data_d <= 1'b0;
            resp_val_c <= 1'b0;
        end else begin
            if (rready && rvalid && rid == MEMTHREAD_Q) begin
                resp_val_d <= 1'b1;
                resp_data_d <= rdata;
            end else if (resp_rdy_d) begin
                resp_val_d <= 1'b0;
            end

            if (rready && rvalid && rid == MEMTHREAD_A) begin
                resp_val_c <= 1'b1;
            end else if (resp_rdy_c) begin
                resp_val_c <= 1'b0;
            end
        end
    end

    always @* begin
        rready = 1'b1;

        if (rid == MEMTHREAD_Q) begin
            rready = ~resp_val_d || resp_rdy_d;
        end else if (rid == MEMTHREAD_A) begin
            rready = ~resp_val_c || resp_rdy_c;
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
