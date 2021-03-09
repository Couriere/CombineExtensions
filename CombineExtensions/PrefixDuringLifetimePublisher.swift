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
public extension Publisher {

	func prefix( during lifetime: Lifetime ) -> Publishers.PrefixDuringLifetimePublisher<Self> {
		return Publishers.PrefixDuringLifetimePublisher( upstream: self, lifetime: lifetime )
	}
}


@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
public extension Publishers {

	struct PrefixDuringLifetimePublisher<Upstream>: Publisher where Upstream : Publisher {

		/// The kind of values published by this publisher.
		public typealias Output = Upstream.Output

		/// The kind of errors this publisher might publish.
		///
		/// Use `Never` if this `Publisher` does not publish errors.
		public typealias Failure = Upstream.Failure

		/// The publisher from which this publisher receives elements.
		public let upstream: Upstream

		/// Lifetime of an object. After expiring, `completed` signal is sent upstream.
		public let lifetime: Lifetime

		public init( upstream: Upstream, lifetime: Lifetime ) {
			self.upstream = upstream
			self.lifetime = lifetime
		}

		public func receive<SubscriberType>( subscriber: SubscriberType ) where
			SubscriberType : Subscriber,
			Upstream.Failure == SubscriberType.Failure,
			Upstream.Output == SubscriberType.Input {
				let subscription = PrefixDuringLifetimeSubscription( upstream: upstream,
																	 lifetime: lifetime,
																	 subscriber: subscriber )
				subscriber.receive( subscription: subscription )
		}
	}
}

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
public extension Publishers.PrefixDuringLifetimePublisher {

	final class PrefixDuringLifetimeSubscription<SubscriberType: Subscriber>: Combine.Subscription where
	SubscriberType.Input == Output, Failure == SubscriberType.Failure {

		init( upstream: Upstream, lifetime: Lifetime, subscriber: SubscriberType ) {
			self.upstream = upstream
			self.lifetime = lifetime
			self.subscriber = subscriber

			guard !lifetime.hasEnded else {
				cancel()
				return
			}

			lifetime.observeEnded {
				self.cancel()
			}
		}
		deinit {
			Swift.print()
		}

		public func request( _ demand: Subscribers.Demand ) {
			// Ignore demand.
			guard subscription == nil else { return }

			subscription = upstream.sink( receiveCompletion: { completion in
				self.subscriber?.receive( completion: completion )
				self.subscriber = nil
			}, receiveValue: { value in
				_ = self.subscriber?.receive( value )
			})
		}

		public func cancel() {
			self.subscription?.cancel()
			self.subscriber?.receiveCompletion()
			self.subscriber = nil
		}

		private var subscriber: SubscriberType?
		private let upstream: Upstream
		private let lifetime: Lifetime
		private var subscription: AnyCancellable?
	}
}
