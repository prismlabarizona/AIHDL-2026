# SPDX-License-Identifier: Apache-2.0
# End-to-end AES-128 test through the SPI register bridge (FIPS-197 App. B).
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

from tqv import TinyQV

TEST_KEY = 0x2B7E151628AED2A6ABF7158809CF4F3C
TEST_PLAIN = 0x3243F6A8885A308D313198A2E0370734
EXPECTED = 0x3925841D02DC09FBDC118597196A0B32


def word(v, i):
    return (v >> (32 * i)) & 0xFFFFFFFF


@cocotb.test()
async def test_aes_fips_e2e(dut):
    dut._log.info("Start")
    clock = Clock(dut.clk, 34, units="ns")  # 29.4 MHz signoff clock
    cocotb.start_soon(clock.start())

    tqv = TinyQV(dut, 0)
    await tqv.reset()

    # key registers are write-only: must read back zero
    assert await tqv.read_word_reg(0x02) == 0, "key must not be readable"

    # load key (0x02-0x05) and plaintext (0x06-0x09)
    for i in range(4):
        await tqv.write_word_reg(0x02 + i, word(TEST_KEY, i))
    for i in range(4):
        await tqv.write_word_reg(0x06 + i, word(TEST_PLAIN, i))

    # start (CTRL bit0), poll STATUS bit0 = done
    await tqv.write_word_reg(0x00, 1)
    status = 0
    for _ in range(50):
        status = await tqv.read_word_reg(0x01)
        if status & 1:
            break
    assert status & 1, f"done never set (STATUS={status:#x})"
    assert not (status & 2), "fault flag set"

    # ciphertext at 0x0A-0x0D
    result = 0
    for i in range(4):
        result |= (await tqv.read_word_reg(0x0A + i)) << (32 * i)
    assert result == EXPECTED, f"ciphertext {result:#034x} != {EXPECTED:#034x}"

    # key still not readable after use
    assert await tqv.read_word_reg(0x05) == 0, "key must not be readable"

    # hard reset clears readable state (ciphertext + status)
    await tqv.reset()
    assert await tqv.read_word_reg(0x0A) == 0, "ciphertext must clear on reset"
    assert (await tqv.read_word_reg(0x01)) & 3 == 0, "status must clear on reset"

    dut._log.info("FIPS-197 round-trip OK")
