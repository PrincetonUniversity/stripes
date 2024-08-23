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

module vx3p1 (
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

    localparam  AXSIZE = `PRGA_AXI4_AXSIZE_4B;
    localparam  DATA_WIDTH = AXSIZE == `PRGA_AXI4_AXSIZE_1B ? 8
                           : AXSIZE == `PRGA_AXI4_AXSIZE_2B ? 16
                           : AXSIZE == `PRGA_AXI4_AXSIZE_4B ? 32
                           : AXSIZE == `PRGA_AXI4_AXSIZE_8B ? 64
                           : -1;

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
    wire                                        awready_f;
    wire                                        awvalid_p;
    wire [`PRGA_AXI4_ID_WIDTH-1:0]              awid_p;
    wire [`PRGA_AXI4_ADDR_WIDTH-1:0]            awaddr_p;
    wire [`PRGA_AXI4_AXLEN_WIDTH-1:0]           awlen_p;
    wire [`PRGA_AXI4_AXSIZE_WIDTH-1:0]          awsize_p;
    wire [`PRGA_AXI4_AXBURST_WIDTH-1:0]         awburst_p;
    wire [`PRGA_AXI4_AXCACHE_WIDTH-1:0]         awcache_p;
    wire [`PRGA_CCM_ECC_WIDTH-1:0]              awuser_p;

    assign awuser_p = ~^{awid_p, awaddr_p, awlen_p, awsize_p, awburst_p, awcache_p};

    prga_valrdy_buf #(
        .REGISTERED         (1)
        ,.DECOUPLED         (1)
        ,.DATA_WIDTH        (
            `PRGA_AXI4_ID_WIDTH
            + `PRGA_AXI4_ADDR_WIDTH
            + `PRGA_AXI4_AXLEN_WIDTH
            + `PRGA_AXI4_AXSIZE_WIDTH
            + `PRGA_AXI4_AXBURST_WIDTH
            + `PRGA_AXI4_AXCACHE_WIDTH
            + `PRGA_CCM_ECC_WIDTH
        )
    ) i_aw_buf (
        .clk                (clk)
        ,.rst               (~rst_n)
        ,.rdy_o             (awready_f)
        ,.val_i             (awvalid_p)
        ,.data_i            ({
            awid_p
            , awaddr_p
            , awlen_p
            , awsize_p
            , awburst_p
            , awcache_p
            , awuser_p
        })
        ,.rdy_i             (awready)
        ,.val_o             (awvalid)
        ,.data_o            ({
            awid
            , awaddr
            , awlen
            , awsize
            , awburst
            , awcache
            , awuser
        })
        );

    // -- W channel --
    wire                                        wready_f;
    wire                                        wvalid_p;
    wire [`PRGA_AXI4_DATA_WIDTH-1:0]            wdata_p;
    wire [`PRGA_AXI4_DATA_BYTES-1:0]            wstrb_p;
    wire                                        wlast_p;
    wire [`PRGA_CCM_ECC_WIDTH-1:0]              wuser_p;

    assign wuser_p = ~^{wdata_p, wstrb_p, wlast_p};

    prga_valrdy_buf #(
        .REGISTERED         (1)
        ,.DECOUPLED         (1)
        ,.DATA_WIDTH        (
            `PRGA_AXI4_DATA_WIDTH
            + `PRGA_AXI4_DATA_BYTES
            + 1
            + `PRGA_CCM_ECC_WIDTH
        )
    ) i_w_buf (
        .clk                (clk)
        ,.rst               (~rst_n)
        ,.rdy_o             (wready_f)
        ,.val_i             (wvalid_p)
        ,.data_i            ({
            wdata_p
            , wstrb_p
            , wlast_p
            , wuser_p
        })
        ,.rdy_i             (wready)
        ,.val_o             (wvalid)
        ,.data_o            ({
            wdata
            , wstrb
            , wlast
            , wuser
        })
        );

    // -- B channel --
    wire                                        bready_p;
    wire                                        bvalid_f;
    wire [`PRGA_AXI4_XRESP_WIDTH-1:0]           bresp_f;
    wire [`PRGA_AXI4_ID_WIDTH-1:0]              bid_f;

    prga_valrdy_buf #(
        .REGISTERED         (1)
        ,.DECOUPLED         (1)
        ,.DATA_WIDTH        (
            `PRGA_AXI4_XRESP_WIDTH
            + `PRGA_AXI4_ID_WIDTH
        )
    ) i_b_buf (
        .clk                (clk)
        ,.rst               (~rst_n)
        ,.rdy_o             (bready)
        ,.val_i             (bvalid)
        ,.data_i            ({
            bresp
            , bid
        })
        ,.rdy_i             (bready_p)
        ,.val_o             (bvalid_f)
        ,.data_o            ({
            bresp_f
            , bid_f
        })
        );

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
            + 1
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
            , rlast
        })
        ,.rdy_i             (rready_p)
        ,.val_o             (rvalid_f)
        ,.data_o            ({
            rresp_f
            , rid_f
            , rdata_f
            , rlast_f
        })
        );

    // ========================================================
    // -- Core Modules ----------------------------------------
    // ========================================================
    wire iq_empty, iq_rd, oq_full, oq_wr;
    wire [DATA_WIDTH-1:0] iq_dout, oq_din;

    wire iq_done, oq_done;
    wire start;
    wire [`PRGA_AXI4_ADDR_WIDTH-1:0]          src_base_addr;
    wire [`PRGA_AXI4_ADDR_WIDTH-1:0]          dst_base_addr;
    wire [`PRGA_CREG_DATA_WIDTH-1:0]          vlen;

    // == cfg ==
    vx3p1_cfg i_cfg (
        .clk                (clk)
        ,.rst_n             (rst_n)
        ,.ureg_req_rdy      (ureg_req_rdy_p)
        ,.ureg_req_val      (ureg_req_val_f)
        ,.ureg_req_addr     (ureg_req_addr_f)
        ,.ureg_req_strb     (ureg_req_strb_f)
        ,.ureg_req_data     (ureg_req_data_f)
        ,.ureg_resp_rdy     (ureg_resp_rdy_f)
        ,.ureg_resp_val     (ureg_resp_val_p)
        ,.ureg_resp_data    (ureg_resp_data_p)
        ,.finish            (iq_done && oq_done)
        ,.start             (start)
        ,.src_base_addr     (src_base_addr)
        ,.dst_base_addr     (dst_base_addr)
        ,.vlen              (vlen)
        );

    // == IQ ==
    vx3p1_iq #(
        .AXSIZE             (AXSIZE)
        ,.DATA_WIDTH        (DATA_WIDTH)
    ) iq (
        .clk                (clk)
        ,.rst_n             (rst_n)
        ,.start             (start)
        ,.src_base_addr     (src_base_addr)
        ,.vlen              (vlen)
        ,.done              (iq_done)
        ,.iq_rd             (iq_rd)
        ,.iq_empty          (iq_empty)
        ,.iq_dout           (iq_dout)
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

    // == OQ ==
    vx3p1_oq #(
        .AXSIZE             (AXSIZE)
        ,.DATA_WIDTH        (DATA_WIDTH)
    ) oq (
        .clk                (clk)
        ,.rst_n             (rst_n)
        ,.start             (start)
        ,.dst_base_addr     (dst_base_addr)
        ,.vlen              (vlen)
        ,.done              (oq_done)
        ,.oq_wr             (oq_wr)
        ,.oq_full           (oq_full)
        ,.oq_din            (oq_din)
        ,.awready                   (awready_f)
        ,.awvalid                   (awvalid_p)
        ,.awid                      (awid_p)
        ,.awaddr                    (awaddr_p)
        ,.awlen                     (awlen_p)
        ,.awsize                    (awsize_p)
        ,.awburst                   (awburst_p)
        ,.awcache                   (awcache_p)
        ,.wready                    (wready_f)
        ,.wvalid                    (wvalid_p)
        ,.wdata                     (wdata_p)
        ,.wstrb                     (wstrb_p)
        ,.wlast                     (wlast_p)
        ,.bready                    (bready_p)
        ,.bvalid                    (bvalid_f)
        ,.bresp                     (bresp_f)
        ,.bid                       (bid_f)
        );

    // == Core ==
    vx3p1_core #(
        .DATA_WIDTH         (DATA_WIDTH)
    ) i_core (
        .clk                (clk)
        ,.rst_n             (rst_n)
        ,.iq_empty          (iq_empty)
        ,.iq_data		    (iq_dout)
        ,.iq_rd		        (iq_rd)
        ,.oq_full		    (oq_full)
        ,.oq_data		    (oq_din)
        ,.oq_wr		        (oq_wr)
        );

endmodule
