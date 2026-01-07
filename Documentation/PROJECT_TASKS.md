# Project Tasks & MCP Compliance

## MCP Verifications
- [x] **2025-12-28**: Search `sealed_currencies` on pub.dev via MCP. Found version 2.5.0. It provides currency data as sealed classes.
- [ ] **Next**: Run `flutter analyze` before closing Phase 1.

## Active- [x] Phase 2: Integrate Selected Currency
    - [x] Update `Formatters` to use `CurrencyProvider`.
    - [x] Refactor `PdfGeneratorService` to accept dynamic currency symbol.
    - [x] Update `MoneyDisplay` widget.
    - [x] Update `LoanEditScreen`, `LoanFormScreen` and `LoanDetailScreen`.
    - [x] Update `PaymentFormScreen` and `ReportsScreen`.
    - [x] Verify `WhatsAppService` integration.

## Pattern / Best Practices
- **UI**: Use existing design system (Theme.of(context)). no hardcoded colors.
- **State**: Riverpod for state management.
- **I18n**: Strings in `LocaleProvider`.
- **Architecture**: Clean Architecture (Screen -> Provider -> Service/Repository).
