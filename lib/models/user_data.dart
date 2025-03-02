import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../utils/file_storage.dart';

import 'package:fzu_qrcode/models/pay_id.dart';
import "package:fzu_qrcode/models/identify_id.dart";

const ymtLoginUrl ='https://oss.fzu.edu.cn/api/qr/login/getAccessToken';
const getPayCodeUrl = 'https://oss.fzu.edu.cn/api/qr/deal/getQrCode';
const getIdentifyCodeUrl = 'https://oss.fzu.edu.cn/api/qr/device/getQrCode';


class UserData with ChangeNotifier {
  String _studentId = '';
  String _password = '';
  String _accessToken = '';
  String _name = '';
  String _deptName = '';
  String _parentDeptName = '';
  List<PayId> _payIdList = [];
  IdentifyId _identifyId =
      IdentifyId(color: "green", validTime: 60, content: "");
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
  IdentifyId get identifyID => _identifyId;

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
    _identifyId = data['identifyID'] != null
        ? IdentifyId.fromJson(data['identifyID'])
        : IdentifyId(color: "green", validTime: 60, content: "");
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
      'identifyID': _identifyId.toJson()
    };
    await _storage.writeData(data);
  }

  Future<bool> loginAndSaveToken() async {
    if (_studentId.isEmpty || _password.isEmpty) {
      throw Exception("学号或密码为空");
    }

    final response = await dio.post(
      ymtLoginUrl,
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
  }

  Future<void> getPayId() async {
    if (!isLoggedIn) {
      return;
    }

    final response = await dio.post(
      getPayCodeUrl,
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
  }

  Future<void> getIdentifyCode() async {
    if (!isLoggedIn) {
      return;
    }

    final response = await dio.get(
      getIdentifyCodeUrl,
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
      throw Exception('无法获得身份认证ID: ${response.statusMessage}');
    }

    final responseData = response.data;
    switch (responseData['msg']) {
      case '请求成功':
        _identifyId = IdentifyResponse.fromJson(responseData).data;
        notifyListeners();
        _saveData();
        break;
      default:
        throw Exception("无法获得身份认证id: \n$responseData");
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
    _identifyId = IdentifyId(color: "green", validTime: 60, content: "");
    notifyListeners();
    await _storage.deleteData();
  }
}
