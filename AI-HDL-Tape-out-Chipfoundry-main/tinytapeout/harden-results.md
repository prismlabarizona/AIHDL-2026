# Local pre-hardening results (LibreLane 2.4.2, sky130A, TT gds recipe)

Every chip-bound project was hardened locally with the exact `gds`-Action
flow before publication. GEMM is excluded per ChipFoundry (exceeds any tile).

| project | tiles | GDS | DRC | LVS | setup vio | hold vio | util % |
|---|---|---|---|---|---|---|---|
| tt-slm-cpu | 8x2 | [gds.xz](signoff/tt-slm-cpu/tt_um_slm_cpu.gds.xz) | 0 | 0 | 0 | 0 | 56.1 |
| tt-slm-gemm | 8x2 | — | — | — | — | — | excluded (too large) |
| tt-slm-softmax | 8x2 | [gds.xz](signoff/tt-slm-softmax/tt_um_slm_softmax.gds.xz) | 0 | 0 | 0 | 0 | 69.7 |
| tt-slm-rmsnorm | 8x2 | [gds.xz](signoff/tt-slm-rmsnorm/tt_um_slm_rmsnorm.gds.xz) | 0 | 0 | 0 | 0 | 47.2 |
| tt-slm-kv | 6x2 | [gds.xz](signoff/tt-slm-kv/tt_um_slm_kv.gds.xz) | 0 | 0 | 0 | 0 | 55.0 |
| tt-slm-dma | 6x2 | [gds.xz](signoff/tt-slm-dma/tt_um_slm_dma.gds.xz) | 0 | 0 | 0 | 0 | 59.5 |
| tt-uofa-mul | 8x2 | [gds.xz](signoff/tt-uofa-mul/tt_um_mul_soc.gds.xz) | 0 | 0 | 0 | 0 | 59.1 |
| tt-uofa-gpio | 8x2 | [gds.xz](signoff/tt-uofa-gpio/tt_um_gpio_soc.gds.xz) | 0 | 0 | 0 | 0 | 38.0 |
| tt-uofa-bp | 8x2 | [gds.xz](signoff/tt-uofa-bp/tt_um_bp_soc.gds.xz) | 0 | 0 | 0 | 0 | 60.9 |
| tt-uofa-bmu | 6x2 | [gds.xz](signoff/tt-uofa-bmu/tt_um_bmu_soc.gds.xz) | 0 | 0 | 0 | 0 | 31.9 |
| tt-uofa-bmi | 6x2 | [gds.xz](signoff/tt-uofa-bmi/tt_um_bmi_soc.gds.xz) | 0 | 0 | 0 | 0 | 34.0 |
| tt-uofa-vec-proc | 8x2 | [gds.xz](signoff/tt-uofa-vec-proc/tt_um_vec_proc.gds.xz) | 0 | 0 | 0 | 0 | 67.3 |
| tt-uofa-vec-coproc | 4x2 | [gds.xz](signoff/tt-uofa-vec-coproc/tt_um_vec_coproc.gds.xz) | 0 | 0 | 0 | 0 | 49.6 |
| tt-uofa-traffic | 1x1 | [gds.xz](signoff/tt-uofa-traffic/tt_um_uofa_traffic.gds.xz) | 0 | 0 | 0 | 0 | 71.0 |
| tt-itims-spi | 2x2 | [gds.xz](signoff/tt-itims-spi/tt_um_itims_spi.gds.xz) | 0 | 0 | 0 | 0 | 27.7 |
| tt-necrl-aes128 | 4x2 | [gds.xz](signoff/tt-necrl-aes128/tt_um_necrl_aes128.gds.xz) | 0 | 0 | 0 | 0 | 63.5 |
