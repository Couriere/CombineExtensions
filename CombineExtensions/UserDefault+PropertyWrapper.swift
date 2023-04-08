//
//  UserDefault+PropertyWrapper.swift
//
//  Created by Vladimir Kazantsev on 30.08.2020.
//

import Foundation
import SwiftUI
import Combine

/// Property wrapper around Codable values backed by UserDefaults.
///
/// Usage:
/// ```
/// @UserDefault( "valueVariable", defaultValue: -1 ) var valueVariable: Int
///
///	@UserDefault( "optionalValueVariable",
///				  defaultValue: nil,
///				  suiteName: nonStandardUserDefaultsSuiteName )
///	var optionalValueVariable: Double?
/// ```
///
/// - note: Since actual data stored in UserDefaults is encoded data, representing
/// value, you can't simply get value back with usual `.object( forKey: )`, `.int( forKey: )` etc.
/// -
/// _However_, to support seamless upgrade, if there is value in UserDefaults,
/// stored by standard means, it will be correctly read.
///
/// - remark: This version supports Combine. Signals will be sent on
/// every change of underlying UserDefault value.
/// ```
///	_optionalValueVariable.publisher
///		.sink { print( $0 ) }
/// ```
///
@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
@propertyWrapper
public struct UserDefault<Value: Codable>: DynamicProperty {

	/// Key used to store values in UserDefaults.
	private let key: String

	/// Default value. Will be returned if value with `key` is not defined in UserDefaults.
	private let defaultValue: Value

	/// UserDefaults suite used to store values. Defaults to `UserDefaults.standard`.
	private let store: UserDefaults

	@ObservedObject private var changeTrigger: _TriggerPublisher

	public init( wrappedValue: Value, _ key: String, store: UserDefaults? = nil ) {
		self.key = key
		self.defaultValue = wrappedValue
		self.store = store ?? .standard

		let observer = _KVO( object: self.store, keyPath: key )
		self.observer = observer
		self.changeTrigger = _TriggerPublisher( triggerPublisher: observer.signal )
	}

	public init( wrappedValue: Value, _ key: String, storeName: String? ) {
		self.init( wrappedValue: wrappedValue, key, store: UserDefaults( suiteName: storeName ) ?? .standard )
	}

	@available( *, deprecated, message: "Use `init(wrapped:_:storeName)` instead" )
	public init( _ key: String, defaultValue: Value, suiteName: String? = nil ) {
		self.init( wrappedValue: defaultValue, key, store: UserDefaults( suiteName: suiteName ) ?? .standard )
	}

	public func remove() {
		store.removeObject( forKey: key )
	}

	public var exists: Bool {
		store.value( forKey: key ) != nil
	}

	public var wrappedValue: Value {
		get { getValue() }
		nonmutating set { setValue( newValue ) }
	}

	public var projectedValue: UserDefault<Value> {
		return self
	}

	public var binding: Binding<Value> {
		Binding( get: getValue, set: setValue )
	}

	public var publisher: AnyPublisher<Value, Never> {
		observer.signal
			.map { self.wrappedValue }
			.prepend( self.wrappedValue )
			.eraseToAnyPublisher()
	}


	// MARK: - Internals

	private func getValue() -> Value {
		guard let rawData = store.object( forKey: key ) else { return defaultValue }

		if let data = rawData as? Data,
		   let value = try? _userDefaults_decoder.decode( Value.self, from: data ) {
			return value
		}

		return rawData as? Value ?? defaultValue
	}

	private func setValue( _ newValue: Value ) {
		if newValue is __PropertyList {
			store.set( newValue, forKey: key )
		} else {
			let data = try! _userDefaults_encoder.encode( newValue )
			store.set( data, forKey: key )
		}
	}



	private let observer: _KVO

	private class _KVO: NSObject {

		let signal = PassthroughSubject<Void, Never>()

		init( object: NSObject, keyPath: String ) {
			self.object = object
			self.keyPath = keyPath

			super.init()

			object.addObserver( self, forKeyPath: keyPath, options: .new, context: nil )
		}
		deinit {
			object.removeObserver( self, forKeyPath: keyPath )
		}

		override func observeValue(
			forKeyPath keyPath: String?,
			of object: Any?,
			change: [NSKeyValueChangeKey : Any]?,
			context: UnsafeMutableRawPointer?
		) {
			if keyPath == self.keyPath, change?[ .newKey ] != nil {
				signal.send(())
			}
		}

		private let object: NSObject
		private let keyPath: String
	}
}

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension UserDefault where Value : ExpressibleByNilLiteral {

	public init(_ key: String, store: UserDefaults? = nil) where Value: Codable {
		self.init( wrappedValue: nil, key, store: store )
	}
	public init(_ key: String, storeName: String? ) where Value: Codable {
		self.init( wrappedValue: nil, key, storeName: storeName )
	}
}

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
private extension UserDefault {

	final class _TriggerPublisher: ObservableObject {
		var cancellable: AnyCancellable?
		init<P: Publisher>( triggerPublisher: P ) where P.Failure == Never {
			cancellable = triggerPublisher.sink { [unowned self] _ in
				self.objectWillChange.send()
			}
		}
	}
}

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension UserDefault: BindingTargetProvider {

	public var bindingTarget: BindingTarget<Value> {
		return BindingTarget( lifetime: .persistent ) {
			wrappedValue = $0
		}
	}
}

private let _userDefaults_encoder = JSONEncoder()
private let _userDefaults_decoder = JSONDecoder()

private protocol __PropertyList {}
extension Bool: __PropertyList { }
extension Date: __PropertyList { }
extension String: __PropertyList { }

extension Int: __PropertyList { }
extension Int8: __PropertyList { }
extension Int16: __PropertyList { }
extension Int32: __PropertyList { }
extension Int64: __PropertyList { }
extension UInt: __PropertyList { }
extension UInt8: __PropertyList { }
extension UInt16: __PropertyList { }
extension UInt32: __PropertyList { }
extension UInt64: __PropertyList { }
extension Float: __PropertyList { }
extension Double: __PropertyList { }

extension CGPoint: __PropertyList { }
extension CGVector: __PropertyList { }
extension CGSize: __PropertyList { }
extension CGRect: __PropertyList { }
extension CGAffineTransform: __PropertyList { }
