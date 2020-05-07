//
//  UIControlEventPublisher.swift
//
//  Created by Vladimir Kazantsev on 20.12.2019.
//  Copyright © 2019 MC2 Software. All rights reserved.
//

#if !os(macOS)
import UIKit
import Combine

/// A custom `Publisher` to work with our custom `UIControlSubscription`.
@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
public struct UIControlEventPublisher<Control: UIControl>: Publisher {

	public typealias Output = Void
	public typealias Failure = Never

	let control: Control
	let controlEvents: UIControl.Event

	public init(control: Control, events: UIControl.Event) {
		self.control = control
		self.controlEvents = events
	}

	public func receive<S>(subscriber: S) where S : Combine.Subscriber, S.Failure == Failure, S.Input == Output {
		let subscription = UIControlSubscription(subscriber: subscriber, control: control, event: controlEvents)
		subscriber.receive(subscription: subscription)
	}
}


@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension UIControlEventPublisher {

	/// A custom subscription to capture UIControl target events.
	final class UIControlSubscription<SubscriberType: Combine.Subscriber, Control: UIControl>: Combine.Subscription where SubscriberType.Input == Void {
		private var subscriber: SubscriberType?
		private let control: Control
		private let event: UIControl.Event

		init(subscriber: SubscriberType, control: Control, event: UIControl.Event) {
			self.subscriber = subscriber
			self.control = control
			self.event = event
			control.addTarget(self, action: #selector(eventHandler), for: event)
		}

		func request(_ demand: Subscribers.Demand) {
			// We do nothing here as we only want to send events when they occur.
			// See, for more info: https://developer.apple.com/documentation/combine/subscribers/demand
		}

		func cancel() {
			control.removeTarget(self, action: #selector(eventHandler), for: event)
			subscriber = nil
		}

		@objc private func eventHandler() {
			_ = subscriber?.receive()
		}
	}
}
#endif
