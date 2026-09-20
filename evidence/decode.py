import struct,pathlib,re,json
root=pathlib.Path(__file__).resolve().parent.parent
raw=(root/'package/var/jb/Library/ControlCenter/Bundles/CCWeatherModule.bundle/CCWeatherModule').read_bytes()
off=struct.unpack_from('>I',raw,16)[0]; b=raw[off:]
u32=lambda p:struct.unpack_from('<I',b,p)[0]
u64=lambda p:struct.unpack_from('<Q',b,p)[0]
i32=lambda p:struct.unpack_from('<i',b,p)[0]
secs={}; allsecs=[]; p=32
for _ in range(u32(16)):
 cmd,size=struct.unpack_from('<II',b,p)
 if cmd==25:
  for q in range(p+72,p+72+80*u32(p+64),80):
   name=b[q:q+16].split(b'\0')[0].decode(); a,z,f=struct.unpack_from('<QQI',b,q+32);secs[name]=(a,z,f);allsecs.append((a,z,f))
 p+=size
def file(a):
 for v,z,f in allsecs:
  if v<=a<v+z:return f+a-v
 raise ValueError(hex(a))
def ptr(a):return u64(file(a))&0xffffffff
def string(a):
 p=file(a);return b[p:b.index(0,p)].decode(errors='replace')
labels={}
a,z,f=secs['__objc_selrefs']
for v in range(a,a+z,8):labels[v]=string(ptr(v))
a,z,f=secs['__cfstring']
for v in range(a,a+z,32):
 flags=u64(file(v+8)); s=ptr(v+16); n=u64(file(v+24))
 labels[v]='@'+(b[file(s):file(s)+n*2].decode('utf-16le') if flags&16 else b[file(s):file(s)+n].decode())
a,z,f=secs['__objc_methlist'];v=a;methods={}
while v<a+z:
 flags=u32(file(v));n=u32(file(v+4));print('METHOD LIST',hex(v),n)
 for t in range(v+8,v+8+12*n,12):
  name=labels.get(t+i32(file(t)), '?');typ=string(t+4+i32(file(t+4)));imp=t+8+i32(file(t+8));methods[imp]=name
  print(hex(imp),name,typ)
 v=(v+8+12*n+7)&~7
print('\nSTRINGS/SELECTORS')
for k,v in labels.items(): print(hex(k),repr(v))
print('\nIVARS RAW')
a,z,f=secs['__objc_const']
for v in range(a,a+z,8):
 try:
  s=string(ptr(v))
  if s.startswith('_') or s.startswith('T@'):print(hex(v),repr(s))
 except:pass
text=(root/'evidence/disassembly.txt').read_text().split('(architecture arm64e)')[0]
stubs={}; a,z,f=secs['__objc_stubs']
for v in range(a,a+z,32):
 ins=u32(file(v+4));imm=(ins>>10&4095)*8
 stubs[v]=labels.get(0x10000+imm,'?')
lines=[];regs={}
for line in text.splitlines():
 m=re.match(r'\s*([0-9a-f]+):',line)
 if m:
  addr=int(m[1],16)
  if addr in methods:lines.append('\nMETHOD '+methods[addr])
  m=re.search(r'adrp\s+(x\d+),.*; (0x[0-9a-f]+)',line)
  if m:regs[m[1]]=int(m[2],16)
  m=re.search(r'(?:ldr|ldrsw|add)\s+\w+, (?:\[)?(x\d+), #(0x[0-9a-f]+)',line)
  if m and m[1] in regs:
   v=regs[m[1]]+int(m[2],16)
   if v in labels:line+=' // '+labels[v]
  m=re.search(r'\b(?:bl|b)\s+(0x[0-9a-f]+)',line)
  if m and int(m[1],16) in stubs:line+=' // SEND '+stubs[int(m[1],16)]
 lines.append(line)
(root/'evidence/annotated-arm64.txt').write_text('\n'.join(lines))
(root/'evidence/method-map.json').write_text(json.dumps(methods,ensure_ascii=False,indent=2))
