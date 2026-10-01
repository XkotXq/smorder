///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'strings.g.dart';

// Path: <root>
class TranslationsEn with BaseTranslations<AppLocale, Translations> implements Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsEn({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	/// Access flat map
	@override dynamic operator[](String key) => _meta.getTranslation(key);

	late final TranslationsEn _root = this; // ignore: unused_field

	@override 
	TranslationsEn $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsEn(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$nav$en nav = _Translations$nav$en._(_root);
	@override late final _Translations$login$en login = _Translations$login$en._(_root);
	@override late final _Translations$orders$en orders = _Translations$orders$en._(_root);
	@override late final _Translations$account$en account = _Translations$account$en._(_root);
}

// Path: nav
class _Translations$nav$en implements Translations$nav$pl {
	_Translations$nav$en._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get ordering => 'Ordering';
	@override String get account => 'Account';
}

// Path: login
class _Translations$login$en implements Translations$login$pl {
	_Translations$login$en._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Log in';
	@override String get subtitle => 'smOrder - login panel';
	@override String get usernameLabel => 'Username';
	@override String get passwordLabel => 'Password';
	@override String get submit => 'Log in';
	@override String get submitting => 'Logging in...';
	@override String get missingFields => 'Enter your username and password.';
	@override late final _Translations$login$errors$en errors = _Translations$login$errors$en._(_root);
}

// Path: orders
class _Translations$orders$en implements Translations$orders$pl {
	_Translations$orders$en._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Ordering';
	@override String get empty => 'No orders.';
	@override String get loading => 'Loading...';
	@override String get loadError => 'Failed to load the order list.';
	@override String get retry => 'Try again';
	@override String get scopeActive => 'Active';
	@override String get scopeHistory => 'History';
	@override late final _Translations$orders$types$en types = _Translations$orders$types$en._(_root);
	@override late final _Translations$orders$status$en status = _Translations$orders$status$en._(_root);
	@override late final _Translations$orders$card$en card = _Translations$orders$card$en._(_root);
	@override late final _Translations$orders$detail$en detail = _Translations$orders$detail$en._(_root);
	@override late final _Translations$orders$details$en details = _Translations$orders$details$en._(_root);
	@override late final _Translations$orders$newOrder$en newOrder = _Translations$orders$newOrder$en._(_root);
}

// Path: account
class _Translations$account$en implements Translations$account$pl {
	_Translations$account$en._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get logout => 'Log out';
	@override String get language => 'Language';
	@override String get languagePolish => 'Polski';
	@override String get languageEnglish => 'English';
	@override String get theme => 'Theme';
	@override String get themeSystem => 'System';
	@override String get themeLight => 'Light';
	@override String get themeDark => 'Dark';
}

// Path: login.errors
class _Translations$login$errors$en implements Translations$login$errors$pl {
	_Translations$login$errors$en._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get invalidCredentials => 'Invalid username or password.';
	@override String get cipUnreachable => 'Failed to connect to CIP.';
	@override String get tooManyAttempts => 'Too many login attempts - try again in a moment.';
	@override String get serverUnreachable => 'Failed to connect to the server.';
}

// Path: orders.types
class _Translations$orders$types$en implements Translations$orders$types$pl {
	_Translations$orders$types$en._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get water_refill => 'Water refill';
	@override String get material_order => 'Material order';
	@override String get spool_order => 'Spool order';
	@override String get goods_transport => 'Goods transport';
	@override String get waste_removal => 'Waste removal';
	@override String get warehouse_return => 'Warehouse return';
	@override String get machine_transport => 'Machine transport';
}

// Path: orders.status
class _Translations$orders$status$en implements Translations$orders$status$pl {
	_Translations$orders$status$en._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get kNew => 'New';
	@override String get inProgress => 'In progress';
	@override String get delivered => 'Delivered';
	@override String get done => 'Completed';
	@override String get cancelled => 'Cancelled';
	@override String get problem => 'Problem';
}

// Path: orders.card
class _Translations$orders$card$en implements Translations$orders$card$pl {
	_Translations$orders$card$en._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get employeeNo => 'Requested by';
	@override String get problemNeedsYou => 'Needs your response';
	@override String get problemWithVendor => 'With the forklift operator';
}

// Path: orders.detail
class _Translations$orders$detail$en implements Translations$orders$detail$pl {
	_Translations$orders$detail$en._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get line => 'Line';
	@override String get productionOrderNo => 'Order number';
	@override String get employeeNo => 'Requested by';
	@override String get takenBy => 'Taken by';
	@override String get deliveredBy => 'Delivered by';
	@override String get fulfilledBy => 'Fulfilled by';
	@override String get createdAt => 'Created at';
	@override String get itemsTitle => 'Items';
	@override String get problemReported => 'Problem reported';
	@override String get photoUnavailable => 'The photo is unavailable right now.';
	@override String autoAcceptIn({required Object time}) => 'Confirms itself in ${time} if you do nothing.';
	@override String get autoAcceptPlain => 'Confirms itself if you do nothing.';
	@override String get accept => 'Confirm';
	@override String get acceptError => 'Could not confirm receipt.';
	@override String get reportProblem => 'Report a problem';
	@override String get problemTitle => 'Report a problem';
	@override String get problemDescription => 'Describe what is wrong with the delivery. The operator will put it right and mark it done - the order is not cancelled.';
	@override String get problemPlaceholder => 'What is wrong?';
	@override String get problemSubmit => 'Report';
	@override String get problemCancel => 'Cancel';
	@override String get problemError => 'Could not report the problem.';
	@override String get problemFromVendor => 'The forklift operator reported a problem';
	@override String problemBy({required Object who}) => 'reported by ${who}';
	@override String get problemWaitingOnYou => 'This order is waiting on you - the forklift operator cannot finish it.';
	@override String get problemResolve => 'Problem solved';
	@override String get problemResolvedTitle => 'Problem solved';
	@override String get resolveError => 'Could not mark the problem as solved.';
	@override String get chat => 'Chat';
	@override String get chatSoon => 'soon';
	@override String get problemMine => 'Problem reported - waiting for the forklift operator';
	@override String get problemWaitingOnVendor => 'The forklift operator will put it right and mark it done.';
}

// Path: orders.details
class _Translations$orders$details$en implements Translations$orders$details$pl {
	_Translations$orders$details$en._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get water => 'Water type';
	@override String get clean => 'Clean water';
	@override String get dirty => 'Mauser for dirty water';
	@override String get productionOrderNo => 'Order number';
}

// Path: orders.newOrder
class _Translations$orders$newOrder$en implements Translations$orders$newOrder$pl {
	_Translations$orders$newOrder$en._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get button => 'New order';
	@override String get pickType => 'Pick an order type';
	@override String titleFor({required Object type}) => 'New order: ${type}';
	@override String get fieldFrom => 'From';
	@override String get fieldPlace => 'Place';
	@override String get fieldCollectFrom => 'Collect from';
	@override String get fieldTo => 'To';
	@override String get fieldToShort => 'To';
	@override String get items => 'Materials';
	@override String get itemSearchPlaceholder => 'Search by number or name...';
	@override String get itemSearchEmpty => 'No results.';
	@override String get note => 'Note';
	@override String get notePlaceholder => 'Additional information (optional)';
	@override String get photo => 'Photo (optional)';
	@override String get photoTake => 'Take a photo';
	@override String get photoPick => 'From gallery';
	@override String get photoError => 'Could not get the photo.';
	@override String photoUploadError({required Object orderNo}) => 'Order ${orderNo} was placed, but the photo could not be uploaded.';
	@override String get submit => 'Place order';
	@override String get submitError => 'Failed to place the order.';
	@override String get cipOrderNoHint => 'The full number isn\'t needed - the ending is enough, e.g. the last 6 digits.';
	@override String get cipOrderNoPlaceholder => 'e.g. 9016501';
	@override String get cipSearch => 'Search';
	@override String get cipSearching => 'Searching...';
	@override String get cipMaterialsTitle => 'Materials on this order';
	@override String get cipNeeded => 'needed';
	@override String cipChangedFrom({required Object from}) => 'Material changed from ${from}';
	@override String get cipNoMaterials => 'This order has no materials from this warehouse.';
	@override String get cipOrderNotFound => 'No such order found in CIP.';
	@override String get cipSessionExpired => 'The CIP session expired - log out and log in again.';
	@override String get cipUnreachable => 'Failed to connect to CIP.';
	@override String get linePick => 'Pick a line';
	@override String get itemsChosen => 'To bring';
	@override String get noteAdd => 'Add a note';
	@override String submitWithItems({required Object count}) => 'Place order (${count} items)';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsEn {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'nav.ordering' => 'Ordering',
			'nav.account' => 'Account',
			'login.title' => 'Log in',
			'login.subtitle' => 'smOrder - login panel',
			'login.usernameLabel' => 'Username',
			'login.passwordLabel' => 'Password',
			'login.submit' => 'Log in',
			'login.submitting' => 'Logging in...',
			'login.missingFields' => 'Enter your username and password.',
			'login.errors.invalidCredentials' => 'Invalid username or password.',
			'login.errors.cipUnreachable' => 'Failed to connect to CIP.',
			'login.errors.tooManyAttempts' => 'Too many login attempts - try again in a moment.',
			'login.errors.serverUnreachable' => 'Failed to connect to the server.',
			'orders.title' => 'Ordering',
			'orders.empty' => 'No orders.',
			'orders.loading' => 'Loading...',
			'orders.loadError' => 'Failed to load the order list.',
			'orders.retry' => 'Try again',
			'orders.scopeActive' => 'Active',
			'orders.scopeHistory' => 'History',
			'orders.types.water_refill' => 'Water refill',
			'orders.types.material_order' => 'Material order',
			'orders.types.spool_order' => 'Spool order',
			'orders.types.goods_transport' => 'Goods transport',
			'orders.types.waste_removal' => 'Waste removal',
			'orders.types.warehouse_return' => 'Warehouse return',
			'orders.types.machine_transport' => 'Machine transport',
			'orders.status.kNew' => 'New',
			'orders.status.inProgress' => 'In progress',
			'orders.status.delivered' => 'Delivered',
			'orders.status.done' => 'Completed',
			'orders.status.cancelled' => 'Cancelled',
			'orders.status.problem' => 'Problem',
			'orders.card.employeeNo' => 'Requested by',
			'orders.card.problemNeedsYou' => 'Needs your response',
			'orders.card.problemWithVendor' => 'With the forklift operator',
			'orders.detail.line' => 'Line',
			'orders.detail.productionOrderNo' => 'Order number',
			'orders.detail.employeeNo' => 'Requested by',
			'orders.detail.takenBy' => 'Taken by',
			'orders.detail.deliveredBy' => 'Delivered by',
			'orders.detail.fulfilledBy' => 'Fulfilled by',
			'orders.detail.createdAt' => 'Created at',
			'orders.detail.itemsTitle' => 'Items',
			'orders.detail.problemReported' => 'Problem reported',
			'orders.detail.photoUnavailable' => 'The photo is unavailable right now.',
			'orders.detail.autoAcceptIn' => ({required Object time}) => 'Confirms itself in ${time} if you do nothing.',
			'orders.detail.autoAcceptPlain' => 'Confirms itself if you do nothing.',
			'orders.detail.accept' => 'Confirm',
			'orders.detail.acceptError' => 'Could not confirm receipt.',
			'orders.detail.reportProblem' => 'Report a problem',
			'orders.detail.problemTitle' => 'Report a problem',
			'orders.detail.problemDescription' => 'Describe what is wrong with the delivery. The operator will put it right and mark it done - the order is not cancelled.',
			'orders.detail.problemPlaceholder' => 'What is wrong?',
			'orders.detail.problemSubmit' => 'Report',
			'orders.detail.problemCancel' => 'Cancel',
			'orders.detail.problemError' => 'Could not report the problem.',
			'orders.detail.problemFromVendor' => 'The forklift operator reported a problem',
			'orders.detail.problemBy' => ({required Object who}) => 'reported by ${who}',
			'orders.detail.problemWaitingOnYou' => 'This order is waiting on you - the forklift operator cannot finish it.',
			'orders.detail.problemResolve' => 'Problem solved',
			'orders.detail.problemResolvedTitle' => 'Problem solved',
			'orders.detail.resolveError' => 'Could not mark the problem as solved.',
			'orders.detail.chat' => 'Chat',
			'orders.detail.chatSoon' => 'soon',
			'orders.detail.problemMine' => 'Problem reported - waiting for the forklift operator',
			'orders.detail.problemWaitingOnVendor' => 'The forklift operator will put it right and mark it done.',
			'orders.details.water' => 'Water type',
			'orders.details.clean' => 'Clean water',
			'orders.details.dirty' => 'Mauser for dirty water',
			'orders.details.productionOrderNo' => 'Order number',
			'orders.newOrder.button' => 'New order',
			'orders.newOrder.pickType' => 'Pick an order type',
			'orders.newOrder.titleFor' => ({required Object type}) => 'New order: ${type}',
			'orders.newOrder.fieldFrom' => 'From',
			'orders.newOrder.fieldPlace' => 'Place',
			'orders.newOrder.fieldCollectFrom' => 'Collect from',
			'orders.newOrder.fieldTo' => 'To',
			'orders.newOrder.fieldToShort' => 'To',
			'orders.newOrder.items' => 'Materials',
			'orders.newOrder.itemSearchPlaceholder' => 'Search by number or name...',
			'orders.newOrder.itemSearchEmpty' => 'No results.',
			'orders.newOrder.note' => 'Note',
			'orders.newOrder.notePlaceholder' => 'Additional information (optional)',
			'orders.newOrder.photo' => 'Photo (optional)',
			'orders.newOrder.photoTake' => 'Take a photo',
			'orders.newOrder.photoPick' => 'From gallery',
			'orders.newOrder.photoError' => 'Could not get the photo.',
			'orders.newOrder.photoUploadError' => ({required Object orderNo}) => 'Order ${orderNo} was placed, but the photo could not be uploaded.',
			'orders.newOrder.submit' => 'Place order',
			'orders.newOrder.submitError' => 'Failed to place the order.',
			'orders.newOrder.cipOrderNoHint' => 'The full number isn\'t needed - the ending is enough, e.g. the last 6 digits.',
			'orders.newOrder.cipOrderNoPlaceholder' => 'e.g. 9016501',
			'orders.newOrder.cipSearch' => 'Search',
			'orders.newOrder.cipSearching' => 'Searching...',
			'orders.newOrder.cipMaterialsTitle' => 'Materials on this order',
			'orders.newOrder.cipNeeded' => 'needed',
			'orders.newOrder.cipChangedFrom' => ({required Object from}) => 'Material changed from ${from}',
			'orders.newOrder.cipNoMaterials' => 'This order has no materials from this warehouse.',
			'orders.newOrder.cipOrderNotFound' => 'No such order found in CIP.',
			'orders.newOrder.cipSessionExpired' => 'The CIP session expired - log out and log in again.',
			'orders.newOrder.cipUnreachable' => 'Failed to connect to CIP.',
			'orders.newOrder.linePick' => 'Pick a line',
			'orders.newOrder.itemsChosen' => 'To bring',
			'orders.newOrder.noteAdd' => 'Add a note',
			'orders.newOrder.submitWithItems' => ({required Object count}) => 'Place order (${count} items)',
			'account.logout' => 'Log out',
			'account.language' => 'Language',
			'account.languagePolish' => 'Polski',
			'account.languageEnglish' => 'English',
			'account.theme' => 'Theme',
			'account.themeSystem' => 'System',
			'account.themeLight' => 'Light',
			'account.themeDark' => 'Dark',
			_ => null,
		};
	}
}
