import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AddressWebViewPage extends StatefulWidget {
  const AddressWebViewPage({super.key});

  @override
  State<AddressWebViewPage> createState() => _AddressWebViewPageState();
}

class _AddressWebViewPageState extends State<AddressWebViewPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted) // ✅ S 대문자
      ..addJavaScriptChannel(
        'ToFlutter',
        onMessageReceived: (JavaScriptMessage msg) {
          final map = jsonDecode(msg.message) as Map<String, dynamic>;
          // TODO: map 처리
        },
      )
    // HTML 문자열 로드
      ..loadHtmlString(_html); // 또는 loadRequest(Uri.parse(url))
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('주소 검색')),
      body: WebViewWidget(controller: _controller), // ✅ 새 위젯
    );
  }
}

const _html = r'''
<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <script src="https://t1.daumcdn.net/mapjsapi/bundle/postcode/prod/postcode.v2.js"></script>
</head>
<body>
  <div id="wrap"></div>
  <script>
    new daum.Postcode({
      oncomplete: function(data) {
        var payload = {
          zonecode: data.zonecode,
          address: data.address,
          roadAddress: data.roadAddress,
          jibunAddress: data.jibunAddress,
          buildingName: data.buildingName,
          sido: data.sido,
          sigungu: data.sigungu
        };
        ToFlutter.postMessage(JSON.stringify(payload));
      }
    }).embed(document.getElementById('wrap'));
  </script>
</body>
</html>
''';
