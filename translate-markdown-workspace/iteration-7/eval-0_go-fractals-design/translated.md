# Go Fractals CLI - 设计

## 概述

一个生成ASCII艺术分形的命令行工具。支持两种分形类型，具有可配置的输出。

## 使用方法

```bash
# Sierpinski三角形
fractals sierpinski --size 32 --depth 5

# Mandelbrot集合
fractals mandelbrot --width 80 --height 24 --iterations 100

# 自定义字符
fractals sierpinski --size 16 --char '#'

# 帮助
fractals --help
fractals sierpinski --help
```

## 命令

### `sierpinski`

使用递归细分生成Sierpinski三角形。

标志：
- `--size` (默认值: 32) - 三角形底边的宽度（字符数）
- `--depth` (默认值: 5) - 递归深度
- `--char` (默认值: '*') - 用于填充点的字符

输出：三角形打印到标准输出，每行一行。

### `mandelbrot`

将Mandelbrot集合渲染为ASCII艺术。将迭代次数映射到字符。

标志：
- `--width` (默认值: 80) - 输出宽度（字符数）
- `--height` (默认值: 24) - 输出高度（字符数）
- `--iterations` (默认值: 100) - 逃逸计算的最大迭代次数
- `--char` (默认值: gradient) - 单个字符，或省略以使用渐变 " .:-=+*#%@"

输出：矩形打印到标准输出。

## 架构

```
cmd/
  fractals/
    main.go           # 入口点，CLI设置
internal/
  sierpinski/
    sierpinski.go     # 算法
    sierpinski_test.go
  mandelbrot/
    mandelbrot.go     # 算法
    mandelbrot_test.go
  cli/
    root.go           # 根命令，帮助
    sierpinski.go     # Sierpinski子命令
    mandelbrot.go     # Mandelbrot子命令
```

## 依赖

- Go 1.21+
- `github.com/spf13/cobra` 用于CLI

## 验收标准

1. `fractals --help` 显示使用说明
2. `fractals sierpinski` 输出可识别的三角形
3. `fractals mandelbrot` 输出可识别的Mandelbrot集合
4. `--size`、`--width`、`--height`、`--depth`、`--iterations` 标志有效
5. `--char` 自定义输出字符
6. 无效输入产生清晰的错误消息
7. 所有测试通过
