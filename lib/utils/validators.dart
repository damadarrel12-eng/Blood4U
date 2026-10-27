class Validators {
  static String? requiredText(String? value, String label) {
    if (value == null || value.trim().isEmpty) return 'Enter $label';
    return null;
  }

  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Enter email';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.length < 8) {
      return 'Use at least 8 characters';
    }
    return null;
  }

  static String? contact(String? value) {
    final contact = value?.trim() ?? '';
    if (contact.isEmpty) return 'Enter a contact number';
    if (contact.length < 6) return 'Enter a valid contact number';
    return null;
  }
}
