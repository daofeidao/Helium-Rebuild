//
//  SwiftObjCPPBridger.h
//  
//
//  Created by lemin on 10/13/23.
//

#import <Foundation/Foundation.h>

#pragma mark - HUD Functions

BOOL IsHUDEnabledBridger();
void SetHUDEnabledBridger(BOOL isEnabled);
void waitForNotificationBridger(void (^onFinish)(), BOOL isEnabled);

/// YES only when a HUD is running and it is not this build -- what an install
/// leaves behind, because the process already on screen keeps running the old
/// code until it is replaced.
BOOL IsHUDBuildStaleBridger();