import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/entities/shopping_item.dart';

class AddItemScreen extends StatefulWidget {
  final String categoryName;
  final ShoppingItem? existingItem;

  const AddItemScreen({
    super.key,
    required this.categoryName,
    this.existingItem,
  });

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetPriceController = TextEditingController();
  final _currentPriceController = TextEditingController();
  final _picker = ImagePicker();
  final _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );
  final _dayFormat = DateFormat('dd/MM/yyyy');

  bool _isPurchased = false;
  DateTime? _purchasedDate;
  String? _imagePath;
  bool _isSavingImage = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingItem;
    if (existing != null) {
      _nameController.text = existing.name;
      _targetPriceController.text = _toPlainNumber(existing.targetPrice);
      _currentPriceController.text = existing.currentPrice > 0
          ? _toPlainNumber(existing.currentPrice)
          : '';
      _isPurchased = existing.isPurchased;
      _purchasedDate = existing.purchasedDate;
      _imagePath = existing.imagePath;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetPriceController.dispose();
    _currentPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUpdate = widget.existingItem != null;
    final dealInfo = _computeDealInfo();
    final targetPrice = _parseNumber(_targetPriceController.text) ?? 0;
    final currentPrice = _parseNumber(_currentPriceController.text) ?? 0;
    final historyCount = widget.existingItem?.priceHistory.length ?? 0;
    final lowestObserved = widget.existingItem?.lowestObservedPrice;

    return Scaffold(
      appBar: AppBar(title: Text(isUpdate ? 'Sửa món đồ' : 'Thêm món đồ')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label(context, 'Hạng mục'),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE9D0B8)),
                      ),
                      child: Text(widget.categoryName),
                    ),
                    const SizedBox(height: 16),
                    _label(context, 'Tên món cần mua'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        hintText: 'Ví dụ: Giỏ quà, mứt dừa, hoa tươi',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nhập tên món cần mua';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _label(context, 'Giá mục tiêu'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _targetPriceController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      decoration: const InputDecoration(hintText: 'VD: 300000'),
                      validator: (value) {
                        final parsed = _parseNumber(value);
                        if (parsed == null || parsed <= 0) {
                          return 'Nhập giá mục tiêu hợp lệ';
                        }
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                    if (targetPrice > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Mục tiêu hiện tại: ${_currencyFormat.format(targetPrice)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF6B5753),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _label(context, 'Giá deal hiện tại'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _currentPriceController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      decoration: const InputDecoration(
                        hintText: 'VD: 250000, bỏ trống nếu chưa có',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    if (targetPrice > 0) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _quickPriceChip('Deal -10%', targetPrice * 0.9),
                          _quickPriceChip('Bằng mục tiêu', targetPrice),
                          _quickPriceChip('+10%', targetPrice * 1.1),
                        ],
                      ),
                    ],
                    if (currentPrice > 0 && targetPrice > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Độ lệch: ${_currencyFormat.format((currentPrice - targetPrice).abs())} ${currentPrice > targetPrice ? '(cao hơn)' : '(thấp hơn)'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: currentPrice > targetPrice
                              ? const Color(0xFFB3261E)
                              : const Color(0xFF1B7A43),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    if (historyCount > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Lịch sử giá: $historyCount mốc${lowestObserved == null ? '' : ' · thấp nhất ${_currencyFormat.format(lowestObserved)}'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF6B5753),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _buildDealAlert(dealInfo),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Đã mua món này'),
                      subtitle: const Text('Bật khi bạn đã thanh toán'),
                      value: _isPurchased,
                      activeThumbColor: const Color(0xFFC62828),
                      onChanged: (value) async {
                        await HapticFeedback.selectionClick();
                        setState(() {
                          _isPurchased = value;
                          if (_isPurchased && _purchasedDate == null) {
                            _purchasedDate = DateTime.now();
                          }
                        });
                      },
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      child: _isPurchased
                          ? Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: OutlinedButton.icon(
                                onPressed: _pickPurchasedDate,
                                icon: const Icon(Icons.calendar_today_outlined),
                                label: Text(
                                  _purchasedDate == null
                                      ? 'Chọn ngày mua'
                                      : 'Ngày mua: ${_dayFormat.format(_purchasedDate!)}',
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 14),
                    _label(context, 'Ảnh hóa đơn/sản phẩm'),
                    const SizedBox(height: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _isSavingImage ? null : _pickImage,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 18,
                          horizontal: 14,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFE0D4C8)),
                        ),
                        child: Row(
                          children: [
                            _isSavingImage
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.add_photo_alternate_outlined,
                                  ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _imagePath == null
                                    ? 'Chọn ảnh'
                                    : 'Đã có ảnh, bấm để thay đổi',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_imagePath != null) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: 180,
                          width: double.infinity,
                          child: _buildImagePreview(_imagePath!),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () async {
                            await HapticFeedback.selectionClick();
                            setState(() => _imagePath = null);
                          },
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Xóa ảnh'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _submit,
                        child: Text(
                          isUpdate ? 'Cập nhật món đồ' : 'Thêm món đồ',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
    );
  }

  Widget _quickPriceChip(String label, double value) {
    return ActionChip(
      label: Text(label),
      onPressed: () async {
        await HapticFeedback.selectionClick();
        setState(() {
          _currentPriceController.text = value.toStringAsFixed(0);
        });
      },
    );
  }

  Widget _buildDealAlert(_DealInfo dealInfo) {
    final color = switch (dealInfo.level) {
      DealLevel.good => const Color(0xFF0F7A3D),
      DealLevel.warning => const Color(0xFFB3261E),
      DealLevel.unknown => const Color(0xFF6B6B6B),
    };

    final bgColor = switch (dealInfo.level) {
      DealLevel.good => const Color(0xFFE7F7EE),
      DealLevel.warning => const Color(0xFFFCEBEB),
      DealLevel.unknown => const Color(0xFFF5F5F5),
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(dealInfo.icon, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              dealInfo.message,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(String path) {
    if (kIsWeb) {
      return Image.network(path, fit: BoxFit.cover);
    }
    return Image.file(File(path), fit: BoxFit.cover);
  }

  Future<void> _pickImage() async {
    try {
      await HapticFeedback.lightImpact();
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image == null) return;

      if (!mounted) return;
      setState(() => _isSavingImage = true);

      final savedPath = await _saveImagePath(image.path);
      if (!mounted) return;

      setState(() {
        _imagePath = savedPath;
        _isSavingImage = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSavingImage = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể tải ảnh: $error')));
    }
  }

  Future<void> _pickPurchasedDate() async {
    final now = DateTime.now();
    final initialDate = _purchasedDate ?? now;
    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
    );
    if (selected != null) {
      setState(() => _purchasedDate = selected);
    }
  }

  Future<String> _saveImagePath(String sourcePath) async {
    if (kIsWeb) return sourcePath;

    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(appDir.path, 'tet_item_images'));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}${p.extension(sourcePath).isEmpty ? '.jpg' : p.extension(sourcePath)}';
    final destination = p.join(imagesDir.path, fileName);

    await File(sourcePath).copy(destination);
    return destination;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final targetPrice = _parseNumber(_targetPriceController.text) ?? 0;
    final currentPrice = _parseNumber(_currentPriceController.text) ?? 0;

    if (_isPurchased && currentPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Món đã mua cần có giá thanh toán lớn hơn 0'),
        ),
      );
      return;
    }

    final resultItem = ShoppingItem(
      id:
          widget.existingItem?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      targetPrice: targetPrice,
      currentPrice: currentPrice,
      isPurchased: _isPurchased,
      imagePath: _imagePath,
      date: widget.existingItem?.dateAdded,
      purchasedDate: _isPurchased ? (_purchasedDate ?? DateTime.now()) : null,
      priceHistory: List<PriceLog>.from(
        widget.existingItem?.priceHistory ?? const [],
      ),
    );

    HapticFeedback.mediumImpact();
    Navigator.pop(context, resultItem);
  }

  _DealInfo _computeDealInfo() {
    final targetPrice = _parseNumber(_targetPriceController.text);
    final currentPrice = _parseNumber(_currentPriceController.text);

    if (targetPrice == null ||
        targetPrice <= 0 ||
        currentPrice == null ||
        currentPrice <= 0) {
      return const _DealInfo(
        level: DealLevel.unknown,
        icon: Icons.tune,
        message: 'Nhập giá mục tiêu và giá hiện tại để bật deal alert.',
      );
    }

    final delta = currentPrice - targetPrice;
    if (delta <= 0) {
      return _DealInfo(
        level: DealLevel.good,
        icon: Icons.trending_down,
        message:
            'Deal tốt: thấp hơn ${_currencyFormat.format(delta.abs())} so với mục tiêu.',
      );
    }

    return _DealInfo(
      level: DealLevel.warning,
      icon: Icons.warning_amber_rounded,
      message:
          'Cân nhắc: cao hơn ${_currencyFormat.format(delta)} so với mục tiêu.',
    );
  }

  double? _parseNumber(String? input) {
    if (input == null) return null;
    final normalized = input.replaceAll('.', '').replaceAll(',', '').trim();
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  String _toPlainNumber(double value) {
    return value.toStringAsFixed(0);
  }
}

class _DealInfo {
  final DealLevel level;
  final IconData icon;
  final String message;

  const _DealInfo({
    required this.level,
    required this.icon,
    required this.message,
  });
}
