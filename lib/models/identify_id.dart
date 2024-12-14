class IdentifyResponse {
  final int code;
  final String msg;
  final String requestId;
  final IdentifyId data;

  IdentifyResponse({
    required this.code,
    required this.msg,
    required this.requestId,
    required this.data,
  });

  factory IdentifyResponse.fromJson(Map<String, dynamic> json) {
    return IdentifyResponse(
      code: json['code'],
      msg: json['msg'],
      requestId: json['requestId'],
      data: IdentifyId.fromJson(json["data"]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'msg': msg,
      'requestId': requestId,
      'data': data.toJson(),
    };
  }
}

class IdentifyId {
  final String color;
  final int validTime;
  final String content;

  IdentifyId({
    required this.color,
    required this.validTime,
    required this.content,
  });

  factory IdentifyId.fromJson(Map<String, dynamic> json) {
    return IdentifyId(
      color: json['color'],
      validTime: json['validTime'],
      content: json['content'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'color': color,
      'validTime': validTime,
      'content': content,
    };
  }
}
