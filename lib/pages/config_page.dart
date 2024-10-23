import 'package:flutter/material.dart';
import 'package:trackmyrun/services/config_service.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

class ConfigPage extends StatefulWidget {
  const ConfigPage({Key? key}) : super(key: key);

  @override
  _ConfigPageState createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await ConfigService.loadConfig();
    setState(() {
      _nameController.text = config['name'] ?? '';
      _numberController.text = config['number'] ?? '';
    });
  }

  bool _validateInputs() {
    final name = _nameController.text;
    final numberText = _numberController.text;
    final number = int.tryParse(numberText);

    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(name)) {
      setState(() {
        _errorMessage = 'Name must be alphanumeric';
      });
      return false;
    }

    if (number == null || number < 1 || number > 999) {
      setState(() {
        _errorMessage = 'Bib number must be between 1 and 999';
      });
      return false;
    }

    setState(() {
      _errorMessage = null;
    });
    return true;
  }

  Future<void> _saveConfig() async {
    if (_validateInputs()) {
      await ConfigService.saveConfig(_nameController.text, _numberController.text);
      Navigator.pop(context); // Return to the home page
    }
  }

  Future<void> _resetConfig() async {
    await ConfigService.resetConfig();
    setState(() {
      _nameController.clear();
      _numberController.clear();
      _errorMessage = null; // Clear any existing error messages
    });
    // Optional: Show a snackbar or dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuration reset successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Votre nom:'),
            ),
            TextField(
              controller: _numberController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'N° de dossard:'),
            ),
            const SizedBox(height: 20),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _saveConfig,
              child: const Text('Valider'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _resetConfig,
              child: const Text('Réinitialiser'),
            ),
          ],
        ),
      ),
    );
  }
}
