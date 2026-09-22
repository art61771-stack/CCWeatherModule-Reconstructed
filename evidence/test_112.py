#!/usr/bin/env python3
"""Runs production C core, real temporary files, and ObjC integration contracts.
No Apple SDK / UIKit / ImageIO / AVFoundation runtime is available here.
"""
import pathlib, tempfile, subprocess, unittest, plistlib, base64, os
from urllib.parse import quote, unquote, urlsplit
from test_111 import Regression111, method
ROOT=pathlib.Path(__file__).resolve().parents[1]
C=(ROOT/'src/WCCContentViewController.m').read_text()
G=(ROOT/'src/WCCGallery.m').read_text()
P=(ROOT/'src/WCCPreferences.m').read_text()
class Regression112(Regression111):
    def test_runtime_metadata(self):
        info=plistlib.loads((ROOT/'Resources/Info.plist').read_bytes())
        self.assertEqual(info['CFBundleShortVersionString'],'1.1.2')
        self.assertEqual(info['CFBundleVersion'],'112')
        self.assertTrue(info['CCSGetModuleSizeAtRuntime'])
        self.assertIn('Version: 1.1.2',(ROOT/'control').read_text())
    def test_objc_integration(self):
        self.assertIn('WCCValidateFile(',P)
        self.assertIn('WCCComputeGeometry(size.width, size.height, _isExpanded)',C)
        self.assertIn('self.customMedia.frame = _iconView.bounds',C)
        self.assertNotIn('constraintEqualToConstant:55',C)
        self.assertIn('NSTimeZone.localTimeZone',C)
        self.assertIn('if (self.greetingSession) return',C)
        self.assertIn('self.greetingSession = NO',method(C,'- (void)controlCenterDidDismiss'))
        for selector in ['- (void)viewWillLayoutSubviews','- (void)updateWeatherDisplay','- (void)preferencesChanged']:
            self.assertNotIn('beginGreetingSession',method(C,selector))
        self.assertIn('error:&directoryError',G)
        self.assertIn('WCCCheckedPath(WCCRoot(), name, &reason)',G)
        self.assertIn('img-src data:',G)
        self.assertIn('loadHTMLString:html baseURL:nil',G)
        self.assertIn('wcc-select://item/%lu',G)
        self.assertIn('didFailProvisionalNavigation',G)
    def test_dynamic_html_and_weather_fields(self):
        for token in ['media-src data:', 'allowsInlineMediaPlayback = YES', 'WKAudiovisualMediaTypeNone', 'video/mp4', 'image/gif', '<video autoplay muted loop playsinline', 'if (video || gif) data = [NSData dataWithContentsOfFile:path', 'if (previewBytes + data.length > 8*1024*1024) data = nil']:
            self.assertIn(token,G)
        self.assertNotIn('break;',method(G,'- (void)reload'))
        self.assertIn('_precipLabel.hidden = !g.details; _highLowLabel.hidden = !g.details;',C)
        self.assertIn('_precipLabel.frame = WCCCGRect(g.precipitation)',C)
        self.assertIn('_highLowLabel.frame = WCCCGRect(g.highLow)',C)
    def test_production_core_and_real_directory(self):
        with tempfile.TemporaryDirectory(prefix='wcc112-') as tmp:
            root=pathlib.Path(tmp); binary=root/'runtime'
            subprocess.run(['cc','-std=c11','-D_XOPEN_SOURCE=700','-Wall','-Wextra','-Werror',str(ROOT/'evidence/runtime112.c'),'-lm','-o',str(binary)],check=True)
            subprocess.run([str(binary)],check=True)
            icons=root/'图 标 #100%?&'/'Icons'; icons.mkdir(parents=True)
            import struct, zlib
            def chunk(kind,data):
                return struct.pack('>I',len(data))+kind+data+struct.pack('>I',zlib.crc32(kind+data))
            png=b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',1,1,8,2,0,0,0))+chunk(b'IDAT',zlib.compress(b'\x00\x00\x00\xff'))+chunk(b'IEND',b'')
            gif=base64.b64decode('R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw==')
            (icons/'晴 天#100%?&.PNG').write_bytes(png)
            (icons/'动图.GIF').write_bytes(gif)
            # A real 0.2s MP4, not an extension-only placeholder.
            raw=root/'frames.rgb'; raw.write_bytes(bytes([0,0,255])*16*16*2)
            subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-f','rawvideo','-pixel_format','rgb24','-video_size','16x16','-framerate','10','-i',str(raw),'-c:v','mpeg4',str(icons/'视频.MP4')],check=True)
            for asset in ['晴 天#100%?&.PNG','动图.GIF','视频.MP4']:
                options=['-pattern_type','none'] if asset.endswith('.PNG') else []
                subprocess.run(['ffmpeg','-hide_banner','-loglevel','error',*options,'-i',str(icons/asset),'-frames:v','1','-f','null','-'],check=True)
            (icons/'空.png').touch(); (icons/'note.txt').write_text('not media')
            (icons/'folder.png').mkdir()
            with (icons/'large.png').open('wb') as f: f.truncate(8*1024*1024+1)
            (icons/'broken.gif').symlink_to(icons/'missing')
            outside=root/'outside.png'; outside.write_bytes(png)
            (icons/'escape.png').symlink_to(outside)
            (icons/'alias.png').symlink_to(icons/'晴 天#100%?&.PNG')
            before={p.name:p.lstat().st_size for p in icons.iterdir()}
            rows=subprocess.check_output([str(binary),str(icons)],text=True).splitlines()
            results={name:int(code) for name,code in (row.rsplit('\t',1) for row in rows)}
            self.assertEqual(results,{'晴 天#100%?&.PNG':0,'动图.GIF':0,'视频.MP4':0,'空.png':7,'note.txt':4,'folder.png':6,'large.png':8,'broken.gif':5,'escape.png':3,'alias.png':0})
            for name,code in [('../outside.png',1),('.',1),('missing.png',5)]:
                self.assertEqual(int(subprocess.check_output([str(binary),str(icons),name])),code)
            alias=root/'root-alias'; alias.symlink_to(icons,target_is_directory=True)
            self.assertEqual(int(subprocess.check_output([str(binary),str(alias),'动图.GIF'])),0)
            self.assertEqual(before,{p.name:p.lstat().st_size for p in icons.iterdir()})
            for name in results:
                url=urlsplit('filza://view'+quote(str(icons/name),safe='/'))
                self.assertFalse(url.query or url.fragment)
                self.assertEqual(unquote(url.path),str(icons/name))
if __name__=='__main__':
    # Avoid running the imported historic 1.1.1 metadata expectation.
    unittest.main(defaultTest='Regression112',verbosity=2)
