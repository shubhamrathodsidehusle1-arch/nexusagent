/// NexusAgent Browser Control
/// Uses Playwright for browser automation (replaces OpenClaw's browser tool)

import 'dart:async';
import 'dart:convert';
import 'dart:io';

class BrowserConfig {
  final String browserType; // chromium, firefox, webkit
  final bool headless;
  final int viewportWidth;
  final int viewportHeight;
  final String? userDataDir; // For persistent sessions

  BrowserConfig({
    this.browserType = 'chromium',
    this.headless = true,
    this.viewportWidth = 1280,
    this.viewportHeight = 720,
    this.userDataDir,
  });
}

class BrowserResult {
  final bool success;
  final String? output;
  final String? error;
  final Map<String, dynamic>? metadata;

  BrowserResult({
    required this.success,
    this.output,
    this.error,
    this.metadata,
  });
}

class BrowserPage {
  final String pageId;
  final String url;
  final String title;

  BrowserPage({
    required this.pageId,
    required this.url,
    required this.title,
  });
}

class BrowserController {
  static final BrowserController _instance = BrowserController._internal();
  factory BrowserController() => _instance;
  BrowserController._internal();

  BrowserConfig _config = BrowserConfig();
  bool _initialized = false;
  String? _activePageId;

  /// Initialize browser
  Future<bool> initialize(BrowserConfig config) async {
    _config = config;
    
    try {
      // Check if Playwright is installed
      final result = await Process.run('which', ['playwright']);
      if (result.exitCode != 0) {
        print('Playwright not found. Installing...');
        await _installPlaywright();
      }
      
      _initialized = true;
      print('Browser controller initialized (${config.browserType})');
      return true;
    } catch (e) {
      print('Browser init failed: $e');
      return false;
    }
  }

  Future<void> _installPlaywright() async {
    // Install Playwright and browsers
    await Process.run('npm', ['install', '-g', 'playwright']);
    await Process.run('playwright', ['install', _config.browserType]);
  }

  /// Navigate to URL
  Future<BrowserResult> navigate(String url, {bool waitUntil = true}) async {
    if (!_initialized) {
      return BrowserResult(success: false, error: 'Browser not initialized');
    }

    try {
      final script = '''
const { chromium } = require('playwright');
(async () => {
  const browser = await chromium.launch({ headless: ${_config.headless} });
  const page = await browser.newPage({
    viewport: { width: ${_config.viewportWidth}, height: ${_config.viewportHeight} }
  });
  await page.goto('${url}'${waitUntil ? ", { waitUntil: 'networkidle' }" : ""});
  const title = await page.title();
  console.log(JSON.stringify({ success: true, url: page.url(), title }));
  await browser.close();
})();
''';

      final result = await _runPlaywrightScript(script);
      return BrowserResult(
        success: true,
        output: result['title'],
        metadata: {'url': result['url'], 'title': result['title']},
      );
    } catch (e) {
      return BrowserResult(success: false, error: e.toString());
    }
  }

  /// Take screenshot
  Future<BrowserResult> screenshot({String? path}) async {
    if (!_initialized) {
      return BrowserResult(success: false, error: 'Browser not initialized');
    }

    final screenshotPath = path ?? '/tmp/nexusagent_${DateTime.now().millisecondsSinceEpoch}.png';

    try {
      final script = '''
const { chromium } = require('playwright');
(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  ${_activePageId != null ? '// Reuse session' : ''}
  await page.screenshot({ path: '${screenshotPath}', fullPage: true });
  console.log(JSON.stringify({ success: true, path: '${screenshotPath}' }));
  await browser.close();
})();
''';

      final result = await _runPlaywrightScript(script);
      return BrowserResult(
        success: true,
        output: screenshotPath,
        metadata: {'path': screenshotPath},
      );
    } catch (e) {
      return BrowserResult(success: false, error: e.toString());
    }
  }

  /// Click element
  Future<BrowserResult> click(String selector) async {
    if (!_initialized) {
      return BrowserResult(success: false, error: 'Browser not initialized');
    }

    try {
      final script = '''
const { chromium } = require('playwright');
(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  await page.click('${selector}');
  console.log(JSON.stringify({ success: true }));
  await browser.close();
})();
''';

      final result = await _runPlaywrightScript(script);
      return BrowserResult(success: result['success'] ?? false);
    } catch (e) {
      return BrowserResult(success: false, error: e.toString());
    }
  }

  /// Type text
  Future<BrowserResult> type(String selector, String text) async {
    if (!_initialized) {
      return BrowserResult(success: false, error: 'Browser not initialized');
    }

    try {
      final escapedText = text.replaceAll("'", "\\'");
      final script = '''
const { chromium } = require('playwright');
(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  await page.fill('${selector}', '${escapedText}');
  console.log(JSON.stringify({ success: true }));
  await browser.close();
})();
''';

      final result = await _runPlaywrightScript(script);
      return BrowserResult(success: result['success'] ?? false);
    } catch (e) {
      return BrowserResult(success: false, error: e.toString());
    }
  }

  /// Get page content
  Future<BrowserResult> getContent() async {
    if (!_initialized) {
      return BrowserResult(success: false, error: 'Browser not initialized');
    }

    try {
      final script = '''
const { chromium } = require('playwright');
(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  const content = await page.content();
  console.log(JSON.stringify({ success: true, content: content.substring(0, 10000) }));
  await browser.close();
})();
''';

      final result = await _runPlaywrightScript(script);
      return BrowserResult(
        success: true,
        output: result['content'],
      );
    } catch (e) {
      return BrowserResult(success: false, error: e.toString());
    }
  }

  /// Evaluate JavaScript
  Future<BrowserResult> evaluate(String jsCode) async {
    if (!_initialized) {
      return BrowserResult(success: false, error: 'Browser not initialized');
    }

    try {
      final escapedCode = jsCode.replaceAll("'", "\\'");
      final script = '''
const { chromium } = require('playwright');
(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  const result = await page.evaluate('${escapedCode}');
  console.log(JSON.stringify({ success: true, result: String(result) }));
  await browser.close();
})();
''';

      final result = await _runPlaywrightScript(script);
      return BrowserResult(
        success: true,
        output: result['result'],
      );
    } catch (e) {
      return BrowserResult(success: false, error: e.toString());
    }
  }

  /// Wait for selector
  Future<BrowserResult> waitFor(String selector, {int timeout = 30000}) async {
    if (!_initialized) {
      return BrowserResult(success: false, error: 'Browser not initialized');
    }

    try {
      final script = '''
const { chromium } = require('playwright');
(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  await page.waitForSelector('${selector}', { timeout: ${timeout} });
  console.log(JSON.stringify({ success: true }));
  await browser.close();
})();
''';

      final result = await _runPlaywrightScript(script);
      return BrowserResult(success: result['success'] ?? false);
    } catch (e) {
      return BrowserResult(success: false, error: e.toString());
    }
  }

  /// Close browser
  Future<void> close() async {
    _initialized = false;
    _activePageId = null;
    print('Browser closed');
  }

  /// Run Playwright script
  Future<Map<String, dynamic>> _runPlaywrightScript(String script) async {
    final tempFile = '/tmp/nexusagent_browser_${DateTime.now().millisecondsSinceEpoch}.js';
    await File(tempFile).writeAsString(script);

    try {
      final result = await Process.run('node', [tempFile]);
      await File(tempFile).delete();
      
      final output = result.stdout.toString().trim();
      if (output.isEmpty) {
        return {'success': false, 'error': 'No output'};
      }
      
      return jsonDecode(output) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
