# Stripes

Stripes is based upon OpenPiton adding many new exciting features!

* Socket interface for integrating cores, accelerators, and widgets
* Intelligent Storage (IS) tiles, which includes support for [indirect memory access](https://dl.acm.org/doi/abs/10.1145/3470496.3527400), smart data re-layout, and bit serial computing.
* [PRGA](https://dl.acm.org/doi/10.1145/3431920.3439294) for fully synthesizable on-chip FPGAs
* On-chip interrupt updates

For more information, please check out the [DECADES project](https://decades.cs.princeton.edu/) and check out our [DECADES CICC 2023](https://ieeexplore.ieee.org/document/10121257) paper.

We would also like to thank the entire DECADES team which without their hard work, this project would not have been possible!

DECADES CICC 2023 citation: Fei Gao, Ting-Jung Chang, Ang Li, Marcelo Orenes-Vera, Davide Giri, Paul J. Jackson, August Ning, Georgios Tziantzioulis, Joseph Zuckerman, Jinzheng Tu, Kaifeng Xu, Grigory Chirkov, Gabriele Tombesi, Jonathan Balkind, Margaret Martonosi, Luca Carloni, David Wentzlaff, "DECADES: A 67mm2, 1.46TOPS, 55 Giga Cache-Coherent 64-bit RISC-V Instructions per second, Heterogeneous Manycore SoC with 109 Tiles including Accelerators, Intelligent Storage, and eFPGA in 12nm FinFET," 2023 IEEE Custom Integrated Circuits Conference (CICC), San Antonio, TX, USA, 2023, pp. 1-2, doi: 10.1109/CICC57935.2023.10121257.

### Get Started

Follow the directions below to get started with Stripes. Further details on OpenPiton can be found on the main [OpenPiton](https://github.com/PrincetonUniversity/openpiton) repo.

#### Environment Setup
- The ```PITON_ROOT``` environment variable should point to the root of the Stripes repository

- The Synopsys environment for simulation should be setup separately by the user.  Besides adding correct paths to your ```PATH``` and ```LD_LIBRARY_PATH``` (usually accomplished by a script provided by Synopsys), the OpenPiton tools specifically reference the ```VCS_HOME``` environment variable which should   point to the root of the Synopsys VCS installation.

- Clone and build the RISCV toolchain:
    - Follow https://github.com/riscv-collab/riscv-gnu-toolchain to build the riscv-gnu toolchain at your preferred location.
    - After the build completes, set `RISCV` environment variable to the built toolchain. The directory structure should look like follows
      ```
        $RISCV/
        ├─ bin/
        │  ├─ riscv64-unknown-elf-*
        │  ├─ spike
        │  └─ ...
        ├─ include/
        ├─ lib/
        └─ ...
      ```
    - Then, `export PATH=${PATH}:${RISCV}/bin`
- Setup environment variables for the Ariane core
    ```
    export ARIANE_ROOT=$PITON_ROOT/piton/design/chip/tile/ariane
    ```
- Run ```source $PITON_ROOT/piton/piton_settings.bash``` to setup the environment

- Run `source piton/ariane_setup.sh` to setup Ariane.

##### Notes on Environment and Dependencies

- Depending on your system setup, Synopsys tools may require the ```-full64``` flag.  This can easily be accomplished by adding a bash function as shown in the following example for VCS (also required for URG):

    ```bash
    function urg() { command urg -full64 "$@"; }; export -f urg
    function vcs() { command vcs -full64 "$@"; }; export -f vcs
    function dve() { command dve -full64 "$@"; }; export -f dve
    ```

#### Running Custom Programs

You can run test programs written in C. The following example program just prints 32 times "hello_world" to the fake UART (see `fake_uart.log` file).

1. ```cd $PITON_ROOT/build```
2. ```sims -sys=manycore -x_tiles=1 -y_tiles=1 -vcs_build -ariane```
3. ```sims -sys=manycore -vcs_run -x_tiles=1 -y_tiles=1 hello_world.c -ariane -rtl_timeout 10000000```

And a simple hello world program running on multiple tiles can run as follows:

1. ```cd $PITON_ROOT/build```
2. ```sims -sys=manycore -x_tiles=4 -y_tiles=4 -vcs_build -ariane```
3. ```sims -sys=manycore -vcs_run -x_tiles=4 -y_tiles=4  hello_world_many.c -ariane -finish_mask 0x1111111111111111 -rtl_timeout 1000000```

In the example above, we have a 4x4 Ariane tile configuration, where each core just prints its own hart ID (hardware thread ID) to the fake UART. Synchronization among the harts is achieved using an atomic ADD operation.

---
