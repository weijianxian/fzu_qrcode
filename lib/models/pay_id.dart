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
