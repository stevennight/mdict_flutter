import 'dart:typed_data';
import 'dart:convert';

int beU16(Uint8List b, [int o = 0]) {
  return (b[o] << 8) | b[o + 1];
}

int beU32(Uint8List b, [int o = 0]) {
  return (b[o] << 24) | (b[o + 1] << 16) | (b[o + 2] << 8) | b[o + 3];
}

int beU64(Uint8List b, [int o = 0]) {
  int hi = beU32(b, o);
  int lo = beU32(b, o + 4);
  return (hi << 32) | (lo & 0xffffffff);
}

String beUtf8(Uint8List b, int o, int len) {
  return utf8.decode(b.sublist(o, o + len));
}

String beUtf16LeString(Uint8List b, int o, int lenBytes) {
  final view = ByteData.sublistView(b, o, o + lenBytes);
  final units = <int>[];
  for (int i = 0; i + 1 < lenBytes; i += 2) {
    units.add(view.getUint16(i, Endian.little));
  }
  return String.fromCharCodes(units);
}

Uint8List slice(Uint8List b, int o, int len) {
  return Uint8List.fromList(b.sublist(o, o + len));
}

String normalizeKey(String s) {
  final r = s.trim().toLowerCase();
  final buf = StringBuffer();
  for (final c in r.runes) {
    if (!(c == 32 || c == 9 || c == 10 || c == 13) && c != 0x2c && c != 0x2e) {
      buf.writeCharCode(c);
    }
  }
  return buf.toString();
}