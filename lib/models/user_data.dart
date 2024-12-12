import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../utils/file_storage.dart';

class PayId {
  final String devId;
  final String payAcctId;
  final String prePayId;
  final String payPrdCode;
  final String expiredTime;

  PayId({
    required this.devId,
    required this.payAcctId,
    required this.prePayId,
    required this.payPrdCode,
    required this.expiredTime,
  });

  factory PayId.fromJson(Map<String, dynamic> json) {
    return PayId(
      devId: json['devId'],
      payAcctId: json['payAcctId'],
      prePayId: json['prePayId'],
      payPrdCode: json['payPrdCode'],
      expiredTime: json['expiredTime'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'devId': devId,
      'payAcctId': payAcctId,
      'prePayId': prePayId,
      'payPrdCode': payPrdCode,
      'expiredTime': expiredTime,
    };
  }
}

class QrCodeResponse {
  final int code;
  final String msg;
  final String requestId;
  final List<PayId> data;

  QrCodeResponse({
    required this.code,
    required this.msg,
    required this.requestId,
    required this.data,
  });

  factory QrCodeResponse.fromJson(Map<String, dynamic> json) {
    var list = json['data'] as List;
    List<PayId> payIdList = list.map((i) => PayId.fromJson(i)).toList();

    return QrCodeResponse(
      code: json['code'],
      msg: json['msg'],
      requestId: json['requestId'],
      data: payIdList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'msg': msg,
      'requestId': requestId,
      'data': data.map((payId) => payId.toJson()).toList(),
    };
  }
}

class UserData with ChangeNotifier {
  String _studentId = '';
  String _password = '';
  String _accessToken = '';
  String _name = '';
  String _deptName = '';
  String _parentDeptName = '';
  List<PayId> _payIdList = [];
  final FileStorage _storage = FileStorage();
  final dio = Dio();

  UserData() {
    _loadData();
  }

  String get studentId => _studentId;
  String get password => _password;
  String get accessToken => _accessToken;
  String get name => _name;
  String get deptName => _deptName;
  String get parentDeptName => _parentDeptName;
  List<PayId> get payIdList => _payIdList;
  bool get isLoggedIn => _accessToken.isNotEmpty;

  void setStudentId(String id) {
    _studentId = id;
    notifyListeners();
    _saveData();
  }

  void setPassword(String pwd) {
    _password = pwd;
    notifyListeners();
    _saveData();
  }

  Future<void> _loadData() async {
    final data = await _storage.readData();
    _studentId = data['studentId'] ?? '';
    _password = data['password'] ?? '';
    _accessToken = data['accessToken'] ?? '';
    _name = data['name'] ?? '';
    _deptName = data['deptName'] ?? '';
    _parentDeptName = data['parentDeptName'] ?? '';
    _payIdList = (data['payIdList'] as List?)
            ?.map((item) => PayId.fromJson(item as Map<String, dynamic>))
            .toList() ??
        [];
    notifyListeners();
  }

  Future<void> _saveData() async {
    final data = {
      'studentId': _studentId,
      'password': _password,
      'accessToken': _accessToken,
      'name': _name,
      'deptName': _deptName,
      'parentDeptName': _parentDeptName,
      'payIdList': _payIdList.map((payId) => payId.toJson()).toList(),
    };
    await _storage.writeData(data);
  }

  Future<bool> loginAndSaveToken() async {
    try {
      final response = await dio.post(
        'https://oss.fzu.edu.cn/api/qr/login/getAccessToken',
        data: {
          'isNotPermanent': true,
          'username': studentId,
          'password': password,
        },
        options: Options(
          contentType: Headers.jsonContentType,
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      if (response.statusCode != 200) {
        throw Exception("在登录时发生异常: \n$response");
      }

      final responseData = response.data;
      switch (responseData['msg']) {
        case '请求成功':
          _accessToken = responseData['data']['access_token'];
          _name = responseData['data']['name'];
          _deptName = responseData['data']['deptName'];
          _parentDeptName = responseData['data']['parentDeptName'];
          notifyListeners();
          _saveData();
          return true;
        case '账号密码错误':
          throw Exception("账号或密码错误，请检查");
        default:
          throw Exception("无法成功登录: \n$responseData");
      }
    } catch (e) {
      throw Exception('登录时发生错误: \n$e');
    }
  }

  Future<void> getPayId() async {
    if (!isLoggedIn) {
      return;
    }

    try {
      final response = await dio.post(
        'https://oss.fzu.edu.cn/api/qr/deal/getQrCode',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_accessToken',
          },
          contentType: Headers.jsonContentType,
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('无法获得PayID: ${response.statusMessage}');
      }

      final responseData = response.data;
      switch (responseData['msg']) {
        case '请求成功':
          _payIdList = (responseData['data'] as List)
              .map((item) => PayId.fromJson(item as Map<String, dynamic>))
              .toList();
          notifyListeners();
          _saveData();
          break;
        default:
          throw Exception("无法获得payid: \n$responseData");
      }
    } catch (e) {
      throw Exception('获取PayID时发生错误: \n$e');
    }
  }

  Future<void> logout() async {
    _studentId = "";
    _password = "";
    _accessToken = "";
    _name = "";
    _deptName = "";
    _parentDeptName = "";
    _payIdList.clear();
    notifyListeners();
    await _storage.deleteData();
  }
}
