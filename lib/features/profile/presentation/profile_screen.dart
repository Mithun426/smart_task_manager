import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/profile_repository.dart';
import '../../../core/theme/theme_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _editName(BuildContext context, WidgetRef ref, String currentName) async {
    final controller = TextEditingController(text: currentName);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Name', style: TextStyle(fontWeight: FontWeight.bold)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'New Name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark 
                ? Colors.grey.shade900 
                : Colors.grey.shade100,
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != currentName) {
      await ref.read(authControllerProvider.notifier).updateProfileName(result);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.value;
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark || 
                   (themeMode == ThemeMode.system && MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3), width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: TextStyle(fontSize: 36, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text('Personal Info', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.blue.withOpacity(0.15), shape: BoxShape.circle),
                          child: const Icon(Icons.person_rounded, color: Colors.blue),
                        ),
                        title: const Text('Name', style: TextStyle(fontSize: 13, color: Colors.grey)),
                        subtitle: Text(user.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_rounded, color: Colors.grey),
                          onPressed: () => _editName(context, ref, user.name),
                        ),
                      ),
                      Divider(height: 1, color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.orange.withOpacity(0.15), shape: BoxShape.circle),
                          child: const Icon(Icons.email_rounded, color: Colors.orange),
                        ),
                        title: const Text('Email', style: TextStyle(fontSize: 13, color: Colors.grey)),
                        subtitle: Text(user.email, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Text('Preferences', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                  ),
                  child: SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    secondary: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.purple.withOpacity(0.15), shape: BoxShape.circle),
                      child: const Icon(Icons.dark_mode_rounded, color: Colors.purple),
                    ),
                    title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w600)),
                    value: isDark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    onChanged: (value) async {
                      ref.read(themeProvider.notifier).toggleTheme(value);
                      try {
                        await ref.read(profileRepositoryProvider).updateUserTheme(user.id, value ? 'dark' : 'light');
                      } catch (e) {
                        // Silently fail backend sync
                      }
                    },
                  ),
                ),
                const SizedBox(height: 48),
                OutlinedButton.icon(
                  onPressed: () {
                    ref.read(authControllerProvider.notifier).logout();
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ),
    );
  }
}
