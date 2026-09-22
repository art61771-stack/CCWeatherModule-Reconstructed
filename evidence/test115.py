from pathlib import Path
import re,subprocess,html
p=Path(__file__).resolve().parents[1]
c=(p/'src/WCCContentViewController.m').read_text()
# Archived original 1.0.4 reconstruction; provenance in original104-SOURCE.md.
o=(p/'evidence/original104-WCCContentViewController.m').read_text()
r=(p/'src/WCCHostObserver.m').read_text()
def method(s,name):
 a=s.index('- (void)'+name);b=s.find('\n- (',a+1);return s[a:b if b!=-1 else len(s)]
assert method(c,'setupHourlyContainer')==method(o,'setupHourlyContainer')
assert c[c.index('- (void)updateHourlyForecast'):]==o[o.index('- (void)updateHourlyForecast'):]
old=method(o,'setupHeaderView')
new=method(c,'layoutOriginalExpanded:')
assert re.findall(r'\[_\w+\.\w+Anchor constraint[^\n]+',old)==re.findall(r'\[_\w+\.\w+Anchor constraint[^\n]+',new)
assert 'CGRectMake(0,0,size.width,85)' in new and 'CGRectMake(0,85,size.width,size.height-85)' in new
assert 'self.greetingLabel.hidden=YES' in new
assert 'drawGreeting' not in method(c,'controlCenterWillPresent')
assert 'drawGreeting' not in method(c,'viewWillLayoutSubviews')
assert 'WCCConsumeExpansion' in method(c,'willTransitionToExpandedContentMode:')
assert 'WCCConsumeModuleHost' in method(c,'consumeHostSession')
assert 'WCCConsumeHostEvent' in r and 'method_getTypeEncoding' in r
assert 'class_addMethod' in r and 'class_getInstanceMethod' in r
for bad in ['dispatch_source','NSTimer','%hook UIViewController','MSHookMessageEx','addObserver:forKeyPath:']:
 assert bad not in r
assert 'src/WCCHostObserver.m' in (p/'Makefile').read_text()
# Native/media/gesture protection (114's obsolete event/alignment assertions intentionally superseded).
for token in ['numberOfTouchesRequired = 1','numberOfTouchesRequired = 2','WCCMappedName(key)']:
 assert token in c
for name in ['WCCGallery.m','WCCMedia.m','WCCSettings.m']:
 assert 'WKWebView' not in (p/'src'/name).read_text()
print('PASS: original 1.0.4 expanded anchor list + hourly container + hourly item implementation identical; event adapter wired; no broad hook/timer; module callback does not force a draw; gestures/native media preserved.')
rows=subprocess.check_output(['/tmp/runtime115','geometry'],text=True).splitlines()
svg=['<svg xmlns="http://www.w3.org/2000/svg" width="820" height="780" viewBox="0 0 820 780"><style>text{font-family:Arial,sans-serif;fill:white}.cap{font-size:14px;fill:#bbb}</style><rect width="820" height="780" fill="#101725"/><text x="24" y="28" font-size="20">115 · production geometry / NOT an iOS screenshot</text>']
labels=['☁','晋安区','33°','局部多云','33° / 24°','降水概率: 20%','下午好，给自己一点放松']
for i,line in enumerate(rows):
 vals=list(map(float,line.split()));cols,rs,w,h,cf,tf,df,gf=vals[:8];rects=[vals[j:j+4] for j in range(8,len(vals),4)]
 x=24 if i<3 else 425;y=65+i*125 if i<3 else 65+(i-3)*205
 svg.append(f'<text class="cap" x="{x}" y="{y-10}">{int(cols)}×{int(rs)} collapsed / actual production rectangles</text><g transform="translate({x},{y})"><rect width="{w}" height="{h}" rx="20" fill="#304157"/>')
 for j,(rx,ry,rw,rh) in enumerate(rects):
  if rw<=0 or rh<=0:continue
  font=[24,cf,tf,df,df,df,gf][j];right=(cols in (2,4) and rs==1 and j in (1,3,5,6));anchor='end' if right else 'start';tx=rx+rw if right else rx
  svg.append(f'<rect x="{rx}" y="{ry}" width="{rw}" height="{rh}" fill="none" stroke="#7190a6" stroke-width=".4"/><text x="{tx}" y="{ry+rh*.82}" text-anchor="{anchor}" font-size="{font}">{html.escape(labels[j])}</text>')
 svg.append('</g>')
svg+=['<text class="cap" x="24" y="478">Expanded: restored original anchors; 85pt header, 180pt total; no greeting row</text>', '<g transform="translate(24,495)"><rect width="360" height="180" rx="22" fill="#304157"/><text x="16" y="56" font-size="42">☁</text><text x="89" y="32" font-size="18">晋安区</text><text x="89" y="50" font-size="13">局部多云</text><text x="89" y="66" font-size="12">降水概率: 20%</text><text x="344" y="49" text-anchor="end" font-size="38">33°</text><text x="344" y="66" text-anchor="end" font-size="13">33° / 24°</text><path d="M16 85 H344" stroke="#ccc" stroke-width=".5"/>']
for i in range(6):
 x=12+i*55
 svg.append(f'<text x="{x+27}" y="107" text-anchor="middle" font-size="11">{i+15}:00</text><text x="{x+27}" y="134" text-anchor="middle" font-size="22">☁</text><text x="{x+27}" y="159" text-anchor="middle" font-size="13">33°</text>')
svg+=['</g><text class="cap" x="24" y="710">Collapsed frames are emitted by compiled WCCComputeModuleGeometry.</text><text class="cap" x="24" y="733">Expanded preview uses source anchors; glyph metrics approximate, UIKit NOT RUN.</text></svg>']
(p/'evidence/layout115.svg').write_text(''.join(svg))
print('PASS: generated layout115.svg from compiled production geometry (all five sizes); expanded anchor illustration explicitly approximate.')
