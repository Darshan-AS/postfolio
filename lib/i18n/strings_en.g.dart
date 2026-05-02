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

	late final TranslationsErrorsEn errors = TranslationsErrorsEn.internal(_root);
	late final TranslationsCommonEn common = TranslationsCommonEn.internal(_root);
	late final TranslationsProjectionEn projection = TranslationsProjectionEn.internal(_root);
	late final TranslationsNavEn nav = TranslationsNavEn.internal(_root);
	late final TranslationsCustomersEn customers = TranslationsCustomersEn.internal(_root);
	late final TranslationsDashboardEn dashboard = TranslationsDashboardEn.internal(_root);
	late final TranslationsOneTimeDepositsEn oneTimeDeposits = TranslationsOneTimeDepositsEn.internal(_root);
	late final TranslationsRecurringDepositsEn recurringDeposits = TranslationsRecurringDepositsEn.internal(_root);
	late final TranslationsNomineesEn nominees = TranslationsNomineesEn.internal(_root);
	late final TranslationsEnumsEn enums = TranslationsEnumsEn.internal(_root);
}

// Path: errors
class TranslationsErrorsEn {
	TranslationsErrorsEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: '${field} is required'
	String requiredField({required Object field}) => '${field} is required';

	/// en: '${field} must be greater than 0'
	String greaterThanZero({required Object field}) => '${field} must be greater than 0';

	/// en: 'Term cannot be negative'
	String get negativeTerm => 'Term cannot be negative';

	/// en: 'Invalid tenure of ${years} years for ${scheme}'
	String invalidTenure({required Object years, required Object scheme}) => 'Invalid tenure of ${years} years for ${scheme}';

	/// en: 'Months are not applicable for fixed tenure schemes'
	String get fixedTenureNoMonths => 'Months are not applicable for fixed tenure schemes';

	/// en: 'Maturity date cannot be before start date'
	String get invalidMaturityDate => 'Maturity date cannot be before start date';

	/// en: '${field} must be at least ${count} characters'
	String minLength({required Object field, required Object count}) => '${field} must be at least ${count} characters';

	/// en: 'Invalid email format'
	String get invalidEmail => 'Invalid email format';

	/// en: 'Invalid phone number (7-15 digits)'
	String get invalidPhone => 'Invalid phone number (7-15 digits)';

	/// en: 'Savings Account Number is required to add nominees'
	String get sbAccountRequiredForNominee => 'Savings Account Number is required to add nominees';
}

// Path: common
class TranslationsCommonEn {
	TranslationsCommonEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final TranslationsCommonDurationEn duration = TranslationsCommonDurationEn.internal(_root);

	/// en: 'Loading...'
	String get loading => 'Loading...';

	/// en: 'Saving...'
	String get saving => 'Saving...';

	/// en: 'Edit'
	String get edit => 'Edit';

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

	/// en: 'More options'
	String get moreOptions => 'More options';

	late final TranslationsCommonSectionsEn sections = TranslationsCommonSectionsEn.internal(_root);
}

// Path: projection
class TranslationsProjectionEn {
	TranslationsProjectionEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Live Projection'
	String get title => 'Live Projection';

	/// en: 'Total Invested'
	String get totalInvested => 'Total Invested';

	/// en: 'Total Interest Earned'
	String get totalInterestEarned => 'Total Interest Earned';

	/// en: 'Estimated Maturity'
	String get estimatedMaturity => 'Estimated Maturity';

	/// en: 'Maturity Date'
	String get maturityDate => 'Maturity Date';

	/// en: 'Payout (${frequency})'
	String payout({required Object frequency}) => 'Payout (${frequency})';
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

	/// en: 'Select Customer'
	String get selectCustomer => 'Select Customer';

	/// en: 'Search by name, phone or CIF...'
	String get searchHint => 'Search by name, phone or CIF...';

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

	/// en: 'Please select a customer'
	String get selectCustomerPrompt => 'Please select a customer';

	late final TranslationsOneTimeDepositsSectionsEn sections = TranslationsOneTimeDepositsSectionsEn.internal(_root);
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

	/// en: 'Please select a customer'
	String get selectCustomerPrompt => 'Please select a customer';

	late final TranslationsRecurringDepositsSectionsEn sections = TranslationsRecurringDepositsSectionsEn.internal(_root);
	late final TranslationsRecurringDepositsFieldsEn fields = TranslationsRecurringDepositsFieldsEn.internal(_root);
}

// Path: nominees
class TranslationsNomineesEn {
	TranslationsNomineesEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Nominees'
	String get title => 'Nominees';

	/// en: 'Add Nominee'
	String get addNominee => 'Add Nominee';

	/// en: 'Edit Nominee'
	String get editNominee => 'Edit Nominee';

	/// en: 'Delete Nominee'
	String get deleteNominee => 'Delete Nominee';

	/// en: 'Nominee Name'
	String get name => 'Nominee Name';

	/// en: 'Relationship'
	String get relationship => 'Relationship';

	/// en: 'Percentage (%)'
	String get percentage => 'Percentage (%)';

	/// en: 'No nominees added yet.'
	String get noNominees => 'No nominees added yet.';
}

// Path: enums
class TranslationsEnumsEn {
	TranslationsEnumsEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final TranslationsEnumsPayoutFrequencyEn payoutFrequency = TranslationsEnumsPayoutFrequencyEn.internal(_root);
	late final TranslationsEnumsDepositStatusEn depositStatus = TranslationsEnumsDepositStatusEn.internal(_root);
	late final TranslationsEnumsOneTimeSchemeTypeEn oneTimeSchemeType = TranslationsEnumsOneTimeSchemeTypeEn.internal(_root);
	late final TranslationsEnumsRecurringSchemeTypeEn recurringSchemeType = TranslationsEnumsRecurringSchemeTypeEn.internal(_root);
}

// Path: common.duration
class TranslationsCommonDurationEn {
	TranslationsCommonDurationEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Term (Years)'
	String get termYears => 'Term (Years)';

	/// en: 'Term (Months)'
	String get termMonths => 'Term (Months)';

	/// en: '(one) {1 Yr} (other) {${n} Yrs}'
	String yearAbbreviation({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '1 Yr',
		other: '${n} Yrs',
	);
}

// Path: common.sections
class TranslationsCommonSectionsEn {
	TranslationsCommonSectionsEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Linked Accounts'
	String get linkedAccounts => 'Linked Accounts';
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

	/// en: 'Location'
	String get location => 'Location';
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

	/// en: 'Full Name'
	String get fullName => 'Full Name';

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

// Path: oneTimeDeposits.sections
class TranslationsOneTimeDepositsSectionsEn {
	TranslationsOneTimeDepositsSectionsEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Investment Details'
	String get investmentDetails => 'Investment Details';

	/// en: 'Timeline'
	String get timeline => 'Timeline';

	/// en: 'Account Information'
	String get accountInformation => 'Account Information';
}

// Path: oneTimeDeposits.fields
class TranslationsOneTimeDepositsFieldsEn {
	TranslationsOneTimeDepositsFieldsEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Status'
	String get status => 'Status';

	/// en: 'Account No.'
	String get accountNo => 'Account No.';

	/// en: 'Principal Amount'
	String get principalAmount => 'Principal Amount';

	/// en: 'Term (Years)'
	String get termYears => 'Term (Years)';

	/// en: 'Term (Months)'
	String get termMonths => 'Term (Months)';

	/// en: '(one) {1 Yr} (other) {${n} Yrs}'
	String yearAbbreviation({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '1 Yr',
		other: '${n} Yrs',
	);

	/// en: 'Customer'
	String get customerId => 'Customer';

	/// en: 'Scheme Type'
	String get schemeType => 'Scheme Type';

	/// en: 'Interest Rate (%)'
	String get interestRate => 'Interest Rate (%)';

	/// en: 'Maturity Amount'
	String get maturityAmount => 'Maturity Amount';

	/// en: 'Start Date'
	String get startDate => 'Start Date';

	/// en: 'Maturity Date'
	String get maturityDate => 'Maturity Date';

	/// en: 'Deposit Date'
	String get depositDate => 'Deposit Date';

	/// en: 'Linked Savings Account'
	String get linkedSavingsAccount => 'Linked Savings Account';
}

// Path: recurringDeposits.sections
class TranslationsRecurringDepositsSectionsEn {
	TranslationsRecurringDepositsSectionsEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Investment Details'
	String get investmentDetails => 'Investment Details';

	/// en: 'Timeline'
	String get timeline => 'Timeline';

	/// en: 'Account Information'
	String get accountInformation => 'Account Information';
}

// Path: recurringDeposits.fields
class TranslationsRecurringDepositsFieldsEn {
	TranslationsRecurringDepositsFieldsEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Status'
	String get status => 'Status';

	/// en: 'Serial No.'
	String get serialNo => 'Serial No.';

	/// en: 'Account No.'
	String get accountNo => 'Account No.';

	/// en: 'Installment Amount'
	String get installmentAmount => 'Installment Amount';

	/// en: 'Term (Years)'
	String get termYears => 'Term (Years)';

	/// en: 'Term (Months)'
	String get termMonths => 'Term (Months)';

	/// en: '(one) {1 Yr} (other) {${n} Yrs}'
	String yearAbbreviation({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '1 Yr',
		other: '${n} Yrs',
	);

	/// en: 'Interest Rate (%)'
	String get interestRate => 'Interest Rate (%)';

	/// en: 'Customer'
	String get customerId => 'Customer';

	/// en: 'Scheme Type'
	String get schemeType => 'Scheme Type';

	/// en: 'Maturity Amount'
	String get maturityAmount => 'Maturity Amount';

	/// en: 'Start Date'
	String get startDate => 'Start Date';

	/// en: 'Maturity Date'
	String get maturityDate => 'Maturity Date';

	/// en: 'Linked Savings Account'
	String get linkedSavingsAccount => 'Linked Savings Account';

	/// en: 'Linked Auto Debit Account'
	String get linkedAutoDebitAccount => 'Linked Auto Debit Account';
}

// Path: enums.payoutFrequency
class TranslationsEnumsPayoutFrequencyEn {
	TranslationsEnumsPayoutFrequencyEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Monthly'
	String get monthly => 'Monthly';

	/// en: 'Quarterly'
	String get quarterly => 'Quarterly';

	/// en: 'Annually'
	String get annually => 'Annually';
}

// Path: enums.depositStatus
class TranslationsEnumsDepositStatusEn {
	TranslationsEnumsDepositStatusEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Active'
	String get active => 'Active';

	/// en: 'Matured'
	String get matured => 'Matured';

	/// en: 'Closed'
	String get closed => 'Closed';
}

// Path: enums.oneTimeSchemeType
class TranslationsEnumsOneTimeSchemeTypeEn {
	TranslationsEnumsOneTimeSchemeTypeEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Time Deposit (TD)'
	String get timeDeposit => 'Time Deposit (TD)';

	/// en: 'Monthly Income Scheme (MIS)'
	String get monthlyIncomeScheme => 'Monthly Income Scheme (MIS)';

	/// en: 'National Savings Certificate (NSC)'
	String get nationalSavingsCertificate => 'National Savings Certificate (NSC)';

	/// en: 'Kisan Vikas Patra (KVP)'
	String get kisanVikasPatra => 'Kisan Vikas Patra (KVP)';
}

// Path: enums.recurringSchemeType
class TranslationsEnumsRecurringSchemeTypeEn {
	TranslationsEnumsRecurringSchemeTypeEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Recurring Deposit (RD)'
	String get recurringDeposit => 'Recurring Deposit (RD)';
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
			'errors.requiredField' => ({required Object field}) => '${field} is required',
			'errors.greaterThanZero' => ({required Object field}) => '${field} must be greater than 0',
			'errors.negativeTerm' => 'Term cannot be negative',
			'errors.invalidTenure' => ({required Object years, required Object scheme}) => 'Invalid tenure of ${years} years for ${scheme}',
			'errors.fixedTenureNoMonths' => 'Months are not applicable for fixed tenure schemes',
			'errors.invalidMaturityDate' => 'Maturity date cannot be before start date',
			'errors.minLength' => ({required Object field, required Object count}) => '${field} must be at least ${count} characters',
			'errors.invalidEmail' => 'Invalid email format',
			'errors.invalidPhone' => 'Invalid phone number (7-15 digits)',
			'errors.sbAccountRequiredForNominee' => 'Savings Account Number is required to add nominees',
			'common.duration.termYears' => 'Term (Years)',
			'common.duration.termMonths' => 'Term (Months)',
			'common.duration.yearAbbreviation' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '1 Yr', other: '${n} Yrs', ), 
			'common.loading' => 'Loading...',
			'common.saving' => 'Saving...',
			'common.edit' => 'Edit',
			'common.delete' => 'Delete',
			'common.cancel' => 'Cancel',
			'common.error' => 'Error',
			'common.retry' => 'Retry',
			'common.notProvided' => 'Not provided',
			'common.moreOptions' => 'More options',
			'common.sections.linkedAccounts' => 'Linked Accounts',
			'projection.title' => 'Live Projection',
			'projection.totalInvested' => 'Total Invested',
			'projection.totalInterestEarned' => 'Total Interest Earned',
			'projection.estimatedMaturity' => 'Estimated Maturity',
			'projection.maturityDate' => 'Maturity Date',
			'projection.payout' => ({required Object frequency}) => 'Payout (${frequency})',
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
			'customers.selectCustomer' => 'Select Customer',
			'customers.searchHint' => 'Search by name, phone or CIF...',
			'customers.customerNotFound' => 'Customer not found',
			'customers.deleteCustomer' => 'Delete Customer',
			'customers.deleteCustomerConfirmation' => 'Are you sure you want to delete this customer?',
			'customers.failedToSaveCustomer' => ({required Object error}) => 'Failed to save customer: ${error}',
			'customers.failedToDeleteCustomer' => ({required Object error}) => 'Failed to delete customer: ${error}',
			'customers.actions.call' => 'Call',
			'customers.actions.sms' => 'SMS',
			'customers.actions.whatsapp' => 'WhatsApp',
			'customers.actions.location' => 'Location',
			'customers.sections.personalInfo' => 'Personal Information',
			'customers.sections.identityDocuments' => 'Identity Documents',
			'customers.sections.savingsBank' => 'Savings Bank',
			'customers.fields.fullName' => 'Full Name',
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
			'oneTimeDeposits.selectCustomerPrompt' => 'Please select a customer',
			'oneTimeDeposits.sections.investmentDetails' => 'Investment Details',
			'oneTimeDeposits.sections.timeline' => 'Timeline',
			'oneTimeDeposits.sections.accountInformation' => 'Account Information',
			'oneTimeDeposits.fields.status' => 'Status',
			'oneTimeDeposits.fields.accountNo' => 'Account No.',
			'oneTimeDeposits.fields.principalAmount' => 'Principal Amount',
			'oneTimeDeposits.fields.termYears' => 'Term (Years)',
			'oneTimeDeposits.fields.termMonths' => 'Term (Months)',
			'oneTimeDeposits.fields.yearAbbreviation' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '1 Yr', other: '${n} Yrs', ), 
			'oneTimeDeposits.fields.customerId' => 'Customer',
			'oneTimeDeposits.fields.schemeType' => 'Scheme Type',
			'oneTimeDeposits.fields.interestRate' => 'Interest Rate (%)',
			'oneTimeDeposits.fields.maturityAmount' => 'Maturity Amount',
			'oneTimeDeposits.fields.startDate' => 'Start Date',
			'oneTimeDeposits.fields.maturityDate' => 'Maturity Date',
			'oneTimeDeposits.fields.depositDate' => 'Deposit Date',
			'oneTimeDeposits.fields.linkedSavingsAccount' => 'Linked Savings Account',
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
			'recurringDeposits.selectCustomerPrompt' => 'Please select a customer',
			'recurringDeposits.sections.investmentDetails' => 'Investment Details',
			'recurringDeposits.sections.timeline' => 'Timeline',
			'recurringDeposits.sections.accountInformation' => 'Account Information',
			'recurringDeposits.fields.status' => 'Status',
			'recurringDeposits.fields.serialNo' => 'Serial No.',
			'recurringDeposits.fields.accountNo' => 'Account No.',
			'recurringDeposits.fields.installmentAmount' => 'Installment Amount',
			'recurringDeposits.fields.termYears' => 'Term (Years)',
			'recurringDeposits.fields.termMonths' => 'Term (Months)',
			'recurringDeposits.fields.yearAbbreviation' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '1 Yr', other: '${n} Yrs', ), 
			'recurringDeposits.fields.interestRate' => 'Interest Rate (%)',
			'recurringDeposits.fields.customerId' => 'Customer',
			'recurringDeposits.fields.schemeType' => 'Scheme Type',
			'recurringDeposits.fields.maturityAmount' => 'Maturity Amount',
			'recurringDeposits.fields.startDate' => 'Start Date',
			'recurringDeposits.fields.maturityDate' => 'Maturity Date',
			'recurringDeposits.fields.linkedSavingsAccount' => 'Linked Savings Account',
			'recurringDeposits.fields.linkedAutoDebitAccount' => 'Linked Auto Debit Account',
			'nominees.title' => 'Nominees',
			'nominees.addNominee' => 'Add Nominee',
			'nominees.editNominee' => 'Edit Nominee',
			'nominees.deleteNominee' => 'Delete Nominee',
			'nominees.name' => 'Nominee Name',
			'nominees.relationship' => 'Relationship',
			'nominees.percentage' => 'Percentage (%)',
			'nominees.noNominees' => 'No nominees added yet.',
			'enums.payoutFrequency.monthly' => 'Monthly',
			'enums.payoutFrequency.quarterly' => 'Quarterly',
			'enums.payoutFrequency.annually' => 'Annually',
			'enums.depositStatus.active' => 'Active',
			'enums.depositStatus.matured' => 'Matured',
			'enums.depositStatus.closed' => 'Closed',
			'enums.oneTimeSchemeType.timeDeposit' => 'Time Deposit (TD)',
			'enums.oneTimeSchemeType.monthlyIncomeScheme' => 'Monthly Income Scheme (MIS)',
			'enums.oneTimeSchemeType.nationalSavingsCertificate' => 'National Savings Certificate (NSC)',
			'enums.oneTimeSchemeType.kisanVikasPatra' => 'Kisan Vikas Patra (KVP)',
			'enums.recurringSchemeType.recurringDeposit' => 'Recurring Deposit (RD)',
			_ => null,
		};
	}
}
