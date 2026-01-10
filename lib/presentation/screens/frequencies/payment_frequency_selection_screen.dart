import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../data/models/payment_frequency.dart';
import '../../../data/providers/payment_frequency_provider.dart';

enum FrequencySortOption { name, days }

class PaymentFrequencySelectionScreen extends ConsumerStatefulWidget {
  const PaymentFrequencySelectionScreen({super.key});

  @override
  ConsumerState<PaymentFrequencySelectionScreen> createState() =>
      _PaymentFrequencySelectionScreenState();
}

class _PaymentFrequencySelectionScreenState
    extends ConsumerState<PaymentFrequencySelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  FrequencySortOption _sortOption = FrequencySortOption.days;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frequenciesAsync = ref.watch(activePaymentFrequenciesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).selectFrequency),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SearchBar(
              controller: _searchController,
              hintText: S.of(context).searchFrequency,
              leading: const Icon(Icons.search, color: AppColors.textSecondary),
              elevation: WidgetStateProperty.all(0),
              backgroundColor: WidgetStateProperty.all(
                Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              trailing: [
                if (_searchQuery.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  ),
              ],
            ),
          ),
        ),
        actions: [
          PopupMenuButton<FrequencySortOption>(
            icon: const Icon(Icons.sort),
            tooltip: S.of(context).sortBy,
            onSelected: (FrequencySortOption result) {
              setState(() {
                _sortOption = result;
              });
            },
            itemBuilder: (BuildContext context) =>
                <PopupMenuEntry<FrequencySortOption>>[
                  PopupMenuItem<FrequencySortOption>(
                    value: FrequencySortOption.name,
                    child: Row(
                      children: [
                        Icon(
                          Icons.sort_by_alpha,
                          color: _sortOption == FrequencySortOption.name
                              ? AppColors.primary
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          S.of(context).sortByName,
                          style: TextStyle(
                            fontWeight: _sortOption == FrequencySortOption.name
                                ? FontWeight.bold
                                : null,
                            color: _sortOption == FrequencySortOption.name
                                ? AppColors.primary
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem<FrequencySortOption>(
                    value: FrequencySortOption.days,
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: _sortOption == FrequencySortOption.days
                              ? AppColors.primary
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          S.of(context).sortByDays,
                          style: TextStyle(
                            fontWeight: _sortOption == FrequencySortOption.days
                                ? FontWeight.bold
                                : null,
                            color: _sortOption == FrequencySortOption.days
                                ? AppColors.primary
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: frequenciesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text(
            'Error: $err',
            style: const TextStyle(color: AppColors.danger),
          ),
        ),
        data: (frequencies) {
          // Filter
          final filtered = frequencies.where((f) {
            final matchesSearch =
                f.name.toLowerCase().contains(_searchQuery) ||
                f.daysInterval.toString().contains(_searchQuery);
            return matchesSearch;
          }).toList();

          // Sort
          filtered.sort((a, b) {
            switch (_sortOption) {
              case FrequencySortOption.name:
                return a.name.compareTo(b.name);
              case FrequencySortOption.days:
                return a.daysInterval.compareTo(b.daysInterval);
            }
          });

          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.search_off,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    S.of(context).noFrequenciesFound,
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: filtered.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final frequency = filtered[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    frequency.daysInterval.toString(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  frequency.name,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  '${frequency.daysInterval} ${S.of(context).daysInterval.toLowerCase()}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () {
                  context.pop(frequency);
                },
              );
            },
          );
        },
      ),
    );
  }
}
