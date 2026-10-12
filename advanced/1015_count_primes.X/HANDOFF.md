# Lab 5 Advanced：`count_primes` 交接說明

這個資料夾是 Lab 5（Mixing with C）Advanced 題的目前進度，交給「Lab 05 优化」session 做**速度優化**。正確性已在 MPLAB 模擬器驗證過（見下方），優化時不能把正確性弄壞。

## 題目

```c
extern unsigned int count_primes(unsigned int n, unsigned int m);
```

回傳 `n ≤ p ≤ m` 的質數個數，`n`、`m` 都是 16 位元無號數。PIC18F4520，XC8 v4.00 + pic-as，只交 `count_primes.S`（不含 `main.c`）。

## judge 的規則與已知行為

- 線上 judge 用自製的 C 模擬器（比 MPLAB 快約 900 倍），20 組測資（14 固定 + 6 隨機），每組答對 1 分；全對之後依 cycle 數給速度分：
  `Score = 10 × (1 − (R − 1) / (1600 − 1))`，`R` = 你的 cycle ÷ 參考程式的 cycle。
- **同一次執行裡連續呼叫 `count_primes` 20 次**，所以所有狀態都要在函式開頭重設（之前 `count` 沒清零，答案一路累加）。
- 呼叫時 BSR 不保證是 0：每個指令都要明寫 `, a`（組譯不能有 `(1522)` 警告）。
- 不能寫死任何 RAM 位址：參數用 `_count_primes$0`（n）、`_count_primes$1`（m），回傳值寫到 `_count_primes$0`（低位）和 `(_count_primes$0+1)`（高位），變數用 `PSECT` + `DS`。
- judge 支援 `TBLRD`；它會回報函式改了哪些暫存器（例如 `TBLPTRL`、`TABLAT`、`FSR0H`…），並自動復原，只是資訊。
- 測資名稱（看得到的部分）：tiny `(1,10)`=4、two-only `(2,2)`=1、no-primes `(24,28)`=0、mid-range `(100,200)`=21、full-range `(1,65535)`=6542，另有 high-window、rand-wide、rand-narrow、rand-cent、rand-full 等隱藏測資。**`n == m` 會出現**，`n` 可能是 0 或 1。
- HackMD 範例畫面裡，別人通過的程式全範圍約 1.4 億 cycle、baseline 寫 1,000,000。

## 目前的演算法（`count_primes.S`）

分段篩法，每段 256 個數：

1. 開頭：`count = 0`、清空 `arr`；`n < 2` 時改成 2；`m < n` 直接回傳 0；`high = n − 1`。
2. `loop`：`Move_hilo_ptr` 算 `lo = high + 1`、`hi = lo + 255`（16 位元，超過 65535 時飽和）；`check_high_ptr` 把 `hi` 夾到 `m`。
3. `count_primes_segment`：對質數表（Flash，`TBLRD*+`，2…251，以 0 結尾）每個 `p`：
   - `p² > m` 就跳過（`comparePsquare`）；
   - `setStart`：從 `p` 開始一直 `+p`，直到 `≥ lo`（**這裡最慢**）；再跟 `p²` 取大；
   - 標記迴圈：`arr[x − lo]` 設 bit 0，直到 `x > hi`；`x + p` 超過 65535 就停。
4. `CountAndResetArray`：數 `arr[0 … hi−lo]` 裡是 0 的格數，然後把 256 格清成 0。
5. `hi == m` 就回傳，否則回到 `loop`。

`arr` 放在 `PSECT udata_bank1`（256 bytes），只用 FSR 存取；其餘變數在 `udata_acs`。

## 已驗證（MPLAB 模擬器 + mdb，同一次執行連續呼叫）

`(1,10)`=4、`(2,2)`=1、`(24,28)`=0、`(0,1)`=0、`(1,1)`=0、`(0,0)`=0、`(100,200)`=21、`(5,5)`=1、`(4,4)`=0、`(114,514)`=67、`(256,1000)`=114、`(65400,65535)`=11、`(65535,65535)`=0，另外單獨跑過 `(65000,65535)`=49、`(1,5000)`=669、`(512,2000)`=206、`(1,2000)`=303。

**這一版還沒交到 judge 上驗證過。** `(1,65535)` 在 MPLAB 模擬器太慢，沒跑完；上一版（只差 `count` 沒清零）在 judge 上全範圍約 2.4 億 cycle。

## 已修過的坑（優化時不要再踩）

- 無號比較一律看 Carry（`subwf` 後 `bnc`/`bc`），不要用 `bn`/`bnn`。
- 16 位元減法用 `subwf` + `subwfb`，不要用會改到被減數的二補數寫法。
- 標記用 `bsf`，不要用 `incf`（同一格被標兩次會讓 bit 0 變回 0）。
- 每個質數開始時清 `temp2_h`；每段重設 `TBLPTR`；找起點是跟本段的 `lo` 比，不是跟 `n` 比；標記上界是 `hi`，不是 `m`。
- `lo` 的低位元組為 0 時，`hi = lo + 255` 要用真正的 16 位元加法。
- `x += p`、`start += p` 都要檢查超過 65535。

## 優化方向（由效益大到小，僅供參考）

1. **不要每段重找起點**：存一張 `next[p]`（約 54 × 2 bytes，放 banked RAM，用 FSR 存取），換段時直接沿用上一段標記結束的位置；只有第一段需要算起點（可用除法或一次性的加法）。
2. `p² > hi` 時直接結束這段的質數迴圈（目前是繼續讀完整張表）。
3. 只存奇數，陣列與標記量減半；2 另外處理。
4. 標記迴圈不要每步重算 `FSR2` 和做 16 位元比較：在段內只用 8 位元的位移量，`arr` 對齊 256 時可以只看 `FSR2L` 的進位。
5. 清陣列只做一次（目前開頭清一次、每段數完再清一次）。
6. 若助教允許，可考慮把質數 bitmap 或前綴計數放在 Flash 查表。

## 本機測試

```bash
tools/multitest.sh count_primes.S "1 10" "2 2" "24 28" "100 200" "114 514"
```

需要 XC8 v4.00、`PIC18Fxxxx_DFP` 1.8.178（含 `xc8` 資料夾）和 MPLAB 的 `mdb.sh`；路徑用 `XC8`、`DFP`、`MDB` 環境變數指定。注意：產生的 `main.c` 必須逐行呼叫，不能用 for 迴圈包住呼叫（XC8 會把迴圈變數和 `_count_primes$1` 放在同一個位址）。

MPLAB X 專案設定（`nbproject/`）在 Additional options 加了 `-mdfp=…/PIC18Fxxxx_DFP/1.8.178/xc8`，因為 MPLAB X 5.20 不會自動傳這個參數。
