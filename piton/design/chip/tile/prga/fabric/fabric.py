# Copyright (c) 2024 Princeton University
# All rights reserved.
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of the copyright holder nor the
#       names of its contributors may be used to endorse or promote products
#       derived from this software without specific prior written permission.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

from prga import *
from prga.netlist import Module, ModuleUtils, NetUtils, PortDirection

from itertools import product, chain
import os, sys

N = 8                       # No. of Grady'18 per CLB
CFG_WIDTH, PHIT_WIDTH = 1, 8
SA_WIDTH, SA_HEIGHT = 8, 8
SA_XCNT, SA_YCNT = 2, 8
NUM_IOB_PER_TILE = 10
MUL_WIDTH = 40
MM_COL = 3                  # memory/multiplier column

FBRC_WIDTH, FBRC_HEIGHT = SA_XCNT * SA_WIDTH + 2, SA_YCNT * SA_HEIGHT + 2

import logging
logger = logging.getLogger("prga")
logger.setLevel(logging.DEBUG)

try:
    ctx = Context.unpickle("ctx.tmp.pkl")

except FileNotFoundError:
    ctx = Pktchain.new_context(phit_width = PHIT_WIDTH, chain_width = CFG_WIDTH,
            router_fifo_depth_log2 = 7,  # 128x8b (32 frames) router FIFO
            )

    # ============================================================================
    # -- Routing Resources -------------------------------------------------------
    # ============================================================================
    glb_clk = ctx.create_global("clk", is_clock = True)
    glb_clk.bind( (SA_XCNT * SA_WIDTH + 1, (SA_YCNT // 2) * SA_HEIGHT + 1), 0)
    l1 = ctx.create_segment('L1', 20, 1)
    l4 = ctx.create_segment('L4', 20, 4)

    # ============================================================================
    # -- Primitives --------------------------------------------------------------
    # ============================================================================

    # multi-mode memory: 512x32b, 1K16b, and 2K8b
    memory = ctx.create_multimode_memory(9, 32, addr_width = 11)

    # extra FIFO buffering
    fifobuf = ctx._database[ModuleView.design, "prga_fifo_buf"] = Module("prga_fifo_buf",
            is_cell = True,
            view = ModuleView.design,
            module_class = ModuleClass.aux,
            verilog_template = "prga_fifo_buf.tmpl.v")
    ModuleUtils.create_port(fifobuf, "clk",     1,          PortDirection.input_, is_clock = True)
    ModuleUtils.create_port(fifobuf, "rst",     1,          PortDirection.input_)
    ModuleUtils.create_port(fifobuf, "wr_i",    1,          PortDirection.input_)
    ModuleUtils.create_port(fifobuf, "full_i",  1,          PortDirection.input_)
    ModuleUtils.create_port(fifobuf, "data_i",  PHIT_WIDTH, PortDirection.input_)
    ModuleUtils.create_port(fifobuf, "wr_o",    1,          PortDirection.output)
    ModuleUtils.create_port(fifobuf, "full_o",  1,          PortDirection.output)
    ModuleUtils.create_port(fifobuf, "data_o",  PHIT_WIDTH, PortDirection.output)

    # ============================================================================
    # -- Blocks ------------------------------------------------------------------
    # ============================================================================

    # -- IOB ---------------------------------------------------------------------
    builder = ctx.build_io_block("prga_iob")
    o = builder.create_input("outpad", 1)
    i = builder.create_output("inpad", 1)
    builder.connect(builder.instances['io'].pins['inpad'], i)
    builder.connect(o, builder.instances['io'].pins['outpad'])
    iob = builder.commit()

    # -- CLB ---------------------------------------------------------------------
    prim = ctx.primitives["grady18v2"]
    builder = ctx.build_logic_block("prga_clb")
    clk = builder.create_global(glb_clk, Orientation.south)
    ce = builder.create_input("ce", 1, Orientation.west)
    in_ = builder.create_input("in", (N // 2) * len(prim.ports["in"]), Orientation.west)
    out = builder.create_output("out", N * len(prim.ports["out"]), Orientation.west)
    cin = builder.create_input("cin", 1, Orientation.south)
    xbar_i, xbar_o = list(in_), []
    for i, inst in enumerate(builder.instantiate(prim, "i_slice", N)):
        builder.connect(clk, inst.pins['clk'])
        builder.connect(ce, inst.pins['ce'])
        builder.connect(inst.pins['out'], out[i * (l := len(prim.ports["out"])):(i + 1) * l])
        builder.connect(cin, inst.pins["cin"], vpr_pack_patterns = ["carrychain"])
        xbar_i.extend(inst.pins["out"])
        xbar_o.extend(inst.pins["in"])
        cin = inst.pins["cout"]
    builder.connect(cin, builder.create_output("cout", 1, Orientation.north), vpr_pack_patterns = ["carrychain"])
    # crossbar: 50% connectivity
    for (i, ipin), (o, opin) in product(enumerate(xbar_i), enumerate(xbar_o)):
        if i % 2 == o % 2:
            builder.connect(ipin, opin)
    clb = builder.commit()

    ctx.create_tunnel("carrychain", clb.ports["cout"], clb.ports["cin"], (0, -1))

    # -- BRAM --------------------------------------------------------------------
    builder = ctx.build_logic_block("prga_bram", 1, 2)
    inst = builder.instantiate(memory, "i_ram")
    builder.connect(
            builder.create_global(glb_clk, Orientation.south),
            inst.pins["clk"])
    builder.connect(
            builder.create_input("we", len(inst.pins["we"]), Orientation.west, (0, 0)),
            inst.pins["we"])
    for y in range(2):
        for p in ["raddr", "waddr", "din"]:
            bits = [b for i, b in enumerate(inst.pins[p]) if i % 2 == y]
            builder.connect(
                    builder.create_input("{}x{}".format(p, y), len(bits), Orientation.west, (0, y)),
                    bits)
        bits = [b for i, b in enumerate(inst.pins["dout"]) if i % 2 == y]
        builder.connect(bits,
                builder.create_output("doutx{}".format(y), len(bits), Orientation.west, (0, y)))

    bram = builder.commit()

    # -- Multiplier --------------------------------------------------------------
    builder = ctx.build_logic_block("prga_bmul", 1, 2)
    clk = builder.create_global(glb_clk, Orientation.south)
    ce = builder.create_input("ce", 1, Orientation.west, (0, 0))
    inst = builder.instantiate(ctx.create_multiplier(MUL_WIDTH, name="prga_prim_mul"), "i_mul")
    ffs = builder.instantiate(ctx.primitives["dffe"], "i_x_f", len(inst.pins["x"]))
    for y in range(2):
        for p in ["a", "b"]:
            bits = [b for i, b in enumerate(inst.pins[p]) if i % 2 == y]
            builder.connect(
                    builder.create_input("{}x{}".format(p, y), len(bits), Orientation.west, (0, y)),
                    bits)
        xbits, fbits = [], []
        for i, b in enumerate(inst.pins["x"]):
            if i % 2 == y:
                xbits.append(b)
                fbits.append(ffs[i].pins["Q"])
                builder.connect(clk, ffs[i].pins["C"])
                builder.connect(ce, ffs[i].pins["E"])
                builder.connect(b, ffs[i].pins["D"], vpr_pack_patterns = ["mul_x2f"])
        builder.connect(xbits,
                o := builder.create_output("x{}".format(y), len(xbits), Orientation.west, (0, y)))
        builder.connect(fbits, o)

    bmul = builder.commit()

    # ============================================================================
    # -- Tiles -------------------------------------------------------------------
    # ============================================================================
    iotile = ctx.build_tile(iob, NUM_IOB_PER_TILE,
            name = "prga_t_iob",
            edge = OrientationTuple(False, east = True),
            ).fill( (.5, .5) ).auto_connect().commit()
    clbtile = ctx.build_tile(clb,
            name = "prga_t_clb",
            ).fill( (0.15, 0.2) ).auto_connect().commit()
    bramtile = ctx.build_tile(bram,
            name = "prga_t_bram",
            ).fill( (0.15, 0.2) ).auto_connect().commit()
    bmultile = ctx.build_tile(bmul,
            name = "prga_t_bmul",
            ).fill( (0.15, 0.2) ).auto_connect().commit()

    # ============================================================================
    # -- Subarrays ---------------------------------------------------------------
    # ============================================================================
    pattern = SwitchBoxPattern.cycle_free(fill_corners = [Corner.northwest, Corner.southwest])

    # -- Single-Tile Arrays ------------------------------------------------------
    builder = ctx.build_array("prga_a_iob", 1, 1, set_as_top = False,
            edge = OrientationTuple(False, east = True))
    builder.instantiate(iotile, (0, 0))
    iosta = builder.fill( pattern ).auto_connect().commit()

    builder = ctx.build_array("prga_a_clb", 1, 1, set_as_top = False)
    builder.instantiate(clbtile, (0, 0))
    clbsta = builder.fill( pattern ).auto_connect().commit()

    builder = ctx.build_array("prga_a_bram", 1, 2, set_as_top = False)
    builder.instantiate(bramtile, (0, 0))
    bramsta = builder.fill( pattern ).auto_connect().commit()

    builder = ctx.build_array("prga_a_bmul", 1, 2, set_as_top = False)
    builder.instantiate(bmultile, (0, 0))
    bmulsta = builder.fill( pattern ).auto_connect().commit()

    # -- Subarray Type A (Left Mega Column) --------------------------------------
    builder = ctx.build_array("prga_region_left", SA_WIDTH, SA_HEIGHT, set_as_top = False)
    for x, y in product(range(builder.width), range(builder.height)):
        if x == SA_WIDTH - 1 and y == 0:
            # reserved for router
            pass
        elif x == SA_WIDTH - MM_COL:
            if y % bmulsta.height == 0:
                builder.instantiate(bmulsta, (x, y))
        else:
            builder.instantiate(clbsta, (x, y))
    left = builder.fill( pattern ).auto_connect().commit()

    # -- Subarray Type B (Right Mega Column) -------------------------------------
    builder = ctx.build_array("prga_region_right", SA_WIDTH + 1, SA_HEIGHT,
            set_as_top = False, edge = OrientationTuple(False, east = True))
    for x, y in product(range(builder.width), range(builder.height)):
        if x == SA_WIDTH - 1 and y == 0:
            # reserved for router
            pass
        elif x == MM_COL:
            if y % bramsta.height == 0:
                builder.instantiate(bramsta, (x, y))
        elif x == SA_WIDTH:
            builder.instantiate(iosta, (x, y))
        else:
            builder.instantiate(clbsta, (x, y))
    right = builder.fill( pattern ).auto_connect().commit()

    # ============================================================================
    # -- Fabric ------------------------------------------------------------------
    # ============================================================================
    builder = ctx.build_array("prga_fabric", FBRC_WIDTH, FBRC_HEIGHT, set_as_top = True)
    for y in range(SA_YCNT):
        builder.instantiate(left,  (1,            1 + y * SA_HEIGHT))
        builder.instantiate(right, (1 + SA_WIDTH, 1 + y * SA_HEIGHT))
    fabric = builder.auto_connect().commit()

    # ============================================================================
    # -- Configuration Chain Injection -------------------------------------------
    # ============================================================================
    def iter_instances(module):
        if module.name == "prga_t_clb":
            yield module.instances[0]
            yield module.instances[Orientation.west, 0]
        elif module.name == "prga_t_iob":
            for i in range(NUM_IOB_PER_TILE):
                yield module.instances[i]
            yield module.instances[Orientation.west, 0]
        elif module.name == "prga_t_bram":
            yield module.instances[0]
            yield module.instances[Orientation.west, 1]
            yield module.instances[Orientation.west, 0]
        elif module.name == "prga_t_bmul":
            yield module.instances[0]
            yield module.instances[Orientation.west, 1]
            yield module.instances[Orientation.west, 0]
        elif module.name.startswith( "prga_a_" ):
            for y in range(module.height):
                yield module.instances[(0, y), Corner.southwest]
                if y == 0: yield module.instances[0, y]
                yield module.instances[(0, y), Corner.northwest]
        elif module.name.startswith( "prga_region_" ):
            # for y in range(module.height):
            #     for x in reversed(range(module.width - 1)):
            #         if i := module.instances.get( (x, y) ): yield i
            #         if i := module.instances.get( ((x, y), Corner.southwest) ): yield i
            #     for x in range(module.width - 1):
            #         if i := module.instances.get( ((x, y), Corner.northwest) ): yield i
            # for y in reversed(range(module.height)):
            #     if i := module.instances.get( ((module.width - 1, y), Corner.northwest) ): yield i
            #     if i := module.instances.get(  (module.width - 1, y) ): yield i
            #     if i := module.instances.get( ((module.width - 1, y), Corner.southwest) ): yield i
            for y in range(module.height):
                if y % 2 == 0:
                    for x in reversed(range(module.width - 1)):
                        if x == SA_WIDTH - 1 and y == 0:
                            yield module.instances[(x, y), Corner.southwest]
                            yield module.instances[(x, y), Corner.northwest]
                        if i := module.instances.get( (x, y) ): yield i
                else:
                    for x in range(module.width - 1):
                        if i := module.instances.get( (x, y) ): yield i
            for y in reversed(range(module.height)):
                if module.width == SA_WIDTH and y == 0:
                    yield module.instances[     (module.width - 1, y), Corner.southwest]
                    yield module.instances[     (module.width - 1, y), Corner.northwest]
                if i := module.instances.get(   (module.width - 1, y) ): yield i
            yield None  # make this a leaf chain
        elif module.name == "prga_fabric":
            for x in reversed(range(SA_XCNT // 2)):
                # upper half
                # going up
                for y in range(SA_YCNT // 2, SA_YCNT):
                    yield module.instances[1 + (2 * x + 1) * SA_WIDTH, 1 + y * SA_HEIGHT]
                # going down
                for y in reversed(range(SA_YCNT // 2, SA_YCNT)):
                    yield module.instances[1 + (2 * x + 0) * SA_WIDTH, 1 + y * SA_HEIGHT]
                # wrap up branch chain
                yield None
                yield None
                # lower half
                # going down
                for y in reversed(range(SA_YCNT // 2)):
                    yield module.instances[1 + (2 * x + 1) * SA_WIDTH, 1 + y * SA_HEIGHT]
                # going down
                for y in range(SA_YCNT // 2):
                    yield module.instances[1 + (2 * x + 0) * SA_WIDTH, 1 + y * SA_HEIGHT]
                # wrap up branch chain
                yield None
                yield None
        else:
            for i in module.instances.values():
                yield i

    Flow(
        Translation(),
        SwitchPathAnnotation(),
        Pktchain.InsertProgCircuitry(iter_instances = iter_instances),
        VPRArchGeneration("vpr/arch.xml"),
        VPR_RRG_Generation("vpr/rrg.xml"),
        YosysScriptsCollection("syn"),
        ).run(ctx, Pktchain.new_renderer())

    # ============================================================================
    # -- Insert FIFO Buffer ------------------------------------------------------
    # ============================================================================
    design_top = ctx.database[ModuleView.design, ctx.top.key]
    for inst in list(design_top.instances.values()):
        if inst.model.module_class.is_array:    # for subarrays
            clk             = NetUtils.get_source(inst.pins[ "prog_clk" ])
            rst             = NetUtils.get_source(inst.pins[ "prog_rst" ])
            phit_i          = NetUtils.get_source(inst.pins[ "phit_i_b0" ])
            phit_i_wr       = NetUtils.get_source(inst.pins[ "phit_i_wr_b0" ])
            phit_i_full     = NetUtils.get_sinks (inst.pins[ "phit_i_full_b0" ])[0]

            NetUtils.disconnect( sinks   = inst.pins[ "phit_i_b0" ] )
            NetUtils.disconnect( sinks   = inst.pins[ "phit_i_wr_b0" ] )
            NetUtils.disconnect( sources = inst.pins[ "phit_i_full_b0" ] )
            
            # insert 2 stages
            for i in range(2):
                ibuf = ModuleUtils.instantiate( design_top, fifobuf, "i_fifo_buf_{}_s{}".format(inst.name, i) )

                NetUtils.connect(clk,                               ibuf.pins["clk"])
                NetUtils.connect(rst,                               ibuf.pins["rst"])
                NetUtils.connect(phit_i,                            ibuf.pins["data_i"])
                NetUtils.connect(phit_i_wr,                         ibuf.pins["wr_i"])
                NetUtils.connect(ibuf.pins["full_o"],               phit_i_full)

                phit_i          = ibuf.pins["data_o"]
                phit_i_wr       = ibuf.pins["wr_o"]
                phit_i_full     = ibuf.pins["full_i"]

            # connect to subarray
            NetUtils.connect(phit_i,                                inst.pins["phit_i_b0"])
            NetUtils.connect(phit_i_wr,                             inst.pins["phit_i_wr_b0"])
            NetUtils.connect(inst.pins["phit_i_full_b0"],           phit_i_full)

    # ============================================================================
    # -- Pickle Context ----------------------------------------------------------
    # ============================================================================

    ctx.pickle("ctx.tmp.pkl")

v = VerilogCollection("rtl", "include")
v.renderer = r = Pktchain.new_renderer(["./templates"])
v._process_module( ctx.database[ModuleView.design, "prga_l15_transducer"] )
v._process_module( ctx.database[ModuleView.design, "prga_fe_axi4lite"] )

Flow(
        Pktchain.BuildSystem("constraints/io.pads",
            core = "prga_fabric_wrap", prog_be_in_core = True,
            interfaces = {InterfaceClass.reg_simple, InterfaceClass.ccm_axi4}),
    ).run(ctx)

top = ctx.database[ModuleView.design, "prga_fabric_wrap"]
i_prog_be = top.instances["i_prog_be"]
i_prog_be.verilog_parameters = {
        "DECOUPLED_INPUT": "1",
        "DECOUPLED_OUTPUT": "1",
        }

# flop reset for 2 cycles
rst = top.ports["prog_rst_n"]
sinks = NetUtils.get_sinks( rst )
NetUtils.disconnect( sources = rst )

for i in range(2):
    inst = ModuleUtils.instantiate( top, ctx.database[ModuleView.design, "prga_simple_buf"],
            "prog_rst_n_buf_s" + str(i) )
    NetUtils.connect(top.ports["prog_clk"], inst.pins["C"])
    NetUtils.connect(rst, inst.pins["D"])
    rst = inst.pins["Q"]

for sink in sinks:
    NetUtils.connect(rst, sink)

Flow( v ).run(ctx, r)

ctx.pickle("ctx.pkl")
