///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'strings.g.dart';

// Path: <root>
typedef TranslationsPl = Translations; // ignore: unused_element
class Translations with BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.pl,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <pl>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	/// Access flat map
	dynamic operator[](String key) => _meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations
	late final Translations$nav$pl nav = Translations$nav$pl._(_root);
	late final Translations$login$pl login = Translations$login$pl._(_root);
	late final Translations$orders$pl orders = Translations$orders$pl._(_root);
	late final Translations$account$pl account = Translations$account$pl._(_root);
}

// Path: nav
class Translations$nav$pl {
	Translations$nav$pl._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// pl: 'Zamawianie'
	String get ordering => 'Zamawianie';

	/// pl: 'Konto'
	String get account => 'Konto';
}

// Path: login
class Translations$login$pl {
	Translations$login$pl._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// pl: 'Zaloguj się'
	String get title => 'Zaloguj się';

	/// pl: 'smOrder - panel logowania'
	String get subtitle => 'smOrder - panel logowania';

	/// pl: 'Login'
	String get usernameLabel => 'Login';

	/// pl: 'Hasło'
	String get passwordLabel => 'Hasło';

	/// pl: 'Zaloguj się'
	String get submit => 'Zaloguj się';

	/// pl: 'Logowanie...'
	String get submitting => 'Logowanie...';

	/// pl: 'Wpisz login i hasło.'
	String get missingFields => 'Wpisz login i hasło.';

	late final Translations$login$errors$pl errors = Translations$login$errors$pl._(_root);
}

// Path: orders
class Translations$orders$pl {
	Translations$orders$pl._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// pl: 'Zamawianie'
	String get title => 'Zamawianie';

	/// pl: 'Brak zamówień.'
	String get empty => 'Brak zamówień.';

	/// pl: 'Wczytywanie...'
	String get loading => 'Wczytywanie...';

	/// pl: 'Nie udało się pobrać listy zamówień.'
	String get loadError => 'Nie udało się pobrać listy zamówień.';

	/// pl: 'Spróbuj ponownie'
	String get retry => 'Spróbuj ponownie';

	/// pl: 'Aktywne'
	String get scopeActive => 'Aktywne';

	/// pl: 'Historia'
	String get scopeHistory => 'Historia';

	late final Translations$orders$types$pl types = Translations$orders$types$pl._(_root);
	late final Translations$orders$status$pl status = Translations$orders$status$pl._(_root);
	late final Translations$orders$card$pl card = Translations$orders$card$pl._(_root);
	late final Translations$orders$detail$pl detail = Translations$orders$detail$pl._(_root);
	late final Translations$orders$details$pl details = Translations$orders$details$pl._(_root);
	late final Translations$orders$newOrder$pl newOrder = Translations$orders$newOrder$pl._(_root);

	/// pl: 'Problem'
	String get sectionProblem => 'Problem';

	/// pl: 'Oczekujące na akceptację'
	String get sectionAwaitingAccept => 'Oczekujące na akceptację';

	/// pl: 'Obecnie realizowane'
	String get sectionInProgress => 'Obecnie realizowane';

	/// pl: 'Nowe'
	String get sectionNew => 'Nowe';

	late final Translations$orders$chat$pl chat = Translations$orders$chat$pl._(_root);
	late final Translations$orders$history$pl history = Translations$orders$history$pl._(_root);
	late final Translations$orders$priority$pl priority = Translations$orders$priority$pl._(_root);
}

// Path: account
class Translations$account$pl {
	Translations$account$pl._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// pl: 'Wyloguj'
	String get logout => 'Wyloguj';

	/// pl: 'Język'
	String get language => 'Język';

	/// pl: 'Polski'
	String get languagePolish => 'Polski';

	/// pl: 'English'
	String get languageEnglish => 'English';

	/// pl: 'Motyw'
	String get theme => 'Motyw';

	/// pl: 'Systemowy'
	String get themeSystem => 'Systemowy';

	/// pl: 'Jasny'
	String get themeLight => 'Jasny';

	/// pl: 'Ciemny'
	String get themeDark => 'Ciemny';
}

// Path: login.errors
class Translations$login$errors$pl {
	Translations$login$errors$pl._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// pl: 'Nieprawidłowy login lub hasło.'
	String get invalidCredentials => 'Nieprawidłowy login lub hasło.';

	/// pl: 'Nie udało się połączyć z CIP.'
	String get cipUnreachable => 'Nie udało się połączyć z CIP.';

	/// pl: 'Zbyt wiele prób logowania - spróbuj ponownie za chwilę.'
	String get tooManyAttempts => 'Zbyt wiele prób logowania - spróbuj ponownie za chwilę.';

	/// pl: 'Nie udało się połączyć z serwerem.'
	String get serverUnreachable => 'Nie udało się połączyć z serwerem.';
}

// Path: orders.types
class Translations$orders$types$pl {
	Translations$orders$types$pl._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// pl: 'Dolewanie wody'
	String get water_refill => 'Dolewanie wody';

	/// pl: 'Zamówienie materiału'
	String get material_order => 'Zamówienie materiału';

	/// pl: 'Zamówienie szpul'
	String get spool_order => 'Zamówienie szpul';

	/// pl: 'Transport półproduktów'
	String get goods_transport => 'Transport półproduktów';

	/// pl: 'Wywożenie odpadu'
	String get waste_removal => 'Wywożenie odpadu';

	/// pl: 'Zwrot na magazyn'
	String get warehouse_return => 'Zwrot na magazyn';

	/// pl: 'Przewóz maszyny'
	String get machine_transport => 'Przewóz maszyny';
}

// Path: orders.status
class Translations$orders$status$pl {
	Translations$orders$status$pl._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// pl: 'Nowe'
	String get kNew => 'Nowe';

	/// pl: 'W realizacji'
	String get inProgress => 'W realizacji';

	/// pl: 'Dostarczone'
	String get delivered => 'Dostarczone';

	/// pl: 'Zrealizowane'
	String get done => 'Zrealizowane';

	/// pl: 'Anulowane'
	String get cancelled => 'Anulowane';

	/// pl: 'Problem'
	String get problem => 'Problem';
}

// Path: orders.card
class Translations$orders$card$pl {
	Translations$orders$card$pl._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// pl: 'Zlecający'
	String get employeeNo => 'Zlecający';

	/// pl: 'Wymaga Twojej reakcji'
	String get problemNeedsYou => 'Wymaga Twojej reakcji';

	/// pl: 'Czeka na wózkowego'
	String get problemWithVendor => 'Czeka na wózkowego';
}

// Path: orders.detail
class Translations$orders$detail$pl {
	Translations$orders$detail$pl._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// pl: 'Linia'
	String get line => 'Linia';

	/// pl: 'Numer zamówienia'
	String get productionOrderNo => 'Numer zamówienia';

	/// pl: 'Zlecający'
	String get employeeNo => 'Zlecający';

	/// pl: 'Przyjął'
	String get takenBy => 'Przyjął';

	/// pl: 'Dostarczył'
	String get deliveredBy => 'Dostarczył';

	/// pl: 'Zrealizował'
	String get fulfilledBy => 'Zrealizował';

	/// pl: 'Utworzono'
	String get createdAt => 'Utworzono';

	/// pl: 'Pozycje'
	String get itemsTitle => 'Pozycje';

	/// pl: 'Zgłoszono problem'
	String get problemReported => 'Zgłoszono problem';

	/// pl: 'Zdjęcie jest chwilowo niedostępne.'
	String get photoUnavailable => 'Zdjęcie jest chwilowo niedostępne.';

	/// pl: 'Automatycznie potwierdzi się za {time}'
	String autoAcceptIn({required Object time}) => 'Automatycznie potwierdzi się za ${time}';

	/// pl: 'Automatycznie potwierdzi się'
	String get autoAcceptPlain => 'Automatycznie potwierdzi się';

	/// pl: 'Zgadza się'
	String get accept => 'Zgadza się';

	/// pl: 'Nie udało się potwierdzić odbioru.'
	String get acceptError => 'Nie udało się potwierdzić odbioru.';

	/// pl: 'Zgłoś problem'
	String get reportProblem => 'Zgłoś problem';

	/// pl: 'Zgłoszenie problemu'
	String get problemTitle => 'Zgłoszenie problemu';

	/// pl: 'Napisz, co jest nie tak z dostawą.'
	String get problemDescription => 'Napisz, co jest nie tak z dostawą.';

	/// pl: 'Opis problemu - co jest nie tak?'
	String get problemPlaceholder => 'Opis problemu - co jest nie tak?';

	/// pl: 'Zgłoś'
	String get problemSubmit => 'Zgłoś';

	/// pl: 'Anuluj'
	String get problemCancel => 'Anuluj';

	/// pl: 'Nie udało się zgłosić problemu.'
	String get problemError => 'Nie udało się zgłosić problemu.';

	/// pl: 'Wózkowy zgłosił problem'
	String get problemFromVendor => 'Wózkowy zgłosił problem';

	/// pl: 'zgłosił {who}'
	String problemBy({required Object who}) => 'zgłosił ${who}';

	/// pl: 'Problem rozwiązany'
	String get problemResolve => 'Problem rozwiązany';

	/// pl: 'Problem rozwiązany'
	String get problemResolvedTitle => 'Problem rozwiązany';

	/// pl: 'Nie udało się oznaczyć problemu jako rozwiązanego.'
	String get resolveError => 'Nie udało się oznaczyć problemu jako rozwiązanego.';

	/// pl: 'Czat'
	String get chat => 'Czat';

	/// pl: 'Zgłoszono problem - czeka na wózkowego'
	String get problemMine => 'Zgłoszono problem - czeka na wózkowego';

	/// pl: 'Edytuj'
	String get edit => 'Edytuj';

	/// pl: 'Nie udało się otworzyć edycji.'
	String get editError => 'Nie udało się otworzyć edycji.';

	/// pl: 'Anuluj'
	String get cancelOrder => 'Anuluj';

	/// pl: 'Anulowanie zamówienia'
	String get cancelTitle => 'Anulowanie zamówienia';

	/// pl: 'Powód anulowania'
	String get cancelPlaceholder => 'Powód anulowania';

	/// pl: 'Anuluj zamówienie'
	String get cancelConfirm => 'Anuluj zamówienie';

	/// pl: 'Nie udało się anulować zamówienia.'
	String get cancelError => 'Nie udało się anulować zamówienia.';

	/// pl: 'Usunąć zamówienie?'
	String get deleteTitle => 'Usunąć zamówienie?';

	/// pl: 'Zamówienie zniknie bez śladu. Jeżeli ma zostać w historii, anuluj je z powodem.'
	String get deleteDescription => 'Zamówienie zniknie bez śladu. Jeżeli ma zostać w historii, anuluj je z powodem.';

	/// pl: 'Usuń'
	String get deleteConfirm => 'Usuń';

	/// pl: 'Nie udało się usunąć zamówienia.'
	String get deleteError => 'Nie udało się usunąć zamówienia.';
}

// Path: orders.details
class Translations$orders$details$pl {
	Translations$orders$details$pl._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// pl: 'Rodzaj wody'
	String get water => 'Rodzaj wody';

	/// pl: 'Czysta woda'
	String get clean => 'Czysta woda';

	/// pl: 'Mauzer na brudną wodę'
	String get dirty => 'Mauzer na brudną wodę';

	/// pl: 'Numer zamówienia'
	String get productionOrderNo => 'Numer zamówienia';
}

// Path: orders.newOrder
class Translations$orders$newOrder$pl {
	Translations$orders$newOrder$pl._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// pl: 'Nowe zamówienie'
	String get button => 'Nowe zamówienie';

	/// pl: 'Wybierz typ zamówienia'
	String get pickType => 'Wybierz typ zamówienia';

	/// pl: 'Skąd'
	String get fieldFrom => 'Skąd';

	/// pl: 'Miejsce'
	String get fieldPlace => 'Miejsce';

	/// pl: 'Gdzie odebrać'
	String get fieldCollectFrom => 'Gdzie odebrać';

	/// pl: 'Dokąd'
	String get fieldTo => 'Dokąd';

	/// pl: 'Dokąd'
	String get fieldToShort => 'Dokąd';

	/// pl: 'Materiały'
	String get items => 'Materiały';

	/// pl: 'Szukaj po numerze lub nazwie...'
	String get itemSearchPlaceholder => 'Szukaj po numerze lub nazwie...';

	/// pl: 'Brak wyników.'
	String get itemSearchEmpty => 'Brak wyników.';

	/// pl: 'Uwagi'
	String get note => 'Uwagi';

	/// pl: 'Dodatkowe informacje (opcjonalnie)'
	String get notePlaceholder => 'Dodatkowe informacje (opcjonalnie)';

	/// pl: 'Zdjęcie (opcjonalnie)'
	String get photo => 'Zdjęcie (opcjonalnie)';

	/// pl: 'Zrób zdjęcie'
	String get photoTake => 'Zrób zdjęcie';

	/// pl: 'Z galerii'
	String get photoPick => 'Z galerii';

	/// pl: 'Nie udało się pobrać zdjęcia.'
	String get photoError => 'Nie udało się pobrać zdjęcia.';

	/// pl: 'Zamówienie {orderNo} zostało złożone, ale nie udało się wysłać zdjęcia.'
	String photoUploadError({required Object orderNo}) => 'Zamówienie ${orderNo} zostało złożone, ale nie udało się wysłać zdjęcia.';

	/// pl: 'Złóż zamówienie'
	String get submit => 'Złóż zamówienie';

	/// pl: 'Nie udało się złożyć zamówienia.'
	String get submitError => 'Nie udało się złożyć zamówienia.';

	/// pl: 'Nie musisz wpisywać całego numeru - wystarczy końcówka, np. 6 ostatnich cyfr.'
	String get cipOrderNoHint => 'Nie musisz wpisywać całego numeru - wystarczy końcówka, np. 6 ostatnich cyfr.';

	/// pl: 'np. 9016501'
	String get cipOrderNoPlaceholder => 'np. 9016501';

	/// pl: 'Szukaj'
	String get cipSearch => 'Szukaj';

	/// pl: 'Szukam...'
	String get cipSearching => 'Szukam...';

	/// pl: 'Materiały z tego zamówienia'
	String get cipMaterialsTitle => 'Materiały z tego zamówienia';

	/// pl: 'potrzebne'
	String get cipNeeded => 'potrzebne';

	/// pl: 'Materiał zmieniony z {from}'
	String cipChangedFrom({required Object from}) => 'Materiał zmieniony z ${from}';

	/// pl: 'To zamówienie nie ma materiałów z tego magazynu.'
	String get cipNoMaterials => 'To zamówienie nie ma materiałów z tego magazynu.';

	/// pl: 'Nie znaleziono takiego zamówienia w CIP.'
	String get cipOrderNotFound => 'Nie znaleziono takiego zamówienia w CIP.';

	/// pl: 'Sesja CIP wygasła - wyloguj się i zaloguj ponownie.'
	String get cipSessionExpired => 'Sesja CIP wygasła - wyloguj się i zaloguj ponownie.';

	/// pl: 'Nie udało się połączyć z CIP.'
	String get cipUnreachable => 'Nie udało się połączyć z CIP.';

	/// pl: 'Wybierz linię'
	String get linePick => 'Wybierz linię';

	/// pl: 'Zamawiasz'
	String get itemsChosen => 'Zamawiasz';

	/// pl: 'Dodaj uwagę'
	String get noteAdd => 'Dodaj uwagę';

	/// pl: 'Złóż zamówienie ({count} poz.)'
	String submitWithItems({required Object count}) => 'Złóż zamówienie (${count} poz.)';

	/// pl: 'Zapisz zmiany'
	String get save => 'Zapisz zmiany';

	/// pl: 'Edycja: {type}'
	String editTitleFor({required Object type}) => 'Edycja: ${type}';

	/// pl: 'Szpule z tego zamówienia'
	String get cipSpoolsTitle => 'Szpule z tego zamówienia';

	/// pl: 'To zamówienie nie ma przypisanej szpuli.'
	String get cipNoSpools => 'To zamówienie nie ma przypisanej szpuli.';

	/// pl: 'Zamień skąd i dokąd'
	String get swapPlaces => 'Zamień skąd i dokąd';
}

// Path: orders.chat
class Translations$orders$chat$pl {
	Translations$orders$chat$pl._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// pl: 'Czat'
	String get title => 'Czat';

	/// pl: 'Napisz wiadomość...'
	String get placeholder => 'Napisz wiadomość...';

	/// pl: 'Brak wiadomości.'
	String get empty => 'Brak wiadomości.';

	/// pl: 'Nie udało się pobrać czatu.'
	String get loadError => 'Nie udało się pobrać czatu.';

	/// pl: 'Nie udało się wysłać wiadomości.'
	String get sendError => 'Nie udało się wysłać wiadomości.';
}

// Path: orders.history
class Translations$orders$history$pl {
	Translations$orders$history$pl._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// pl: 'To już wszystko.'
	String get allLoaded => 'To już wszystko.';
}

// Path: orders.priority
class Translations$orders$priority$pl {
	Translations$orders$priority$pl._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// pl: 'Priorytet'
	String get label => 'Priorytet';

	/// pl: 'Zwykły'
	String get normal => 'Zwykły';

	/// pl: 'Pilny'
	String get urgent => 'Pilny';

	/// pl: 'Bardzo pilny'
	String get critical => 'Bardzo pilny';
}

/// The flat map containing all translations for locale <pl>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'nav.ordering' => 'Zamawianie',
			'nav.account' => 'Konto',
			'login.title' => 'Zaloguj się',
			'login.subtitle' => 'smOrder - panel logowania',
			'login.usernameLabel' => 'Login',
			'login.passwordLabel' => 'Hasło',
			'login.submit' => 'Zaloguj się',
			'login.submitting' => 'Logowanie...',
			'login.missingFields' => 'Wpisz login i hasło.',
			'login.errors.invalidCredentials' => 'Nieprawidłowy login lub hasło.',
			'login.errors.cipUnreachable' => 'Nie udało się połączyć z CIP.',
			'login.errors.tooManyAttempts' => 'Zbyt wiele prób logowania - spróbuj ponownie za chwilę.',
			'login.errors.serverUnreachable' => 'Nie udało się połączyć z serwerem.',
			'orders.title' => 'Zamawianie',
			'orders.empty' => 'Brak zamówień.',
			'orders.loading' => 'Wczytywanie...',
			'orders.loadError' => 'Nie udało się pobrać listy zamówień.',
			'orders.retry' => 'Spróbuj ponownie',
			'orders.scopeActive' => 'Aktywne',
			'orders.scopeHistory' => 'Historia',
			'orders.types.water_refill' => 'Dolewanie wody',
			'orders.types.material_order' => 'Zamówienie materiału',
			'orders.types.spool_order' => 'Zamówienie szpul',
			'orders.types.goods_transport' => 'Transport półproduktów',
			'orders.types.waste_removal' => 'Wywożenie odpadu',
			'orders.types.warehouse_return' => 'Zwrot na magazyn',
			'orders.types.machine_transport' => 'Przewóz maszyny',
			'orders.status.kNew' => 'Nowe',
			'orders.status.inProgress' => 'W realizacji',
			'orders.status.delivered' => 'Dostarczone',
			'orders.status.done' => 'Zrealizowane',
			'orders.status.cancelled' => 'Anulowane',
			'orders.status.problem' => 'Problem',
			'orders.card.employeeNo' => 'Zlecający',
			'orders.card.problemNeedsYou' => 'Wymaga Twojej reakcji',
			'orders.card.problemWithVendor' => 'Czeka na wózkowego',
			'orders.detail.line' => 'Linia',
			'orders.detail.productionOrderNo' => 'Numer zamówienia',
			'orders.detail.employeeNo' => 'Zlecający',
			'orders.detail.takenBy' => 'Przyjął',
			'orders.detail.deliveredBy' => 'Dostarczył',
			'orders.detail.fulfilledBy' => 'Zrealizował',
			'orders.detail.createdAt' => 'Utworzono',
			'orders.detail.itemsTitle' => 'Pozycje',
			'orders.detail.problemReported' => 'Zgłoszono problem',
			'orders.detail.photoUnavailable' => 'Zdjęcie jest chwilowo niedostępne.',
			'orders.detail.autoAcceptIn' => ({required Object time}) => 'Automatycznie potwierdzi się za ${time}',
			'orders.detail.autoAcceptPlain' => 'Automatycznie potwierdzi się',
			'orders.detail.accept' => 'Zgadza się',
			'orders.detail.acceptError' => 'Nie udało się potwierdzić odbioru.',
			'orders.detail.reportProblem' => 'Zgłoś problem',
			'orders.detail.problemTitle' => 'Zgłoszenie problemu',
			'orders.detail.problemDescription' => 'Napisz, co jest nie tak z dostawą.',
			'orders.detail.problemPlaceholder' => 'Opis problemu - co jest nie tak?',
			'orders.detail.problemSubmit' => 'Zgłoś',
			'orders.detail.problemCancel' => 'Anuluj',
			'orders.detail.problemError' => 'Nie udało się zgłosić problemu.',
			'orders.detail.problemFromVendor' => 'Wózkowy zgłosił problem',
			'orders.detail.problemBy' => ({required Object who}) => 'zgłosił ${who}',
			'orders.detail.problemResolve' => 'Problem rozwiązany',
			'orders.detail.problemResolvedTitle' => 'Problem rozwiązany',
			'orders.detail.resolveError' => 'Nie udało się oznaczyć problemu jako rozwiązanego.',
			'orders.detail.chat' => 'Czat',
			'orders.detail.problemMine' => 'Zgłoszono problem - czeka na wózkowego',
			'orders.detail.edit' => 'Edytuj',
			'orders.detail.editError' => 'Nie udało się otworzyć edycji.',
			'orders.detail.cancelOrder' => 'Anuluj',
			'orders.detail.cancelTitle' => 'Anulowanie zamówienia',
			'orders.detail.cancelPlaceholder' => 'Powód anulowania',
			'orders.detail.cancelConfirm' => 'Anuluj zamówienie',
			'orders.detail.cancelError' => 'Nie udało się anulować zamówienia.',
			'orders.detail.deleteTitle' => 'Usunąć zamówienie?',
			'orders.detail.deleteDescription' => 'Zamówienie zniknie bez śladu. Jeżeli ma zostać w historii, anuluj je z powodem.',
			'orders.detail.deleteConfirm' => 'Usuń',
			'orders.detail.deleteError' => 'Nie udało się usunąć zamówienia.',
			'orders.details.water' => 'Rodzaj wody',
			'orders.details.clean' => 'Czysta woda',
			'orders.details.dirty' => 'Mauzer na brudną wodę',
			'orders.details.productionOrderNo' => 'Numer zamówienia',
			'orders.newOrder.button' => 'Nowe zamówienie',
			'orders.newOrder.pickType' => 'Wybierz typ zamówienia',
			'orders.newOrder.fieldFrom' => 'Skąd',
			'orders.newOrder.fieldPlace' => 'Miejsce',
			'orders.newOrder.fieldCollectFrom' => 'Gdzie odebrać',
			'orders.newOrder.fieldTo' => 'Dokąd',
			'orders.newOrder.fieldToShort' => 'Dokąd',
			'orders.newOrder.items' => 'Materiały',
			'orders.newOrder.itemSearchPlaceholder' => 'Szukaj po numerze lub nazwie...',
			'orders.newOrder.itemSearchEmpty' => 'Brak wyników.',
			'orders.newOrder.note' => 'Uwagi',
			'orders.newOrder.notePlaceholder' => 'Dodatkowe informacje (opcjonalnie)',
			'orders.newOrder.photo' => 'Zdjęcie (opcjonalnie)',
			'orders.newOrder.photoTake' => 'Zrób zdjęcie',
			'orders.newOrder.photoPick' => 'Z galerii',
			'orders.newOrder.photoError' => 'Nie udało się pobrać zdjęcia.',
			'orders.newOrder.photoUploadError' => ({required Object orderNo}) => 'Zamówienie ${orderNo} zostało złożone, ale nie udało się wysłać zdjęcia.',
			'orders.newOrder.submit' => 'Złóż zamówienie',
			'orders.newOrder.submitError' => 'Nie udało się złożyć zamówienia.',
			'orders.newOrder.cipOrderNoHint' => 'Nie musisz wpisywać całego numeru - wystarczy końcówka, np. 6 ostatnich cyfr.',
			'orders.newOrder.cipOrderNoPlaceholder' => 'np. 9016501',
			'orders.newOrder.cipSearch' => 'Szukaj',
			'orders.newOrder.cipSearching' => 'Szukam...',
			'orders.newOrder.cipMaterialsTitle' => 'Materiały z tego zamówienia',
			'orders.newOrder.cipNeeded' => 'potrzebne',
			'orders.newOrder.cipChangedFrom' => ({required Object from}) => 'Materiał zmieniony z ${from}',
			'orders.newOrder.cipNoMaterials' => 'To zamówienie nie ma materiałów z tego magazynu.',
			'orders.newOrder.cipOrderNotFound' => 'Nie znaleziono takiego zamówienia w CIP.',
			'orders.newOrder.cipSessionExpired' => 'Sesja CIP wygasła - wyloguj się i zaloguj ponownie.',
			'orders.newOrder.cipUnreachable' => 'Nie udało się połączyć z CIP.',
			'orders.newOrder.linePick' => 'Wybierz linię',
			'orders.newOrder.itemsChosen' => 'Zamawiasz',
			'orders.newOrder.noteAdd' => 'Dodaj uwagę',
			'orders.newOrder.submitWithItems' => ({required Object count}) => 'Złóż zamówienie (${count} poz.)',
			'orders.newOrder.save' => 'Zapisz zmiany',
			'orders.newOrder.editTitleFor' => ({required Object type}) => 'Edycja: ${type}',
			'orders.newOrder.cipSpoolsTitle' => 'Szpule z tego zamówienia',
			'orders.newOrder.cipNoSpools' => 'To zamówienie nie ma przypisanej szpuli.',
			'orders.newOrder.swapPlaces' => 'Zamień skąd i dokąd',
			'orders.sectionProblem' => 'Problem',
			'orders.sectionAwaitingAccept' => 'Oczekujące na akceptację',
			'orders.sectionInProgress' => 'Obecnie realizowane',
			'orders.sectionNew' => 'Nowe',
			'orders.chat.title' => 'Czat',
			'orders.chat.placeholder' => 'Napisz wiadomość...',
			'orders.chat.empty' => 'Brak wiadomości.',
			'orders.chat.loadError' => 'Nie udało się pobrać czatu.',
			'orders.chat.sendError' => 'Nie udało się wysłać wiadomości.',
			'orders.history.allLoaded' => 'To już wszystko.',
			'orders.priority.label' => 'Priorytet',
			'orders.priority.normal' => 'Zwykły',
			'orders.priority.urgent' => 'Pilny',
			'orders.priority.critical' => 'Bardzo pilny',
			'account.logout' => 'Wyloguj',
			'account.language' => 'Język',
			'account.languagePolish' => 'Polski',
			'account.languageEnglish' => 'English',
			'account.theme' => 'Motyw',
			'account.themeSystem' => 'Systemowy',
			'account.themeLight' => 'Jasny',
			'account.themeDark' => 'Ciemny',
			_ => null,
		};
	}
}
