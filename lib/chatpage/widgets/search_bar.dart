import 'package:flutter/material.dart';
import 'package:w3aflutter/chatpage/model/message_model.dart';
import 'package:web3dart/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SearchBarWidget extends StatefulWidget {
  final Function(UserProfile, Message) onAddressVerified;

  const SearchBarWidget({super.key, required this.onAddressVerified});

  @override
  _SearchBarWidgetState createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  TextEditingController addressController = TextEditingController();
  String? _searchResult;

  bool isValidEthereumAddress(String address) {
  if (address.startsWith('0x') && address.length == 42) {
    try {
      // Remove the "0x" prefix before converting to bytes
      hexToBytes(address.substring(2));
      return true;
    } catch (e) {
      return false;
    }
  }
  return false;
}


  Future<void> searchWalletAddress(String address, BuildContext context) async {
    try {
      final docRef =
          FirebaseFirestore.instance.collection('users').doc(address);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        UserProfile userProfile = UserProfile(
          interactionScore:
              (docSnapshot.data()?['interactionScore'] as num?)?.toInt() ?? 0,
          walletBalance:
              (docSnapshot.data()?['walletBalance'] as num?)?.toDouble() ?? 0.0,
          walletAddress: address,
          name: docSnapshot.data()?['name'] ?? 'Unknown',
        );

        // Create a message for the chat
        Message message = Message(
          messageContent: 'New chat initiated with ${userProfile.name}',
          isSentByUser: true,
          senderAddress: address,
          timestamp: DateTime.now(), 
          isRead: false,
        );

        setState(() {
          _searchResult = address;
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
          SnackBar(
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
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            controller: addressController,
            decoration: InputDecoration(
              fillColor: Colors.grey.shade200,
              filled: true,
              hintText: 'Enter EVM Address',
              prefixIcon: Icon(Icons.search),
              suffixIcon: IconButton(
                onPressed: () {
                  String address = addressController.text.trim();
                  if (isValidEthereumAddress(address)) {
                    searchWalletAddress(address, context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Invalid Ethereum address")),
                    );
                  }
                },
                icon: Icon(Icons.check),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}
