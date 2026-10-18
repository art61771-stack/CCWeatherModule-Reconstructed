from pathlib import Path
p=Path(__file__).parents[1]; s=p/'src'
b=(s/'WCCBackground.m').read_text(); ui=(s/'WCCBackgroundSettings.m').read_text(); c=(s/'WCCContentViewController.m').read_text(); pref=(s/'WCCPreferences.m').read_text(); cfg=(s/'WCCConfigurations.m').read_text(); wf=(p/'.github/workflows/build.yml').read_text()
assert '/var/mobile/Documents/CCWeatherModule/Background' in b and 'O_NOFOLLOW' in b and 'lstat' in b
assert '64ULL*1024ULL*1024ULL' in b and '.incoming-' in b and '.previous' in b
assert 'current-image.jpg' in b and 'current-video.mp4' in b and 'WCCClearBackground' in b
assert 'PHPickerViewController' in ui and 'loadFileRepresentationForTypeIdentifier' in ui and 'selectionLimit=1' in ui
assert 'WCCBackgroundPickerGenerationCurrent' in ui and 'ownerValid' in ui
assert 'backgroundMaskView' in c and 'addSubview:self.backgroundMedia' in c and 'userInteractionEnabled=NO' in c
assert 'aspectFill=YES' in c and 'didReceiveMemoryWarning' in c and 'updateBackgroundPlayback' in c
assert 'version>7' in pref and 'backgroundMask1212' in pref and 'MIN(1,MAX(0' in pref
assert '@"version":@7' in cfg and 'WCCBackgroundRelativeName' in cfg
assert 'Version: 1.2.12' in (p/'control').read_text() and 'CCWeatherModule-1.2.12-rootless' in wf
print('PASS1212 static: secure picker copy, confinement, atomic rollback, v7 mask/background, lifecycle wiring. UIKit/device NOT RUN.')
