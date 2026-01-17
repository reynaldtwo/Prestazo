import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prestamos_app/data/models/business_financial_policy.dart';
import 'package:prestamos_app/data/providers/database_providers.dart';

/// Provee la política financiera activa actualmente.
final activePolicyProvider = FutureProvider<BusinessFinancialPolicy>((
  ref,
) async {
  final repo = ref.watch(businessPolicyRepositoryProvider);
  return repo.getActivePolicy();
});
