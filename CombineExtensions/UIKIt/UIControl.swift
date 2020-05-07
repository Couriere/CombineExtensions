//
//  UIControl.swift
//
//  Created by Vladimir Kazantsev on 06.02.2020.
//  Copyright © 2020 MC2 Software. All rights reserved.
//

#if !os(macOS)
import UIKit
import Combine

@available(iOS 13, tvOS 13, watchOS 6, *)
public extension Reactive where Base: UIControl {

	func publisher(for events: UIControl.Event) -> UIControlEventPublisher<Base> {
		return UIControlEventPublisher(control: base, events: events)
	}

	var isEnabled: BindingTarget<Bool> {
		return makeUIBindingTarget { $0.isEnabled = $1 }
	}

	var isSelected: BindingTarget<Bool> {
		return makeUIBindingTarget { $0.isSelected = $1 }
	}

	func mapControlEvents<Value>( _ controlEvents: UIControl.Event,
										 _ transform: @escaping (Base) -> Value) -> AnyPublisher<Value, Never> {
		UIControlEventPublisher( control: base, events: controlEvents )
			.map { transform( self.base ) }
			.eraseToAnyPublisher()
	}
}
#endif
