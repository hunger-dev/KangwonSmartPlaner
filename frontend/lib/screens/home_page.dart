// lib/screens/home_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/festival.dart';
import '../services/api_client.dart';
import 'festival_detail_page.dart';
import '../widgets/glass.dart';
import '../widgets/glass_search_bar.dart';


const kIconColor = Color(0xCCFFFFFF);   // #FFFFFF
const kTextColor = Color(0xCCFFFFFF);   // #FFFFFF, 90% 투명도(=E6)

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Festival>> _future;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _future = ApiClient.fetchFirstPage(); // 첫 페이지 기본 16건
  }

  String _fmtDate(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('yyyy.MM.dd').format(dt.toLocal());
  }

  Future<void> _reload({String? q}) async {
    setState(() {
      _future = ApiClient.fetchFirstPage(q: q);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 배경은 루트에서 그라데이션 주고 있으니 투명 유지
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 0, // 타이틀 영역 제거 (원하면 유지해도 됨)
        elevation: 0,
        backgroundColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(76),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: StatefulBuilder( // suffix 아이콘 갱신용
              builder: (context, setLocal) {
                _searchCtrl.addListener(() => setLocal(() {}));
                return GlassSearchBar(
                  controller: _searchCtrl,
                  onSearch: (q) => _reload(q: q),
                );
              },
            ),
          ),
        ),
      ),

      body: RefreshIndicator(
        onRefresh: () => _reload(q: _searchCtrl.text),
        child: FutureBuilder<List<Festival>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // RefreshIndicator가 동작하도록 항상 스크롤 가능하게
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 160),
                  Center(child: CircularProgressIndicator()),
                  SizedBox(height: 400),
                ],
              );
            }
            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  const SizedBox(height: 80),
                  Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                  const SizedBox(height: 12),
                  Text('불러오기 실패: ${snapshot.error}',
                      textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: () => _reload(q: _searchCtrl.text),
                      child: const Text('다시 시도'),
                    ),
                  ),
                  const SizedBox(height: 400),
                ],
              );
            }

            final items = snapshot.data ?? const [];
            if (items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 80),
                  Center(child: Text('표시할 축제가 없어요.')),
                  SizedBox(height: 400),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final f = items[index];
                final periodText = (f.periodStart != null || f.periodEnd != null)
                    ? '${_fmtDate(f.periodStart)} ~ ${_fmtDate(f.periodEnd)}'
                    : (f.periodRaw ?? '');

                return GlassContainer(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => FestivalDetailPage(festival: f),
                      ),
                    );
                  },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 썸네일
                      SizedBox(
                        width: 96,
                        height: 96,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: (f.imageSrc == null || f.imageSrc!.isEmpty)
                              ? Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.image_not_supported),
                          )
                              : Hero(
                            tag: 'poster_${f.id}',
                            child: CachedNetworkImage(
                              imageUrl: f.imageSrc!,
                              fit: BoxFit.cover,
                              placeholder: (c, _) =>
                                  Container(color: Colors.grey.shade200),
                              errorWidget: (c, _, __) =>
                              const Icon(Icons.broken_image),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 텍스트
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              f.title,
                              style: const TextStyle(
                                color: kTextColor, // #1F6FEB
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (periodText.isNotEmpty)
                              Row(
                                children: [
                                  const Icon(Icons.event, size: 16, color: kIconColor),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      periodText,
                                      style: const TextStyle(color: kTextColor),
                                    ),
                                  ),
                                ],
                              ),
                            if ((f.address ?? '').isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.place, size: 16, color: kIconColor),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      f.address!,
                                      style: const TextStyle(color: kTextColor),
                                    ),
                                  ),
                                ],
                              ),
                            ]
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
