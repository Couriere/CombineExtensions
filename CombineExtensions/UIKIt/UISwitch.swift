//
//  UISwitch.swift
//
//  Created by Vladimir Kazantsev on 06.02.2020.
//  Copyright © 2020 MC2 Software. All rights reserved.
//

#if !os(macOS)
import UIKit
import Combine


@available(iOS 13, tvOS 13, watchOS 6, *)
@available(tvOS, unavailable)
public extension Reactive where Base: UISwitch {

	func valueChangedPublisher() -> AnyPublisher<Bool, Never> {
		return mapControlEvents( .valueChanged ) { $0.isOn }
	}

	var isOn: BindingTarget<Bool> {
		return makeBindingTarget { $0.isOn = $1 }
	}
}

#endif
