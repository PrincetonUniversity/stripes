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
module prga_a_bmul (
    input wire [19:0] bi_u1v3n_L4
    , input wire [19:0] bi_u1y3s_L4
    , input wire [19:0] bi_u1v1n_L4
    , input wire [19:0] bi_u1v2n_L4
    , input wire [19:0] bi_u1y2s_L4
    , input wire [19:0] bi_u1y4s_L4
    , input wire [19:0] bi_u1y0e_L1
    , input wire [19:0] bi_u4y0e_L4
    , input wire [19:0] bi_x0y0w_L1
    , input wire [19:0] bi_x3y0w_L4
    , input wire [19:0] bi_u1y0e_L4
    , input wire [19:0] bi_u2y0e_L4
    , input wire [19:0] bi_u3y0e_L4
    , input wire [19:0] bi_x0y0w_L4
    , input wire [19:0] bi_x1y0w_L4
    , input wire [19:0] bi_x2y0w_L4
    , input wire [19:0] bi_u1v1n_L1
    , input wire [19:0] bi_u1v4n_L4
    , input wire [19:0] bi_u1v1e_L1
    , input wire [19:0] bi_u1v1e_L4
    , input wire [19:0] bi_u2v1e_L4
    , input wire [19:0] bi_u3v1e_L4
    , input wire [19:0] bi_u4v1e_L4
    , input wire [19:0] bi_x0v1w_L1
    , input wire [19:0] bi_x0v1w_L4
    , input wire [19:0] bi_x1v1w_L4
    , input wire [19:0] bi_x2v1w_L4
    , input wire [19:0] bi_x3v1w_L4
    , input wire [19:0] bi_u1y1e_L1
    , input wire [19:0] bi_u4y1e_L4
    , input wire [19:0] bi_u1y2s_L1
    , input wire [19:0] bi_u1y5s_L4
    , input wire [19:0] bi_x0y1w_L1
    , input wire [19:0] bi_x3y1w_L4
    , input wire [19:0] bi_u1y1e_L4
    , input wire [19:0] bi_u2y1e_L4
    , input wire [19:0] bi_u3y1e_L4
    , input wire [19:0] bi_x0y1w_L4
    , input wire [19:0] bi_x1y1w_L4
    , input wire [19:0] bi_x2y1w_L4
    , output wire [19:0] bo_u1y0w_L4
    , output wire [19:0] bo_u1y1w_L4
    , output wire [19:0] bo_u1y0w_L1
    , output wire [19:0] bo_u1y1w_L1
    , output wire [19:0] bo_u1y1s_L4
    , output wire [19:0] bo_u1y0s_L4
    , output wire [19:0] bo_u1y0s_L1
    , output wire [19:0] bo_u1y1n_L4
    , output wire [19:0] bo_u1y0n_L4
    , output wire [19:0] bo_u1y1n_L1
    , output wire [19:0] bo_x0y0e_L1
    , output wire [19:0] bo_x0y0e_L4
    , output wire [19:0] bo_x0y1e_L1
    , output wire [19:0] bo_x0y1e_L4
    , input wire [0:0] clk
    , input wire [0:0] prog_clk
    , input wire [0:0] prog_rst
    , input wire [0:0] prog_done
    , input wire [0:0] prog_we
    , input wire [0:0] prog_din
    , output wire [0:0] prog_dout
    , output wire [0:0] prog_we_o
    );
    
        
    wire [19:0] _i_tile_x0y0__cu_u1y0n_L1;
    wire [19:0] _i_tile_x0y0__cu_u1y0s_L1;
    wire [19:0] _i_tile_x0y0__cu_u1y0n_L4;
    wire [19:0] _i_tile_x0y0__cu_u1y0s_L4;
    wire [19:0] _i_tile_x0y0__cu_u1y1n_L1;
    wire [19:0] _i_tile_x0y0__cu_u1y1s_L1;
    wire [19:0] _i_tile_x0y0__cu_u1y1n_L4;
    wire [19:0] _i_tile_x0y0__cu_u1y1s_L4;
    wire [0:0] _i_tile_x0y0__prog_dout;
    wire [0:0] _i_tile_x0y0__prog_we_o;
    wire [19:0] _i_sbox_x0y0nw__so_x0y0e_L4;
    wire [19:0] _i_sbox_x0y0nw__so_x0y0e_L1;
    wire [19:0] _i_sbox_x0y0nw__so_u1y0w_L4;
    wire [19:0] _i_sbox_x0y0nw__so_u1y0w_L1;
    wire [19:0] _i_sbox_x0y0nw__so_u1y0s_L1;
    wire [19:0] _i_sbox_x0y0nw__so_u1y0s_L4;
    wire [0:0] _i_sbox_x0y0nw__prog_dout;
    wire [0:0] _i_sbox_x0y0nw__prog_we_o;
    wire [19:0] _i_sbox_x0y0sw__so_u1y0n_L1;
    wire [19:0] _i_sbox_x0y0sw__so_u1y0n_L4;
    wire [0:0] _i_sbox_x0y0sw__prog_dout;
    wire [0:0] _i_sbox_x0y0sw__prog_we_o;
    wire [19:0] _i_sbox_x0y1nw__so_x0y0e_L4;
    wire [19:0] _i_sbox_x0y1nw__so_x0y0e_L1;
    wire [19:0] _i_sbox_x0y1nw__so_u1y0w_L4;
    wire [19:0] _i_sbox_x0y1nw__so_u1y0w_L1;
    wire [19:0] _i_sbox_x0y1nw__so_u1y0s_L1;
    wire [19:0] _i_sbox_x0y1nw__so_u1y0s_L4;
    wire [0:0] _i_sbox_x0y1nw__prog_dout;
    wire [0:0] _i_sbox_x0y1nw__prog_we_o;
    wire [19:0] _i_sbox_x0y1sw__so_u1y0n_L1;
    wire [19:0] _i_sbox_x0y1sw__so_u1y0n_L4;
    wire [0:0] _i_sbox_x0y1sw__prog_dout;
    wire [0:0] _i_sbox_x0y1sw__prog_we_o;
    wire [0:0] _i_buf_prog_rst_l0__Q;
    wire [0:0] _i_buf_prog_done_l0__Q;
    wire [0:0] _i_buf_prog_rst_l1__Q;
    wire [0:0] _i_buf_prog_done_l1__Q;
    wire [0:0] _i_buf_prog_rst_l2__Q;
    wire [0:0] _i_buf_prog_done_l2__Q;
        
    prga_t_bmul i_tile_x0y0 (
        .bi_u1y0n_L1(_i_sbox_x0y0sw__so_u1y0n_L1)
        ,.bi_u1y0s_L1(_i_sbox_x0y0nw__so_u1y0s_L1)
        ,.cu_u1y0n_L1(_i_tile_x0y0__cu_u1y0n_L1)
        ,.cu_u1y0s_L1(_i_tile_x0y0__cu_u1y0s_L1)
        ,.bi_u1y0n_L4(_i_sbox_x0y0sw__so_u1y0n_L4)
        ,.bi_u1y0s_L4(_i_sbox_x0y0nw__so_u1y0s_L4)
        ,.bi_u1v3n_L4(bi_u1v3n_L4)
        ,.bi_u1y3s_L4(bi_u1y3s_L4)
        ,.bi_u1v1n_L4(bi_u1v1n_L4)
        ,.bi_u1y1s_L4(_i_sbox_x0y1nw__so_u1y0s_L4)
        ,.bi_u1v2n_L4(bi_u1v2n_L4)
        ,.bi_u1y2s_L4(bi_u1y2s_L4)
        ,.cu_u1y0n_L4(_i_tile_x0y0__cu_u1y0n_L4)
        ,.cu_u1y0s_L4(_i_tile_x0y0__cu_u1y0s_L4)
        ,.bi_u1y1n_L1(_i_sbox_x0y1sw__so_u1y0n_L1)
        ,.bi_u1y1s_L1(_i_sbox_x0y1nw__so_u1y0s_L1)
        ,.cu_u1y1n_L1(_i_tile_x0y0__cu_u1y1n_L1)
        ,.cu_u1y1s_L1(_i_tile_x0y0__cu_u1y1s_L1)
        ,.bi_u1y1n_L4(_i_sbox_x0y1sw__so_u1y0n_L4)
        ,.bi_u1y4s_L4(bi_u1y4s_L4)
        ,.cu_u1y1n_L4(_i_tile_x0y0__cu_u1y1n_L4)
        ,.cu_u1y1s_L4(_i_tile_x0y0__cu_u1y1s_L4)
        ,.clk(clk)
        ,.prog_clk(prog_clk)
        ,.prog_rst(_i_buf_prog_rst_l2__Q)
        ,.prog_done(_i_buf_prog_done_l2__Q)
        ,.prog_we(_i_sbox_x0y0sw__prog_we_o)
        ,.prog_din(_i_sbox_x0y0sw__prog_dout)
        ,.prog_dout(_i_tile_x0y0__prog_dout)
        ,.prog_we_o(_i_tile_x0y0__prog_we_o)
        );
    sbox_nw_ESW i_sbox_x0y0nw (
        .bi_u1y0n_L1(_i_sbox_x0y0sw__so_u1y0n_L1)
        ,.so_x0y0e_L4(_i_sbox_x0y0nw__so_x0y0e_L4)
        ,.so_x0y0e_L1(_i_sbox_x0y0nw__so_x0y0e_L1)
        ,.bi_u1y0n_L4(_i_sbox_x0y0sw__so_u1y0n_L4)
        ,.bi_u1v1n_L4(bi_u1v1n_L4)
        ,.bi_u1v2n_L4(bi_u1v2n_L4)
        ,.bi_u1v3n_L4(bi_u1v3n_L4)
        ,.bi_u1y0e_L1(bi_u1y0e_L1)
        ,.bi_u4y0e_L4(bi_u4y0e_L4)
        ,.bi_u1y1s_L1(_i_sbox_x0y1nw__so_u1y0s_L1)
        ,.bi_u1y1s_L4(_i_sbox_x0y1nw__so_u1y0s_L4)
        ,.bi_u1y2s_L4(bi_u1y2s_L4)
        ,.bi_u1y3s_L4(bi_u1y3s_L4)
        ,.bi_u1y4s_L4(bi_u1y4s_L4)
        ,.so_u1y0w_L4(_i_sbox_x0y0nw__so_u1y0w_L4)
        ,.so_u1y0w_L1(_i_sbox_x0y0nw__so_u1y0w_L1)
        ,.bi_x0y0w_L1(bi_x0y0w_L1)
        ,.bi_x3y0w_L4(bi_x3y0w_L4)
        ,.so_u1y0s_L1(_i_sbox_x0y0nw__so_u1y0s_L1)
        ,.so_u1y0s_L4(_i_sbox_x0y0nw__so_u1y0s_L4)
        ,.bi_u1y0e_L4(bi_u1y0e_L4)
        ,.bi_u2y0e_L4(bi_u2y0e_L4)
        ,.bi_u3y0e_L4(bi_u3y0e_L4)
        ,.bi_x0y0w_L4(bi_x0y0w_L4)
        ,.bi_x1y0w_L4(bi_x1y0w_L4)
        ,.bi_x2y0w_L4(bi_x2y0w_L4)
        ,.cu_u1y0s_L1(_i_tile_x0y0__cu_u1y0s_L1)
        ,.cu_u1y0s_L4(_i_tile_x0y0__cu_u1y0s_L4)
        ,.prog_clk(prog_clk)
        ,.prog_rst(_i_buf_prog_rst_l1__Q)
        ,.prog_done(_i_buf_prog_done_l1__Q)
        ,.prog_we(_i_tile_x0y0__prog_we_o)
        ,.prog_din(_i_tile_x0y0__prog_dout)
        ,.prog_dout(_i_sbox_x0y0nw__prog_dout)
        ,.prog_we_o(_i_sbox_x0y0nw__prog_we_o)
        );
    sbox_sw_N i_sbox_x0y0sw (
        .bi_u1v1n_L1(bi_u1v1n_L1)
        ,.so_u1y0n_L1(_i_sbox_x0y0sw__so_u1y0n_L1)
        ,.bi_u1v4n_L4(bi_u1v4n_L4)
        ,.so_u1y0n_L4(_i_sbox_x0y0sw__so_u1y0n_L4)
        ,.bi_u1v1e_L1(bi_u1v1e_L1)
        ,.bi_u1v1e_L4(bi_u1v1e_L4)
        ,.bi_u2v1e_L4(bi_u2v1e_L4)
        ,.bi_u3v1e_L4(bi_u3v1e_L4)
        ,.bi_u4v1e_L4(bi_u4v1e_L4)
        ,.bi_x0v1w_L1(bi_x0v1w_L1)
        ,.bi_x0v1w_L4(bi_x0v1w_L4)
        ,.bi_x1v1w_L4(bi_x1v1w_L4)
        ,.bi_x2v1w_L4(bi_x2v1w_L4)
        ,.bi_x3v1w_L4(bi_x3v1w_L4)
        ,.cu_u1y0n_L1(_i_tile_x0y0__cu_u1y0n_L1)
        ,.cu_u1y0n_L4(_i_tile_x0y0__cu_u1y0n_L4)
        ,.prog_clk(prog_clk)
        ,.prog_rst(_i_buf_prog_rst_l1__Q)
        ,.prog_done(_i_buf_prog_done_l1__Q)
        ,.prog_we(prog_we)
        ,.prog_din(prog_din)
        ,.prog_dout(_i_sbox_x0y0sw__prog_dout)
        ,.prog_we_o(_i_sbox_x0y0sw__prog_we_o)
        );
    sbox_nw_ESW i_sbox_x0y1nw (
        .bi_u1y0n_L1(_i_sbox_x0y1sw__so_u1y0n_L1)
        ,.so_x0y0e_L4(_i_sbox_x0y1nw__so_x0y0e_L4)
        ,.so_x0y0e_L1(_i_sbox_x0y1nw__so_x0y0e_L1)
        ,.bi_u1y0n_L4(_i_sbox_x0y1sw__so_u1y0n_L4)
        ,.bi_u1v1n_L4(_i_sbox_x0y0sw__so_u1y0n_L4)
        ,.bi_u1v2n_L4(bi_u1v1n_L4)
        ,.bi_u1v3n_L4(bi_u1v2n_L4)
        ,.bi_u1y0e_L1(bi_u1y1e_L1)
        ,.bi_u4y0e_L4(bi_u4y1e_L4)
        ,.bi_u1y1s_L1(bi_u1y2s_L1)
        ,.bi_u1y1s_L4(bi_u1y2s_L4)
        ,.bi_u1y2s_L4(bi_u1y3s_L4)
        ,.bi_u1y3s_L4(bi_u1y4s_L4)
        ,.bi_u1y4s_L4(bi_u1y5s_L4)
        ,.so_u1y0w_L4(_i_sbox_x0y1nw__so_u1y0w_L4)
        ,.so_u1y0w_L1(_i_sbox_x0y1nw__so_u1y0w_L1)
        ,.bi_x0y0w_L1(bi_x0y1w_L1)
        ,.bi_x3y0w_L4(bi_x3y1w_L4)
        ,.so_u1y0s_L1(_i_sbox_x0y1nw__so_u1y0s_L1)
        ,.so_u1y0s_L4(_i_sbox_x0y1nw__so_u1y0s_L4)
        ,.bi_u1y0e_L4(bi_u1y1e_L4)
        ,.bi_u2y0e_L4(bi_u2y1e_L4)
        ,.bi_u3y0e_L4(bi_u3y1e_L4)
        ,.bi_x0y0w_L4(bi_x0y1w_L4)
        ,.bi_x1y0w_L4(bi_x1y1w_L4)
        ,.bi_x2y0w_L4(bi_x2y1w_L4)
        ,.cu_u1y0s_L1(_i_tile_x0y0__cu_u1y1s_L1)
        ,.cu_u1y0s_L4(_i_tile_x0y0__cu_u1y1s_L4)
        ,.prog_clk(prog_clk)
        ,.prog_rst(_i_buf_prog_rst_l1__Q)
        ,.prog_done(_i_buf_prog_done_l1__Q)
        ,.prog_we(_i_sbox_x0y1sw__prog_we_o)
        ,.prog_din(_i_sbox_x0y1sw__prog_dout)
        ,.prog_dout(_i_sbox_x0y1nw__prog_dout)
        ,.prog_we_o(_i_sbox_x0y1nw__prog_we_o)
        );
    sbox_sw_N i_sbox_x0y1sw (
        .bi_u1v1n_L1(_i_sbox_x0y0sw__so_u1y0n_L1)
        ,.so_u1y0n_L1(_i_sbox_x0y1sw__so_u1y0n_L1)
        ,.bi_u1v4n_L4(bi_u1v3n_L4)
        ,.so_u1y0n_L4(_i_sbox_x0y1sw__so_u1y0n_L4)
        ,.bi_u1v1e_L1(bi_u1y0e_L1)
        ,.bi_u1v1e_L4(bi_u1y0e_L4)
        ,.bi_u2v1e_L4(bi_u2y0e_L4)
        ,.bi_u3v1e_L4(bi_u3y0e_L4)
        ,.bi_u4v1e_L4(bi_u4y0e_L4)
        ,.bi_x0v1w_L1(bi_x0y0w_L1)
        ,.bi_x0v1w_L4(bi_x0y0w_L4)
        ,.bi_x1v1w_L4(bi_x1y0w_L4)
        ,.bi_x2v1w_L4(bi_x2y0w_L4)
        ,.bi_x3v1w_L4(bi_x3y0w_L4)
        ,.cu_u1y0n_L1(_i_tile_x0y0__cu_u1y1n_L1)
        ,.cu_u1y0n_L4(_i_tile_x0y0__cu_u1y1n_L4)
        ,.prog_clk(prog_clk)
        ,.prog_rst(_i_buf_prog_rst_l1__Q)
        ,.prog_done(_i_buf_prog_done_l1__Q)
        ,.prog_we(_i_sbox_x0y0nw__prog_we_o)
        ,.prog_din(_i_sbox_x0y0nw__prog_dout)
        ,.prog_dout(_i_sbox_x0y1sw__prog_dout)
        ,.prog_we_o(_i_sbox_x0y1sw__prog_we_o)
        );
    prga_simple_buf i_buf_prog_rst_l0 (
        .C(prog_clk)
        ,.D(_i_buf_prog_rst_l1__Q)
        ,.Q(_i_buf_prog_rst_l0__Q)
        );
    prga_simple_bufr i_buf_prog_done_l0 (
        .C(prog_clk)
        ,.R(_i_buf_prog_rst_l0__Q)
        ,.D(_i_buf_prog_done_l1__Q)
        ,.Q(_i_buf_prog_done_l0__Q)
        );
    prga_simple_buf i_buf_prog_rst_l1 (
        .C(prog_clk)
        ,.D(_i_buf_prog_rst_l2__Q)
        ,.Q(_i_buf_prog_rst_l1__Q)
        );
    prga_simple_bufr i_buf_prog_done_l1 (
        .C(prog_clk)
        ,.R(_i_buf_prog_rst_l0__Q)
        ,.D(_i_buf_prog_done_l2__Q)
        ,.Q(_i_buf_prog_done_l1__Q)
        );
    prga_simple_buf i_buf_prog_rst_l2 (
        .C(prog_clk)
        ,.D(prog_rst)
        ,.Q(_i_buf_prog_rst_l2__Q)
        );
    prga_simple_bufr i_buf_prog_done_l2 (
        .C(prog_clk)
        ,.R(_i_buf_prog_rst_l0__Q)
        ,.D(prog_done)
        ,.Q(_i_buf_prog_done_l2__Q)
        );
        
    assign bo_u1y0w_L4 = _i_sbox_x0y0nw__so_u1y0w_L4;
    assign bo_u1y1w_L4 = _i_sbox_x0y1nw__so_u1y0w_L4;
    assign bo_u1y0w_L1 = _i_sbox_x0y0nw__so_u1y0w_L1;
    assign bo_u1y1w_L1 = _i_sbox_x0y1nw__so_u1y0w_L1;
    assign bo_u1y1s_L4 = _i_sbox_x0y1nw__so_u1y0s_L4;
    assign bo_u1y0s_L4 = _i_sbox_x0y0nw__so_u1y0s_L4;
    assign bo_u1y0s_L1 = _i_sbox_x0y0nw__so_u1y0s_L1;
    assign bo_u1y1n_L4 = _i_sbox_x0y1sw__so_u1y0n_L4;
    assign bo_u1y0n_L4 = _i_sbox_x0y0sw__so_u1y0n_L4;
    assign bo_u1y1n_L1 = _i_sbox_x0y1sw__so_u1y0n_L1;
    assign bo_x0y0e_L1 = _i_sbox_x0y0nw__so_x0y0e_L1;
    assign bo_x0y0e_L4 = _i_sbox_x0y0nw__so_x0y0e_L4;
    assign bo_x0y1e_L1 = _i_sbox_x0y1nw__so_x0y0e_L1;
    assign bo_x0y1e_L4 = _i_sbox_x0y1nw__so_x0y0e_L4;
    assign prog_dout = _i_sbox_x0y1nw__prog_dout;
    assign prog_we_o = _i_sbox_x0y1nw__prog_we_o;

endmodule
