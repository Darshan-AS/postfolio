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
	late final TranslationsCustomersEn customers = TranslationsCustomersEn.internal(_root);
	late final TranslationsDashboardEn dashboard = TranslationsDashboardEn.internal(_root);
	late final TranslationsOneTimeDepositsEn oneTimeDeposits = TranslationsOneTimeDepositsEn.internal(_root);
	late final TranslationsRecurringDepositsEn recurringDeposits = TranslationsRecurringDepositsEn.internal(_root);
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

	/// en: 'One-Time Deposits'
	String get oneTimeDeposits => 'One-Time Deposits';

	/// en: 'Recurring Deposits'
	String get recurringDeposits => 'Recurring Deposits';

	/// en: 'Customers'
	String get customers => 'Customers';
}

// Path: customers
class TranslationsCustomersEn {
	TranslationsCustomersEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Customers'
	String get title => 'Customers';

	/// en: 'Customer Details'
	String get customerDetails => 'Customer Details';

	/// en: 'New Customer'
	String get newCustomer => 'New Customer';

	/// en: 'Edit Customer'
	String get editCustomer => 'Edit Customer';

	/// en: 'Save Customer'
	String get saveCustomer => 'Save Customer';

	/// en: 'No customers found. Add one!'
	String get noCustomersFound => 'No customers found. Add one!';

	/// en: 'Customer not found'
	String get customerNotFound => 'Customer not found';

	/// en: 'Delete Customer'
	String get deleteCustomer => 'Delete Customer';

	/// en: 'Are you sure you want to delete this customer?'
	String get deleteCustomerConfirmation => 'Are you sure you want to delete this customer?';

	/// en: 'Failed to save customer: ${error}'
	String failedToSaveCustomer({required Object error}) => 'Failed to save customer: ${error}';

	/// en: 'Failed to delete customer: ${error}'
	String failedToDeleteCustomer({required Object error}) => 'Failed to delete customer: ${error}';

	late final TranslationsCustomersActionsEn actions = TranslationsCustomersActionsEn.internal(_root);
	late final TranslationsCustomersSectionsEn sections = TranslationsCustomersSectionsEn.internal(_root);
	late final TranslationsCustomersFieldsEn fields = TranslationsCustomersFieldsEn.internal(_root);
}

// Path: dashboard
class TranslationsDashboardEn {
	TranslationsDashboardEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Dashboard Charts Go Here'
	String get charts => 'Dashboard Charts Go Here';
}

// Path: oneTimeDeposits
class TranslationsOneTimeDepositsEn {
	TranslationsOneTimeDepositsEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'One-Time Deposits'
	String get title => 'One-Time Deposits';

	/// en: 'New Deposit'
	String get newDeposit => 'New Deposit';

	/// en: 'Edit Deposit'
	String get editDeposit => 'Edit Deposit';

	/// en: 'Save Deposit'
	String get saveDeposit => 'Save Deposit';

	/// en: 'No one-time deposits found. Add one!'
	String get noDepositsFound => 'No one-time deposits found. Add one!';

	/// en: 'Deposit not found'
	String get depositNotFound => 'Deposit not found';

	/// en: 'Delete Deposit'
	String get deleteDeposit => 'Delete Deposit';

	/// en: 'Are you sure you want to delete this deposit?'
	String get deleteDepositConfirmation => 'Are you sure you want to delete this deposit?';

	/// en: 'Failed to save deposit: ${error}'
	String failedToSaveDeposit({required Object error}) => 'Failed to save deposit: ${error}';

	/// en: 'Failed to delete deposit: ${error}'
	String failedToDeleteDeposit({required Object error}) => 'Failed to delete deposit: ${error}';

	late final TranslationsOneTimeDepositsFieldsEn fields = TranslationsOneTimeDepositsFieldsEn.internal(_root);
}

// Path: recurringDeposits
class TranslationsRecurringDepositsEn {
	TranslationsRecurringDepositsEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Recurring Deposits'
	String get title => 'Recurring Deposits';

	/// en: 'New RD'
	String get newDeposit => 'New RD';

	/// en: 'Edit RD'
	String get editDeposit => 'Edit RD';

	/// en: 'Save RD'
	String get saveDeposit => 'Save RD';

	/// en: 'No recurring deposits found. Add one!'
	String get noDepositsFound => 'No recurring deposits found. Add one!';

	/// en: 'RD not found'
	String get depositNotFound => 'RD not found';

	/// en: 'Delete RD'
	String get deleteDeposit => 'Delete RD';

	/// en: 'Are you sure you want to delete this RD?'
	String get deleteDepositConfirmation => 'Are you sure you want to delete this RD?';

	/// en: 'Failed to save RD: ${error}'
	String failedToSaveDeposit({required Object error}) => 'Failed to save RD: ${error}';

	/// en: 'Failed to delete RD: ${error}'
	String failedToDeleteDeposit({required Object error}) => 'Failed to delete RD: ${error}';

	late final TranslationsRecurringDepositsFieldsEn fields = TranslationsRecurringDepositsFieldsEn.internal(_root);
}

// Path: customers.actions
class TranslationsCustomersActionsEn {
	TranslationsCustomersActionsEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Call'
	String get call => 'Call';

	/// en: 'SMS'
	String get sms => 'SMS';

	/// en: 'WhatsApp'
	String get whatsapp => 'WhatsApp';
}

// Path: customers.sections
class TranslationsCustomersSectionsEn {
	TranslationsCustomersSectionsEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Personal Information'
	String get personalInfo => 'Personal Information';

	/// en: 'Identity Documents'
	String get identityDocuments => 'Identity Documents';

	/// en: 'Savings Bank'
	String get savingsBank => 'Savings Bank';
}

// Path: customers.fields
class TranslationsCustomersFieldsEn {
	TranslationsCustomersFieldsEn.internal(this._root);

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

	/// en: 'CIF'
	String get cif => 'CIF';

	/// en: 'Aadhaar Number'
	String get aadhaarNumber => 'Aadhaar Number';

	/// en: 'PAN Number'
	String get panNumber => 'PAN Number';

	/// en: 'SB Account No.'
	String get sbAccountNumber => 'SB Account No.';

	/// en: 'SB Nominee Name'
	String get sbNomineeName => 'SB Nominee Name';

	/// en: 'SB Nominee Relationship'
	String get sbNomineeRelationship => 'SB Nominee Relationship';

	/// en: 'Date of Birth'
	String get dateOfBirth => 'Date of Birth';

	/// en: 'Nominees'
	String get nominees => 'Nominees';

	/// en: 'Add Nominee'
	String get addNominee => 'Add Nominee';

	/// en: 'Nominee Name'
	String get nomineeName => 'Nominee Name';

	/// en: 'Relationship'
	String get relationship => 'Relationship';

	/// en: 'Percentage (%)'
	String get percentage => 'Percentage (%)';
}

// Path: oneTimeDeposits.fields
class TranslationsOneTimeDepositsFieldsEn {
	TranslationsOneTimeDepositsFieldsEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Row ID *'
	String get rowId => 'Row ID *';

	/// en: 'Account No *'
	String get accountNo => 'Account No *';

	/// en: 'Principal Amount *'
	String get principalAmount => 'Principal Amount *';

	/// en: 'Term (Years) *'
	String get termYears => 'Term (Years) *';

	/// en: 'Term (Months) *'
	String get termMonths => 'Term (Months) *';

	/// en: 'Customer ID *'
	String get customerId => 'Customer ID *';

	/// en: 'Scheme Type'
	String get schemeType => 'Scheme Type';

	/// en: 'Maturity Amount *'
	String get maturityAmount => 'Maturity Amount *';

	/// en: 'Start Date'
	String get startDate => 'Start Date';

	/// en: 'Maturity Date'
	String get maturityDate => 'Maturity Date';
}

// Path: recurringDeposits.fields
class TranslationsRecurringDepositsFieldsEn {
	TranslationsRecurringDepositsFieldsEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Account No *'
	String get accountNo => 'Account No *';

	/// en: 'Installment Amount *'
	String get installmentAmount => 'Installment Amount *';

	/// en: 'Term (Years) *'
	String get termYears => 'Term (Years) *';

	/// en: 'Term (Months) *'
	String get termMonths => 'Term (Months) *';

	/// en: 'Interest Rate *'
	String get interestRate => 'Interest Rate *';

	/// en: 'Customer ID *'
	String get customerId => 'Customer ID *';

	/// en: 'Scheme Type'
	String get schemeType => 'Scheme Type';

	/// en: 'Maturity Amount *'
	String get maturityAmount => 'Maturity Amount *';

	/// en: 'Start Date'
	String get startDate => 'Start Date';

	/// en: 'Maturity Date'
	String get maturityDate => 'Maturity Date';
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
			'nav.oneTimeDeposits' => 'One-Time Deposits',
			'nav.recurringDeposits' => 'Recurring Deposits',
			'nav.customers' => 'Customers',
			'customers.title' => 'Customers',
			'customers.customerDetails' => 'Customer Details',
			'customers.newCustomer' => 'New Customer',
			'customers.editCustomer' => 'Edit Customer',
			'customers.saveCustomer' => 'Save Customer',
			'customers.noCustomersFound' => 'No customers found. Add one!',
			'customers.customerNotFound' => 'Customer not found',
			'customers.deleteCustomer' => 'Delete Customer',
			'customers.deleteCustomerConfirmation' => 'Are you sure you want to delete this customer?',
			'customers.failedToSaveCustomer' => ({required Object error}) => 'Failed to save customer: ${error}',
			'customers.failedToDeleteCustomer' => ({required Object error}) => 'Failed to delete customer: ${error}',
			'customers.actions.call' => 'Call',
			'customers.actions.sms' => 'SMS',
			'customers.actions.whatsapp' => 'WhatsApp',
			'customers.sections.personalInfo' => 'Personal Information',
			'customers.sections.identityDocuments' => 'Identity Documents',
			'customers.sections.savingsBank' => 'Savings Bank',
			'customers.fields.fullName' => 'Full Name *',
			'customers.fields.phoneNumber' => 'Phone Number',
			'customers.fields.emailAddress' => 'Email Address',
			'customers.fields.homeAddress' => 'Home Address',
			'customers.fields.cif' => 'CIF',
			'customers.fields.aadhaarNumber' => 'Aadhaar Number',
			'customers.fields.panNumber' => 'PAN Number',
			'customers.fields.sbAccountNumber' => 'SB Account No.',
			'customers.fields.sbNomineeName' => 'SB Nominee Name',
			'customers.fields.sbNomineeRelationship' => 'SB Nominee Relationship',
			'customers.fields.dateOfBirth' => 'Date of Birth',
			'customers.fields.nominees' => 'Nominees',
			'customers.fields.addNominee' => 'Add Nominee',
			'customers.fields.nomineeName' => 'Nominee Name',
			'customers.fields.relationship' => 'Relationship',
			'customers.fields.percentage' => 'Percentage (%)',
			'dashboard.charts' => 'Dashboard Charts Go Here',
			'oneTimeDeposits.title' => 'One-Time Deposits',
			'oneTimeDeposits.newDeposit' => 'New Deposit',
			'oneTimeDeposits.editDeposit' => 'Edit Deposit',
			'oneTimeDeposits.saveDeposit' => 'Save Deposit',
			'oneTimeDeposits.noDepositsFound' => 'No one-time deposits found. Add one!',
			'oneTimeDeposits.depositNotFound' => 'Deposit not found',
			'oneTimeDeposits.deleteDeposit' => 'Delete Deposit',
			'oneTimeDeposits.deleteDepositConfirmation' => 'Are you sure you want to delete this deposit?',
			'oneTimeDeposits.failedToSaveDeposit' => ({required Object error}) => 'Failed to save deposit: ${error}',
			'oneTimeDeposits.failedToDeleteDeposit' => ({required Object error}) => 'Failed to delete deposit: ${error}',
			'oneTimeDeposits.fields.rowId' => 'Row ID *',
			'oneTimeDeposits.fields.accountNo' => 'Account No *',
			'oneTimeDeposits.fields.principalAmount' => 'Principal Amount *',
			'oneTimeDeposits.fields.termYears' => 'Term (Years) *',
			'oneTimeDeposits.fields.termMonths' => 'Term (Months) *',
			'oneTimeDeposits.fields.customerId' => 'Customer ID *',
			'oneTimeDeposits.fields.schemeType' => 'Scheme Type',
			'oneTimeDeposits.fields.maturityAmount' => 'Maturity Amount *',
			'oneTimeDeposits.fields.startDate' => 'Start Date',
			'oneTimeDeposits.fields.maturityDate' => 'Maturity Date',
			'recurringDeposits.title' => 'Recurring Deposits',
			'recurringDeposits.newDeposit' => 'New RD',
			'recurringDeposits.editDeposit' => 'Edit RD',
			'recurringDeposits.saveDeposit' => 'Save RD',
			'recurringDeposits.noDepositsFound' => 'No recurring deposits found. Add one!',
			'recurringDeposits.depositNotFound' => 'RD not found',
			'recurringDeposits.deleteDeposit' => 'Delete RD',
			'recurringDeposits.deleteDepositConfirmation' => 'Are you sure you want to delete this RD?',
			'recurringDeposits.failedToSaveDeposit' => ({required Object error}) => 'Failed to save RD: ${error}',
			'recurringDeposits.failedToDeleteDeposit' => ({required Object error}) => 'Failed to delete RD: ${error}',
			'recurringDeposits.fields.accountNo' => 'Account No *',
			'recurringDeposits.fields.installmentAmount' => 'Installment Amount *',
			'recurringDeposits.fields.termYears' => 'Term (Years) *',
			'recurringDeposits.fields.termMonths' => 'Term (Months) *',
			'recurringDeposits.fields.interestRate' => 'Interest Rate *',
			'recurringDeposits.fields.customerId' => 'Customer ID *',
			'recurringDeposits.fields.schemeType' => 'Scheme Type',
			'recurringDeposits.fields.maturityAmount' => 'Maturity Amount *',
			'recurringDeposits.fields.startDate' => 'Start Date',
			'recurringDeposits.fields.maturityDate' => 'Maturity Date',
			_ => null,
		};
	}
}
