// lib/screens/address_search_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:webview_flutter/webview_flutter.dart';

class DaumAddress {
  final String? zonecode, address, roadAddress, jibunAddress, buildingName, sido, sigungu;
  DaumAddress({
    this.zonecode, this.address, this.roadAddress, this.jibunAddress,
    this.buildingName, this.sido, this.sigungu,
  });
  factory DaumAddress.fromJson(Map<String, dynamic> j) => DaumAddress(
    zonecode: j['zonecode'] as String?,
    address: j['address'] as String?,
    roadAddress: j['roadAddress'] as String?,
    jibunAddress: j['jibunAddress'] as String?,
    buildingName: j['buildingName'] as String?,
    sido: j['sido'] as String?,
    sigungu: j['sigungu'] as String?,
  );
  String get display => (roadAddress?.isNotEmpty ?? false) ? roadAddress! : (address ?? '');
}

class AddressSearchPage extends StatefulWidget {
  const AddressSearchPage({super.key});
  @override
  State<AddressSearchPage> createState() => _AddressSearchPageState();
}

class _AddressSearchPageState extends State<AddressSearchPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
    // JS 채널 (정상 경로)
      ..addJavaScriptChannel('ToFlutter', onMessageReceived: (msg) {
        final map = jsonDecode(msg.message) as Map<String, dynamic>;
        Navigator.of(context).pop(DaumAddress.fromJson(map));
      })
    // 커스텀 스킴 백업 경로
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (req) {
          if (req.url.startsWith('app://addr')) {
            final uri = Uri.parse(req.url);
            final encoded = uri.queryParameters['data'];
            if (encoded != null) {
              final map = jsonDecode(Uri.decodeComponent(encoded)) as Map<String, dynamic>;
              Navigator.of(context).pop(DaumAddress.fromJson(map));
            }
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ));

    _loadHtml();
  }

  Future<void> _loadHtml() async {
    final html = await rootBundle.loadString('assets/daum_postcode.html');
    // ⬇️ file:// 대신 https 베이스로 로드(콘솔 경고 제거 + 메시지 안정화)
    await _controller.loadHtmlString(
      html,
      baseUrl: 'https://local.postcode.app', // ✅ 문자열
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // 검정 헤더가 보이지 않도록
      appBar: AppBar(
        title: const Text('주소 검색'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
