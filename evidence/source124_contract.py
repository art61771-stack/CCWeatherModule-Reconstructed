def provider124(provider):
 assert '    NSDictionary *wind=D(real[@"wind"]);\n    NSNumber *speed=N(wind[@"speed"]),*direction=N(wind[@"direction"]),*humidity=N(real[@"humidity"]);\n    s.windSpeedKPH=speed && speed.doubleValue>=0?speed:nil;\n    s.windDirectionDegrees=direction && direction.doubleValue>=0 && direction.doubleValue<=360?direction:nil;\n    s.relativeHumidity=humidity && humidity.doubleValue>=0 && humidity.doubleValue<=1?humidity:nil;\n' in provider
 return provider.replace('    NSDictionary *wind=D(real[@"wind"]);\n    NSNumber *speed=N(wind[@"speed"]),*direction=N(wind[@"direction"]),*humidity=N(real[@"humidity"]);\n    s.windSpeedKPH=speed && speed.doubleValue>=0?speed:nil;\n    s.windDirectionDegrees=direction && direction.doubleValue>=0 && direction.doubleValue<=360?direction:nil;\n    s.relativeHumidity=humidity && humidity.doubleValue>=0 && humidity.doubleValue<=1?humidity:nil;\n','').replace('NSNumber *currentTemperature,*maximum,*minimum,*windSpeedKPH,*windDirectionDegrees,*relativeHumidity;','NSNumber *currentTemperature,*maximum,*minimum;')

"""124 replaces byte identity only for explicitly changed scheduling paths."""
import re

def verify(p):
 s=p/'src';old=p/'evidence/fixtures122'
 provider=(s/'CYCaiyunProvider.m').read_text()
 assert provider124(provider).replace('age<(self.cacheTTL>0?self.cacheTTL:900)','age<900').replace('age>=(self.cacheTTL>0?self.cacheTTL:900)','age>=900')==(old/'CYCaiyunProvider.m').read_text()
 # Keep credential, parsing, render, transaction and epoch protections unchanged.
 source=(s/'WCCWeatherSource.m').read_text();before=(old/'WCCWeatherSource.m').read_text()
 projection=source.split('@interface WCCWeatherSource')[0]
 projection=projection[:projection.index('// Explicit provider units only.')]+projection[projection.index('NSDictionary *WCCRenderCaiyunSnapshot'):]
 projection=projection.replace('@"details":WCCWeatherDetails(s),@"outlook":WCCWeatherOutlook(s),','')
 assert projection.replace('#import "WCCRefreshPolicy.h"\n','')==before.split('@interface WCCWeatherSource')[0]
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
