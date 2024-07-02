import 'dart:developer';

import 'package:sentichat/main.dart';
import 'package:sentichat/models/ChatRoomModel.dart';
import 'package:sentichat/models/UserModel.dart';
import 'package:sentichat/pages/ChatRoomPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  final UserModel userModel;
  final User firebaseUser;

  const SearchPage({Key? key, required this.userModel, required this.firebaseUser}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {

  TextEditingController searchController = TextEditingController();

  Future<ChatRoomModel?> getChatroomModel(UserModel targetUser) async {
    ChatRoomModel? chatRoom;

    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection("chatrooms").where("participants.${widget.userModel.uid}", isEqualTo: true).where("participants.${targetUser.uid}", isEqualTo: true).get();

    if(snapshot.docs.isNotEmpty) {
      // Fetch the existing one
      var docData = snapshot.docs[0].data();
      ChatRoomModel existingChatroom = ChatRoomModel.fromMap(docData as Map<String, dynamic>);

      chatRoom = existingChatroom;
    } else {
      // Create a new one
      ChatRoomModel newChatroom = ChatRoomModel(
        chatroomid: uuid.v1(),
        lastMessage: "",
        participants: {
          widget.userModel.uid.toString(): true,
          targetUser.uid.toString(): true,
        },
      );

      await FirebaseFirestore.instance.collection("chatrooms").doc(newChatroom.chatroomid).set(newChatroom.toMap());

      chatRoom = newChatroom;

      log("New Chatroom Created!");
    }

    return chatRoom;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Search"),
      ),
      body: SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 10,
          ),
          child: Column(
            children: [
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                    labelText: "User Name"
                ),
                onChanged: (value) {
                  setState(() {});  // Triggers the StreamBuilder to refresh
                },
              ),
              SizedBox(height: 20,),
              StreamBuilder(
                stream: searchController.text.isEmpty
                    ? null
                    : FirebaseFirestore.instance.collection("users")
                    .where("fullname", isGreaterThanOrEqualTo: searchController.text)
                    .where("fullname", isLessThanOrEqualTo: searchController.text + '\uf8ff')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (searchController.text.isEmpty) {
                    return Text("Enter a username to search.");
                  }

                  if (snapshot.connectionState == ConnectionState.active) {
                    if (snapshot.hasData) {
                      QuerySnapshot dataSnapshot = snapshot.data as QuerySnapshot;

                      if (dataSnapshot.docs.isNotEmpty) {
                        return Expanded(
                          child: ListView.builder(
                            itemCount: dataSnapshot.docs.length,
                            itemBuilder: (context, index) {
                              Map<String, dynamic> userMap = dataSnapshot.docs[index].data() as Map<String, dynamic>;

                              UserModel searchedUser = UserModel.fromMap(userMap);

                              return ListTile(
                                onTap: () async {
                                  ChatRoomModel? chatroomModel = await getChatroomModel(searchedUser);

                                  if (chatroomModel != null) {
                                    Navigator.pop(context);
                                    Navigator.push(context, MaterialPageRoute(
                                        builder: (context) {
                                          return ChatRoomPage(
                                            targetUser: searchedUser,
                                            userModel: widget.userModel,
                                            firebaseUser: widget.firebaseUser,
                                            chatroom: chatroomModel,
                                          );
                                        }
                                    ));
                                  }
                                },
                                leading: CircleAvatar(
                                  backgroundImage: NetworkImage(searchedUser.profilepic ?? ""),
                                  backgroundColor: Colors.grey[500],
                                ),
                                title: Text(searchedUser.fullname ?? ""),
                                subtitle: Text(searchedUser.email ?? ""),
                                trailing: Icon(Icons.keyboard_arrow_right),
                              );
                            },
                          ),
                        );
                      } else {
                        return Text("No results found!");
                      }
                    } else if (snapshot.hasError) {
                      return Text("An error occurred!");
                    } else {
                      return Text("No results found!");
                    }
                  } else {
                    return Center(child: CircularProgressIndicator());
                  }
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
