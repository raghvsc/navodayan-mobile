import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/offering.dart';
import '../services/offerings_service.dart';
import '../theme/app_theme.dart';

class OfferingsScreen extends StatefulWidget {
  const OfferingsScreen({super.key});

  @override
  State<OfferingsScreen> createState() => _OfferingsScreenState();
}

class _OfferingsScreenState extends State<OfferingsScreen> {
  final OfferingsService _service = OfferingsService();
  final TextEditingController _searchController = TextEditingController();

  List<OfferingItem> _offerings = [];
  List<OfferingCategory> _categories = [];
  String _selectedCategory = 'ALL';
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _service.getOfferings(
          category: _selectedCategory,
          search: _searchController.text.trim(),
        ),
        _service.getCategories(),
      ]);

      if (mounted) {
        setState(() {
          _offerings = results[0] as List<OfferingItem>;
          _categories = results[1] as List<OfferingCategory>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Unable to load offerings at this time.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleExpressInterest(OfferingItem item) async {
    try {
      await _service.expressInterest(item.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Expressed interest in ${item.businessName}! The coordinator or owner will be notified.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to express interest: $e')),
        );
      }
    }
  }

  void _showAddOfferingDialog() {
    final nameController = TextEditingController();
    final summaryController = TextEditingController();
    final websiteController = TextEditingController();
    final phoneController = TextEditingController();
    final cityController = TextEditingController();
    String selectedCat = 'SERVICE';
    bool hiring = false;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final colors = AppColors.of(context);
          return Container(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Post Your Offering',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Business or Project Name',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'e.g. NavoTech Solutions',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Category',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedCat,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    items: [
                      const DropdownMenuItem(value: 'SERVICE', child: Text('Service')),
                      const DropdownMenuItem(value: 'HIRING', child: Text('Hiring / Jobs')),
                      const DropdownMenuItem(value: 'PRODUCT', child: Text('Product')),
                      const DropdownMenuItem(value: 'PRACTICE', child: Text('Practice / Professional')),
                      const DropdownMenuItem(value: 'VOLUNTEER', child: Text('Volunteer Initiative')),
                      const DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedCat = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Summary',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: summaryController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Describe your business or services to alumni...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Website / URL (Optional)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: websiteController,
                    decoration: InputDecoration(
                      hintText: 'https://example.com',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'City / Location (Optional)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: cityController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Bangalore, India',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Currently Hiring Navodayans?'),
                    value: hiring,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setModalState(() => hiring = val),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final name = nameController.text.trim();
                            final summary = summaryController.text.trim();
                            if (name.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter a business or offering name')),
                              );
                              return;
                            }
                            setModalState(() => isSubmitting = true);
                            try {
                              await _service.saveMyOffering({
                                'businessName': name,
                                'category': selectedCat,
                                'summary': summary,
                                if (websiteController.text.trim().isNotEmpty)
                                  'website': websiteController.text.trim(),
                                if (cityController.text.trim().isNotEmpty)
                                  'city': cityController.text.trim(),
                                'hiring': hiring,
                              });
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Offering posted successfully!')),
                                );
                                _loadData();
                              }
                            } catch (e) {
                              setModalState(() => isSubmitting = false);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to save offering: $e')),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: isSubmitting
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Post Offering', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _categoryColor(String category) {
    switch (category.toUpperCase()) {
      case 'SERVICE':
        return const Color(0xFF3B82F6);
      case 'HIRING':
        return const Color(0xFF10B981);
      case 'PRODUCT':
        return const Color(0xFF8B5CF6);
      case 'PRACTICE':
        return const Color(0xFFF59E0B);
      case 'VOLUNTEER':
        return const Color(0xFFEC4899);
      default:
        return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Navodayan Offerings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter header
          Container(
            color: colors.surface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onSubmitted: (_) => _loadData(),
                  decoration: InputDecoration(
                    hintText: 'Search businesses, products, services...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _loadData();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: colors.border)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('ALL', 'All Offerings', colors),
                      ..._categories.map((c) => _buildFilterChip(c.key, c.label, colors)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Offerings List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline_rounded, size: 48, color: colors.error),
                            const SizedBox(height: 12),
                            Text(_errorMessage!, style: TextStyle(color: colors.textSecondary)),
                            const SizedBox(height: 16),
                            ElevatedButton(onPressed: _loadData, child: const Text('Try Again')),
                          ],
                        ),
                      )
                    : _offerings.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.storefront_outlined, size: 56, color: colors.textSecondary),
                                const SizedBox(height: 12),
                                Text(
                                  'No offerings found',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Be the first to list your business or services!',
                                  style: TextStyle(fontSize: 13, color: colors.textSecondary),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                  onPressed: _showAddOfferingDialog,
                                  icon: const Icon(Icons.add_rounded),
                                  label: const Text('Post Your Offering'),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadData,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _offerings.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 14),
                              itemBuilder: (context, index) {
                                final item = _offerings[index];
                                final catColor = _categoryColor(item.category);

                                return Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: colors.surface,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: colors.border),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.businessName,
                                              style: TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.bold,
                                                color: colors.textPrimary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: catColor.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              item.categoryLabel ?? item.category,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: catColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (item.hiring) ...[
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: colors.success.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.work_outline_rounded, size: 14, color: colors.success),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Actively Hiring Alumni',
                                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.success),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      if (item.summary != null && item.summary!.isNotEmpty) ...[
                                        const SizedBox(height: 10),
                                        Text(
                                          item.summary!,
                                          style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.4),
                                        ),
                                      ],
                                      if (item.city != null || item.country != null) ...[
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Icon(Icons.location_on_outlined, size: 14, color: colors.textSecondary),
                                            const SizedBox(width: 4),
                                            Text(
                                              [item.city, item.country].where((e) => e != null).join(', '),
                                              style: TextStyle(fontSize: 12, color: colors.textSecondary),
                                            ),
                                          ],
                                        ),
                                      ],
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          if (item.website != null && item.website!.isNotEmpty)
                                            OutlinedButton.icon(
                                              onPressed: () async {
                                                final uri = Uri.tryParse(item.website!);
                                                if (uri != null && await canLaunchUrl(uri)) {
                                                  await launchUrl(uri);
                                                }
                                              },
                                              icon: const Icon(Icons.open_in_new_rounded, size: 14),
                                              label: const Text('Website', style: TextStyle(fontSize: 12)),
                                              style: OutlinedButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              ),
                                            ),
                                          const Spacer(),
                                          ElevatedButton.icon(
                                            onPressed: () => _handleExpressInterest(item),
                                            icon: const Icon(Icons.handshake_outlined, size: 14),
                                            label: const Text('I\'m Interested', style: TextStyle(fontSize: 12)),
                                            style: ElevatedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddOfferingDialog,
        icon: const Icon(Icons.add_business_rounded),
        label: const Text('Post Offering'),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, ThemePalette colors) {
    final isSelected = _selectedCategory == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : colors.textPrimary,
        ),
        selectedColor: colors.primary,
        backgroundColor: colors.surface,
        checkmarkColor: Colors.white,
        onSelected: (_) {
          setState(() {
            _selectedCategory = key;
          });
          _loadData();
        },
      ),
    );
  }
}
