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
`timescale 1ns/1ps

/*
* Cache-coherent memory transducer.
*/

`include "prga_system.vh"

module prga_ccm_transducer (
    input wire                                  clk,
    input wire                                  rst_n,

    // == Ctrl Signals from Core Ctrl ========================================
    input wire                                  app_en,
    input wire [`PRGA_CREG_DATA_WIDTH-1:0]      app_features,

    // == Generic Cache-Coherent Memory Interface ============================
    input wire                                  ccm_req_rdy,
    output reg                                  ccm_req_val,
    output reg [`PRGA_CCM_REQTYPE_WIDTH-1:0]    ccm_req_type,
    output reg [`PRGA_CCM_ADDR_WIDTH-1:0]       ccm_req_addr,
    output reg [`PRGA_CCM_DATA_WIDTH-1:0]       ccm_req_data,
    output reg [`PRGA_CCM_SIZE_WIDTH-1:0]       ccm_req_size,
    output reg [`PRGA_CCM_THREADID_WIDTH-1:0]   ccm_req_threadid,
    output reg [`PRGA_CCM_AMO_OPCODE_WIDTH-1:0] ccm_req_amo_opcode,

    output reg                                  ccm_resp_rdy,
    input wire                                  ccm_resp_val,
    input wire [`PRGA_CCM_RESPTYPE_WIDTH-1:0]   ccm_resp_type,
    input wire [`PRGA_CCM_THREADID_WIDTH-1:0]   ccm_resp_threadid,
    input wire [`PRGA_CCM_CACHETAG_INDEX]       ccm_resp_addr,  // only used for invalidations
    input wire [`PRGA_CCM_CACHELINE_WIDTH-1:0]  ccm_resp_data,

    // == Transducer -> SAX ==================================================
    input wire                                  sax_rdy,
    output reg                                  sax_val,
    output reg [`PRGA_SAX_DATA_WIDTH-1:0]       sax_data,

    // == ASX -> Transducer ==================================================
    output reg                                  asx_rdy,
    input wire                                  asx_val,
    input wire [`PRGA_ASX_DATA_WIDTH-1:0]       asx_data
    );

    wire ccm_intf_en;
    assign ccm_intf_en = app_en && app_features[`PRGA_APP_CCM_EN_INDEX];

    // =======================================================================
    // -- Handle ASX Requests ------------------------------------------------
    // =======================================================================

    // == Disassemble ASX Message ==
    always @* begin
        asx_rdy = ~ccm_intf_en || ccm_req_rdy;

        ccm_req_val = ccm_intf_en && asx_val;
        ccm_req_addr = asx_data[`PRGA_CCM_DATA_WIDTH+:`PRGA_CCM_ADDR_WIDTH];
        ccm_req_data = asx_data[0+:`PRGA_CCM_DATA_WIDTH];
        ccm_req_size = asx_data[`PRGA_ASX_SIZE_INDEX];
        ccm_req_threadid = asx_data[`PRGA_ASX_THREADID_INDEX];
        ccm_req_amo_opcode = `PRGA_CCM_AMO_OPCODE_NONE;

        case (asx_data[`PRGA_ASX_MSGTYPE_INDEX])
            `PRGA_ASX_MSGTYPE_CCM_LOAD: begin
                ccm_req_type = `PRGA_CCM_REQTYPE_LOAD;
            end
            `PRGA_ASX_MSGTYPE_CCM_LOAD_NC: begin
                ccm_req_type = `PRGA_CCM_REQTYPE_LOAD_NC;
            end
            `PRGA_ASX_MSGTYPE_CCM_STORE: begin
                ccm_req_type = `PRGA_CCM_REQTYPE_STORE;
            end
            `PRGA_ASX_MSGTYPE_CCM_STORE_NC: begin
                ccm_req_type = `PRGA_CCM_REQTYPE_STORE_NC;
            end
            `PRGA_ASX_MSGTYPE_CCM_AMO: begin
                ccm_req_type = `PRGA_CCM_REQTYPE_AMO;
                ccm_req_amo_opcode = asx_data[`PRGA_ASX_AMO_OPCODE_INDEX];
            end
            default: begin
                ccm_req_type = {`PRGA_CCM_REQTYPE_WIDTH {1'b0} };
            end
        endcase
    end

    // =======================================================================
    // -- Handle SAX Responses -----------------------------------------------
    // =======================================================================

    // == Assemble SAX Message ==
    always @* begin
        ccm_resp_rdy = ~ccm_intf_en || sax_rdy;

        sax_val = ccm_intf_en && ccm_resp_val;
        sax_data = {`PRGA_SAX_DATA_WIDTH {1'b0} };
        sax_data[`PRGA_SAX_THREADID_INDEX] = ccm_resp_threadid;

        case (ccm_resp_type)
            `PRGA_CCM_RESPTYPE_LOAD_ACK: begin
                sax_data[`PRGA_SAX_MSGTYPE_INDEX] = `PRGA_SAX_MSGTYPE_CCM_LOAD_ACK;
                sax_data[0+:`PRGA_CCM_CACHELINE_WIDTH] = ccm_resp_data;
            end
            `PRGA_CCM_RESPTYPE_LOAD_NC_ACK: begin
                sax_data[`PRGA_SAX_MSGTYPE_INDEX] = `PRGA_SAX_MSGTYPE_CCM_LOAD_NC_ACK;
                sax_data[0+:`PRGA_CCM_CACHELINE_WIDTH] = ccm_resp_data;
            end
            `PRGA_CCM_RESPTYPE_STORE_ACK: begin
                sax_data[`PRGA_SAX_MSGTYPE_INDEX] = `PRGA_SAX_MSGTYPE_CCM_STORE_ACK;
            end
            `PRGA_CCM_RESPTYPE_STORE_NC_ACK: begin
                sax_data[`PRGA_SAX_MSGTYPE_INDEX] = `PRGA_SAX_MSGTYPE_CCM_STORE_NC_ACK;
            end
            `PRGA_CCM_RESPTYPE_AMO_ACK: begin
                sax_data[`PRGA_SAX_MSGTYPE_INDEX] = `PRGA_SAX_MSGTYPE_CCM_AMO_ACK;
            end
        endcase
    end

endmodule