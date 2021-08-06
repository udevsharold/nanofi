//    Copyright (c) 2021 udevs
//
//    This program is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, version 3.
//
//    This program is distributed in the hope that it will be useful, but
//    WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
//    General Public License for more details.
//
//    You should have received a copy of the GNU General Public License
//    along with this program. If not, see <http://www.gnu.org/licenses/>.

#import "common.h"
#import "NFShared.h"

id valueForKey(NSString *key, id defaultValue){
    NSMutableDictionary *prefs = [NSMutableDictionary dictionary];
    [prefs addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:kPrefsPath]];
    return prefs[key] ?: defaultValue;
}

void setValueForKey(NSString *key, id value){
    NSMutableDictionary *prefs = [NSMutableDictionary dictionary];
    [prefs addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:kPrefsPath]];
    
    [prefs setObject:value forKey:key];
    [prefs writeToFile:kPrefsPath atomically:YES];
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (CFStringRef)kPrefsChanged, NULL, NULL, YES);
}

