import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sentichat/models/UserModel.dart';
import 'package:sentichat/models/ChatRoomModel.dart';
import 'package:sentichat/pages/ChatRoomPage.dart';

import '../models/FirebaseHelper.dart';

class ClassificationPage extends StatefulWidget {
    final UserModel userModel;
    final User firebaseUser;

    ClassificationPage({required this.userModel, required this.firebaseUser});

    @override
    _ClassificationPageState createState() => _ClassificationPageState();
}

class _ClassificationPageState extends State<ClassificationPage> {
    Map<String, String> userClassifications = {};
    bool isLoading = false;
    String? errorMessage;
    List<String> _classifications = [];
    String? _selectedClassification;

    Future<void> fetchClassifications() async {
        setState(() {
            isLoading = true;
            errorMessage = null;
        });

        try {
            final response =
            await http.get(Uri.parse('https://religious-alla-dibru-adfe3639.koyeb.app/classify_all'));

            if (response.statusCode == 200) {
                final data = jsonDecode(response.body) as Map<String, dynamic>;

                setState(() {
                    userClassifications = {};
                    _classifications = [];

                    data.forEach((userId, classifications) {
                        if (classifications is List<dynamic>) {
                            // Count frequency of each classification
                            Map<String, int> frequencyMap = {};
                            for (var classification in classifications) {
                                if (classification is String) {
                                    frequencyMap[classification] = (frequencyMap[classification] ?? 0) + 1;
                                }
                            }

                            // Find the most frequent classification
                            String mostFrequentClass = '';
                            if (frequencyMap.isNotEmpty) {
                                mostFrequentClass = frequencyMap.entries.fold('', (prev, entry) {
                                    return entry.value > (frequencyMap[prev] ?? 0) ? entry.key : prev;
                                });
                            }

                            userClassifications[userId] = mostFrequentClass;

                            if (!_classifications.contains(mostFrequentClass)) {
                                _classifications.add(mostFrequentClass);
                            }
                        }
                    });

                    isLoading = false;
                });
            } else {
                setState(() {
                    errorMessage = 'Failed to load classifications: ${response.reasonPhrase}';
                    isLoading = false;
                });
            }
        } catch (e) {
            setState(() {
                errorMessage = 'An error occurred: $e';
                isLoading = false;
            });
        }
    }

    Future<String?> fetchUidByFullName(String fullName) async {
        try {
            QuerySnapshot snapshot = await FirebaseFirestore.instance
                .collection('users')
                .where('fullname', isEqualTo: fullName)
                .get();

            if (snapshot.docs.isNotEmpty) {
                return snapshot.docs.first.id;
            } else {
                return null;
            }
        } catch (e) {
            print('Error fetching UID by full name: $e');
            return null;
        }
    }

    Future<ChatRoomModel?> getChatroomModel(UserModel targetUser) async {
        try {
            QuerySnapshot snapshot = await FirebaseFirestore.instance
                .collection('chatrooms')
                .where('participants.${widget.userModel.uid}', isEqualTo: true)
                .where('participants.${targetUser.uid!}', isEqualTo: true)
                .get();

            if (snapshot.docs.isNotEmpty) {
                // Fetch the existing chatroom
                var docData = snapshot.docs[0].data();
                ChatRoomModel existingChatroom = ChatRoomModel.fromMap(docData as Map<String, dynamic>);
                return existingChatroom;
            } else {
                // Create a new chatroom
                ChatRoomModel newChatroom = ChatRoomModel(
                    chatroomid: FirebaseFirestore.instance.collection('chatrooms').doc().id,
                    participants: {
                        widget.userModel.uid!: true,
                        targetUser.uid!: true,
                    },
                    lastMessage: '', // You can set an initial value for lastMessage if needed
                );

                await FirebaseFirestore.instance.collection('chatrooms').doc(newChatroom.chatroomid).set(newChatroom.toMap());

                return newChatroom;
            }
        } catch (e) {
            print('Error fetching or creating chatroom: $e');
            return null;
        }
    }

    @override
    void initState() {
        super.initState();
        fetchClassifications();
    }

    @override
    Widget build(BuildContext context) {
        // Apply filtering based on selected classification
        final filteredClassifications = _selectedClassification == null
            ? userClassifications.entries.toList()
            : userClassifications.entries.where((entry) => entry.value == _selectedClassification).toList();

        return Scaffold(
            appBar: AppBar(
                title: Text('User Classifications'),
            ),
            body: isLoading
                ? Center(child: CircularProgressIndicator())
                : errorMessage != null
                ? Center(child: Text(errorMessage!))
                : Column(
                children: [
                    Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                            children: [
                                Expanded(
                                    child: DropdownButtonFormField<String>(
                                        value: _selectedClassification,
                                        decoration: InputDecoration(
                                            labelText: 'Filter by Classification',
                                            border: OutlineInputBorder(),
                                        ),
                                        items: [
                                            DropdownMenuItem(
                                                value: null,
                                                child: Text('View All'),
                                            ),
                                            ..._classifications.map(
                                                    (classification) => DropdownMenuItem(
                                                    value: classification,
                                                    child: Text(classification),
                                                ),
                                            ),
                                        ],
                                        onChanged: (classification) {
                                            setState(() {
                                                _selectedClassification = classification;
                                            });
                                        },
                                    ),
                                ),
                            ],
                        ),
                    ),
                    Expanded(
                        child: filteredClassifications.isEmpty
                            ? Center(child: Text('No data available'))
                            : ListView.builder(
                            itemCount: filteredClassifications.length,
                            itemBuilder: (context, index) {
                                String fullName = filteredClassifications[index].key;
                                String classification = filteredClassifications[index].value ?? 'Unknown';

                                // Fetch UID using the full name
                                return FutureBuilder<String?>(
                                    future: fetchUidByFullName(fullName),
                                    builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                            return ListTile(
                                                leading: CircularProgressIndicator(),
                                                title: Text('User: $fullName'),
                                                subtitle: Text('Fetching UID...'),
                                            );
                                        } else if (snapshot.connectionState == ConnectionState.done) {
                                            if (snapshot.hasData && snapshot.data != null) {
                                                String uid = snapshot.data!;

                                                // Fetch UserModel using the UID
                                                return FutureBuilder<UserModel?>(
                                                    future: FirebaseHelper.getUserModelById(uid),
                                                    builder: (context, userSnapshot) {
                                                        if (userSnapshot.connectionState == ConnectionState.waiting) {
                                                            return ListTile(
                                                                leading: CircularProgressIndicator(),
                                                                title: Text('User: $fullName'),
                                                                subtitle: Text('Fetching data...'),
                                                            );
                                                        } else if (userSnapshot.connectionState == ConnectionState.done) {
                                                            if (userSnapshot.hasData && userSnapshot.data != null) {
                                                                UserModel user = userSnapshot.data!;
                                                                return ListTile(
                                                                    onTap: () async {
                                                                        ChatRoomModel? chatroomModel = await getChatroomModel(user);

                                                                        if (chatroomModel != null) {
                                                                            Navigator.push(
                                                                                context,
                                                                                MaterialPageRoute(
                                                                                    builder: (context) => ChatRoomPage(
                                                                                        chatroom: chatroomModel,
                                                                                        userModel: widget.userModel,
                                                                                        targetUser: user,
                                                                                        firebaseUser: widget.firebaseUser,
                                                                                    ),
                                                                                ),
                                                                            );
                                                                        }
                                                                    },

                                                                    leading: CircleAvatar(
                                                                        backgroundImage: user.profilepic != null && user.profilepic!.isNotEmpty
                                                                            ? NetworkImage(user.profilepic!)
                                                                            : AssetImage('assets/default_profile_pic.png') as ImageProvider<Object>,
                                                                        backgroundColor: Colors.grey[500],
                                                                    ),
                                                                    title: Text(user.fullname ?? 'Unknown'),
                                                                    subtitle: Text('Classification: $classification'),
                                                                    trailing: Icon(Icons.keyboard_arrow_right),
                                                                );
                                                            } else {
                                                                return ListTile(
                                                                    leading: CircleAvatar(
                                                                        backgroundImage: AssetImage('assets/default_profile_pic.png'),
                                                                        backgroundColor: Colors.grey[500],
                                                                    ),
                                                                    title: Text('User: $fullName'),
                                                                    subtitle: Text('Classification: $classification'),
                                                                );
                                                            }
                                                        } else {
                                                            return ListTile(
                                                                leading: CircleAvatar(
                                                                    backgroundImage: AssetImage('assets/default_profile_pic.png'),
                                                                    backgroundColor: Colors.grey[500],
                                                                ),
                                                                title: Text('User: $fullName'),
                                                                subtitle: Text('Connection State: ${userSnapshot.connectionState}'),
                                                            );
                                                        }
                                                    },
                                                );
                                            } else {
                                                return ListTile(
                                                    leading: CircleAvatar(
                                                        backgroundImage: AssetImage('assets/default_profile_pic.png'),
                                                        backgroundColor: Colors.grey[500],
                                                    ),
                                                    title: Text('User: $fullName'),
                                                    subtitle: Text('Classification: $classification'),
                                                );
                                            }
                                        } else {
                                            return ListTile(
                                                leading: CircleAvatar(
                                                    backgroundImage: AssetImage('assets/default_profile_pic.png'),
                                                    backgroundColor: Colors.grey[500],
                                                ),
                                                title: Text('User: $fullName'),
                                                subtitle: Text('Connection State: ${snapshot.connectionState}'),
                                            );
                                        }
                                    },
                                );
                            },
                        ),
                    ),
                ],
            ),
        );
    }
}
