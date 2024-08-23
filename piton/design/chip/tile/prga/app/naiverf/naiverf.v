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
module naiverf (
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

    // Tie unused ports
    always @* begin
        uccm_req_val        = 1'b0;
		uccm_req_type	    = {`PRGA_CCM_REQTYPE_WIDTH {1'b0} };
		uccm_req_addr	    = {`PRGA_CCM_ADDR_WIDTH {1'b0} };
		uccm_req_data	    = {`PRGA_CCM_DATA_WIDTH {1'b0} };
		uccm_req_size	    = {`PRGA_CCM_SIZE_WIDTH {1'b0} };
		uccm_req_threadid	= {`PRGA_CCM_THREADID_WIDTH {1'b0} };
		uccm_req_amo_opcode	= {`PRGA_CCM_AMO_OPCODE_WIDTH {1'b0} };
		uccm_req_ecc	    = {`PRGA_ECC_WIDTH {1'b0} };
        uccm_resp_rdy       = 1'b0;
    end

    // Request Buffer
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

    // Response Buffer
    wire ureg_resp_rdy_f;
    reg ureg_resp_val_f;
    reg [`PRGA_CREG_DATA_WIDTH-1:0] ureg_resp_data_f;
    reg [`PRGA_ECC_WIDTH-1:0] ureg_resp_ecc_f;

    prga_valrdy_buf #(
        .REGISTERED         (1)
        ,.DECOUPLED         (1)
        ,.DATA_WIDTH        (`PRGA_CREG_DATA_WIDTH + `PRGA_ECC_WIDTH)
    ) i_resp_buf (
        .clk                (clk)
        ,.rst               (~rst_n)
        ,.rdy_o             (ureg_resp_rdy_f)
        ,.val_i             (ureg_resp_val_f)
        ,.data_i            ({ureg_resp_data_f, ureg_resp_ecc_f})
        ,.rdy_i             (ureg_resp_rdy)
        ,.val_o             (ureg_resp_val)
        ,.data_o            ({ureg_resp_data, ureg_resp_ecc})
        );

    // Memory (make sure it's inferred as BRAM)
    reg [`PRGA_CREG_DATA_WIDTH - 1:0]   mem     [0:63];     // 64 generic registers

    always @(posedge clk) begin
        if (ureg_req_rdy_f && ureg_req_val_f && (&ureg_req_strb_f) && ureg_req_addr_f[2:0] == 3'b0) begin
            mem[ureg_req_addr_f[8:3]] <= ureg_req_data_f;
        end

        ureg_resp_data_f <= mem[ureg_req_addr_f[8:3]];
    end

    // handle request: pipelined
    always @* begin
        ureg_req_rdy_f = ureg_resp_rdy_f;
        ureg_resp_ecc_f = ~^ureg_resp_data_f;
    end

    always @(posedge clk) begin
        if (~rst_n) begin
            ureg_resp_val_f <= 1'b0;
        end else if (~ureg_resp_val_f || ureg_resp_rdy_f) begin
            ureg_resp_val_f <= ureg_req_rdy_f && ureg_req_val_f;
        end else begin
            ureg_resp_val_f <= ureg_resp_val_f;
        end
    end

endmodule
