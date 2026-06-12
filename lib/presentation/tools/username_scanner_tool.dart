import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/utils/osint_utils_service.dart';

class UsernameScannerTool extends ConsumerStatefulWidget {
  const UsernameScannerTool({super.key});

  @override
  ConsumerState<UsernameScannerTool> createState() => _UsernameScannerToolState();
}

class _UsernameScannerToolState extends ConsumerState<UsernameScannerTool> {
  static const String TAG = "UsernameScannerTool";
  final TextEditingController _usernameController = TextEditingController();
  final OSINTUtilsService _osintUtils = OSINTUtilsService();
  Map<String, bool> _results = {};
  bool _isLoading = false;

  @override
  void initState() {
    developer.log('[initState] → Entry', name: TAG);
    super.initState();
  }

  @override
  void dispose() {
    developer.log('[dispose] → Entry', name: TAG);
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final user = _usernameController.text.trim();
    developer.log('[_scan] → Entry: username=$user', name: TAG);
    if (user.isEmpty) {
      developer.log('[_scan] → Exit: Username is empty', name: TAG);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _results = {};
    });

    try {
      final results = await _osintUtils.scanUsernames(user);
      developer.log('[_scan] → Status: Probe complete, processing ${results.length} nodes', name: TAG);

      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }
      developer.log('[_scan] → Exit: Results updated', name: TAG);
    } catch (e) {
      developer.log('[_scan] → Error: $e', name: TAG, error: e);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _launchUrl(String platform, String username) async {
    developer.log('[_launchUrl] → Entry: platform=$platform, target=$username', name: TAG);
    final platforms = {
      'Instagram': 'https://www.instagram.com/$username/',
      'X/Twitter': 'https://x.com/$username',
      'GitHub': 'https://github.com/$username',
      'LinkedIn': 'https://www.linkedin.com/in/$username/',
      'TikTok': 'https://www.tiktok.com/@$username',
      'Reddit': 'https://www.reddit.com/user/$username/',
      'Pinterest': 'https://www.pinterest.com/$username/',
      'Behance': 'https://www.behance.net/$username',
      'Dribbble': 'https://dribbble.com/$username',
      'Vimeo': 'https://vimeo.com/$username',
      'SoundCloud': 'https://soundcloud.com/$username',
      'Medium': 'https://medium.com/@$username',
      'DeviantArt': 'https://www.deviantart.com/$username',
      'Twitch': 'https://www.twitch.tv/$username',
      'Patreon': 'https://www.patreon.com/$username',
      'Letterboxd': 'https://letterboxd.com/$username/',
      'Goodreads': 'https://www.goodreads.com/$username',
      'Steam': 'https://steamcommunity.com/id/$username',
      'Discord (Web)': 'https://discord.com/users/$username',
    };

    final url = platforms[platform];
    if (url != null) {
      final uri = Uri.parse(url);
      try {
        if (await canLaunchUrl(uri)) {
          developer.log('[_launchUrl] → Status: Navigating to external profile', name: TAG);
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          developer.log('[_launchUrl] → Warning: Unable to resolve handler for URL', name: TAG);
        }
      } catch (e) {
        developer.log('[_launchUrl] → Error: $e', name: TAG, error: e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(settingsProvider).theme;
    final accentColor = AppColors.getAccent(theme);
    final backgroundColor = AppColors.getBackground(theme);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomAppBar(theme, accentColor),
            _buildSearchHeader(accentColor),
            if (_isLoading)
              const LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
                minHeight: 1,
              ),
            Expanded(
              child: _results.isEmpty && !_isLoading
                  ? _buildEmptyState(accentColor)
                  : _buildResultsList(accentColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(AppTheme theme, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: accentColor, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          Text(
            'SOCIAL_ID_PROBE',
            style: AppTextStyles.title(theme).copyWith(
              fontSize: 14,
              color: accentColor,
              letterSpacing: 4,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48), // Balancing back button
        ],
      ),
    );
  }

  Widget _buildSearchHeader(Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SYSTEM.INPUT.TARGET_NAME',
            style: TextStyle(color: color.withValues(alpha: 0.5), fontSize: 9, fontFamily: 'monospace'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _usernameController,
            style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 16),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'ENTER_HANDLE...',
              hintStyle: TextStyle(color: color.withValues(alpha: 0.2), fontSize: 16),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: color.withValues(alpha: 0.3))),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: color)),
              suffixIcon: _usernameController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey, size: 18),
                      onPressed: () => setState(() {
                        developer.log('[Interaction] → Query reset', name: TAG);
                        _usernameController.clear();
                        _results = {};
                      }),
                    )
                  : Icon(Icons.person_search, color: color.withValues(alpha: 0.5), size: 20),
            ),
            onChanged: (v) => setState(() {}),
            onSubmitted: (_) => _scan(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: Material(
              color: color.withValues(alpha: 0.1),
              child: InkWell(
                onTap: _isLoading ? null : () {
                  developer.log('[Interaction] → Global search triggered', name: TAG);
                  _scan();
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: color),
                  ),
                  child: Center(
                    child: _isLoading
                        ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: color))
                        : Text(
                            'EXEC_GLOBAL_SEARCH',
                            style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              fontFamily: 'monospace'
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(Color color) {
    final entries = _results.entries.toList();
    final detectedCount = entries.where((e) => e.value).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'NODES_SCANNED: ${entries.length}',
                style: TextStyle(color: color.withValues(alpha: 0.4), fontSize: 9, fontFamily: 'monospace'),
              ),
              Text(
                'HITS: $detectedCount',
                style: const TextStyle(color: Colors.greenAccent, fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
              ),
            ],
          ),
        ),
        const Divider(color: Colors.white10, height: 1),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: entries.length,
            separatorBuilder: (context, index) => const SizedBox(height: 1),
            itemBuilder: (context, index) {
              final e = entries[index];
              return _ResultTile(
                platform: e.key,
                found: e.value,
                accentColor: color,
                onTap: e.value ? () {
                  developer.log('[Interaction] → Inspecting hit node: ${e.key}', name: TAG);
                  _launchUrl(e.key, _usernameController.text.trim());
                } : null,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(Color color) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.radar, size: 32, color: color.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          Text(
            'SYSTEM_IDLE',
            style: TextStyle(color: color.withValues(alpha: 0.2), fontSize: 10, fontFamily: 'monospace', letterSpacing: 3)
          ),
        ],
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final String platform;
  final bool found;
  final Color accentColor;
  final VoidCallback? onTap;

  const _ResultTile({
    required this.platform,
    required this.found,
    required this.accentColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: found ? Colors.white.withValues(alpha: 0.03) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 16,
                color: found ? Colors.greenAccent : Colors.white10,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  platform.toUpperCase(),
                  style: TextStyle(
                    color: found ? Colors.white : Colors.white24,
                    fontSize: 12,
                    fontFamily: 'monospace',
                    letterSpacing: 1,
                    fontWeight: found ? FontWeight.bold : FontWeight.normal,
                  )
                ),
              ),
              if (found) ...[
                const Icon(Icons.open_in_new, color: Colors.greenAccent, size: 14),
                const SizedBox(width: 8),
                const Text(
                  'ACCESS_GRANTED',
                  style: TextStyle(color: Colors.greenAccent, fontSize: 8, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                ),
              ] else
                const Text(
                  'NOT_FOUND',
                  style: TextStyle(color: Colors.white10, fontSize: 8, fontFamily: 'monospace'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
