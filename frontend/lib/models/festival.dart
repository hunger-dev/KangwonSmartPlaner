class Festival {
  final int id;
  final String title;
  final String? periodRaw;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final String? address;
  final String? imageSrc;
  final String? detailUrl;

  Festival({
    required this.id,
    required this.title,
    this.periodRaw,
    this.periodStart,
    this.periodEnd,
    this.address,
    this.imageSrc,
    this.detailUrl,
  });

  factory Festival.fromJson(Map<String, dynamic> json) {
    final period = json['period'] as Map<String, dynamic>?;
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      final s = v.toString();
      // API: "YYYY-MM-DD" 형태 → DateTime.parse 가능
      try { return DateTime.parse(s); } catch (_) { return null; }
    }
    return Festival(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      periodRaw: period?['raw'] as String?,
      periodStart: parseDate(period?['start']),
      periodEnd: parseDate(period?['end']),
      address: json['address'] as String?,
      imageSrc: json['image_src'] as String?,
      detailUrl: json['detail_url'] as String?,
    );
  }
}