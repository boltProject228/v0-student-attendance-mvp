import 'package:attendance_system/providers/auth_provider.dart';
import 'package:attendance_system/widgets/admin/admin_home_appbar.dart';
import 'package:attendance_system/widgets/admin/admin_home_drawer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/group.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    await Future.wait([
      adminProvider.fetchUsers(),
      adminProvider.fetchGroups(),
      adminProvider.fetchStudents(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: buildAdminHomeAppBar(
        context,
        authProvider,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Пользователи'),
            Tab(text: 'Группы'),
            Tab(text: 'Студенты'),
          ],
          labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      drawer: const AdminHomeDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: const [
          UsersTab(),
          GroupsTab(),
          StudentsTab(),
        ],
      ),
    );
  }
}

// -------------------- USERS TAB ------------------------
class UsersTab extends StatelessWidget {
  const UsersTab({super.key});

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Text(
                'Пользователи',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _showAddUserDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Добавить'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
              ),
            ],
          ),
        ),
        if (adminProvider.error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              adminProvider.error!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        Expanded(
          child: adminProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : adminProvider.users.isEmpty
                  ? const Center(child: Text('Нет пользователей'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: adminProvider.users.length,
                      itemBuilder: (context, index) {
                        final user = adminProvider.users[index];
                        String roleDisplay;
                        switch (user.role) {
                          case 'admin':
                            roleDisplay = 'Админ';
                            break;
                          case 'head':
                            roleDisplay = 'Заведующий';
                            break;
                          default:
                            roleDisplay = 'Преподаватель';
                        }
                        return UserTile(
                          id: user.id,
  title: user.fullName ?? user.login,
  subtitle: '$roleDisplay (${user.login})',
  icon: Icons.person,
  fullName: user.fullName ?? '—',
  login: user.login,
  role: roleDisplay,
  onDelete: () async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить пользователя?'),
        content: Text('Вы уверены, что хотите удалить пользователя "${user.fullName ?? user.login}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final success = await Provider.of<AdminProvider>(context, listen: false).deleteUser(user.id);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Пользователь удалён успешно')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка удаления')),
        );
      }
    }
  }, 
);


                      },
                    ),
        ),
      ],
    );
  }

  void _showAddUserDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final loginController = TextEditingController();
    final passwordController = TextEditingController();
    final fullNameController = TextEditingController();
    String role = 'teacher';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Добавить пользователя'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: fullNameController,
                    decoration: const InputDecoration(labelText: 'ФИО'),
                    validator: (value) =>
                        value == null || value.trim().isEmpty ? 'Введите ФИО' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: loginController,
                    decoration: const InputDecoration(labelText: 'Логин'),
                    validator: (value) =>
                        value == null || value.trim().isEmpty ? 'Введите логин' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    decoration: const InputDecoration(labelText: 'Пароль'),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Введите пароль';
                      if (value.length < 6) return 'Пароль должен быть не менее 6 символов';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: role,
                    decoration: const InputDecoration(labelText: 'Роль'),
                    items: const [
                      DropdownMenuItem(value: 'teacher', child: Text('Преподаватель')),
                      DropdownMenuItem(value: 'head', child: Text('Заведующий')),
                      DropdownMenuItem(value: 'admin', child: Text('Админ')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        role = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final adminProvider = Provider.of<AdminProvider>(context, listen: false);
                  final success = await adminProvider.createUser({
                    'fullName': fullNameController.text.trim(),
                    'login': loginController.text.trim(),
                    'password': passwordController.text.trim(),
                    'role': role,
                  });
                  if (context.mounted) Navigator.pop(context);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Пользователь добавлен успешно')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(adminProvider.error ?? 'Ошибка добавления')),
                    );
                  }
                }
              },
              child: const Text('Добавить'),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------- GROUPS TAB ------------------------
class GroupsTab extends StatefulWidget {
  const GroupsTab({super.key});

  @override
  State<GroupsTab> createState() => _GroupsTabState();
}

class _GroupsTabState extends State<GroupsTab> {
  final Set<String> _deletingIds = {};

  static const List<String> _specialties = [
    'ПО',
    'СИБ',
    'М(Ру)',
    'ТЭ(Ру)',
    'БҚЕ',
    'АҚЖ',
    'М(Қаз)',
    'ТЭ(Қаз)',
  ];
  static const List<int> _courses = [1, 2, 3, 4];

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Text(
                'Группы',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _showAddGroupDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Добавить'),
                style: FilledButton.styleFrom(backgroundColor: Colors.blue),
              ),
            ],
          ),
        ),
        if (adminProvider.error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(adminProvider.error!, style: const TextStyle(color: Colors.red)),
          ),
        Expanded(
          child: adminProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : adminProvider.groups.isEmpty
                  ? const Center(child: Text('Нет групп'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: adminProvider.groups.length,
                      itemBuilder: (context, index) {
                        final group = adminProvider.groups[index];
                        final isDeleting = _deletingIds.contains(group.id);
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: const Icon(Icons.groups, color: Colors.blue),
                            title: Text(group.name),
                            subtitle:
                                Text('${group.specialty}, Курс ${group.course}'),
                            trailing: isDeleting
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () async {
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Удалить группу?'),
                                          content: Text(
                                              'Вы уверены, что хотите удалить группу "${group.name}"? Все связанные студенты останутся без группы.'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('Отмена'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: const Text('Удалить',
                                                  style: TextStyle(color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirmed == true) {
                                        setState(() => _deletingIds.add(group.id));
                                        final success = await adminProvider.deleteGroup(group.id);
                                        setState(() => _deletingIds.remove(group.id));
                                        if (success) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Группа удалена успешно')),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(adminProvider.error ?? 'Ошибка удаления')),
                                          );
                                        }
                                      }
                                    },
                                  ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  void _showAddGroupDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    String specialty = _specialties.first;
    int course = _courses.first;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Добавить группу'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration:
                        const InputDecoration(labelText: 'Название (например, ПО-115)'),
                        
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Введите название группы';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: specialty,
                    decoration: const InputDecoration(labelText: 'Специальность'),
                    items: _specialties
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        specialty = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: course,
                    decoration: const InputDecoration(labelText: 'Курс'),
                    items: _courses
                        .map((c) => DropdownMenuItem(value: c, child: Text('$c')))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        course = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final adminProvider = Provider.of<AdminProvider>(context, listen: false);
                  final success = await adminProvider.createGroup({
                    'name': nameController.text.trim(),
                    'specialty': specialty,
                    'course': course,
                  });
                  if (context.mounted) Navigator.pop(context);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Группа добавлена успешно')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(adminProvider.error ?? 'Ошибка добавления')),
                    );
                  }
                }
              },
              child: const Text('Добавить'),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------- STUDENTS TAB ------------------------
class StudentsTab extends StatefulWidget {
  const StudentsTab({super.key});

  @override
  State<StudentsTab> createState() => _StudentsTabState();
}

class _StudentsTabState extends State<StudentsTab> {
  final Set<String> _deletingIds = {};

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Text(
                'Студенты',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: adminProvider.groups.isEmpty
                    ? null
                    : () => _showAddStudentDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Добавить'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.blue,
                  disabledBackgroundColor: Colors.grey.shade400,
                  disabledForegroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        if (adminProvider.error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(adminProvider.error!, style: const TextStyle(color: Colors.red)),
          ),
        if (adminProvider.groups.isEmpty && !adminProvider.isLoading)
          const Center(child: Text('Сначала добавьте группы')),
        Expanded(
          child: adminProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : adminProvider.students.isEmpty
                  ? const Center(child: Text('Нет студентов'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: adminProvider.students.length,
                      itemBuilder: (context, index) {
                        final student = adminProvider.students[index];
                        final isDeleting = _deletingIds.contains(student.id);
                        final group = adminProvider.groups.firstWhere(
                          (g) => g.id == student.groupId,
                          orElse: () => Group(
                              id: '',
                              name: 'Неизвестно',
                              specialty: '',
                              course: 0,
                              createdAt: DateTime.now()),
                        );
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: const Icon(Icons.person_outline, color: Colors.blue),
                            title: Text(student.fullName),
                            subtitle: Text('Группа: ${group.name}'),
                            trailing: isDeleting
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () async {
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Удалить студента?'),
                                          content: Text(
                                              'Вы уверены, что хотите удалить студента "${student.fullName}"? Все связанные посещения будут удалены.'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('Отмена'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: const Text('Удалить',
                                                  style: TextStyle(color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirmed == true) {
                                        setState(() => _deletingIds.add(student.id));
                                        final success =
                                            await adminProvider.deleteStudent(student.id);
                                        setState(() => _deletingIds.remove(student.id));
                                        if (success) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                                content: Text('Студент удалён успешно')),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                                content: Text(adminProvider.error ??
                                                    'Ошибка удаления')),
                                          );
                                        }
                                      }
                                    },
                                  ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  void _showAddStudentDialog(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    String? groupId = adminProvider.groups.first.id;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Добавить студента'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'ФИО'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Введите ФИО';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: groupId,
                    decoration: const InputDecoration(labelText: 'Группа'),
                    items: adminProvider.groups
                        .map((g) => DropdownMenuItem(value: g.id, child: Text(g.name)))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        groupId = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Выберите группу';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final success = await adminProvider.createStudent({
                    'fullName': nameController.text.trim(),
                    'groupId': groupId,
                  });
                  if (context.mounted) Navigator.pop(context);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Студент добавлен успешно')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(adminProvider.error ?? 'Ошибка добавления')),
                    );
                  }
                }
              },
              child: const Text('Добавить'),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------- Reusable User Tile with Edit & Delete ----------------
class UserTile extends StatefulWidget {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final String fullName;
  final String login;
  final String role;
  final Future<void> Function() onDelete;

  const UserTile({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.fullName,
    required this.login,
    required this.role,
    required this.onDelete,
    super.key,
  });

  @override
  State<UserTile> createState() => _UserTileState();
}

class _UserTileState extends State<UserTile> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        leading: Icon(widget.icon, color: Colors.blue),
        title: Text(widget.title, style: const TextStyle(color: Colors.black)),
        subtitle: Text(widget.subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Редактировать',
              icon: const Icon(Icons.edit, color: Colors.amber),
              onPressed: () => _showEditDialog(context),
            ),
            _isDeleting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      setState(() => _isDeleting = true);
                      await widget.onDelete();
                      if (mounted) setState(() => _isDeleting = false);
                    },
                  ),
          ],
        ),
        children: [
          Container(
            width: double.infinity,
            color: Colors.grey.shade100,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('ФИО', widget.fullName),
                const SizedBox(height: 8),
                _buildInfoRow('Логин', widget.login),
                const SizedBox(height: 8),
                _buildInfoRow('Роль', widget.role),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.black87),
          ),
        ),
      ],
    );
  }

  void _showEditDialog(BuildContext context) {
  final formKey = GlobalKey<FormState>();
  final fullNameController = TextEditingController(text: widget.fullName);
  final loginController = TextEditingController(text: widget.login);
  final passwordController = TextEditingController();
  String role = widget.role.toLowerCase() == 'админ'
      ? 'admin'
      : widget.role.toLowerCase() == 'заведующий'
          ? 'head'
          : 'teacher';

  bool obscurePassword = true;

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Редактировать пользователя'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: fullNameController,
                  decoration: const InputDecoration(labelText: 'ФИО'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Введите ФИО' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: loginController,
                  decoration: const InputDecoration(labelText: 'Логин'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Введите логин' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(labelText: 'Роль'),
                  items: const [
                    DropdownMenuItem(value: 'teacher', child: Text('Преподаватель')),
                    DropdownMenuItem(value: 'head', child: Text('Заведующий')),
                    DropdownMenuItem(value: 'admin', child: Text('Админ')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      role = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Новый пароль (опционально)',
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => obscurePassword = !obscurePassword);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final Map<String, dynamic> updatedData = {
                  'fullName': fullNameController.text.trim(),
                  'login': loginController.text.trim(),
                  'role': role,
                };

                if (passwordController.text.trim().isNotEmpty) {
                  updatedData['password'] = passwordController.text.trim();
                }

                final adminProvider = Provider.of<AdminProvider>(context, listen: false);
                final success = await adminProvider.updateUser(widget.id, updatedData);

                if (context.mounted) Navigator.pop(context);

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Пользователь обновлён')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(adminProvider.error ?? 'Ошибка обновления')),
                  );
                }
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    ),
  );
  }
}
