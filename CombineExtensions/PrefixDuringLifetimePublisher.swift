//
//  PrefixDuringLifetimePublisher.swift
//  CombineExtensions
//
//  Created by Vladimir Kazantsev on 23.04.2020.
//  Copyright © 2020 MC2 Software. All rights reserved.
//

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
				self.subscriber?.receiveCompletion()
				self.subscriber = nil
				return
			}

			lifetime.observeEnded {
				self.subscriber?.receiveCompletion()
				self.subscriber = nil
			}
		}

		public func request( _ demand: Subscribers.Demand ) {
			// Ignore demand.
			guard subscription == nil else { return }

			subscription = upstream.sink( receiveCompletion: { completion in
				self.subscriber?.receive( completion: completion )
				self.subscription = nil
			}, receiveValue: { value in
				_ = self.subscriber?.receive( value )
			})
		}

		public func cancel() {
			self.subscriber = nil
		}

		private var subscriber: SubscriberType?
		private let upstream: Upstream
		private let lifetime: Lifetime
		private var subscription: AnyCancellable?
	}
}

