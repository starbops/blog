---
layout: post
title: 'Motherboard & RAM'
category: note
slug: motherboard-and-ram
---
## 記憶體挑選準則

- 時脈越高越好
- 時序越低越好

## 記憶體種類

- 揮發性記憶體 Volatile Memory
    - Static Random Access Memory (SRAM)
    - Dynamic Random Access Memory (DRAM)
- 非揮發性記憶體 Non-Volatile Memory
    - Read-Only Memory (ROM)
    - Flash Memory

## DRAM Level

1. Channel

    每組記憶體控制器個別對應一個 channel。

2. DIMM

    早前消費者必須購買記憶體顆粒直接插在主機板上，而後才漸漸發展出將多組記憶體顆粒焊在一片電路板上的做法，隨著時代演進依序出現以下兩種配置：

    - Single In-line Memory Module (SIMM) 頻寬 32-bit
    - Dual In-line Memory Module (DIMM) 頻寬 64-bit
3. Rank

    可視為「分組」。連接到同一個 Chip Select (CS) 的記憶體顆粒 (Chip)。

    一個 Rank 會有幾顆 Chip 端看記憶體控制器頻寬與顆粒頻寬之間的關係。記憶體控制器通道 64-bit 寬，記憶體顆粒則是 8-bit 寬，則並聯八顆即可滿足記憶體控制器的需求，也就是一組 Rank。若記憶體顆粒通道為 16-bit 寬，則一組 Rank 只有四顆 Chip。

    因為雙 Rank (2R) 的模組因為顆粒數目較多，大多會將顆粒焊在兩面；而單一 Rank 的模組有焊在同一面也有焊在兩面的。**記憶體模組 Rank 數與單雙面焊件並無絕對關係**，有雙面雙 Rank 的記憶體模組，也有雙面單 Rank 的記憶體模組。

4. Chip
5. Bank
6. Row/Column

## Motherboard Memory Layouts

一般的主機板，CPU 內部的 Integrated Memory Controller (IMC) 走線到記憶體插槽在四個插槽以上的配置有兩種：

- Daisy Chain
- T-Type (T-Topology)

![Daisy Chain / T-Type](/assets/images/motherboard-and-ram/Untitled.png)

在 ITX 或特規主機板上通常只有兩個記憶體插槽，在 1 DIMM Per Channel (1DPC) 這樣的配置下，IMC 很單純就是各拉一條線到個別的插槽，沒有兩條記憶體共享頻寬的問題，因此訊號最好記憶體也最容易超頻上去。

### ODT

在 DDR 和 DDR2 時代，阻抗做在主機板上，較難適配不同的記憶體。DDR3 則是改成在記憶體上的 On-Die Termination (ODT)，透過主機板 BIOS 中的 Memory Reference Code (MRC) 針對不同的記憶體去調控阻抗。

signal reflection

天線 (stub) 所造成的干擾

> 單面比較好超

> CPU 的 IMC 品質好壞也會影響到記憶體的超頻能力

## Configuration

- 1 DIMM Per Channel (1DPC)
- 2 DIMMs Per Channel (2DPC)

## 同捆包

絕大部分市售雙通道、四通道組合之記憶體皆為通過 1DPC configuration 測試，極少數有測試 2DPC configuration。

- 兩根包
- 四根包

## SPD

記憶體上的 EEPROM 是介於 BIOS 和記憶體本身之間很重要的溝通工具，開機時 BIOS 用以確認初始記憶體頻率、電壓等參數，另外還記錄了：

- XMP profile（Intel 平臺）
- Chip ID（板廠可藉由此參數辨別顆粒特性來優化）
- Stepping ID
- PCB ID

## 記憶體體質判斷

記憶體廠商生產出記憶體後，定義其頻率的方式是看在某特定平臺（通常是 1DPC 配置）上測試能穩跑的最低頻率。因此這個「特定平臺」就變成了重點。

記憶體體質不能只看標籤，要搭配主機板以及 configuration（1DPC 或 2DPC）共同來看。QVL 過測的記憶體主機板組合一定可以跑到其宣稱頻率甚至更高。

**同樣的一根記憶體，其表現在不同平臺會有落差。**以 ITX 平臺（兩插槽 1DPC）生產過測的 DDR4-3600 兩根包為例：

- Daisy Chain layout 主機板：維持或稍降
- T-Type layout 主機板：降很多

又，一根在 T-Type 生產過測的記憶體，改插 Daisy Chain 其頻率可以再拉高。

## References

- [SPD 講解](https://youtu.be/xQNcpA1DuHE)
- [主機板上的記憶體線路不同所造成的訊號差異](https://youtu.be/9fTOux85nmE)
- [RAM 結構講解（資料可能有點過時）](https://www.techbang.com/posts/18381-from-the-channel-to-address-computer-main-memory-structures-to-understand)
- [記憶體 Rank 數與單雙面無關](https://www.strongpilab.com/ddr-2rx8-rank-not-side/)
- [記憶體體質定義](https://youtu.be/JTcIlt-zbsw)
