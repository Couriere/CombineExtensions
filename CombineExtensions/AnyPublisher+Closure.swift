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

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
public extension AnyPublisher {

	init( _ closure: @escaping ( AnySubscriber<Output, Failure>, Lifetime ) -> Void ) {
		let publisher = Publishers.ClosurePublisher( closure: closure )
		self.init( publisher )
	}
}


@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
public extension Publishers {

	struct ClosurePublisher<Output, Failure>: Publisher where Failure: Error {

		public typealias InitClosure = ( AnySubscriber<Output, Failure>, Lifetime ) -> Void

		private let closure: InitClosure

		public init( closure: @escaping InitClosure ) {
			self.closure = closure
		}

		public func receive<SubscriberType>( subscriber: SubscriberType ) where
			SubscriberType : Subscriber,
			ClosurePublisher.Failure == SubscriberType.Failure,
			ClosurePublisher.Output == SubscriberType.Input {
				let subscription = ClosurePublisherSubscription( subscriber: subscriber, closure: closure )
				subscriber.receive( subscription: subscription )
		}
	}
}

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
public extension Publishers.ClosurePublisher {

	final class ClosurePublisherSubscription<SubscriberType: Subscriber>: Combine.Subscription where
		SubscriberType.Input == Output, Failure == SubscriberType.Failure {

		init( subscriber: SubscriberType, closure: @escaping InitClosure ) {
			self.subscriber = subscriber
			let observer = AnySubscriber<Output, Failure>(
				receiveSubscription: nil,
				receiveValue: { [weak self] value in
					return self?.subscriber?.receive( value ) ?? .none },
				receiveCompletion: { [weak self] completion in
					self?.subscriber?.receive( completion: completion ) }
			)
			closure( observer, lifetime.lifetime )
		}

		public func request( _ demand: Subscribers.Demand ) {
			// Ignore demand.
		}

		public func cancel() {
			self.subscriber = nil
			lifetime.token.cancel()
		}

		private var subscriber: SubscriberType?
		private let lifetime = Lifetime.make()
	}
}
