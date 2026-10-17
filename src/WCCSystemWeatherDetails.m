#import "WCCSystemWeatherDetails.h"
#import <objc/message.h>
#import <math.h>

static const char *WCCSkipQualifiers(const char *type) {
    while (type && strchr("rnNoORV", *type)) type++;
    return type;
}
static BOOL WCCSignature(id object, SEL selector, NSMethodSignature **out) {
    if (!object || ![object respondsToSelector:selector]) return NO;
    NSMethodSignature *s=[object methodSignatureForSelector:selector];
    if (!s || s.numberOfArguments!=2) return NO;
    if (out) *out=s; return YES;
}
static id WCCObject(id object, NSString *name) {
    SEL sel=NSSelectorFromString(name); NSMethodSignature *s=nil;
    if (!WCCSignature(object,sel,&s) || *WCCSkipQualifiers(s.methodReturnType)!='@') return nil;
    return ((id(*)(id,SEL))objc_msgSend)(object,sel);
}
static NSNumber *WCCNumber(id object, NSString *name) {
    SEL sel=NSSelectorFromString(name); NSMethodSignature *s=nil;
    if (!WCCSignature(object,sel,&s)) return nil;
    const char *t=WCCSkipQualifiers(s.methodReturnType); double value=NAN;
    switch (*t) {
        case '@': { id v=((id(*)(id,SEL))objc_msgSend)(object,sel); if (![v isKindOfClass:NSNumber.class]) return nil; value=[v doubleValue]; break; }
        case 'f': value=((float(*)(id,SEL))objc_msgSend)(object,sel); break;
        case 'd': value=((double(*)(id,SEL))objc_msgSend)(object,sel); break;
        case 'c': value=((char(*)(id,SEL))objc_msgSend)(object,sel); break;
        case 'C': value=((unsigned char(*)(id,SEL))objc_msgSend)(object,sel); break;
        case 's': value=((short(*)(id,SEL))objc_msgSend)(object,sel); break;
        case 'S': value=((unsigned short(*)(id,SEL))objc_msgSend)(object,sel); break;
        case 'i': value=((int(*)(id,SEL))objc_msgSend)(object,sel); break;
        case 'I': value=((unsigned int(*)(id,SEL))objc_msgSend)(object,sel); break;
        case 'l': value=((long(*)(id,SEL))objc_msgSend)(object,sel); break;
        case 'L': value=((unsigned long(*)(id,SEL))objc_msgSend)(object,sel); break;
        case 'q': value=((long long(*)(id,SEL))objc_msgSend)(object,sel); break;
        case 'Q': value=((unsigned long long(*)(id,SEL))objc_msgSend)(object,sel); break;
        default: return nil;
    }
    return isfinite(value)?@(value):nil;
}
static NSString *WCCDirection(double degrees) {
    if (!isfinite(degrees) || degrees<0 || degrees>360) return nil;
    NSArray *names=@[@"北风",@"东北风",@"东风",@"东南风",@"南风",@"西南风",@"西风",@"西北风"];
    return names[(NSInteger)floor((fmod(degrees,360)+22.5)/45)%8];
}
static NSDate *WCCDate(id hour) {
    id date=WCCObject(hour,@"date");
    if ([date isKindOfClass:NSDate.class]) return date;
    NSNumber *stamp=WCCNumber(hour,@"forecastTime");
    return stamp ? [NSDate dateWithTimeIntervalSince1970:stamp.doubleValue] : nil;
}
static NSTimeZone *WCCTimeZone(id city) {
    id zone=WCCObject(city,@"timeZone");
    return [zone isKindOfClass:NSTimeZone.class]?zone:nil;
}
NSDictionary<NSString *,NSString *> *WCCRenderSystemWeatherDetails(id city, NSDate *now, WCCSystemConditionName conditionName) {
    if (!city) return @{@"details":@"",@"outlook":@""};
    NSMutableArray *parts=[NSMutableArray array];
    NSNumber *direction=WCCNumber(city,@"windDirection");
    NSString *directionText=direction?WCCDirection(direction.doubleValue):nil;
    // Runtime headers establish City's windSpeed as a raw float, but do not establish its unit.
    // Do not print or Beaufort-convert an unproven speed value.
    if (directionText) [parts addObject:directionText];
    NSNumber *humidity=WCCNumber(city,@"humidity");
    if (humidity) {
        double h=humidity.doubleValue;
        if (h>=0 && h<=1) [parts addObject:[NSString stringWithFormat:@"湿度%.0f%%",h*100]];
        else if (h>1 && h<=100) [parts addObject:[NSString stringWithFormat:@"湿度%.0f%%",h]];
    }
    NSMutableArray *names=[NSMutableArray array]; NSDate *first=nil,*last=nil; NSInteger samples=0;
    id raw=WCCObject(city,@"hourlyForecasts"); NSArray *hours=[raw isKindOfClass:NSArray.class]?raw:nil;
    NSDate *reference=now?:[NSDate date]; NSDate *expected=nil;
    for (id hour in hours) {
        if(samples>=24)break;
        NSDate *date=WCCDate(hour); if(!date) { if(first)break; continue; }
        NSTimeInterval future=[date timeIntervalSinceDate:reference];
        if(future<0)continue; if(future>24*3600)break;
        if(!first) { if(future>3600)break; }
        else if(fabs([date timeIntervalSinceDate:expected])>1)break;
        NSNumber *code=WCCNumber(hour,@"conditionCode"); NSString *name=code&&conditionName?conditionName(code.integerValue):nil;
        if(!name.length) { if(first)break; continue; }
        if(!first)first=date; last=date; expected=[date dateByAddingTimeInterval:3600]; samples++;
        if(![names containsObject:name])[names addObject:name];
    }
    NSString *outlook=@"";
    if(samples>0) {
        NSDateFormatter *f=[NSDateFormatter new]; f.locale=[NSLocale localeWithLocaleIdentifier:@"zh_CN"];
        f.timeZone=WCCTimeZone(city)?:NSTimeZone.localTimeZone; f.dateFormat=@"MM-dd HH:mm";
        outlook=[NSString stringWithFormat:@"未来%ld小时 %@–%@：%@",(long)samples,[f stringFromDate:first],[f stringFromDate:last],[names componentsJoinedByString:@" / "]];
    }
    return @{@"details":[parts componentsJoinedByString:@" · "],@"outlook":outlook};
}
