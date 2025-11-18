import 'dart:convert';
import 'dart:typed_data';
import 'package:mdict_flutter/src/ripemd128.dart';
import 'package:test/test.dart';

String hex(Uint8List b) => b.map((e) => e.toRadixString(16).padLeft(2, '0')).join();

void main() {
  test('ripemd128 empty', () {
    final h = ripemd128Bytes(Uint8List(0));
    expect(hex(h), 'cdf26213a150dc3ecb610f18f6b38b46');
  });
  test('ripemd128 a', () {
    final h = ripemd128Bytes(Uint8List.fromList(utf8.encode('a')));
    expect(hex(h), '86be7afa339d0fc7cfc785e72f578d33');
  });
  test('ripemd128 abc', () {
    final h = ripemd128Bytes(Uint8List.fromList(utf8.encode('abc')));
    expect(hex(h), 'c14a12199c66e4ba84636b0f69144c77');
  });
  test('ripemd128 message digest', () {
    final h = ripemd128Bytes(Uint8List.fromList(utf8.encode('message digest')));
    expect(hex(h), '9e327b3d6e523062afc1132d7df9d1b8');
  });
  test('ripemd128 alphabet', () {
    final h = ripemd128Bytes(Uint8List.fromList(utf8.encode('abcdefghijklmnopqrstuvwxyz')));
    expect(hex(h), 'fd2aa607f71dc8f510714922b371834e');
  });
  test('ripemd128 alnum', () {
    final h = ripemd128Bytes(Uint8List.fromList(utf8.encode('ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789')));
    expect(hex(h), 'd1e959eb179c911faea4624c60c5c702');
  });
}