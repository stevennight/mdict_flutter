import 'dart:convert';
import 'dart:typed_data';

String trimNulls(String s) {
  int i = s.length - 1;
  while (i >= 0 && s.codeUnitAt(i) == 0) {
    i--;
  }
  return s.substring(0, i + 1);
}

Uint8List hexToBytes(String hex) {
  final s = hex.length % 2 == 0 ? hex : '0$hex';
  final out = Uint8List(s.length ~/ 2);
  for (int i = 0; i < s.length; i += 2) {
    out[i >> 1] = int.parse(s.substring(i, i + 2), radix: 16);
  }
  return out;
}

String base64FromHex(String hex) {
  return base64Encode(hexToBytes(hex));
}