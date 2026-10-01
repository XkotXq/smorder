import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';

/// One sm_catalog row - reference material list (see wpsApi's
/// src/smCatalog.js). Used here to search/pick materials for a
/// "Zamówienie materiału"/"Zamówienie szpul" order's items, same reference
/// list wps's own NewOrderPanel searches and ../../../smpda's own
/// SmCatalogItem mirrors.
class SmCatalogItem {
  const SmCatalogItem({required this.itemNo, required this.itemName, required this.unit});

  final String itemNo;
  final String itemName;

  /// The catalog's own unit (e.g. "kg", "KM") - shown next to the item in
  /// the picker, but never sent as the order_item's own unit (always
  /// "szt." - see orders_api.dart's own comment).
  final String unit;

  factory SmCatalogItem.fromJson(Map<String, dynamic> json) =>
      SmCatalogItem(itemNo: json['itemNo'] as String, itemName: json['itemName'] as String? ?? '', unit: json['unit'] as String? ?? '');
}

class SmCatalogApi {
  SmCatalogApi(this._dio);
  final Dio _dio;

  Future<List<SmCatalogItem>> list() async {
    final res = await _dio.get<List<dynamic>>('/sm-catalog');
    return (res.data ?? []).map((e) => SmCatalogItem.fromJson(e as Map<String, dynamic>)).toList();
  }
}

final smCatalogApiProvider = Provider<SmCatalogApi>((ref) => SmCatalogApi(ref.watch(authedDioProvider)));
