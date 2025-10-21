//
//  LyoApp-Bridging-Header.h
//  LyoApp
//
//  Bridging header for Swift-ObjC interoperability
//

#ifndef LyoApp_Bridging_Header_h
#define LyoApp_Bridging_Header_h

#import <UnityFramework/UnityFramework.h>

extern void UnitySendMessage(const char* className, const char* methodName, const char* message);

#endif
