import 'package:flutter/material.dart';
import 'package:arbichat/chatpage/model/message_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class SearchBarWidget extends StatefulWidget {
  final Function(UserProfile, ChatMessage) onAddressVerified;

  const SearchBarWidget({super.key, required this.onAddressVerified});

  @override
  // ignore: library_private_types_in_public_api
  _SearchBarWidgetState createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  TextEditingController addressController = TextEditingController();
  String? _searchResult;

  bool isValidEthereumAddress(String otherUserAddress) {
    if (otherUserAddress.startsWith('0x') && otherUserAddress.length == 42) {
      try {
        // Remove the "0x" prefix before converting to bytes
        hexToBytes(otherUserAddress.substring(2));
        return true;
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  Future<void> searchWalletAddress(String otherUserAddress, BuildContext context) async {
    try {
      final docRef =
          FirebaseFirestore.instance.collection('users').doc(otherUserAddress);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        UserProfile userProfile = UserProfile(
          interactionScore:
              (docSnapshot.data()?['interactionScore'] as num?)?.toInt() ?? 0,
          walletBalance:
              (docSnapshot.data()?['walletBalance'] as num?)?.toDouble() ?? 0.0,
          walletAddress: otherUserAddress,
          name: docSnapshot.data()?['name'] ?? 'Unknown',
          avatarUrl: (docSnapshot.data()?['avatarUrl'] ?? 'assets/profileplaceholder.png')
        );

        final prefs = await SharedPreferences.getInstance();
        final privateKey = prefs.getString('privateKey') ?? '0';
        final credentials = EthPrivateKey.fromHex(privateKey);
        final userWalletAddress = await credentials.extractAddress();

        // Create a message for the chat
        ChatMessage message = ChatMessage(
          sender: userWalletAddress, // You'll need this
          receiver: EthereumAddress.fromHex(otherUserAddress),
          cid: '',
          timestamp: BigInt.from(DateTime.now().millisecondsSinceEpoch ~/ 1000),
          deleted: false,
          plaintext: 'Start a conversation with ${userProfile.name}',
        );

        setState(() {
          _searchResult = otherUserAddress;
        });

        // Pass userProfile and message back to the parent widget
        widget.onAddressVerified(userProfile, message);

        // Clear the address input
        addressController.clear();
      } else {
        setState(() {
          _searchResult = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Wallet address is not registered with ArbiChat.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error searching Firestore: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            controller: addressController,
            decoration: InputDecoration(
              fillColor: Colors.grey.shade200,
              filled: true,
              hintText: 'Enter EVM Address',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                onPressed: () {
                  String address = addressController.text.trim();
                  if (isValidEthereumAddress(address)) {
                    searchWalletAddress(address, context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Invalid Ethereum address",)),
                    );
                  }
                },
                icon: const Icon(Icons.check),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 0),
        ],
      ),
    );
  }
}
