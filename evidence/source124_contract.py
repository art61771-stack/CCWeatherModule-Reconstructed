"""124 replaces byte identity only for explicitly changed scheduling paths."""
import re

def verify(p):
 s=p/'src';old=p/'evidence/fixtures122'
 provider=(s/'CYCaiyunProvider.m').read_text()
 assert provider.replace('age<(self.cacheTTL>0?self.cacheTTL:900)','age<900').replace('age>=(self.cacheTTL>0?self.cacheTTL:900)','age>=900')==(old/'CYCaiyunProvider.m').read_text()
 # Keep credential, parsing, render, transaction and epoch protections unchanged.
 source=(s/'WCCWeatherSource.m').read_text();before=(old/'WCCWeatherSource.m').read_text()
 assert source.split('@interface WCCWeatherSource')[0].replace('#import "WCCRefreshPolicy.h"\n','')==before.split('@interface WCCWeatherSource')[0]
 def method(t,name):
  m=re.search(r'^- \\([^\\n]+', '') if False else None
  start=t.index(name);a=t.index('{',start);depth=1;i=a+1
  while depth:
   depth+=(t[i]=='{')-(t[i]=='}');i+=1
  return t[start:i]
 for name in ['- (BOOL)hasToken','- (BOOL)deleteToken','- (BOOL)applyCaiyun:','- (void)refreshManual:','- (void)cancel','- (void)invalidate']:
  current=method(source,name)
  current=current.replace('[self stopTimer];','').replace('self.provider.cacheTTL=self.refreshTTL;','').replace('[self scheduleResult:nil]; ','').replace('[self scheduleResult:r];','')
  assert re.sub(r'\s+','',current)==re.sub(r'\s+','',method(before,name)),name
 for guard in ['NSTimer scheduledTimerWithTimeInterval:delay repeats:NO','WCCRefreshDelay(age,self.refreshTTL,retry)','if(!self.automaticActive || !self.caiyun)return','[self refreshManual:NO]']:
  assert guard in source,guard
