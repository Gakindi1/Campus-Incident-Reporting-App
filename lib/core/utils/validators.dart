class Validators {
  Validators._();

  static const List<String> allowedEmailDomains = [
    'alustudent.com',
    'alueducation.com',
  ];

  static final RegExp _emailPattern = RegExp(
    r'^[\w.+-]+@([\w-]+\.)+[a-zA-Z]{2,}$',
  );

  static bool isAluEmail(String email) {
    final domain = email.trim().toLowerCase().split('@').last;
    return allowedEmailDomains.contains(domain);
  }

  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email is required';
    if (!_emailPattern.hasMatch(email)) return 'Enter a valid email address';
    if (!isAluEmail(email)) {
      return 'Use your ALU email (@alustudent.com or @alueducation.com)';
    }
    return null;
  }

  static String? password(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Password is required';
    if (password.length < 8) return 'Use at least 8 characters';
    if (!RegExp(r'[A-Za-z]').hasMatch(password) ||
        !RegExp(r'\d').hasMatch(password)) {
      return 'Include at least one letter and one number';
    }
    return null;
  }

  static String? loginPassword(String? value) =>
      (value ?? '').isEmpty ? 'Password is required' : null;

  static String? Function(String?) confirmPassword(String Function() original) {
    return (value) {
      if ((value ?? '').isEmpty) return 'Please confirm your password';
      if (value != original()) return 'Passwords do not match';
      return null;
    };
  }

  static String? fullName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Full name is required';
    if (name.length < 3) return 'Name is too short';
    return null;
  }

  static String? incidentTitle(String? value) {
    final title = value?.trim() ?? '';
    if (title.isEmpty) return 'Give your report a short title';
    if (title.length < 5) return 'Title should be at least 5 characters';
    if (title.length > 80) return 'Keep the title under 80 characters';
    return null;
  }

  static String? incidentDescription(String? value) {
    final description = value?.trim() ?? '';
    if (description.isEmpty) return 'Describe what happened';
    if (description.length < 15) {
      return 'Add a little more detail (at least 15 characters)';
    }
    if (description.length > 1000) return 'Keep it under 1000 characters';
    return null;
  }

  static String? requiredField(String? value, String fieldName) =>
      (value == null || value.trim().isEmpty) ? '$fieldName is required' : null;
}
