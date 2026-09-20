#ifndef WCC_ABI_H
#define WCC_ABI_H
#include <stddef.h>
#include <string.h>
/* Reject structs, extra args, qualifiers and mismatched BOOL encodings; no guesses. */
static inline int WCCABICompatible(const char *result,const char *expectedResult,
    size_t count,const char *const *actual,size_t explicitCount,const char *const *expected) {
    if(!result || !expectedResult || strcmp(result,expectedResult) || count!=explicitCount+2 || !actual) return 0;
    if(!actual[0]||!actual[1]||strcmp(actual[0],"@")||strcmp(actual[1],":")) return 0;
    for(size_t i=0;i<explicitCount;i++)
        if(!actual[i+2]||!expected||!expected[i]||strcmp(actual[i+2],expected[i])) return 0;
    return 1;
}
#endif
