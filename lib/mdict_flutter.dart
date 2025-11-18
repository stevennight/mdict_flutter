import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'src/binary.dart';
import 'src/codec.dart';
import 'src/ripemd128.dart';

enum OutputEncoding { hex, base64 }

class KeyBlockInfo {
  final String firstKey;
  final String lastKey;
  final int startOffset;
  final int compSize;
  final int decompSize;
  final int compAcc;
  final int decompAcc;
  KeyBlockInfo(this.firstKey, this.lastKey, this.startOffset, this.compSize, this.decompSize, this.compAcc, this.decompAcc);
}

class KeyListItem {
  final int recordStart;
  final String key;
  KeyListItem(this.recordStart, this.key);
}

class RecordHeaderItem {
  final int idx;
  final int compSize;
  final int decompSize;
  final int compAcc;
  final int decompAcc;
  RecordHeaderItem(this.idx, this.compSize, this.decompSize, this.compAcc, this.decompAcc);
}

class MdictReader {
  final String path;
  RandomAccessFile? _raf;
  String filetype = "MDX";
  double version = 0.0;
  int numberWidth = 8;
  int encoding = 0;
  int encrypt = 0;

  int headerBytesSize = 0;
  int keyBlockStartOffset = 0;
  int keyBlockInfoStartOffset = 0;
  int keyBlockInfoDecompressSize = 0;
  int keyBlockInfoSize = 0;
  int keyBlockSize = 0;
  int keyBlockCompressedStartOffset = 0;
  int keyBlockBodyStart = 0;

  int keyBlockNum = 0;
  int entriesNum = 0;

  int recordBlockInfoOffset = 0;
  int recordBlockInfoSize = 0;
  int recordBlockHeaderSize = 0;
  int recordBlockSize = 0;
  int recordBlockNumber = 0;
  int recordBlockEntriesNumber = 0;
  int recordBlockOffset = 0;

  final List<KeyBlockInfo> keyBlockInfoList = [];
  final List<RecordHeaderItem> recordHeader = [];
  final Map<int, List<KeyListItem>> _blockCache = {};
  final List<int> _cacheOrder = [];
  final int _cacheLimit = 8;

  MdictReader(this.path) {
    if (path.toLowerCase().endsWith('.mdd')) filetype = 'MDD';
  }

  Future<void> open() async {
    final f = File(path);
    if (!await f.exists()) {
      throw Exception('File not found: $path');
    }
    _raf = await f.open();
    _readHeader();
    _readKeyBlockHeader();
    _readKeyBlockInfo();
    _readRecordBlockHeader();
    _buildKeyList();
  }

  Future<void> close() async {
    await _raf?.close();
    _raf = null;
  }

  Uint8List _read(int offset, int len) {
    final raf = _raf!;
    raf.setPositionSync(offset);
    return raf.readSync(len);
  }

  void _readHeader() {
    final sizeBuf = _read(0, 4);
    headerBytesSize = beU32(sizeBuf);
    keyBlockStartOffset = headerBytesSize + 8;

    final headBuf = _read(4, headerBytesSize);
    final headerText = beUtf16LeString(headBuf, 0, headerBytesSize);

    final map = parseXmlHeader(headerText);

    final enc = map['Encrypted'] ?? 'No';
    if (enc == 'No') encrypt = 0; else if (enc == 'Yes' || enc.startsWith('1')) encrypt = 1; else if (enc.startsWith('2')) encrypt = 2; else encrypt = 0;

    final verStr = map['GeneratedByEngineVersion'] ?? '1.0';
    version = double.tryParse(verStr) ?? 0.0;
    if (version >= 2.0) {
      numberWidth = 8;
      keyBlockInfoStartOffset = keyBlockStartOffset + 40 + 4;
    } else {
      numberWidth = 4;
      keyBlockInfoStartOffset = keyBlockStartOffset + 16;
    }

    final encStr = map['Encoding'] ?? 'UTF-8';
    if (encStr == 'utf16' || encStr == 'utf-16') encoding = 1; else encoding = 0;
    if (filetype == 'MDD') encoding = 1;
  }

  void _readKeyBlockHeader() {
    final len = version >= 2.0 ? 8 * 5 : 4 * 4;
    final buf = _read(keyBlockStartOffset, len);
    int o = 0;
    if (version >= 2.0) {
      keyBlockNum = beU64(buf, o); o += 8;
      entriesNum = beU64(buf, o); o += 8;
      keyBlockInfoDecompressSize = beU64(buf, o); o += 8;
      keyBlockInfoSize = beU64(buf, o); o += 8;
      keyBlockSize = beU64(buf, o); o += 8;
    } else {
      keyBlockNum = beU32(buf, o); o += 4;
      entriesNum = beU32(buf, o); o += 4;
      keyBlockInfoSize = beU32(buf, o); o += 4;
      keyBlockSize = beU32(buf, o); o += 4;
    }
  }

  void _readKeyBlockInfo() {
    final cmp = _read(keyBlockInfoStartOffset, keyBlockInfoSize);
    if (version >= 2.0) {
      if (encrypt == 1) throw Exception('Record encryption not supported');
      Uint8List comp = cmp;
      if (encrypt == 2) {
        comp = _mdxDecrypt(comp);
      }
      final decomp = Uint8List.fromList(ZLibCodec().decode(comp.sublist(8)));
      int dataOffset = 0;
      int counter = 0;
      int previousStartOffset = 0;
      int byteWidth = 2;
      int textTerm = 1;
      int compAcc = 0;
      int decompAcc = 0;
      while (counter < keyBlockNum) {
        dataOffset += numberWidth;
        int firstKeySize = beU16(decomp, dataOffset); dataOffset += byteWidth;
        int stepGap = encoding == 1 ? (firstKeySize + textTerm) * 2 : (firstKeySize + textTerm);
        String firstKey;
        if (filetype == 'MDX') {
          firstKey = beUtf8(decomp, dataOffset, stepGap - textTerm);
        } else {
          firstKey = beUtf16LeString(decomp, dataOffset, stepGap - textTerm);
        }
        dataOffset += stepGap;
        int lastKeySize = beU16(decomp, dataOffset); dataOffset += byteWidth;
        stepGap = encoding == 1 ? (lastKeySize + textTerm) * 2 : (lastKeySize + textTerm);
        String lastKey;
        if (filetype == 'MDX') {
          lastKey = beUtf8(decomp, dataOffset, stepGap - textTerm);
        } else {
          lastKey = beUtf16LeString(decomp, dataOffset, stepGap - textTerm);
        }
        dataOffset += stepGap;
        final keyBlockCompSize = beU64(decomp, dataOffset); dataOffset += numberWidth;
        final keyBlockDecompSize = beU64(decomp, dataOffset); dataOffset += numberWidth;
        keyBlockInfoList.add(KeyBlockInfo(firstKey, lastKey, previousStartOffset, keyBlockCompSize, keyBlockDecompSize, compAcc, decompAcc));
        previousStartOffset += keyBlockCompSize;
        counter += 1;
        compAcc += keyBlockCompSize;
        decompAcc += keyBlockDecompSize;
      }
      keyBlockBodyStart = keyBlockInfoStartOffset + keyBlockInfoSize;
      keyBlockCompressedStartOffset = keyBlockBodyStart;
      recordBlockInfoOffset = keyBlockInfoStartOffset + keyBlockInfoSize + keyBlockSize;
    } else {
      throw Exception('Version <2.0 not implemented');
    }
  }

  void _readRecordBlockHeader() {
    recordBlockInfoSize = version >= 2.0 ? 4 * 8 : 4 * 4;
    final info = _read(recordBlockInfoOffset, recordBlockInfoSize);
    if (version >= 2.0) {
      int o = 0;
      recordBlockNumber = beU64(info, o); o += numberWidth;
      recordBlockEntriesNumber = beU64(info, o); o += numberWidth;
      recordBlockHeaderSize = beU64(info, o); o += numberWidth;
      recordBlockSize = beU64(info, o); o += numberWidth;
    }
    final headerBuf = _read(recordBlockInfoOffset + recordBlockInfoSize, recordBlockHeaderSize);
    int sizeCounter = 0;
    int compAccu = 0;
    int decompAccu = 0;
    for (int i = 0; i < recordBlockNumber; i++) {
      final compSize = beU64(headerBuf, sizeCounter); sizeCounter += numberWidth;
      final decompSize = beU64(headerBuf, sizeCounter); sizeCounter += numberWidth;
      recordHeader.add(RecordHeaderItem(i, compSize, decompSize, compAccu, decompAccu));
      compAccu += compSize;
      decompAccu += decompSize;
    }
    recordBlockOffset = recordBlockInfoOffset + recordBlockInfoSize + recordBlockHeaderSize;
  }

  List<KeyListItem> _decodeKeyBlockById(int blockId) {
    final info = keyBlockInfoList[blockId];
    final compSize = info.compSize;
    final decompSize = info.decompSize;
    final start = info.compAcc + keyBlockCompressedStartOffset;
    final buf = _read(start, compSize);
    final compType = buf[0] & 0xff;
    final checksum = beU32(buf, 4);
    Uint8List keyBlock;
    if (compType == 0) {
      keyBlock = buf.sublist(8);
    } else if (compType == 2) {
      keyBlock = Uint8List.fromList(ZLibCodec().decode(buf.sublist(8)));
      final adler = _adler32(keyBlock, decompSize);
      if (adler != checksum || keyBlock.length != decompSize) {
        throw Exception('Key block checksum mismatch');
      }
    } else {
      throw Exception('Unsupported key block compression');
    }
    return _splitKeyBlock(keyBlock, decompSize);
  }

  List<KeyListItem> decodeKeyBlockById(int blockId) {
    return _decodeKeyBlockById(blockId);
  }

  List<KeyListItem> _getBlockKeyList(int blockId) {
    if (_blockCache.containsKey(blockId)) return _blockCache[blockId]!;
    final t = _decodeKeyBlockById(blockId);
    _blockCache[blockId] = t;
    _cacheOrder.add(blockId);
    if (_cacheOrder.length > _cacheLimit) {
      final evictId = _cacheOrder.removeAt(0);
      _blockCache.remove(evictId);
    }
    return t;
  }

  int _findBlockIdForNormalizedKey(String w) {
    int start = 0, end = keyBlockInfoList.length - 1;
    while (start <= end) {
      final mid = (start + end) >> 1;
      final f = normalizeKey(keyBlockInfoList[mid].firstKey);
      final l = normalizeKey(keyBlockInfoList[mid].lastKey);
      if (w.compareTo(f) < 0) {
        end = mid - 1;
      } else if (w.compareTo(l) > 0) {
        start = mid + 1;
      } else {
        return mid;
      }
    }
    return -1;
  }

  List<KeyListItem> _splitKeyBlock(Uint8List keyBlock, int keyBlockLen) {
    int keyStartIdx = 0;
    int keyEndIdx = 0;
    final out = <KeyListItem>[];
    while (keyStartIdx < keyBlockLen) {
      int recordStart = version >= 2.0 ? beU64(keyBlock, keyStartIdx) : beU32(keyBlock, keyStartIdx);
      final width = encoding == 1 ? 2 : 1;
      int i = keyStartIdx + numberWidth;
      if (i >= keyBlockLen) throw Exception('key start idx > key block length');
      while (i < keyBlockLen) {
        if (encoding == 1) {
          if ((keyBlock[i] & 0x0f) == 0 && ((keyBlock[i] & 0xf0) >> 4) == 0 && (keyBlock[i + 1] & 0x0f) == 0 && (((keyBlock[i + 1] & 0xf0) >> 4) == 0)) {
            keyEndIdx = i;
            break;
          }
        } else {
          if (((keyBlock[i] & 0xf0) >> 4) == 0 && ((keyBlock[i] & 0x0f)) == 0) {
            keyEndIdx = i;
            break;
          }
        }
        i += width;
      }
      if (keyEndIdx >= keyBlockLen) keyEndIdx = keyBlockLen;
      String keyText;
      if (encoding == 1) {
        keyText = beUtf16LeString(keyBlock, keyStartIdx + numberWidth, keyEndIdx - keyStartIdx - numberWidth);
      } else {
        keyText = beUtf8(keyBlock, keyStartIdx + numberWidth, keyEndIdx - keyStartIdx - numberWidth);
      }
      out.add(KeyListItem(recordStart, keyText));
      keyStartIdx = keyEndIdx + width;
    }
    return out;
  }

  void _buildKeyList() {}


  Future<String?> lookup(String word) async {
    final w = normalizeKey(word);
    final bytes = _getRecordBytesForKey(w);
    if (bytes == null) return null;
    String s;
    if (filetype == 'MDX') {
      if (encoding == 1) {
        s = beUtf16LeString(bytes, 0, bytes.length);
      } else {
        s = utf8.decode(bytes);
      }
    } else {
      s = String.fromCharCodes(bytes);
    }
    return trimNulls(s);
  }

  int _lowerBoundBlockByLastKey(String w) {
    int s = 0, e = keyBlockInfoList.length - 1, ans = -1;
    while (s <= e) {
      final m = (s + e) >> 1;
      final l = normalizeKey(keyBlockInfoList[m].lastKey);
      if (l.compareTo(w) >= 0) { ans = m; e = m - 1; } else { s = m + 1; }
    }
    return ans;
  }

  Future<List<String>> prefixSearch(String prefix, {int limit = 50}) async {
    final p = normalizeKey(prefix);
    if (p.isEmpty) return [];
    final upper = '$p\uFFFF';
    final start = _lowerBoundBlockByLastKey(p);
    if (start < 0) return [];
    final out = <String>[];
    for (int b = start; b < keyBlockInfoList.length && out.length < limit; b++) {
      final info = keyBlockInfoList[b];
      final f = normalizeKey(info.firstKey);
      final l = normalizeKey(info.lastKey);
      if (f.compareTo(upper) > 0) break;
      if (l.compareTo(p) < 0) continue;
      final tlist = _getBlockKeyList(b);
      int s = 0, e = tlist.length - 1, idx = tlist.length;
      while (s <= e) {
        final m = (s + e) >> 1;
        final kw = normalizeKey(tlist[m].key);
        if (kw.compareTo(p) >= 0) { idx = m; e = m - 1; } else { s = m + 1; }
      }
      for (int i = idx; i < tlist.length && out.length < limit; i++) {
        final kw = normalizeKey(tlist[i].key);
        if (kw.compareTo(upper) >= 0) break;
        if (kw.startsWith(p)) out.add(tlist[i].key);
      }
    }
    return out;
  }

  Future<String?> locate(String key, {OutputEncoding encodingOut = OutputEncoding.base64}) async {
    final bytes = _getRecordBytesForKey(normalizeKey(key));
    if (bytes != null) {
      if (encodingOut == OutputEncoding.hex) {
        return bytes.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
      } else {
        return base64Encode(bytes);
      }
    }
    return null;
  }

  Uint8List? _getRecordBytesForKey(String normalizedKey) {
    final blockId = _findBlockIdForNormalizedKey(normalizedKey);
    if (blockId < 0) return null;
    final tlist = _getBlockKeyList(blockId);
    int s = 0, e = tlist.length - 1, idx = -1;
    while (s <= e) {
      final m = (s + e) >> 1;
      final kw = normalizeKey(tlist[m].key);
      final cmp = normalizedKey.compareTo(kw);
      if (cmp == 0) { idx = m; break; }
      if (cmp < 0) e = m - 1; else s = m + 1;
    }
    if (idx < 0) return null;
    final recordStart = tlist[idx].recordStart;
    final blockIdx = _reduceRecordBlockOffset(recordStart);
    final compSize = recordHeader[blockIdx].compSize;
    final uncompSize = recordHeader[blockIdx].decompSize;
    final compAccu = recordHeader[blockIdx].compAcc;
    final decompAccu = recordHeader[blockIdx].decompAcc;
    final prevEnd = blockIdx > 0 ? recordHeader[blockIdx - 1].decompAcc : 0;
    final prevUncomp = blockIdx > 0 ? recordHeader[blockIdx - 1].decompSize : 0;
    final cmpBuf = _read(recordBlockOffset + compAccu, compSize);
    if ((cmpBuf[0] & 0xff) != 2) return null;
    final uncmp = Uint8List.fromList(ZLibCodec().decode(cmpBuf.sublist(8)));
    int expectStart = recordStart - decompAccu;
    int expectEnd;
    if (idx < tlist.length - 1) {
      expectEnd = tlist[idx + 1].recordStart - tlist[idx].recordStart;
    } else {
      expectEnd = recordBlockSize - (prevEnd + prevUncomp);
    }
    final upbound = expectEnd < uncompSize ? expectEnd : uncompSize;
    return uncmp.sublist(expectStart, expectStart + upbound);
  }

  int _reduceRecordBlockOffset(int recordStart) {
    int start = 0, end = recordHeader.length - 1, ans = 0;
    while (start <= end) {
      final mid = (start + end) >> 1;
      final acc = recordHeader[mid].decompAcc;
      final size = recordHeader[mid].decompSize;
      if (recordStart < acc) {
        end = mid - 1;
      } else if (recordStart >= acc + size) {
        start = mid + 1;
      } else {
        ans = mid; break;
      }
    }
    return ans;
  }

  Uint8List _mdxDecrypt(Uint8List comp) {
    final keyBuf = Uint8List(8);
    keyBuf.setRange(0, 4, comp.sublist(4, 8));
    keyBuf[4] = 0x95;
    keyBuf[5] = 0x36;
    final key = ripemd128Bytes(keyBuf);
    final data = Uint8List.fromList(comp);
    int prev = 0x36;
    for (int i = 8; i < data.length; i++) {
      int t = (((data[i] >> 4) | (data[i] << 4)) & 0xff);
      t = t ^ prev ^ (i & 0xff) ^ key[i % 16];
      prev = data[i];
      data[i] = t & 0xff;
    }
    return data;
  }

  int _adler32(Uint8List data, int len) {
    const mod = 65521;
    int a = 1, b = 0;
    final n = len <= data.length ? len : data.length;
    for (int i = 0; i < n; i++) {
      a = (a + data[i]) % mod;
      b = (b + a) % mod;
    }
    return ((b << 16) | a) & 0xffffffff;
  }

}

Map<String, String> parseXmlHeader(String s) {
  final out = <String, String>{};
  final t = s.trim();
  final re = RegExp(r'(\w+)\s*=\s*"([\s\S]*?)"');
  for (final m in re.allMatches(t)) {
    out[m.group(1)!] = m.group(2)!;
  }
  return out;
}