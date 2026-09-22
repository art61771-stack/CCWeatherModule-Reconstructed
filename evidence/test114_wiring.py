from pathlib import Path
root=Path(__file__).resolve().parents[1]
c=(root/'src/WCCContentViewController.m').read_text()
r=(root/'src/WCCRuntime.h').read_text()
g=(root/'src/WCCGallery.m').read_text()
m=(root/'Makefile').read_text()
present=c.split('- (void)controlCenterWillPresent {')[1].split('- (void)viewDidLoad')[0]
assert 'WCCPresentGreeting(&state,hour,arc4random_uniform(840))' in present
assert 'NSTimeZone.localTimeZone' in present
layout=c.split('- (void)viewWillLayoutSubviews')[1].split('- (void)refreshWeatherData')[0]
assert 'beginGreetingSession' not in layout and 'bindGreetingText' in layout
assert 'self.layoutSize.width>=2 && self.layoutSize.width<=4 && self.layoutSize.height==1' in layout
assert 'NSTextAlignmentRight : NSTextAlignmentLeft' in layout
assert '[self bindGreetingText];' in c.split('- (void)setupHeaderView')[1].split('- (void)setupHourlyContainer')[0]
assert 'WCCGreetingPrefixes[6]' in r and 'WCCGreetingSuffixes[6][8]' in r
for path in list((root/'src').glob('*'))+list((root/'Resources').glob('*.html'))+[root/'Makefile']:
 text=path.read_text()
 for token in ['WKWebView','WebKit','WCCGalleryBridge','HTML 动态图库','Gallery.html']:
  assert token not in text,(path,token)
for path in ['Resources/Gallery.html','src/WCCGalleryBridge.m','src/WCCGalleryBridge.h']:
 assert not (root/path).exists()
assert '_pendingName || !_preview.hasMedia' in g
assert 'WCCCheckedPath(WCCRoot(),name,&reason)' in g
assert 'UIBarButtonSystemItemRefresh' in g
assert 'numberOfTouchesRequired = 1' in c and 'numberOfTouchesRequired = 2' in c
assert 'ARCHS = arm64 arm64e' in m and 'THEOS_PACKAGE_SCHEME = rootless' in m
print('PASS static production wiring: presentation edge/local timezone/stable layout/label binding/3x1 alignment/native-only source/deleted web assets/validated commit/gestures/rootless architectures. Runtime UIKit ABI/event delivery NOT RUN.')
