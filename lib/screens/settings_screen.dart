import 'package:flutter/material.dart';
import 'package:math/managers/profile_manager.dart';
import 'package:math/models/settings_model.dart';

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
  late bool _advancedMode;

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
        _advancedMode = profile.settings.advancedMode;
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
          SnackBar(
            content: const Text(
              'Please select at least one table before saving.',
            ),
            backgroundColor: const Color(0xFFFF6B6B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
      return false;
    }
    final newSettings = AppSettings(
      selectedTables: _selectedTables,
      quizDuration: _quizDuration,
      additionSubtractionLimit: _additionSubtractionLimit,
      advancedMode: _advancedMode,
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(existingName == null ? 'Add Profile' : 'Rename Profile'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: "Profile Name",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(
                    color: Color(0xFF667eea),
                    width: 2,
                  ),
                ),
              ),
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
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667eea),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
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
                    // Error is already handled by validator
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
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          elevation: 0,
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
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
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              const Color(0xFF667eea).withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.person_rounded,
                        color: Color(0xFF667eea),
                        size: 28,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Profiles',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF667eea),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_rounded),
                    color: const Color(0xFF667eea),
                    iconSize: 32,
                    onPressed: () => _showProfileDialog(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ..._profileManager.profileNames.map(
                (name) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    title: Text(
                      name,
                      style: TextStyle(
                        fontWeight: name == _currentProfileName
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 18,
                      ),
                    ),
                    leading: Icon(
                      name == _currentProfileName
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: const Color(0xFF667eea),
                      size: 28,
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
                          icon: const Icon(Icons.edit_rounded),
                          color: const Color(0xFF667eea),
                          onPressed: () =>
                              _showProfileDialog(existingName: name),
                        ),
                        if (_profileManager.profileNames.length > 1)
                          IconButton(
                            icon: const Icon(Icons.delete_rounded),
                            color: const Color(0xFFFF6B6B),
                            onPressed: () async {
                              await _profileManager.deleteProfile(name);
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTablesCard() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              const Color(0xFF4ECDC4).withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.calculate_rounded,
                    color: Color(0xFF4ECDC4),
                    size: 28,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Multiplication Tables',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4ECDC4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10.0,
                runSpacing: 10.0,
                children: List<Widget>.generate(8, (index) {
                  final tableNumber = index + 2;
                  final isSelected = _selectedTables.contains(tableNumber);
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: ChoiceChip(
                      label: Text(
                        '$tableNumber',
                        style: TextStyle(
                          fontSize: 22.0,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF4ECDC4),
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (bool selected) {
                        _toggleTable(tableNumber);
                      },
                      backgroundColor: Colors.white,
                      selectedColor: const Color(0xFF4ECDC4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      elevation: isSelected ? 4 : 2,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _selectAll,
                    icon: const Icon(Icons.done_all_rounded),
                    label: const Text('Select All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4ECDC4),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _clearAll,
                    icon: const Icon(Icons.clear_all_rounded),
                    label: const Text('Clear All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B6B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdditionSubtractionCard() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              const Color(0xFFFFE66D).withValues(alpha: 0.2),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.exposure_rounded,
                    color: Color(0xFFFFE66D),
                    size: 28,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Addition & Subtraction',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFE66D),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Number Limit',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE66D),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      '≤ $_additionSubtractionLimit',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: const Color(0xFFFFE66D),
                  inactiveTrackColor: const Color(
                    0xFFFFE66D,
                  ).withValues(alpha: 0.3),
                  thumbColor: const Color(0xFFFFE66D),
                  overlayColor: const Color(0xFFFFE66D).withValues(alpha: 0.2),
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 12,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 24,
                  ),
                ),
                child: Slider(
                  value: _additionSubtractionLimit.toDouble(),
                  min: 10,
                  max: 100,
                  divisions: 9,
                  label: _additionSubtractionLimit.round().toString(),
                  onChanged: (double value) {
                    setState(() {
                      _additionSubtractionLimit = value.round();
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuizSettingsCard() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              const Color(0xFFFF6B6B).withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.quiz_rounded, color: Color(0xFFFF6B6B), size: 28),
                  SizedBox(width: 8),
                  Text(
                    'Quiz Settings',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF6B6B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Duration',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B6B),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      '${_quizDuration.round()} sec',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: const Color(0xFFFF6B6B),
                  inactiveTrackColor: const Color(
                    0xFFFF6B6B,
                  ).withValues(alpha: 0.3),
                  thumbColor: const Color(0xFFFF6B6B),
                  overlayColor: const Color(0xFFFF6B6B).withValues(alpha: 0.2),
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 12,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 24,
                  ),
                ),
                child: Slider(
                  value: _quizDuration.toDouble(),
                  min: 15,
                  max: 120,
                  divisions: 7,
                  label: _quizDuration.round().toString(),
                  onChanged: (double value) {
                    setState(() {
                      _quizDuration = value.round();
                    });
                  },
                ),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Advanced Mode',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Use numeric keypad',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                  Switch(
                    value: _advancedMode,
                    onChanged: (value) => setState(() => _advancedMode = value),
                    activeTrackColor: const Color(0xFFFF6B6B),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
