import 'package:flutter/material.dart';
import '../widgets/row_button_stack.dart';

class HorcruxGallery extends StatelessWidget {
  const HorcruxGallery({super.key});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return Scaffold(
          appBar: AppBar(
            title: const Text('UI Component Gallery'),
            actions: [
              PopupMenuButton(
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'a', child: Text('First action')),
                  PopupMenuItem(value: 'b', child: Text('Second action')),
                ],
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Buttons', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Primary'),
                  ),
                  OutlinedButton(
                    onPressed: () {},
                    child: const Text('Secondary'),
                  ),
                  TextButton(onPressed: () {}, child: const Text('Tertiary')),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.more_horiz),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Form', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              const Text("Here is some explanatory body text for a field."),
              const SizedBox(height: 8),
              const TextField(
                decoration: InputDecoration(labelText: 'Vault name'),
              ),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(labelText: 'Username'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      obscureText: true,
                      decoration: InputDecoration(labelText: 'Password'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Switch(value: true, onChanged: (_) {}),
                  const SizedBox(width: 8),
                  const Text('Remember me'),
                ],
              ),
              const SizedBox(height: 24),
              Text('List', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              ...ListTile.divideTiles(
                context: context,
                tiles: [
                  ListTile(
                    leading: _icon(context),
                    title: const Text('test vault'),
                    subtitle: const Text('Owner: You'),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                  ListTile(
                    leading: _icon(context),
                    title: const Text('new vault'),
                    subtitle: const Text('Owner: You'),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('Saved!')));
                    },
                    child: const Text('Show toast'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.error,
                      foregroundColor: cs.onError,
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: cs.error,
                          content: const Text('Something went wrong'),
                        ),
                      );
                    },
                    child: const Text('Show error'),
                  ),
                ],
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: RowButtonStack(
              buttons: [
                RowButtonConfig(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('First action')),
                    );
                  },
                  icon: Icons.download,
                  text: 'Import',
                ),
                RowButtonConfig(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Second action')),
                    );
                  },
                  icon: Icons.settings,
                  text: 'Settings',
                ),
                RowButtonConfig(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Primary action')),
                    );
                  },
                  icon: Icons.add,
                  text: 'Create Vault',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _icon(BuildContext context) => Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.lock_outline,
          color: Theme.of(context).colorScheme.onSurface,
          size: 24,
        ),
      );
}
