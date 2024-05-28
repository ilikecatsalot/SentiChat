import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ClassificationPage extends StatefulWidget {
    @override
    _ClassificationPageState createState() => _ClassificationPageState();
}

class _ClassificationPageState extends State<ClassificationPage> {
    Map<String, String> userClassifications = {};
    bool isLoading = false;
    String? errorMessage;

    Future<void> fetchClassifications() async {
        setState(() {
            isLoading = true;
            errorMessage = null;
        });

        try {
            final response = await http.get(Uri.parse('http://127.0.0.1:5000/classify_all'));

            if (response.statusCode == 200) {
                final data = jsonDecode(response.body) as Map<String, dynamic>;

                setState(() {
                    userClassifications = {};

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

    @override
    void initState() {
        super.initState();
        fetchClassifications();
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: Text('User Classifications'),
            ),
            body: isLoading
                ? Center(child: CircularProgressIndicator())
                : errorMessage != null
                ? Center(child: Text(errorMessage!))
                : userClassifications.isEmpty
                ? Center(child: Text('No data available'))
                : ListView.builder(
                itemCount: userClassifications.length,
                itemBuilder: (context, index) {
                    String userId = userClassifications.keys.elementAt(index);
                    String classification = userClassifications[userId] ?? 'Unknown';
                    return ListTile(
                        title: Text('User ID: $userId'),
                        subtitle: Text('Classification: $classification'),
                    );
                },
            ),
        );
    }
}

