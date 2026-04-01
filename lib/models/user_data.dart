// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt_pkg;
import 'package:fzu_qrcode/utils/file_storage.dart';
import 'package:fzu_qrcode/utils/constants.dart';
import 'package:fzu_qrcode/utils/ykt_login.dart';

// 支付ID模型
class PayId {
  final String prePayId;
  final String payId;

  PayId({required this.prePayId, required this.payId});

  factory PayId.fromJson(Map<String, dynamic> json) {
    return PayId(
      prePayId: json['prePayId'] ?? '',
      payId: json['payId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'prePayId': prePayId,
      'payId': payId,
    };
  }
}

// 认证码模型
class IdentifyId {
  final String content;
  final String color;

  IdentifyId({required this.content, required this.color});

  factory IdentifyId.fromJson(Map<String, dynamic> json) {
    return IdentifyId(
      content: json['content'] ?? '',
      color: json['color'] ?? 'black',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'color': color,
    };
  }
}

// 两步验证回调接口
typedef TwoFactorAuthCallback = Future<String?> Function(
  String phone,
  String tip,
  Future<void> Function() sendSms,
);

// 用户数据模型
class UserData extends ChangeNotifier {
  final FileStorage _storage = FileStorage();
  late final Dio _dio;
  bool _initialized = false;

  UserData() {
    // 初始化 Dio，设置合理的超时时间
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        validateStatus: (status) => status != null && status < 400,
      ),
    );
    _loadFromStorage();
  }

  String _studentId = '';
  String _password = '';
  String _ssoCookie = '';
  String _synjonesAuth = '';
  String _yktUserInfo = '';
  List<PayId> _payIdList = [];
  IdentifyId _identifyID = IdentifyId(content: '', color: 'black');

  String get studentId => _studentId;
  String get password => _password;
  String get ssoCookie => _ssoCookie;
  String get synjonesAuth => _synjonesAuth;
  String get yktUserInfo => _yktUserInfo;
  List<PayId> get payIdList => _payIdList;
  IdentifyId get identifyID => _identifyID;
  bool get isLoggedIn => _ssoCookie.isNotEmpty;
  bool get isInitialized => _initialized;

  void _log(String message) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[SSO] $message');
    }
  }

  // 从本地存储加载数据
  Future<void> _loadFromStorage() async {
    _log('加载本地存储数据');
    try {
      final data = await _storage.readData();
      _studentId = data['studentId'] ?? '';
      _password = data['password'] ?? '';
      _ssoCookie = data['ssoCookie'] ?? '';
      _synjonesAuth = data['synjonesAuth'] ?? '';
      _yktUserInfo = data['yktUserInfo'] ?? '';
      if (data['payIdList'] != null) {
        _payIdList = (data['payIdList'] as List)
            .map((item) => PayId.fromJson(item))
            .toList();
      }
      if (data['identifyID'] != null) {
        _identifyID = IdentifyId.fromJson(data['identifyID']);
      }
      _log(
          '加载成功: studentId=${_studentId.isEmpty ? '空' : '已保存'}, ssoCookie=${_ssoCookie.isEmpty ? '空' : '已保存'}');
    } catch (e) {
      _log('加载存储数据失败: $e');
    } finally {
      _initialized = true;
      notifyListeners();
    }
  }

  // 保存数据到本地存储
  Future<void> _saveToStorage() async {
    _log('写入本地存储');
    try {
      await _storage.writeData({
        'studentId': _studentId,
        'password': _password,
        'ssoCookie': _ssoCookie,
        'synjonesAuth': _synjonesAuth,
        'yktUserInfo': _yktUserInfo,
        'payIdList': _payIdList.map((item) => item.toJson()).toList(),
        'identifyID': _identifyID.toJson(),
      });
      _log('写入成功');
    } catch (e) {
      _log('保存数据失败: $e');
    }
  }

  void setStudentId(String value) {
    _studentId = value;
    _log('更新studentId, 长度=${value.length}');
    notifyListeners();
  }

  void setPassword(String value) {
    _password = value;
    _log('更新password, 长度=${value.length}');
    notifyListeners();
  }

  // 提取Cookie中的键值对（从多个set-cookie header中）
  String _extractCookie(Headers headers, String key) {
    final setCookies = headers.map['set-cookie'] ?? const <String>[];
    _log('尝试在cookie中查找$key, 共${setCookies.length}个set-cookie');

    for (final cookie in setCookies) {
      _log('检查cookie: $cookie');
      final regex = RegExp('$key=([^;]+)');
      final match = regex.firstMatch(cookie);
      if (match != null && match.group(1) != null) {
        final value = match.group(1)!;
        _log('找到$key=$value');
        return value;
      }
    }

    _log('未在cookie中找到$key');
    throw Exception('Cookie中未找到: $key');
  }

  // AES加密 (AES-ECB模式)
  String _encrypt(String plainText, String keyBase64) {
    try {
      _log('准备加密文本, 原文长度=${plainText.length}');
      final keyBytes = base64Decode(keyBase64);
      final key = encrypt_pkg.Key(keyBytes);
      final encrypter = encrypt_pkg.Encrypter(
        encrypt_pkg.AES(key, mode: encrypt_pkg.AESMode.ecb, padding: 'PKCS7'),
      );
      final encrypted = encrypter.encrypt(plainText);
      _log('加密成功, 密文长度=${encrypted.base64.length}');
      return encrypted.base64;
    } catch (e) {
      _log('加密失败: $e');
      rethrow;
    }
  }

  // 生成CSRF Token
  Map<String, String> _genCSRFToken() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = List.generate(32, (index) {
      final randomIndex = DateTime.now().microsecondsSinceEpoch % chars.length;
      return chars[(randomIndex + index) % chars.length];
    }).join();

    final base64Key = base64Encode(utf8.encode(random));
    final halfLength = base64Key.length ~/ 2;
    final tokenData = base64Key.substring(0, halfLength) +
        base64Key +
        base64Key.substring(halfLength);

    final csrfValue = md5.convert(utf8.encode(tokenData)).toString();

    final result = {
      'csrfKey': random,
      'csrfValue': csrfValue,
    };
    _log('生成CSRF token key=${result['csrfKey']}');
    return result;
  }

  // 发送短信验证码
  Future<Map<String, dynamic>> sendSmsCode(String phone, String session) async {
    final csrf = _genCSRFToken();
    try {
      final response = await _dio.post(
        ssoLoginSmsUrl,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': 'SESSION=$session',
            'Csrf-Key': csrf['csrfKey'],
            'Csrf-Value': csrf['csrfValue'],
          },
        ),
        data: {
          'businessNo': '0008',
          'phone': phone,
        },
      );

      if (response.data['code'] == 200) {
        return {'success': true};
      } else if (response.data['code'] == 412) {
        return {'success': false, 'message': '验证码发送频率过快，请等待120秒后重试'};
      } else {
        return {'success': false, 'message': response.data['msg'] ?? '验证码发送失败'};
      }
    } catch (e) {
      if (kDebugMode) {
        print('发送验证码失败: $e');
      }
      return {'success': false, 'message': '验证码发送失败'};
    }
  }

  // SSO登录
  Future<String> ssoLogin(String account, String password,
      TwoFactorAuthCallback? twoFactorCallback) async {
    _log('开始SSO登录流程, account=$account');
    if (account.isEmpty || password.isEmpty) {
      throw Exception('账号密码不能为空');
    }

    try {
      // 首先请求SSO界面获得密钥
      _log('请求SSO登录页: $ssoLoginUrl');
      final ssoPage = await _dio.get(
        ssoLoginUrl,
        options: Options(
          followRedirects: false,
          validateStatus: (status) => status! < 400,
        ),
      );

      _log('SSO登录页返回状态: ${ssoPage.statusCode}');
      final html = ssoPage.data as String;
      _log('SSO登录页内容长度: ${html.length}');

      // 从页面中提取密钥和execution
      final cryptoMatch = RegExp(r'"login-croypto">(.*?)<').firstMatch(html);
      final executionMatch =
          RegExp(r'"login-page-flowkey">(.*?)<').firstMatch(html);

      if (cryptoMatch == null || executionMatch == null) {
        throw Exception('无法从页面中提取密钥');
      }

      final crypto = cryptoMatch.group(1)!;
      final execution = executionMatch.group(1)!;
      _log('提取到croypto: $crypto, execution: $execution');
      final session = _extractCookie(ssoPage.headers, 'SESSION');
      _log('获得SESSION: $session');

      // 构建登录数据
      final data = {
        'username': account,
        'type': 'UsernamePassword',
        '_eventId': 'submit',
        'geolocation': '',
        'execution': execution,
        'captcha_code': '',
        'croypto': crypto,
        'password': _encrypt(password, crypto),
        'captcha_payload': _encrypt('{}', crypto),
      };

      // 发送登录请求
      _log('提交用户名密码登录...');
      var loginResp = await _dio.post(
        ssoLoginUrl,
        options: Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'Cookie': 'SESSION=$session',
          },
          followRedirects: false,
          validateStatus: (status) => status! < 400,
        ),
        data: data,
      );

      // 检查是否需要两步验证
      final loginHtml = loginResp.data as String;
      if (loginHtml.contains('<p id="current-login-type">smsLogin</p>')) {
        _log('检测到需要短信验证');
        final phoneMatch =
            RegExp(r'<p id="phone-number">(.*?)</p>').firstMatch(loginHtml);
        final tipMatch =
            RegExp(r'<p id="second-auth-tip">(.*?)</p>').firstMatch(loginHtml);

        final phone = phoneMatch?.group(1);
        final tip = tipMatch?.group(1) ?? '请进行手机验证以保障您的账号安全';

        if (phone == null) {
          throw Exception('需要进行手机验证，但未找到手机号');
        }

        if (twoFactorCallback == null) {
          throw Exception('需要进行两步验证，但未提供验证回调');
        }

        // 创建发送验证码的函数
        Future<void> sendSms() async {
          _log('准备发送验证码到: $phone');
          final sendResult = await sendSmsCode(phone, session);
          if (sendResult['success'] != true) {
            throw Exception(sendResult['message'] ?? '验证码发送失败');
          }
          _log('验证码发送成功');
        }

        // 调用回调获取用户输入的验证码
        final userInputCode = await twoFactorCallback(phone, tip, sendSms);
        if (userInputCode == null || userInputCode.isEmpty) {
          return ''; // 用户取消
        }
        _log('收到用户输入的验证码');

        // 验证验证码
        final csrf = _genCSRFToken();
        _log('验证验证码, csrfKey=${csrf['csrfKey']}');
        final verifyResp = await _dio.post(
          ssoLoginVerifySmsCodeUrl,
          options: Options(
            headers: {
              'Content-Type': 'application/json',
              'Cookie': 'SESSION=$session',
              'Csrf-Key': csrf['csrfKey'],
              'Csrf-Value': csrf['csrfValue'],
            },
          ),
          data: {
            'phone': phone,
            'token': userInputCode,
            'delete': 'false',
            'trustDevice': 'false',
          },
        );

        _log('验证码验证返回: ${verifyResp.data}');
        if (verifyResp.data['code'] != 200) {
          throw Exception(verifyResp.data['msg'] ?? '验证码验证失败');
        }

        // 完成登录流程
        _log('验证码验证通过，继续短信登录');
        loginResp = await _dio.post(
          ssoLoginUrl,
          options: Options(
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Cookie': 'SESSION=$session',
            },
            followRedirects: false,
            validateStatus: (status) => status! < 400,
          ),
          data: {
            'username': account,
            'password': userInputCode,
            'type': 'smsLogin',
            '_eventId': 'submit',
            'geolocation': '',
            'execution': execution,
            'captcha_code': '',
            'trustDevice': 'false',
          },
        );
      }

      // 验证登录是否成功
      final sourceidTgc = _extractCookie(loginResp.headers, 'SOURCEID_TGC');
      final cookies = 'SOURCEID_TGC=$sourceidTgc';
      _log('登录成功, SOURCEID_TGC: $sourceidTgc');
      return cookies;
    } catch (e) {
      _log('SSO登录失败: $e');
      rethrow;
    }
  }

  // 登录并保存token
  Future<void> loginAndSaveToken(
      [TwoFactorAuthCallback? twoFactorCallback]) async {
    final cookies = await ssoLogin(_studentId, _password, twoFactorCallback);
    if (cookies.isEmpty) {
      throw Exception('登录被取消');
    }
    _ssoCookie = cookies;
    await _saveToStorage();
    notifyListeners();
  }

  // 获取支付ID
  Future<void> getPayId() async {
    if (_ssoCookie.isEmpty) {
      throw Exception('请先完成SSO登录');
    }

    _log('getPayId: 开始获取一码通支付数据');
    final ykt = YKTLogin(
      dio: _dio,
      authResolver: _resolveYktAuthFromSso,
    );

    final result = await ykt.getPayCode(
      ssoCookie: _ssoCookie,
      cachedAuth: _synjonesAuth,
    );

    _synjonesAuth = result.synjonesAuth;
    _yktUserInfo = result.userInfoRaw;
    _payIdList = [
      PayId(prePayId: result.payInfo.account, payId: result.payInfo.payacc),
    ];
    _identifyID = IdentifyId(content: result.payCode, color: 'black');

    _log('getPayId: 获取成功, payacc=${result.payInfo.payacc}');
    await _saveToStorage();
    notifyListeners();
  }

  // 登出
  Future<void> logout() async {
    _studentId = '';
    _password = '';
    _ssoCookie = '';
    _synjonesAuth = '';
    _yktUserInfo = '';
    _payIdList = [];
    _identifyID = IdentifyId(content: '', color: 'black');
    await _storage.deleteData();
    notifyListeners();
  }

  // 从 dynamic 类型的头部值中安全提取字符串
  String? _extractHeaderString(dynamic headerValue) {
    if (headerValue == null) return null;
    try {
      if (headerValue is String) {
        return headerValue.isEmpty ? null : headerValue;
      }
      // 如果是列表类型，提取第一个元素
      if (headerValue is List) {
        return headerValue.isEmpty ? null : (headerValue.first as String);
      }
      // 其他情况转换为字符串
      final str = headerValue.toString();
      return str.isEmpty ? null : str;
    } catch (e) {
      _log('提取头部字符串失败: $e');
      return null;
    }
  }

  // 通过SSO Cookie兑换YKT token，使用CAS重定向流程
  // 参考：https://github.com/west2-online/fzuhelper-app/pull/347
  Future<String> _resolveYktAuthFromSso(String ssoCookie) async {
    if (ssoCookie.isEmpty) {
      throw Exception('SSO Cookie 不能为空');
    }

    try {
      // 第一步：访问 SSO 登录页，携带 service 参数指向一卡通系统
      const casServiceUrl =
          'https://sso.fzu.edu.cn/login?service=https%3A%2F%2Fxcx.fzu.edu.cn%2Fberserker-auth%2Fcas%2Flogin%2FruiJie%3FtargetUrl%3Dhttps%253A%252F%252Fxcx.fzu.edu.cn%252Fberserker-base%252Fredirect%253FappId%253D16%2526nodeId%253D15%2526type%253Dapp';

      _log('第1步：发送 CAS 登录请求...');
      var response = await _dio.get(
        casServiceUrl,
        options: Options(
          headers: {'Cookie': ssoCookie},
          followRedirects: false,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
          validateStatus: (status) => status != null && status < 400,
        ),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('第1步请求超时（15秒）'),
      );

      _log('第1步响应状态: ${response.statusCode}');

      // 提取新的 SESSION cookie
      var currentCookie = ssoCookie;
      final setcookieStr = _extractHeaderString(response.headers['set-cookie']);
      if (setcookieStr != null) {
        final sessionMatch =
            RegExp(r'SESSION=([^;]+)').firstMatch(setcookieStr);
        if (sessionMatch != null) {
          final sessionValue = sessionMatch.group(1);
          _log('提取到新 SESSION: $sessionValue');
          currentCookie = '$ssoCookie; SESSION=$sessionValue';
        }
      }

      // 第二步：跟随重定向到一卡通系统
      final redirectUrl = _extractHeaderString(response.headers['location']);
      if (redirectUrl == null || redirectUrl.isEmpty) {
        throw Exception('无法从 CAS 登录页获得重定向地址');
      }

      _log('第2步：跟随重定向到 $redirectUrl');
      response = await _dio.get(
        redirectUrl,
        options: Options(
          headers: {'Cookie': currentCookie},
          followRedirects: false,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
          validateStatus: (status) => status != null && status < 400,
        ),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('第2步请求超时（15秒）'),
      );

      _log('第2步响应状态: ${response.statusCode}');

      // 第三步：从最终的重定向 URL 中提取 synjones-auth token
      final finalRedirectUrl =
          _extractHeaderString(response.headers['location']);
      if (finalRedirectUrl == null || finalRedirectUrl.isEmpty) {
        throw Exception('无法从一卡通重定向中获得 synjones-auth');
      }

      _log('最终重定向 URL: $finalRedirectUrl');
      final tokenMatch =
          RegExp(r'synjones-auth=([^&]+)').firstMatch(finalRedirectUrl);
      if (tokenMatch != null) {
        final token = tokenMatch.group(1);
        _log('成功提取 synjones-auth token: $token');
        return Uri.decodeComponent(token ?? '');
      }

      throw Exception('重定向 URL 中未找到 synjones-auth 参数');
    } catch (e) {
      _log('YKT 鉴权失败: $e');
      rethrow;
    }
  }
}
