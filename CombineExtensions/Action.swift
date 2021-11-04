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


/**
 Represents a value that accepts a workFactory which takes some Observable<Input> as its input
 and produces an Observable<Element> as its output.

 When this excuted via execute() or inputs subject, it passes its parameter to this closure and subscribes to the work.
 */
@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
public final class Action<Input, Output, Failure: Error> {
	public typealias WorkFactory = (Input) -> AnyPublisher<Output, Failure>

	public let workFactory: WorkFactory

	/// Bindable sink for inputs that triggers execution of action.
	public let inputs: PassthroughSubject<Input, Never>

	/// Whether or not we're currently executing.
	/// Delivered on whatever scheduler they were sent from.
	public let values: AnyPublisher<Output, Never>

	/// Errors aggrevated from invocations of execute().
	/// Delivered on whatever scheduler they were sent from.
	public let errors: AnyPublisher<Failure, Never>

	/// A signal of all failed attempts to start a unit of work of the `Action`.
	/// Delivered on whatever scheduler they were sent from.
	public let disabledErrors: AnyPublisher<Void, Never>

	/// Whether or not we're currently executing.
	public let isExecuting: Property<Bool>

	/// Observables returned by the workFactory.
	/// Useful for sending results back from work being completed
	/// e.g. response from a network call.
	public let executionObservables: AnyPublisher<AnyPublisher<Output, ActionError<Failure>>, Never>

	/// Whether or not we're enabled. Value of this property
	/// based on enabledIf initializer and if we're currently executing.
	public let isEnabled: Property<Bool>

	public convenience init<PublisherType: Publisher>(
		enabledIf: CurrentValueSubject<Bool, Never> = .init( true ),
		workFactory: @escaping (Input) -> PublisherType
	) where Output == PublisherType.Output, Failure == PublisherType.Failure {
		self.init( enabledIf: enabledIf ) {
			workFactory( $0 ).eraseToAnyPublisher()
		}
	}

	public init(
		enabledIf: CurrentValueSubject<Bool, Never> = .init( true ),
		workFactory: @escaping WorkFactory
	) {
		self.workFactory = workFactory

		let _isEnabled = CurrentValueSubject<Bool, Never>( true )
		isEnabled = Property( _isEnabled )

		let inputsSubject = PassthroughSubject<Input, Never>()
		inputs = inputsSubject

		executionObservables = inputsSubject
			.withLatest( from: _isEnabled ) { input, enabled in (input, enabled) }
			.flatMap { input, enabled -> AnyPublisher<AnyPublisher<Output, ActionError<Failure>>, Never> in
				if enabled {
					let workPublisher = workFactory( input )
						.mapError { ActionError.failed( $0 ) }
						.replayLazily()
						.eraseToAnyPublisher()
					return Just( workPublisher ).eraseToAnyPublisher()
				} else {
					return AnyPublisher( value: AnyPublisher( error: ActionError<Failure>.disabled ))
				}
			}
			.share()
			.eraseToAnyPublisher()

		values = executionObservables
			.flatMap { $0.catch { _ in Empty( completeImmediately: false ) } }
			.eraseToAnyPublisher()

		let errorsSubject = executionObservables
			.flatMap { execution -> AnyPublisher<ActionError<Failure>, Never> in
				execution
					.flatMap { _ in AnyPublisher( completeImmediately: false ) }
					.catch { AnyPublisher( value: $0 ) }
					.eraseToAnyPublisher()
			}
		errors = errorsSubject.compactMap { $0.failure }.eraseToAnyPublisher()
		disabledErrors = errorsSubject.filter { $0.isDisabled }.map { _ in () }.eraseToAnyPublisher()


		let _isExecuting = executionObservables
			.flatMap { execution -> AnyPublisher<Bool, Never> in
				let execution = execution
					.flatMap { _ in Empty<Bool, ActionError<Failure>>() }
					.catch { _ in Empty<Bool, Never>() }

				return execution
					.prepend( true )
					.append( false )
					.eraseToAnyPublisher()
			}

		isExecuting = Property( initial: false, then: _isExecuting )

		cancellables += _isEnabled <~ Publishers.CombineLatest( isExecuting.prepend( false ), enabledIf )
			.map { !$0 && $1 }
	}


	public func apply( _ input: Input ) -> AnyPublisher<Output, ActionError<Failure>> {
		defer {
			self.inputs.send( input )
		}

		let replay = ReplaySubject<Output, ActionError<Failure>>()
		cancellables += executionObservables
			.prefix( during: bindingTarget.lifetime )
			.prefix( 1 )
			.setFailureType( to: ActionError<Failure>.self )
			.flatMap { $0 }
			.sink {
				replay.send( completion: $0 )
			} receiveValue: {
				replay.send( $0 )
			}

		return AnyPublisher( replay )
	}

	public func applyIgnoringDisabled(
		_ input: Input
	) -> Publishers.Catch<AnyPublisher<Output, ActionError<Failure>>, AnyPublisher<Output, Failure>> {
		return apply( input )
			.catch { actionError -> AnyPublisher<Output, Failure> in
				switch actionError {
				case .disabled: return AnyPublisher( completeImmediately: false )
				case .failed( let error ): return AnyPublisher( error: error )
				}
			}
	}

	private var cancellables: Set<AnyCancellable> = []
}

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension Action: BindingTargetProvider {
	public var bindingTarget: BindingTarget<Input> {
		return BindingTarget( lifetime: Lifetime.of( self )) { [weak self] in self?.inputs.send( $0 ) }
	}
}


/// Possible errors from invoking execute()
@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
public enum ActionError<Failure: Error>: Error {
	case disabled
	case failed( Failure )
}

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension ActionError {
	public var failure: Failure? { if case .failed( let failure ) = self { return failure }; return nil }
	public var isDisabled: Bool { if case .disabled = self { return true }; return false }
}

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension ActionError: Equatable where Failure: Equatable {
	public static func == (lhs: ActionError<Failure>, rhs: ActionError<Failure>) -> Bool {
		switch (lhs, rhs) {
		case (.disabled, .disabled): return true
		case let (.failed( left ), .failed( right )): return left == right
		default: return false
		}
	}
}
