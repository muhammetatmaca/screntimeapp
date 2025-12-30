import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class MonthlyChart extends StatefulWidget {
  final List<double> data; // Usage in hours
  final double maxUsageHours;

  const MonthlyChart({
    super.key,
    required this.data,
    this.maxUsageHours = 8.0,
  });

  @override
  State<MonthlyChart> createState() => _MonthlyChartState();
}

class _MonthlyChartState extends State<MonthlyChart> {
  int? _selectedIndex;

  String _formatDuration(double hours) {
    if (hours == 0) return "0 dk";
    final totalMins = (hours * 60).round();
    final h = totalMins ~/ 60;
    final m = totalMins % 60;
    if (h > 0) return "${h}s ${m}dk";
    return "$m dk";
  }

  @override
  Widget build(BuildContext context) {
    // Verilerdeki maksimum saati bul (en az 1.0 olsun)
    double currentMax = widget.maxUsageHours;
    for (var val in widget.data) {
      if (val > currentMax) currentMax = val;
    }

    return Column(
      children: [
        // Seçilen günün bilgisi (Dinamik Gösterge)
        Container(
          height: 30,
          alignment: Alignment.center,
          child: _selectedIndex != null
              ? AnimatedOpacity(
                  opacity: 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.textPrimary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "${widget.data.length - 1 - _selectedIndex!} gün önce: ${_formatDuration(widget.data[_selectedIndex!])}",
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              : Text(
                  "Bir güne basarak detayı gör",
                  style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary),
                ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 140,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(widget.data.length, (index) {
              final val = widget.data[index];
              final heightFactor = (val / currentMax).clamp(0.01, 1.0);
              final isLast = index == widget.data.length - 1;
              final isSelected = _selectedIndex == index;
              
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Çok küçük yazı (Sadece çok yüksek barlarda veya seçiliyse)
                        if (isSelected && val > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              "${val.toStringAsFixed(1)}s",
                              style: const TextStyle(fontSize: 7, fontWeight: FontWeight.bold),
                            ),
                          ),
                        Expanded(
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.gray100,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              FractionallySizedBox(
                                heightFactor: heightFactor,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  decoration: BoxDecoration(
                                    color: isSelected 
                                        ? AppColors.iosBlue 
                                        : (isLast ? AppColors.textPrimary : AppColors.gray300),
                                    borderRadius: BorderRadius.circular(2),
                                    boxShadow: (isLast || isSelected) ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 2,
                                      )
                                    ] : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('30 gün önce', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary, fontSize: 9)),
            Text('Bugün', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 9)),
          ],
        ),
      ],
    );
  }
}
