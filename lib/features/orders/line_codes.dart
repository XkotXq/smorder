/// The plant's real line codes - SH01-07, ST01-13, FC01-03, FL01, same
/// series wpsApi's schema.sql seeds `locations` with (see wps's own
/// LINE_CODES in OrdersCipListTable.js). Used as a fallback before
/// OrdersApi.locations() resolves, and as the fixed picker for every order
/// type but the free-text goods_transport.
final lineCodes = [
  for (var i = 1; i <= 7; i++) 'SH0$i',
  for (var i = 1; i <= 13; i++) 'ST${i.toString().padLeft(2, '0')}',
  'FC01',
  'FC02',
  'FC03',
  'FL01',
];
