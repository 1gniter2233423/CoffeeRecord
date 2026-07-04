import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/brew_provider.dart';
import '../models/brew_record.dart';
import 'add_record_screen.dart';
import 'detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('手冲咖啡记录'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Consumer<BrewProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.records.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadRecords(),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: provider.records.length,
              itemBuilder: (context, index) {
                return _BrewCard(record: provider.records[index]);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAdd(context),
        icon: const Icon(Icons.add),
        label: const Text('记录冲煮'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Brewista 风格手冲壶
          SizedBox(
            width: 120,
            height: 120,
            child: CustomPaint(
              size: const Size(120, 120),
              painter: _KettlePainter(),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '还没有冲煮记录',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击下方按钮开始记录你的第一杯手冲',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToAdd(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddRecordScreen()),
    );
  }
}

class _BrewCard extends StatelessWidget {
  final BrewRecord record;

  const _BrewCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy/MM/dd HH:mm').format(record.brewDate);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DetailScreen(record: record),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题行：咖啡名 + 评分
              Row(
                children: [
                  Expanded(
                    child: Text(
                      record.coffeeName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (record.rating != null) _buildRating(record.rating!),
                ],
              ),

              const SizedBox(height: 4),

              // 产地 + 烘焙度
              if (record.origin != null || record.roastLevel != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      if (record.origin != null) ...[
                        Icon(Icons.public, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          record.origin!,
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                      if (record.origin != null && record.roastLevel != null)
                        const SizedBox(width: 12),
                      if (record.roastLevel != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _roastColor(record.roastLevel!).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            record.roastLevel!,
                            style: TextStyle(
                              fontSize: 11,
                              color: _roastColor(record.roastLevel!),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

              // 参数行
              Row(
                children: [
                  _doseChip('${record.doseG}g'),
                  const SizedBox(width: 8),
                  _paramChip(Icons.water_drop, '${record.waterMl}ml'),
                  const SizedBox(width: 8),
                  _paramChip(Icons.swap_horiz, record.ratioDisplay),
                ],
              ),
              if (record.waterTemp != null || record.brewTimeDisplay != '--')
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      if (record.waterTemp != null)
                        _paramChip(Icons.thermostat, '${record.waterTemp}℃'),
                      if (record.waterTemp != null && record.brewTimeDisplay != '--')
                        const SizedBox(width: 8),
                      if (record.brewTimeDisplay != '--')
                        _paramChip(Icons.timer, record.brewTimeDisplay),
                    ],
                  ),
                ),
              if (record.brewTechnique != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      Icon(Icons.local_cafe, size: 13, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        '手法：${record.brewTechnique}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),

              // 日期
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 12, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(
                      dateStr,
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ),
              ),

              // 品鉴摘要
              if (record.goodFlavors != null || record.badFlavors != null || record.improvement != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      if (record.goodFlavors != null && record.goodFlavors!.isNotEmpty)
                        _flavorLine(Icons.thumb_up_alt, Colors.green, record.goodFlavors!),
                      if (record.badFlavors != null && record.badFlavors!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: _flavorLine(Icons.thumb_down_alt, Colors.red, record.badFlavors!),
                        ),
                      if (record.improvement != null && record.improvement!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: _flavorLine(Icons.lightbulb_outline, Colors.amber[700]!, record.improvement!),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRating(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < rating ? Icons.favorite : Icons.favorite_border,
          color: i < rating ? Colors.red[400] : Colors.grey[300],
          size: 16,
        );
      }),
    );
  }

  /// 粉量芯片（咖啡豆图标）
  Widget _doseChip(String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 16, height: 16,
          child: CustomPaint(painter: _CoffeeBeanPainter()),
        ),
        const SizedBox(width: 3),
        Text(
          text,
          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
        ),
      ],
    );
  }

  Widget _paramChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.brown[400]),
        const SizedBox(width: 3),
        Text(
          text,
          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
        ),
      ],
    );
  }

  Widget _flavorLine(IconData icon, Color color, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12, color: Colors.grey[700], height: 1.3),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Color _roastColor(String roastLevel) {
    switch (roastLevel) {
      case '极浅烘':
        return Colors.yellow[700]!;
      case '浅烘':
        return Colors.orange[300]!;
      case '中烘':
        return Colors.brown[400]!;
      case '深烘':
        return Colors.brown[700]!;
      case '极深烘':
        return Colors.brown[900]!;
      default:
        return Colors.grey;
    }
  }
}

// ============ 自定义绘图 ============

/// Brewista Artisan 风格手冲壶（缩短版）
class _KettlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.brown[400]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    // ---- 壶身（矮胖圆柱） ----
    // 垂直范围压缩到 h*0.38 ~ h*0.82
    final bodyPath = Path()
      ..moveTo(w * 0.25, h * 0.82)     // 左下
      ..lineTo(w * 0.25, h * 0.42)     // 左侧垂直
      ..cubicTo(
        w * 0.27, h * 0.34,
        w * 0.34, h * 0.32,
        w * 0.50, h * 0.32,            // 左肩
      )
      ..cubicTo(
        w * 0.66, h * 0.32,
        w * 0.73, h * 0.34,
        w * 0.75, h * 0.42,            // 右肩
      )
      ..lineTo(w * 0.75, h * 0.82)
      ..close();
    canvas.drawPath(bodyPath, p);

    // ---- 壶盖 ----
    canvas.drawLine(Offset(w * 0.25, h * 0.34), Offset(w * 0.75, h * 0.34), p);
    final lidTop = Path()
      ..moveTo(w * 0.28, h * 0.34)
      ..quadraticBezierTo(w * 0.50, h * 0.31, w * 0.72, h * 0.34);
    canvas.drawPath(lidTop, p);
    // 盖钮
    final knob = Path()
      ..moveTo(w * 0.44, h * 0.32)
      ..lineTo(w * 0.56, h * 0.32)
      ..lineTo(w * 0.57, h * 0.29)
      ..lineTo(w * 0.43, h * 0.29)
      ..close();
    canvas.drawPath(knob, p);

    // ---- 鹅颈壶嘴 ----
    final spout = Path()
      ..moveTo(w * 0.73, h * 0.42)
      ..cubicTo(w * 0.82, h * 0.38, w * 0.90, h * 0.32, w * 0.88, h * 0.24)
      ..cubicTo(w * 0.87, h * 0.20, w * 0.83, h * 0.18, w * 0.80, h * 0.20);
    canvas.drawPath(spout, p);

    // ---- 把手 ----
    final handle = Path()
      ..moveTo(w * 0.25, h * 0.82)
      ..cubicTo(w * 0.06, h * 0.76, w * 0.02, h * 0.48, w * 0.08, h * 0.36)
      ..cubicTo(w * 0.12, h * 0.28, w * 0.18, h * 0.30, w * 0.25, h * 0.34);
    canvas.drawPath(handle, p);

    // ---- 底座 ----
    canvas.drawLine(Offset(w * 0.22, h * 0.82), Offset(w * 0.78, h * 0.82), p);
    canvas.drawLine(Offset(w * 0.24, h * 0.86), Offset(w * 0.76, h * 0.86), p..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 咖啡豆图标 - 肾形豆
class _CoffeeBeanPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    // 左半豆（深色）- 外弧饱满
    final left = Paint()..color = Colors.brown[500]!..style = PaintingStyle.fill;
    final lp = Path()
      ..moveTo(cx - w * 0.01, cy - h * 0.38)
      ..cubicTo(cx - w * 0.30, cy - h * 0.32, cx - w * 0.30, cy + h * 0.22, cx - w * 0.06, cy + h * 0.38)
      ..cubicTo(cx - w * 0.02, cy + h * 0.34, cx + w * 0.01, cy + h * 0.28, cx + w * 0.01, cy - h * 0.38)
      ..close();
    canvas.drawPath(lp, left);

    // 右半豆（浅色）- 内弧稍平
    final right = Paint()..color = Colors.brown[300]!..style = PaintingStyle.fill;
    final rp = Path()
      ..moveTo(cx + w * 0.01, cy - h * 0.38)
      ..cubicTo(cx + w * 0.30, cy - h * 0.30, cx + w * 0.26, cy + h * 0.20, cx + w * 0.06, cy + h * 0.38)
      ..cubicTo(cx + w * 0.02, cy + h * 0.34, cx - w * 0.01, cy + h * 0.28, cx - w * 0.01, cy - h * 0.38)
      ..close();
    canvas.drawPath(rp, right);

    // S 形中缝
    final line = Paint()..color = Colors.brown[700]!..style = PaintingStyle.stroke..strokeWidth = 1.5..strokeCap = StrokeCap.round;
    final sl = Path()
      ..moveTo(cx, cy - h * 0.37)
      ..cubicTo(cx + w * 0.04, cy - h * 0.10, cx - w * 0.04, cy + h * 0.10, cx + w * 0.01, cy + h * 0.36);
    canvas.drawPath(sl, line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
