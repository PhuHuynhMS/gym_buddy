import 'package:flutter/material.dart';
import 'package:gym_buddy_app/features/auth/domain/entities/auth_session_ui_model.dart';
import 'package:gym_buddy_app/features/auth/domain/entities/auth_ui_model.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/list_sessions_use_case.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/logout_all_use_case.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/logout_use_case.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/revoke_session_use_case.dart';
import 'package:gym_buddy_app/features/location/presentation/location_permission_panel.dart';
import 'package:gym_buddy_app/features/maps/data/buddy_repository.dart';
import 'package:gym_buddy_app/features/maps/data/gym_repository.dart';
import 'package:gym_buddy_app/features/maps/presentation/map_preview_panel.dart';
import 'package:gym_buddy_app/features/maps/presentation/map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.auth,
    required this.logoutUseCase,
    required this.logoutAllUseCase,
    required this.listSessionsUseCase,
    required this.revokeSessionUseCase,
    required this.gymRepository,
    required this.buddyRepository,
    required this.onSignedOut,
    super.key,
  });

  final AuthUiModel auth;
  final LogoutUseCase logoutUseCase;
  final LogoutAllUseCase logoutAllUseCase;
  final ListSessionsUseCase listSessionsUseCase;
  final RevokeSessionUseCase revokeSessionUseCase;
  final GymRepository gymRepository;
  final BuddyRepository buddyRepository;
  final VoidCallback onSignedOut;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _mapRefreshKey = 0;
  int _selectedTab = 0;

  void _reloadMapPreview() {
    setState(() {
      _mapRefreshKey += 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GymBuddy'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SettingsScreen(
                    logoutUseCase: widget.logoutUseCase,
                    logoutAllUseCase: widget.logoutAllUseCase,
                    listSessionsUseCase: widget.listSessionsUseCase,
                    revokeSessionUseCase: widget.revokeSessionUseCase,
                    onSignedOut: widget.onSignedOut,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: _selectedTab == 0 ? _buildHomeTab() : _buildMapTab(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (i) => setState(() => _selectedTab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Welcome, ${widget.auth.displayName}',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          widget.auth.email,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        Text(widget.auth.message),
        const SizedBox(height: 24),
        LocationPermissionPanel(onPermissionChanged: _reloadMapPreview),
        const SizedBox(height: 16),
        MapPreviewPanel(key: ValueKey(_mapRefreshKey)),
      ],
    );
  }

  Widget _buildMapTab() {
    return MapScreen(
      gymRepository: widget.gymRepository,
      buddyRepository: widget.buddyRepository,
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    required this.logoutUseCase,
    required this.logoutAllUseCase,
    required this.listSessionsUseCase,
    required this.revokeSessionUseCase,
    required this.onSignedOut,
    super.key,
  });

  final LogoutUseCase logoutUseCase;
  final LogoutAllUseCase logoutAllUseCase;
  final ListSessionsUseCase listSessionsUseCase;
  final RevokeSessionUseCase revokeSessionUseCase;
  final VoidCallback onSignedOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.devices_outlined),
            title: const Text('Sessions'),
            subtitle: const Text('Manage devices signed in to GymBuddy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SessionsScreen(
                    logoutAllUseCase: logoutAllUseCase,
                    listSessionsUseCase: listSessionsUseCase,
                    revokeSessionUseCase: revokeSessionUseCase,
                    onSignedOut: onSignedOut,
                  ),
                ),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              await logoutUseCase();
              if (context.mounted) {
                onSignedOut();
              }
            },
          ),
        ],
      ),
    );
  }
}

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({
    required this.logoutAllUseCase,
    required this.listSessionsUseCase,
    required this.revokeSessionUseCase,
    required this.onSignedOut,
    super.key,
  });

  final LogoutAllUseCase logoutAllUseCase;
  final ListSessionsUseCase listSessionsUseCase;
  final RevokeSessionUseCase revokeSessionUseCase;
  final VoidCallback onSignedOut;

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  late Future<List<AuthSessionUiModel>> _sessions;

  @override
  void initState() {
    super.initState();
    _sessions = widget.listSessionsUseCase();
  }

  void _reload() {
    setState(() {
      _sessions = widget.listSessionsUseCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sessions')),
      body: FutureBuilder<List<AuthSessionUiModel>>(
        future: _sessions,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: FilledButton.icon(
                onPressed: _reload,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            );
          }

          final sessions = snapshot.data ?? const [];
          return ListView.separated(
            itemCount: sessions.length + 1,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              if (index == sessions.length) {
                return ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Logout all devices'),
                  onTap: () async {
                    final confirmed = await _confirm(
                      context,
                      'Logout all devices?',
                      'This will sign you out on this device too.',
                    );
                    if (!confirmed) {
                      return;
                    }
                    await widget.logoutAllUseCase();
                    if (context.mounted) {
                      widget.onSignedOut();
                    }
                  },
                );
              }

              final session = sessions[index];
              return ListTile(
                leading: Icon(
                  session.isCurrentDevice
                      ? Icons.phone_android
                      : Icons.devices_other,
                ),
                title: Text(session.deviceName),
                subtitle: Text(
                  session.isCurrentDevice
                      ? '${session.platform} - This device'
                      : session.platform,
                ),
                trailing: IconButton(
                  tooltip: 'Revoke session',
                  icon: const Icon(Icons.close),
                  onPressed: () async {
                    final confirmed = await _confirm(
                      context,
                      session.isCurrentDevice
                          ? 'Revoke this device?'
                          : 'Revoke session?',
                      session.isCurrentDevice
                          ? 'This will sign you out on this device.'
                          : 'This device will need to log in again.',
                    );
                    if (!confirmed) {
                      return;
                    }

                    await widget.revokeSessionUseCase(session.id);
                    if (session.isCurrentDevice && context.mounted) {
                      widget.onSignedOut();
                    } else {
                      _reload();
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<bool> _confirm(
    BuildContext context,
    String title,
    String content,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
