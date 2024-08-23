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

//`timescale 1 ns / 10 ps
`include "dream.h"
`include "dcp.h"

`ifdef DEFAULT_NETTYPE_NONE
`default_nettype none
`endif

module dream (
    input  wire clk,
    input  wire rst_n,

    input  wire                             config_hsk,     // Any opcode into Dream or Scratchpad
    input  wire [22:0]                      config_addr,    // noc1decoder_dcp_address
    input  wire [31:0]                      config_data_hi, // noc1decoder_dcp_data
    input  wire [31:0]                      config_data_lo,
    input  wire                             config_load,    // It is a Load if set, else a Store
    input  wire                             config_spd,     // It is a Scratchpad request (either load or store)
    input  wire [`MSG_DATA_SIZE_WIDTH-1:0]  config_size,  

    // NOC1 - Outgoing noshare_load/swap_wb request to L2 
    input  wire                             dream_noc1buffer_rdy,
    output wire                             dream_noc1buffer_val,
    output wire [`MSG_TYPE_WIDTH-1:0]       dream_noc1buffer_type,
    output wire [`DCP_MSHRID_WIDTH -1:0]    dream_noc1buffer_mshrid,
    output wire [`DCP_PADDR_MASK       ]    dream_noc1buffer_address,
    output wire [`DCP_UNPARAM_2_0      ]    dream_noc1buffer_size,
    output wire [`DCP_UNPARAM_63_0     ]    dream_noc1buffer_data_0,
    output wire [`DCP_UNPARAM_63_0     ]    dream_noc1buffer_data_1,
    output wire [`MSG_AMO_MASK_WIDTH-1:0]   dream_noc1buffer_write_mask,

    // NOC2 - Incoming noshare_load/swap_wb response from L2
    input  wire                              noc2decoder_dream_val,
    input  wire [`DCP_MSHRID_WIDTH -1:0]     noc2decoder_dream_mshrid,
    input  wire [`DCP_NOC_RES_DATA_SIZE-1:0] noc2decoder_dream_data,

    // Scratchpad interface 
    output wire                             dream_sp_val,
    output wire [15:0]                      dream_sp_addr,
    output wire                             dream_sp_rdwen,
    output reg  [511:0]                     dream_sp_bw,
    output reg  [511:0]                     dream_sp_wdata,
    input  wire [511:0]                     sp_dream_rdata,

    output wire [63:0]                      dream_ariane_data,
    output wire                             dream_read_to_ariane
);

// Common Local Parameters
localparam sp_entry_used = `DREAM_MB_LD_MSHR_SIZE * 20;
localparam noc1_data_size = `MSG_TYPE_WIDTH + `DCP_MSHRID_WIDTH + `DCP_PADDR_HI + 1 + 3 + `DREAM_NOC1_DATA_WIDTH + `MSG_AMO_MASK_WIDTH;

genvar j;

// Flop the reset
reg rst_n_f;
always @(posedge clk) begin
    rst_n_f <= rst_n;
end

wire                             dream_noc1buffer_rdy_f;
reg                              dream_noc1buffer_val_f;
reg  [`MSG_TYPE_WIDTH-1:0]       dream_noc1buffer_type_f;
reg  [`DCP_MSHRID_WIDTH -1:0]    dream_noc1buffer_mshrid_f;
reg  [`DCP_PADDR_MASK       ]    dream_noc1buffer_address_f;
reg  [`DCP_UNPARAM_2_0      ]    dream_noc1buffer_size_f;
reg  [`DCP_UNPARAM_63_0     ]    dream_noc1buffer_data_0_f;
reg  [`DCP_UNPARAM_63_0     ]    dream_noc1buffer_data_1_f;
reg  [`MSG_AMO_MASK_WIDTH-1:0]   dream_noc1buffer_write_mask_f;


prga_valrdy_buf # (.REGISTERED(1), .DECOUPLED(1), .DATA_WIDTH(noc1_data_size)) 
    dream_noc1buffer_buf (
    .clk            (clk)
    ,.rst           (~rst_n_f)
    ,.rdy_o         (dream_noc1buffer_rdy_f)
    ,.val_i         (dream_noc1buffer_val_f)
    ,.data_i        ({dream_noc1buffer_type_f, dream_noc1buffer_mshrid_f, dream_noc1buffer_address_f, dream_noc1buffer_size_f, dream_noc1buffer_data_0_f, dream_noc1buffer_data_1_f, dream_noc1buffer_write_mask_f})
    ,.rdy_i         (dream_noc1buffer_rdy)
    ,.val_o         (dream_noc1buffer_val)
    ,.data_o        ({dream_noc1buffer_type, dream_noc1buffer_mshrid, dream_noc1buffer_address, dream_noc1buffer_size, dream_noc1buffer_data_0, dream_noc1buffer_data_1, dream_noc1buffer_write_mask})
);

////////////////////////////
// Config
/////////////////////////////

wire [`DREAM_CONFIG_WIDTH-1:0] config_pkt_num = config_addr[`DREAM_CONFIG_PKT];

wire [`DREAM_CONFIG_DATA_WIDTH-1:0]   c0_data;
reg  [`DREAM_OPCODE_WIDTH-1:0]        c0_op;
reg  [`DREAM_PADDR_MASK]              c0_src_addr_r, c0_dest_addr_r; 
reg  [`DREAM_MAX_COPY_SIZE_BIT-1:0]   c0_copy_size_r;
reg  [`DREAM_MAX_NUM_FIELD_BIT-1:0]   c0_num_field_r;
reg  [`DREAM_CONFIG_DATA_WIDTH-1:0]   c0_field_size_0_r, c0_field_size_1_r;
reg  [`DREAM_MAX_NUM_ELEMENT_BIT-1:0] c0_num_elements_r;
reg  [`DREAM_MAX_ELEMENT_SIZE_BIT-1:0] c0_structure_size_r;
reg  [3:0] c0_num_elements_bit_r;
reg  c0_invalidate_r;

wire dream_config_hsk = config_hsk && !config_spd;

generate if (`LITTLE_ENDIAN) begin : little_endian_gen 
    assign c0_data = {config_data_hi[7:0],config_data_hi[15:8],config_data_hi[23:16],config_data_hi[31:24],
                     config_data_lo[7:0],config_data_lo[15:8],config_data_lo[23:16],config_data_lo[31:24]};
end else begin : big_endian_gen
    assign c0_data = {config_data_hi,config_data_lo};
end endgenerate

always @(posedge clk) begin
    if (!rst_n_f) begin
        c0_op <= {`DREAM_OPCODE_WIDTH{1'b0}};
        c0_src_addr_r <= {`DREAM_PADDR_HI{1'b0}};
        c0_dest_addr_r <= {`DREAM_PADDR_HI{1'b0}};
        c0_copy_size_r <= {`DREAM_MAX_COPY_SIZE_BIT{1'b0}};
        c0_num_field_r <= {`DREAM_MAX_NUM_FIELD_BIT{1'b0}};
        c0_field_size_0_r <= 64'd0;
        c0_field_size_1_r <= 64'd0;
        c0_num_elements_r <= {`DREAM_MAX_NUM_ELEMENT_BIT{1'b0}};
        c0_num_elements_bit_r <= 4'd0;
        c0_structure_size_r <= {`DREAM_MAX_ELEMENT_SIZE_BIT{1'b0}};
        c0_invalidate_r <= 1'd0;
    end
    else if (dream_config_hsk && !config_load) begin
        case (config_pkt_num)
            `DREAM_CONFIG_OP:
                c0_op <= c0_data[`DREAM_OPCODE_WIDTH-1:0];
            `DREAM_CONFIG_SRC_ADDR: 
                c0_src_addr_r <= c0_data[`DREAM_PADDR_MASK];
            `DREAM_CONFIG_DEST_ADDR:
                c0_dest_addr_r <= c0_data[`DREAM_PADDR_MASK];
            `DREAM_CONFIG_COPY_SIZE:
                c0_copy_size_r <= c0_data[`DREAM_MAX_COPY_SIZE_BIT-1:0];
            `NUM_FIELD:
                c0_num_field_r <= c0_data[`DREAM_MAX_NUM_FIELD_BIT-1:0];
            `FIELD_SIZE_0:
                c0_field_size_0_r <= c0_data;
            `FIELD_SIZE_1:
                c0_field_size_1_r <= c0_data;
            `NUM_ELEMENT:
                c0_num_elements_r <= c0_data[`DREAM_MAX_NUM_ELEMENT_BIT-1:0];
            `NUM_ELEMENT_BIT:
                c0_num_elements_bit_r <= c0_data[3:0];
            `STRUCTURE_SIZE:
                c0_structure_size_r <= c0_data[`DREAM_MAX_ELEMENT_SIZE_BIT-1:0];   
            `DREAM_STOP:
                c0_invalidate_r <= c0_data[0];
        endcase
    end
end

reg  [`DREAM_MAX_FIELD_SIZE_BIT-1:0] field_size [`DREAM_MAX_NUM_FIELD-1:0];
reg  [`DREAM_PADDR_HI-1:0] field_base_addr [`DREAM_MAX_NUM_FIELD-1:0];

reg [2:0] dream_st_current_field_size, dream_st_buf_current_field_size;

reg  [`DREAM_MAX_NUM_FIELD_BIT-1:0]     dream_field_counter, dream_field_counter_nxt;
reg  [`DREAM_MAX_NUM_ELEMENT_BIT-1:0]   dream_st_element_counter;
reg  [`DREAM_MAX_NUM_ELEMENT_BIT-1:0]   dream_st_element_counter_nxt;

reg  [1023:0]  sp_data_status;
reg  [10:0] new_base_bit;

reg start_config;
reg [4:0] config_counter;

generate
    for (j=0; j<16; j++) begin: field_size_gen
        always @(posedge clk) begin
            if(!rst_n_f) begin
                field_size[j] <= {`DREAM_MAX_FIELD_SIZE_BIT{1'b0}};
            end else if(start_config) begin
                if(j<8) begin
                    field_size[j] <= c0_field_size_0_r[j*8+:8];
                end else begin
                    field_size[j] <= c0_field_size_1_r[(j-8)*8+:8];
                end
            end
        end
    end
endgenerate

generate
    for (j=0; j<16; j++) begin: field_base_addr_gen
        always @(posedge clk) begin
            if(!rst_n_f) begin
                field_base_addr[j] <= {`DREAM_MAX_FIELD_SIZE_BIT{1'b0}};
            end else if(j==config_counter && start_config) begin
                if(j==0) begin
                    field_base_addr[j] <= c0_dest_addr_r;
                end else begin
                    if(c0_op == `DREAM_AOS_SOA_OP) begin
                        field_base_addr[j] <= field_base_addr[j-1] + ((1<<field_size[j-1]) << c0_num_elements_bit_r);
                    end else begin
                        field_base_addr[j] <= field_base_addr[j-1] + (1<<field_size[j-1]);
                    end
                end
            end
        end
    end
endgenerate

wire dest_scratchpad = (c0_dest_addr_r[22:20] == 3'd1) ? 1'b1 : 1'b0;

reg [`DREAM_MAX_LOAD_CNT_BIT-1:0] total_ld;
reg [`DREAM_MAX_STORE_CNT_BIT-1:0] total_st;
reg [`DREAM_MAX_DATA_SIZE_BIT-1:0] data_size;


wire [4:0] aos_dream_st_data_buffer_size = (total_ld > 5'd16) ? 5'd16 : total_ld;

always @(posedge clk) begin
    if(!rst_n_f) begin
        data_size <= {`DREAM_MAX_DATA_SIZE_BIT{1'b0}};
    end else if (config_counter==5'd0 && start_config) begin
        if (c0_op == `DREAM_AOS_SOA_OP || c0_op == `DREAM_SOA_AOS_OP) begin
            data_size <= (c0_structure_size_r << c0_num_elements_bit_r);
        end
    end
end

always @(posedge clk) begin
    if(!rst_n_f) begin
        total_ld <= {`DREAM_MAX_LOAD_CNT_BIT{1'b0}};
        total_st <= {`DREAM_MAX_STORE_CNT_BIT{1'b0}};
    end else if (config_counter==5'd1 && start_config) begin
        if(c0_op == `DREAM_COPY_OP) begin
            total_ld <= {4'd0, c0_copy_size_r[`DREAM_MAX_COPY_SIZE_BIT-1:6]};
            total_st <= c0_copy_size_r >> 4;
        end else if (c0_op == `DREAM_AOS_SOA_OP || c0_op == `DREAM_SOA_AOS_OP) begin
            total_ld <= data_size[`DREAM_MAX_DATA_SIZE_BIT-1:6];
            total_st <= c0_num_elements_r * c0_num_field_r;
        end
    end
end

reg c0_ready;

// TODO: block new request when old one is not done yet
always @(posedge clk) begin
    if (!rst_n_f) begin
        c0_ready <= 1'b0;
    end else if (config_counter == 5'd16) begin
        c0_ready <= 1'b1;
    end else begin 
        c0_ready <= 1'b0;
    end
end

always @(posedge clk) begin
    if (!rst_n_f) begin
        start_config <= 1'b0;
    end else if (dream_config_hsk && (c0_data[63]==1'b1) && !config_load) begin
        start_config <= 1'b1;
    end else if(config_counter == 5'd16) begin 
        start_config <= 1'b0;
    end
end

always @(posedge clk) begin
    if (!rst_n_f) begin
        config_counter <= 5'd0;
    end else if (start_config) begin
        config_counter <= config_counter + 5'd1;
    end else if(config_counter == 5'd16) begin 
        config_counter <= 5'd0;
    end
end

reg dream_working, dream_done;
reg [`DREAM_MAX_LOAD_CNT_BIT-1:0] ld_cnt;
reg [`DREAM_MAX_STORE_CNT_BIT-1:0] st_cnt;

always @(posedge clk) begin
    if (!rst_n_f) begin
        dream_working <= 1'b0;
    end else if (c0_invalidate_r) begin
        dream_working <= 1'b0;
    end else if (c0_ready) begin
        dream_working <= 1'b1;
    end else if (ld_cnt == total_ld && st_cnt == total_st) begin 
        dream_working <= 1'b0;
    end
end

reg                                 mb_ld_add_val, mb_st_add_val; 
wire                                mb_ld_add_rdy, mb_st_add_rdy; 
wire                                mb_ld_add_hsk, mb_st_add_hsk; 
wire  [`DREAM_MB_SIZE_BITS-1:0]     mb_ld_add_idx, mb_st_add_idx;
reg                                 mb_ld_clr_rdy, mb_st_clr_rdy; 
reg   [`DREAM_MB_SIZE_BITS-1:0]     mb_ld_clr_idx, mb_st_clr_idx; 
wire                                mb_ld_mshr_full, mb_ld_full, mb_st_full;
wire  [`DREAM_MB_LD_MSHR_SIZE-1:0]  mb_ld_slot_val; 
wire  [`DREAM_MB_SIZE-1:0]          mb_st_slot_val;
wire  [9:0]                         mb_ld_add_idx_addr, mb_st_add_idx_addr;

dream_mshr # (.MB_SIZE_BITS(6), .MB_SIZE(`DREAM_MB_LD_MSHR_SIZE))
    u_ld_mshr (
    .clk (clk),
    .rst_n (rst_n_f),
    .mb_add_val (mb_ld_add_val), 
    .mb_add_rdy (mb_ld_add_rdy), 
    .mb_add_hsk (mb_ld_add_hsk), 
    .mb_add_idx (mb_ld_add_idx),
    .mb_clr_rdy (mb_ld_clr_rdy), 
    .mb_clr_idx (mb_ld_clr_idx),
    .mb_full (mb_ld_mshr_full),
    .mb_slot_val (mb_ld_slot_val),
    .mb_add_idx_addr (mb_ld_add_idx_addr),
    .sp_data_status (sp_data_status)
);

assign mb_ld_full = mb_ld_mshr_full || (sp_data_status[mb_ld_add_idx_addr] == 1'b1);

dream_mshr # (.MB_SIZE_BITS(6))
    u_st_mshr (
    .clk (clk),
    .rst_n (rst_n_f),
    .mb_add_val (mb_st_add_val), 
    .mb_add_rdy (mb_st_add_rdy), 
    .mb_add_hsk (mb_st_add_hsk), 
    .mb_add_idx (mb_st_add_idx),
    .mb_clr_rdy (mb_st_clr_rdy), 
    .mb_clr_idx (mb_st_clr_idx),
    .mb_full (mb_st_full),
    .mb_slot_val (mb_st_slot_val),
    .mb_add_idx_addr (mb_st_add_idx_addr),
    .sp_data_status (sp_data_status)
);


/////////////////////////////
// Send noc1 request
/////////////////////////////

wire dream_noc1buffer_hsk;

reg  noc1_ld_val, noc1_st_val;
wire noc1_ld_rdy, noc1_ld_hsk;
wire noc1_st_rdy, noc1_st_hsk;

assign dream_noc1buffer_hsk = dream_noc1buffer_rdy_f && dream_noc1buffer_val_f;

assign noc1_ld_rdy = dream_noc1buffer_rdy_f && noc1_ld_val;
assign noc1_st_rdy = dream_noc1buffer_rdy_f && !noc1_ld_val;

assign noc1_ld_hsk = noc1_ld_rdy && noc1_ld_val;
assign noc1_st_hsk = noc1_st_rdy && noc1_st_val;

reg [`DCP_PADDR_MASK]    dream_noc1_ld_address, dream_noc1_ld_address_next;
reg [`DCP_PADDR_MASK]    dream_noc1_st_address, dream_noc1_st_address_next;

reg        dream_st_field_done;
reg        dream_st_data_buffer_fin, dream_ld_data_buffer_fin;

reg [7:0]  dream_st_buf_st_counter;

always @(posedge clk) begin
    if (!rst_n_f) begin
        dream_noc1_ld_address <= {`DREAM_PADDR_WIDTH{1'b0}};
    end else if (c0_ready) begin
        dream_noc1_ld_address <= c0_src_addr_r;
    end else if (noc1_ld_hsk) begin
        if(c0_op == `DREAM_COPY_OP) begin
            dream_noc1_ld_address <= dream_noc1_ld_address + 7'd64;
        end else if (c0_op == `DREAM_AOS_SOA_OP || c0_op == `DREAM_SOA_AOS_OP) begin
            dream_noc1_ld_address <= dream_noc1_ld_address + 7'd64;
        end
    end
end

always @(posedge clk) begin
    if (!rst_n_f) begin
        dream_noc1_st_address <= {`DREAM_PADDR_WIDTH{1'b0}};
    end else if (c0_ready) begin
        dream_noc1_st_address <= c0_dest_addr_r;
    end else if (noc1_st_hsk) begin
        case (c0_op)
            `DREAM_COPY_OP:
            begin
                dream_noc1_st_address <= dream_noc1_st_address + 7'd16;
            end
            `DREAM_AOS_SOA_OP:
            begin
                if(dream_st_field_done) begin
                    dream_noc1_st_address <= field_base_addr[dream_field_counter_nxt] + (dream_st_element_counter_nxt << field_size[dream_field_counter_nxt]);
                end 
            end
            `DREAM_SOA_AOS_OP:
            begin
                if(dream_st_field_done) begin
                    dream_noc1_st_address <= field_base_addr[dream_field_counter_nxt];
                end else begin
                    dream_noc1_st_address <= dream_noc1_st_address + c0_structure_size_r;
                end
            end
        endcase 
    end
end

always @* begin
    noc1_ld_val = 1'b0;
    if(c0_op == `DREAM_COPY_OP || c0_op == `DREAM_AOS_SOA_OP || c0_op == `DREAM_SOA_AOS_OP) begin
        noc1_ld_val = (dream_working && !mb_ld_full && (ld_cnt < total_ld)) ? 1'b1 : 1'b0;
    end
end

reg dream_sp_read_to_buffer_val;

reg  [`DREAM_BUFFER_DATA_WIDTH-1:0] dream_st_data_buffer;
reg  [128-1:0] aos_dream_st_data;
wire [15:0]  dream_sp_buf_addr;
reg  [9:0]   store_sp_idx;
reg          dream_st_data_buffer_rdy;
reg          dream_st_data_buffer_done;

assign dream_sp_buf_addr = store_sp_idx << 6;

always @(posedge clk) begin
    if(!rst_n_f) begin
        noc1_st_val <= 1'b0;
    end else begin
        if(c0_op == `DREAM_COPY_OP) begin
            if (noc1_st_val && (dream_st_buf_st_counter == 8'd3) && noc1_st_hsk) begin
                    noc1_st_val <= 1'b0;
                end else if (dream_working && !mb_st_full && (st_cnt < total_st) && dream_st_data_buffer_done) begin
                    if (!dest_scratchpad) begin
                        noc1_st_val <= 1'b1;
                    end
            end
        end else if (c0_op == `DREAM_AOS_SOA_OP || c0_op == `DREAM_SOA_AOS_OP) begin
            if (noc1_st_val && dream_st_data_buffer_fin && noc1_st_hsk) begin
                noc1_st_val <= 1'b0;
            end else if (dream_working && !mb_st_full && (st_cnt < total_st) && dream_st_data_buffer_done) begin
                if (!dest_scratchpad) begin
                    noc1_st_val <= 1'b1;
                end
            end
        end
    end
end

always @* begin
    dream_sp_read_to_buffer_val = 1'b0;
    if(c0_op == `DREAM_COPY_OP) begin
        if (!noc1_ld_val && !dream_st_data_buffer_rdy && dream_working && (st_cnt < total_st) && (dream_st_buf_st_counter == 8'd0)) begin
                if (sp_data_status[store_sp_idx]) begin
                    dream_sp_read_to_buffer_val = 1'b1;
                end
            end
    end else if (c0_op == `DREAM_AOS_SOA_OP || c0_op == `DREAM_SOA_AOS_OP) begin
        if (!noc1_ld_val && !dream_st_data_buffer_done && dream_working) begin
            if (sp_data_status[store_sp_idx]) begin
                dream_sp_read_to_buffer_val = 1'b1;
            end
        end
    end 
end

always @(posedge clk) begin
    if(!rst_n_f) begin
        store_sp_idx <= 10'd0;
    end else if (dream_sp_read_to_buffer_val) begin
        if(store_sp_idx < (sp_entry_used-10'd1)) begin
            store_sp_idx <= store_sp_idx + 10'd1;
        end else begin
            store_sp_idx <= 10'd0;
        end
    end
end

always @(posedge clk) begin
    if (!rst_n_f) begin 
        dream_st_buf_st_counter <= 8'd0;
    end else if (noc1_st_hsk) begin
        case (c0_op)
            `DREAM_COPY_OP:
            begin
                if(dream_st_buf_st_counter == 8'd3) begin
                    dream_st_buf_st_counter <= 8'd0;
                end else begin
                    dream_st_buf_st_counter <= dream_st_buf_st_counter + 8'd1;
                end
            end
            `DREAM_AOS_SOA_OP:
            begin
                if(dream_st_field_done) begin
                    dream_st_buf_st_counter <= 8'd0;
                end else begin
                    dream_st_buf_st_counter <= dream_st_buf_st_counter + 8'd1;
                end
            end
            `DREAM_SOA_AOS_OP:
            begin
                if(dream_st_field_done) begin
                    dream_st_buf_st_counter <= 8'd0;
                end else begin
                    dream_st_buf_st_counter <= dream_st_buf_st_counter + 8'd1;
                end
            end            
        endcase
    end
end

always @(posedge clk) begin
    if (!rst_n_f) begin 
        dream_field_counter <= {`DREAM_MAX_NUM_FIELD_BIT{1'b0}};
    end else begin
        case (c0_op)
            `DREAM_AOS_SOA_OP:
            begin
                if (dream_st_field_done) begin
                    dream_field_counter <= dream_field_counter_nxt;
                end
            end
            `DREAM_SOA_AOS_OP:
            begin
                if (dream_st_field_done) begin
                    dream_field_counter <= dream_field_counter_nxt;
                end
            end
        endcase
    end
end

always @* begin
    dream_field_counter_nxt = dream_field_counter;
    case (c0_op)
        `DREAM_AOS_SOA_OP:
        begin
            if (dream_st_field_done) begin
                if(dream_field_counter != (c0_num_field_r - 5'd1)) begin
                    dream_field_counter_nxt = dream_field_counter + 5'd1;
                end else begin
                    dream_field_counter_nxt = 0;
                end
            end
        end
        `DREAM_SOA_AOS_OP:
        begin
            if (dream_st_field_done) begin
                dream_field_counter_nxt = dream_field_counter + 5'd1;
            end
        end
    endcase
end

reg  [6:0] current_field_store_cnt;

always @* begin
    current_field_store_cnt = 5'd0;
    if(c0_op == `DREAM_AOS_SOA_OP) begin
        current_field_store_cnt = (dream_st_current_field_size[2]) ? (dream_st_current_field_size - 7'd3) : 7'd1;
    end else if(c0_op == `DREAM_SOA_AOS_OP) begin
        current_field_store_cnt = (dream_st_current_field_size[2]) ? c0_num_elements_r << (dream_st_current_field_size - 7'd4) : c0_num_elements_r;
    end
end

always @* begin
    dream_st_field_done = 1'b0;
    if((dream_st_buf_st_counter == (current_field_store_cnt-1)) && noc1_st_hsk) begin
        dream_st_field_done = 1'b1;
    end
end

reg [3:0] dream_st_data_buffer_idx;

always @(posedge clk) begin
    if (!rst_n_f) begin 
        dream_st_data_buffer_rdy <= 1'd0;
    end else if(c0_op == `DREAM_COPY_OP) begin
        if (dream_sp_read_to_buffer_val) begin
            dream_st_data_buffer_rdy <= 1'd1;
        end else if (dream_st_data_buffer_rdy && (dream_st_buf_st_counter == 2'd3) && noc1_st_hsk) begin
            dream_st_data_buffer_rdy <= 1'd0;
        end
    end else if (c0_op == `DREAM_AOS_SOA_OP || c0_op == `DREAM_SOA_AOS_OP) begin
        dream_st_data_buffer_rdy <= dream_sp_read_to_buffer_val;
    end
end

reg [9:0] current_st_base_bit;
reg [9:0] next_st_base_bit;

always @* begin
    dream_st_data_buffer_fin = 1'd0;
    if (c0_op == `DREAM_AOS_SOA_OP || c0_op == `DREAM_SOA_AOS_OP) begin
        if (next_st_base_bit[9:3] == 7'd64 && noc1_st_hsk) begin
            dream_st_data_buffer_fin = 1'd1;
        end 
    end
end

always @(posedge clk) begin
    if (!rst_n_f) begin 
        dream_st_data_buffer_done <= 1'd0;
    end else if(c0_op == `DREAM_COPY_OP) begin
        if (dream_sp_read_to_buffer_val) begin
            dream_st_data_buffer_done <= 1'd1;
        end else if (dream_st_data_buffer_done && (dream_st_buf_st_counter == 2'd3) && noc1_st_hsk) begin
            dream_st_data_buffer_done <= 1'd0;
        end
    end else if (c0_op == `DREAM_AOS_SOA_OP || c0_op == `DREAM_SOA_AOS_OP) begin
        if (dream_st_data_buffer_fin) begin
            dream_st_data_buffer_done <= 1'd0;
        end else if (dream_sp_read_to_buffer_val) begin
            dream_st_data_buffer_done <= 1'd1;
        end
    end
end

always @(posedge clk) begin
    if (!rst_n_f) begin 
        dream_st_element_counter <= {`DREAM_MAX_NUM_ELEMENT_BIT{1'b0}};
    end else if (c0_op == `DREAM_AOS_SOA_OP || c0_op == `DREAM_SOA_AOS_OP) begin
        dream_st_element_counter <= dream_st_element_counter_nxt;
    end
end


always @* begin
    dream_st_element_counter_nxt = {`DREAM_MAX_NUM_ELEMENT_BIT{1'b0}};
    if(dream_field_counter == (c0_num_field_r - 5'd1) && dream_st_field_done) begin
        dream_st_element_counter_nxt = dream_st_element_counter + 5'd1;
    end else begin
        dream_st_element_counter_nxt = dream_st_element_counter;
    end
end

reg [511:0] dream_st_data_buffer_r [15:0];

always @(posedge clk) begin
    if (!rst_n_f) begin
        dream_st_data_buffer_idx <= 4'd0;
    end else if(c0_op == `DREAM_COPY_OP) begin
        dream_st_data_buffer_idx <= 4'd0;
    end else if(c0_op == `DREAM_AOS_SOA_OP) begin
        if(dream_st_data_buffer_fin) begin
            dream_st_data_buffer_idx <= 4'd0;
        end else if (dream_st_data_buffer_rdy) begin
            dream_st_data_buffer_idx <= dream_st_data_buffer_idx + 1'b1;
        end
    end
end

always @(posedge clk) begin
    if (!rst_n_f) begin
        dream_st_data_buffer <= {`DREAM_BUFFER_DATA_WIDTH{1'b0}};
    end else begin
        case (c0_op)
            `DREAM_COPY_OP:
            begin
                if (dream_st_data_buffer_rdy && dream_st_buf_st_counter == 2'd0) begin
                    dream_st_data_buffer <= sp_dream_rdata;
                end
            end
            `DREAM_AOS_SOA_OP:
            begin
                if (dream_st_data_buffer_rdy) begin
                    dream_st_data_buffer <= sp_dream_rdata;
                end
            end
            `DREAM_SOA_AOS_OP:
            begin
                if (dream_st_data_buffer_rdy) begin
                    dream_st_data_buffer <= sp_dream_rdata;
                end
            end
            default: begin
                dream_st_data_buffer <= {`DREAM_BUFFER_DATA_WIDTH{1'b0}};
            end
        endcase 
    end
end

reg [127:0] dream_st_data_16B;
reg [63:0] dream_st_data_0, dream_st_data_1;
reg [15:0] dream_st_data_wm;

reg [127:0] soa_dream_st_data;

always @* begin
    dream_st_data_0 = 64'd0;
    dream_st_data_1 = 64'd0;
    case (c0_op)
        `DREAM_COPY_OP:
        begin
            case (dream_st_buf_st_counter) 
                2'd0: begin
                    dream_st_data_0 =  dream_st_data_buffer[0+:64];
                    dream_st_data_1 =  dream_st_data_buffer[64+:64];
                end
                2'd1: begin
                    dream_st_data_0 =  dream_st_data_buffer[128+:64];
                    dream_st_data_1 =  dream_st_data_buffer[192+:64];
                end
                2'd2: begin
                    dream_st_data_0 =  dream_st_data_buffer[256+:64];
                    dream_st_data_1 =  dream_st_data_buffer[320+:64];
                end
                2'd3: begin
                    dream_st_data_0 =  dream_st_data_buffer[384+:64];
                    dream_st_data_1 =  dream_st_data_buffer[448+:64];
                end
            endcase
        end
        `DREAM_AOS_SOA_OP:
        begin
            dream_st_data_0 = soa_dream_st_data[63:0];
            dream_st_data_1 = soa_dream_st_data[127:64];
        end
        `DREAM_SOA_AOS_OP:
        begin
            dream_st_data_0 = aos_dream_st_data[63:0];
            dream_st_data_1 = aos_dream_st_data[127:64];
        end
    endcase
end

wire [6:0] current_st_addr_bit;
wire [3:0] current_st_addr_byte;
assign current_st_addr_bit = dream_noc1_st_address[3:0] << 3;
assign current_st_addr_byte = dream_noc1_st_address[3:0];

always @* begin
    dream_st_data_wm = 16'd0;
    case(dream_st_current_field_size)
    3'd0:
    begin
        dream_st_data_wm[current_st_addr_byte+:1] = 1'd1;
    end
    3'd1:
    begin
        dream_st_data_wm[current_st_addr_byte+:2] = 2'd3;
    end
    3'd2:
    begin
        dream_st_data_wm[current_st_addr_byte+:4] = 4'hF;
    end
    3'd3:
    begin
        dream_st_data_wm[current_st_addr_byte+:8] = 8'hFF;
    end
    default:
    begin
        dream_st_data_wm = 16'hFFFF;
    end
    endcase
end

always @* begin
    aos_dream_st_data = 128'd0;
    case(dream_st_current_field_size)
    3'd0:
    begin
        aos_dream_st_data[current_st_addr_bit+:8] = dream_st_data_buffer[current_st_base_bit+:8];
    end
    3'd1:
    begin
        aos_dream_st_data[current_st_addr_bit+:16] = dream_st_data_buffer[current_st_base_bit+:16];
    end
    3'd2:
    begin
        aos_dream_st_data[current_st_addr_bit+:32] = dream_st_data_buffer[current_st_base_bit+:32];
    end
    3'd3:
    begin
        aos_dream_st_data[current_st_addr_bit+:64] = dream_st_data_buffer[current_st_base_bit+:64];
    end
    default:
    begin
        aos_dream_st_data = dream_st_data_buffer[current_st_base_bit+:128];
    end
    endcase
end

always @* begin
    soa_dream_st_data = 128'd0;
    case(dream_st_current_field_size)
    3'd0:
    begin
        soa_dream_st_data[current_st_addr_bit+:8] = dream_st_data_buffer[current_st_base_bit+:8];
    end
    3'd1:
    begin
        soa_dream_st_data[current_st_addr_bit+:16] = dream_st_data_buffer[current_st_base_bit+:16];
    end
    3'd2:
    begin
        soa_dream_st_data[current_st_addr_bit+:32] = dream_st_data_buffer[current_st_base_bit+:32];
    end
    3'd3:
    begin
        soa_dream_st_data[current_st_addr_bit+:64] = dream_st_data_buffer[current_st_base_bit+:64];
    end
    default:
    begin
        soa_dream_st_data = dream_st_data_buffer[current_st_base_bit+:128];
    end
    endcase
end

always @* begin
    next_st_base_bit = 10'd0;
    if(dream_st_current_field_size>4) begin
        next_st_base_bit = current_st_base_bit + 10'd128;
    end else begin
        next_st_base_bit = current_st_base_bit + ((1 << dream_st_current_field_size) << 3);
    end
end

always @(posedge clk) begin
    if (!rst_n_f) begin
        current_st_base_bit <= 9'd0;
    end else if (noc1_st_hsk) begin
        if(next_st_base_bit[9]) begin
            current_st_base_bit <= 9'd0;
        end else begin
            current_st_base_bit <= next_st_base_bit;
        end
    end
end

always @* begin
    dream_st_current_field_size = field_size[dream_field_counter];
end

always @* begin
    mb_ld_add_val = 1'b0;
    if (noc1_ld_hsk) begin
        mb_ld_add_val = 1'b1;
    end
end

always @* begin
    mb_st_add_val = 1'b0;
    if (noc1_st_hsk) begin
        mb_st_add_val = 1'b1;
    end
end

always @(posedge clk) begin
    if (!rst_n_f) begin
        ld_cnt <= 11'd0;
        st_cnt <= 11'd0;
    end else if (c0_ready) begin
        ld_cnt <= 11'd0;
        st_cnt <= 11'd0;
    end else if (noc1_ld_hsk) begin
        ld_cnt <= ld_cnt + 11'd1;
    end else if (noc1_st_hsk) begin
        st_cnt <= st_cnt + 11'd1;
    end 
end

always @* begin
    dream_noc1buffer_val_f = 1'b0;
    dream_noc1buffer_address_f = {`DCP_PADDR_HI{1'b0}};
    dream_noc1buffer_type_f = {`MSG_TYPE_WIDTH{1'b0}};
    dream_noc1buffer_size_f = 3'd0;
    dream_noc1buffer_data_0_f = 64'd0;
    dream_noc1buffer_data_1_f = 64'd0;
    dream_noc1buffer_mshrid_f = {`DCP_MSHRID_WIDTH{1'b0}};
    dream_noc1buffer_write_mask_f = {`MSG_AMO_MASK_WIDTH{1'b0}};
    if (dream_working) begin
        if(c0_op == `DREAM_COPY_OP || c0_op == `DREAM_AOS_SOA_OP || c0_op == `DREAM_SOA_AOS_OP) begin
            if (noc1_ld_val) begin
                dream_noc1buffer_val_f = 1'b1;
                dream_noc1buffer_address_f = dream_noc1_ld_address;
                dream_noc1buffer_type_f = {2'b0, `DREAM_NS_LOAD};
                dream_noc1buffer_size_f = `MSG_DATA_SIZE_64B;
                dream_noc1buffer_data_0_f = 64'd0;
                dream_noc1buffer_data_1_f = 64'd0;
                dream_noc1buffer_mshrid_f = mb_ld_add_idx + `DREAM_MB_LD_BASE;
                dream_noc1buffer_write_mask_f = 16'd0;
            end else if (noc1_st_val) begin
                dream_noc1buffer_val_f = 1'b1;
                dream_noc1buffer_address_f = {dream_noc1_st_address[`DCP_PADDR_HI:4], 4'd0};
                dream_noc1buffer_type_f = {2'b0, `DREAM_SW_WB};
                dream_noc1buffer_size_f = `MSG_DATA_SIZE_16B;
                dream_noc1buffer_data_0_f = dream_st_data_0;
                dream_noc1buffer_data_1_f = dream_st_data_1;
                dream_noc1buffer_mshrid_f = mb_st_add_idx + `DREAM_MB_ST_BASE;
                dream_noc1buffer_write_mask_f = dream_st_data_wm;
            end
        end
    end
end

/////////////////////////////
// Receive noc2 response
/////////////////////////////

wire [15:0]  dream_sp_noc2_addr;
reg  dream_sp_noc2_write_val;
wire [`DCP_NOC_RES_DATA_SIZE-1:0] dream_sp_noc2_data;

assign dream_sp_noc2_data = noc2decoder_dream_data;

wire [5:0] current_tail_diff;

assign dream_sp_noc2_addr = (mb_ld_add_idx_addr - current_tail_diff) << 6;
assign current_tail_diff = ((noc2decoder_dream_mshrid - `DREAM_MB_LD_BASE) < mb_ld_add_idx) ? 
                            (mb_ld_add_idx - noc2decoder_dream_mshrid + `DREAM_MB_LD_BASE) :
                            (mb_ld_add_idx + `DREAM_MB_LD_MSHR_SIZE - noc2decoder_dream_mshrid + `DREAM_MB_LD_BASE);

always @* begin
    mb_ld_clr_rdy = 1'b0;
    mb_st_clr_rdy = 1'b0;
    if (noc2decoder_dream_val) begin
        if (noc2decoder_dream_mshrid >= `DREAM_MB_ST_BASE) begin
            mb_st_clr_rdy = 1'b1;
            mb_st_clr_idx = noc2decoder_dream_mshrid - `DREAM_MB_ST_BASE;
        end else begin
            mb_ld_clr_rdy = 1'b1;
            mb_ld_clr_idx = noc2decoder_dream_mshrid - `DREAM_MB_LD_BASE;
        end
    end
end

always @* begin
    dream_sp_noc2_write_val = 1'b0;
    if(c0_op == `DREAM_COPY_OP || c0_op == `DREAM_AOS_SOA_OP || c0_op == `DREAM_SOA_AOS_OP) begin
        if (noc2decoder_dream_val && noc2decoder_dream_mshrid < `DREAM_MB_ST_BASE) begin
            dream_sp_noc2_write_val = 1'b1;
        end
    end
end

/////////////////////////////
// Scratchpad interface
/////////////////////////////

// Ariane/SP iface
wire dream_sp_read_to_ariane;
wire dream_sp_write_for_ariane;
wire dream_sp_rdw_ariane;
wire other_sp_read, other_sp_write; 
wire dream_sp_read_val, dream_sp_write_val;
wire dream_config_read_to_ariane;

assign dream_sp_val = dream_sp_write_val || dream_sp_read_val;
assign dream_sp_addr = (dream_sp_rdw_ariane) ? config_addr[15:0] : 
                       (other_sp_write) ? dream_sp_noc2_addr :
                       dream_sp_buf_addr;
assign dream_sp_rdwen = (dream_sp_read_val) ? 1'b1 : 1'b0;


generate
    for (j=0; j<1024; j++) begin: sp_data_status_gen
        always @(posedge clk) begin
            if(!rst_n_f) begin
                sp_data_status[j] <= 1'b0;
            end else if (other_sp_write && (j[9:0]==(dream_sp_noc2_addr[15:6]))) begin
                sp_data_status[j] <= 1'b1;
            end else if (other_sp_read && (j[9:0]==(dream_sp_buf_addr[15:6]))) begin
                sp_data_status[j] <= 1'b0;
            end
        end
    end
endgenerate

reg [63:0] config_data;

generate
for (j = 0; j < 8; j=j+1) begin : dream_sp_wdata_gen
    always @* begin
        dream_sp_wdata[j*64+63:j*64] = 64'd0;
        if (dream_sp_rdw_ariane) begin
            dream_sp_wdata[j*64+63:j*64] = (j == config_addr[5:3]) ? c0_data : 64'd0;
        end else begin
            dream_sp_wdata[j*64+63:j*64] = dream_sp_noc2_data[j*64+63:j*64];
        end
    end
end endgenerate

generate
for (j = 0; j < 64; j=j+1) begin : dream_sp_bw_gen
    always @* begin
        dream_sp_bw[j*8+:8] = 8'hFF;
        if (dream_sp_write_for_ariane) begin
            case (config_size)
                `MSG_DATA_SIZE_1B: begin
                    if (j[5:0] == config_addr[5:0]) begin
                        dream_sp_bw[j*8+:8] = 8'hFF;
                    end else begin
                        dream_sp_bw[j*8+:8] = 8'h00;
                    end
                end
                `MSG_DATA_SIZE_2B: begin
                    if (j[5:1] == config_addr[5:1]) begin
                        dream_sp_bw[j*8+:8] = 8'hFF;
                    end else begin
                        dream_sp_bw[j*8+:8] = 8'h00;
                    end
                end
                `MSG_DATA_SIZE_4B: begin
                    if (j[5:2] == config_addr[5:2]) begin
                        dream_sp_bw[j*8+:8] = 8'hFF;
                    end else begin
                        dream_sp_bw[j*8+:8] = 8'h00;
                    end
                end
                `MSG_DATA_SIZE_8B: begin
                    if (j[5:3] == config_addr[5:3]) begin
                        dream_sp_bw[j*8+:8] = 8'hFF;
                    end else begin
                        dream_sp_bw[j*8+:8] = 8'h00;
                    end
                end
                default: begin
                    dream_sp_bw[j*8+:8] = 8'h00;
                end
            endcase
        end else begin
            dream_sp_bw[j*8+:8] = 8'hFF;
        end
    end
end endgenerate


assign dream_read_to_ariane = config_hsk && config_load;

assign dream_sp_read_to_ariane = config_hsk && config_load && config_spd;
assign dream_sp_write_for_ariane = config_hsk && !config_load && config_spd;
assign dream_sp_rdw_ariane = dream_sp_read_to_ariane || dream_sp_write_for_ariane;

// TODO: should not be 1 at the same time
assign other_sp_write = dream_sp_noc2_write_val;
assign other_sp_read = dream_sp_read_to_buffer_val;

assign dream_sp_read_val = dream_sp_read_to_ariane || other_sp_read;
assign dream_sp_write_val = dream_sp_write_for_ariane || other_sp_write;


reg dream_sp_read_to_ariane_r;
reg [17:0] config_addr_r;
reg [`MSG_DATA_SIZE_WIDTH-1:0] config_size_r;

always @(posedge clk) begin
    if (!rst_n_f) begin
        dream_sp_read_to_ariane_r <= 1'b0;
        config_addr_r <= 18'd0;
        config_size_r <= {`MSG_DATA_SIZE_WIDTH{1'b0}};
    end else begin
        dream_sp_read_to_ariane_r <= dream_sp_read_to_ariane;
        config_addr_r <= config_addr;
        config_size_r <= config_size;
    end
end

reg [63:0] sp_dream_rdata_ariane;

reg [7:0] sp_dream_rdata_ariane_1B;
reg [15:0] sp_dream_rdata_ariane_2B;
reg [31:0] sp_dream_rdata_ariane_4B;
reg [63:0] sp_dream_rdata_ariane_8B;
reg [127:0] sp_dream_rdata_ariane_16B;

always @* begin
    sp_dream_rdata_ariane_16B = 128'd0;
    case (config_addr_r[5:4])
        2'b00: sp_dream_rdata_ariane_16B = sp_dream_rdata[0+:128];
        2'b01: sp_dream_rdata_ariane_16B = sp_dream_rdata[128+:128];
        2'b10: sp_dream_rdata_ariane_16B = sp_dream_rdata[256+:128];
        2'b11: sp_dream_rdata_ariane_16B = sp_dream_rdata[384+:128];
    endcase
end

always @* begin
    sp_dream_rdata_ariane_8B = 64'd0;
    case (config_addr_r[3])
        1'b0: sp_dream_rdata_ariane_8B = sp_dream_rdata_ariane_16B[0+:64];
        1'b1: sp_dream_rdata_ariane_8B = sp_dream_rdata_ariane_16B[64+:64];
    endcase
end

always @* begin
    sp_dream_rdata_ariane_4B = 32'd0;
    case (config_addr_r[2])
        1'b0: sp_dream_rdata_ariane_4B = sp_dream_rdata_ariane_8B[0+:32];
        1'b1: sp_dream_rdata_ariane_4B = sp_dream_rdata_ariane_8B[32+:32];
    endcase
end

always @* begin
    sp_dream_rdata_ariane_2B = 16'd0;
    case (config_addr_r[1])
        1'b0: sp_dream_rdata_ariane_2B = sp_dream_rdata_ariane_4B[0+:16];
        1'b1: sp_dream_rdata_ariane_2B = sp_dream_rdata_ariane_4B[16+:16];
    endcase
end

always @* begin
    sp_dream_rdata_ariane_1B = 8'd0;
    case (config_addr_r[0])
        1'b0: sp_dream_rdata_ariane_1B = sp_dream_rdata_ariane_2B[0+:8];
        1'b1: sp_dream_rdata_ariane_1B = sp_dream_rdata_ariane_2B[8+:8];
    endcase
end

always @* begin
    sp_dream_rdata_ariane = 64'd0;
    case (config_size_r)
        `MSG_DATA_SIZE_1B: begin
            sp_dream_rdata_ariane = {56'd0, sp_dream_rdata_ariane_1B} << {config_addr_r[2:0], 3'd0};
        end
        `MSG_DATA_SIZE_2B: begin
            sp_dream_rdata_ariane = {48'd0, sp_dream_rdata_ariane_2B} << {config_addr_r[2:1], 4'd0};
        end
        `MSG_DATA_SIZE_4B: begin
            sp_dream_rdata_ariane = {32'd0, sp_dream_rdata_ariane_4B} << {config_addr_r[2], 5'd0};
        end
        `MSG_DATA_SIZE_8B: begin
            sp_dream_rdata_ariane = sp_dream_rdata_ariane_8B;
        end
    endcase
end

assign dream_ariane_data = (dream_sp_read_to_ariane_r) ? sp_dream_rdata_ariane : config_data;

always @(posedge clk) begin
    if (!rst_n_f) begin
        config_data <= 64'd0;
    end else if (config_hsk && config_load) begin
        case (config_pkt_num)
            `DREAM_CONFIG_OP:
                config_data <= c0_op;
            `DREAM_CONFIG_SRC_ADDR: 
                config_data <= c0_src_addr_r;
            `DREAM_CONFIG_DEST_ADDR:
                config_data <= c0_dest_addr_r;
            `DREAM_CONFIG_COPY_SIZE:
                config_data <= c0_copy_size_r;
            `NUM_FIELD:
                config_data <= c0_num_field_r;
            `FIELD_SIZE_0:
                config_data <= c0_field_size_0_r;
            `FIELD_SIZE_1:
                config_data <= c0_field_size_1_r;
            `NUM_ELEMENT:
                config_data <= c0_num_elements_r;
            `DREAM_DONE:
                config_data <= !dream_working;
            default:
                config_data <= 64'd0;
        endcase
    end
end

endmodule