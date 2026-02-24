class JwtTokens {
  const JwtTokens({
    required this.access,
    required this.refresh,
  });

  final String access;
  final String refresh;

  factory JwtTokens.fromJson(Map<String, dynamic> json) {
    return JwtTokens(
      access: json['access']?.toString() ?? '',
      refresh: json['refresh']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'access': access,
      'refresh': refresh,
    };
  }
}
