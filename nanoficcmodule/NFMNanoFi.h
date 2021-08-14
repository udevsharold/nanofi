#include <ControlCenterUIKit/CCUIToggleModule.h>
#include <ControlCenterUIKit/CCUIToggleViewController.h>

@interface NFMNanoFi : CCUIToggleModule{
    BOOL _selected;
    BOOL _enabled;
    BOOL _requesting;
}
@end

@interface UIApplication ()
-(BOOL)_openURL:(id)arg1 ;
@end
