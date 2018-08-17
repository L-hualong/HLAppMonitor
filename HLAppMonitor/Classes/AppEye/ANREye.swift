//
//  ANREye.swift
//  Pods
//
//  Created by zixun on 16/12/24.
//
//

import Foundation

//--------------------------------------------------------------------------
// MARK: - ANREyeDelegate
//--------------------------------------------------------------------------
@objc public protocol ANREyeDelegate: class {
    @objc optional func anrEye(anrEye:ANREye,
                               catchWithThreshold threshold:Double,
                               mainThreadBacktrace:String?,
                               allThreadBacktrace:String?)
    // 卡顿时长,startTime:开始时间,endTime:结束数据,都是以毫秒的时间戳
    @objc optional func anrEye(anrEye:ANREye,startTime:Int64,endTime: Int64,
                               catchWithThreshold threshold:Double,
                               mainThreadBacktrace:String?,
                               allThreadBacktrace:String?)
}

//--------------------------------------------------------------------------
// MARK: - ANREye
//--------------------------------------------------------------------------
open class ANREye: NSObject {
    
    //--------------------------------------------------------------------------
    // MARK: OPEN PROPERTY
    //--------------------------------------------------------------------------
    open weak var delegate: ANREyeDelegate?
    
    open var isOpening: Bool {
        get {
            guard let pingThread = self.pingThread else {
                return false
            }
            return !pingThread.isCancelled
        }
    }
    //--------------------------------------------------------------------------
    // MARK: OPEN FUNCTION
    //--------------------------------------------------------------------------
    
    open func open(with threshold:Double) {
        if Thread.current.isMainThread {
            //mach_thread_self() 获得线程内核端口的发送权限
            AppBacktrace.main_thread_id = mach_thread_self()
        }else {
            DispatchQueue.main.async {
                AppBacktrace.main_thread_id = mach_thread_self()
            }
        }
        
        self.pingThread = AppPingThread()
        var main: String?
        var all: String?
        self.pingThread?.start(threshold: threshold, handler: { [weak self] in
            
            guard let sself = self else {
                return
            }
            
            main = AppBacktrace.mainThread() 
             all = AppBacktrace.allThread()
            sself.delegate?.anrEye?(anrEye: sself,
                                    catchWithThreshold: threshold,
                                    mainThreadBacktrace: main,
                                    allThreadBacktrace: all)
        }, catonLengthhandler: { [weak self]  (startTime,endTime) in
            guard let sself = self else {
                return
            }
            
//            let main = AppBacktrace.mainThread()
//            let all = AppBacktrace.allThread()
            sself.delegate?.anrEye?(anrEye: sself, startTime: startTime, endTime: endTime, catchWithThreshold: threshold, mainThreadBacktrace: main, allThreadBacktrace: all)
        })
//        self.pingThread?.start(threshold: threshold, handler: { [weak self] in
//            guard let sself = self else {
//                return
//            }
//            
//            let main = AppBacktrace.mainThread()
//            let all = AppBacktrace.allThread()
//            sself.delegate?.anrEye?(anrEye: sself,
//                                   catchWithThreshold: threshold,
//                                   mainThreadBacktrace: main,
//                                   allThreadBacktrace: all)
//            
//        })
    }
    
    open func close() {
        self.pingThread?.cancel()
    }
    
    //--------------------------------------------------------------------------
    // MARK: LIFE CYCLE
    //--------------------------------------------------------------------------
    deinit {
        self.pingThread?.cancel()
    }
    
    //--------------------------------------------------------------------------
    // MARK: PRIVATE PROPERTY
    //--------------------------------------------------------------------------
    private var pingThread: AppPingThread?
    
}

//--------------------------------------------------------------------------
// MARK: - GLOBAL DEFINE
//--------------------------------------------------------------------------
public typealias AppPingThreadCallBack = () -> Void
//卡顿时长回到
public typealias AppPingCatonLengthThreadCallBack = (Int64,Int64) -> Void

//--------------------------------------------------------------------------
// MARK: - AppPingThread
//--------------------------------------------------------------------------
private class AppPingThread: Thread {
    
    func start(threshold:Double, handler: @escaping AppPingThreadCallBack, catonLengthhandler:  @escaping AppPingCatonLengthThreadCallBack) {
        self.handler = handler
        self.threshold = threshold
        self.catonLengthhandler = catonLengthhandler
        self.start()
    }
    //线程入口
    override func main() {
        
        while self.isCancelled == false {
            self.isMainThreadBlock = true
            //是否卡顿
            var isCaton: Bool = false
            let startTime = self.currentTime()
            DispatchQueue.main.async {
                self.isMainThreadBlock = false
                //发送信号量将semaphore的值+1，这个时候其他等待中的线程就会被唤醒执行（同等优先级下随机唤醒）
                self.semaphore.signal()
            }
            
            Thread.sleep(forTimeInterval: self.threshold)
            if self.isMainThreadBlock  {
                isCaton = true
                self.handler?()
            }
            //DispatchTime.distantFuture， 等待信号量 timeout可以控制可等待的最长时间，设置为.distantFuture表示永久等待
           let _ = self.semaphore.wait(timeout: DispatchTime.distantFuture)
            //有卡顿信息才回调出去
            if isCaton {
                //如果是大于时间间隔就将时间回调出去
                let endTime = self.currentTime()
                let catonLengTime = endTime - startTime
                if catonLengTime > Int64(self.threshold * 1000) {
                    self.catonLengthhandler?(startTime,endTime)
                }
                
                print("time=%d",endTime - startTime)
            }
        }
    }
    //创建信号量 设置为0
    private let semaphore = DispatchSemaphore(value: 0)
    
    private var isMainThreadBlock = false
    
    private var threshold: Double = 0.4
    
    fileprivate var handler: (() -> Void)?
    //卡顿时长block
    fileprivate var catonLengthhandler: ((Int64,Int64) -> Void)?
    
    func currentTime() -> Int64 {
        let time = NSDate().timeIntervalSince1970 * 1000
        let timeN = NSNumber(value: time).int64Value
        return timeN
    }
    
}
