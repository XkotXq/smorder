/// The plant's real line codes - SH01-07, ST01-13, FC01-03, FL01, same
/// series wpsApi's schema.sql seeds `locations` with (see wps's own
/// LINE_CODES in OrdersCipListTable.js). Used as a fallback before
/// OrdersApi.locations() resolves, and as the fixed picker for every order
/// type but the free-text goods_transport.
// Spelled out since 2026-10-06: the series stopped being regular ranges
// (SH to 13, FC to 8, plus SC/SU/TF/WS). Kept in step with wpsApi's seed
// and wps's own LINE_CODES by hand.
const lineCodes = [
  'SH01', 'SH02', 'SH03', 'SH04', 'SH05', 'SH06', 'SH07', 'SH08',
  'SH09', 'SH10', 'SH11', 'SH12', 'SH13', 'FC01', 'FC02', 'FC03',
  'FC04', 'FC05', 'FC06', 'FC07', 'FC08', 'FL01', 'WS01', 'SC01',
  'SC02', 'SC03', 'SC04', 'SC05', 'SC06', 'SC07', 'SC08', 'TF01',
  'TF02', 'TF03', 'SU01', 'SU02', 'SU03', 'SU04', 'SU05', 'SU06',
  'SU07', 'SU08', 'ST01', 'ST02', 'ST03', 'ST04', 'ST05', 'ST06',
  'ST07',
];
