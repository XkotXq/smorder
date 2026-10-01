import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';

/// One line of a transport order - see wpsApi's schema.sql `order_items`/
/// `order_items_progress` and orders.js's own orderRowToApi, same shape
/// ../../../smVendor's/../../../smpda's own OrderItem reads.
class OrderItem {
  const OrderItem({
    required this.itemNo,
    required this.itemName,
    required this.quantity,
    required this.unit,
    required this.issuedQuantity,
    required this.issuedUnit,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    itemNo: json['itemNo'] as String,
    itemName: json['itemName'] as String? ?? '',
    quantity: json['quantity'] as String? ?? '0',
    unit: json['unit'] as String? ?? '',
    issuedQuantity: json['issuedQuantity'] as String? ?? '0',
    issuedUnit: json['issuedUnit'] as String? ?? '',
  );

  final String itemNo;
  final String itemName;
  final String quantity;
  final String unit;
  final String issuedQuantity;
  final String issuedUnit;

  bool get isFulfilled => (double.tryParse(issuedQuantity) ?? 0) >= (double.tryParse(quantity) ?? 0);
}

/// One transport order - same JSON shape every client in this app family
/// reads from wpsApi's orders.js (see ../../../smVendor's own
/// TransportOrder). This app is the *requester's* own (the one who placed
/// it, see AGENTS.md's "Transport orders" in wpsApi) - it both creates
/// orders (see OrdersApi.create) and watches their status through to
/// done/cancelled, read-only past that (a forklift operator's own actions -
/// take/deliver - live in smVendor, not here).
class TransportOrder {
  const TransportOrder({
    required this.id,
    required this.orderNo,
    required this.type,
    required this.status,
    required this.from,
    required this.to,
    required this.employeeNo,
    required this.takenBy,
    required this.deliveredBy,
    required this.deliveredAt,
    this.autoAcceptInSeconds,
    required this.fulfilledBy,
    required this.createdAt,
    required this.note,
    required this.details,
    required this.items,
    required this.cancelReason,
    required this.cancelledAt,
    required this.problemNote,
    required this.problemReportedBy,
    required this.problemReportedAt,
    required this.problemReportedFrom,
    required this.problemResolvedBy,
    required this.problemResolvedAt,
    this.photoUrl,
  });

  factory TransportOrder.fromJson(Map<String, dynamic> json) => TransportOrder(
    id: json['id'] as String,
    orderNo: json['orderNo'] as String? ?? '',
    type: json['type'] as String? ?? '',
    // "new" | "inProgress" | "delivered" | "done" | "cancelled" - see
    // wpsapi's orders.js STATUS_TO_API.
    status: json['status'] as String? ?? 'new',
    from: json['from'] as String?,
    to: json['to'] as String?,
    employeeNo: json['employeeNo'] as String? ?? '',
    takenBy: json['takenBy'] as String?,
    deliveredBy: json['deliveredBy'] as String?,
    deliveredAt: json['deliveredAt'] != null ? DateTime.tryParse(json['deliveredAt'] as String) : null,
    autoAcceptInSeconds: (json['autoAcceptInSeconds'] as num?)?.toInt(),
    fulfilledBy: json['fulfilledBy'] as String? ?? '-',
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    note: json['note'] as String? ?? '-',
    details: (json['details'] as Map?)?.cast<String, dynamic>() ?? const {},
    items: (json['items'] as List? ?? const []).map((e) => OrderItem.fromJson(e as Map<String, dynamic>)).toList(),
    // This app's own "Zgłoś problem" on a delivered order (delivered ->
    // cancelled, wpsApi's cancelOrder), and wps's same action - a closed
    // order, unlike the `problem` status below.
    cancelReason: json['cancelReason'] as String?,
    cancelledAt: json['cancelledAt'] != null ? DateTime.tryParse(json['cancelledAt'] as String) : null,
    // The forklift operator's "Zgłoś problem" while fulfilling - status
    // 'problem', which is **not** a cancellation: the order stays open and
    // it is this app's turn to deal with it (see resolveProblem).
    problemNote: json['problemNote'] as String? ?? '',
    problemReportedBy: json['problemReportedBy'] as String?,
    problemReportedAt: json['problemReportedAt'] != null
        ? DateTime.tryParse(json['problemReportedAt'] as String)
        : null,
    // "inProgress" = the operator got stuck, so this app answers it;
    // "delivered" = this app rejected the delivery, so the operator does.
    // "" when no problem is open. See wpsApi's problem_reported_from.
    problemReportedFrom: json['problemReportedFrom'] as String? ?? '',
    problemResolvedBy: json['problemResolvedBy'] as String?,
    problemResolvedAt: json['problemResolvedAt'] != null
        ? DateTime.tryParse(json['problemResolvedAt'] as String)
        : null,
    // A short-lived presigned link, re-issued by wpsApi on every read (see
    // its src/orderPhotos.js) - never cache it anywhere, just show it.
    photoUrl: ((json['photo'] as Map?)?.cast<String, dynamic>())?['url'] as String?,
  );

  final String id;
  final String orderNo;
  final String type;
  final String status;
  final String? from;
  final String? to;
  final String employeeNo;
  final String? takenBy;
  final String? deliveredBy;

  /// When the forklift operator pressed "Dostarczone".
  final DateTime? deliveredAt;

  /// Seconds left before wpsApi auto-accepts this order, straight from the
  /// server (see its orderRowToApi) - null unless it is actually waiting.
  /// **Measured on the server clock on purpose**: a phone that is minutes
  /// out would otherwise show a countdown that is simply wrong, and the
  /// 10-minute window stays a server-only constant. The screen ticks this
  /// down locally between reads and re-syncs on every poll.
  final int? autoAcceptInSeconds;
  final String fulfilledBy;
  final DateTime createdAt;
  final String note;
  final Map<String, dynamic> details;
  final List<OrderItem> items;
  final String? cancelReason;
  final DateTime? cancelledAt;

  /// What the forklift operator says is blocking this order right now
  /// (status 'problem'), and who said so when. Cleared server-side once it
  /// is resolved - the episode itself stays in GET /orders/:id/events, so a
  /// cleared note is not a lost one.
  final String problemNote;
  final String? problemReportedBy;
  final DateTime? problemReportedAt;

  /// Which status the open problem was reported from, and so **whose turn
  /// it is to answer it**: 'inProgress' (the operator is stuck - this app
  /// answers) or 'delivered' (this app rejected the delivery - the operator
  /// answers). Empty when nothing is pending.
  final String problemReportedFrom;

  /// Who last resolved a problem on this order, and when - shown on an
  /// order that got blocked and then carried on, so the person who
  /// unblocked it can see their own answer landed.
  final String? problemResolvedBy;
  final DateTime? problemResolvedAt;
  final String? photoUrl;

  String? get productionOrderNo => details['productionOrderNo'] as String?;
  String? get water => details['water'] as String?;

  /// Waiting for the requester to confirm it or report a problem.
  bool get awaitingConfirmation => status == 'delivered';

  /// There is an open problem, whichever side reported it.
  bool get hasOpenProblem => status == 'problem';

  /// The open problem is **this person's to answer**: the forklift operator
  /// got stuck and is waiting for them to sort it out and mark it
  /// corrected. A problem *they* reported on a delivery waits on the
  /// operator instead, and this app only shows that it is pending.
  bool get awaitingProblemResolution => hasOpenProblem && problemReportedFrom == 'inProgress';


  /// "skąd → dokąd" when both are set, else the one place this order
  /// concerns - same fallback as wps's own routeLabel()/smVendor's route().
  String route() {
    if (from != null && to != null) return '$from → $to';
    return to ?? from ?? '-';
  }
}

/// One item to add to a new material_order/spool_order - the piece a
/// NewOrderForm row builds before submit.
class NewOrderItem {
  const NewOrderItem({required this.itemNo, required this.itemName, required this.quantity, this.unit = 'szt.'});
  final String itemNo;
  final String itemName;
  final String quantity;
  final String unit;

  Map<String, dynamic> toJson() => {'itemNo': itemNo, 'itemName': itemName, 'quantity': quantity, 'unit': unit};
}

/// GET /orders (list + one), GET /orders/locations, POST /orders - see
/// wpsapi's routes/orders.js. Same direct-to-wpsapi pattern as
/// ../../../smVendor's own OrdersApi, using the shared bearer token.
class OrdersApi {
  OrdersApi(this._dio);
  final Dio _dio;

  /// scope: "active" (new + in_progress + delivered) | "history" (done +
  /// cancelled) - see wpsapi's listOrders/STATUS_SETS. No per-requester
  /// filter server-side (listOrders has none) - every order placed by
  /// anyone shows here, same shared-dashboard model wps's own "Lista
  /// zamówień" already uses.
  Future<List<TransportOrder>> list(String scope) async {
    final res = await _dio.get<List<dynamic>>('/orders', queryParameters: {'scope': scope});
    return (res.data ?? []).map((e) => TransportOrder.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<TransportOrder> get(String id) async {
    final res = await _dio.get<Map<String, dynamic>>('/orders/$id');
    return TransportOrder.fromJson(res.data!);
  }

  /// Every known place (fixed lines + whatever was typed on an earlier
  /// goods_transport order) - the free-text "skąd"/"dokąd" suggestion pool,
  /// straight from the database's own `locations` table, same as wps's own
  /// lib/ordersApi.js.
  Future<List<String>> locations() async {
    final res = await _dio.get<List<dynamic>>('/orders/locations');
    return (res.data ?? []).cast<String>();
  }

  /// "Nowe zamówienie" - see wpsapi's createOrder for the exact body shape
  /// this mirrors (type/employeeNo/from/to/details/note/items). No `photo`
  /// field (unlike wps's own NewOrderPanel, which sends one too) - there is
  /// no upload endpoint for it yet either side (see wpsApi's AGENTS.md
  /// roadmap, "Photos"), so wps's own copy is a dead field today too.
  Future<TransportOrder> create({
    required String type,
    required String employeeNo,
    String? from,
    String? to,
    Map<String, dynamic> details = const {},
    String note = '',
    List<NewOrderItem> items = const [],
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/orders',
      data: {
        'type': type,
        'employeeNo': employeeNo,
        'from': from,
        'to': to,
        'details': details,
        'note': note,
        'items': items.map((i) => i.toJson()).toList(),
      },
    );
    return TransportOrder.fromJson(res.data!);
  }

  /// "Zgadza się" - the requester confirming what was delivered
  /// (`delivered -> done`, see wpsApi's acceptOrder). Doing nothing is also
  /// valid: wpsApi closes a delivered order itself once the window it
  /// reports as [TransportOrder.autoAcceptInSeconds] runs out, which is why
  /// the order page counts that down instead of demanding an answer.
  Future<TransportOrder> accept(String id, String acceptedBy) async {
    final res = await _dio.post<Map<String, dynamic>>('/orders/$id/accept', data: {'acceptedBy': acceptedBy});
    return TransportOrder.fromJson(res.data!);
  }

  /// "Zgłoś problem" on what arrived - `delivered -> problem`, the same
  /// endpoint and the same loop smVendor uses from the other side (see
  /// wpsApi's reportOrderProblem).
  ///
  /// It used to cancel the order (`POST /:id/cancel`), which was wrong:
  /// that ended the transport and left nobody to answer it. Now the
  /// delivery is undone and **the forklift operator** is the one who has to
  /// put it right and mark it corrected, after which they deliver again.
  ///
  /// A description is required - server-side too - because somebody is
  /// being asked to act on it.
  Future<TransportOrder> reportProblem(String id, {required String reportedBy, required String note}) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/orders/$id/problem',
      data: {'reportedBy': reportedBy, 'note': note},
    );
    return TransportOrder.fromJson(res.data!);
  }

  /// "Problem rozwiązany" - the answer to a problem the forklift operator
  /// reported while fulfilling (`problem -> in_progress`, see wpsApi's
  /// resolveOrderProblem). The order carries on from where it was: the
  /// operator is shown that it was unblocked and gets "Dostarczone" /
  /// "Zgłoś problem" back, so this can legitimately happen more than once
  /// on one order. [note] is optional and goes to the timeline
  /// (`order_events`) rather than onto the order row.
  Future<TransportOrder> resolveProblem(String id, {required String resolvedBy, String note = ''}) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/orders/$id/problem/resolve',
      data: {'resolvedBy': resolvedBy, 'note': note},
    );
    return TransportOrder.fromJson(res.data!);
  }

  /// Attaches one photo to an existing order - multipart POST to wpsApi,
  /// which puts the file in object storage and keeps only its key (see that
  /// repo's src/orderPhotos.js). Sent after the order itself exists,
  /// because the file is stored under the order's own id.
  ///
  /// Bytes rather than a path on purpose: on web an XFile has no real file
  /// path, so reading it into memory is the one thing that works on both
  /// targets this app ships to.
  Future<void> uploadPhoto({
    required String orderId,
    required List<int> bytes,
    required String filename,
    required String contentType,
    required String uploadedBy,
  }) async {
    final subtype = contentType.split('/').last;
    final form = FormData.fromMap({
      'uploadedBy': uploadedBy,
      'photo': MultipartFile.fromBytes(bytes, filename: filename, contentType: DioMediaType('image', subtype)),
    });
    await _dio.post<Map<String, dynamic>>('/orders/$orderId/photo', data: form);
  }
}

final ordersApiProvider = Provider<OrdersApi>((ref) => OrdersApi(ref.watch(authedDioProvider)));
