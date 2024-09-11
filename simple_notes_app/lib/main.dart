import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const NotesApp());
}

class NotesApp extends StatelessWidget {
  const NotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Enhanced Notes App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const NotesHomePage(),
    );
  }
}

class NotesHomePage extends StatefulWidget {
  const NotesHomePage({super.key});

  @override
  _NotesHomePageState createState() => _NotesHomePageState();
}

class _NotesHomePageState extends State<NotesHomePage> {
  List<Map<String, String>> _notes = [];
  List<Map<String, String>> _filteredNotes = [];
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final String _searchText = "";

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  // Load saved notes from SharedPreferences
  _loadNotes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? notesData = prefs.getStringList('notes');

    if (notesData != null) {
      setState(() {
        _notes = notesData.map((note) {
          final splitNote = note.split('||');
          return {"text": splitNote[0], "timestamp": splitNote[1]};
        }).toList();
        _filteredNotes = _notes;
      });
    }
  }

  // Save notes to SharedPreferences
  _saveNotes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> notesData = _notes.map((note) => "${note['text']}||${note['timestamp']}").toList();
    prefs.setStringList('notes', notesData);
  }

  // Add or Edit a note
  _addOrEditNote([int? index]) {
    String timestamp = DateFormat('yyyy-MM-dd – kk:mm').format(DateTime.now());
    if (index == null) {
      setState(() {
        _notes.add({"text": _noteController.text, "timestamp": timestamp});
      });
    } else {
      setState(() {
        _notes[index] = {"text": _noteController.text, "timestamp": _notes[index]['timestamp']!};
      });
    }
    _noteController.clear();
    _saveNotes();
  }

  // Delete a note
  _deleteNote(int index) {
    setState(() {
      _notes.removeAt(index);
    });
    _saveNotes();
  }

  // Search functionality
  _searchNotes(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredNotes = _notes;
      } else {
        _filteredNotes = _notes
            .where((note) => note['text']!.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  // Show dialog for adding/editing notes
  _showNoteDialog([int? index]) {
    if (index != null) {
      _noteController.text = _notes[index]['text']!;
    }
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(index == null ? 'Add Note' : 'Edit Note'),
          content: TextField(
            controller: _noteController,
            decoration: const InputDecoration(labelText: 'Enter a note'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _addOrEditNote(index);
                Navigator.of(context).pop();
              },
              child: Text(index == null ? 'Add' : 'Edit'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: NotesSearch(_filteredNotes),
              );
            },
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Notes',
                border: OutlineInputBorder(),
              ),
              onChanged: _searchNotes,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredNotes.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_filteredNotes[index]['text']!),
                  subtitle: Text('Created: ${_filteredNotes[index]['timestamp']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteNote(index),
                  ),
                  onTap: () => _showNoteDialog(index),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () => _showNoteDialog(),
              child: const Text('Add Note'),
            ),
          ),
        ],
      ),
    );
  }
}

class NotesSearch extends SearchDelegate {
  final List<Map<String, String>> notes;
  NotesSearch(this.notes);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [IconButton(onPressed: () => query = '', icon: const Icon(Icons.clear))];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(onPressed: () => close(context, null), icon: const Icon(Icons.arrow_back));
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = notes.where((note) => note['text']!.toLowerCase().contains(query.toLowerCase())).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(results[index]['text']!),
          subtitle: Text('Created: ${results[index]['timestamp']}'),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = notes.where((note) => note['text']!.toLowerCase().contains(query.toLowerCase())).toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(suggestions[index]['text']!),
          subtitle: Text('Created: ${suggestions[index]['timestamp']}'),
        );
      },
    );
  }
}