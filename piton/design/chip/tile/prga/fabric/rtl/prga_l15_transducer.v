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
* Transducer for OpenPiton TRI protocol.
*/

`include "l15.tmp.h"
`include "prga_system.vh"

`ifdef DEFAULT_NETTYPE_NONE
    `default_nettype none
`endif

module prga_l15_transducer (
    input wire                                  clk,
    input wire                                  rst_n,

    // == Transducer -> L15 ==================================================
    // Outputs
    output reg                                  transducer_l15_val,
    output reg [4:0]                            transducer_l15_rqtype,
    output reg [`L15_THREADID_MASK]             transducer_l15_threadid,
    output reg                                  transducer_l15_nc,
    output reg [2:0]                            transducer_l15_size,
    output reg [39:0]                           transducer_l15_address,
    output reg [63:0]                           transducer_l15_data,
    output reg [`L15_AMO_OP_WIDTH-1:0]          transducer_l15_amo_op,

    // ACK
    input wire                                  l15_transducer_ack,
    input wire                                  l15_transducer_header_ack,

    // Unused outputs
    output reg [1:0]                            transducer_l15_l1rplway,
    output reg                                  transducer_l15_prefetch,
    output reg                                  transducer_l15_invalidate_cacheline,    // L1 invalidation
    output reg                                  transducer_l15_blockstore,
    output reg                                  transducer_l15_blockinitstore,
    output reg [63:0]                           transducer_l15_data_next_entry, // unused (for CAS only)
    output reg [`TLB_CSM_WIDTH-1:0]             transducer_l15_csm_data,        // unused (for CDR only)

    // == L15 -> Transducer ==================================================
    // Inputs
    input wire                                  l15_transducer_val,
    input wire [3:0]                            l15_transducer_returntype,
    input wire [15:4]                           l15_transducer_inval_address_15_4,
    input wire                                  l15_transducer_noncacheable,
    input wire [`L15_THREADID_MASK]             l15_transducer_threadid,
    input wire [63:0]                           l15_transducer_data_0,
    input wire [63:0]                           l15_transducer_data_1,

    // ACK: Must be asserted in the same cycle when `l15_transducer_val` is asserted
    output reg                                  transducer_l15_req_ack,

    // == Transducer -> CCM ==================================================
    output reg                                  ccm_req_rdy,
    input wire                                  ccm_req_val,
    input wire [`PRGA_CCM_REQTYPE_WIDTH-1:0]    ccm_req_type,
    input wire [`PRGA_CCM_ADDR_WIDTH-1:0]       ccm_req_addr,
    input wire [`PRGA_CCM_DATA_WIDTH-1:0]       ccm_req_data,
    input wire [`PRGA_CCM_SIZE_WIDTH-1:0]       ccm_req_size,
    input wire [`PRGA_CCM_THREADID_WIDTH-1:0]   ccm_req_threadid,
    input wire [`PRGA_CCM_AMO_OPCODE_WIDTH-1:0] ccm_req_amo_opcode,

    // == CCM -> Transducer ==================================================
    input wire                                  ccm_resp_rdy,
    output reg                                  ccm_resp_val,
    output reg [`PRGA_CCM_RESPTYPE_WIDTH-1:0]   ccm_resp_type,
    output reg [`PRGA_CCM_THREADID_WIDTH-1:0]   ccm_resp_threadid,
    output reg [`PRGA_CCM_CACHETAG_INDEX]       ccm_resp_addr,  // only used for invalidations
    output reg [`PRGA_CCM_CACHELINE_WIDTH-1:0]  ccm_resp_data
    );

    // =======================================================================
    // -- Forward Declarations -----------------------------------------------
    // =======================================================================

    // == MSHR ==
    reg [`L15_THREAD_ARRAY_MASK]    load_mshr, allocate_load_mshr, deallocate_load_mshr;
    reg [`L15_THREAD_ARRAY_MASK]    store_mshr, allocate_store_mshr, deallocate_store_mshr;

    always @(posedge clk) begin
        if (~rst_n) begin
            load_mshr   <= {`L15_NUM_THREADS{1'b0} };
            store_mshr  <= {`L15_NUM_THREADS{1'b0} };
        end else begin
            load_mshr   <= ~deallocate_load_mshr & (load_mshr | allocate_load_mshr);
            store_mshr  <= ~deallocate_store_mshr & (store_mshr | allocate_store_mshr);
        end
    end

    // =======================================================================
    // -- Handle CCM Requests ------------------------------------------------
    // =======================================================================

    // == Send L15 Request ==
    reg                             transducer_l15_stall, l15_transducer_ack_pending;
    reg                             transducer_l15_val_next;
    reg [4:0]                       transducer_l15_rqtype_next;
    reg                             transducer_l15_nc_next;
    reg [2:0]                       transducer_l15_size_next;
    reg [`L15_THREADID_MASK]        transducer_l15_threadid_next;
    reg [39:0]                      transducer_l15_address_next;
    reg [63:0]                      transducer_l15_data_next;
    reg [`L15_AMO_OP_WIDTH-1:0]     transducer_l15_amo_op_next;

    always @(posedge clk) begin
        if (~rst_n) begin
            l15_transducer_ack_pending  <= 1'b0;

            transducer_l15_val          <= 1'b0;
            transducer_l15_rqtype       <= 5'b0;
            transducer_l15_threadid     <= {`L15_THREADID_WIDTH {1'b0} };
            transducer_l15_nc           <= 1'b0;
            transducer_l15_size         <= 3'b0;
            transducer_l15_address      <= 40'b0;
            transducer_l15_data         <= 64'b0;
            transducer_l15_amo_op       <= `L15_AMO_OP_NONE;
        end else if (~transducer_l15_stall) begin
            l15_transducer_ack_pending  <= transducer_l15_val_next;

            transducer_l15_val          <= transducer_l15_val_next;
            transducer_l15_rqtype       <= transducer_l15_rqtype_next;
            transducer_l15_threadid     <= transducer_l15_threadid_next;
            transducer_l15_nc           <= transducer_l15_nc_next;
            transducer_l15_size         <= transducer_l15_size_next;
            transducer_l15_address      <= transducer_l15_address_next;
            transducer_l15_data         <= transducer_l15_data_next;
            transducer_l15_amo_op       <= transducer_l15_amo_op_next;
        end else begin
            if (transducer_l15_val && l15_transducer_header_ack) begin
                transducer_l15_val <= 1'b0;
            end

            if (l15_transducer_ack_pending && l15_transducer_ack) begin
                l15_transducer_ack_pending <= 1'b0;
            end
        end
    end

    always @* begin
        transducer_l15_stall = (transducer_l15_val && ~l15_transducer_header_ack) ||
                               (l15_transducer_ack_pending && ~l15_transducer_ack);

        // Tie unused outputs to constant low
        transducer_l15_l1rplway = 2'b0;     // no L1 cache
        transducer_l15_prefetch = 1'b0;
        transducer_l15_invalidate_cacheline = 1'b0;
        transducer_l15_blockstore = 1'b0;
        transducer_l15_blockinitstore = 1'b0;
        transducer_l15_data_next_entry = 64'b0;
        transducer_l15_csm_data = {`TLB_CSM_WIDTH{1'b0} };
    end

    // == Request State Machine ==
    localparam  ST_REQ_RST      = 1'h0,
                ST_REQ_ACTIVE   = 1'h1;
    
    reg [0:0] req_state, req_state_next;

    always @(posedge clk) begin
        if (~rst_n) begin
            req_state   <= ST_REQ_RST;
        end else begin
            req_state   <= req_state_next;
        end
    end

    // == Helper Signals ==
    reg load_mshr_avail, store_mshr_avail;

    always @* begin
        load_mshr_avail = ~load_mshr[ccm_req_threadid] || deallocate_load_mshr[ccm_req_threadid];
        store_mshr_avail = ~store_mshr[ccm_req_threadid] || deallocate_store_mshr[ccm_req_threadid];
    end

    always @* begin
        req_state_next = req_state;
        ccm_req_rdy = ~transducer_l15_stall;

        allocate_load_mshr = {`L15_NUM_THREADS{1'b0} };
        allocate_store_mshr = {`L15_NUM_THREADS{1'b0} };
        transducer_l15_val_next = 1'b0;
        transducer_l15_rqtype_next = transducer_l15_rqtype;
        transducer_l15_threadid_next = transducer_l15_threadid;
        transducer_l15_nc_next = transducer_l15_nc;
        transducer_l15_size_next = transducer_l15_size;
        transducer_l15_address_next = transducer_l15_address;
        transducer_l15_data_next = transducer_l15_data;
        transducer_l15_amo_op_next = transducer_l15_amo_op;

        case (req_state)
            ST_REQ_RST: begin
                req_state_next = ST_REQ_ACTIVE;
            end
            ST_REQ_ACTIVE: if (ccm_req_val) begin
                transducer_l15_threadid_next = ccm_req_threadid;
                transducer_l15_size_next = ccm_req_size;
                transducer_l15_address_next = ccm_req_addr;
                transducer_l15_data_next = ccm_req_data;

                case (ccm_req_type)
                    `PRGA_CCM_REQTYPE_LOAD,
                    `PRGA_CCM_REQTYPE_LOAD_NC: begin
                        transducer_l15_rqtype_next = `PCX_REQTYPE_LOAD;
                        transducer_l15_nc_next = ccm_req_type == `PRGA_CCM_REQTYPE_LOAD_NC;
                        transducer_l15_amo_op_next = `L15_AMO_OP_NONE;

                        allocate_load_mshr[ccm_req_threadid] = ~transducer_l15_stall;
                        transducer_l15_val_next = load_mshr_avail;
                        ccm_req_rdy = ~transducer_l15_stall && load_mshr_avail;
                    end
                    `PRGA_CCM_REQTYPE_STORE,
                    `PRGA_CCM_REQTYPE_STORE_NC: begin
                        transducer_l15_rqtype_next = `PCX_REQTYPE_STORE;
                        transducer_l15_nc_next = ccm_req_type == `PRGA_CCM_REQTYPE_STORE_NC;
                        transducer_l15_amo_op_next = `L15_AMO_OP_NONE;

                        allocate_store_mshr[ccm_req_threadid] = ~transducer_l15_stall;
                        transducer_l15_val_next = store_mshr_avail;
                        ccm_req_rdy = ~transducer_l15_stall && store_mshr_avail;
                    end
                    `PRGA_CCM_REQTYPE_AMO: begin
                        transducer_l15_rqtype_next = `PCX_REQTYPE_AMO;
                        transducer_l15_nc_next = 1'b1;
                        transducer_l15_amo_op_next = ccm_req_amo_opcode;

                        allocate_load_mshr[ccm_req_threadid] = ~transducer_l15_stall && store_mshr_avail;
                        allocate_store_mshr[ccm_req_threadid] = ~transducer_l15_stall && load_mshr_avail;
                        transducer_l15_val_next = store_mshr_avail && load_mshr_avail;
                        ccm_req_rdy = ~transducer_l15_stall && store_mshr_avail && load_mshr_avail;
                    end
                endcase
            end
        endcase
    end

    // =======================================================================
    // -- Send Reponses/Invalidations ----------------------------------------
    // =======================================================================

    // Register L15 responses
    reg                             l15_transducer_stall;
    reg                             l15_transducer_val_f;
    reg [3:0]                       l15_transducer_returntype_f;
    reg [15:4]                      l15_transducer_inval_address_15_4_f;
    reg                             l15_transducer_noncacheable_f;
    reg [`L15_THREADID_MASK]        l15_transducer_threadid_f;
    reg [63:0]                      l15_transducer_data_0_f;
    reg [63:0]                      l15_transducer_data_1_f;

    always @(posedge clk) begin
        if (~rst_n) begin
            l15_transducer_val_f	            <= 1'b0;
            l15_transducer_returntype_f	        <= 4'b0;
            l15_transducer_inval_address_15_4_f	<= 12'b0;
            l15_transducer_noncacheable_f	    <= 1'b0;
            l15_transducer_threadid_f	        <= {`L15_THREADID_WIDTH {1'b0} };
            l15_transducer_data_0_f	            <= 64'b0;
            l15_transducer_data_1_f	            <= 64'b0;
        end else if (~l15_transducer_stall) begin
            l15_transducer_val_f	            <= l15_transducer_val;
            l15_transducer_returntype_f	        <= l15_transducer_returntype;
            l15_transducer_inval_address_15_4_f	<= l15_transducer_inval_address_15_4;
            l15_transducer_noncacheable_f	    <= l15_transducer_noncacheable;
            l15_transducer_threadid_f	        <= l15_transducer_threadid;
            l15_transducer_data_0_f	            <= l15_transducer_data_0;
            l15_transducer_data_1_f	            <= l15_transducer_data_1;
        end
    end

    always @* begin
        transducer_l15_req_ack = l15_transducer_val && ~l15_transducer_stall;
    end

    // Response State Machine    
    localparam  ST_RESP_RST         = 1'h0,
                ST_RESP_ACTIVE      = 1'h1;

    reg [0:0] resp_state, resp_state_next;

    always @(posedge clk) begin
        if (~rst_n) begin
            resp_state  <= ST_RESP_RST;
        end else begin
            resp_state  <= resp_state_next;
        end
    end

    always @* begin
        resp_state_next = resp_state;
        l15_transducer_stall = 1'b1;

        deallocate_load_mshr = {`L15_NUM_THREADS{1'b0} };
        deallocate_store_mshr = {`L15_NUM_THREADS{1'b0} };

        ccm_resp_val = 1'b0;
        ccm_resp_type = {`PRGA_CCM_RESPTYPE_WIDTH {1'b0} };
        ccm_resp_threadid = l15_transducer_threadid_f;
        ccm_resp_addr = l15_transducer_inval_address_15_4_f[`PRGA_CCM_CACHETAG_INDEX];
        ccm_resp_data = {l15_transducer_data_1_f, l15_transducer_data_0_f};

        case (l15_transducer_returntype_f)
            `CPX_RESTYPE_LOAD: if (l15_transducer_noncacheable_f) begin
                ccm_resp_type = `PRGA_CCM_RESPTYPE_LOAD_NC_ACK;
            end else begin
                ccm_resp_type = `PRGA_CCM_RESPTYPE_LOAD_ACK;
            end
            `CPX_RESTYPE_STORE_ACK: if (l15_transducer_noncacheable_f) begin
                ccm_resp_type = `PRGA_CCM_RESPTYPE_STORE_NC_ACK;
            end else begin
                ccm_resp_type = `PRGA_CCM_RESPTYPE_STORE_ACK;
            end
            `CPX_RESTYPE_ATOMIC_RES: begin
                ccm_resp_type = `PRGA_CCM_RESPTYPE_AMO_ACK;
            end
        endcase

        case (resp_state)
            ST_RESP_RST: begin
                resp_state_next = ST_RESP_ACTIVE;
            end
            ST_RESP_ACTIVE: if (l15_transducer_val_f) begin
                case (l15_transducer_returntype_f)
                    `CPX_RESTYPE_LOAD: begin
                        ccm_resp_val = 1'b1;
                        l15_transducer_stall = ~ccm_resp_rdy;
                        deallocate_load_mshr[l15_transducer_threadid_f] = ccm_resp_rdy;
                    end
                    `CPX_RESTYPE_STORE_ACK: begin
                        ccm_resp_val = 1'b1;
                        l15_transducer_stall = ~ccm_resp_rdy;
                        deallocate_store_mshr[l15_transducer_threadid_f] = ccm_resp_rdy;
                    end
                    `CPX_RESTYPE_ATOMIC_RES: begin
                        ccm_resp_val = 1'b1;
                        l15_transducer_stall = ~ccm_resp_rdy;
                        deallocate_load_mshr[l15_transducer_threadid_f] = ccm_resp_rdy;
                        deallocate_store_mshr[l15_transducer_threadid_f] = ccm_resp_rdy;
                    end
                    default: begin
                        l15_transducer_stall = 1'b0;
                    end
                endcase
            end else begin
                l15_transducer_stall = 1'b0;
            end
        endcase
    end

endmodule