//
//  AnySubscriber+Extension.swift
//
//  Created by Vladimir Kazantsev on 10.02.2020.
//  Copyright © 2020 MC2 Software. All rights reserved.
//

import Foundation
import Combine

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
public extension Subscriber {

	/// Convenience method equivalent to `.receive( completion: .failure( Failure ) )`
	/// - parameter error: Failure to send to subscriber(s)
	func receive( error: Failure ) {
		self.receive( completion: .failure( error ) )
	}

	/// Convenience method equivalent to `receive( completion: .finished )`
	func receiveCompletion() {
		self.receive( completion: .finished )
	}
}

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension AnySubscriber: BindingTargetProvider {

	public var bindingTarget: BindingTarget<Input> {
		return BindingTarget( lifetime: .persistent ) { _ = self.receive( $0 ) }
	}
}
