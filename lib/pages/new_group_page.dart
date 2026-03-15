import 'package:flutter/material.dart';
import 'package:sign_education/data/db/db_helper_classes.dart';
import 'package:sign_education/data/models/user_model.dart';
import 'package:flex_color_picker/flex_color_picker.dart';

class NewGroupPage extends StatefulWidget {
  final UserModel teacher;

  const NewGroupPage({super.key, required this.teacher});

  @override
  State<NewGroupPage> createState() => _NewGroupPageState();
}

class _NewGroupPageState extends State<NewGroupPage> {
  final _formKey = GlobalKey<FormState>();

  final nameCtrl = TextEditingController();
  final levelCtrl = TextEditingController();
  final branchCtrl = TextEditingController();

  String? _selectedSubject;
  Color _avatarColor = Colors.blueGrey;

  final List<String> _subjects = [
    "رياضيات",
    "فيزياء",
    "كيمياء",
    "أحياء",
    "تاريخ",
    "جغرافيا",
    "علوم الحاسوب",
    "إنجليزية",
    "أخرى",
  ];

  /// Show the FlexColorPicker dialog
  Future<void> _pickColor() async {
    final Color? pickedColor = await showColorPickerDialog(
      context,
      _avatarColor,
      title: const Text("اختر لونًا"),
      width: 60,
      height: 60,
      spacing: 5,
      runSpacing: 5,
      borderRadius: 10,
      pickersEnabled: <ColorPickerType, bool>{
        ColorPickerType.custom: true,
        ColorPickerType.accent: false,
        ColorPickerType.both: false,
      },
    );

    if (pickedColor != null) {
      setState(() => _avatarColor = pickedColor);
    }
  }

  /// Create group and save to Supabase
  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate() || _selectedSubject == null) return;

    final classGroupId =
        "${levelCtrl.text}_${branchCtrl.text}_${_selectedSubject}";

    final hexColor =
        '#${_avatarColor.value.toRadixString(16).substring(2).toUpperCase()}';

    await DbHelperClasses.createClassGroup(
      level: levelCtrl.text.trim(),
      branch: branchCtrl.text.trim(),
      subject: _selectedSubject!,
      teacherId: widget.teacher.id,
      name: nameCtrl.text.trim(),
      avatarColor: hexColor,
    );

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("مجموعة جديدة")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              /// Group Name
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: "اسم المجموعة",
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? "أدخل اسم المجموعة" : null,
              ),
              const SizedBox(height: 12),

              /// Level + Branch in one row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: levelCtrl,
                      decoration: const InputDecoration(
                        labelText: "المستوى",
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? "أدخل المستوى" : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: branchCtrl,
                      decoration: const InputDecoration(
                        labelText: "الشعبة",
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? "أدخل الشعبة" : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              /// Subject dropdown
              DropdownButtonFormField<String>(
                value: _selectedSubject,
                decoration: const InputDecoration(
                  labelText: "المادة",
                  border: OutlineInputBorder(),
                ),
                items: _subjects
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedSubject = val),
                validator: (v) => v == null ? "الرجاء اختيار مادة" : null,
              ),
              const SizedBox(height: 12),

              /// Color picker row
              Row(
                children: [
                  const Text(
                    "لون الرمز:",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: Icon(Icons.color_lens, color: _avatarColor, size: 30),
                    onPressed: _pickColor,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              /// Create group button
              ElevatedButton.icon(
                onPressed: _createGroup,
                icon: const Icon(Icons.check),
                label: const Text("إنشاء المجموعة"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
