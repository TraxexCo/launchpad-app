/// Centralised form validators used across all screens.
///
/// Every method matches the `FormFieldValidator<String>` signature so it can
/// be passed directly to a [TextFormField.validator] parameter.
class FormValidation {
  const FormValidation._();

  /// Ensures the field is not empty.
  static String? requiredField(
    String? value, [
    String fieldName = 'This field',
  ]) {
    return (value == null || value.trim().isEmpty)
        ? '$fieldName is required'
        : null;
  }

  /// Validates an email address format.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final trimmed = value.trim();
    // Basic but reliable check: must have @ with chars before and a dot after
    final re = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!re.hasMatch(trimmed)) return 'Enter a valid email address';
    return null;
  }

  /// Validates a password: minimum 6 characters (matches Supabase default).
  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  /// Validates a strong password: minimum 8 characters (used in register).
  static String? strongPassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Use at least 8 characters';
    if (!RegExp(r'[A-Za-z]').hasMatch(value) ||
        !RegExp(r'[0-9]').hasMatch(value)) {
      return 'Include at least one letter and one number';
    }
    return null;
  }

  /// Validates a URL: must start with http:// or https://.
  static String? url(String? value, {String fieldName = 'URL'}) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    final trimmed = value.trim();
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      return 'Enter a valid $fieldName (must start with https://)';
    }
    return null;
  }

  /// Optional URL — passes if empty, validates format otherwise.
  static String? optionalUrl(String? value, {String fieldName = 'URL'}) {
    if (value == null || value.trim().isEmpty) return null;
    return url(value, fieldName: fieldName);
  }

  /// Validates a job / project description: minimum 50 characters.
  static String? jobDescription(String? value) {
    if (value == null || value.trim().isEmpty) return 'Description is required';
    if (value.trim().length < 50) return 'Write at least 50 characters';
    return null;
  }

  /// Validates a numeric budget greater than zero.
  static String? jobBudget(String? value) {
    if (value == null || value.isEmpty) return 'Budget is required';
    final amount = double.tryParse(value.replaceAll(',', '').trim());
    if (amount == null) return 'Enter a valid number';
    if (amount <= 0) return 'Budget must be greater than zero';
    return null;
  }

  /// Validates a proposal pitch: minimum 80 characters.
  static String? proposalPitch(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please provide a pitch explaining your approach';
    }
    if (value.trim().length < 80) return 'Write at least 80 characters';
    return null;
  }

  /// Validates a proposed rate as a positive number.
  static String? proposalRate(String? value) {
    if (value == null || value.isEmpty) return 'Enter your proposed rate';
    if (double.tryParse(value.replaceAll(',', '').trim()) == null) {
      return 'Enter a valid numeric amount';
    }
    return null;
  }

  /// Validates a project or portfolio title.
  static String? projectTitle(String? value) =>
      value == null || value.trim().isEmpty ? 'Please enter a title' : null;
}
