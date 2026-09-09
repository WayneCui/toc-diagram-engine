# TOC Diagram Engine

中文因果句 DSL → TOC 六棵树 SVG。Oldes Rebol3。

## 一句话

写下「如果…那么…」「要想…就必须…」，生成现状图 / 冲突图 / 未来图 / 负面分支 / 前提条件树 / 转变图。

## 依赖

- [Oldes Rebol3](https://github.com/Oldes/Rebol3) `r3`（本机常用 `/Users/wayne/.local/bin/r3`）
- 可选：`rsvg-convert` 把 SVG 转 PNG

## 用法

```bash
r3 main.reb parse examples/firefighting.toc
r3 main.reb render examples/firefighting.toc --out out/
r3 tests/run-pure.reb
```

## DSL 要点

- 陈述一律用「」；同一句话跨树共用同一实体
- 充分因果树（现状图/未来图/负面分支/转变图）只用「如果…那么…」
- 必要条件树（冲突图/前提条件树）只用「要想…就必须…」
- 「并且」只在引号外作合取；「因为」挂在上一根箭头上当假设
- 冲突图用「A」与「B」冲突；注入用「打破」或「剪断」

完整文法与不变量见 [ARCHITECTURE.md](ARCHITECTURE.md)。金标案例：`examples/firefighting.toc`。

## 模块

| 文件 | 职责 |
|------|------|
| `keywords.reb` | 中文关键词（UTF-8 二进制，源文件 ASCII 安全） |
| `dsl.reb` | `.toc` parse + 按树种校验 |
| `model.reb` | 实体 / 边 / AND / 冲突云五框还原 |
| `layout.reb` | 坐标与锚点 |
| `render.reb` | SVG |
| `main.reb` | CLI |

## 不做（v1）

CLR 审树、从 UDE 自动推理病根、拖拽画布、内置 PNG。
