class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) return "Enter email";
    if (!value.contains("@")) return "Invalid email";
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.length < 6) return "Min 6 characters";
    return null;
  }
}