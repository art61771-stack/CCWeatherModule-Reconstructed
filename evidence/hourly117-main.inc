int main(void){@autoreleasepool{
 Harness *h=[Harness new]; h->_currentCity=[City new];h.hourlyItems=[NSMutableArray array];
 h->_hourlyScrollView=[UIScrollView new];h->_hourlyScrollView.bounds=CGRectMake(0,0,200,80);
 h.view=[UIView new];h.view.window=[NSObject new];h.mediaVisible=YES;h->_isExpanded=YES;
 for(int night=0;night<2;night++)for(int code=0;code<48;code++){
  h->_currentCity.isDay=!night;Forecast*f=[Forecast new];f.conditionCode=code;
  assert(![f respondsToSelector:NSSelectorFromString(@"isDaylight")]);
  WCCHourlyItem*i=(id)[h createHourlyItemWithForecast:f isNow:NO formatter:[NSDateFormatter new]];
  assert([i.assetKey isEqual:loadedName]);assert([i.assetKey isEqual:WCCAssetKey(code,night)]);
  assert(i.originalIcon.image && !i.originalIcon.hidden);
  assert(i.media.frame.origin.x==12 && i.media.frame.origin.y==22 && i.media.frame.size.width==30);
 }
 [h.hourlyItems removeAllObjects];
 for(int code=9;code<15;code++){
  Forecast*f=[Forecast new];f.conditionCode=code;WCCHourlyItem*i=(id)[h createHourlyItemWithForecast:f isNow:YES formatter:[NSDateFormatter new]];
  i.frame=CGRectMake((code-9)*55,0,55,80);i.cachedPath=@"fixture.png";i.cachedIdentity=[NSString stringWithFormat:@"%d",code];
 }
 h->_hourlyScrollView.contentOffset=(CGPoint){54,0};[h refreshHourlyMedia];
 for(int j=0;j<6;j++){WCCHourlyItem*i=h.hourlyItems[j];assert(i.media.active==(j<5));assert(i.originalIcon.hidden==(j<5));}
 [h refreshHourlyMedia];assert(((WCCHourlyItem*)h.hourlyItems[0]).media.loads==1);
 h->_hourlyScrollView.contentOffset=(CGPoint){275,0};[h refreshHourlyMedia];
 assert(!((WCCHourlyItem*)h.hourlyItems[0]).media.active);assert(!((WCCHourlyItem*)h.hourlyItems[0]).originalIcon.hidden);
 h->_hourlyScrollView.contentOffset=(CGPoint){54,0};[h refreshHourlyMedia];
 assert(((WCCHourlyItem*)h.hourlyItems[0]).media.active);
 h.mediaVisible=NO;[h refreshHourlyMedia];for(WCCHourlyItem*i in h.hourlyItems)assert(!i.media.active);
 Forecast*unknown=[Forecast new];unknown.conditionCode=99;WCCHourlyItem*u=(id)[h createHourlyItemWithForecast:unknown isNow:NO formatter:[NSDateFormatter new]];assert(!u.assetKey && u.originalIcon.image);
 puts("PASS exact production ObjC resolver + hourly creation + admission: 96 resource selections, no daylight getter, five partial/full visible static items, reuse, offscreen release/return, parent gate, unknown fallback. UIKit/decoder/iOS16 NOT RUN.");
}return 0;}
