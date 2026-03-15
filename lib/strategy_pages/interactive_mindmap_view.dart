import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:html_to_pdf_plus/html_to_pdf_plus.dart';
import 'dart:convert';

class InteractiveMindMapView extends StatefulWidget {
  final Map<String, dynamic> mindMapJson;
  final String username;

  const InteractiveMindMapView({
    super.key,
    required this.mindMapJson,
    required this.username,
  });

  @override
  State<InteractiveMindMapView> createState() => _InteractiveMindMapViewState();
}

class _InteractiveMindMapViewState extends State<InteractiveMindMapView> {
  bool _loading = true;
  File? _pdfFile;

  @override
  void initState() {
    super.initState();
    _generatePdf();
  }

  Future<void> _generatePdf() async {
    final html = _htmlTemplate.replaceFirst(
      '{{MINDMAP_HTML}}',
      jsonEncode(widget.mindMapJson),
    );

    final dir = await getApplicationDocumentsDirectory();
    final fileName = '${widget.mindMapJson['content'] ?? 'mindmap'}.pdf';

    final file = await HtmlToPdf.convertFromHtmlContent(
      htmlContent: html,
      configuration: PdfConfiguration(
        targetDirectory: dir.path,
        targetName: fileName.replaceAll('.pdf', ''),
        printSize: PrintSize.A4,
        printOrientation: PrintOrientation.Landscape,
      ),
    );

    setState(() {
      _pdfFile = file;
      _loading = false;
    });
  }

  /// Recursively builds HTML mind map nodes
  String _buildMindMapHtml(Map<String, dynamic> node, [int level = 0]) {
    final content = node['content'] ?? '';
    final children = node['nodes'] ?? [];
    final buffer = StringBuffer();

    buffer.writeln('<div class="node level-$level">$content</div>');

    if (children.isNotEmpty) {
      buffer.writeln('<div class="children level-$level">');
      for (final child in children) {
        buffer.writeln('<div class="edge"></div>');
        buffer.writeln(_buildMindMapHtml(child, level + 1));
      }
      buffer.writeln('</div>');
    }

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mind Map PDF')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _pdfFile != null
          ? SfPdfViewer.file(_pdfFile!)
          : const Center(child: Text('PDF generation failed')),
    );
  }
}

const String _htmlTemplate = r'''
<!DOCTYPE html>
<html dir="rtl" lang="ar">
<head>
<meta charset="utf-8"/>
<title>الخريطة الذهنية</title>
<style>
  html, body {
    margin: 0;
    padding: 0;
    height: 100%;
    background: #f7f9fb;
    font-family: "Cairo", "Segoe UI", sans-serif;
  }

  #map {
    position: relative;
    width: 100%;
    height: 100%;
    overflow: hidden;
  }

  svg {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
  }

  .node {
    position: absolute;
    padding: 8px 12px;
    border-radius: 10px;
    text-align: center;
    white-space: normal;
    word-wrap: break-word;
    background: white;
    border: 2px solid #dbeafe;
    box-shadow: 0 2px 6px rgba(0,0,0,0.08);
    font-weight: 600;
    font-size: 12px;
    line-height: 1.3;
    color: #1e3a8a;
    transform: translate(-50%, -50%);
    max-width: 140px;
    min-width: 80px;
  }

  .node.root {
    background: #2563eb;
    color: white;
    border: 2px solid #1d4ed8;
    font-size: 15px;
    font-weight: bold;
    max-width: 200px;
    min-width: 120px;
    padding: 10px 16px;
  }

  path.link {
    fill: none;
    stroke: #93c5fd;
    stroke-width: 2.5;
    opacity: 0.9;
  }
</style>
</head>
<body>
<div id="map">
  <svg id="links"></svg>
  <div id="nodes"></div>
</div>

<script>
const data = {{MINDMAP_HTML}};

const pageWidth = 1123;  // A4 landscape width in px
const pageHeight = 794;  // A4 landscape height in px
const margin = 60;
const rootWidth = 200; // match .node.root max-width
const centerX = pageWidth / 2;
const centerY = pageHeight / 2;
const svg = document.getElementById("links");
const nodeContainer = document.getElementById("nodes");

function getSubtreeWeight(node) {
  if (!node.nodes || node.nodes.length === 0) return 1;
  return 1 + node.nodes.map(getSubtreeWeight).reduce((a, b) => a + b, 0);
}

function balanceBranches(nodes) {
  const sorted = [...nodes].sort((a, b) => getSubtreeWeight(b) - getSubtreeWeight(a));
  const left = [], right = [];
  let lw = 0, rw = 0;
  for (const n of sorted) {
    const w = getSubtreeWeight(n);
    if (lw <= rw) { left.push(n); lw += w; } else { right.push(n); rw += w; }
  }
  return { left, right };
}

function getSubtreeHeight(node) {
  if (!node.nodes || node.nodes.length === 0) return 1;
  return node.nodes.map(getSubtreeHeight).reduce((a, b) => a + b, 0);
}

function getMaxDepth(node, depth = 0) {
  if (!node.nodes || node.nodes.length === 0) return depth;
  return Math.max(...node.nodes.map(n => getMaxDepth(n, depth + 1)));
}

function calculateSpacing(root) {
  const { left, right } = balanceBranches(root.nodes);
  const maxDepth = Math.max(
    getMaxDepth({ nodes: left }),
    getMaxDepth({ nodes: right })
  );
  const totalHeight = Math.max(
    getSubtreeHeight({ nodes: left }),
    getSubtreeHeight({ nodes: right })
  );

  const availableWidth = (pageWidth - 2 * margin - rootWidth) / 2;
  const availableHeight = pageHeight - 2 * margin;

  const minSpacingX = 120; // minimum horizontal spacing between nodes
  const idealSpacingX = availableWidth / (maxDepth || 1);
  const spacingX = Math.max(minSpacingX, idealSpacingX);

  const spacingY = Math.min(80, availableHeight / (totalHeight || 1));

  return { spacingX, spacingY };
}

function layout(node, x, y, side = 1, level = 1, spacing) {
  const { spacingX, spacingY } = spacing;
  let offsetY = y - (getSubtreeHeight(node) - 1) * spacingY / 2;

  node.nodes.forEach((child) => {
    const h = getSubtreeHeight(child);
    const childY = offsetY + (h - 1) * spacingY / 2;
    const childX = x + side * spacingX;
    createLink(x, y, childX, childY);
    createNode(child, childX, childY, level);
    layout(child, childX, childY, side, level + 1, spacing);
    offsetY += h * spacingY;
  });
}

function createNode(node, x, y, level) {
  const div = document.createElement("div");
  div.className = "node" + (level === 0 ? " root" : "");
  div.textContent = node.content;
  div.style.left = x + "px";
  div.style.top = y + "px";
  nodeContainer.appendChild(div);
}

function createLink(x1, y1, x2, y2) {
  const path = document.createElementNS("http://www.w3.org/2000/svg", "path");
  const cx1 = x1 - (x1 - x2) * 0.4;
  const cx2 = x2 + (x1 - x2) * 0.4;
  const d = `M ${x1},${y1} C ${cx1},${y1} ${cx2},${y2} ${x2},${y2}`;
  path.setAttribute("d", d);
  path.classList.add("link");
  svg.appendChild(path);
}

// --- Main Execution ---
const spacing = calculateSpacing(data);
const { left, right } = balanceBranches(data.nodes);

// Draw root node once
createNode(data, centerX, centerY, 0);

// Layout left and right subtrees symmetrically
layout({ nodes: left }, centerX, centerY, -1, 1, spacing);
layout({ nodes: right }, centerX, centerY, 1, 1, spacing);
</script>
</body>
</html>
''';
