import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';

/// One material on a CIP production order's bill of materials - see wpsApi's
/// routes/cipOrders.js (`/cip-orders/materials/warehouse`). `itemCode`/`name`
/// are already normalized there: for a substituted material both are the item
/// it was changed *to*, so what is added to an order is never the stale
/// pre-swap number.
class CipOrderMaterial {
  const CipOrderMaterial({
    required this.itemCode,
    required this.name,
    required this.unit,
    required this.requiredQuantity,
    required this.changedFrom,
  });

  factory CipOrderMaterial.fromJson(Map<String, dynamic> json) {
    final change = (json['materialChange'] as Map?)?.cast<String, dynamic>();
    return CipOrderMaterial(
      itemCode: (json['itemCode'] as String? ?? '').trim(),
      name: json['name'] as String? ?? '',
      unit: json['unit'] as String? ?? '',
      requiredQuantity: (json['requiredQuantity'] as num?)?.toDouble(),
      changedFrom: change?['from'] as String?,
    );
  }

  final String itemCode;
  final String name;

  /// The catalog's/CIP's own unit (kg, km, ...) - shown for context only. An
  /// order_item is always counted in pieces (see orders_api.dart).
  final String unit;

  /// How much of it the whole production order needs, per CIP. Null for a
  /// drum requirement, which carries no quantity.
  final double? requiredQuantity;

  /// Set when this material was substituted after the order was planned -
  /// the item it replaced. Worth showing, so nobody wonders why the BOM they
  /// remember lists a different number.
  final String? changedFrom;
}

/// One production line of an order - a bare order number (or a fragment)
/// can match several, each with its own BOM.
class CipOrderLine {
  const CipOrderLine({required this.orderId, required this.segDescription, required this.materials});

  factory CipOrderLine.fromJson(Map<String, dynamic> json) => CipOrderLine(
    orderId: json['orderId'] as String? ?? '',
    segDescription: json['segDescription'] as String?,
    materials: (json['materials'] as List? ?? const [])
        .map((e) => CipOrderMaterial.fromJson((e as Map).cast<String, dynamic>()))
        .toList(),
  );

  final String orderId;
  final String? segDescription;
  final List<CipOrderMaterial> materials;
}

/// Why a lookup failed, in terms this app can act on: an expired CIP session
/// is recoverable (refresh and retry), an unknown order is not.
enum CipLookupError { noSession, notFound, unreachable }

class CipLookupFailure implements Exception {
  CipLookupFailure(this.kind);
  final CipLookupError kind;
}

/// Looks a production order's materials up in CIP, live (there is no local
/// copy - see wpsApi's AGENTS.md, "Order lookup"). Kept to what this
/// warehouse actually stocks (`/materials/warehouse`), because a BOM also
/// lists fibre, masterbatch and everything else that never comes from here.
///
/// Unlike every other call in this app, this one needs the operator's **own
/// CIP token** on top of the shared bearer token - wpsApi talks to CIP as
/// that person (see readCipToken there).
class CipOrdersApi {
  CipOrdersApi(this._dio);
  final Dio _dio;

  Future<List<CipOrderLine>> warehouseMaterials({required String orderId, required String cipToken}) async {
    if (cipToken.isEmpty) throw CipLookupFailure(CipLookupError.noSession);
    try {
      final res = await _dio.post<dynamic>(
        '/cip-orders/materials/warehouse',
        data: {'orderId': orderId},
        options: Options(headers: {'X-Cip-Token': cipToken}),
      );
      final data = res.data;
      // One matching line comes back as a bare object, several as a list -
      // see respondMaterials in wpsApi's routes/cipOrders.js.
      final lines = data is List ? data : [data];
      return lines.map((e) => CipOrderLine.fromJson((e as Map).cast<String, dynamic>())).toList();
    } on DioException catch (e) {
      throw CipLookupFailure(switch (e.response?.statusCode) {
        401 => CipLookupError.noSession,
        404 => CipLookupError.notFound,
        _ => CipLookupError.unreachable,
      });
    }
  }
}

final cipOrdersApiProvider = Provider<CipOrdersApi>((ref) => CipOrdersApi(ref.watch(authedDioProvider)));
