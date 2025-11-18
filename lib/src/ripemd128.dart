import 'dart:typed_data';

int _rotl(int x, int s) => ((x << s) | (x >>> (32 - s))) & 0xffffffff;
int _f(int x, int y, int z) => (x ^ y ^ z);
int _g(int x, int y, int z) => ((x & y) | (~x & z));
int _h(int x, int y, int z) => ((x | ~y) ^ z);
int _i(int x, int y, int z) => ((x & z) | (y & ~z));

List<int> _padIso7816(Uint8List d) {
  final l = d.length;
  final p = ((l % 64) < 56 ? 56 : 120) - (l % 64);
  final out = Uint8List(l + p + 8);
  out.setRange(0, l, d);
  out[l] = 0x80;
  final bits = l * 8;
  final bd = ByteData(8);
  bd.setUint32(0, bits & 0xffffffff, Endian.little);
  bd.setUint32(4, 0, Endian.little);
  out.setRange(l + p, l + p + 8, bd.buffer.asUint8List());
  return out;
}

Uint8List ripemd128(Uint8List msg) {
  final m = Uint8List.fromList(_padIso7816(msg));
  var A = 0x67452301;
  var B = 0xefcdab89;
  var C = 0x98badcfe;
  var D = 0x10325476;
  final bd = ByteData.sublistView(m);

  for (int off = 0; off < m.length; off += 64) {
    final X = List<int>.generate(16, (i) => bd.getUint32(off + i * 4, Endian.little));
    // left lane
    var aa = A, bb = B, cc = C, dd = D;
    aa = _rotl((aa + _f(bb, cc, dd) + X[0]) & 0xffffffff, 11);
    dd = _rotl((dd + _f(aa, bb, cc) + X[1]) & 0xffffffff, 14);
    cc = _rotl((cc + _f(dd, aa, bb) + X[2]) & 0xffffffff, 15);
    bb = _rotl((bb + _f(cc, dd, aa) + X[3]) & 0xffffffff, 12);
    aa = _rotl((aa + _f(bb, cc, dd) + X[4]) & 0xffffffff, 5);
    dd = _rotl((dd + _f(aa, bb, cc) + X[5]) & 0xffffffff, 8);
    cc = _rotl((cc + _f(dd, aa, bb) + X[6]) & 0xffffffff, 7);
    bb = _rotl((bb + _f(cc, dd, aa) + X[7]) & 0xffffffff, 9);
    aa = _rotl((aa + _f(bb, cc, dd) + X[8]) & 0xffffffff, 11);
    dd = _rotl((dd + _f(aa, bb, cc) + X[9]) & 0xffffffff, 13);
    cc = _rotl((cc + _f(dd, aa, bb) + X[10]) & 0xffffffff, 14);
    bb = _rotl((bb + _f(cc, dd, aa) + X[11]) & 0xffffffff, 15);
    aa = _rotl((aa + _f(bb, cc, dd) + X[12]) & 0xffffffff, 6);
    dd = _rotl((dd + _f(aa, bb, cc) + X[13]) & 0xffffffff, 7);
    cc = _rotl((cc + _f(dd, aa, bb) + X[14]) & 0xffffffff, 9);
    bb = _rotl((bb + _f(cc, dd, aa) + X[15]) & 0xffffffff, 8);

    aa = _rotl((aa + _g(bb, cc, dd) + X[7] + 0x5a827999) & 0xffffffff, 7);
    dd = _rotl((dd + _g(aa, bb, cc) + X[4] + 0x5a827999) & 0xffffffff, 6);
    cc = _rotl((cc + _g(dd, aa, bb) + X[13] + 0x5a827999) & 0xffffffff, 8);
    bb = _rotl((bb + _g(cc, dd, aa) + X[1] + 0x5a827999) & 0xffffffff, 13);
    aa = _rotl((aa + _g(bb, cc, dd) + X[10] + 0x5a827999) & 0xffffffff, 11);
    dd = _rotl((dd + _g(aa, bb, cc) + X[6] + 0x5a827999) & 0xffffffff, 9);
    cc = _rotl((cc + _g(dd, aa, bb) + X[15] + 0x5a827999) & 0xffffffff, 7);
    bb = _rotl((bb + _g(cc, dd, aa) + X[3] + 0x5a827999) & 0xffffffff, 15);
    aa = _rotl((aa + _g(bb, cc, dd) + X[12] + 0x5a827999) & 0xffffffff, 7);
    dd = _rotl((dd + _g(aa, bb, cc) + X[0] + 0x5a827999) & 0xffffffff, 12);
    cc = _rotl((cc + _g(dd, aa, bb) + X[9] + 0x5a827999) & 0xffffffff, 15);
    bb = _rotl((bb + _g(cc, dd, aa) + X[5] + 0x5a827999) & 0xffffffff, 9);
    aa = _rotl((aa + _g(bb, cc, dd) + X[2] + 0x5a827999) & 0xffffffff, 11);
    dd = _rotl((dd + _g(aa, bb, cc) + X[14] + 0x5a827999) & 0xffffffff, 7);
    cc = _rotl((cc + _g(dd, aa, bb) + X[11] + 0x5a827999) & 0xffffffff, 13);
    bb = _rotl((bb + _g(cc, dd, aa) + X[8] + 0x5a827999) & 0xffffffff, 12);

    aa = _rotl((aa + _h(bb, cc, dd) + X[3] + 0x6ed9eba1) & 0xffffffff, 11);
    dd = _rotl((dd + _h(aa, bb, cc) + X[10] + 0x6ed9eba1) & 0xffffffff, 13);
    cc = _rotl((cc + _h(dd, aa, bb) + X[14] + 0x6ed9eba1) & 0xffffffff, 6);
    bb = _rotl((bb + _h(cc, dd, aa) + X[4] + 0x6ed9eba1) & 0xffffffff, 7);
    aa = _rotl((aa + _h(bb, cc, dd) + X[9] + 0x6ed9eba1) & 0xffffffff, 14);
    dd = _rotl((dd + _h(aa, bb, cc) + X[15] + 0x6ed9eba1) & 0xffffffff, 9);
    cc = _rotl((cc + _h(dd, aa, bb) + X[8] + 0x6ed9eba1) & 0xffffffff, 13);
    bb = _rotl((bb + _h(cc, dd, aa) + X[1] + 0x6ed9eba1) & 0xffffffff, 15);
    aa = _rotl((aa + _h(bb, cc, dd) + X[2] + 0x6ed9eba1) & 0xffffffff, 14);
    dd = _rotl((dd + _h(aa, bb, cc) + X[7] + 0x6ed9eba1) & 0xffffffff, 8);
    cc = _rotl((cc + _h(dd, aa, bb) + X[0] + 0x6ed9eba1) & 0xffffffff, 13);
    bb = _rotl((bb + _h(cc, dd, aa) + X[6] + 0x6ed9eba1) & 0xffffffff, 6);
    aa = _rotl((aa + _h(bb, cc, dd) + X[13] + 0x6ed9eba1) & 0xffffffff, 5);
    dd = _rotl((dd + _h(aa, bb, cc) + X[11] + 0x6ed9eba1) & 0xffffffff, 12);
    cc = _rotl((cc + _h(dd, aa, bb) + X[5] + 0x6ed9eba1) & 0xffffffff, 7);
    bb = _rotl((bb + _h(cc, dd, aa) + X[12] + 0x6ed9eba1) & 0xffffffff, 5);

    aa = _rotl((aa + _i(bb, cc, dd) + X[1] + 0x8f1bbcdc) & 0xffffffff, 11);
    dd = _rotl((dd + _i(aa, bb, cc) + X[9] + 0x8f1bbcdc) & 0xffffffff, 12);
    cc = _rotl((cc + _i(dd, aa, bb) + X[11] + 0x8f1bbcdc) & 0xffffffff, 14);
    bb = _rotl((bb + _i(cc, dd, aa) + X[10] + 0x8f1bbcdc) & 0xffffffff, 15);
    aa = _rotl((aa + _i(bb, cc, dd) + X[0] + 0x8f1bbcdc) & 0xffffffff, 14);
    dd = _rotl((dd + _i(aa, bb, cc) + X[8] + 0x8f1bbcdc) & 0xffffffff, 15);
    cc = _rotl((cc + _i(dd, aa, bb) + X[12] + 0x8f1bbcdc) & 0xffffffff, 9);
    bb = _rotl((bb + _i(cc, dd, aa) + X[4] + 0x8f1bbcdc) & 0xffffffff, 8);
    aa = _rotl((aa + _i(bb, cc, dd) + X[13] + 0x8f1bbcdc) & 0xffffffff, 9);
    dd = _rotl((dd + _i(aa, bb, cc) + X[3] + 0x8f1bbcdc) & 0xffffffff, 14);
    cc = _rotl((cc + _i(dd, aa, bb) + X[7] + 0x8f1bbcdc) & 0xffffffff, 5);
    bb = _rotl((bb + _i(cc, dd, aa) + X[15] + 0x8f1bbcdc) & 0xffffffff, 6);
    aa = _rotl((aa + _i(bb, cc, dd) + X[14] + 0x8f1bbcdc) & 0xffffffff, 8);
    dd = _rotl((dd + _i(aa, bb, cc) + X[5] + 0x8f1bbcdc) & 0xffffffff, 6);
    cc = _rotl((cc + _i(dd, aa, bb) + X[6] + 0x8f1bbcdc) & 0xffffffff, 5);
    bb = _rotl((bb + _i(cc, dd, aa) + X[2] + 0x8f1bbcdc) & 0xffffffff, 12);

    // right lane
    var aaa = A, bbb = B, ccc = C, ddd = D;
    aaa = _rotl((aaa + _i(bbb, ccc, ddd) + X[5] + 0x50a28be6) & 0xffffffff, 8);
    ddd = _rotl((ddd + _i(aaa, bbb, ccc) + X[14] + 0x50a28be6) & 0xffffffff, 9);
    ccc = _rotl((ccc + _i(ddd, aaa, bbb) + X[7] + 0x50a28be6) & 0xffffffff, 9);
    bbb = _rotl((bbb + _i(ccc, ddd, aaa) + X[0] + 0x50a28be6) & 0xffffffff, 11);
    aaa = _rotl((aaa + _i(bbb, ccc, ddd) + X[9] + 0x50a28be6) & 0xffffffff, 13);
    ddd = _rotl((ddd + _i(aaa, bbb, ccc) + X[2] + 0x50a28be6) & 0xffffffff, 15);
    ccc = _rotl((ccc + _i(ddd, aaa, bbb) + X[11] + 0x50a28be6) & 0xffffffff, 15);
    bbb = _rotl((bbb + _i(ccc, ddd, aaa) + X[4] + 0x50a28be6) & 0xffffffff, 5);
    aaa = _rotl((aaa + _i(bbb, ccc, ddd) + X[13] + 0x50a28be6) & 0xffffffff, 7);
    ddd = _rotl((ddd + _i(aaa, bbb, ccc) + X[6] + 0x50a28be6) & 0xffffffff, 7);
    ccc = _rotl((ccc + _i(ddd, aaa, bbb) + X[15] + 0x50a28be6) & 0xffffffff, 8);
    bbb = _rotl((bbb + _i(ccc, ddd, aaa) + X[8] + 0x50a28be6) & 0xffffffff, 11);
    aaa = _rotl((aaa + _i(bbb, ccc, ddd) + X[1] + 0x50a28be6) & 0xffffffff, 14);
    ddd = _rotl((ddd + _i(aaa, bbb, ccc) + X[10] + 0x50a28be6) & 0xffffffff, 14);
    ccc = _rotl((ccc + _i(ddd, aaa, bbb) + X[3] + 0x50a28be6) & 0xffffffff, 12);
    bbb = _rotl((bbb + _i(ccc, ddd, aaa) + X[12] + 0x50a28be6) & 0xffffffff, 6);

    aaa = _rotl((aaa + _h(bbb, ccc, ddd) + X[6] + 0x5c4dd124) & 0xffffffff, 9);
    ddd = _rotl((ddd + _h(aaa, bbb, ccc) + X[11] + 0x5c4dd124) & 0xffffffff, 13);
    ccc = _rotl((ccc + _h(ddd, aaa, bbb) + X[3] + 0x5c4dd124) & 0xffffffff, 15);
    bbb = _rotl((bbb + _h(ccc, ddd, aaa) + X[7] + 0x5c4dd124) & 0xffffffff, 7);
    aaa = _rotl((aaa + _h(bbb, ccc, ddd) + X[0] + 0x5c4dd124) & 0xffffffff, 12);
    ddd = _rotl((ddd + _h(aaa, bbb, ccc) + X[13] + 0x5c4dd124) & 0xffffffff, 8);
    ccc = _rotl((ccc + _h(ddd, aaa, bbb) + X[5] + 0x5c4dd124) & 0xffffffff, 9);
    bbb = _rotl((bbb + _h(ccc, ddd, aaa) + X[10] + 0x5c4dd124) & 0xffffffff, 11);
    aaa = _rotl((aaa + _h(bbb, ccc, ddd) + X[14] + 0x5c4dd124) & 0xffffffff, 7);
    ddd = _rotl((ddd + _h(aaa, bbb, ccc) + X[15] + 0x5c4dd124) & 0xffffffff, 7);
    ccc = _rotl((ccc + _h(ddd, aaa, bbb) + X[8] + 0x5c4dd124) & 0xffffffff, 12);
    bbb = _rotl((bbb + _h(ccc, ddd, aaa) + X[12] + 0x5c4dd124) & 0xffffffff, 7);
    aaa = _rotl((aaa + _h(bbb, ccc, ddd) + X[4] + 0x5c4dd124) & 0xffffffff, 6);
    ddd = _rotl((ddd + _h(aaa, bbb, ccc) + X[9] + 0x5c4dd124) & 0xffffffff, 15);
    ccc = _rotl((ccc + _h(ddd, aaa, bbb) + X[1] + 0x5c4dd124) & 0xffffffff, 13);
    bbb = _rotl((bbb + _h(ccc, ddd, aaa) + X[2] + 0x5c4dd124) & 0xffffffff, 11);

    aaa = _rotl((aaa + _g(bbb, ccc, ddd) + X[15] + 0x6d703ef3) & 0xffffffff, 9);
    ddd = _rotl((ddd + _g(aaa, bbb, ccc) + X[5] + 0x6d703ef3) & 0xffffffff, 7);
    ccc = _rotl((ccc + _g(ddd, aaa, bbb) + X[1] + 0x6d703ef3) & 0xffffffff, 15);
    bbb = _rotl((bbb + _g(ccc, ddd, aaa) + X[3] + 0x6d703ef3) & 0xffffffff, 11);
    aaa = _rotl((aaa + _g(bbb, ccc, ddd) + X[7] + 0x6d703ef3) & 0xffffffff, 8);
    ddd = _rotl((ddd + _g(aaa, bbb, ccc) + X[14] + 0x6d703ef3) & 0xffffffff, 6);
    ccc = _rotl((ccc + _g(ddd, aaa, bbb) + X[6] + 0x6d703ef3) & 0xffffffff, 6);
    bbb = _rotl((bbb + _g(ccc, ddd, aaa) + X[9] + 0x6d703ef3) & 0xffffffff, 14);
    aaa = _rotl((aaa + _g(bbb, ccc, ddd) + X[11] + 0x6d703ef3) & 0xffffffff, 12);
    ddd = _rotl((ddd + _g(aaa, bbb, ccc) + X[8] + 0x6d703ef3) & 0xffffffff, 13);
    ccc = _rotl((ccc + _g(ddd, aaa, bbb) + X[12] + 0x6d703ef3) & 0xffffffff, 5);
    bbb = _rotl((bbb + _g(ccc, ddd, aaa) + X[2] + 0x6d703ef3) & 0xffffffff, 14);
    aaa = _rotl((aaa + _g(bbb, ccc, ddd) + X[10] + 0x6d703ef3) & 0xffffffff, 13);
    ddd = _rotl((ddd + _g(aaa, bbb, ccc) + X[0] + 0x6d703ef3) & 0xffffffff, 13);
    ccc = _rotl((ccc + _g(ddd, aaa, bbb) + X[4] + 0x6d703ef3) & 0xffffffff, 7);
    bbb = _rotl((bbb + _g(ccc, ddd, aaa) + X[13] + 0x6d703ef3) & 0xffffffff, 5);

    aaa = _rotl((aaa + _f(bbb, ccc, ddd) + X[8]) & 0xffffffff, 15);
    ddd = _rotl((ddd + _f(aaa, bbb, ccc) + X[6]) & 0xffffffff, 5);
    ccc = _rotl((ccc + _f(ddd, aaa, bbb) + X[4]) & 0xffffffff, 8);
    bbb = _rotl((bbb + _f(ccc, ddd, aaa) + X[1]) & 0xffffffff, 11);
    aaa = _rotl((aaa + _f(bbb, ccc, ddd) + X[3]) & 0xffffffff, 14);
    ddd = _rotl((ddd + _f(aaa, bbb, ccc) + X[11]) & 0xffffffff, 14);
    ccc = _rotl((ccc + _f(ddd, aaa, bbb) + X[15]) & 0xffffffff, 6);
    bbb = _rotl((bbb + _f(ccc, ddd, aaa) + X[0]) & 0xffffffff, 14);
    aaa = _rotl((aaa + _f(bbb, ccc, ddd) + X[5]) & 0xffffffff, 6);
    ddd = _rotl((ddd + _f(aaa, bbb, ccc) + X[12]) & 0xffffffff, 9);
    ccc = _rotl((ccc + _f(ddd, aaa, bbb) + X[2]) & 0xffffffff, 12);
    bbb = _rotl((bbb + _f(ccc, ddd, aaa) + X[13]) & 0xffffffff, 9);
    aaa = _rotl((aaa + _f(bbb, ccc, ddd) + X[9]) & 0xffffffff, 12);
    ddd = _rotl((ddd + _f(aaa, bbb, ccc) + X[7]) & 0xffffffff, 5);
    ccc = _rotl((ccc + _f(ddd, aaa, bbb) + X[10]) & 0xffffffff, 15);
    bbb = _rotl((bbb + _f(ccc, ddd, aaa) + X[14]) & 0xffffffff, 8);

    // combine
    ddd = (ddd + cc + B) & 0xffffffff;
    B = (C + dd + aaa) & 0xffffffff;
    C = (D + aa + bbb) & 0xffffffff;
    D = (A + bb + ccc) & 0xffffffff;
    A = ddd;
  }

  final out = Uint8List(16);
  final bdOut = ByteData(16);
  bdOut.setUint32(0, A, Endian.little);
  bdOut.setUint32(4, B, Endian.little);
  bdOut.setUint32(8, C, Endian.little);
  bdOut.setUint32(12, D, Endian.little);
  out.setAll(0, bdOut.buffer.asUint8List());
  return out;
}

Uint8List ripemd128Bytes(Uint8List message) {
  return ripemd128(message);
}