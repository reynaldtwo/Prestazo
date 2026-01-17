// ignore_for_file: deprecated_member_use // Using deprecated members until migration roadmap is defined
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prestamos_app/core/localization/locale_provider.dart';
import 'package:prestamos_app/core/providers/currency_provider.dart';
import 'package:prestamos_app/core/theme/app_colors.dart';
import 'package:prestamos_app/core/theme/app_typography.dart';
import 'package:sealed_currencies/sealed_currencies.dart';

/// Pantalla de selección de moneda.
class CurrencySelectionScreen extends ConsumerStatefulWidget {
  /// Crea una instancia de [CurrencySelectionScreen].
  const CurrencySelectionScreen({
    super.key,
    this.initialValue,
    this.isGlobalUpdate = false,
  });

  /// Valor inicial seleccionado.
  final String? initialValue;

  /// Indica si la actualización debe ser global en el proveedor de moneda del app.
  final bool isGlobalUpdate;

  @override
  ConsumerState<CurrencySelectionScreen> createState() =>
      _CurrencySelectionScreenState();
}

class _CurrencySelectionScreenState
    extends ConsumerState<CurrencySelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<FiatCurrency> _allCurrencies = FiatCurrency.list;
  List<FiatCurrency> _filteredCurrencies = [];

  @override
  void initState() {
    super.initState();
    _filteredCurrencies = _allCurrencies;
    _searchController.addListener(_filterCurrencies);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCurrencies() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCurrencies = _allCurrencies.where((currency) {
        return currency.code.toLowerCase().contains(query) ||
            currency.name.toLowerCase().contains(query) ||
            (currency.symbol?.toLowerCase().contains(query) ?? false);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    // If not global update, use passed initialValue, otherwise fallback to provider
    final currentCode = widget.isGlobalUpdate
        ? ref.watch(currencyProvider).code
        : widget.initialValue;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          S.of(context).selectCurrency,
          style: AppTypography.titleMedium.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                hintText: S.of(context).searchCurrencyHint,
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.white.withOpacity(0.8),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: _filteredCurrencies.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final currency = _filteredCurrencies[index];
                final isSelected = currency.code == currentCode;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.1)
                          : AppColors.surfaceVariant,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      currency.symbol ?? r'$',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  title: Text(
                    currency.name,
                    style: isSelected
                        ? AppTypography.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          )
                        : AppTypography.bodyMedium,
                  ),
                  subtitle: Text(currency.code),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: AppColors.primary)
                      : null,
                  onTap: () {
                    // Update global provider ONLY if requested
                    if (widget.isGlobalUpdate) {
                      ref.read(currencyProvider.notifier).setCurrency(currency);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(S.of(context).currencyUpdated)),
                      );
                    }
                    // Return the currency code for callers
                    Navigator.pop(context, currency.code);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
