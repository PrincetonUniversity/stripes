'''
==========================================================================
pyocn_mesh_valrdy.py
==========================================================================
Helper function that generates the pyocn_mesh_credit_ifc module.

SPDX-License-Identifier: BSD-3-Clause
Author : Yanghui Ou, Cornell University
  Date : Mar 18, 2020
'''

def print_module():
  tmpl = '''
module pyocn_router_valrdy (
  input clk,
  input reset,
  input  [`NOC_CHIPID_WIDTH-1:0] chipid,
  input  [`NOC_X_WIDTH-1     :0] pos_x,
  input  [`NOC_Y_WIDTH-1     :0] pos_y,
  input  [`DATA_WIDTH-1:0] in_N_dat,
  input                    in_N_val,
  output                   in_N_rdy,
  input  [`DATA_WIDTH-1:0] in_S_dat,
  input                    in_S_val,
  output                   in_S_rdy,
  input  [`DATA_WIDTH-1:0] in_W_dat,
  input                    in_W_val,
  output                   in_W_rdy,
  input  [`DATA_WIDTH-1:0] in_E_dat,
  input                    in_E_val,
  output                   in_E_rdy,
  input  [`DATA_WIDTH-1:0] in_P_dat,
  input                    in_P_val,
  output                   in_P_rdy,

  output [`DATA_WIDTH-1:0] out_N_dat,
  output                   out_N_val,
  input                    out_N_rdy,
  output [`DATA_WIDTH-1:0] out_S_dat,
  output                   out_S_val,
  input                    out_S_rdy,
  output [`DATA_WIDTH-1:0] out_W_dat,
  output                   out_W_val,
  input                    out_W_rdy,
  output [`DATA_WIDTH-1:0] out_E_dat,
  output                   out_E_val,
  input                    out_E_rdy,
  output [`DATA_WIDTH-1:0] out_P_dat,
  output                   out_P_val,
  input                    out_P_rdy

);

wire [`DATA_WIDTH-1:0] in_msg [0:4];
wire                   in_val [0:4];
wire                   in_rdy [0:4];
wire [`DATA_WIDTH-1:0] out_msg [0:4];
wire                   out_val [0:4];
wire                   out_rdy [0:4];

assign in_msg[0] = in_N_dat;
assign in_msg[1] = in_S_dat;
assign in_msg[2] = in_W_dat;
assign in_msg[3] = in_E_dat;
assign in_msg[4] = in_P_dat;

assign in_val[0] = in_N_val;
assign in_val[1] = in_S_val;
assign in_val[2] = in_W_val;
assign in_val[3] = in_E_val;
assign in_val[4] = in_P_val;

assign in_N_rdy = in_rdy[0];
assign in_S_rdy = in_rdy[1];
assign in_W_rdy = in_rdy[2];
assign in_E_rdy = in_rdy[3];
assign in_P_rdy = in_rdy[4];

assign out_N_dat = out_msg[0];
assign out_S_dat = out_msg[1];
assign out_W_dat = out_msg[2];
assign out_E_dat = out_msg[3];
assign out_P_dat = out_msg[4];

assign out_N_val = out_val[0];
assign out_S_val = out_val[1];
assign out_W_val = out_val[2];
assign out_E_val = out_val[3];
assign out_P_val = out_val[4];

assign out_rdy[0] = out_N_rdy;
assign out_rdy[1] = out_S_rdy;
assign out_rdy[2] = out_W_rdy;
assign out_rdy[3] = out_E_rdy;
assign out_rdy[4] = out_P_rdy;

pyocn_router router(
  .clk     ( clk   ),
  .reset   ( reset ),
  .pos     ( { chipid, pos_x, pos_y } ),
  .in___msg( in_msg ),
  .in___val( in_val ),
  .in___rdy( in_rdy ),
  .out__msg( out_msg ),
  .out__val( out_val ),
  .out__rdy( out_rdy )
);

endmodule
'''
  print( tmpl )
