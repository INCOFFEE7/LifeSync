import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lifesync_app/presentation/widgets/custom_numeric_keypad.dart';

Future<double?> showCalculatorInputDialog({
  required BuildContext context,
  required String title,
  double initialValue = 0.0,
}) {
  return showModalBottomSheet<double>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _CalculatorDialogContent(title: title, initialValue: initialValue),
  );
}

class _CalculatorDialogContent extends StatefulWidget {
  final String title;
  final double initialValue;

  const _CalculatorDialogContent({required this.title, required this.initialValue});

  @override
  State<_CalculatorDialogContent> createState() => _CalculatorDialogContentState();
}

class _CalculatorDialogContentState extends State<_CalculatorDialogContent> {
  late String calcExpr;
  late bool _isInitialValue;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue > 0) {
      calcExpr = widget.initialValue.toInt().toString();
      _isInitialValue = true;
    } else {
      calcExpr = '0';
      _isInitialValue = false;
    }
  }

  double _evaluateExpr(String expr) {
    try {
      String sanitized = expr.replaceAll('×', '*').replaceAll('÷', '/').replaceAll(' ', '');
      if (sanitized.isEmpty) return 0.0;

      List<String> tokens = [];
      String currentNum = '';

      for (int i = 0; i < sanitized.length; i++) {
        String char = sanitized[i];
        if (char == '+' || char == '×' || char == '*' || char == '÷' || char == '/') {
          if (currentNum.isNotEmpty) {
            tokens.add(currentNum);
            currentNum = '';
          }
          tokens.add(char);
        } else if (char == '-') {
          if (currentNum.isEmpty && (tokens.isEmpty || tokens.last == '+' || tokens.last == '-' || tokens.last == '*' || tokens.last == '/')) {
            currentNum += char;
          } else {
            if (currentNum.isNotEmpty) {
              tokens.add(currentNum);
              currentNum = '';
            }
            tokens.add('-');
          }
        } else {
          currentNum += char;
        }
      }
      if (currentNum.isNotEmpty) {
        tokens.add(currentNum);
      }

      if (tokens.isEmpty) return 0.0;
      if (tokens.length == 1) return double.tryParse(tokens[0]) ?? 0.0;

      for (int i = 1; i < tokens.length - 1; i += 2) {
        if (tokens[i] == '*' || tokens[i] == '/') {
          double left = double.parse(tokens[i - 1]);
          double right = double.parse(tokens[i + 1]);
          double res = tokens[i] == '*' ? (left * right) : (right == 0 ? 0 : left / right);
          tokens[i - 1] = res.toString();
          tokens.removeAt(i);
          tokens.removeAt(i);
          i -= 2;
        }
      }

      double total = double.parse(tokens[0]);
      for (int i = 1; i < tokens.length - 1; i += 2) {
        String op = tokens[i];
        double nextNum = double.parse(tokens[i + 1]);
        if (op == '+') total += nextNum;
        else if (op == '-') total -= nextNum;
      }
      return total;
    } catch (_) {
      // If trailing operator like '50000-', parse left portion instead of collapsing to entire stripped digits
      final match = RegExp(r'^-?\d+(\.\d+)?').firstMatch(expr.trim());
      if (match != null) {
        return double.tryParse(match.group(0)!) ?? 0.0;
      }
      return 0.0;
    }
  }

  bool _hasOperator(String expr) {
    return expr.contains('+') || expr.contains('-') || expr.contains('×') || expr.contains('÷');
  }

  String _formatCurrency(double val) {
    final fmt = NumberFormat('#,###', 'id_ID');
    if (val == 0) return 'Rp 0';
    if (val < 0) return '-Rp ${fmt.format(val.abs().toInt())}';
    return 'Rp ${fmt.format(val.toInt())}';
  }

  void _onKeyPress(String k) {
    setState(() {
      if (k == 'C') {
        calcExpr = '0';
        _isInitialValue = false;
        return;
      }

      final isOp = (String c) => c == '+' || c == '-' || c == '×' || c == '÷';

      if (_isInitialValue) {
        _isInitialValue = false;
        if (!isOp(k) && k != '.') {
          // Ketik angka pertama langsung menggantikan nilai default!
          calcExpr = k;
          return;
        }
      }

      if (calcExpr == '0' && !isOp(k) && k != '.') {
        calcExpr = k;
        return;
      }

      final last = calcExpr[calcExpr.length - 1];
      if ((isOp(k) || k == '.') && (isOp(last) || last == '.')) {
        calcExpr = calcExpr.substring(0, calcExpr.length - 1) + k;
        return;
      }
      if (calcExpr.length < 24) calcExpr += k;
    });
  }

  void _onDelete() {
    setState(() {
      if (_isInitialValue) {
        _isInitialValue = false;
        calcExpr = '0';
        return;
      }

      if (calcExpr.length > 1) {
        calcExpr = calcExpr.substring(0, calcExpr.length - 1);
      } else {
        calcExpr = '0';
      }
    });
  }

  void _onEquals() {
    setState(() {
      _isInitialValue = false;
      calcExpr = _evaluateExpr(calcExpr).toInt().toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final evaluated = _evaluateExpr(calcExpr);
    final formattedAmt = _formatCurrency(evaluated);
    final showExpr = _hasOperator(calcExpr);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 20,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                  widget.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2563EB), width: 1.5),
              ),
              child: Column(
                children: [
                  Text('NOMINAL KALKULATOR', style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  if (showExpr) ...[
                    Text(
                      calcExpr,
                      style: TextStyle(fontSize: 14, color: isDark ? Colors.white54 : const Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(formattedAmt, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                ],
              ),
            ),
            const SizedBox(height: 12),
            CustomNumericKeypad(
              onKeyPress: _onKeyPress,
              onDelete: _onDelete,
              onEquals: _onEquals,
              onClose: () => Navigator.pop(context, evaluated),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context, evaluated),
              child: const Text('Gunakan Nominal Ini', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
