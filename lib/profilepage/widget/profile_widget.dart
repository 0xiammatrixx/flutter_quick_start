import 'package:flutter/material.dart';
import 'package:w3aflutter/profilepage/model/profile_model.dart';

class ProfileWidget extends StatelessWidget {
  final Profile profile;
  const ProfileWidget({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Stack(children: [
              Container(
                child: CircleAvatar(
                  backgroundImage: AssetImage(profile.avatarUrl),
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
          SizedBox(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                profile.name,
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
              SizedBox(
                width: 5,
              ),
              if (profile.isOnline)
                Icon(
                  Icons.circle,
                  size: 13,
                  color: Colors.blue,
                )
            ],
          ),
          const SizedBox(height: 5),
          SizedBox(
            width: screenWidth * 0.35,
            child: ElevatedButton(
              onPressed: () {},
              child: Row(
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
          Divider(),
          Card(
            child: ListTile(
              leading: Icon(Icons.mail_outline_rounded),
              title: Text('Email address'),
              subtitle: Text(
                profile.emailAddress,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.phone_enabled_outlined),
              title: Text('Wallet Address'),
              subtitle: Text(
                profile.walletAddress,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ),
          ),
          profile.location != null
              ? Card(
                  child: ListTile(
                    leading: Icon(Icons.location_on_outlined),
                    title: Text('Location'),
                    subtitle: Text(
                      profile.location!,
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                  ),
                )
              : Card(
                  child: ListTile(
                    leading: Icon(Icons.location_on_outlined),
                    title: Text('No Location Set'),
                  ),
                ),
          SizedBox(
            height: 20,
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.share),
              title: Text(
                'Share your profile',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('Invite your friends and family here'),
              trailing: Icon(Icons.file_upload_outlined),
              onTap: () {},
            ),
          )
        ],
      ),
    );
  }
}