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

	/// en: 'Users'
	String get users => 'Users';

	/// en: 'Dashboard'
	String get dashboard => 'Dashboard';

	/// en: 'Deposits'
	String get deposits => 'Deposits';

	/// en: 'Recurring Deposits'
	String get recurringDeposits => 'Recurring Deposits';

	/// en: 'RD'
	String get rd => 'RD';

	/// en: 'New User'
	String get newUser => 'New User';

	/// en: 'Edit User'
	String get editUser => 'Edit User';

	/// en: 'Save User'
	String get saveUser => 'Save User';

	/// en: 'Saving...'
	String get saving => 'Saving...';

	/// en: 'Loading...'
	String get loading => 'Loading...';

	/// en: 'No users found. Add one!'
	String get noUsersFound => 'No users found. Add one!';

	/// en: 'Dashboard Charts Go Here'
	String get dashboardCharts => 'Dashboard Charts Go Here';

	/// en: 'Deposits List Goes Here'
	String get depositsList => 'Deposits List Goes Here';

	/// en: 'RD List Goes Here'
	String get rdList => 'RD List Goes Here';

	/// en: 'Full Name *'
	String get fullName => 'Full Name *';

	/// en: 'Phone Number'
	String get phoneNumber => 'Phone Number';

	/// en: 'Email Address'
	String get emailAddress => 'Email Address';

	/// en: 'Home Address'
	String get homeAddress => 'Home Address';

	/// en: 'Delete'
	String get delete => 'Delete';

	/// en: 'Delete User'
	String get deleteUser => 'Delete User';

	/// en: 'Are you sure you want to delete this user?'
	String get deleteUserConfirmation => 'Are you sure you want to delete this user?';

	/// en: 'Cancel'
	String get cancel => 'Cancel';

	/// en: 'Error'
	String get error => 'Error';

	/// en: 'Retry'
	String get retry => 'Retry';

	/// en: 'User not found'
	String get userNotFound => 'User not found';

	/// en: 'Not provided'
	String get notProvided => 'Not provided';

	/// en: 'Failed to save user: ${error}'
	String failedToSaveUser({required Object error}) => 'Failed to save user: ${error}';

	/// en: 'Failed to delete user: ${error}'
	String failedToDeleteUser({required Object error}) => 'Failed to delete user: ${error}';
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
			'users' => 'Users',
			'dashboard' => 'Dashboard',
			'deposits' => 'Deposits',
			'recurringDeposits' => 'Recurring Deposits',
			'rd' => 'RD',
			'newUser' => 'New User',
			'editUser' => 'Edit User',
			'saveUser' => 'Save User',
			'saving' => 'Saving...',
			'loading' => 'Loading...',
			'noUsersFound' => 'No users found. Add one!',
			'dashboardCharts' => 'Dashboard Charts Go Here',
			'depositsList' => 'Deposits List Goes Here',
			'rdList' => 'RD List Goes Here',
			'fullName' => 'Full Name *',
			'phoneNumber' => 'Phone Number',
			'emailAddress' => 'Email Address',
			'homeAddress' => 'Home Address',
			'delete' => 'Delete',
			'deleteUser' => 'Delete User',
			'deleteUserConfirmation' => 'Are you sure you want to delete this user?',
			'cancel' => 'Cancel',
			'error' => 'Error',
			'retry' => 'Retry',
			'userNotFound' => 'User not found',
			'notProvided' => 'Not provided',
			'failedToSaveUser' => ({required Object error}) => 'Failed to save user: ${error}',
			'failedToDeleteUser' => ({required Object error}) => 'Failed to delete user: ${error}',
			_ => null,
		};
	}
}
