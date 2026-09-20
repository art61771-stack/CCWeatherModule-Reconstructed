#ifndef WCC_SESSION_H
#define WCC_SESSION_H
#include <stdint.h>
/* Shared by the Objective-C host adapter and the executable C tests. */
typedef struct { uint64_t generation; int visible; } WCCHostState;
typedef enum { WCCHostBegin, WCCHostPresented, WCCHostDismissed } WCCHostEvent;
static inline int WCCConsumeHostEvent(WCCHostState *s, WCCHostEvent e, int active) {
    int visible=e==WCCHostBegin ? 1 : !!active;
    if(s->visible==visible) return 0;
    s->visible=visible;
    if(visible) ++s->generation;
    return 1;
}
typedef struct { uint64_t generation; int expanded; } WCCModuleSession;
static inline int WCCConsumeModuleHost(WCCModuleSession *s, WCCHostState h) {
    if(!h.visible || !h.generation || s->generation==h.generation) return 0;
    s->generation=h.generation; return 1;
}
static inline int WCCConsumeExpansion(WCCModuleSession *s,int expanded) {
    expanded=!!expanded;
    if(s->expanded==expanded) return 0;
    s->expanded=expanded; return 1;
}
#endif
