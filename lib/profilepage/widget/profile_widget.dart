import 'package:arbichat/profilepage/page/profile_edit.dart';
import 'package:flutter/material.dart';
import 'package:arbichat/profilepage/model/profile_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileWidget extends StatelessWidget {
  final Profile profile;
  final bool isOwnProfile;
  final String walletAddress;
  const ProfileWidget({
    super.key,
    required this.profile,
    required this.walletAddress,
    this.isOwnProfile = true,
  });

  Future<String?> _getPrivateKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('privateKey');
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    ImageProvider avatarProvider;

    if (profile.avatarUrl.startsWith('http')) {
      avatarProvider = NetworkImage(profile.avatarUrl);
    } else {
      avatarProvider = AssetImage(profile.avatarUrl);
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Stack(children: [
              Container(
                child: CircleAvatar(
                  backgroundImage: avatarProvider,
                  radius: 70,
                ),
              ),
              if (profile.isVerified)
                Positioned(
                    bottom: 0,
                    right: 0,
                    child: Icon(
                      Icons.verified,
                      color: Theme.of(context).primaryColor,
                      size: 40,
                    ))
            ]),
          ),
          const SizedBox(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                profile.name,
                style:
                    const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
              const SizedBox(
                width: 5,
              ),
              if (profile.isOnline)
                const Icon(
                  Icons.circle,
                  size: 13,
                  color: Colors.blue,
                )
            ],
          ),
          const SizedBox(height: 5),
          if (isOwnProfile)
            Container(
              width: screenWidth * 0.5,
              decoration: BoxDecoration(boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 4,
                  blurRadius: 6,
                  offset: const Offset(0, 4),
                ),
              ], borderRadius: BorderRadius.circular(10)),
              child: ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith<Color>(
                      (Set<WidgetState> states) {
                    if (states.contains(
                      WidgetState.pressed,
                    )) {
                      return Colors.grey;
                    }
                    return Colors.black;
                  }),
                  foregroundColor: WidgetStateProperty.all(
                      const Color.fromARGB(255, 255, 255, 255)),
                  shape: WidgetStateProperty.all(RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
                  textStyle: WidgetStateProperty.all(const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                onPressed: () async {
                  final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => EditProfilePage(
                              walletAddress: profile.walletAddress,
                              currentName: profile.name,
                              currentLocation: profile.location ?? '',
                              currentAvatarUrl: profile.avatarUrl)));
                  if (result == true) {
                    Navigator.pop(context, true);
                  }
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.edit,
                      size: 15,
                    ),
                    SizedBox(
                      width: 5,
                    ),
                    Text('Edit profile'),
                  ],
                ),
              ),
            ),
          const SizedBox(
            height: 20,
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.mail_outline_rounded),
              title: const Text('Email Address'),
              subtitle: Text(
                profile.emailAddress,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: const Text('Wallet Address'),
              subtitle: Text(
                profile.walletAddress,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ),
          ),
          if (isOwnProfile)
            FutureBuilder<String?>(
              future: _getPrivateKey(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                final key = snapshot.data!;
                return PrivateKeyDisplay(
                  privateKey: key,
                );
              },
            ),
          profile.location != null
              ? Card(
                  child: ListTile(
                    leading: const Icon(Icons.location_on_outlined),
                    title: const Text('Location'),
                    subtitle: Text(
                      profile.location!,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                  ),
                )
              : const Card(
                  child: ListTile(
                    leading: Icon(Icons.location_on_outlined),
                    title: Text('No Location Set'),
                  ),
                ),
          const SizedBox(
            height: 20,
          ),
          if (isOwnProfile)
            Card(
              child: ListTile(
                leading: const Icon(Icons.share),
                title: const Text(
                  'Share your profile',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Invite your friends and family here'),
                trailing: const Icon(Icons.file_upload_outlined),
                onTap: () {},
              ),
            )
        ],
      ),
    );
  }
}

class PrivateKeyDisplay extends StatefulWidget {
  final String privateKey;
  const PrivateKeyDisplay({super.key, required this.privateKey});

  @override
  State<PrivateKeyDisplay> createState() => _PrivateKeyDisplayState();
}

class _PrivateKeyDisplayState extends State<PrivateKeyDisplay> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    final key = widget.privateKey;
    // Mask all except first 6 and last 4 chars if obscured
    final displayKey = _obscured
        ? '${key.substring(0, 6)}••••••••••••${key.substring(key.length - 4)}'
        : key;

    return Card(
      child: ListTile(
        leading: const Icon(Icons.lock_outline),
        title: const Text('Private Key'),
        subtitle: Text(
          displayKey,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            fontFamily: 'monospace',
          ),
        ),
        trailing: InkWell(
            onTap: () {
              setState(() {
                _obscured = !_obscured;
              });
            },
            child: Icon(_obscured ? Icons.visibility : Icons.visibility_off)),
      ),
    );
  }
}
