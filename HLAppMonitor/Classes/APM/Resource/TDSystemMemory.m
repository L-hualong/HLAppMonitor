//
//  TDSystemMemory.m
//  TuanDaiV4
//
//  Created by guoxiaoliang on 2018/6/25.
//  Copyright © 2018 Dee. All rights reserved.
//

#import "TDSystemMemory.h"
#import <mach/mach.h>
#import <mach/vm_statistics.h>


#ifndef NBYTE_PER_MB
#define NBYTE_PER_MB (1024 * 1024)
#endif


@implementation TDSystemMemory

- (TDSystemMemoryUsage)currentUsage {
    vm_statistics64_data_t vmstat;
    natural_t size = HOST_VM_INFO64_COUNT;
    if (host_statistics64(mach_host_self(), HOST_VM_INFO64, (host_info64_t)&vmstat, &size) == KERN_SUCCESS) {
        return (TDSystemMemoryUsage){
            .free = vmstat.free_count * PAGE_SIZE / NBYTE_PER_MB,
            .wired = vmstat.wire_count * PAGE_SIZE / NBYTE_PER_MB,
            .active = vmstat.active_count * PAGE_SIZE / NBYTE_PER_MB,
            .inactive = vmstat.inactive_count * PAGE_SIZE / NBYTE_PER_MB,
            .compressed = vmstat.compressor_page_count * PAGE_SIZE / NBYTE_PER_MB,
            .total = [NSProcessInfo processInfo].physicalMemory / NBYTE_PER_MB,
        };
    }
    return (TDSystemMemoryUsage){ 0 };
}
@end
