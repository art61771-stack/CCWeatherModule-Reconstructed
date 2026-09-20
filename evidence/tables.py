import contextlib,io
with contextlib.redirect_stdout(io.StringIO()):
 from decode import *
print('FLOATS')
for a in range(0x8fc8,0x9008,8):print(hex(a),struct.unpack_from('<d',b,file(a))[0])
print('SYMBOLS')
symbols=[labels[ptr(0xc1f8+i*8)][1:] for i in range(48)]
print(symbols)
print('IMAGE JUMPS')
imageTargets=[0x6f7c+b[file(0x9008)+i]*4 for i in range(48)]
print([hex(t) for t in imageTargets])
regs={};stack={}
for line in text.splitlines():
 m=re.match(r'\s*([0-9a-f]+):',line)
 if not m or not 0x6818<=int(m[1],16)<0x6be0:continue
 m=re.search(r'adrp\s+(x\d+),.*; (0x[0-9a-f]+)',line)
 if m:regs[m[1]]=int(m[2],16)
 m=re.search(r'add\s+(x\d+), (x\d+), #(0x[0-9a-f]+)',line)
 if m and m[2] in regs:regs[m[1]]=regs[m[2]]+int(m[3],16)
 m=re.search(r'stp\s+(x\d+), (x\d+), \[sp, #(0x[0-9a-f]+)\]',line)
 if m:
  p=int(m[3],16);stack[p]=regs.get(m[1]);stack[p+8]=regs.get(m[2])
 m=re.search(r'str\s+(x\d+), \[sp, #(0x[0-9a-f]+)\]',line)
 if m:stack[int(m[2],16)]=regs.get(m[1])
conditions=[labels[stack[0x188+i*8]][1:] for i in range(48)]
print('CONDITIONS',conditions)
images={0x6f7c:'雷阵雨',0x6f88:'雨夹雪',0x6f94:'中雨',0x6fa0:'小雪-%@',0x6fb4:'多云-%@',0x6fc8:'龙卷风',0x6fd4:'中雪',0x6fe0:'大风',0x6fec:'多云-夜间',0x6ff8:'晴天-白天',0x7004:'大雪',0x7010:'小雨-%@',0x702c:'晴天-夜间',0x703c:'冰雹',0x7048:'浮尘',0x7054:'雾',0x7060:'轻度雾霾',0x706c:'中度雾霾',0x7078:'寒冷',0x7084:'阴天',0x7090:'炎热'}
imageNames=[images[t] for t in imageTargets]
print('IMAGES',imageNames)
(root/'evidence/tables.json').write_text(json.dumps(dict(conditions=conditions,symbols=symbols,images=imageNames),ensure_ascii=False,indent=2))
