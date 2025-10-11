import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/groups_provider.dart';
import '../widgets/app_drawer.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final groupsProvider = Provider.of<GroupsProvider>(context, listen: false);
    await groupsProvider.fetchGroups();
  }

  @override
  Widget build(BuildContext context) {
    final groupsProvider = Provider.of<GroupsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Группы'),
        elevation: 2,
      ),
      drawer: const AppDrawer(),
      body: groupsProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : groupsProvider.groups.isEmpty
              ? const Center(child: Text('Группы не найдены'))
              : Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.5,
                    ),
                    itemCount: groupsProvider.groups.length,
                    itemBuilder: (context, index) {
                      final group = groupsProvider.groups[index];
                      return Card(
                        child: InkWell(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(group.name),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Специальность: ${group.specialty}'),
                                    const SizedBox(height: 8),
                                    Text('Курс: ${group.course}'),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Закрыть'),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.groups,
                                  size: 48,
                                  color: Color(0xFF2563EB),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  group.name,
                                  style: Theme.of(context).textTheme.titleLarge,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  group.specialty,
                                  style: Theme.of(context).textTheme.bodySmall,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Курс ${group.course}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
