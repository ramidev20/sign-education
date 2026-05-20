import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:sign_education/data/db/db_helper_classes.dart';
import 'package:sign_education/data/models/user_model.dart';
import 'package:sign_education/utils/app_strings.dart';

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
    'رياضيات',
    'فيزياء',
    'كيمياء',
    'أحياء',
    'تاريخ',
    'جغرافيا',
    'علوم الحاسوب',
    'إنجليزية',
    'أخرى',
  ];

  Future<void> _pickColor() async {
    final strings = AppStrings.of(context);
    final pickedColor = await showColorPickerDialog(
      context,
      _avatarColor,
      title: Text(strings.text('اختر لونًا', 'Choose a color', 'Choisir une couleur')),
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

    setState(() => _avatarColor = pickedColor);
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate() || _selectedSubject == null) return;

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
    final strings = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.text('مجموعة جديدة', 'New group', 'Nouveau groupe')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: strings.text('اسم المجموعة', 'Group name', 'Nom du groupe'),
                ),
                validator: (v) => v == null || v.isEmpty
                    ? strings.text('أدخل اسم المجموعة', 'Enter the group name', 'Entrez le nom du groupe')
                    : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: levelCtrl,
                      decoration: InputDecoration(
                        labelText: strings.text('المستوى', 'Level', 'Niveau'),
                      ),
                      validator: (v) => v == null || v.isEmpty
                          ? strings.text('أدخل المستوى', 'Enter the level', 'Entrez le niveau')
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: branchCtrl,
                      decoration: InputDecoration(labelText: strings.branch),
                      validator: (v) => v == null || v.isEmpty
                          ? strings.text('أدخل الشعبة', 'Enter the branch', 'Entrez la filiere')
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedSubject,
                decoration: InputDecoration(
                  labelText: strings.text('المادة', 'Subject', 'Matiere'),
                ),
                items: _subjects
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedSubject = val),
                validator: (v) => v == null
                    ? strings.text('الرجاء اختيار مادة', 'Please choose a subject', 'Veuillez choisir une matiere')
                    : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    strings.text('لون الرمز:', 'Badge color:', 'Couleur du badge :'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: Icon(Icons.color_lens, color: _avatarColor, size: 30),
                    onPressed: _pickColor,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _createGroup,
                icon: const Icon(Icons.check),
                label: Text(
                  strings.text('إنشاء المجموعة', 'Create group', 'Creer le groupe'),
                ),
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
