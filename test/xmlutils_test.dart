import 'package:mdict_flutter/mdict_flutter.dart';
import 'package:test/test.dart';

void main() {
  test('XML empty and invalid', () {
    expect(parseXmlHeader(''), isEmpty);
    expect(parseXmlHeader('a'), isEmpty);
    expect(parseXmlHeader('abc'), isEmpty);
    expect(parseXmlHeader('abc>'), isEmpty);
  });

  test('XML basic', () {
    final m = parseXmlHeader('version="1.0" encoding="UTF-8"/>');
    expect(m.length, 2);
    expect(m['version'], '1.0');
    expect(m['encoding'], 'UTF-8');
  });

  test('XML spaces', () {
    final m = parseXmlHeader('  version="1.0"  encoding="UTF-8"  />');
    expect(m.length, 2);
    expect(m['version'], '1.0');
    expect(m['encoding'], 'UTF-8');
  });

  test('XML multiple', () {
    final m = parseXmlHeader('version="1.0" encoding="UTF-8" standalone="yes" />');
    expect(m.length, 3);
    expect(m['version'], '1.0');
    expect(m['encoding'], 'UTF-8');
    expect(m['standalone'], 'yes');
  });

  test('XML special chars', () {
    final m = parseXmlHeader('version="1.0" encoding="UTF-8" description="Test & Special > Characters < " />');
    expect(m.length, 3);
    expect(m['version'], '1.0');
    expect(m['encoding'], 'UTF-8');
    expect(m['description'], 'Test & Special > Characters < ');
  });

  test('XML dictionary header parsing', () {
    final dicxml = '<Dictionary GeneratedByEngineVersion="2.0" RequiredEngineVersion="2.0" Format="Html" KeyCaseSensitive="No" StripKey="Yes" Encrypted="2" RegisterBy="EMail" Description="Oxford Advanced Learner\'s English-Chinese Dictionary Eighth edition Based on Langheping&apos;s version Modified by EarthWorm&lt;br/&gt;Headwords: 41969 &lt;br/&gt; Entries: 109473 &lt;br/&gt; Version: 3.0.0 &lt;br/&gt;Date: 2018.02.18 &lt;br/&gt; Last Modified By roamlog&lt;br/&gt;" Title="" Encoding="UTF-8" CreationDate="2018-2-18" Compact="Yes" Compat="Yes" Left2Right="Yes" DataSourceFormat="106" StyleSheet="a"/>';
    final headinfo = parseXmlHeader(dicxml);
    expect(headinfo['GeneratedByEngineVersion'], '2.0');
    expect(headinfo['RequiredEngineVersion'], '2.0');
    expect(headinfo['Format'], 'Html');
    expect(headinfo['KeyCaseSensitive'], 'No');
    expect(headinfo['StripKey'], 'Yes');
    expect(headinfo['Encrypted'], '2');
    expect(headinfo['RegisterBy'], 'EMail');
    expect(headinfo['Title'], '');
    expect(headinfo['Encoding'], 'UTF-8');
    expect(headinfo['CreationDate'], '2018-2-18');
    expect(headinfo['Compact'], 'Yes');
    expect(headinfo['Compat'], 'Yes');
    expect(headinfo['Left2Right'], 'Yes');
    expect(headinfo['DataSourceFormat'], '106');
    expect(headinfo['StyleSheet'], 'a');
    expect(headinfo.length, 16);
  });
}