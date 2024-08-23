// Copyright (c) 2020 Princeton University
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
`include "l15.tmp.h"
`include "define.tmp.h"

module pmesh_rvic #(
    parameter  integer                  NUM_SOURCES = 128,
    parameter  integer                  NUM_HARTS = 59,
    parameter  integer                  MAX_PRIORITY = 7,
    parameter                           CLINT_BASE   = 64'he103c00000,
    parameter                           PLIC_BASE    = 64'he200000000,
    parameter                           SWAP_ENDIANESS = 1
) (
    input                               clk,
    input                               rst_n,

    // Interrupt status is snooped from TRI responses
    input                               l15_transducer_val,
    input [3:0]                         l15_transducer_returntype,
    input [63:0]                        l15_transducer_data_0,

    // input from noc1 (load/store to PLIC)
    input                               src_rvic_vr_noc1_val,
    input [`NOC_DATA_WIDTH-1:0]         src_rvic_vr_noc1_dat,
    output                              src_rvic_vr_noc1_rdy,

    // output to noc2 (load/store PLIC response)
    output                              rvic_dst_vr_noc2_val,
    output [`NOC_DATA_WIDTH-1:0]        rvic_dst_vr_noc2_dat,
    input                               rvic_dst_vr_noc2_rdy,

    // Interrupt targets go to core
    output   [NUM_HARTS*2-1:0]          irq_targets,

    // input from noc1 (load/store to CLINT)
    input                               src_clint_noc1_val,
    input [`NOC_DATA_WIDTH-1:0]         src_clint_noc1_dat,
    output                              src_clint_noc1_rdy,

    // output to noc2 (load/store CLINT response)
    output                              clint_dst_noc2_val,
    output [`NOC_DATA_WIDTH-1:0]        clint_dst_noc2_dat,
    input                               clint_dst_noc2_rdy,

    input                               rtc_i,
    output [NUM_HARTS-1:0]              timer_irq_o,
    output [NUM_HARTS-1:0]              ipi_o
);

reg                     new_edge_irq;
reg                     new_edge_irq_next;

reg  [NUM_SOURCES:0]  lev_or_edge;
reg  [NUM_SOURCES:0]  lev_or_edge_next;
reg  [NUM_SOURCES:0]  irq_sources;
reg  [NUM_SOURCES:0]  irq_sources_next;

reg  [6:0]              most_recent_source;
reg  [6:0]              most_recent_source_next;

reg  [9:0]            source_id_field;

// flit2: 
//     63    1
//     59:56 source id bit [9:6], for decades, only use bit[6:0]
//     33:26 ypos
//     25:18 xpos
//     17:16 type
//     15:9  0
//     8     threadid
//     7     0:level, 1:edge
//     6     0:rising, 1:falling
//     5:0   source id bit [5:0]
// Read from the l15 message
// for edge-sensitive or rising edge of level-sensitive,
// the next cycle of that interrupt should be high.
// The edge sensitive interrupt will automatically return to 0 after 1 cycle
always @* begin
    new_edge_irq_next = 1'b0;
    most_recent_source_next = most_recent_source;
    irq_sources_next = irq_sources;
    lev_or_edge_next = lev_or_edge;
    source_id_field  = 10'b0;
    if (l15_transducer_val && (l15_transducer_returntype == `CPX_RESTYPE_INTERRUPT) && ~new_edge_irq && (l15_transducer_data_0[17:16] == 2'b0)) begin
        // Combine the source id together
	source_id_field = {l15_transducer_data_0[59:56], l15_transducer_data_0[5:0]};
        // Either level sensitive edge or rising edge of edge sensitive pulse
        new_edge_irq_next = l15_transducer_data_0[7];
        most_recent_source_next = source_id_field[6:0];
	irq_sources_next[source_id_field[6:0]] = l15_transducer_data_0[7] | (~l15_transducer_data_0[7] & ~l15_transducer_data_0[6]); // edge-sensitive or rising edge of level-sensitive
	lev_or_edge_next[source_id_field[6:0]] = l15_transducer_data_0[7];
    end else if (new_edge_irq) begin
        // Edge sensitive automatic falling edge of pulse
        most_recent_source_next = 7'b0;
	irq_sources_next[most_recent_source] = 1'b0;
    end
end

always @(posedge clk) begin
    if (~rst_n) begin
        new_edge_irq <= 1'b0;
        most_recent_source <= 7'b0;
    end else begin
        new_edge_irq <= new_edge_irq_next;
        most_recent_source <= most_recent_source_next;
    end
end

always @(posedge clk) begin
    if (~rst_n) begin
        irq_sources <= {NUM_SOURCES+1{1'b0}};
        lev_or_edge <= {NUM_SOURCES+1{1'b0}};
    end else  begin
        irq_sources <= irq_sources_next;
	lev_or_edge <= lev_or_edge_next;
    end
end

wire [63:0]            aw_addr;
wire                   aw_valid;
wire                   aw_ready;
wire [63:0]            w_data;
wire [7:0]             w_strb;
wire                   w_valid;
wire                   w_ready;
wire [63:0]            ar_addr;
wire                   ar_valid;
wire                   ar_ready;
wire [63:0]            r_data;  
wire [1:0]             r_resp; 
wire                   r_valid; 
wire                   r_ready; 
wire [1:0]             b_resp;  
wire                   b_valid; 
wire                   b_ready; 
wire [2:0]             aw_size; 
wire [2:0]             ar_size; 

wire [63:0]            clint_aw_addr;
wire                   clint_aw_valid;
wire                   clint_aw_ready;
wire [63:0]            clint_w_data;  
wire [7:0]             clint_w_strb;  
wire                   clint_w_valid; 
wire                   clint_w_ready; 
wire [63:0]            clint_ar_addr; 
wire                   clint_ar_valid;
wire                   clint_ar_ready;
wire [63:0]            clint_r_data; 
wire [1:0]             clint_r_resp;  
wire                   clint_r_valid; 
wire                   clint_r_ready;
wire [1:0]             clint_b_resp;  
wire                   clint_b_valid; 
wire                   clint_b_ready; 


noc_axilite_bridge #(
    .SLAVE_RESP_BYTEWIDTH   ( 0             ),
    .SWAP_ENDIANESS         ( SWAP_ENDIANESS ),
    .ALIGN_RDATA            ( 0             )
) rvic_bridge (
    .clk                    ( clk                   ),
    .rst                    ( ~rst_n                ),
    .splitter_bridge_val    ( src_rvic_vr_noc1_val  ),
    .splitter_bridge_data   ( src_rvic_vr_noc1_dat  ),
    .bridge_splitter_rdy    ( src_rvic_vr_noc1_rdy  ),
    .bridge_splitter_val    ( rvic_dst_vr_noc2_val  ),
    .bridge_splitter_data   ( rvic_dst_vr_noc2_dat  ),
    .splitter_bridge_rdy    ( rvic_dst_vr_noc2_rdy  ),
    .m_axi_awaddr           ( aw_addr               ),
    .m_axi_awvalid          ( aw_valid              ),
    .m_axi_awready          ( aw_ready              ),
    .m_axi_wdata            ( w_data                ),
    .m_axi_wstrb            ( w_strb                ),
    .m_axi_wvalid           ( w_valid               ),
    .m_axi_wready           ( w_ready               ),
    .m_axi_araddr           ( ar_addr               ),
    .m_axi_arvalid          ( ar_valid              ),
    .m_axi_arready          ( ar_ready              ),
    .m_axi_rdata            ( r_data                ),
    .m_axi_rresp            ( r_resp                ),
    .m_axi_rvalid           ( r_valid               ),
    .m_axi_rready           ( r_ready               ),
    .m_axi_bresp            ( b_resp                ),
    .m_axi_bvalid           ( b_valid               ),
    .m_axi_bready           ( b_ready               ),
    .w_reqbuf_size          ( aw_size               ),
    .r_reqbuf_size          ( ar_size               )
);


noc_axilite_bridge #(
    .SLAVE_RESP_BYTEWIDTH   ( 8             ),
    .SWAP_ENDIANESS         ( SWAP_ENDIANESS )
) clint_bridge (
    .clk                    ( clk                ),
    .rst                    ( ~rst_n             ),
    .splitter_bridge_val    ( src_clint_noc1_val ),
    .splitter_bridge_data   ( src_clint_noc1_dat ),
    .bridge_splitter_rdy    ( src_clint_noc1_rdy ),
    .bridge_splitter_val    ( clint_dst_noc2_val ),
    .bridge_splitter_data   ( clint_dst_noc2_dat ),
    .splitter_bridge_rdy    ( clint_dst_noc2_rdy ),
    .m_axi_awaddr           ( clint_aw_addr      ),
    .m_axi_awvalid          ( clint_aw_valid     ),
    .m_axi_awready          ( clint_aw_ready     ),
    .m_axi_wdata            ( clint_w_data       ),
    .m_axi_wstrb            ( clint_w_strb       ),
    .m_axi_wvalid           ( clint_w_valid      ),
    .m_axi_wready           ( clint_w_ready      ),
    .m_axi_araddr           ( clint_ar_addr      ),
    .m_axi_arvalid          ( clint_ar_valid     ),
    .m_axi_arready          ( clint_ar_ready     ),
    .m_axi_rdata            ( clint_r_data       ),
    .m_axi_rresp            ( clint_r_resp       ),
    .m_axi_rvalid           ( clint_r_valid      ),
    .m_axi_rready           ( clint_r_ready      ),
    .m_axi_bresp            ( clint_b_resp       ),
    .m_axi_bvalid           ( clint_b_valid      ),
    .m_axi_bready           ( clint_b_ready      ),
    .w_reqbuf_size          (                    ),
    .r_reqbuf_size          (                    )
  );


rvic_wrap #(
    .NumSources        ( NUM_SOURCES   ),
    .NumHarts          ( NUM_HARTS     ),
    .PlicMaxPriority   ( MAX_PRIORITY  ),
    .ClintBase         ( CLINT_BASE    ),
    .PlicBase          ( PLIC_BASE     )
) rvic_wrap (
    .clk            ( clk           ),
    .rst_n          ( rst_n         ),
    .axi_awaddr     ( aw_addr       ),
    .axi_awvalid    ( aw_valid      ),
    .axi_awready    ( aw_ready      ),
    .axi_wdata      ( w_data        ),
    .axi_wstrb      ( w_strb        ),
    .axi_wvalid     ( w_valid       ),
    .axi_wready     ( w_ready       ),
    .axi_araddr     ( ar_addr       ),
    .axi_arvalid    ( ar_valid      ),
    .axi_arready    ( ar_ready      ),
    .axi_rdata      ( r_data        ),
    .axi_rresp      ( r_resp        ),
    .axi_rvalid     ( r_valid       ),
    .axi_rready     ( r_ready       ),
    .axi_bresp      ( b_resp        ),
    .axi_bvalid     ( b_valid       ),
    .axi_bready     ( b_ready       ),
    .w_reqbuf_size  ( aw_size       ),
    .r_reqbuf_size  ( ar_size       ),

 
    .clint_axi_awaddr     ( clint_aw_addr       ),
    .clint_axi_awvalid    ( clint_aw_valid      ),
    .clint_axi_awready    ( clint_aw_ready      ),
    .clint_axi_wdata      ( clint_w_data        ),
    .clint_axi_wstrb      ( clint_w_strb        ),
    .clint_axi_wvalid     ( clint_w_valid       ),
    .clint_axi_wready     ( clint_w_ready       ),
    .clint_axi_araddr     ( clint_ar_addr       ),
    .clint_axi_arvalid    ( clint_ar_valid      ),
    .clint_axi_arready    ( clint_ar_ready      ),
    .clint_axi_rdata      ( clint_r_data        ),
    .clint_axi_rresp      ( clint_r_resp        ),
    .clint_axi_rvalid     ( clint_r_valid       ),
    .clint_axi_rready     ( clint_r_ready       ),
    .clint_axi_bresp      ( clint_b_resp        ),
    .clint_axi_bvalid     ( clint_b_valid       ),
    .clint_axi_bready     ( clint_b_ready       ),

    .irq_sources_i  ( irq_sources[NUM_SOURCES:1]   ),
    .irq_le_i       ( lev_or_edge_next[NUM_SOURCES:1]   ),
    .irq_o          ( irq_targets   ),
    .testmode_i     ( 1'b0          ),
    .rtc_i          ( rtc_i         ),
    .timer_irq_o    ( timer_irq_o   ),
    .ipi_o          ( ipi_o         )
);

endmodule
