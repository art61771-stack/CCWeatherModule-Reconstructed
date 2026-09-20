int main(void){@autoreleasepool{
 Harness *h=[Harness new]; h->_currentCity=[City new];h.hourlyItems=[NSMutableArray array];
 pending=[NSMutableArray array];h->_hourlyContainer=[UIView new];
 h->_hourlyScrollView=[WCCHourlyScrollView new];h->_hourlyScrollView.window=[NSObject new];h->_hourlyScrollView.bounds=CGRectMake(0,0,200,80);
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
 // Actual production scroll callbacks: zero bounds/no window -> final 400pt first layout.
 [h.hourlyItems removeAllObjects];h.mediaVisible=YES;
 __weak Harness*weak=h;((WCCHourlyScrollView*)h->_hourlyScrollView).geometryReady=^{[weak refreshHourlyMedia];};
 h->_hourlyScrollView.window=nil;h->_hourlyScrollView.bounds=CGRectZero;
 for(int j=0;j<9;j++){Forecast*f=[Forecast new];f.conditionCode=9;WCCHourlyItem*i=(id)[h createHourlyItemWithForecast:f isNow:NO formatter:[NSDateFormatter new]];i.frame=CGRectMake(j*55,0,55,80);i.cachedPath=@"fixture.gif";i.cachedIdentity=@"same";}
 h->_hourlyScrollView.contentOffset=CGPointZero;
 [h->_hourlyScrollView layoutSubviews];for(WCCHourlyItem*i in h.hourlyItems)assert(i.media.loads==0);
 h->_hourlyScrollView.window=[NSObject new];[h->_hourlyScrollView didMoveToWindow];for(WCCHourlyItem*i in h.hourlyItems)assert(i.media.loads==0);
 h->_hourlyScrollView.bounds=CGRectMake(0,0,400,80);[h->_hourlyScrollView layoutSubviews];
 for(int j=0;j<9;j++){WCCHourlyItem*i=h.hourlyItems[j];assert(i.media.active==(j<8));assert(i.media.loads==(j<8));}
 [h->_hourlyScrollView layoutSubviews];for(int j=0;j<8;j++)assert(((WCCHourlyItem*)h.hourlyItems[j]).media.loads==1);
 // Synchronous media callback reentry must not recurse/reload.
 WCCHourlyItem*first=h.hourlyItems[0];first.cachedIdentity=@"new";first.media.mediaChanged=^{[weak refreshHourlyMedia];};[h refreshHourlyMedia];assert(first.media.loads==3&&!h.hourlyRefreshing);
 __block int layouts=0;h.view.onLayout=^{layouts++;};
 [h scheduleHourlyLayoutValidation];[h scheduleHourlyLayoutValidation];assert(pending.count==2);drain();assert(layouts==1&&pending.count==0);
 [h scheduleHourlyLayoutValidation];[h didTransitionToExpandedContentMode:NO];drain();assert(layouts==1);
 [h didTransitionToExpandedContentMode:YES];assert(layouts==2);drain();assert(layouts==3);
 // Controller lifetime is weak in pending blocks; scroll callback also weak.
 [h scheduleHourlyLayoutValidation];h=nil;assert(!weak);drain();
 puts("PASS 118 exact production scroll layout/window + refresh + transition + queued generation: zero bounds/no window, eight visible without scroll, same identity, synchronous reentry, cancellation, weak lifetime. Stub preparation only; decoder generation verified separately.");
 puts("PASS exact production ObjC resolver + hourly creation + admission: 96 resource selections, no daylight getter, five partial/full visible static items, reuse, offscreen release/return, parent gate, unknown fallback. UIKit/decoder/iOS16 NOT RUN.");
}return 0;}
