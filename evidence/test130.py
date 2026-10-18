from pathlib import Path
import plistlib

p = Path(__file__).resolve().parents[1]
post = (p / 'layout/DEBIAN/postinst').read_text()
assert post.startswith('#!/bin/sh\n')
for needle in ('${SILEO:-}', 'read -r fd ver', '*[!0-9]*', '[ "${ver}" -ge 1 ]', "echo 'finish:restart' >&\"${fd}\""):
    assert needle in post, needle
assert 'eval' not in post
for bad in ('killall', 'launchctl', 'sbreload', 'ldrestart', 'curl', 'wget'):
    assert bad not in post.lower()
assert 'echo finish:restart' not in post
import subprocess
assert subprocess.check_output(['git', 'ls-files', '-s', 'layout/DEBIAN/postinst'], cwd=p, text=True).startswith('100755 ')
control = (p / 'control').read_text()
assert 'Version: 1.2.12' in control
assert 'Architecture: iphoneos-arm64' in control
info = plistlib.loads((p / 'Resources/Info.plist').read_bytes())
assert info['CFBundleVersion'] == info['CFBundleShortVersionString'] == '1.2.12'
workflow = (p / '.github/workflows/build.yml').read_text()
for needle in ('test130_sileo_postinst.sh', 'sileo130-packaged.txt', 'CCWeatherModule-1.2.12-rootless', "grep -q 'arm64 arm64e'", "m.uname=='root' and m.gname=='wheel'", 'm.mode==0o755'):
    assert needle in workflow, needle
print('PASS130 static: official Sileo dynamic-fd semantics, safe validation, 1.2.12 metadata and unpacked-package CI assertions.')
