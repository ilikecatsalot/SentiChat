import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sentichat/models/ChatRoomModel.dart';
import 'package:sentichat/models/FirebaseHelper.dart';
import 'package:sentichat/models/UserModel.dart';
import 'package:sentichat/pages/ChatRoomPage.dart';
import 'package:sentichat/pages/ClassificationPage.dart';
import 'package:sentichat/pages/LoginPage.dart';
import 'package:sentichat/pages/SearchPage.dart';

class HomePage extends StatefulWidget {
  final UserModel userModel;
  final User firebaseUser;

  const HomePage({Key? key, required this.userModel, required this.firebaseUser}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isEmpty = true; // Variable to track if the page is empty

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Senti',
                style: TextStyle(
                  color: Color(0xFF663187),
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: 'Chat',
                style: TextStyle(
                  color: Color(0xFFC490D1),
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.popUntil(context, (route) => route.isFirst);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return LoginPage();
                  },
                ),
              );
            },
            icon: Icon(Icons.exit_to_app),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder(
          stream: FirebaseFirestore.instance.collection("chatrooms").where("participants.${widget.userModel.uid}", isEqualTo: true).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.active) {
              if (snapshot.hasData) {
                QuerySnapshot chatRoomSnapshot = snapshot.data as QuerySnapshot;
                bool newIsEmpty = chatRoomSnapshot.docs.isEmpty;

                // Update the state only if there's a change
                if (newIsEmpty != isEmpty) {
                  WidgetsBinding.instance?.addPostFrameCallback((_) {
                    setState(() {
                      isEmpty = newIsEmpty;
                    });
                  });
                }

                if (isEmpty) {
                  return buildEmptyState();
                } else {
                  return buildChatRooms(chatRoomSnapshot);
                }
              } else if (snapshot.hasError) {
                return Center(
                  child: Text(snapshot.error.toString()),
                );
              } else {
                return Center(
                  child: Text("No Chats"),
                );
              }
            } else {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
          },
        ),
      ),
      floatingActionButton: isEmpty ? null : buildFloatingActionButton(),
    );
  }

  Widget buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 300, // Adjust button width as needed
            height: 170, // Adjust button height as needed, increased to accommodate labels below icons
            child: Column(
              children: [
                SizedBox(
                  width: 120, // Adjust size of FloatingActionButton
                  height: 120, // Adjust size of FloatingActionButton
                  child: FloatingActionButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) {
                          return SearchPage(userModel: widget.userModel, firebaseUser: widget.firebaseUser);
                        }),
                      );
                    },
                    heroTag: null,
                    child: Icon(Icons.search, size: 80), // Adjust size of Icon
                  ),
                ),
                SizedBox(height: 20), // Adjust spacing between icon and label
                Text(
                  'Search For People',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold), // Adjust font size and weight
                ),
              ],
            ),
          ),
          SizedBox(height: 100), // Adjust spacing between buttons
          Container(
            width: 300, // Adjust button width as needed
            height: 170, // Adjust button height as needed, increased to accommodate labels below icons
            child: Column(
              children: [
                SizedBox(
                  width: 120, // Adjust size of FloatingActionButton
                  height: 120, // Adjust size of FloatingActionButton
                  child: FloatingActionButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) {
                          return ClassificationPage(userModel: widget.userModel, firebaseUser: widget.firebaseUser,);
                        }),
                      );
                    },
                    heroTag: null,
                    child: Icon(Icons.analytics, size: 80), // Adjust size of Icon
                  ),
                ),
                SizedBox(height: 20), // Adjust spacing between icon and label
                Text(
                  'Interest Classes',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold), // Adjust font size and weight
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }



  Widget buildChatRooms(QuerySnapshot chatRoomSnapshot) {
    return ListView.builder(
      itemCount: chatRoomSnapshot.docs.length,
      itemBuilder: (context, index) {
        ChatRoomModel chatRoomModel = ChatRoomModel.fromMap(chatRoomSnapshot.docs[index].data() as Map<String, dynamic>);
        Map<String, dynamic> participants = chatRoomModel.participants!;
        List<String> participantKeys = participants.keys.toList();
        participantKeys.remove(widget.userModel.uid);
        return FutureBuilder<UserModel?>(
          future: FirebaseHelper.getUserModelById(participantKeys[0]),
          builder: (context, AsyncSnapshot<UserModel?> userData) {
            if (userData.connectionState == ConnectionState.done) {
              if (userData.hasData && userData.data != null) {
                UserModel targetUser = userData.data!;
                return ChatRoomTile(
                  chatRoomModel: chatRoomModel,
                  targetUser: targetUser,
                  firebaseUser: widget.firebaseUser,
                  userModel: widget.userModel,
                );
              } else {
                return Container(); // Placeholder for handling null data scenario
              }
            } else {
              return CircularProgressIndicator(); // Placeholder for loading state
            }
          },
        );
      },
    );
  }

  Widget buildFloatingActionButton() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return SearchPage(userModel: widget.userModel, firebaseUser: widget.firebaseUser);
            }));
          },
          child: Icon(Icons.search),
          heroTag: null,
        ),
        SizedBox(height: 10),
        FloatingActionButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return ClassificationPage(userModel: widget.userModel, firebaseUser: widget.firebaseUser);
            }));
          },
          child: Icon(Icons.analytics),
          heroTag: null,
        ),
      ],
    );
  }
}

class ChatRoomTile extends StatelessWidget {
  final ChatRoomModel chatRoomModel;
  final UserModel targetUser;
  final User firebaseUser;
  final UserModel userModel;

  const ChatRoomTile({
    Key? key,
    required this.chatRoomModel,
    required this.targetUser,
    required this.firebaseUser,
    required this.userModel,
  }) : super(key: key);

  void deleteChatroom(BuildContext context) async {
    try {
      // Delete all messages in the chatroom
      await FirebaseFirestore.instance
          .collection("chatrooms")
          .doc(chatRoomModel.chatroomid)
          .collection("messages")
          .get()
          .then((querySnapshot) {
        querySnapshot.docs.forEach((doc) {
          doc.reference.delete();
        });
      });

      // Delete the chatroom document itself
      await FirebaseFirestore.instance
          .collection("chatrooms")
          .doc(chatRoomModel.chatroomid)
          .delete();

      // Optional: Update UI or show a message after deletion
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Chatroom deleted"),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // Handle any errors that occur during deletion
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to delete chatroom"),
          duration: Duration(seconds: 2),
        ),
      );
      print("Failed to delete chatroom: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) {
            return ChatRoomPage(
              chatroom: chatRoomModel,
              firebaseUser: firebaseUser,
              userModel: userModel,
              targetUser: targetUser,
            );
          }),
        );
      },
      leading: GestureDetector(
        onTap: () {
          // Show zoomed profile picture in an AlertDialog
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: Colors.transparent,
              content: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Center(
                  child: Hero(
                    tag: 'profile_${targetUser.uid}',
                    child: CircleAvatar(
                      radius: 100.0,
                      backgroundImage: NetworkImage(targetUser.profilepic.toString()),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        child: Hero(
          tag: 'profile_${targetUser.uid}',
          child: CircleAvatar(
            backgroundImage: NetworkImage(targetUser.profilepic.toString()),
          ),
        ),
      ),
      title: Text(targetUser.fullname.toString()),
      subtitle: (chatRoomModel.lastMessage.toString().isNotEmpty)
          ? Text(chatRoomModel.lastMessage.toString())
          : Text(
        "Say hi to your new friend!",
        style: TextStyle(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
      trailing: IconButton(
        icon: Icon(Icons.delete),
        onPressed: () {
          // Show confirmation dialog before deletion
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text("Delete Chatroom"),
                content: Text("Are you sure you want to delete this chatroom?"),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                    },
                    child: Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () {
                      deleteChatroom(context); // Call delete function
                      Navigator.of(context).pop(); // Close dialog
                    },
                    child: Text("Delete"),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

