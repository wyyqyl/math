import 'package:material_ui/material_ui.dart';
import 'package:math/managers/profile_manager.dart';
import 'package:math/models/settings_model.dart';

import 'widgets/study_layout.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _profiles = ProfileManager();
  late Set<int> _tables;
  late int _duration;
  late int _limit;
  late bool _advanced;
  late bool _sound;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final settings = _profiles.currentProfile!.settings;
    _tables = settings.selectedTables.toSet();
    _duration = settings.quizDuration;
    _limit = settings.additionSubtractionLimit;
    _advanced = settings.advancedMode;
    _sound = settings.soundEnabled;
  }

  Future<void> _save() {
    return _profiles.updateProfileSettings(
      _profiles.currentProfile!.name,
      AppSettings(
        selectedTables: _tables.toList()..sort(),
        quizDuration: _duration,
        additionSubtractionLimit: _limit,
        advancedMode: _advanced,
        soundEnabled: _sound,
      ),
    );
  }

  Future<void> _updateProfiles(Future<void> Function() change) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _save();
      await change();
      if (mounted) setState(_loadSettings);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save the change. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveAndClose() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _save();
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save settings. Please try again.'),
        ),
      );
    }
  }

  Future<void> _editProfile({String? oldName}) async {
    final form = GlobalKey<FormState>();
    var name = oldName ?? '';
    final editedName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(oldName == null ? 'Add profile' : 'Rename profile'),
        content: Form(
          key: form,
          child: TextFormField(
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            initialValue: oldName,
            decoration: const InputDecoration(labelText: 'Name'),
            onChanged: (value) => name = value.trim(),
            validator: (_) {
              if (name.isEmpty) return 'Enter a name';
              if (_profiles.profileNames.any(
                (other) =>
                    other != oldName &&
                    other.toLowerCase() == name.toLowerCase(),
              )) {
                return 'That name is already in use';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.of(context).pop(name);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (!mounted || editedName == null || editedName == oldName) return;
    await _updateProfiles(
      () => oldName == null
          ? _profiles.createProfile(editedName, makeActive: true)
          : _profiles.renameProfile(oldName, editedName),
    );
  }

  Future<void> _deleteProfile(String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $name?'),
        content: const Text(
          'This will delete this profile’s settings and math progress.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete profile'),
          ),
        ],
      ),
    );
    if (mounted && confirmed == true) {
      await _updateProfiles(() => _profiles.deleteProfile(name));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _saveAndClose();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profiles & settings'),
          actions: [
            TextButton(
              onPressed: _busy ? null : _saveAndClose,
              child: const Text('Save'),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: StudyPage(
          child: IgnorePointer(
            ignoring: _busy,
            child: StudyColumns(
              first: Column(
                children: [
                  _profileCard(context),
                  const SizedBox(height: 12),
                  _tableCard(context),
                ],
              ),
              second: _practiceSettings(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _profileCard(BuildContext context) {
    return StudyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Profiles', style: Theme.of(context).textTheme.titleLarge),
          for (final name in _profiles.profileNames)
            ListTile(
              minTileHeight: 56,
              contentPadding: EdgeInsets.zero,
              selected: name == _profiles.currentProfile!.name,
              leading: Icon(
                name == _profiles.currentProfile!.name
                    ? Icons.check_circle
                    : Icons.account_circle_outlined,
              ),
              title: Text(name),
              onTap: name == _profiles.currentProfile!.name
                  ? null
                  : () => _updateProfiles(() => _profiles.switchProfile(name)),
              trailing: PopupMenuButton<String>(
                tooltip: 'Manage $name',
                onSelected: (action) {
                  if (action == 'rename') {
                    _editProfile(oldName: name);
                  } else {
                    _deleteProfile(name);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'rename', child: Text('Rename')),
                  if (_profiles.profileNames.length > 1)
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _editProfile,
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Add profile'),
          ),
        ],
      ),
    );
  }

  Widget _tableCard(BuildContext context) {
    return StudyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mixed multiplication',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Text('Choose tables for mixed practice and quizzes.'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var table = 1; table <= AppSettings.maxTable; table++)
                Semantics(
                  selected: _tables.contains(table),
                  label: '$table times table',
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(52, 52),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      backgroundColor: _tables.contains(table)
                          ? studyTint
                          : Colors.white,
                    ),
                    onPressed: () => setState(() {
                      if (!_tables.contains(table)) {
                        _tables.add(table);
                      } else if (_tables.length > 1) {
                        _tables.remove(table);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Keep at least one table selected.'),
                          ),
                        );
                      }
                    }),
                    child: Text('$table'),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              TextButton(
                onPressed: () => setState(() {
                  _tables = {for (var i = 1; i <= AppSettings.maxTable; i++) i};
                }),
                child: const Text('Select all'),
              ),
              TextButton(
                onPressed: () =>
                    setState(() => _tables = AppSettings.defaultTables.toSet()),
                child: const Text('Reset to 2–9'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _practiceSettings(BuildContext context) {
    return StudyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Practice & quizzes',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Text('Addition and subtraction number limit · $_limit'),
          Slider(
            value: _limit.toDouble(),
            min: 10,
            max: 100,
            divisions: 9,
            label: '$_limit',
            semanticFormatterCallback: (value) => '${value.round()} maximum',
            onChanged: (value) => setState(() => _limit = value.round()),
          ),
          Text('Timed quiz length · $_duration seconds'),
          Slider(
            value: _duration.toDouble(),
            min: 15,
            max: 120,
            divisions: 7,
            label: '$_duration seconds',
            semanticFormatterCallback: (value) => '${value.round()} seconds',
            onChanged: (value) => setState(() => _duration = value.round()),
          ),
          const Divider(),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Type answers'),
            subtitle: const Text('Use a number pad for practice and quizzes.'),
            value: _advanced,
            onChanged: (value) => setState(() => _advanced = value),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Game sounds'),
            value: _sound,
            onChanged: (value) => setState(() => _sound = value),
          ),
        ],
      ),
    );
  }
}
