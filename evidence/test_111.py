#!/usr/bin/env python3
"""Source-contract regression only; not an Apple SDK or device test."""
import pathlib
import plistlib
import re
import unittest
from urllib.parse import quote, urlsplit, unquote

ROOT = pathlib.Path(__file__).resolve().parents[1]
P = (ROOT / 'src/WCCPreferences.m').read_text()
M = (ROOT / 'src/WCCModule.m').read_text()
S = (ROOT / 'src/WCCSettings.m').read_text()
H = (ROOT / 'src/WCCSettings.h').read_text()
C = (ROOT / 'src/WCCContentViewController.m').read_text()

def method(source, name):
    start = source.index(name)
    brace = source.index('{', start)
    depth = 1
    end = brace + 1
    while depth:
        depth += (source[end] == '{') - (source[end] == '}')
        end += 1
    return source[brace:end]

class Regression111(unittest.TestCase):
    def test_exact_five_sizes(self):
        values = re.findall(r'@"(\dx\d)"', method(P, 'WCCSizeOptions(void)'))
        self.assertEqual(values, ['2x1', '3x1', '4x1', '2x2', '3x3'])
        self.assertIn('for (NSString *size in WCCSizeOptions())', S)
        self.assertEqual([tuple(map(int, x.split('x'))) for x in values],
                         [(2, 1), (3, 1), (4, 1), (2, 2), (3, 3)])

    def test_persistence_validation(self):
        body = method(P, 'WCCSetSelectedSize(NSString *size)')
        self.assertIn('![WCCSizeOptions() containsObject:size]', body)
        for key in ['moduleSize', 'columns', 'rows']:
            self.assertIn('forKey:@"' + key + '"', body)
        self.assertIn('synchronize', body)

    def test_legacy_and_invalid(self):
        body = method(P, 'WCCSelectedSize(void)')
        self.assertIn('isKindOfClass:NSString.class', body)
        self.assertIn('[WCCSizeOptions() containsObject:size]', body)
        self.assertIn('isKindOfClass:NSNumber.class', body)
        self.assertIn('[@[@2, @3, @4] containsObject:old]', body)
        self.assertIn('@"%ldx1"', body)
        self.assertIn('return @"4x1"', body)

    def test_default_off_and_both_axes(self):
        body = method(P, 'WCCEffectiveSize(void)')
        self.assertIn('if (![WCCPrefs() boolForKey:@"customSize"]) return (WCCLayoutSize){4, 1}', body)
        self.assertIn('{[parts[0] integerValue], [parts[1] integerValue]}', body)
        self.assertNotIn('setBool:YES forKey:@"customSize"', P + S)

    def test_ccsupport_snapshot(self):
        body = method(M, 'moduleSizeForOrientation:(int)orientation')
        self.assertIn('static WCCLayoutSize size', body)
        self.assertIn('dispatch_once(&once, ^{ size = WCCEffectiveSize(); })', body)
        self.assertIn('return size;', body)
        self.assertNotIn('{columns, 1}', M)
        h = (ROOT / 'src/WCCPreferences.h').read_text()
        self.assertIn('NSUInteger width; NSUInteger height;', h)
        self.assertIn('手动注销 SpringBoard', S)
        self.assertNotIn('killall', S)

    def test_runtime_metadata(self):
        info = plistlib.loads((ROOT / 'Resources/Info.plist').read_bytes())
        self.assertTrue(info['CCSGetModuleSizeAtRuntime'])
        for key in ['CCSModuleSize', 'ModuleSize']:
            for orientation in ['Portrait', 'Landscape']:
                self.assertEqual(info[key][orientation], {'Width': 4, 'Height': 1})
        self.assertEqual(info['CFBundleShortVersionString'], '1.1.1')
        self.assertEqual(info['CFBundleVersion'], '111')
        self.assertIn('Version: 1.1.1', (ROOT / 'control').read_text())

    def test_gesture_separation(self):
        self.assertIn('tap.numberOfTapsRequired = 2; tap.numberOfTouchesRequired = 1;', C)
        self.assertIn('settingsTap.numberOfTapsRequired = 2; settingsTap.numberOfTouchesRequired = 2;', C)
        self.assertIn('[tap requireGestureRecognizerToFail:settingsTap]', C)
        one = method(C, '- (void)handleDoubleTap:')
        two = method(C, '- (void)handleTwoFingerDoubleTap:')
        self.assertIn('_displayMode = _displayMode == 0 ? 1 : 0;', one)
        self.assertIn('[self updateCityLabel]', one)
        self.assertNotIn('WCCSettings', one)
        self.assertIn('[WCCSettings presentFrom:self completion:', two)
        self.assertIn('presentedViewController', one)
        self.assertIn('presentedViewController', two)

    def test_settings_declarations_and_style(self):
        self.assertIn('WCCSettings : NSObject', H)
        for selector in ['presentFrom:', 'editLandmarkFrom:']:
            self.assertIn(selector, H)
            self.assertIn(selector, S)
        self.assertIn('preferredStyle:UIAlertControllerStyleAlert', S)
        self.assertNotIn('UITableViewStyleInsetGrouped', S)
        self.assertNotIn('UIModalPresentationFullScreen', S)
        self.assertIn('return UIModalPresentationNone;', S)
        self.assertIn('pop.permittedArrowDirections = 0', S)

    def test_all_settings_retained(self):
        for text in ['customIcon', 'customSize', 'displayMode', 'landmark',
                     '浏览 HTML 动态图库', '用 Filza 打开素材目录', '复制路径']:
            self.assertIn(text, S)
        self.assertIn('name.length ? 2 : 0', S)
        self.assertIn('name.length > 80', S)
        self.assertIn('UIBarButtonSystemItemDone', S)
        self.assertIn('WCCPreferencesChanged', S)

    def test_filza_launch_and_failure(self):
        body = method(S, '+ (void)openFilzaFrom:')
        self.assertLess(body.index('createDirectoryAtPath:'), body.index('NSURL *url'))
        self.assertIn('withIntermediateDirectories:YES attributes:nil error:&error', body)
        self.assertIn('openURL:withCompletionHandler:', body)
        self.assertIn('respondsToSelector:springOpen', body)
        self.assertIn('completionHandler:finish', body)
        self.assertIn('finish(NO)', body)
        self.assertIn('UIPasteboard.generalPasteboard.string = path', S)
        self.assertIn('if (finished) return; finished = YES;', body)

    def test_url_encoding_contract(self):
        chars = re.search(r'characterSetWithCharactersInString:@"([^"]+)"', S)[1]
        self.assertFalse(any(x in chars for x in ' #%?#&'))
        for path in ['/var/mobile/Documents/CCWeatherModule/Icons',
                     '/var/mobile/Documents/图 标/#100%?&/Icons']:
            url = urlsplit('filza://view' + quote(path, safe=chars))
            self.assertEqual(url.scheme, 'filza')
            self.assertEqual(url.netloc, 'view')
            self.assertFalse(url.query or url.fragment)
            self.assertEqual(unquote(url.path), path)

if __name__ == '__main__':
    unittest.main(verbosity=2)
