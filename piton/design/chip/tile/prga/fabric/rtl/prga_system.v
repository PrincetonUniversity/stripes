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
module prga_system (
    input wire [0:0] clk
    , input wire [0:0] rst_n
    , output wire [0:0] reg_req_rdy
    , input wire [0:0] reg_req_val
    , input wire [11:0] reg_req_addr
    , input wire [7:0] reg_req_strb
    , input wire [63:0] reg_req_data
    , input wire [0:0] reg_resp_rdy
    , output wire [0:0] reg_resp_val
    , output wire [63:0] reg_resp_data
    , input wire [0:0] ccm_req_rdy
    , output wire [0:0] ccm_req_val
    , output wire [2:0] ccm_req_type
    , output wire [39:0] ccm_req_addr
    , output wire [63:0] ccm_req_data
    , output wire [2:0] ccm_req_size
    , output wire [0:0] ccm_req_threadid
    , output wire [3:0] ccm_req_amo_opcode
    , output wire [0:0] ccm_resp_rdy
    , input wire [0:0] ccm_resp_val
    , input wire [2:0] ccm_resp_type
    , input wire [6:0] ccm_resp_addr
    , input wire [127:0] ccm_resp_data
    , input wire [0:0] ccm_resp_threadid
    );
    
        
    wire [0:0] _i_sysintf__aclk;
    wire [0:0] _i_sysintf__arst_n;
    wire [0:0] _i_sysintf__reg_req_rdy;
    wire [0:0] _i_sysintf__reg_resp_val;
    wire [63:0] _i_sysintf__reg_resp_data;
    wire [0:0] _i_sysintf__ccm_req_val;
    wire [2:0] _i_sysintf__ccm_req_type;
    wire [39:0] _i_sysintf__ccm_req_addr;
    wire [63:0] _i_sysintf__ccm_req_data;
    wire [2:0] _i_sysintf__ccm_req_size;
    wire [0:0] _i_sysintf__ccm_req_threadid;
    wire [3:0] _i_sysintf__ccm_req_amo_opcode;
    wire [0:0] _i_sysintf__ccm_resp_rdy;
    wire [0:0] _i_sysintf__prog_rst_n;
    wire [0:0] _i_sysintf__prog_req_val;
    wire [11:0] _i_sysintf__prog_req_addr;
    wire [7:0] _i_sysintf__prog_req_strb;
    wire [63:0] _i_sysintf__prog_req_data;
    wire [0:0] _i_sysintf__prog_resp_rdy;
    wire [0:0] _i_sysintf__ureg_req_val;
    wire [11:0] _i_sysintf__ureg_req_addr;
    wire [7:0] _i_sysintf__ureg_req_strb;
    wire [63:0] _i_sysintf__ureg_req_data;
    wire [0:0] _i_sysintf__ureg_resp_rdy;
    wire [0:0] _i_sysintf__awready;
    wire [0:0] _i_sysintf__wready;
    wire [0:0] _i_sysintf__bvalid;
    wire [1:0] _i_sysintf__bresp;
    wire [0:0] _i_sysintf__bid;
    wire [0:0] _i_sysintf__arready;
    wire [0:0] _i_sysintf__rvalid;
    wire [1:0] _i_sysintf__rresp;
    wire [0:0] _i_sysintf__rid;
    wire [63:0] _i_sysintf__rdata;
    wire [0:0] _i_sysintf__rlast;
    wire [0:0] _i_sysintf__urst_n;
    wire [0:0] _i_core__ureg_req_rdy;
    wire [0:0] _i_core__ureg_resp_val;
    wire [63:0] _i_core__ureg_resp_data;
    wire [0:0] _i_core__ureg_resp_ecc;
    wire [0:0] _i_core__awvalid;
    wire [0:0] _i_core__awid;
    wire [39:0] _i_core__awaddr;
    wire [7:0] _i_core__awlen;
    wire [2:0] _i_core__awsize;
    wire [1:0] _i_core__awburst;
    wire [3:0] _i_core__awcache;
    wire [0:0] _i_core__awuser;
    wire [0:0] _i_core__awlock;
    wire [2:0] _i_core__awprot;
    wire [3:0] _i_core__awqos;
    wire [3:0] _i_core__awregion;
    wire [0:0] _i_core__wvalid;
    wire [63:0] _i_core__wdata;
    wire [7:0] _i_core__wstrb;
    wire [0:0] _i_core__wlast;
    wire [0:0] _i_core__wuser;
    wire [0:0] _i_core__bready;
    wire [0:0] _i_core__arvalid;
    wire [0:0] _i_core__arid;
    wire [39:0] _i_core__araddr;
    wire [7:0] _i_core__arlen;
    wire [2:0] _i_core__arsize;
    wire [1:0] _i_core__arburst;
    wire [0:0] _i_core__arlock;
    wire [3:0] _i_core__arcache;
    wire [68:0] _i_core__aruser;
    wire [2:0] _i_core__arprot;
    wire [3:0] _i_core__arqos;
    wire [3:0] _i_core__arregion;
    wire [0:0] _i_core__rready;
    wire [1:0] _i_core__prog_status;
    wire [0:0] _i_core__prog_req_rdy;
    wire [0:0] _i_core__prog_resp_val;
    wire [0:0] _i_core__prog_resp_err;
    wire [63:0] _i_core__prog_resp_data;
        
    prga_sysintf i_sysintf (
        .clk(clk)
        ,.rst_n(rst_n)
        ,.aclk(_i_sysintf__aclk)
        ,.arst_n(_i_sysintf__arst_n)
        ,.reg_req_rdy(_i_sysintf__reg_req_rdy)
        ,.reg_req_val(reg_req_val)
        ,.reg_req_addr(reg_req_addr)
        ,.reg_req_strb(reg_req_strb)
        ,.reg_req_data(reg_req_data)
        ,.reg_resp_rdy(reg_resp_rdy)
        ,.reg_resp_val(_i_sysintf__reg_resp_val)
        ,.reg_resp_data(_i_sysintf__reg_resp_data)
        ,.ccm_req_rdy(ccm_req_rdy)
        ,.ccm_req_val(_i_sysintf__ccm_req_val)
        ,.ccm_req_type(_i_sysintf__ccm_req_type)
        ,.ccm_req_addr(_i_sysintf__ccm_req_addr)
        ,.ccm_req_data(_i_sysintf__ccm_req_data)
        ,.ccm_req_size(_i_sysintf__ccm_req_size)
        ,.ccm_req_threadid(_i_sysintf__ccm_req_threadid)
        ,.ccm_req_amo_opcode(_i_sysintf__ccm_req_amo_opcode)
        ,.ccm_resp_rdy(_i_sysintf__ccm_resp_rdy)
        ,.ccm_resp_val(ccm_resp_val)
        ,.ccm_resp_type(ccm_resp_type)
        ,.ccm_resp_addr(ccm_resp_addr)
        ,.ccm_resp_data(ccm_resp_data)
        ,.ccm_resp_threadid(ccm_resp_threadid)
        ,.prog_rst_n(_i_sysintf__prog_rst_n)
        ,.prog_status(_i_core__prog_status)
        ,.prog_req_rdy(_i_core__prog_req_rdy)
        ,.prog_req_val(_i_sysintf__prog_req_val)
        ,.prog_req_addr(_i_sysintf__prog_req_addr)
        ,.prog_req_strb(_i_sysintf__prog_req_strb)
        ,.prog_req_data(_i_sysintf__prog_req_data)
        ,.prog_resp_rdy(_i_sysintf__prog_resp_rdy)
        ,.prog_resp_val(_i_core__prog_resp_val)
        ,.prog_resp_err(_i_core__prog_resp_err)
        ,.prog_resp_data(_i_core__prog_resp_data)
        ,.ureg_req_rdy(_i_core__ureg_req_rdy)
        ,.ureg_req_val(_i_sysintf__ureg_req_val)
        ,.ureg_req_addr(_i_sysintf__ureg_req_addr)
        ,.ureg_req_strb(_i_sysintf__ureg_req_strb)
        ,.ureg_req_data(_i_sysintf__ureg_req_data)
        ,.ureg_resp_rdy(_i_sysintf__ureg_resp_rdy)
        ,.ureg_resp_val(_i_core__ureg_resp_val)
        ,.ureg_resp_data(_i_core__ureg_resp_data)
        ,.ureg_resp_ecc(_i_core__ureg_resp_ecc)
        ,.awready(_i_sysintf__awready)
        ,.awvalid(_i_core__awvalid)
        ,.awid(_i_core__awid)
        ,.awaddr(_i_core__awaddr)
        ,.awlen(_i_core__awlen)
        ,.awsize(_i_core__awsize)
        ,.awburst(_i_core__awburst)
        ,.awcache(_i_core__awcache)
        ,.awuser(_i_core__awuser)
        ,.wready(_i_sysintf__wready)
        ,.wvalid(_i_core__wvalid)
        ,.wdata(_i_core__wdata)
        ,.wstrb(_i_core__wstrb)
        ,.wlast(_i_core__wlast)
        ,.wuser(_i_core__wuser)
        ,.bready(_i_core__bready)
        ,.bvalid(_i_sysintf__bvalid)
        ,.bresp(_i_sysintf__bresp)
        ,.bid(_i_sysintf__bid)
        ,.arready(_i_sysintf__arready)
        ,.arvalid(_i_core__arvalid)
        ,.arid(_i_core__arid)
        ,.araddr(_i_core__araddr)
        ,.arlen(_i_core__arlen)
        ,.arsize(_i_core__arsize)
        ,.arburst(_i_core__arburst)
        ,.arlock(_i_core__arlock)
        ,.arcache(_i_core__arcache)
        ,.aruser(_i_core__aruser)
        ,.rready(_i_core__rready)
        ,.rvalid(_i_sysintf__rvalid)
        ,.rresp(_i_sysintf__rresp)
        ,.rid(_i_sysintf__rid)
        ,.rdata(_i_sysintf__rdata)
        ,.rlast(_i_sysintf__rlast)
        ,.urst_n(_i_sysintf__urst_n)
        );
    prga_fabric_wrap i_core (
        .uclk(_i_sysintf__aclk)
        ,.urst_n(_i_sysintf__urst_n)
        ,.ureg_req_rdy(_i_core__ureg_req_rdy)
        ,.ureg_req_val(_i_sysintf__ureg_req_val)
        ,.ureg_req_addr(_i_sysintf__ureg_req_addr)
        ,.ureg_req_strb(_i_sysintf__ureg_req_strb)
        ,.ureg_req_data(_i_sysintf__ureg_req_data)
        ,.ureg_resp_rdy(_i_sysintf__ureg_resp_rdy)
        ,.ureg_resp_val(_i_core__ureg_resp_val)
        ,.ureg_resp_data(_i_core__ureg_resp_data)
        ,.ureg_resp_ecc(_i_core__ureg_resp_ecc)
        ,.awready(_i_sysintf__awready)
        ,.awvalid(_i_core__awvalid)
        ,.awid(_i_core__awid)
        ,.awaddr(_i_core__awaddr)
        ,.awlen(_i_core__awlen)
        ,.awsize(_i_core__awsize)
        ,.awburst(_i_core__awburst)
        ,.awcache(_i_core__awcache)
        ,.awuser(_i_core__awuser)
        ,.awlock(_i_core__awlock)
        ,.awprot(_i_core__awprot)
        ,.awqos(_i_core__awqos)
        ,.awregion(_i_core__awregion)
        ,.wready(_i_sysintf__wready)
        ,.wvalid(_i_core__wvalid)
        ,.wdata(_i_core__wdata)
        ,.wstrb(_i_core__wstrb)
        ,.wlast(_i_core__wlast)
        ,.wuser(_i_core__wuser)
        ,.bready(_i_core__bready)
        ,.bvalid(_i_sysintf__bvalid)
        ,.bresp(_i_sysintf__bresp)
        ,.bid(_i_sysintf__bid)
        ,.arready(_i_sysintf__arready)
        ,.arvalid(_i_core__arvalid)
        ,.arid(_i_core__arid)
        ,.araddr(_i_core__araddr)
        ,.arlen(_i_core__arlen)
        ,.arsize(_i_core__arsize)
        ,.arburst(_i_core__arburst)
        ,.arlock(_i_core__arlock)
        ,.arcache(_i_core__arcache)
        ,.aruser(_i_core__aruser)
        ,.arprot(_i_core__arprot)
        ,.arqos(_i_core__arqos)
        ,.arregion(_i_core__arregion)
        ,.rready(_i_core__rready)
        ,.rvalid(_i_sysintf__rvalid)
        ,.rresp(_i_sysintf__rresp)
        ,.rid(_i_sysintf__rid)
        ,.rdata(_i_sysintf__rdata)
        ,.rlast(_i_sysintf__rlast)
        ,.prog_rst_n(_i_sysintf__prog_rst_n)
        ,.prog_status(_i_core__prog_status)
        ,.prog_req_rdy(_i_core__prog_req_rdy)
        ,.prog_req_val(_i_sysintf__prog_req_val)
        ,.prog_req_addr(_i_sysintf__prog_req_addr)
        ,.prog_req_strb(_i_sysintf__prog_req_strb)
        ,.prog_req_data(_i_sysintf__prog_req_data)
        ,.prog_resp_rdy(_i_sysintf__prog_resp_rdy)
        ,.prog_resp_val(_i_core__prog_resp_val)
        ,.prog_resp_err(_i_core__prog_resp_err)
        ,.prog_resp_data(_i_core__prog_resp_data)
        ,.prog_clk(clk)
        );
        
    assign reg_req_rdy = _i_sysintf__reg_req_rdy;
    assign reg_resp_val = _i_sysintf__reg_resp_val;
    assign reg_resp_data = _i_sysintf__reg_resp_data;
    assign ccm_req_val = _i_sysintf__ccm_req_val;
    assign ccm_req_type = _i_sysintf__ccm_req_type;
    assign ccm_req_addr = _i_sysintf__ccm_req_addr;
    assign ccm_req_data = _i_sysintf__ccm_req_data;
    assign ccm_req_size = _i_sysintf__ccm_req_size;
    assign ccm_req_threadid = _i_sysintf__ccm_req_threadid;
    assign ccm_req_amo_opcode = _i_sysintf__ccm_req_amo_opcode;
    assign ccm_resp_rdy = _i_sysintf__ccm_resp_rdy;

endmodule
