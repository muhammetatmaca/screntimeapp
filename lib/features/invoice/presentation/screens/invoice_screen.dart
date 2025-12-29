import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
// import 'package:screenshot/screenshot.dart';
// import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:image_gallery_saver/image_gallery_saver.dart'; // Removed
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/services/usage_service.dart';
import 'widget_settings_screen.dart';

class InvoiceScreen extends StatefulWidget {
  const InvoiceScreen({super.key});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  // final ScreenshotController _screenshotController = ScreenshotController();
  List<AppUsageRecord> _apps = [];
  bool _isLoading = true;
  Duration _totalUsage = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final apps = await UsageService.getTodayAppList(withAppInfo: true);
    final total = await UsageService.getTodayTotalUsage();
    
    // 0 dakika olanları çıkar
    final filteredApps = apps.where((app) => app.usage.inMinutes > 0).toList();
    
    if (mounted) {
      setState(() {
        _apps = filteredApps.take(15).toList(); // En çok kullanılan ilk 15 uygulama
        _totalUsage = total;
        _isLoading = false;
      });
    }
  }

  Future<void> _shareScreenshot() async {
    // TODO: Re-enable when packages are added
    _showSnackBar('Paylaşım özelliği yakında eklenecek!');
    // try {
    //   final image = await _screenshotController.capture();
    //   if (image != null) {
    //     final directory = await getTemporaryDirectory();
    //     final imagePath = await File('${directory.path}/spending_invoice.png').create();
    //     await imagePath.writeAsBytes(image);
    //     
    //     await Share.shareXFiles([XFile(imagePath.path)], text: 'Günlük Ekran Süresi Extresi 📱');
    //   }
    // } catch (e) {
    //   _showSnackBar('Paylaşım sırasında bir hata oluştu.');
    // }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7), // iOS Grouped Background
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F2F7).withOpacity(0.9),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.iosBlue, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Fatura',
          style: TextStyle(
            color: Colors.black,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.widgets_outlined, color: AppColors.iosBlue, size: 24),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const WidgetSettingsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.ios_share, color: AppColors.iosBlue, size: 24),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.iosBlue))
        : Stack(
            children: [
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 120),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    // Screenshot widget disabled for now
                    _buildReceiptCard(),
                    const SizedBox(height: 16),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        'Bu belge günlük dijital kullanım özetinizdir. Veriler cihazınızdan anlık olarak alınmaktadır.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF8E8E93),
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildBottomAction(),
            ],
          ),
    );
  }

  Widget _buildReceiptCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Zigzag TOP edge (New)
          Positioned(
            top: -10,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: const Size(double.infinity, 10),
              painter: _ZigZagTopPainter(),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Color(0xFFE5E7EB),
                        style: BorderStyle.solid,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.receipt_long_rounded, size: 48, color: Colors.black),
                      const SizedBox(height: 24),
                      const Text(
                        'EKRAN SÜRESİ\nEXTRESİ',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                          fontFamily: 'Courier', // Using system mono font
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'FİŞ NO: ${DateTime.now().year}${DateTime.now().month}${DateTime.now().day}-99',
                        style: TextStyle(
                          fontSize: 13,
                          color: const Color(0xFF636366),
                          fontFamily: 'Courier',
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        '${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year} • ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF636366),
                          fontFamily: 'Courier',
                        ),
                      ),
                    ],
                  ),
                ),

                // Items
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildHeaderRow(),
                      const SizedBox(height: 16),
                      ..._apps.map((app) => Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: _buildReceiptItem(
                          iconBase64: app.iconBase64,
                          name: app.appName ?? app.packageName.split('.').last,
                          category: 'Uygulama',
                          duration: _formatDurationShort(app.usage),
                          percentage: _totalUsage.inMinutes > 0 
                              ? '%${((app.usage.inMinutes / _totalUsage.inMinutes) * 100).toStringAsFixed(0)}'
                              : '%0',
                        ),
                      )).toList(),
                    ],
                  ),
                ),

                // Subtotal
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Color(0xFFE5E7EB),
                        style: BorderStyle.none, // Handled by dashed custom painter if possible
                        width: 2,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Dash line replacement
                      CustomPaint(
                        size: const Size(double.infinity, 2),
                        painter: _DashPainter(),
                      ),
                      const SizedBox(height: 24),
                      _buildTotalRow('AKTİF SÜRE', _formatDurationShort(_totalUsage)),
                      const SizedBox(height: 12),
                      _buildTotalRow('BOŞTA KALAN', _formatDurationShort(const Duration(hours: 24) - _totalUsage)),
                      const SizedBox(height: 16),
                      const Divider(color: Colors.black, thickness: 1.5),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'TOPLAM KULLANIM',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            _formatDurationFull(_totalUsage),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Courier',
                              letterSpacing: -1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Barcode
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
                  child: Column(
                    children: [
                      _buildBarcode(),
                      const SizedBox(height: 16),
                      const Text(
                        'ES-2023-PAY-ID',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 3,
                          fontFamily: 'Courier',
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'DURUM: ONAYLANDI',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Zigzag bottom edge (simulated with clipping or custom paint)
          Positioned(
            bottom: -10,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: const Size(double.infinity, 10),
              painter: _ZigZagPainter(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black, width: 1)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'HİZMET',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          Row(
            children: [
              SizedBox(width: 48, child: Text('SÜRE', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1))),
              SizedBox(width: 64, child: Text('PAY', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptItem({
    String? iconBase64,
    required String name,
    required String category,
    required String duration,
    required String percentage,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE5E7EB)),
                color: const Color(0xFFF9FAFB),
              ),
              child: iconBase64 != null 
                ? ClipOval(child: Image.memory(base64Decode(iconBase64), fit: BoxFit.cover))
                : const Icon(Icons.apps_rounded, size: 18, color: Colors.black),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Courier'),
                  ),
                ),
                Text(
                  category,
                  style: const TextStyle(fontSize: 10, color: Color(0xFF636366)),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            SizedBox(
              width: 58,
              child: Text(
                duration,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 13, fontFamily: 'Courier'),
              ),
            ),
            SizedBox(
              width: 54,
              child: Text(
                percentage,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Courier'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDurationShort(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}sa ${d.inMinutes % 60}dk';
    }
    return '${d.inMinutes}dk';
  }

  String _formatDurationFull(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    return "${twoDigits(d.inHours)}:$twoDigitMinutes:00";
  }

  Widget _buildTotalRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF636366), fontFamily: 'Courier'),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, fontFamily: 'Courier'),
        ),
      ],
    );
  }

  Widget _buildBarcode() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(24, (index) {
        final widths = [1, 1, 2, 1, 3, 1, 2, 1, 1, 3, 1, 2, 1, 1, 4, 1, 2, 1, 3, 2, 1, 1, 2, 1];
        final heights = [40, 30, 40, 25, 40, 20, 40, 30, 40, 25, 40, 30, 40, 30, 40, 25, 40, 20, 40, 30, 40, 25, 40, 30];
        
        return Container(
          width: widths[index % widths.length].toDouble(),
          height: heights[index % heights.length].toDouble(),
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          color: Colors.black,
        );
      }),
    );
  }

  Widget _buildBottomAction() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F7).withOpacity(0.9),
          border: const Border(
            top: BorderSide(color: Color(0xFFC6C6C8), width: 0.5),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton(
              onPressed: _shareScreenshot,
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                side: BorderSide.none,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.ios_share, size: 20),
                  SizedBox(width: 12),
                  Text('Extreyi Paylaş', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Kapat',
                style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    var max = size.width;
    var dashWidth = 8;
    var dashSpace = 8;
    double startX = 0;
    while (startX < max) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ZigZagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    var path = Path();
    path.moveTo(0, 0);
    
    double x = 0;
    double y = 0;
    double step = 8;
    
    while (x < size.width) {
      x += step;
      y = (y == 0) ? size.height : 0;
      path.lineTo(x, y);
    }
    
    path.lineTo(size.width, 0);
    path.close();
    
    canvas.drawPath(path, paint);
    
    // Shadow for zigzag
    var shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
      
    canvas.drawPath(path, shadowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ZigZagTopPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    var path = Path();
    path.moveTo(0, size.height);
    
    double x = 0;
    double y = size.height;
    double step = 8;
    
    while (x < size.width) {
      x += step;
      y = (y == size.height) ? 0 : size.height;
      path.lineTo(x, y);
    }
    
    path.lineTo(size.width, size.height);
    path.close();
    
    canvas.drawPath(path, paint);
    
    var shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
      
    canvas.drawPath(path, shadowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
