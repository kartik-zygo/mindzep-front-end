class CreatePsychologistRequest {
  final String name;
  final String email;
  final String phone;
  final String credentials;
  final String specialization;
  final List<String> specializations;
  final String bio;
  final List<String> languages;
  final int yearsExperience;
  final double ratePerMinute;

  const CreatePsychologistRequest({
    required this.name,
    required this.email,
    required this.phone,
    required this.credentials,
    required this.specialization,
    required this.specializations,
    required this.bio,
    required this.languages,
    required this.yearsExperience,
    required this.ratePerMinute,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'credentials': credentials,
      'specialization': specialization,
      'specializations': specializations,
      'bio': bio,
      'languages': languages,
      'yearsExperience': yearsExperience,
      'ratePerMinute': ratePerMinute,
    };
  }
}

class CreditWalletRequest {
  final double amount;
  final String reason;

  const CreditWalletRequest({required this.amount, required this.reason});

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'reason': reason,
    };
  }
}

class SuspendEntityRequest {
  final String reason;

  const SuspendEntityRequest({required this.reason});

  Map<String, dynamic> toJson() {
    return {'reason': reason};
  }
}

class UpdateStaticContentRequest {
  final String title;
  final String content;

  const UpdateStaticContentRequest({
    required this.title,
    required this.content,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
    };
  }
}
