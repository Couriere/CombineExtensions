//
//  Property.swift
//
//  Created by Vladimir Kazantsev on 25.02.2021.
//

import Combine
import Foundation

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
@propertyWrapper
public class MutableProperty<Output> {

	public typealias Failure = Never

	public var value: Output {
		get { underlyingSubject.value }
		set { underlyingSubject.value = newValue }
	}

	public var wrappedValue: Output {
		get { underlyingSubject.value }
		set { underlyingSubject.value = newValue }
	}

	public var projectedValue: MutableProperty<Output> { self }

	public let underlyingSubject: CurrentValueSubject<Output, Never>

	public init( _ initialValue: Output ) {
		self.underlyingSubject = CurrentValueSubject( initialValue )
	}

	public convenience init( wrappedValue: Output ) {
		self.init( wrappedValue )
	}
}

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension MutableProperty: BindingTargetProvider {

	public var bindingTarget: BindingTarget<Output> {
		return BindingTarget( lifetime: Lifetime.of( self )) { self.underlyingSubject.value = $0 }
	}
}
