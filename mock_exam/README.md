# 上機考模擬題：Advanced

期中上機考前的練習題，範圍 Lab 1 ~ Lab 5，難度對齊各 Lab 的 Advanced（30%）。一律用 PIC18F4520 assembly（MPASM）撰寫，不能搭配 C。建議每題 25 分鐘內完成。

所有預期輸出都用 Python 驗算過。

| 題目 | 主題 | 對應 Lab |
|---|---|---|
| [Advanced 1](#advanced-1run-length-encoding) | Run-Length Encoding | Lab 2 indirect addressing |
| [Advanced 2](#advanced-216--16-乘法-macro不准用硬體乘法) | 16×16 乘法 macro，禁用 `MULWF` | Lab 3 + Lab 4 |
| [Advanced 3](#advanced-316-bit-質因數分解) | 16-bit 質因數分解 | Lab 4 subroutine + Lab 5 |
| [Advanced 4](#advanced-4crc-8-校驗碼) | CRC-8 校驗碼 | Lab 2 + Lab 3 |
| [Advanced 5](#advanced-54-位數-packed-bcd-加法禁用-daw) | packed BCD 加法，禁用 `DAW` | Lab 3 + Lab 4 |

---

## Advanced 1：Run-Length Encoding

**Description**

序列長度 `l` 存在 `[0x000]`，序列從 `[0x100]` 開始，佔 `0x100 ~ 0x100+l-1`，每個元素是 unsigned 8-bit。請對序列做 RLE 壓縮，把連續相同的值壓成一組 `(value, count)`。

- 從 `[0x200]` 開始依序存放 `value0, count0, value1, count1, ...`
- 總組數存在 `[0x001]`
- `1 ≤ l ≤ 255`，所以 count 不會超過 255

**Example**

| | Test Case 1 | Test Case 2 |
|---|---|---|
| `[0x000]` | `0x0A` | `0x06` |
| 序列 | `05 05 05 07 07 01 09 09 09 09` | `FF 00 00 00 00 FF` |
| `[0x001]` | `0x04` | `0x03` |
| `[0x200]~` | `05 03 07 02 01 01 09 04` | `FF 01 00 04 FF 01` |

**Standard of grading**

1. 讀取序列、寫入結果都必須用 indirect addressing（FSR / INDF / POSTINC…）。
2. 長度必須從 `[0x000]` 讀取，不能寫死。
3. 最後一組也要輸出；`l = 1` 時 `[0x001] = 1`。

---

## Advanced 2：16 × 16 乘法 macro，不准用硬體乘法

**Description**

定義 macro `Mul16 xH, xL, yH, yL`，計算兩個 16-bit unsigned 整數相乘的 32-bit 結果。

- x：`[0x000]`（high）、`[0x001]`（low）
- y：`[0x002]`（high）、`[0x003]`（low）
- 結果 high-byte-first 存到 `[0x010] ~ [0x013]`

**Example**

| | TC1 | TC2 | TC3 |
|---|---|---|---|
| x | `0x1234` | `0xFFFF` | `0x8000` |
| y | `0x5678` | `0xFFFF` | `0x0003` |
| `[0x010]~[0x013]` | `06 26 00 60` | `FF FE 00 01` | `00 01 80 00` |

**Standard of grading**

1. 必須寫成 macro，並以 `Mul16 0x00, 0x01, 0x02, 0x03` 的形式呼叫。
2. 禁止使用 `MULWF`、`MULLW`，要用 shift-and-add（`RRCF` / `RLCF` 搭配 carry 傳遞）。
3. 不能修改輸入 `[0x000]~[0x003]`。

> 提示：y 右移，每次看移出的 bit（C flag）。是 1 就把 x 加到 32-bit 累加器的高半部，然後整個累加器右移一位，共 16 次。加法產生的 carry 也要一起右移進去。

---

## Advanced 3：16-bit 質因數分解

**Description**

`[0x000]`（high）、`[0x001]`（low）存一個 16-bit unsigned 整數 N（`1 ≤ N ≤ 65535`）。請將 N 質因數分解，由小到大存放。

- 從 `[0x020]` 開始，每個不同的質因數佔 3 bytes：`prime_H, prime_L, exponent`
- 不同質因數的個數存在 `[0x010]`
- `N = 1` 時 `[0x010] = 0`

**Example**

| | TC1 | TC2 | TC3 | TC4 |
|---|---|---|---|---|
| N | `0x0168`（360） | `0xFFFF` | `0xFFF1`（65521） | `0x7E00` |
| `[0x010]` | `0x03` | `0x04` | `0x01` | `0x03` |
| `[0x020]~` | `00 02 03` `00 03 02` `00 05 01` | `00 03 01` `00 05 01` `00 11 01` `01 01 01` | `FF F1 01` | `00 02 09` `00 03 02` `00 07 01` |

**Standard of grading**

1. 必須寫一個名為 `division` 的 subroutine（16-bit ÷ 8-bit，回傳 16-bit 商與 8-bit 餘數），以 `RCALL` / `CALL` 呼叫，整除判斷必須透過它。
2. 結果的位址、順序、格式都要正確。

> 陷阱：65535 = 3 · 5 · 17 · 257，257 超過 8-bit 除數範圍。試除到 255 之後若剩下的 N > 1，它一定是質數（因為 √65535 < 256），要用 16-bit 存進去。TC2、TC3 就是在考這點。

---

## Advanced 4：CRC-8 校驗碼

**Description**

序列長度 `l` 存在 `[0x000]`（`1 ≤ l ≤ 255`），資料從 `[0x100]` 開始。請計算整段資料的 CRC-8（多項式 `0x07`，初值 `0x00`），結果存到 `[0x010]`。

```
crc = 0x00
for each byte b:
    crc = crc XOR b
    repeat 8 times:
        if crc bit7 == 1:  crc = (crc << 1) XOR 0x07
        else:              crc = (crc << 1)
```

左移只保留低 8 位。

**Example**

| | TC1 | TC2 | TC3 | TC4 |
|---|---|---|---|---|
| `[0x000]` | `0x09` | `0x01` | `0x03` | `0x02` |
| 資料 | `31 32 33 34 35 36 37 38 39`（"123456789"） | `FF` | `01 02 03` | `80 00` |
| `[0x010]` | `0xF4` | `0xF3` | `0x48` | `0xB6` |

**Standard of grading**

1. 讀取資料必須用 indirect addressing。
2. 長度必須從 `[0x000]` 讀取。
3. 必須用到 `XORWF` / `XORLW`，以及 `RLCF` / `RLNCF` 或 `BTFSC` / `BTFSS` 判斷 bit7。

> 陷阱：要先判斷 bit7 再左移。用 `RLCF` 要先清 C，否則 carry 會進 bit0；用 `RLNCF` 則 bit7 會轉回 bit0，要另外處理。TC1 的 `0xF4` 是 CRC-8 的標準 check value。

---

## Advanced 5：4 位數 packed BCD 加法，禁用 `DAW`

**Description**

兩個 4 位數十進位數以 packed BCD 表示（每個 nibble 是 0~9）：

- A：`[0x000]`（千、百位）、`[0x001]`（十、個位）
- B：`[0x002]`（千、百位）、`[0x003]`（十、個位）

請算 A + B，結果以 packed BCD 存放：`[0x010]` 萬位（`0x00` 或 `0x01`），`[0x011]` 千、百位，`[0x012]` 十、個位。

**Example**

| | TC1 | TC2 | TC3 | TC4 |
|---|---|---|---|---|
| A | `12 34` | `09 99` | `45 67` | `99 99` |
| B | `87 66` | `00 01` | `23 45` | `99 99` |
| `[0x010]~[0x012]` | `01 00 00` | `00 10 00` | `00 69 12` | `01 99 98` |

**Standard of grading**

1. 禁止使用 `DAW`，十進位調整要自己做。
2. 必須寫一個名為 `bcd_add_byte` 的 subroutine（兩個 packed BCD byte 加上進位），呼叫兩次：先低位 byte，再高位 byte。
3. 不能修改輸入 `[0x000]~[0x003]`。

> 提示：個位、十位分開處理（`ANDLW 0x0F` 取低 nibble，`SWAPF` + `ANDLW 0x0F` 取高 nibble）。每位數 = a + b + carry_in，≥ 10 就減 10 並令 carry_out = 1。TC4 的 9+9+1 = 19 > 15，只靠「> 9 就加 6」的 nibble 寫法會出錯；TC2 測連續進位。
