//
//  -=Combine Extensions=-
//
// MIT License
//
// Copyright (c) 2019-present Vladimir Kazantsev
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation
import Combine

/// A scheduler that executes its work on the main queue as soon as possible.
///
/// This scheduler is inspired by the
/// [equivalent](https://github.com/ReactiveCocoa/ReactiveSwift/blob/58d92aa01081301549c48a4049e215210f650d07/Sources/Scheduler.swift#L92)
/// scheduler in the [ReactiveSwift](https://github.com/ReactiveCocoa/ReactiveSwift) project.
///
/// If `UIScheduler.shared.schedule` is invoked from the main thread then the unit of work will be
/// performed immediately. This is in contrast to `DispatchQueue.main.schedule`, which will incur
/// a thread hop before executing since it uses `DispatchQueue.main.async` under the hood.
///
/// This scheduler can be useful for situations where you need work executed as quickly as
/// possible on the main thread, and for which a thread hop would be problematic, such as when
/// performing animations.
@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public struct UIScheduler: Scheduler {
	public typealias SchedulerOptions = Never
	public typealias SchedulerTimeType = DispatchQueue.SchedulerTimeType

	public var now: SchedulerTimeType { DispatchQueue.main.now }
	public var minimumTolerance: SchedulerTimeType.Stride { DispatchQueue.main.minimumTolerance }

	public init() {}

	public func schedule(
		options: SchedulerOptions? = nil,
		_ action: @escaping () -> Void
	) {
		// On iOS prior to 13.4 this line causes crash.
		if Thread.isMainThread, #available( iOS 13.4, * ) {
			action()
		} else {
			DispatchQueue.main.schedule(action)
		}
	}

	public func schedule(
		after date: SchedulerTimeType,
		tolerance: SchedulerTimeType.Stride,
		options: SchedulerOptions? = nil,
		_ action: @escaping () -> Void
	) {
		DispatchQueue.main.schedule(after: date, tolerance: tolerance, options: nil, action)
	}

	public func schedule(
		after date: SchedulerTimeType,
		interval: SchedulerTimeType.Stride,
		tolerance: SchedulerTimeType.Stride,
		options: SchedulerOptions? = nil,
		_ action: @escaping () -> Void
	) -> Cancellable {
		DispatchQueue.main.schedule(
			after: date, interval: interval, tolerance: tolerance, options: nil, action
		)
	}
}
