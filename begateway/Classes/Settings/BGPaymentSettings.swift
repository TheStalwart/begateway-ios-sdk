//
//  PaymentSettings.swift
//  Alamofire
//
//  Created by FEDAR TRUKHAN on 8/25/19.
//

public struct BGPaymentSettings {
    public var endpoint: String
    public var isTestMode: Bool
    public var locale: String
    public var securedBy = "beGateway"
    public var supportedCardTypes: [BGCardType]
    public var styleSettings: BGStyleSettings
    public var cardViewColorsSettings: BGCardViewColorsSettings
    public var image: UIImage?
    public var returnURL: String
    public var notificationURL: String
    
    public mutating func updateSecuredBy(with value: String) {
        securedBy = value
    }
    
    public static var standart: BGPaymentSettings {
        return BGPaymentSettings(
            endpoint: "",
            isTestMode: true,
            locale: "en",
            supportedCardTypes: [],
            styleSettings: BGStyleSettings.standart,
            cardViewColorsSettings: BGCardViewColorsSettings.standart,
            returnURL: "",
            notificationURL: "")
    }
}
