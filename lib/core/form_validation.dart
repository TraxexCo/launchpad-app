class FormValidation {
  const FormValidation._();

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? jobDescription(String? value) {
    if (value == null || value.trim().isEmpty) return 'Description is required';
    if (value.trim().length < 50) return 'Write at least 50 characters';
    return null;
  }

  static String? jobBudget(String? value) {
    if (value == null || value.isEmpty) return 'Budget is required';
    final amount = double.tryParse(value.replaceAll(',', '').trim());
    if (amount == null) return 'Enter a valid number';
    if (amount <= 0) return 'Budget must be greater than zero';
    return null;
  }

  static String? proposalPitch(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please provide a pitch or cover letter explaining your approach';
    }
    if (value.trim().length < 80) return 'Write at least 80 characters';
    return null;
  }

  static String? proposalRate(String? value) {
    if (value == null || value.isEmpty) return 'Enter your proposed rate';
    if (double.tryParse(value.replaceAll(',', '').trim()) == null) {
      return 'Enter a valid numeric amount';
    }
    return null;
  }

  static String? projectTitle(String? value) =>
      value == null || value.trim().isEmpty ? 'Please enter a title' : null;
}
