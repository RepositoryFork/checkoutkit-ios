//
//  CheckoutKitTests.swift
//  CheckoutKitTests
//
//  Created by Manon Henrioux on 26/08/2015.
//  Copyright (c) 2015 Checkout.com. All rights reserved.
//

import UIKit
import XCTest
import CheckoutKit
import Nimble

class CardValidatorTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testValidateCardNumber() {
        XCTAssertTrue(CardValidator.validateCardNumber("4242424242424242"))
        XCTAssertTrue(CardValidator.validateCardNumber("4242-42424242-4242"))
        XCTAssertTrue(CardValidator.validateCardNumber("4242 4242 4242 4242"))
        XCTAssertTrue(CardValidator.validateCardNumber("378282246310005"))
        XCTAssertTrue(CardValidator.validateCardNumber("5555 5555 5555 4444"))
        XCTAssertFalse(CardValidator.validateCardNumber("4242-1111-8887-1111"))
        XCTAssertFalse(CardValidator.validateCardNumber("1234asd"))
    }

    func testGetCardType() {
        expect(CardInfo.VISA).to(equal(CardValidator.getCardType("4543474002249996")!))
        expect(CardInfo.VISA).to(equal(CardValidator.getCardType("4242-4242-4242-4242")!))
        expect(CardInfo.VISA).to(equal(CardValidator.getCardType("4543474002249996")!))
        expect(CardInfo.AMEX).to(equal(CardValidator.getCardType("378282246310005")!))
        expect(CardInfo.AMEX).to(equal(CardValidator.getCardType("345678901234564")!))
        expect(CardInfo.MASTERCARD).to(equal(CardValidator.getCardType("5555 5555 5555 4444")!))
        expect(CardInfo.MASTERCARD).to(equal(CardValidator.getCardType("5436031030606378")!))
        expect(CardInfo.DINERSCLUB).to(equal(CardValidator.getCardType("30123456789019")!))
        expect(CardInfo.JCB).to(equal(CardValidator.getCardType("3530111333300000")!))
        expect(CardInfo.DISCOVER).to(equal(CardValidator.getCardType("6011111111111117")!))
    }

    func testValidateExpiryDate() {
        expect(CardValidator.validateExpiryDate("02", year: "2020")).to(beTrue())
        expect(CardValidator.validateExpiryDate("02", year: "35")).to(beTrue())
        expect(CardValidator.validateExpiryDate("02", year: "15")).to(beFalse())
        expect(CardValidator.validateExpiryDate("02", year: "1999")).to(beFalse())
        expect(CardValidator.validateExpiryDate(02, year: 2020)).to(beTrue())
        expect(CardValidator.validateExpiryDate(02, year: 35)).to(beTrue())
        expect(CardValidator.validateExpiryDate(02, year: 15)).to(beFalse())
        expect(CardValidator.validateExpiryDate(12, year: 1999)).to(beFalse())
        expect(CardValidator.validateExpiryDate("02", year: "2020")).to(beTrue())
        expect(CardValidator.validateExpiryDate("02", year: "2020")).to(beTrue())
    }

    func testValidateCVV() {
        expect(CardValidator.validateCVV("123", card: CardInfo.VISA)).to(beTrue())
        expect(CardValidator.validateCVV("1234", card: CardInfo.AMEX)).to(beTrue())
        expect(CardValidator.validateCVV(123, card: CardInfo.VISA)).to(beTrue())
        expect(CardValidator.validateCVV(1234, card: CardInfo.AMEX)).to(beTrue())
        expect(CardValidator.validateCVV("", card: CardInfo.MAESTRO)).to(beFalse())
    }

}

class CheckoutKitTests: XCTestCase {
    
    let cps: [CardProvider] = [CardProvider(id: "cp_1", name: "VISA", cvvRequired: true), CardProvider(id: "cp_2", name: "MASTERCARD", cvvRequired: true), CardProvider(id: "cp_3", name: "AMEX", cvvRequired: true), CardProvider(id: "cp_4", name: "DISCOVER", cvvRequired: true), CardProvider(id: "cp_5", name: "DINERSCLUB", cvvRequired: true)]
    let cd: CustomerDetails = CustomerDetails(address1: "100 test street", address2: "", postCode: "E1", country: "UK", city: "London", state: "", phoneNumber: "44", phoneCountryCode: "00000000")
    
    func testWrongPublicKey() {
        CheckoutKit.destroy()
        expect { try CheckoutKit.getInstance("pk_test_6ff46046-30af-41d9-bf58-929022d2") }.to(throwError(errorType: CheckoutError.self))
    }
    
    func testWrongCardNumber() {
        expect{ try Card(name: "", number: "4242424242424252", expYear: "19", expMonth: "6", cvv: "100", billingDetails: self.cd) }.to(throwError(errorType: CardError.self))
    }
    
    func testWrongExpiryDate() {
        expect{ try Card(name: "", number: "4242424242424242", expYear: "1999", expMonth: "2", cvv: "100", billingDetails: self.cd) }.to(throwError(errorType: CardError.self))
    }
    
    func testWrongCVV() {
        expect{ try Card(name: "", number: "4242424242424242", expYear: "18", expMonth: "9", cvv: "10000", billingDetails: self.cd) }.to(throwError(errorType: CardError.self))
    }
    
    func testGetCardProviders() {
        var err: NSError?
        var ck: CheckoutKit?
        do {
            ck = try CheckoutKit.getInstance("pk_test_6ff46046-30af-41d9-bf58-929022d2cd14")
        } catch let error as NSError {
            err = error
            ck = nil
        }
        expect(err).to(beNil())
        ck!.getCardProviders({(resp: Response<CardProviderResponse>) -> Void in
            expect(resp.hasError).to(beFalse())
            expect(resp.httpStatus).to(equal(200))
            expect(resp.model).toNot(beNil())
            expect(resp.model!.count).to(equal(self.cps.count))
            for i in 0  ..< self.cps.count {
                expect(resp.model!.data[i]).to(equal(self.cps[i]))
            }
        })
    }
    
    func testCreateCardToken() {
        var err: NSError?
        var ck: CheckoutKit?
        do {
            ck = try CheckoutKit.getInstance("pk_test_6ff46046-30af-41d9-bf58-929022d2cd14")
        } catch let error as NSError {
            err = error
            ck = nil
        }
        expect(err).to(beNil())
        var c: Card?
        do {
            c = try Card(name: "", number: "4242424242424242", expYear: "20", expMonth: "6", cvv: "100", billingDetails: cd)
        } catch let error as NSError {
            err = error
            c = nil
        }
        expect(err).to(beNil())
        ck!.createCardToken(c!, completion: {(resp: Response<CardTokenResponse>) -> Void in
            expect(resp.hasError).to(beFalse())
            expect(resp.httpStatus).to(equal(200))
            expect(resp.model).toNot(beNil())
        })
    }
    
    func testNoPk() {
        CheckoutKit.destroy()
        expect { try CheckoutKit.getInstance() }.to(throwError(errorType: CheckoutError.self))
    }

}
