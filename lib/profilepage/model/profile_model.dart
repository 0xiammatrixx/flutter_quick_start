class Profile {
  final String avatarUrl;
  final String name;
  final String emailAddress;
  final String walletAddress;
  final String? location;
  final bool isOnline;
  final bool isVerified;

  Profile({
    required this.avatarUrl,
    required this.name,
    required this.emailAddress,
    required this.walletAddress,
    this.location,
    required this.isOnline,
    required this.isVerified,
  }); 
}