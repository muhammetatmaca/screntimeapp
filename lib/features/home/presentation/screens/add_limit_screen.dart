import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/services/usage_service.dart';
import '../../../../core/services/limit_service.dart';
import '../../../onboarding/presentation/widgets/onboarding_buttons.dart';

class AddLimitScreen extends StatefulWidget {
  const AddLimitScreen({super.key});

  @override
  State<AddLimitScreen> createState() => _AddLimitScreenState();
}

class _AddLimitScreenState extends State<AddLimitScreen> {
  List<Map<String, String>> _allApps = [];
  List<Map<String, String>> _filteredApps = [];
  Map<String, int> _existingLimits = {}; // {packageName: limitMinutes}
  bool _isLoading = true;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    final apps = await UsageService.getInstalledApps();
    final limits = await LimitService.getLimits();
    
    final Map<String, int> limitsMap = {
      for (var l in limits) l.packageName: l.limitMinutes
    };

    apps.sort((a, b) => a['appName']!.toLowerCase().compareTo(b['appName']!.toLowerCase()));
    
    if (mounted) {
      setState(() {
        _allApps = apps;
        _filteredApps = apps;
        _existingLimits = limitsMap;
        _isLoading = false;
      });
    }
  }

  void _filterApps(String query) {
    setState(() {
      _searchQuery = query;
      _filteredApps = _allApps
          .where((app) =>
              app['appName']!.toLowerCase().contains(query.toLowerCase()) ||
              app['packageName']!.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _selectApp(Map<String, String> app) {
    final existingLimit = _existingLimits[app['packageName']];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TimePickerDialog(
        app: app, 
        initialMinutes: existingLimit,
      ),
    ).then((value) {
      if (value == true) {
        _loadApps(); // Refresh limits after saving
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Limit Ekle', style: AppTextStyles.headlineSmall.copyWith(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.gray100),
              ),
              child: TextField(
                onChanged: _filterApps,
                decoration: const InputDecoration(
                  hintText: 'Uygulama ara...',
                  border: InputBorder.none,
                  icon: Icon(Icons.search_rounded, color: AppColors.textTertiary),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredApps.length,
                    itemBuilder: (context, index) {
                      final app = _filteredApps[index];
                      final existingLimit = _existingLimits[app['packageName']];
                      return _AppListItem(
                        app: app,
                        currentLimitMinutes: existingLimit,
                        onTap: () => _selectApp(app),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _AppListItem extends StatelessWidget {
  final Map<String, String> app;
  final int? currentLimitMinutes;
  final VoidCallback onTap;

  const _AppListItem({
    required this.app, 
    required this.onTap,
    this.currentLimitMinutes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray100),
      ),
      child: ListTile(
        onTap: onTap,
        leading: FutureBuilder<String?>(
          future: UsageService.getAppIcon(app['packageName']!),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(
                  base64Decode(snapshot.data!),
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                ),
              );
            }
            return Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.apps_rounded, color: AppColors.textTertiary),
            );
          },
        ),
        title: Text(app['appName']!, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
        subtitle: Text(
          currentLimitMinutes != null 
              ? 'Mevcut Limit: ${(currentLimitMinutes! ~/ 60)}s ${(currentLimitMinutes! % 60)}dk'
              : app['packageName']!, 
          style: AppTextStyles.labelSmall.copyWith(
            color: currentLimitMinutes != null ? AppColors.iosBlue : AppColors.textTertiary,
            fontWeight: currentLimitMinutes != null ? FontWeight.w600 : FontWeight.normal,
          ), 
          maxLines: 1, 
          overflow: TextOverflow.ellipsis
        ),
        trailing: Icon(
          currentLimitMinutes != null ? Icons.edit_rounded : Icons.add_circle_outline_rounded, 
          color: currentLimitMinutes != null ? AppColors.iosBlue : AppColors.gray300
        ),
      ),
    );
  }
}

class _TimePickerDialog extends StatefulWidget {
  final Map<String, String> app;
  final int? initialMinutes;
  const _TimePickerDialog({required this.app, this.initialMinutes});

  @override
  State<_TimePickerDialog> createState() => _TimePickerDialogState();
}

class _TimePickerDialogState extends State<_TimePickerDialog> {
  late int _hours;
  late int _minutes;

  @override
  void initState() {
    super.initState();
    _hours = widget.initialMinutes != null ? (widget.initialMinutes! ~/ 60) : 1;
    _minutes = widget.initialMinutes != null ? (widget.initialMinutes! % 60) : 0;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Süre Belirle', style: AppTextStyles.headlineSmall.copyWith(fontWeight: FontWeight.w800)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.app['appName']} için günlük kullanım limiti seçin.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPickerColumn('Saat', 0, 23, _hours, (val) => setState(() => _hours = val)),
              const Text(':', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              _buildPickerColumn('Dakika', 0, 59, _minutes, (val) => setState(() => _minutes = val)),
            ],
          ),
          const SizedBox(height: 32),
          PrimaryButton(
            text: 'Limiti Kaydet',
            onPressed: () async {
              final limitMinutes = (_hours * 60) + _minutes;
              if (limitMinutes == 0) return;

              await LimitService.saveLimit(AppLimit(
                packageName: widget.app['packageName']!,
                appName: widget.app['appName']!,
                limitMinutes: limitMinutes,
              ));
              
              if (mounted) Navigator.pop(context, true);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPickerColumn(String label, int min, int max, int current, Function(int) onSelected) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.overline.copyWith(color: AppColors.textTertiary)),
        const SizedBox(height: 8),
        SizedBox(
          height: 150,
          width: 80,
          child: ListWheelScrollView.useDelegate(
            itemExtent: 50,
            onSelectedItemChanged: onSelected,
            physics: const FixedExtentScrollPhysics(),
            controller: FixedExtentScrollController(initialItem: current),
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: max - min + 1,
              builder: (context, index) {
                final val = index + min;
                final isSelected = val == current;
                return Center(
                  child: Text(
                    val.toString().padLeft(2, '0'),
                    style: TextStyle(
                      fontSize: isSelected ? 32 : 24,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                      color: isSelected ? AppColors.textPrimary : AppColors.gray300,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
