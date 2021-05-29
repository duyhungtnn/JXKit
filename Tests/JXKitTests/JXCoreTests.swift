//
//  Original SwiftJS license header:
//
//  The MIT License
//  Copyright (c) 2015 - 2021 Susan Cheng. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import JXKit
import XCTest

@available(macOS 10.12, iOS 10.0, tvOS 10.0, *)
class JXCoreTests: XCTestCase {
    
    func testArrayBuffer() {
        let context = JXContext()
        
        let bytes: [UInt8] = [1, 2, 3, 4, 5, 6, 7, 8]
        context.global["buffer"] = JXValue(newArrayBufferWithBytes: bytes, in: context)
        
        XCTAssertTrue(context.global["buffer"].isArrayBuffer)
        XCTAssertEqual(context.global["buffer"].byteLength, 8)
    }
    
    func testArrayBufferWithBytesNoCopy() {
        var flag = 0
        
        do {
            let context = JXContext()
            var bytes: [UInt8] = [1, 2, 3, 4, 5, 6, 7, 8]
            
            bytes.withUnsafeMutableBytes { bytes in
                context.global["buffer"] = JXValue(
                    newArrayBufferWithBytesNoCopy: bytes,
                    deallocator: { _ in flag = 1 },
                    in: context)
                
                XCTAssertTrue(context.global["buffer"].isArrayBuffer)
                XCTAssertEqual(context.global["buffer"].byteLength, 8)
            }
        }
        
        XCTAssertEqual(flag, 1)
    }
    
    func testDataView() {
        let context = JXContext()
        
        let bytes: [UInt8] = [1, 2, 3, 4, 5, 6, 7, 8]
        context.global["buffer"] = JXValue(newArrayBufferWithBytes: bytes, in: context)
        
        context.evaluateScript("new DataView(buffer).setUint8(0, 5)")
        
        XCTAssertEqual(context["buffer"].copyBytes().map(Array.init), [5, 2, 3, 4, 5, 6, 7, 8])
    }
    
    func testSlice() {
        let context = JXContext()
        
        let bytes: [UInt8] = [1, 2, 3, 4, 5, 6, 7, 8]
        context.global["buffer"] = JXValue(newArrayBufferWithBytes: bytes, in: context)
        
        XCTAssertEqual(context.evaluateScript("buffer.slice(2, 4)").copyBytes().map(Array.init), [3, 4])
    }
    
    func testFunctionConstructor() {
        let context = JXContext()

        let myClass = JXValue(newFunctionIn: context) { context, this, arguments in

            let result = arguments[0].doubleValue! + arguments[1].doubleValue!

            let object = JXValue(newObjectIn: context)
            object["result"] = JXValue(double: result, in: context)

            return object
        }

        XCTAssertTrue(myClass.isConstructor)

        context.global["myClass"] = myClass

        let result = context.evaluateScript("new myClass(1, 2)")
        XCTAssertNil(context.currentError, "\(context.currentError!)")

        XCTAssertTrue(result.isObject)
        XCTAssertEqual(result["result"].doubleValue, 3)

        XCTAssertTrue(result.isInstance(of: myClass))
    }

    func testFunction1() {
        let context = JXContext()

        let myFunction = JXValue(newFunctionIn: context) { context, this, arguments in

            let result = arguments[0].doubleValue! + arguments[1].doubleValue!

            return JXValue(double: result, in: context)
        }

        XCTAssertTrue(myFunction.isFunction)

        let result = myFunction.call(withArguments: [JXValue(double: 1, in: context), JXValue(double: 2, in: context)])
        XCTAssertNil(context.currentError, "\(context.currentError!)")

        XCTAssertTrue(result.isNumber)
        XCTAssertEqual(result.doubleValue, 3)
    }

    func testFunction2() {
        let context = JXContext()

        let myFunction = JXValue(newFunctionIn: context) { context, this, arguments in

            let result = arguments[0].doubleValue! + arguments[1].doubleValue!

            return JXValue(double: result, in: context)
        }

        XCTAssertTrue(myFunction.isFunction)

        context.global["myFunction"] = myFunction

        let result = context.evaluateScript("myFunction(1, 2)")
        XCTAssertNil(context.currentError, "\(context.currentError!)")

        XCTAssertTrue(result.isNumber)
        XCTAssertEqual(result.doubleValue, 3)
    }

    func testCalculation() {
        let context = JXContext()

        let result = context.evaluateScript("1 + 1")
        XCTAssertNil(context.currentError, "\(context.currentError!)")

        XCTAssertTrue(result.isNumber)
        XCTAssertEqual(result.doubleValue, 2)
    }

    func testArray() {
        let context = JXContext()

        let result = context.evaluateScript("[1 + 2, \"BMW\", \"Volvo\"]")
        XCTAssertNil(context.currentError, "\(context.currentError!)")

        XCTAssertTrue(result.isArray)

        let length = result["length"]
        XCTAssertEqual(length.doubleValue, 3)

        XCTAssertEqual(result[0].doubleValue, 3)
        XCTAssertEqual(result[1].stringValue, "BMW")
        XCTAssertEqual(result[2].stringValue, "Volvo")
    }

    func testGetter() {
        let context = JXContext()

        context.global["obj"] = JXValue(newObjectIn: context)

        let desc = JSPropertyDescriptor(
            getter: { this in JXValue(double: 3, in: this.env) }
        )

        context.global["obj"].defineProperty("three", desc)

        let result = context.evaluateScript("obj.three")
        XCTAssertNil(context.currentError, "\(context.currentError!)")

        XCTAssertEqual(result.doubleValue, 3)
    }

    func testSetter() {
        let context = JXContext()

        context.global["obj"] = JXValue(newObjectIn: context)

        let desc = JSPropertyDescriptor(
            getter: { this in this["number_container"] },
            setter: { this, newValue in this["number_container"] = newValue }
        )

        context.global["obj"].defineProperty("number", desc)

        context.evaluateScript("obj.number = 5")
        XCTAssertNil(context.currentError, "\(context.currentError!)")

        XCTAssertEqual(context.global["obj"]["number"].doubleValue, 5)
        XCTAssertEqual(context.global["obj"]["number_container"].doubleValue, 5)

        context.evaluateScript("obj.number = 3")
        XCTAssertNil(context.currentError, "\(context.currentError!)")

        XCTAssertEqual(context.global["obj"]["number"].doubleValue, 3)
        XCTAssertEqual(context.global["obj"]["number_container"].doubleValue, 3)
    }
}
