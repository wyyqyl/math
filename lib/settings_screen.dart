import 'package:flutter/material.dart';
import 'package:math/profile_manager.dart';
import 'settings_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ProfileManager _profileManager = ProfileManager();
  late List<int> _selectedTables;
  late int _quizDuration;
  late int _additionSubtractionLimit;
  late String _currentProfileName;

  @override
  void initState() {
    super.initState();
    _loadSettingsFromProfile();
    _profileManager.addListener(_onProfileChanged);
  }

  void _toggleTable(int tableNumber) {
    setState(() {
      if (_selectedTables.contains(tableNumber)) {
        _selectedTables.remove(tableNumber);
      } else {
        _selectedTables.add(tableNumber);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedTables = [2, 3, 4, 5, 6, 7, 8, 9];
    });
  }

  void _clearAll() {
    setState(() {
      _selectedTables = [];
    });
  }

  void _loadSettingsFromProfile() {
    final profile = _profileManager.currentProfile;
    if (profile != null) {
      setState(() {
        _selectedTables = List.from(profile.settings.selectedTables);
        _quizDuration = profile.settings.quizDuration;
        _additionSubtractionLimit = profile.settings.additionSubtractionLimit;
        _currentProfileName = profile.name;
      });
    }
  }

  void _onProfileChanged() {
    _loadSettingsFromProfile();
  }

  @override
  void dispose() {
    _profileManager.removeListener(_onProfileChanged);
    super.dispose();
  }

  Future<bool> _saveCurrentSettings() async {
    if (_selectedTables.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one table before saving.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return false;
    }
    final newSettings = AppSettings(
      selectedTables: _selectedTables,
      quizDuration: _quizDuration,
      additionSubtractionLimit: _additionSubtractionLimit,
    );
    await _profileManager.updateProfileSettings(
      _currentProfileName,
      newSettings,
    );
    return true;
  }

  Future<void> _showProfileDialog({String? existingName}) async {
    final nameController = TextEditingController(text: existingName);
    final formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(existingName == null ? 'Add Profile' : 'Rename Profile'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: nameController,
              decoration: const InputDecoration(hintText: "Profile Name"),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Name cannot be empty';
                }
                if (_profileManager.profileNames.any(
                  (p) =>
                      p.toLowerCase() == value.trim().toLowerCase() &&
                      p.toLowerCase() != existingName?.toLowerCase(),
                )) {
                  return 'Name already exists';
                }
                return null;
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text(existingName == null ? 'Add' : 'Rename'),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final newName = nameController.text.trim();
                  try {
                    if (existingName != null) {
                      await _profileManager.renameProfile(
                        existingName,
                        newName,
                      );
                    } else {
                      await _profileManager.createProfile(
                        newName,
                        makeActive: true,
                      );
                    }
                    if (context.mounted) Navigator.of(context).pop();
                  } catch (e) {
                    // Error is already handled by validator, but as a fallback
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        final bool canPop = await _saveCurrentSettings();
        if (canPop && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          backgroundColor: Colors.orangeAccent,
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orangeAccent, Colors.yellow],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SingleChildScrollView(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 600) {
                  return _buildWideLayout();
                } else {
                  return _buildNarrowLayout();
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNarrowLayout() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildProfileCard(),
          const SizedBox(height: 20),
          _buildTablesCard(),
          const SizedBox(height: 20),
          _buildAdditionSubtractionCard(),
          const SizedBox(height: 20),
          _buildQuizSettingsCard(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildWideLayout() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: Column(
              children: [
                _buildProfileCard(),
                const SizedBox(height: 20),
                _buildTablesCard(),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                _buildQuizSettingsCard(),
                const SizedBox(height: 20),
                _buildAdditionSubtractionCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Profiles',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  color: Colors.orange.shade800,
                  onPressed: () => _showProfileDialog(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._profileManager.profileNames.map(
              (name) => ListTile(
                title: Text(
                  name,
                  style: TextStyle(
                    fontWeight: name == _currentProfileName
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                leading: Icon(
                  name == _currentProfileName
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: Colors.orange.shade800,
                ),
                onTap: () async {
                  if (name != _currentProfileName) {
                    if (await _saveCurrentSettings()) {
                      _profileManager.switchProfile(name);
                    }
                  }
                },
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showProfileDialog(existingName: name),
                    ),
                    if (_profileManager.profileNames.length > 1)
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          await _profileManager.deleteProfile(name);
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTablesCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Multiplication Tables',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade800,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 120,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 1.0,
              ),
              itemCount: 8,
              itemBuilder: (context, index) {
                final tableNumber = index + 2;
                final isSelected = _selectedTables.contains(tableNumber);
                return InkWell(
                  onTap: () => _toggleTable(tableNumber),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(15.0),
                      border: isSelected
                          ? Border.all(color: Colors.orange.shade800, width: 4)
                          : Border.all(color: Colors.grey.shade300),
                    ),
                    child: Center(
                      child: Text(
                        '$tableNumber',
                        style: TextStyle(
                          fontSize: 40.0,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.orange.shade800
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: _selectAll,
                  icon: const Icon(Icons.done_all),
                  label: const Text('Select All'),
                ),
                TextButton.icon(
                  onPressed: _clearAll,
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear All'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionSubtractionCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Addition & Subtraction Settings',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Number Limit', style: TextStyle(fontSize: 18)),
                Text(
                  '<= $_additionSubtractionLimit',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Slider(
              value: _additionSubtractionLimit.toDouble(),
              min: 10,
              max: 100,
              divisions: 9,
              label: _additionSubtractionLimit.round().toString(),
              activeColor: Colors.orange,
              inactiveColor: Colors.orange.shade100,
              onChanged: (double value) {
                setState(() {
                  _additionSubtractionLimit = value.round();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizSettingsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quiz Settings',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Duration', style: TextStyle(fontSize: 18)),
                Text(
                  '${_quizDuration.round()} seconds',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Slider(
              value: _quizDuration.toDouble(),
              min: 15,
              max: 120,
              divisions: 7,
              label: _quizDuration.round().toString(),
              activeColor: Colors.orange,
              inactiveColor: Colors.orange.shade100,
              onChanged: (double value) {
                setState(() {
                  _quizDuration = value.round();
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
