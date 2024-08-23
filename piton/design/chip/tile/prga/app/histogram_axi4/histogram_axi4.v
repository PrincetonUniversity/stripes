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

module histogram_axi4 (
    input wire                                      clk,
    input wire                                      rst_n,

    // == UREG Interface ==
    output wire                                     ureg_req_rdy,
    input wire                                      ureg_req_val,
    input wire [`PRGA_CREG_ADDR_WIDTH-1:0]          ureg_req_addr,
    input wire [`PRGA_CREG_DATA_BYTES-1:0]          ureg_req_strb,
    input wire [`PRGA_CREG_DATA_WIDTH-1:0]          ureg_req_data,

    input wire                                      ureg_resp_rdy,
    output wire                                     ureg_resp_val,
    output wire [`PRGA_CREG_DATA_WIDTH-1:0]         ureg_resp_data,
    output wire [`PRGA_ECC_WIDTH-1:0]               ureg_resp_ecc,

    // == AXI4 Slave Interface ===============================================
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

    // ECC
    output wire [`PRGA_CCM_ECC_WIDTH-1:0]           awuser,

    // -- W channel --
    input wire                                      wready,
    output wire                                     wvalid,
    output wire [`PRGA_AXI4_DATA_WIDTH-1:0]         wdata,
    output wire [`PRGA_AXI4_DATA_BYTES-1:0]         wstrb,
    output wire                                     wlast,

    // ECC
    output wire [`PRGA_CCM_ECC_WIDTH-1:0]           wuser,

    // -- B channel --
    output wire                                     bready,
    input wire                                      bvalid,
    input wire [`PRGA_AXI4_XRESP_WIDTH-1:0]         bresp,
    input wire [`PRGA_AXI4_ID_WIDTH-1:0]            bid,

    // -- AR channel --
    input wire                                      arready,
    output wire                                     arvalid,
    output wire [`PRGA_AXI4_ID_WIDTH-1:0]           arid,
    output wire [`PRGA_AXI4_ADDR_WIDTH-1:0]         araddr,
    output wire [`PRGA_AXI4_AXLEN_WIDTH-1:0]        arlen,
    output wire [`PRGA_AXI4_AXSIZE_WIDTH-1:0]       arsize,
    output wire [`PRGA_AXI4_AXBURST_WIDTH-1:0]      arburst,

    // non-standard use of ARLOCK: indicates an atomic operation.
    // Type of the atomic operation is specified in the ARUSER field
    output wire                                     arlock,

    // non-standard use of ARCACHE: Only |ARCACHE[3:2] is checked: 1'b1: cacheable; 1'b0: non-cacheable
    output wire [`PRGA_AXI4_AXCACHE_WIDTH-1:0]      arcache,

    // ATOMIC operation type, data & ECC:
    //      aruser[`PRGA_CCM_ECC_WIDTH + `PRGA_CCM_AMO_OPCODE_WIDTH +: `PRGA_CCM_DATA_WIDTH]        amo_data
    //      aruser[`PRGA_CCM_ECC_WIDTH                              +: `PRGA_CCM_AMO_OPCODE_WIDTH]  amo_opcode
    //      aruser[0                                                +: `PRGA_CCM_ECC_WIDTH]         ecc
    output wire [`PRGA_CCM_AMO_OPCODE_WIDTH + `PRGA_CCM_ECC_WIDTH + `PRGA_CCM_DATA_WIDTH - 1:0]     aruser,

    // -- R channel --
    output wire                                     rready,
    input wire                                      rvalid,
    input wire [`PRGA_AXI4_XRESP_WIDTH-1:0]         rresp,
    input wire [`PRGA_AXI4_ID_WIDTH-1:0]            rid,
    input wire [`PRGA_AXI4_DATA_WIDTH-1:0]          rdata,
    input wire                                      rlast
    );

    // ========================================================
    // -- Val/Rdy Buffers -------------------------------------
    // ========================================================
    // -- UREG request channel --
    wire                                        ureg_req_rdy_p;
    wire                                        ureg_req_val_f;
    wire [`PRGA_CREG_ADDR_WIDTH-1:0]            ureg_req_addr_f;
    wire [`PRGA_CREG_DATA_BYTES-1:0]            ureg_req_strb_f;
    wire [`PRGA_CREG_DATA_WIDTH-1:0]            ureg_req_data_f;

    prga_valrdy_buf #(
        .REGISTERED         (1)
        ,.DECOUPLED         (1)
        ,.DATA_WIDTH        (
            `PRGA_CREG_ADDR_WIDTH
            + `PRGA_CREG_DATA_BYTES
            + `PRGA_CREG_DATA_WIDTH
        )
    ) i_ureg_req_buf (
        .clk                (clk)
        ,.rst               (~rst_n)
        ,.rdy_o             (ureg_req_rdy)
        ,.val_i             (ureg_req_val)
        ,.data_i            ({
            ureg_req_addr
            , ureg_req_strb
            , ureg_req_data
        })
        ,.rdy_i             (ureg_req_rdy_p)
        ,.val_o             (ureg_req_val_f)
        ,.data_o            ({
            ureg_req_addr_f
            , ureg_req_strb_f
            , ureg_req_data_f
        })
        );

    // -- UREG response channel --
    wire                                        ureg_resp_rdy_f;
    wire                                        ureg_resp_val_p;
    wire [`PRGA_CREG_DATA_WIDTH-1:0]            ureg_resp_data_p;
    wire [`PRGA_ECC_WIDTH-1:0]                  ureg_resp_ecc_p;

    assign ureg_resp_ecc_p = ~^ureg_resp_data_p;

    prga_valrdy_buf #(
        .REGISTERED         (1)
        ,.DECOUPLED         (1)
        ,.DATA_WIDTH        (`PRGA_CREG_DATA_WIDTH + 1)
    ) i_ureg_resp_buf (
        .clk                (clk)
        ,.rst               (~rst_n)
        ,.rdy_o             (ureg_resp_rdy_f)
        ,.val_i             (ureg_resp_val_p)
        ,.data_i            ({ureg_resp_data_p, ureg_resp_ecc_p})
        ,.rdy_i             (ureg_resp_rdy)
        ,.val_o             (ureg_resp_val)
        ,.data_o            ({ureg_resp_data, ureg_resp_ecc})
        );

    // -- AW channel --
    //  Unbuffered (because it's not used)
    assign awuser = ~^{awid, awaddr, awlen, awsize, awburst, awcache};

    // -- W channel --
    //  Unbuffered (because it's not used)
    assign wuser = ~^{wdata, wstrb, wlast};

    // -- B channel --
    //  Unbuffered (because it's not used)

    // -- AR channel --
    wire                                        arready_f;
    wire                                        arvalid_p;
    wire [`PRGA_AXI4_ID_WIDTH-1:0]              arid_p;
    wire [`PRGA_AXI4_ADDR_WIDTH-1:0]            araddr_p;
    wire [`PRGA_AXI4_AXLEN_WIDTH-1:0]           arlen_p;
    wire [`PRGA_AXI4_AXSIZE_WIDTH-1:0]          arsize_p;
    wire [`PRGA_AXI4_AXBURST_WIDTH-1:0]         arburst_p;
    wire                                        arlock_p;
    wire [`PRGA_AXI4_AXCACHE_WIDTH-1:0]         arcache_p;
    wire [`PRGA_CCM_AMO_OPCODE_WIDTH-1:0]       aramo_opcode_p;
    wire [`PRGA_CCM_DATA_WIDTH-1:0]             aramo_data_p;
    wire [`PRGA_CCM_ECC_WIDTH-1:0]              arecc_p;

    assign arecc_p = ~^{arid_p, araddr_p, arlen_p, arsize_p, arburst_p, arlock_p, arcache_p,
        aramo_opcode_p, aramo_data_p};

    prga_valrdy_buf #(
        .REGISTERED         (1)
        ,.DECOUPLED         (1)
        ,.DATA_WIDTH        (
            `PRGA_AXI4_ID_WIDTH
            + `PRGA_AXI4_ADDR_WIDTH
            + `PRGA_AXI4_AXLEN_WIDTH
            + `PRGA_AXI4_AXSIZE_WIDTH
            + `PRGA_AXI4_AXBURST_WIDTH
            + 1
            + `PRGA_AXI4_AXCACHE_WIDTH
            + `PRGA_CCM_AMO_OPCODE_WIDTH
            + `PRGA_CCM_DATA_WIDTH
            + `PRGA_CCM_ECC_WIDTH
        )
    ) i_ar_buf (
        .clk                (clk)
        ,.rst               (~rst_n)
        ,.rdy_o             (arready_f)
        ,.val_i             (arvalid_p)
        ,.data_i            ({
            arid_p
            , araddr_p
            , arlen_p
            , arsize_p
            , arburst_p
            , arlock_p
            , arcache_p
            , aramo_data_p
            , aramo_opcode_p
            , arecc_p
        })
        ,.rdy_i             (arready)
        ,.val_o             (arvalid)
        ,.data_o            ({
            arid
            , araddr
            , arlen
            , arsize
            , arburst
            , arlock
            , arcache
            , aruser
        })
        );

    // -- R channel --
    wire                                        rready_p;
    wire                                        rvalid_f;
    wire [`PRGA_AXI4_XRESP_WIDTH-1:0]           rresp_f;
    wire [`PRGA_AXI4_ID_WIDTH-1:0]              rid_f;
    wire [`PRGA_AXI4_DATA_WIDTH-1:0]            rdata_f;
    wire                                        rlast_f;

    prga_valrdy_buf #(
        .REGISTERED         (1)
        ,.DECOUPLED         (1)
        ,.DATA_WIDTH        (
            `PRGA_AXI4_XRESP_WIDTH
            + `PRGA_AXI4_ID_WIDTH
            + `PRGA_AXI4_DATA_WIDTH
        )
    ) i_r_buf (
        .clk                (clk)
        ,.rst               (~rst_n)
        ,.rdy_o             (rready)
        ,.val_i             (rvalid)
        ,.data_i            ({
            rresp
            , rid
            , rdata
        })
        ,.rdy_i             (rready_p)
        ,.val_o             (rvalid_f)
        ,.data_o            ({
            rresp_f
            , rid_f
            , rdata_f
        })
        );

    // ========================================================
    // -- Core ------------------------------------------------
    // ========================================================
    histogram_axi4_core i_core (
        .clk                        (clk)
        ,.rst_n                     (rst_n)

        ,.ureg_req_rdy              (ureg_req_rdy_p)
        ,.ureg_req_val              (ureg_req_val_f)
        ,.ureg_req_addr             (ureg_req_addr_f)
        ,.ureg_req_strb             (ureg_req_strb_f)
        ,.ureg_req_data             (ureg_req_data_f)

        ,.ureg_resp_rdy             (ureg_resp_rdy_f)
        ,.ureg_resp_val             (ureg_resp_val_p)
        ,.ureg_resp_data            (ureg_resp_data_p)

        ,.awready                   (awready)
        ,.awvalid                   (awvalid)
        ,.awid                      (awid)
        ,.awaddr                    (awaddr)
        ,.awlen                     (awlen)
        ,.awsize                    (awsize)
        ,.awburst                   (awburst)
        ,.awcache                   (awcache)

        ,.wready                    (wready)
        ,.wvalid                    (wvalid)
        ,.wdata                     (wdata)
        ,.wstrb                     (wstrb)
        ,.wlast                     (wlast)

        ,.bready                    (bready)
        ,.bvalid                    (bvalid)
        ,.bresp                     (bresp)
        ,.bid                       (bid)

        ,.arready                   (arready_f)
        ,.arvalid                   (arvalid_p)
        ,.arid                      (arid_p)
        ,.araddr                    (araddr_p)
        ,.arlen                     (arlen_p)
        ,.arsize                    (arsize_p)
        ,.arburst                   (arburst_p)
        ,.arlock                    (arlock_p)
        ,.arcache                   (arcache_p)
        ,.aramo_opcode              (aramo_opcode_p)
        ,.aramo_data                (aramo_data_p)

        ,.rready                    (rready_p)
        ,.rvalid                    (rvalid_f)
        ,.rresp                     (rresp_f)
        ,.rid                       (rid_f)
        ,.rdata                     (rdata_f)
        ,.rlast                     (rlast_f)
        );

endmodule
