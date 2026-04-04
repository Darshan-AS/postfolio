///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'strings.g.dart';

// Path: <root>
typedef TranslationsEn = Translations; // ignore: unused_element
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
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	dynamic operator[](String key) => $meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations

	/// en: 'Postfolio'
	String get appTitle => 'Postfolio';

	late final TranslationsCommonEn common = TranslationsCommonEn.internal(_root);
	late final TranslationsNavEn nav = TranslationsNavEn.internal(_root);
	late final TranslationsUsersEn users = TranslationsUsersEn.internal(_root);
	late final TranslationsDashboardEn dashboard = TranslationsDashboardEn.internal(_root);
	late final TranslationsDepositsEn deposits = TranslationsDepositsEn.internal(_root);
	late final TranslationsRdEn rd = TranslationsRdEn.internal(_root);
}

// Path: common
class TranslationsCommonEn {
	TranslationsCommonEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Loading...'
	String get loading => 'Loading...';

	/// en: 'Saving...'
	String get saving => 'Saving...';

	/// en: 'Delete'
	String get delete => 'Delete';

	/// en: 'Cancel'
	String get cancel => 'Cancel';

	/// en: 'Error'
	String get error => 'Error';

	/// en: 'Retry'
	String get retry => 'Retry';

	/// en: 'Not provided'
	String get notProvided => 'Not provided';
}

// Path: nav
class TranslationsNavEn {
	TranslationsNavEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Dashboard'
	String get dashboard => 'Dashboard';

	/// en: 'Deposits'
	String get deposits => 'Deposits';

	/// en: 'Recurring Deposits'
	String get recurringDeposits => 'Recurring Deposits';

	/// en: 'RD'
	String get rd => 'RD';

	/// en: 'Users'
	String get users => 'Users';
}

// Path: users
class TranslationsUsersEn {
	TranslationsUsersEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Users'
	String get title => 'Users';

	/// en: 'New User'
	String get newUser => 'New User';

	/// en: 'Edit User'
	String get editUser => 'Edit User';

	/// en: 'Save User'
	String get saveUser => 'Save User';

	/// en: 'No users found. Add one!'
	String get noUsersFound => 'No users found. Add one!';

	/// en: 'User not found'
	String get userNotFound => 'User not found';

	/// en: 'Delete User'
	String get deleteUser => 'Delete User';

	/// en: 'Are you sure you want to delete this user?'
	String get deleteUserConfirmation => 'Are you sure you want to delete this user?';

	/// en: 'Failed to save user: ${error}'
	String failedToSaveUser({required Object error}) => 'Failed to save user: ${error}';

	/// en: 'Failed to delete user: ${error}'
	String failedToDeleteUser({required Object error}) => 'Failed to delete user: ${error}';

	late final TranslationsUsersFieldsEn fields = TranslationsUsersFieldsEn.internal(_root);
}

// Path: dashboard
class TranslationsDashboardEn {
	TranslationsDashboardEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Dashboard Charts Go Here'
	String get charts => 'Dashboard Charts Go Here';
}

// Path: deposits
class TranslationsDepositsEn {
	TranslationsDepositsEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Deposits List Goes Here'
	String get list => 'Deposits List Goes Here';
}

// Path: rd
class TranslationsRdEn {
	TranslationsRdEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'RD List Goes Here'
	String get list => 'RD List Goes Here';
}

// Path: users.fields
class TranslationsUsersFieldsEn {
	TranslationsUsersFieldsEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Full Name *'
	String get fullName => 'Full Name *';

	/// en: 'Phone Number'
	String get phoneNumber => 'Phone Number';

	/// en: 'Email Address'
	String get emailAddress => 'Email Address';

	/// en: 'Home Address'
	String get homeAddress => 'Home Address';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'appTitle' => 'Postfolio',
			'common.loading' => 'Loading...',
			'common.saving' => 'Saving...',
			'common.delete' => 'Delete',
			'common.cancel' => 'Cancel',
			'common.error' => 'Error',
			'common.retry' => 'Retry',
			'common.notProvided' => 'Not provided',
			'nav.dashboard' => 'Dashboard',
			'nav.deposits' => 'Deposits',
			'nav.recurringDeposits' => 'Recurring Deposits',
			'nav.rd' => 'RD',
			'nav.users' => 'Users',
			'users.title' => 'Users',
			'users.newUser' => 'New User',
			'users.editUser' => 'Edit User',
			'users.saveUser' => 'Save User',
			'users.noUsersFound' => 'No users found. Add one!',
			'users.userNotFound' => 'User not found',
			'users.deleteUser' => 'Delete User',
			'users.deleteUserConfirmation' => 'Are you sure you want to delete this user?',
			'users.failedToSaveUser' => ({required Object error}) => 'Failed to save user: ${error}',
			'users.failedToDeleteUser' => ({required Object error}) => 'Failed to delete user: ${error}',
			'users.fields.fullName' => 'Full Name *',
			'users.fields.phoneNumber' => 'Phone Number',
			'users.fields.emailAddress' => 'Email Address',
			'users.fields.homeAddress' => 'Home Address',
			'dashboard.charts' => 'Dashboard Charts Go Here',
			'deposits.list' => 'Deposits List Goes Here',
			'rd.list' => 'RD List Goes Here',
			_ => null,
		};
	}
}
