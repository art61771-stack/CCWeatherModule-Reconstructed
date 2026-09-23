#ifndef WCC_ROUTE_POLICY_H
#define WCC_ROUTE_POLICY_H
static inline int WCCRouteCanEnter(int loaded,int window,int presented,int presenting,int dismissing,int transitioning) {
 return loaded && window && !presented && !presenting && !dismissing && !transitioning;
}
static inline int WCCRouteCanReturn(int exists,int ended,int same,int window) { return exists && !ended && same && window; }
static inline int WCCRouteOwnsDismiss(int root,int same,int dismissing) { return root && same && !dismissing; }
#endif
