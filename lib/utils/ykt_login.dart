import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:encrypt/encrypt.dart' as encrypt_pkg;

typedef YKTAuthResolver = Future<String> Function(String ssoCookie);

class OfflineCodeParams {
  final String offlineUserdata;
  final String userhashkey;
  final String offlineEffectiveTime;
  final String version;

  const OfflineCodeParams({
    required this.offlineUserdata,
    required this.userhashkey,
    required this.offlineEffectiveTime,
    required this.version,
  });

  factory OfflineCodeParams.fromJson(Map<String, dynamic> json) {
    return OfflineCodeParams(
      offlineUserdata: (json['offline_userdata'] ?? '').toString(),
      userhashkey: (json['userhashkey'] ?? '').toString(),
      offlineEffectiveTime: (json['offline_effective_time'] ?? '0').toString(),
      version: (json['version'] ?? '3').toString(),
    );
  }
}

class PayInfo {
  final String account;
  final String payacc;
  final String paytype;
  final String voucher;

  const PayInfo({
    required this.account,
    required this.payacc,
    required this.paytype,
    required this.voucher,
  });

  factory PayInfo.fromJson(Map<String, dynamic> json) {
    return PayInfo(
      account: (json['account'] ?? '').toString(),
      payacc: (json['payacc'] ?? '').toString(),
      paytype: (json['paytype'] ?? '').toString(),
      voucher: (json['voucher'] ?? '').toString(),
    );
  }
}

class FrontInfo {
  final String privateKey;
  final String offlineCode;

  const FrontInfo({
    required this.privateKey,
    required this.offlineCode,
  });

  factory FrontInfo.fromJson(Map<String, dynamic> json) {
    return FrontInfo(
      privateKey: (json['privateKey'] ?? '').toString(),
      offlineCode: (json['offlineCode'] ?? '0').toString(),
    );
  }
}

class YKTPayCodeResult {
  final String synjonesAuth;
  final String userInfoRaw;
  final PayInfo payInfo;
  final String payCode;

  const YKTPayCodeResult({
    required this.synjonesAuth,
    required this.userInfoRaw,
    required this.payInfo,
    required this.payCode,
  });
}

class YKTException implements Exception {
  final String message;

  const YKTException(this.message);

  @override
  String toString() => message;
}

class YKTLogin {
  static const Map<String, String> _urls = {
    'getUserInfo': 'https://xcx.fzu.edu.cn/berserker-base/user?synAccessSource=h5',
    'getCodebarPayInfo': 'https://xcx.fzu.edu.cn/berserker-app/ykt/tsm/codebarPayinfo?synAccessSource=h5',
    'getBatchBarcode': 'https://xcx.fzu.edu.cn/berserker-app/ykt/tsm/batchGetBarCodeGet',
    'getOfflinePayInfo': 'https://xcx.fzu.edu.cn/berserker-app/ykt/tsm/offlienPar',
    'getFrontInfo': 'https://xcx.fzu.edu.cn/berserker-app/frontInfo?synAccessSource=h5',
    'referer': 'https://xcx.fzu.edu.cn/plat/pay?appId=16&nodeId=15',
  };

  static const String _fallbackPrivateKey = '''-----BEGIN PRIVATE KEY-----
MIICdgIBADANBgkqhkiG9w0BAQEFAASCAmAwggJcAgEAAoGBANU64/H2n5i6i2L9
xs7TQ2nC7Oe8S/LkyiumV5YWoOjcbDzJ8Nm9JSBFSt12Y3mDmVT2guP763akpL4P
U9rz30Vt9uL8EnjzGRvhwvIQq1HfI9z8c67GJbL1wOxLFknnXxPPicn7B5/nTN66
zobrhhgbUDUTO4eBZCPryDf9/fJNAgMBAAECgYEAtBN2/BpOsFoiayhtJLBQR1pC
XnasIWZMws5JO8zCecXldvUIfap6VyWN0zgvTCjybkl9QvK26UykgIpLRCcez2Yk
4znIWS4AJb2TvcpbEIRt8mMICGtp9MNe54GieQ9dTQdKY2J4e+zJKHJUgut03M6C
ME8SYss0uu1RksiamGECQQDsm91KWfQEi5bOJJ5ippAYsGyQkByATzRqbGPXPCwZ
1HRBrDMQBjE4u89EwKpb50H6HYbySB/Pqi6VI20Y6ltlAkEA5rSH02LaY3GIb5ih
oD2D7oqbwt3x4bJvJRjq0oFr/tPkTrV9NyrdUcDzSSpJs4TXNwU8oV2+J0cQTwhd
7gBwyQJARmEec81J/kgfNXZC/okY958Sy/Vx5OCqcLWJBS7K12wQoLA+CBgvb/a9
cm/0vJ2PTHyX9V1qyPSQIqCFBRJA2QJAValGnZig2je3nygfKy5sJFBXEX3zaAgm
+LFNz6e6f74RkaAVxDwoPUjVjJ8lCoESoB1Tq97w0giy54WFyu9i8QJAQY/ozmFh
VLYEVJjk/c+KorA3j3Wt94x4SnIcq00Gj8bh8dVGydfPY5lVNLOAjMwofAETTrHV
OxZLn+h28MX9Mg==
-----END PRIVATE KEY-----''';

  final Dio _dio;
  final YKTAuthResolver? _authResolver;

  YKTLogin({Dio? dio, YKTAuthResolver? authResolver})
      : _dio = dio ?? Dio(),
        _authResolver = authResolver;

  Future<YKTPayCodeResult> getPayCode({
    required String ssoCookie,
    String? cachedAuth,
  }) async {
    final synjonesAuth = await getAuth(ssoCookie, cachedAuth: cachedAuth);
    final userInfoRaw = await getUserInfo(synjonesAuth);
    final payInfo = await getCodebarPayInfo(synjonesAuth);

    final parts = await Future.wait<dynamic>([
      getBatchBarcode(synjonesAuth, payInfo.account, payInfo.payacc, payInfo.paytype),
      getOfflineParams(synjonesAuth, payInfo.payacc, payInfo.paytype, payInfo.voucher),
      getFrontInfo(),
    ]);

    final barcode = parts[0] as String;
    final offlineParams = parts[1] as OfflineCodeParams;
    final frontInfo = parts[2] as FrontInfo;

    final payCode = _generateQRCodeDataString(barcode, payInfo.payacc, offlineParams, frontInfo);

    return YKTPayCodeResult(
      synjonesAuth: synjonesAuth,
      userInfoRaw: userInfoRaw,
      payInfo: payInfo,
      payCode: payCode,
    );
  }

  Future<bool> isAuthValid(String synjonesAuth) async {
    try {
      await _get(
        url: _urls['getUserInfo']!,
        headers: {'Synjones-Auth': 'bearer $synjonesAuth'},
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String> getAuth(String ssoCookie, {String? cachedAuth}) async {
    if (cachedAuth != null && cachedAuth.isNotEmpty && await isAuthValid(cachedAuth)) {
      return cachedAuth;
    }

    if (ssoCookie.isEmpty) {
      throw const YKTException('未登录SSO，无法获取synjones-auth');
    }

    if (_authResolver == null) {
      throw const YKTException('缺少YKT鉴权实现: 请在YKTLogin构造时传入authResolver');
    }

    final auth = await _authResolver.call(ssoCookie);
    if (auth.isEmpty) {
      throw const YKTException('获取synjones-auth失败');
    }
    return auth;
  }

  Future<String> getUserInfo(String synjonesAuth) async {
    if (synjonesAuth.isEmpty) {
      throw const YKTException('synjonesAuth不能为空');
    }

    final userInfoResp = await _get(
      url: _urls['getUserInfo']!,
      headers: {'Synjones-Auth': 'bearer $synjonesAuth'},
    );

    final data = userInfoResp['data'];
    return jsonEncode(data);
  }

  Future<PayInfo> getCodebarPayInfo(String synjonesAuth) async {
    if (synjonesAuth.isEmpty) {
      throw const YKTException('synjonesAuth不能为空');
    }

    final codebarResp = await _get(
      url: _urls['getCodebarPayInfo']!,
      headers: {
        'Referer': _urls['referer']!,
        'Synaccesssource': 'h5',
        'Synjones-Auth': 'bearer $synjonesAuth',
      },
    );

    final list = codebarResp['data'];
    if (list is! List || list.isEmpty) {
      throw const YKTException('获取支付信息失败: data为空');
    }

    final payInfo = PayInfo.fromJson((list.first as Map).cast<String, dynamic>());
    if (payInfo.account.isEmpty || payInfo.payacc.isEmpty || payInfo.paytype.isEmpty || payInfo.voucher.isEmpty) {
      throw const YKTException('获取支付信息失败: 字段不完整');
    }

    return payInfo;
  }

  Future<String> getBatchBarcode(String synjonesAuth, String account, String payacc, String paytype) async {
    final barcodeUrl =
        '${_urls['getBatchBarcode']}?account=${Uri.encodeQueryComponent(account)}&payacc=${Uri.encodeQueryComponent(payacc)}&paytype=${Uri.encodeQueryComponent(paytype)}&synAccessSource=h5';

    final barcodeResp = await _get(
      url: barcodeUrl,
      headers: {
        'Referer': _urls['referer']!,
        'Synaccesssource': 'h5',
        'Synjones-Auth': 'bearer $synjonesAuth',
      },
    );

    final barcodeList = (barcodeResp['data'] as Map?)?['barcode'];
    if (barcodeList is! List || barcodeList.isEmpty) {
      throw const YKTException('获取条码失败: barcode为空');
    }
    final barcode = (barcodeList.first ?? '').toString();
    if (barcode.length != 20) {
      throw YKTException('获取条码失败: 长度异常(${barcode.length})');
    }
    return barcode;
  }

  Future<OfflineCodeParams> getOfflineParams(
    String synjonesAuth,
    String payacc,
    String paytype,
    String voucher,
  ) async {
    if (synjonesAuth.isEmpty) {
      throw const YKTException('synjonesAuth不能为空');
    }

    final offlineUrl =
        '${_urls['getOfflinePayInfo']}?payacc=${Uri.encodeQueryComponent(payacc)}&paytype=${Uri.encodeQueryComponent(paytype)}&voucher=${Uri.encodeQueryComponent(voucher)}&synAccessSource=h5';

    final offlineResp = await _get(
      url: offlineUrl,
      headers: {
        'Referer': _urls['referer']!,
        'Synaccesssource': 'h5',
        'Synjones-Auth': 'bearer $synjonesAuth',
      },
    );

    return OfflineCodeParams.fromJson((offlineResp['data'] as Map).cast<String, dynamic>());
  }

  Future<FrontInfo> getFrontInfo() async {
    try {
      final frontResp = await _get(url: _urls['getFrontInfo']!);
      final data = (frontResp['data'] as Map).cast<String, dynamic>();
      final raw = (data['getFrontConfig'] ?? '').toString();
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return FrontInfo.fromJson(decoded);
    } catch (_) {
      return const FrontInfo(privateKey: _fallbackPrivateKey, offlineCode: '0');
    }
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? data,
  }) async {
    try {
      final mergedHeaders = <String, String>{
        'Content-Type': 'application/json',
        ...?headers,
      };

      late final Response<dynamic> response;
      if (method == 'GET') {
        response = await _dio.get(url, options: Options(headers: mergedHeaders));
      } else if (method == 'POST') {
        response = await _dio.post(url, data: data, options: Options(headers: mergedHeaders));
      } else {
        throw const YKTException('HTTP请求方法错误');
      }

      final jsonData = _parseJSONData(response.data);
      if (jsonData['code'] != 200) {
        throw YKTException('业务失败: ${jsonEncode(jsonData)}');
      }
      return jsonData;
    } on YKTException {
      rethrow;
    } catch (e) {
      throw YKTException('请求失败: $e');
    }
  }

  Future<Map<String, dynamic>> _get({required String url, Map<String, String>? headers}) {
    return _request('GET', url, headers: headers);
  }

  Map<String, dynamic> _parseJSONData(dynamic data) {
    if (data == null) {
      throw const YKTException('响应数据为空');
    }

    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return data.cast<String, dynamic>();
    }

    if (data is String) {
      return (jsonDecode(data) as Map).cast<String, dynamic>();
    }

    if (data is List<int>) {
      final raw = utf8.decode(data);
      return (jsonDecode(raw) as Map).cast<String, dynamic>();
    }

    if (data is Uint8List) {
      final raw = utf8.decode(data);
      return (jsonDecode(raw) as Map).cast<String, dynamic>();
    }

    final raw = data.toString();
    return (jsonDecode(raw) as Map).cast<String, dynamic>();
  }

  String _generateQRCodeDataString(
    String currentBarcode,
    String payacc,
    OfflineCodeParams offlineParams,
    FrontInfo frontInfo,
  ) {
    final normalizedPem = _normalizePrivateKey(frontInfo.privateKey) ?? _fallbackPrivateKey;
    final hashKeyHex = _decryptUserHashKeyHex(offlineParams.userhashkey, normalizedPem).substring(0, 32);
    final offlineUserDataHex = offlineParams.offlineUserdata.toUpperCase();
    final payAccTagHex = _buildPayAccTag(payacc, '01');
    final isNewVersion = _isNewOfflineVersion(frontInfo);

    final totalLength = isNewVersion
        ? 13 + (offlineUserDataHex.length + payAccTagHex.length) ~/ 2 + 1
        : 13 + offlineUserDataHex.length ~/ 2;

    final headerBytes = _generateHeaderBytes(currentBarcode, totalLength, offlineParams, isNewVersion);
    var digestSourceHex = _bytesToHex(headerBytes).substring(48);

    var payAccTagLengthHex = '';
    if (isNewVersion) {
      payAccTagLengthHex = _padEvenHex((payAccTagHex.length ~/ 2).toRadixString(16).toUpperCase());
      digestSourceHex = '$digestSourceHex$offlineUserDataHex$payAccTagLengthHex$payAccTagHex$hashKeyHex';
    } else {
      digestSourceHex = '$digestSourceHex$offlineUserDataHex$hashKeyHex';
    }

    final hash8 = _sha1HexText(digestSourceHex).substring(0, 8).toUpperCase();
    final payloadHex = isNewVersion
        ? '$offlineUserDataHex$payAccTagLengthHex$payAccTagHex$hash8'
        : '$offlineUserDataHex$hash8';

    final payloadBytes = _hexToBytes(payloadHex);
    final combinedBytes = <int>[...headerBytes, ...payloadBytes];
    final protocolSuffix = 'S${String.fromCharCode(isNewVersion ? 80 : 79)}';

    if (isNewVersion) {
      final encoded = base64.encode(Uint8List.fromList(combinedBytes.sublist(22)));
      return '$currentBarcode$protocolSuffix$encoded';
    }

    final rawBytes = combinedBytes.sublist(22);
    final rawText = latin1.decode(rawBytes);
    return '$currentBarcode$protocolSuffix$rawText';
  }

  String _decryptUserHashKeyHex(String userhashkeyHex, String privateKeyPem) {
    final parser = encrypt_pkg.RSAKeyParser();
    final privateKey = parser.parse(privateKeyPem);
    final encrypter = encrypt_pkg.Encrypter(
      encrypt_pkg.RSA(
        privateKey: privateKey as dynamic,
        encoding: encrypt_pkg.RSAEncoding.PKCS1,
      ),
    );

    final encryptedBytes = Uint8List.fromList(_hexToBytes(userhashkeyHex));
    final decryptedBytes = encrypter.decryptBytes(encrypt_pkg.Encrypted(encryptedBytes));
    return _bytesToHex(decryptedBytes).toUpperCase();
  }

  String _padEvenHex(String value) => value.length.isEven ? value : '0$value';

  String _hexLengthPrefix(String valueHex) {
    final lenHex = (valueHex.length ~/ 2).toRadixString(16).toUpperCase();
    return _padEvenHex(lenHex);
  }

  List<int> _hexToBytes(String hex) {
    final normalized = _padEvenHex(hex);
    final bytes = <int>[];
    for (var i = 0; i < normalized.length; i += 2) {
      bytes.add(int.parse(normalized.substring(i, i + 2), radix: 16));
    }
    return bytes;
  }

  String _bytesToHex(List<int> bytes) {
    final buffer = StringBuffer();
    for (final value in bytes) {
      final h = value.toRadixString(16).padLeft(2, '0');
      buffer.write(h);
    }
    return buffer.toString().toUpperCase();
  }

  String _buildPayAccTag(String payacc, String accountType) {
    final charCodesHex = payacc.codeUnits.map((u) => u.toRadixString(16).toUpperCase()).join();
    final payaccHex = _padEvenHex(charCodesHex);

    final tag84 = '84${_hexLengthPrefix(payaccHex)}$payaccHex';
    final accountTypeHex = _padEvenHex(accountType.toUpperCase());
    final tag85 = '85${_hexLengthPrefix(accountTypeHex)}$accountTypeHex';
    final payload = '$tag84$tag85';
    return '6F${_hexLengthPrefix(payload)}$payload';
  }

  String _sha1HexText(String value) {
    final digest = sha1.convert(utf8.encode(value));
    return digest.toString().toUpperCase();
  }

  bool _isNewOfflineVersion(FrontInfo frontInfo) => frontInfo.offlineCode != '0';

  String? _normalizePrivateKey(String? privateKey) {
    if (privateKey == null || privateKey.isEmpty) {
      return null;
    }

    final trimmed = privateKey.trim();
    if (trimmed.contains('\n')) {
      return trimmed;
    }

    return trimmed
        .replaceFirst('-----BEGIN PRIVATE KEY-----', '-----BEGIN PRIVATE KEY-----\n')
        .replaceFirst('-----END PRIVATE KEY-----', '\n-----END PRIVATE KEY-----');
  }

  List<int> _generateHeaderBytes(
    String currentBarcode,
    int totalLength,
    OfflineCodeParams offlineParams,
    bool isNewVersion,
  ) {
    final version = int.tryParse(offlineParams.version) ?? 3;
    final protocolCode = isNewVersion ? 80 : 79;
    final effectiveTime = int.tryParse(offlineParams.offlineEffectiveTime) ?? 0;
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final headerBytes = List<int>.filled(33, 0);
    for (var i = 0; i < currentBarcode.length && i < 20; i += 1) {
      headerBytes[i] = currentBarcode.codeUnitAt(i);
    }

    headerBytes[20] = 83;
    headerBytes[21] = protocolCode;
    headerBytes[22] = (totalLength ~/ 256) % 256;
    headerBytes[23] = totalLength % 256;
    headerBytes[24] = version;
    headerBytes[25] = 0;
    headerBytes[26] = timestamp % 256;
    headerBytes[27] = (timestamp ~/ 256) % 256;
    headerBytes[28] = (timestamp ~/ 65536) % 256;
    headerBytes[29] = (timestamp ~/ 16777216) % 256;
    headerBytes[30] = 1;
    headerBytes[31] = effectiveTime % 256;
    headerBytes[32] = 1;

    return headerBytes;
  }
}