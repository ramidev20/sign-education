import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sign_education/data/db/db_helper_users.dart';
import 'package:sign_education/utils/theme_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _role = "student";
  String? _level;
  String? _branch;
  final List<String> _selectedSubjects = [];
  bool _isLoading = false;

  final supabase = Supabase.instance.client;

  final List<String> levels = ["1 ثانوي", "2 ثانوي", "3 ثانوي"];
  final Map<String, List<String>> branchesByLevel = {
    "1 ثانوي": ["فنون", "آداب", "جذع مشترك علوم تجريبية"],
    "2 ثانوي": [
      "فنون",
      "لغات أجنبية",
      "آداب وفلسفة",
      "تقني رياضي",
      "رياضيات",
      "اقتصاد",
    ],
    "3 ثانوي": [
      "فنون",
      "لغات أجنبية",
      "آداب وفلسفة",
      "تقني رياضي",
      "رياضيات",
      "اقتصاد",
    ],
  };

  final List<String> teacherSubjects = [
    "رياضيات",
    "فيزياء",
    "كيمياء",
    "أحياء",
    "تاريخ",
    "جغرافيا",
    "لغات",
    "الكل",
  ];

  Future<void> _signupWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final res = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (res.user == null) throw Exception("فشل إنشاء الحساب");

      await DbHelperUsers.createUser(
        supabaseUser: res.user!,
        name: _nameController.text.trim(),
        role: _role,
        level: _role == "student" ? _level : null,
        branch: _role == "student" ? _branch : null,
        subjects: _role == "teacher"
            ? (_selectedSubjects.contains("الكل") ? ["all"] : _selectedSubjects)
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("تم إنشاء الحساب بنجاح 🎉")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("خطأ: $e")));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = context.watch<ThemeController>().isDarkMode;

    return Scaffold(
      appBar: AppBar(title: const Text("إنشاء حساب"), elevation: 0),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        color: theme.colorScheme.surface,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  if (!isDark)
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "إنشاء حساب ✨",
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "سجّل باستخدام البريد الإلكتروني وكلمة المرور",
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // الاسم الكامل
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: "الاسم الكامل",
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? "أدخل اسمك" : null,
                      ),
                      const SizedBox(height: 15),

                      // البريد الإلكتروني
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: "البريد الإلكتروني",
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (v) => v == null || !v.contains("@")
                            ? "أدخل بريدًا إلكترونيًا صالحًا"
                            : null,
                      ),
                      const SizedBox(height: 15),

                      // كلمة المرور
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "كلمة المرور",
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        validator: (v) => v == null || v.length < 6
                            ? "الحد الأدنى 6 أحرف"
                            : null,
                      ),
                      const SizedBox(height: 20),

                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: "teacher",
                            label: Text("معلّم"),
                            icon: Icon(Icons.school_outlined),
                          ),
                          ButtonSegment(
                            value: "student",
                            label: Text("طالب"),
                            icon: Icon(Icons.person_outline),
                          ),
                        ],
                        selected: {_role},
                        onSelectionChanged: (val) {
                          setState(() {
                            _role = val.first;
                            _level = null;
                            _branch = null;
                            _selectedSubjects.clear();
                          });
                        },
                      ),
                      const SizedBox(height: 20),

                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        switchInCurve: Curves.easeInOut,
                        switchOutCurve: Curves.easeInOut,
                        child: _role == "student"
                            ? Column(
                                key: const ValueKey("student"),
                                children: [
                                  DropdownButtonFormField<String>(
                                    initialValue: _level,
                                    decoration: const InputDecoration(
                                      labelText: "المستوى",
                                    ),
                                    items: levels
                                        .map(
                                          (l) => DropdownMenuItem(
                                            value: l,
                                            child: Text(l),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (v) =>
                                        setState(() => _level = v),
                                    validator: (v) =>
                                        v == null ? "اختر المستوى" : null,
                                  ),
                                  const SizedBox(height: 15),
                                  DropdownButtonFormField<String>(
                                    initialValue: _branch,
                                    decoration: const InputDecoration(
                                      labelText: "الشعبة",
                                    ),
                                    items:
                                        (_level != null
                                                ? branchesByLevel[_level]!
                                                : <String>[])
                                            .map(
                                              (b) => DropdownMenuItem(
                                                value: b,
                                                child: Text(b),
                                              ),
                                            )
                                            .toList(),
                                    onChanged: _level == null
                                        ? null
                                        : (v) => setState(() => _branch = v),
                                    validator: (v) =>
                                        _role == "student" &&
                                            _level != null &&
                                            v == null
                                        ? "اختر الشعبة"
                                        : null,
                                  ),
                                ],
                              )
                            : Column(
                                key: const ValueKey("teacher"),
                                children: [
                                  const Text("اختر المواد"),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    children: teacherSubjects.map((subject) {
                                      final selected = _selectedSubjects
                                          .contains(subject);
                                      return FilterChip(
                                        label: Text(subject),
                                        selected: selected,
                                        onSelected: (val) {
                                          setState(() {
                                            if (val) {
                                              _selectedSubjects.add(subject);
                                            } else {
                                              _selectedSubjects.remove(subject);
                                            }
                                          });
                                        },
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 24),

                      FilledButton(
                        onPressed: _isLoading ? null : _signupWithEmail,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: _isLoading
                              ? const SizedBox(
                                  key: ValueKey("loading"),
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text("إنشاء حساب", key: ValueKey("text")),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
