//
//  MSGCDTimer.swift
//  ProjectDetail
//
//  Created by guoxiaoliang on 2018/4/23.
//  Copyright © 2018年 LuoJieFeng. All rights reserved.
//GCD定时器

import Foundation

/// timer类
public class MSGCDTimer: NSObject {

    /// 定时器状态
    ///
    /// - paused: //暂停
    /// - running: //运行
    /// - executing: //执行:观察员正在执行
    /// - finished: //结束
    public enum State: Equatable, CustomStringConvertible {
        case paused
        case running
        case executing
        case finished

        public static func == (lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.paused, .paused),
                 (.running, .running),
                 (.executing, .executing),
                 (.finished, .finished):
                return true
            default:
                return false
            }
        }
        /// 返回“true”如果当前计时器运行,包括当观察员正在执行。
        public var isRunning: Bool {
            guard self == .running || self == .executing else { return false }
            return true
        }

        /// 返回“true”如果观察员正在执行。
        public var isExecuting: Bool {
            guard case .executing = self else { return false }
            return true
        }

        /// 定时器是否已经完成
        /// It return always `false` for infinite timers.
        /// It return `true` for `.once` mode timer after the first fire,
        /// and when `.remainingIterations` is zero for `.finite` mode timers
        public var isFinished: Bool {
            guard case .finished = self else { return false }
            return true
        }
        ///状态描述
        public var description: String {
            switch self {
            case .paused: return "idle/paused"
            case .finished: return "finished"
            case .running: return "running"
            case .executing: return "executing"
            }
        }
    }

    /// Repeat interval,时间间隔
    ///
    /// - nanoseconds: 纳秒
    /// - microseconds: 微妙
    /// - milliseconds: 毫秒
    /// - seconds: 秒数
    /// - hours: 小时数
    /// - days: 天数
    public enum Interval {
        case nanoseconds(_: Int)
        case microseconds(_: Int)
        case milliseconds(_: Int)
        case seconds(_: Double)
        case hours(_: Int)
        case days(_: Int)

        internal var value: DispatchTimeInterval {
            switch self {
            case .nanoseconds(let value):    return .nanoseconds(value)
            case .microseconds(let value):    return .microseconds(value)
            case .milliseconds(let value):    return .milliseconds(value)
            case .seconds(let value):      return .milliseconds(Int( Double(value) * Double(1000)))
            case .hours(let value):        return .seconds(value * 3600)
            case .days(let value):        return .seconds(value * 86400)
            }
        }
    }

    /// 定时器模式
    /// - infinite: 无限循环
    /// - finite: 有限次数循环
    /// - once: 单个执行
    public enum Mode {
        case infinite
        case finite(_: Int)
        case once

        /// 定时器是否循环
        internal var isRepeating: Bool {
            switch self {
            case .once: return false
            default:  return true
            }
        }

        /// 循环次数
        public var countIterations: Int? {
            switch self {
            case .finite(let counts):  return counts
            default:          return nil
            }
        }

        /// 是否无限的计时器
        public var isInfinite: Bool {
            guard case .infinite = self else {
                return false
            }
            return true
        }
    }

    /// 回调block类型
    public typealias Observer = ((MSGCDTimer) -> Void)
    /// 存储观察者block 的标识
    public typealias ObserverToken = UInt64

    /// C当前状态的计时器
    public fileprivate(set) var state: State = .paused {
        didSet {
            ///监听状态改变,block回调出去
            self.onStateChanged?(self, state)
        }
    }

    /// 计时器状态改变回调,监听状态和timer回调出去
    public var onStateChanged: ((_ timer: MSGCDTimer, _ state: State) -> Void)?

    /// 计时器观察者列表,字典保存,一一对应保存block
    fileprivate var observers = [ObserverToken: Observer]()
    /// 定时器的间隔,隔多久调用一次
    public fileprivate(set) var interval: Interval
    ///  定时器的精度,允许误差
    fileprivate var tolerance: DispatchTimeInterval
    ///  下一个定时器的标识
    fileprivate var nextObserverID: UInt64 = 0
    /// 内部GCD定时器
    fileprivate var timer: DispatchSourceTimer?
    /// 定时器模式
    public fileprivate(set) var mode: Mode
    /// 剩余数量的重复计数
    public fileprivate(set) var remainingIterations: Int
    /// 定时器调度队列
    fileprivate var queue: DispatchQueue?
    
    ///////////////////////////Objective-C Bridge /////////////////////////////////////////////////
    /// 初始化定时器 (提供给OC使用的方法。)
    ///
    /// - Parameters:
    ///   - interval: 时间间隔
    ///   - mode: 定时器模式 （-2: 无限循环， -1: 执行一次，X>0 : 执行X次）
    ///   - tolerance: 定时器误差,默认是0
    ///   - queue: 定时器执行队列,为nil重新创建一个新队列.
    ///   - observer: 观察者,处理时间block
    @objc public convenience init(seconds: Double, modeOption: Int , tolerance: Int , queue: DispatchQueue? , observer: @escaping Observer) {
        var mode: Mode = .infinite
        if modeOption == -2 {
            mode = .infinite
        }else if (modeOption == -1) {
            mode = .once
        }else if (modeOption > 0) {
            mode = .finite(modeOption)
        }else {
            //printlog("参数定时器模式错误")
        }
        self.init(interval: Interval.seconds(seconds),
                  mode: mode,
                  tolerance: DispatchTimeInterval.seconds(tolerance),
                  queue: queue,
                  observer: observer)
    }
    /////////////////////////////////////////////////////////////////////////////////////////////
    
    /// 初始化定时器
    ///
    /// - Parameters:
    ///   - interval: 时间间隔
    ///   - mode: 定时器模式
    ///   - tolerance: 定时器误差,默认是0
    ///   - queue: 定时器执行队列,为nil重新创建一个新队列.
    ///   - observer: 观察者,处理时间block
    public init(interval: Interval, mode: Mode = .infinite, tolerance: DispatchTimeInterval = .seconds(0), queue: DispatchQueue? = nil , observer: @escaping Observer) {
        self.mode = mode
        self.remainingIterations = (mode.countIterations ?? 0)
        self.interval = interval
        self.tolerance = tolerance
        self.queue = (queue ?? DispatchQueue(label: "com.tuandai.queue"))
        super.init()
        self.timer = configureTimer()
        self.observe(observer)
    }
    ///初始化timer
    fileprivate func configureTimer() -> DispatchSourceTimer {

        ///创建timer,queue:指定线程
        let timer = DispatchSource.makeTimerSource(flags: [], queue: (queue ?? DispatchQueue(label: "com.tuandai.queue")))
        let repeatInterval = interval.value
        let deadline: DispatchTime = (DispatchTime.now() + repeatInterval)
        if self.mode.isRepeating {//是否是重复倒计时
            /**
             wallDeadline: 什么时候开始
             leeway: 调用频率,即多久调用一次
             */
            //循环执行，deadline时间开始，interval:时间间隔,leeway:允许的误差
            timer.scheduleRepeating(deadline: deadline, interval: repeatInterval, leeway: tolerance)
            //swift4.0
//            timer.schedule(deadline: deadline, repeating: repeatInterval, leeway: tolerance)
        } else {
            //单次执行,deadline时间开始,leeway:允许误差
            timer.scheduleOneshot(deadline: deadline, leeway: tolerance)
            //swift4.0
//            timer.schedule(deadline: deadline, leeway: tolerance)
        }
        //执行timer
        timer.setEventHandler { [weak self] in
            if let unwrapped = self {
                unwrapped.timeFired()
            }
        }
        return timer
    }


    /// 销毁当前定时器
    fileprivate func destroyTimer() {
        self.timer?.setEventHandler(handler: nil)
        self.timer?.cancel()//取消(异步的取消，会保证当前eventHander执行完)

        if state == .paused || state == .finished {
            self.timer?.resume()//继续
        }
    }


    /// 调用计时器回调
    fileprivate func timeFired() {
        self.state = .executing
        switch self.mode {
        case .finite:
            // 有限次数循环
            self.remainingIterations -= 1
        default:
            break
        }
        // 循环遍历所有处理事件block 回调出去
        self.observers.values.forEach { $0(self) }
        // 管理定时器生命周期
        switch self.mode {
        case .once:
            // 执行一次
            self.setPause(from: .executing, to: .finished)
        case .finite:
            if self.remainingIterations == 0 {
                // 如果计数remainingIterations==0 暂停定时器和停止
                self.setPause(from: .executing, to: .finished)
            }
        case .infinite:
            // 无限循环
            break
        }
    }
    deinit {
        self.observers.removeAll()
        self.destroyTimer()
        //printlog("MSGCDTimer--deinit")
    }
}

// MARK: - 类方法
extension MSGCDTimer {
    /// 创建和安排一个定时器在指定的时间后将调用处理程序
    ///
    /// - Parameters:
    ///   - interval: 时间间隔interval调用
    ///   - handler: 处理事件回调
    /// - Returns: 返回新定时器
    @discardableResult
    public class func once(after interval: Interval, _ observer: @escaping Observer) -> MSGCDTimer {
        let timer = MSGCDTimer(interval: interval, mode: .once, observer: observer)
        timer.start()
        return timer
    }

    /// 创建和安排一个定时器,在间隔interval时间调用count次
    ///
    /// - Parameters:
    ///   - interval: 调用时间间隔
    ///   - count: 调用次数,如果为nil或者0 则是无限调用
    ///   - handler: 处理事件回调
    /// - Returns: 返回新定时器
    @discardableResult
    public class func every(_ interval: Interval, count: Int? = nil, _ handler: @escaping Observer) -> MSGCDTimer {
        var mode: Mode = .infinite
        if let count1 = count , count1 > 0 {
            mode = .finite(count1)
        }
        let timer = MSGCDTimer(interval: interval, mode: mode, observer: handler)
        timer.start()
        return timer
    }
}

// MARK: - 对象方法
extension MSGCDTimer {

    /// 添加新的监听者到定时器中.
    ///
    /// - Parameter callback: 触发事件回调
    /// - Returns: 标识,方便移除监听者
    @discardableResult
    public func observe(_ observer: @escaping Observer) -> ObserverToken {
        var (new, overflow) = self.nextObserverID.addingReportingOverflow(1)
        //返回nextObserverID和给定值1的总和new, overflow:是否发生溢出
        if overflow { // 发生溢出,重新赋值0
            self.nextObserverID = 0
            new = 0
        }
        self.nextObserverID = new
        self.observers[new] = observer
        return new
    }
    /// 移除一个计时器
    /// - Parameter id: 标识,对应的计时器
    public func remove(observer identifier: ObserverToken) {
        self.observers.removeValue(forKey: identifier)
    }

    /// 移除所有的计时器
    /// - Parameter stopTimer: 是否暂停定时器
    public func removeAllObservers(thenStop stopTimer: Bool = false) {
        self.observers.removeAll()
        if stopTimer {
            self.pause()
        }
    }



    /// 执行定时器,立即执行回调block
    ///pause:true 表示执行一次就暂停,false:继续执行
    public func fire(andPause pause: Bool = false) {
        self.timeFired()
        if pause == true {
            self.pause()
        }
    }

    /// 重置计时器
    ///
    /// - Parameters:
    ///   - interval: 新的时间间隔,为nil,就取最新的时间间隔,上一次的时间将
    ///   - restart: 是否重新启动定时器,true:是
    public func reset(_ interval: Interval?, restart: Bool = true) {
        if self.state.isRunning {//定时器正在运行中
            self.setPause(from: self.state)//暂停定时器
        }

        // 当前定时器剩余次数重新赋值
        if case .finite(let count) = self.mode {
            self.remainingIterations = count
        }
        // 如果有新的时间间隔,赋值新的时间间隔
        if let newInterval = interval {
            self.interval = newInterval
        }
        //重置定时器
        self.destroyTimer()
        self.timer = configureTimer()
        self.state = .paused

        if restart {
            self.timer?.resume()
            self.state = .running
        }
    }

    /// 定时器开始,如果定时器已经运行它什么都不做。
    @discardableResult
    @objc public func start() -> Bool {
        guard self.state.isRunning == false else {
            //如果正在开始,就什么都不做
            return false
        }

        // If timer has not finished its lifetime we want simply
        // restart it from the current state.
        guard self.state.isFinished == true else {
            //定时器没有完成状态,继续之前间隔时间
            //如果不是定时器生命结束,还会继续之前的倒计时间隔继续,
            self.state = .running
            //继续倒计时
            self.timer?.resume()
            return true
        }

        // 表示已经完成了或者不是在运行中状态
        // 需要重置状态再次启动它。
        self.reset(nil, restart: true)
        return true
    }

    /// 暂停运行的定时器。如果定时器时暂停就什么都不做。
    @discardableResult
    public func pause() -> Bool {
        guard state != .paused && state != .finished else {
            return false
        }

        return self.setPause(from: self.state)
    }

    /// 暂停运行计时器 有选择地改变 状态关于当前状态
    ///改变定时器状态,从状态currentState改变成newState,newState:默认是暂停状态,挂起定时器
    /// - Returns: 如果定时器暂停返回true
    @discardableResult
    fileprivate func setPause(from currentState: State, to newState: State = .paused) -> Bool {
        guard self.state == currentState else {//如果当前状态跟currentState不一致,就什么都不处理
            return false
        }
        //挂起定时器
        self.timer?.suspend()
        //赋值新状态
        self.state = newState
        return true
    }
}
