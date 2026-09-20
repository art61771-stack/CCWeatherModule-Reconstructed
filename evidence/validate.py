import pathlib,re,json,hashlib
root=pathlib.Path(__file__).resolve().parent.parent
methods=json.loads((root/'evidence/method-map.json').read_text())
source='\n'.join(p.read_text() for p in (root/'src').glob('*.m'))
implemented=set()
for line in source.splitlines():
 if re.match(r'^[-+]\s*\(',line):
  body=re.sub(r'^[-+]\s*\([^)]*\)\s*','',line)
  parts=re.findall(r'(\w+)\s*:',body.split('{')[0])
  implemented.add(''.join(p+':' for p in parts) if parts else re.match(r'\w+',body)[0])
synthesized={'contentViewController','weatherModel','setWeatherModel:','forecast','setForecast:','isInitialized','setIsInitialized:','.cxx_destruct'}
missing=set(methods.values())-implemented-synthesized
print('Recovered metadata entries:',len(methods))
print('Explicit source selectors:',len(implemented))
print('Missing original selectors:',sorted(missing))
assert not missing
original=root/'package/var/jb/Library/ControlCenter/Bundles/CCWeatherModule.bundle'
files=[p for p in original.iterdir() if p.name!='CCWeatherModule']
for p in files:assert p.read_bytes()==(root/'Resources'/p.name).read_bytes(),p.name
print('Byte-identical original resources:',len(files))
tables=json.loads((root/'evidence/tables.json').read_text())
for values in tables.values():assert len(values)==48
for name in tables['images']:
 for n in ([name.replace('%@','白天'),name.replace('%@','夜间')] if '%@' in name else [name]):assert (root/'Resources'/(n+'.png')).exists(),n
print('All 144 recovered condition/image/symbol entries and image resources present.')
print('STATIC CHECKS ONLY: no Apple SDK compile, link or device runtime test performed.')
