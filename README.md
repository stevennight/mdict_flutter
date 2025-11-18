# mdict_flutter

MDX/MDD 解析库（Dart/Flutter），基于 mdict-cpp 原理的复刻实现。支持：
- 精确查询词条（MDX）
- 前缀匹配返回键列表（MDX/MDD）
- 资源定位与读取（MDD），支持 Base64/Hex 编码输出
- 懒加载与块级 LRU 缓存，低内存占用

## 安装
在 `pubspec.yaml` 中添加：
```yaml
dependencies:
  mdict_flutter: ^0.1.0
```
或通过本地路径 / Git 依赖方式引入。

## 使用
```dart
import 'package:mdict_flutter/mdict_flutter.dart';

final mdx = MdictReader('D:/dicts/xxx.mdx');
await mdx.open();
final def = await mdx.lookup('朝');
final list = await mdx.prefixSearch('朝', limit: 50);
await mdx.close();

final mdd = MdictReader('D:/dicts/xxx.mdd');
await mdd.open();
final b64 = await mdd.locate('audio/xxx.mp3');
await mdd.close();
```

## 平台说明
- 使用 `dart:io` 随机文件读取：支持 Dart VM、Flutter 移动/桌面端，不支持 Flutter Web。
- 字典文件建议放在外部目录（如应用私有目录）；如从 assets 读取，需先拷贝到临时文件再打开。

## 许可证
BSD-3-Clause，详见 `LICENSE`。