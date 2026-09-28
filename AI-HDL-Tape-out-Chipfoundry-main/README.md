# AI-HDL Tapeout — sky130A, signed-off GDSII

11 designs, SkyWater sky130A, LibreLane 3.0.5 / OpenROAD. Sign-off September 2026.

| Design | GDSII | DRC | LVS | Metrics |
|---|---|---|---|---|
| itims-spi | [gds](itims-spi/gds/tt_um_itims_spi.gds) | [0 violations](itims-spi/signoff/drc.magic.rpt) | [clean](itims-spi/signoff/lvs.netgen.rpt) | [metrics](itims-spi/signoff/metrics.json) |
| necrl-aes128 | [gds](necrl-aes128/gds/tt_um_necrl_aes128.gds) | [0 violations](necrl-aes128/signoff/drc.magic.rpt) | [clean](necrl-aes128/signoff/lvs.netgen.rpt) | [metrics](necrl-aes128/signoff/metrics.json) |

All designs: Magic DRC **0 violations**, Netgen LVS **"Circuits match uniquely"**.
RTL + hardening config under each design's `src/`. Large GDS are xz-compressed
(`xz -dk <file>`). Apache-2.0.

## TinyTapeout-format projects (`tinytapeout/`)

For MPW integration via the ChipFoundry flow, each design is also provided as
a complete [chipdiscover-verilog-template](https://github.com/chipfoundry/chipdiscover-verilog-template)
project under `tinytapeout/`: `tt_um_*` top with the standard TinyTapeout
pinout, completed `info.yaml` (v6, tile size set), datasheet `docs/info.md`,
and cocotb tests in `test/` (all passing locally with the exact commands the
template's `test` workflow runs).

| Project | top_module | tiles |
|---|---|---|
| [tt-itims-spi](tinytapeout/tt-itims-spi) | tt_um_itims_spi | 2x2 |
| [tt-necrl-aes128](tinytapeout/tt-necrl-aes128) | tt_um_necrl_aes128 | 4x2 |

To submit any project for tapeout, create a public repo from the template,
copy the project's contents over it, and enable GitHub Actions (`test` →
`gds` → `precheck` → `gl_test` run on push).
