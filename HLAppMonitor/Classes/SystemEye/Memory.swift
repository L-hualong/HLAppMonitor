//
//  Memory.swift
//  Pods
//
//  Created by zixun on 2016/12/6.
//
//

import Foundation

private let HOST_VM_INFO64_COUNT: mach_msg_type_number_t =
    UInt32(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)

private let PAGE_SIZE : Double = Double(vm_kernel_page_size)

open class Memory: NSObject {
    
    //--------------------------------------------------------------------------
    // MARK: OPEN FUNCTION
    //--------------------------------------------------------------------------
    
    /// Memory usage of application  获取当前任务所占用的内存
    open class func applicationUsage() -> Array<Double> {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout.size(ofValue: info) / MemoryLayout<integer_t>.size)
        let kerr = withUnsafeMutablePointer(to: &info) {
            return $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                return task_info(mach_task_self_,task_flavor_t(MACH_TASK_BASIC_INFO),$0,&count
                )
            }
        }
        guard kerr == KERN_SUCCESS else {
            return [0,self.totalBytes]
        }
        
        return [Double(info.resident_size),self.totalBytes]
    }
    
    /// Memory usage of system 获取当前设备内存使用情况
    open class func systemUsage() -> Array<Double> {
        let statistics = self.VMStatistics64()
        
        //空闲内存
        /*
         总的内存: (active_count + inactive_count + speculative_count + wire_count + compressor_page_count ＋ free_count) * 4096
         
         使用的内存: (active_count + inactive_count + speculative_count + wire_count + compressor_page_count － purgeable_count － external_page_count) * 4096
         
         应用内存: internal_page_count * 4096
         
         联动内存: wire_count * 4096
         
         已压缩: compressor_page_count * 4096
         
         已缓存文件: (purgeable_count + external_page_count) * 4096
         
         内存压力: (vm_stat.wire_count + vm_stat.compressor_page_count) / 总的内存 * 100%

         */
        //空闲内存
        let free = Double(statistics.free_count) * PAGE_SIZE
        //使用内存 =(active_count+inactive_count+wire_count)*PAGE_SIZE
        //Active Memory活动内存
        let active = Double(statistics.active_count) * PAGE_SIZE
        //Inactive Memory  不活跃的内存 
        let inactive = Double(statistics.inactive_count) * PAGE_SIZE
        //Wired Memory
        let wired = Double(statistics.wire_count) * PAGE_SIZE
        let compressed = Double(statistics.compressor_page_count) * PAGE_SIZE
        
        return [free,active,inactive,wired,compressed,self.totalBytes]
    }
    
    //--------------------------------------------------------------------------
    // MARK: PRIVATE PROPERTY
    //--------------------------------------------------------------------------
    //总的内存 获取总内存大小
    private static let totalBytes = Double(ProcessInfo.processInfo.physicalMemory)
    
    //--------------------------------------------------------------------------
    // MARK: PRIVATE FUNCTION
    //--------------------------------------------------------------------------
    private static func VMStatistics64() -> vm_statistics64 {
//        
//        let hostPort: mach_port_t = mach_host_self()
//        var host_size: mach_msg_type_number_t = mach_msg_type_number_t(MemoryLayout<vm_statistics_data_t>.stride / MemoryLayout<integer_t>.stride)
//        var pagesize:vm_size_t = 0
//        host_page_size(hostPort, &pagesize)
//        var vmStat: vm_statistics = vm_statistics_data_t()
//        let status: kern_return_t = withUnsafeMutableBytes(of: &vmStat) {
//            let boundPtr = $0.baseAddress?.bindMemory(to: Int32.self, capacity: MemoryLayout.size(ofValue: vmStat) / MemoryLayout<Int32>.stride)
//            return host_statistics(hostPort, HOST_VM_INFO, boundPtr, &host_size)
//            }

        //----------------------------------------
        var size     = HOST_VM_INFO64_COUNT//  UInt32(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        var hostInfo = vm_statistics64()
        
        let result = withUnsafeMutablePointer(to: &hostInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
                host_statistics64(System.machHost, HOST_VM_INFO64, $0, &size)
            }
        }
        #if DEBUG
            if result != KERN_SUCCESS {
                print("ERROR - \(#file):\(#function) - kern_result_t = "
                    + "\(result)")
            }
        #endif
        return hostInfo
    }
}
