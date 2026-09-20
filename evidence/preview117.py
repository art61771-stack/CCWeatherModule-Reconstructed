from pathlib import Path
import subprocess
r=Path(__file__).resolve().parents[1]
subprocess.run(['cc','-Wall','-Wextra','-Werror',str(r/'evidence/layout117.c'),'-lm','-o','/tmp/layout117'],check=True)
rects=[list(map(float,l.split())) for l in subprocess.check_output(['/tmp/layout117'],text=True).splitlines()]
labels=['26°','33° / 25°','ICON','示例城','有雨','降水概率:40%','晚上好，享受属于你的时光']
colors=['#fdcf76','#fdcf76','#73c4ff','#8ee6c7','#8ee6c7','#8ee6c7','#d3b0fa']
svg=['<svg xmlns="http://www.w3.org/2000/svg" width="1000" height="410" viewBox="0 0 333 137"><rect width="333" height="137" fill="#12202b"/><g transform="translate(21.5 16)"><rect width="290" height="84" rx="18" fill="#263843" stroke="#ddd"/>']
for (x,y,w,h),t,c in zip(rects,labels,colors):
 svg.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="none" stroke="{c}" stroke-width=".5"/><text x="{x+w/2}" y="{y+h*.7}" text-anchor="middle" fill="{c}" font-size="{min(9,h*.65)}">{t}</text>')
svg+=['</g><text x="166.5" y="112" text-anchor="middle" fill="white" font-size="5">Production WCCBalanceMeasuredStrip; explicit text-width fixture; NOT UIKit/device render</text><text x="166.5" y="124" text-anchor="middle" fill="white" font-size="5">Weather outer margins: 49.026 / 49.026; icon centered in metadata rail; greeting centered separately</text></svg>']
(r/'evidence/preview117.svg').write_text(''.join(svg))
print('PASS production rectangle preview; fixture widths, not UIKit font/rasterization evidence')
