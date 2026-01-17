import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prestamos_app/core/localization/locale_provider.dart';
import 'package:prestamos_app/core/theme/app_colors.dart';
import 'package:prestamos_app/core/theme/app_typography.dart';
import 'package:prestamos_app/data/models/customer.dart';
import 'package:prestamos_app/data/models/customer_category.dart';
import 'package:prestamos_app/data/providers/customer_category_provider.dart';

/// Pantalla para gestionar las categorías de los clientes (operaciones CRUD).
class CustomerCategoriesScreen extends ConsumerStatefulWidget {
  /// Crea una instancia de [CustomerCategoriesScreen].
  const CustomerCategoriesScreen({super.key});

  @override
  ConsumerState<CustomerCategoriesScreen> createState() =>
      _CustomerCategoriesScreenState();
}

class _CustomerCategoriesScreenState
    extends ConsumerState<CustomerCategoriesScreen> {
  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(customerCategoriesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).customerCategories)),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCategoryDialog,
        child: const Icon(Icons.add),
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (categories) {
          if (categories.isEmpty) {
            return _buildEmptyState();
          }
          return _buildCategoryList(categories);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            S.of(context).noCategories,
            style: AppTypography.titleMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            S.of(context).noCategoriesHint,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList(List<CustomerCategory> categories) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryCard(category);
      },
    );
  }

  Widget _buildCategoryCard(CustomerCategory category) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _parseColor(category.colorHex) ?? AppColors.primary,
          child: Text(
            category.name.isNotEmpty ? category.name[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(category.name),
        trailing: PopupMenuButton<String>(
          onSelected: (action) {
            if (action == 'edit') {
              _showCategoryDialog(category: category);
            } else if (action == 'delete') {
              _confirmDelete(category);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  const Icon(Icons.edit),
                  const SizedBox(width: 8),
                  Text(S.of(context).edit),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete, color: AppColors.danger),
                  const SizedBox(width: 8),
                  Text(
                    S.of(context).delete,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color? _parseColor(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) return null;
    try {
      final hex = hexColor.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } on Exception catch (_) {
      return null;
    }
  }

  Future<void> _showCategoryDialog({CustomerCategory? category}) async {
    final isEditing = category != null;
    final nameController = TextEditingController(text: category?.name ?? '');
    final formKey = GlobalKey<FormState>();
    var selectedColorHex = category?.colorHex;

    final result = await showDialog<Map<String, String?>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(
            isEditing ? S.of(context).editCategory : S.of(context).addCategory,
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(dialogContext).size.height * 0.5,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: S.of(context).categoryName,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return S.of(context).categoryRequired;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      S.of(context).colorSelector,
                      style: AppTypography.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    ColorPicker(
                      color: selectedColorHex != null
                          ? _parseColor(selectedColorHex) ?? Colors.blue
                          : Colors.blue,
                      onColorChanged: (Color color) {
                        setDialogState(() {
                          selectedColorHex = color
                              .toARGB32()
                              .toRadixString(16)
                              .padLeft(8, '0')
                              .substring(2)
                              .toUpperCase();
                        });
                      },
                      width: 28,
                      height: 28,
                      borderRadius: 14,
                      spacing: 6,
                      runSpacing: 6,
                      wheelDiameter: 140,
                      wheelWidth: 12,
                      enableShadesSelection: false,
                      pickersEnabled: const <ColorPickerType, bool>{
                        ColorPickerType.wheel: true,
                        ColorPickerType.accent: false,
                        ColorPickerType.primary: false,
                        ColorPickerType.custom: false,
                        ColorPickerType.customSecondary: false,
                      },
                      showColorCode: true,
                      colorCodeHasColor: true,
                      copyPasteBehavior: const ColorPickerCopyPasteBehavior(
                        copyFormat: ColorPickerCopyFormat.hexRRGGBB,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(S.of(context).cancel),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext, {
                    'name': nameController.text.trim(),
                    'color': selectedColorHex,
                  });
                }
              },
              child: Text(S.of(context).save),
            ),
          ],
        ),
      ),
    );

    if (result != null &&
        result['name'] != null &&
        result['name']!.isNotEmpty) {
      final name = result['name']!;
      final colorHex = result['color'];

      if (isEditing) {
        await ref
            .read(customerCategoriesProvider.notifier)
            .updateCategory(category.copyWith(name: name, colorHex: colorHex));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context).categoryUpdated)),
          );
        }
      } else {
        await ref
            .read(customerCategoriesProvider.notifier)
            .add(name: name, colorHex: colorHex);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context).categoryCreated)),
          );
        }
      }
    }
  }

  Future<void> _confirmDelete(CustomerCategory category) async {
    // Check if category is in use
    final customers = await ref
        .read(customerCategoriesProvider.notifier)
        .getCustomersWithCategory(category.categoryId);

    if (customers.isNotEmpty) {
      if (!mounted) return;
      // Show warning dialog
      final customerCount = customers.length;
      final firstCustomer = customers.first as Customer;
      final message = customerCount == 1
          ? S.of(context).categoryInUseByOne(firstCustomer.displayName)
          : S.of(context).categoryInUseByMany(customerCount);
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(S.of(context).categoryInUse),
          content: Text(message),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(S.of(context).understood),
            ),
          ],
        ),
      );
      return;
    }

    // Confirm deletion
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context).deleteCategory),
        content: Text('${S.of(context).delete} "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(S.of(context).cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: Text(S.of(context).delete),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      final success = await ref
          .read(customerCategoriesProvider.notifier)
          .delete(category.categoryId);

      if (mounted && success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(S.of(context).categoryDeleted)));
      }
    }
  }
}
