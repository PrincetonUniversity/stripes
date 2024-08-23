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

module vx3p1_cfg (
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

    // == Configuration Signals ==
    input wire                                      finish,
    output wire                                     start,
    output reg [`PRGA_AXI4_ADDR_WIDTH-1:0]          src_base_addr,
    output reg [`PRGA_AXI4_ADDR_WIDTH-1:0]          dst_base_addr,
    output reg [`PRGA_CREG_DATA_WIDTH-1:0]          vlen
    );

    localparam  SRC_BASE_ADDR           =   12'h000,    // WR
                DST_BASE_ADDR           =   12'h008,    // WR
                VLEN                    =   12'h010,    // WR
                START                   =   12'h018,    // WO
                RUNNING                 =   12'h020;    // RO

    reg running;

    always @(posedge clk) begin
        if (~rst_n) begin
            running     <= 1'b0;
        end else if (finish) begin
            running     <= 1'b0;
        end else if (start) begin
            running     <= 1'b1;
        end
    end

    // ========================================================
    // -- Register Implementation -----------------------------
    // ========================================================
    // write
    always @(posedge clk) begin
        if (~rst_n) begin
            src_base_addr   <= {`PRGA_AXI4_ADDR_WIDTH {1'b0} };
            dst_base_addr   <= {`PRGA_AXI4_ADDR_WIDTH {1'b0} };
            vlen            <= {`PRGA_CREG_DATA_WIDTH {1'b0} };
        end else if (ureg_req_rdy && ureg_req_val) begin
            if (|ureg_req_strb) begin
                case (ureg_req_addr)
                    SRC_BASE_ADDR: begin
                        src_base_addr   <= ureg_req_data;
                    end
                    DST_BASE_ADDR: begin
                        dst_base_addr   <= ureg_req_data;
                    end
                    VLEN: begin
                        vlen            <= ureg_req_data;
                    end
                endcase
            end
        end
    end

    assign start = ureg_req_rdy && ureg_req_val && |ureg_req_strb && ureg_req_addr == START;

    // read
    always @* begin
        ureg_req_rdy = ureg_resp_rdy;
        ureg_resp_val = ureg_req_val;
        ureg_resp_data = {`PRGA_CREG_DATA_WIDTH {1'b0} };

        if (ureg_req_val && ~|ureg_req_strb) begin
            case (ureg_req_addr)
                SRC_BASE_ADDR:  ureg_resp_data = src_base_addr;
                DST_BASE_ADDR:  ureg_resp_data = dst_base_addr;
                VLEN:           ureg_resp_data = vlen;
                RUNNING:        ureg_resp_data[0] = running;
            endcase
        end
    end

endmodule
