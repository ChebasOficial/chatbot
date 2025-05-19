import 'package:flutter/material.dart';
import 'package:chatbot/utils/firebase_auth_tester.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({Key? key}) : super(key: key);

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  String _testResult = "Aguardando teste...";
  bool _isLoading = false;

  Future<void> _runTest() async {
    setState(() {
      _isLoading = true;
      _testResult = "Executando teste...";
    });

    try {
      final result = await FirebaseAuthTester.testFirebaseAuth();
      setState(() {
        _testResult = result;
      });
    } catch (e) {
      setState(() {
        _testResult = "Erro ao executar teste: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teste de Firebase Auth'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _runTest,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Executar Teste de Firebase'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Resultado do Teste:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(_testResult),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
