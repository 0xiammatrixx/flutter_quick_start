import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:w3aflutter/chatpage/model/chat_model.dart';
import 'package:w3aflutter/chatpage/model/message_model.dart';
import 'package:w3aflutter/chatpage/widgets/chat_widget.dart';
import 'package:w3aflutter/chatpage/widgets/search_bar.dart';
import 'package:w3aflutter/profilepage/page/profile_page.dart';
import 'message_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/web3dart.dart' as web3dart;

class ChatsPage extends StatefulWidget {
  ChatsPage({super.key});

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  final FocusNode _searchFocusNode = FocusNode();
  List<Chat> chats = []; // Initialize an empty list of chats
  bool loading = true;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? currentWalletAddress;

  @override
  void initState() {
    super.initState();
    print("initState called");
    _loadChats();
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _loadChats() async {
    print("Loading chats...");
  final prefs = await SharedPreferences.getInstance();
  final privateKey = prefs.getString('privateKey');
  print("Private key retrieved: $privateKey");


  if (privateKey != null) {
    final credentials = web3dart.EthPrivateKey.fromHex(privateKey);
    currentWalletAddress = credentials.address.hexEip55;
    print("Current wallet address: $currentWalletAddress");

    List<Chat> tempChats = []; // Temporary list for batch updates

    final querySnapshot = await _firestore
        .collection('users')
        .doc(currentWalletAddress)
        .collection('messages')
        .get();

      print("Query snapshot retrieved: ${querySnapshot.docs.length} documents");


    if (querySnapshot.docs.isEmpty) {
      setState(() {
        loading = false;
      });
      print("No chat documents found.");
      return;
    }

    for (var doc in querySnapshot.docs) {
      String otherWalletAddress = doc.id;
      print("Processing chat with: $otherWalletAddress");

      final userProfileSnapshot = await _firestore
        .collection('users')
        .doc(otherWalletAddress)
        .get();

      if (!userProfileSnapshot.exists) {
        print("User profile not found for: $otherWalletAddress");
        continue;
      }

      final userProfileData = userProfileSnapshot.data()!;
      print("User profile data for $otherWalletAddress: $userProfileData");
      var userProfile = UserProfile.fromMap(userProfileData);

      String avatarUrl = userProfileData['avatarUrl'] ?? 'assets/profileplaceholder.png';

      final messagesSnapshot = await _firestore
          .collection('users')
          .doc(currentWalletAddress)
          .collection('messages')
          .doc(otherWalletAddress)
          .collection('chat')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();
          print("Messages snapshot retrieved for $otherWalletAddress: ${messagesSnapshot.docs.length} messages");

      if (messagesSnapshot.docs.isNotEmpty) {
        final lastMessage = Message.fromFirestore(messagesSnapshot.docs.first);
        print("Last message content: ${lastMessage.messageContent}");

        tempChats.add(Chat(
          userProfile: userProfile,
          message: lastMessage,
          avatarUrl: avatarUrl,
          isUnread: !lastMessage.isRead && !lastMessage.isSentByUser,
          isRead: lastMessage.isRead,
          unreadCount: lastMessage.isRead ? 0 : 1,
        ));
      }
    }

    setState(() {
      chats = tempChats;
      loading = false;
    });
  }
}


  void addNewChat(UserProfile userProfile, Message message) async {
    // Check if a chat with the given userProfile already exists
    bool chatExists = chats.any(
        (chat) => chat.userProfile.walletAddress == userProfile.walletAddress);

    if (chatExists) {
      // If the chat exists, open it instead of creating a new one
      // Find the index of the existing chat
      int chatIndex = chats.indexWhere((chat) =>
          chat.userProfile.walletAddress == userProfile.walletAddress);

      // Open the existing chat (navigate to MessagingPage)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MessagingPage(
            userProfile: chats[chatIndex].userProfile,
          ),
        ),
      );
    } else {

      final userProfileSnapshot = await _firestore
        .collection('users')
        .doc(userProfile.walletAddress)
        .get();

    String avatarUrl = 'assets/profileplaceholder.png'; // Default avatar URL

    if (userProfileSnapshot.exists) {
      final userProfileData = userProfileSnapshot.data();
      // Check if avatarUrl exists in userProfile data, otherwise use placeholder
      avatarUrl = userProfileData?['avatarUrl'] ?? avatarUrl;
    }

      // If the chat doesn't exist, add a new chat to the list
      setState(() {
        chats.add(Chat(
          userProfile: userProfile,
          message: message,
          avatarUrl:
              'assets/profileplaceholder.png',
          isUnread: true, // Set to true for the new chat
          isRead: false,
          unreadCount: 1, // You can adjust this logic as needed
        ));
      });

      // After adding the new chat, navigate to the new chat page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MessagingPage(
            userProfile: userProfile,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Messages',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
        ),
        actions: <Widget>[
          IconButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => ProfilePage()));
              },
              icon: Icon(Icons.person))
        ],
      ),
      body: Container(
        padding: EdgeInsets.all(20),
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Column(
            children: [
              SearchBarWidget(
                onAddressVerified:
                    addNewChat, // Pass the function to add new chats
              ),
              SizedBox(height: screenHeight * 0.05),
              const Divider(),
              Expanded(
                child: loading
                    ? Center(
                        child: CircularProgressIndicator(),
                      )
                    : ListView.builder(
                        itemCount: chats.length,
                        itemBuilder: (context, index) {
                          return ChatTile(
                            chat: chats[index],
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MessagingPage(
                                    userProfile: chats[index].userProfile,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
