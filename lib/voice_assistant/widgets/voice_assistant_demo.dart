import 'package:flutter/material.dart';
import 'voice_assistant_wrapper.dart';

/// A demo screen for showcasing the voice assistant
class VoiceAssistantDemo extends StatefulWidget {
  const VoiceAssistantDemo({Key? key}) : super(key: key);

  @override
  State<VoiceAssistantDemo> createState() => _VoiceAssistantDemoState();
}

class _VoiceAssistantDemoState extends State<VoiceAssistantDemo> {
  List<String> _commands = [];

  @override
  Widget build(BuildContext context) {
    return VoiceAssistantWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Voice Assistant Demo'),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Voice Assistant Instructions:',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tap the microphone button in the bottom right corner to start speaking. '
                        'The voice assistant supports both English and Urdu languages.\n\n'
                        'Try these commands:',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      _buildCommandItem('Add banana to cart', 'کیلے کارٹ میں شامل کریں'),
                      _buildCommandItem('Remove apple from cart', 'سیب کارٹ سے نکالیں'),
                      _buildCommandItem('Check my cart', 'میرا کارٹ چیک کریں'),
                      _buildCommandItem('Checkout', 'چیک آؤٹ کریں'),
                      _buildCommandItem('Search for milk', 'دودھ تلاش کریں'),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Command History:',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _commands.clear();
                                });
                              },
                              child: const Text('Clear'),
                            ),
                          ],
                        ),
                        const Divider(),
                        Expanded(
                          child: _commands.isEmpty
                              ? Center(
                                  child: Text(
                                    'No commands yet. Try speaking to the assistant!',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Colors.grey,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _commands.length,
                                  itemBuilder: (context, index) {
                                    return ListTile(
                                      leading: Icon(
                                        Icons.record_voice_over,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                      title: Text(_commands[index]),
                                      subtitle: Text('Command ${_commands.length - index}'),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommandItem(String englishText, String urduText) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          const Icon(Icons.mic, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  englishText,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  urduText,
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 