import 'package:flutter/material.dart';

class InteractiveComparisonView extends StatelessWidget {
  final Map<String, dynamic> comparisonJson;
  final String username;

  const InteractiveComparisonView({
    super.key,
    required this.comparisonJson,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    final title = (comparisonJson['title'] ?? 'جدول المقارنة').toString();
    final normalized = _normalizeTable(comparisonJson);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          centerTitle: true,
        ),
        body: normalized.options.isEmpty || normalized.rows.isEmpty
            ? const Center(child: Text('لا توجد بيانات مقارنة لعرضها'))
            : LayoutBuilder(
                builder: (context, constraints) {
                  final tableMinWidth = (normalized.options.length + 1) * 180.0;
                  final width = tableMinWidth < constraints.maxWidth
                      ? constraints.maxWidth
                      : tableMinWidth;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: width,
                        child: Card(
                          clipBehavior: Clip.antiAlias,
                          child: DataTable(
                            headingRowHeight: 60,
                            dataRowMinHeight: 76,
                            dataRowMaxHeight: 132,
                            columnSpacing: 14,
                            horizontalMargin: 14,
                            headingRowColor: MaterialStateProperty.all(
                              Theme.of(context)
                                  .colorScheme
                                  .primaryContainer
                                  .withOpacity(0.92),
                            ),
                            columns: [
                              const DataColumn(
                                label: Text(
                                  'المعيار',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ),
                              for (final option in normalized.options)
                                DataColumn(
                                  label: Text(
                                    option,
                                    style: const TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                ),
                            ],
                            rows: [
                              for (var rowIndex = 0;
                                  rowIndex < normalized.rows.length;
                                  rowIndex++)
                                _buildRow(
                                  context: context,
                                  rowIndex: rowIndex,
                                  row: normalized.rows[rowIndex],
                                  options: normalized.options,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  DataRow _buildRow({
    required BuildContext context,
    required int rowIndex,
    required _ComparisonRow row,
    required List<String> options,
  }) {
    final stripe = _rowStripe(rowIndex);
    final criterionBg = stripe.withOpacity(0.30);
    final defaultBg = Theme.of(context).colorScheme.surface;

    return DataRow(
      cells: [
        DataCell(
          Container(
            constraints: const BoxConstraints(minWidth: 170),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: criterionBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              row.criterion,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
        for (var col = 0; col < options.length; col++)
          DataCell(
            Container(
              constraints: const BoxConstraints(minWidth: 170),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: col.isEven ? defaultBg : stripe.withOpacity(0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                row.values[options[col]]?.toString() ?? '-',
              ),
            ),
          ),
      ],
    );
  }

  _ComparisonTable _normalizeTable(Map<String, dynamic> json) {
    final rawTable = json['comparisonTable'];
    if (rawTable is! List) {
      return const _ComparisonTable(options: [], rows: []);
    }

    final options = <String>{};
    final rows = <_ComparisonRow>[];

    for (final item in rawTable) {
      if (item is! Map) continue;
      final mapped = Map<String, dynamic>.from(item);
      if (mapped.isEmpty) continue;

      final criterion = mapped.keys.first.toString();
      final valuesRaw = mapped.values.first;
      if (valuesRaw is! Map) continue;
      final values = Map<String, dynamic>.from(valuesRaw);
      options.addAll(values.keys.map((e) => e.toString()));
      rows.add(_ComparisonRow(criterion: criterion, values: values));
    }

    return _ComparisonTable(
      options: options.toList(),
      rows: rows,
    );
  }

  Color _rowStripe(int rowIndex) {
    const palette = <Color>[
      Color(0xFF22C55E),
      Color(0xFF0EA5E9),
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
      Color(0xFF8B5CF6),
      Color(0xFF14B8A6),
    ];
    return palette[rowIndex % palette.length];
  }
}

class _ComparisonTable {
  final List<String> options;
  final List<_ComparisonRow> rows;

  const _ComparisonTable({
    required this.options,
    required this.rows,
  });
}

class _ComparisonRow {
  final String criterion;
  final Map<String, dynamic> values;

  const _ComparisonRow({
    required this.criterion,
    required this.values,
  });
}
