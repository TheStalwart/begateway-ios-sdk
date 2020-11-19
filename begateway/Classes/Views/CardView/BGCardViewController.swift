//
//  BGCardView.swift
//  begateway
//
//  Created by FEDAR TRUKHAN on 9/7/19.
//

import Foundation
import UIKit

class BGTextField: UITextField {
    let padding = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
    
    override open func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
    
    override open func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
    
    override open func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
}

protocol BGCardViewControllerDelegate: class {
    func dismissTouch()
    func payTouch(card: BGCard)
}

extension BGCardViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y > -30 {
            if self.dissmissButton.isUserInteractionEnabled {
                self.dissmissButton.isUserInteractionEnabled = false
                UIView.animate(withDuration: 0.3) {
                    self.dissmissButton.alpha = 0.1
                }
            }
        } else if !self.dissmissButton.isUserInteractionEnabled {
            self.dissmissButton.isUserInteractionEnabled = true
            UIView.animate(withDuration: 0.3) {
                self.dissmissButton.alpha = 1
            }
        }
    }
}

extension UIView {
    func makeRedBlink() {
        let blinkView = UIView()
        blinkView.backgroundColor = UIColor.red.withAlphaComponent(0.3)
        blinkView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(blinkView)
        blinkView.frame = self.bounds
        blinkView.clipsToBounds = true
        blinkView.isUserInteractionEnabled = false
        blinkView.layer.cornerRadius = 10
        blinkView.alpha = 0
        UIView.animate(withDuration: 0.3) {
            blinkView.alpha = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            UIView.animate(withDuration: 0.3, animations: {
                blinkView.alpha = 0
            })
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            blinkView.removeFromSuperview()
        }
    }
}

public protocol BGCardView: UIViewController {
    
}

class BGCardViewController: UIViewController, MaskedTextFieldDelegateListener, BGCardView {
    var isLoading = false {
        didSet {
            if Thread.isMainThread {
                self.loadingBack.isHidden = !self.isLoading
                self.isLoading ? self.loadingIndicator.startAnimating() : self.loadingIndicator.stopAnimating()
                self.view.isUserInteractionEnabled = !self.isLoading
            } else {
                DispatchQueue.global().async(execute: {
                    DispatchQueue.main.sync {
                        self.loadingBack.isHidden = !self.isLoading
                        self.isLoading ? self.loadingIndicator.startAnimating() : self.loadingIndicator.stopAnimating()
                        self.view.isUserInteractionEnabled = !self.isLoading
                    }
                })
            }
        }
    }
    
    var card: BGCard {
        return BGCard.init(
            number: tempCardNumber,
            verificationValue: tempCVV,
            holder: cardHolderTF.text ?? "",
            expMonth: tempMonth,
            expYear: tempYear)
    }
    
    var paymentSettings: BGPaymentSettings = BGPaymentSettings.standart
    var colors: BGCardViewColorsSettings = BGCardViewColorsSettings.standart {
        didSet {
            DispatchQueue.main.async {
                self.updateWithColorSettings()
            }
        }
    }
    var style: BGStyleSettings = BGStyleSettings.standart {
        didSet {
            DispatchQueue.main.async {
                self.updateWithStyle()
            }
        }
    }
    
    var cardHolderPlaceholder: String? {
        set {
            if let string = newValue {
                cardHolderTF.attributedPlaceholder = NSAttributedString(
                    string: string,
                    attributes: [NSAttributedString.Key.foregroundColor: colors.holderNamePlaceholderColor])
            } else {
                cardHolderTF.attributedPlaceholder = nil
            }
        }
        get {
            return cardHolderTF.attributedPlaceholder?.string
        }
    }
    var cardNumberPlaceholder: String? {
        set {
            if let string = newValue {
                cardNumberTF.attributedPlaceholder = NSAttributedString(
                    string: string,
                    attributes: [NSAttributedString.Key.foregroundColor: colors.cardNumberPlaceholderColor])
            } else {
                cardNumberTF.attributedPlaceholder = nil
            }
        }
        get {
            return cardNumberTF.attributedPlaceholder?.string
        }
    }
    var cvvPlaceholder: String? {
        set {
            if let string = newValue {
                CVVTF.attributedPlaceholder = NSAttributedString(
                    string: string,
                    attributes: [NSAttributedString.Key.foregroundColor: colors.cvvTextPlaceholderColor])
            } else {
                CVVTF.attributedPlaceholder = nil
            }
        }
        get {
            return CVVTF.attributedPlaceholder?.string
        }
    }
    var expirationDatePlaceholder: String? {
        set {
            if let string = newValue {
                expirationDateTF.attributedPlaceholder = NSAttributedString(
                    string: string,
                    attributes: [NSAttributedString.Key.foregroundColor: colors.expirationDatePlaceholderColor])
            } else {
                expirationDateTF.attributedPlaceholder = nil
            }
        }
        get {
            return expirationDateTF.attributedPlaceholder?.string
        }
    }
    
    private var tempCardNumber: String = ""
    private var tempCVV: String = ""
    var tempMonth: String = ""
    var tempYear: String = ""
    
    func textField(_ textField: UITextField,
                   didFillMandatoryCharacters complete: Bool,
                   didExtractValue value: String) {
        
        switch textField {
        case cardNumberTF:
            tempCardNumber = value
            let type = BGCardType(cardNumber: value)
            
            cvvPlaceholder = type.securityCodeName
            
            if value.isEmpty {
                cardIcon.image = nil
            } else if value.count > 1 {
                cardIcon.image = type.icon
            } else {
                cardIcon.image = UIImage(named: "bgunknown", in: Bundle(for: BGCardViewController.self), compatibleWith: nil)
            }
            
            switch type {
            case .AMEX:
                var mask = "["
                for i in 1 ..< type.maxCardLength+1 {
                    mask += "0"
                    if BGCardType.AMEX_SPACE_INDICES.contains(i) {
                        mask += "] ["
                    }
                    if i == type.maxCardLength {
                        mask += "]"
                    }
                }
                cardHolderTFMask.primaryMaskFormat = "[0000] [000000] [0000]"
            default:
                var mask = "["
                for i in 1 ..< type.maxCardLength+1 {
                    mask += "0"
                    if BGCardType.DEFAULT_SPACE_INDICES.contains(i) {
                        mask += "] ["
                    }
                    if i == type.maxCardLength {
                        mask += "]"
                    }
                }
                cardHolderTFMask.primaryMaskFormat = "[0000] [0000] [0000] [0000]"
            }
            if type.isLuhnValid(cardNumber: value) {
                if !expirationDateTF.isHidden {
                    if (expirationDateTF.text ?? "").isEmpty {
                        self.nextButtonAction()
                    } else {
                        self.doneButtonAction()
                    }
                } else if !CVVTF.isHidden {
                    CVVTF.becomeFirstResponder()
                }
            }
            if value.count == type.maxCardLength && !type.isLuhnValid(cardNumber: value) {
                cardNumberTF.textColor = colors.cardNumberInvalidColor
            } else {
                cardNumberTF.textColor = colors.cardNumberTextColor
            }
        case CVVTF:
            tempCVV = value
            let type = BGCardType(cardNumber: value)
            var mask = "["
            for _ in 0 ..< type.securityCodeLength {
                mask += "0"
            }
            mask += "]"
            CVVTFMask.primaryMaskFormat = mask
        default:
            break
        }
    }
    
    private let cardHolderTFMask = MaskedTextFieldDelegate()
    private let cardHolderTF = BGTextField()
    private let cardNumberTF = BGTextField()
    private let expirationDateTF = BGTextField()
    private let expirationDateTFMask = MaskedTextFieldDelegate()
    private let CVVTF = BGTextField()
    private let CVVTFMask = MaskedTextFieldDelegate()
    private let saveCardLabel = UILabel()
    let saveCardSwitch = UISwitch()
    private let cardIcon = UIImageView()
    
    private let mainStack = UIStackView()
    private let expirationDateAndCVVStack = UIStackView()
    private let saveSwitchStack = UIStackView()
    private let mainScrollView = UIScrollView()
    private let stubsaveView = UIView()
    
    private let dissmissButton = UIButton()
    private let imageView = UIImageView()
    private let payButton = UIButton()
    private let infoButton = UIButton()
    private let refundsButton = UIButton()
    private let datePicker = MonthYearPickerView()

    private let loadingBack = UIView()
    private let loadingIndicator = UIActivityIndicatorView(style: .whiteLarge)
    
    weak var delegate: BGCardViewControllerDelegate?
    
    func onDateSelected(_ month: Int, _ year: Int) -> Void {
        if month < 10 {
            expirationDateTF.text = "0\(month)/\(year)"
            tempMonth = "0\(month)"
            tempYear = "\(year)"
        } else {
            expirationDateTF.text = "\(month)/\(year)"
            tempMonth = "\(month)"
            tempYear = "\(year)"
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(BGCardViewController.keyboardWillChangeFrame), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(BGCardViewController.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)

        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupViews() {
        loadingIndicator.hidesWhenStopped = true
        loadingBack.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        isLoading = false
        
        mainScrollView.delegate = self
        cardHolderTFMask.affinityCalculationStrategy = .prefix
        cardHolderTFMask.primaryMaskFormat = ""
        view.backgroundColor = UIColor.white
        
        mainStack.axis = .vertical
        mainStack.spacing = 5
        
        expirationDateAndCVVStack.axis = .horizontal
        expirationDateAndCVVStack.distribution = .fillEqually
        expirationDateAndCVVStack.spacing = 5
        expirationDateTF.tintColor = UIColor.clear
        
        stubsaveView.backgroundColor = UIColor.clear
        saveCardSwitch.setOn(true, animated: false)
        saveSwitchStack.axis = .horizontal
        saveSwitchStack.spacing = 10
        
        dissmissButton.setTitle(BGLocalization.cancel, for: .normal)
        payButton.setTitle(BGLocalization.begatewayButtonPay, for: .normal)
        payButton.clipsToBounds = true
        payButton.layer.cornerRadius = 10
        
        infoButton.setTitle("\(NSLocalizedString("Merchant details", comment: "")) ⓘ", for: .normal)
        refundsButton.setTitle(NSLocalizedString("refunds and returns", comment: ""), for: .normal)
        
        if #available(iOS 11.0, *) {
            mainScrollView.insetsLayoutMarginsFromSafeArea = true
            view.insetsLayoutMarginsFromSafeArea = true
        }
        mainScrollView.contentInset = .init(top: 50, left: 0, bottom: 0, right: 0)
        
        cardHolderPlaceholder = BGLocalization.begatewayFormHintCardholderName
        cardNumberPlaceholder = BGLocalization.begatewayFormHintCardNumber
        cvvPlaceholder = BGLocalization.begatewayCVV
        expirationDatePlaceholder = BGLocalization.begatewayFormHintExpiration
        
        cardHolderTF.autocapitalizationType = .allCharacters
        cardHolderTF.autocorrectionType = .no
        
        cardNumberTF.delegate = cardHolderTFMask
        cardHolderTFMask.delegate = self
        
        expirationDateTF.delegate = expirationDateTFMask
        expirationDateTFMask.delegate = self
        expirationDateTFMask.primaryMaskFormat = "[00]/[0000]"
        expirationDateTF.inputView = datePicker
        datePicker.onDateSelected = self.onDateSelected
        
        CVVTF.delegate = CVVTFMask
        CVVTFMask.delegate = self
        
        let defaultCornerRadius: CGFloat = 10
        cardNumberTF.layer.cornerRadius = defaultCornerRadius
        cardHolderTF.layer.cornerRadius = defaultCornerRadius
        expirationDateTF.layer.cornerRadius = defaultCornerRadius
        CVVTF.layer.cornerRadius = defaultCornerRadius
        
        cardIcon.contentMode = .scaleAspectFit
        cardIcon.isUserInteractionEnabled = false
        
        saveCardLabel.text = BGLocalization.begatewaySavecard
        saveCardLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        
        cardHolderTF.addTarget(self, action: #selector(self.nextButtonAction), for: .primaryActionTriggered)
        cardNumberTF.addTarget(self, action: #selector(self.nextButtonAction), for: .primaryActionTriggered)
        expirationDateTF.addTarget(self, action: #selector(self.nextButtonAction), for: .primaryActionTriggered)
        CVVTF.addTarget(self, action: #selector(self.doneButtonAction), for: .primaryActionTriggered)
        cardHolderTF.returnKeyType = .next
        cardNumberTF.keyboardType = .numberPad
        cardNumberTF.returnKeyType = .next
        CVVTF.keyboardType = .numberPad
        CVVTF.returnKeyType = .done
        self.addNextButtonOnKeyboard(cardNumberTF)
        self.addNextButtonOnKeyboard(expirationDateTF)
        self.addDoneButtonOnKeyboard(CVVTF)
    }
    
    private func disableAutoresizingMask() {
        cardHolderTF.translatesAutoresizingMaskIntoConstraints = false
        cardNumberTF.translatesAutoresizingMaskIntoConstraints = false
        expirationDateTF.translatesAutoresizingMaskIntoConstraints = false
        CVVTF.translatesAutoresizingMaskIntoConstraints = false
        
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        expirationDateAndCVVStack.translatesAutoresizingMaskIntoConstraints = false
        mainScrollView.translatesAutoresizingMaskIntoConstraints = false
        
        dissmissButton.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        cardIcon.translatesAutoresizingMaskIntoConstraints = false
        payButton.translatesAutoresizingMaskIntoConstraints = false
        infoButton.translatesAutoresizingMaskIntoConstraints = false
        refundsButton.translatesAutoresizingMaskIntoConstraints = false
        saveSwitchStack.translatesAutoresizingMaskIntoConstraints = false
        loadingBack.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func arrangeSubviews() {
        view.addSubview(mainScrollView)
        mainScrollView.addSubview(mainStack)
        mainStack.addArrangedSubview(cardNumberTF)
        mainStack.addArrangedSubview(cardHolderTF)
        mainStack.addArrangedSubview(expirationDateAndCVVStack)
        expirationDateAndCVVStack.addArrangedSubview(expirationDateTF)
        expirationDateAndCVVStack.addArrangedSubview(CVVTF)
        
        mainScrollView.addSubview(cardIcon)
        
        saveSwitchStack.addArrangedSubview(saveCardLabel)
        saveSwitchStack.addArrangedSubview(saveCardSwitch)
        saveSwitchStack.addArrangedSubview(stubsaveView)
        
        view.addSubview(dissmissButton)
        view.addSubview(imageView)
        mainStack.addArrangedSubview(saveSwitchStack)
        mainStack.addArrangedSubview(payButton)
        mainStack.addArrangedSubview(infoButton)
        mainStack.addArrangedSubview(refundsButton)
        view.addSubview(loadingBack)
        view.addSubview(loadingIndicator)
    }
    
    private var mainScrollBottomConstraint: NSLayoutConstraint!
    private func makeConstraints() {
        var mainScrollTopConstraint = mainScrollView.topAnchor.constraint(equalTo: view.topAnchor)
        mainScrollBottomConstraint = mainScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        if #available(iOS 11.0, *) {
            mainScrollTopConstraint = mainScrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
            mainScrollBottomConstraint = mainScrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        }
        NSLayoutConstraint.activate([
            mainScrollTopConstraint,
            mainScrollBottomConstraint,
            mainScrollView.leftAnchor.constraint(equalTo: view.leftAnchor),
            mainScrollView.rightAnchor.constraint(equalTo: view.rightAnchor)
            ])
        var dismissButtonTopConstraint = dissmissButton.topAnchor.constraint(equalTo: view.topAnchor)
        var imageViewTopConstraint = imageView.topAnchor.constraint(equalTo: view.topAnchor)
        if #available(iOS 11.0, *) {
            dismissButtonTopConstraint = dissmissButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
            imageViewTopConstraint = imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        }
        NSLayoutConstraint.activate([
            dismissButtonTopConstraint,
            dissmissButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
            dissmissButton.heightAnchor.constraint(equalToConstant: 40),
            dissmissButton.rightAnchor.constraint(lessThanOrEqualTo: view.rightAnchor, constant: -20)
            ])

        NSLayoutConstraint.activate([
            imageViewTopConstraint,
            imageView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
            imageView.heightAnchor.constraint(equalToConstant: 40),
            imageView.widthAnchor.constraint(equalToConstant: 180),
            ])
        
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: mainScrollView.topAnchor),
            mainStack.leftAnchor.constraint(equalTo: mainScrollView.leftAnchor, constant: 16),
            mainStack.rightAnchor.constraint(equalTo: mainScrollView.rightAnchor, constant: -16),
            mainStack.bottomAnchor.constraint(equalTo: mainScrollView.bottomAnchor),
            mainStack.widthAnchor.constraint(equalTo: mainScrollView.widthAnchor, constant: -32)
            ])
        
        NSLayoutConstraint.activate([
            cardHolderTF.heightAnchor.constraint(equalToConstant: 50),
            cardNumberTF.heightAnchor.constraint(equalToConstant: 50),
            CVVTF.heightAnchor.constraint(equalToConstant: 50),
            expirationDateTF.heightAnchor.constraint(equalToConstant: 50)
            ])
        
        NSLayoutConstraint.activate([
            cardIcon.centerYAnchor.constraint(equalTo: cardNumberTF.centerYAnchor),
            cardIcon.widthAnchor.constraint(equalTo: cardIcon.heightAnchor, multiplier: 168.0/112.0),
            cardIcon.heightAnchor.constraint(equalTo: cardNumberTF.heightAnchor, multiplier: 0.8),
            cardIcon.rightAnchor.constraint(equalTo: cardNumberTF.rightAnchor, constant: -20)
            ])
        NSLayoutConstraint.activate([
            payButton.heightAnchor.constraint(equalToConstant: 50)
            ])
        
        if #available(iOS 11.0, *) {
            mainStack.setCustomSpacing(10, after: expirationDateAndCVVStack)
            mainStack.setCustomSpacing(20, after: saveSwitchStack)
            mainStack.setCustomSpacing(10, after: payButton)
        }
        NSLayoutConstraint.activate([
            loadingBack.leftAnchor.constraint(equalTo: view.leftAnchor),
            loadingBack.topAnchor.constraint(equalTo: view.topAnchor),
            loadingBack.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            loadingBack.rightAnchor.constraint(equalTo: view.rightAnchor),
            loadingIndicator.centerXAnchor.constraint(equalTo: loadingBack.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: loadingBack.centerYAnchor)
            ])
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        DispatchQueue.main.async {
            self.setupViews()
            self.arrangeSubviews()
            self.disableAutoresizingMask()
            self.makeConstraints()
            self.makeActions()
            self.updateWithColorSettings()
            self.updateWithStyle()
        }
    }
    private func makeActions() {
        dissmissButton.addTarget(self, action: #selector(BGCardViewController.dismissTouch), for: .touchUpInside)
        payButton.addTarget(self, action: #selector(BGCardViewController.payTouch), for: .touchUpInside)
        infoButton.addTarget(self, action: #selector(BGCardViewController.infoTouch), for: .touchUpInside)
        refundsButton.addTarget(self, action: #selector(BGCardViewController.refundsTouch), for: .touchUpInside)
    }
    @objc private func dismissTouch() {
        delegate?.dismissTouch()
    }
    var brands: [BGBrand] = []
    @objc private func payTouch() {
        guard let holderName = cardHolderTF.text else {
            self.cardHolderTF.makeRedBlink()
            return
        }
        var isHasEmptyFields = false
        if holderName.isEmpty {
            isHasEmptyFields = true
            self.cardHolderTF.makeRedBlink()
        }
        if tempYear.isEmpty || tempMonth.isEmpty {
            isHasEmptyFields = true
            self.expirationDateTF.makeRedBlink()
        }
        let type = BGCardType(cardNumber: tempCardNumber)
        if !(type.minCardLength...type.maxCardLength ~= tempCardNumber.count) ||
            !type.isLuhnValid(cardNumber: tempCardNumber) {
            isHasEmptyFields = true
            self.cardNumberTF.makeRedBlink()
        }
        if type.securityCodeLength != tempCVV.count {
            isHasEmptyFields = true
            self.CVVTF.makeRedBlink()
        }
        if isHasEmptyFields {
            return
        }
        if !brands.isEmpty {
            if !brands.contains(where: { (brandItem) -> Bool in
                brandItem.cardType == BGCardType(cardNumber: card.number)
            }) {
                let alert = UIAlertController(title: "Warning", message: "This merchant does not accept \(BGCardType.init(cardNumber: card.number)) cards", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: BGLocalization.close, style: .cancel, handler: nil))
                return
            }
        }
        delegate?.payTouch(card: card)
    }
    @objc private func infoTouch() {
        let alertController = UIAlertController(title: nil, message: NSLocalizedString("merchant_info", comment: ""), preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: BGLocalization.close, style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    @objc private func refundsTouch() {
        UIApplication.shared.open(URL(string: "https://www.vialet.eu/terms-and-conditions")!, options: [:], completionHandler: nil)
    }
    private func updateWithColorSettings() {
        cardHolderTF.textColor = colors.holderNameTextColor
        cardHolderTF.backgroundColor = colors.holderNameBackgroundColor
        
        cardNumberTF.textColor = colors.cardNumberTextColor
        cardNumberTF.backgroundColor = colors.cardNumberBackgroundColor
        
        CVVTF.textColor = colors.cvvTextColor
        CVVTF.backgroundColor = colors.cvvBackgroundColor
        
        expirationDateTF.textColor = colors.expirationDateTextColor
        expirationDateTF.backgroundColor = colors.expirationDateBackgroundColor
        
        dissmissButton.setTitleColor(colors.cancelTextColor, for: .normal)

        imageView.image = paymentSettings.image
        imageView.contentMode = .scaleAspectFit
        
        payButton.setTitleColor(colors.payButtonTextColor, for: .normal)
        payButton.backgroundColor = colors.payButtonBackgroundColor
        
        infoButton.setTitleColor(colors.secureInfoTextColor, for: .normal)

        refundsButton.setTitleColor(colors.secureInfoTextColor, for: .normal)
        refundsButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        
        saveCardLabel.textColor = colors.saveCardSwitchTextColor
        saveCardSwitch.onTintColor = colors.saveCardSwitchTintOnColor
        saveCardSwitch.tintColor = colors.saveCardSwitchTintOffColor
    }
    func updateWithStyle() {
        cardHolderTF.isHidden = !style.isRequiredCardHolderName
        cardNumberTF.isHidden = !style.isRequiredCardNumber
        expirationDateTF.isHidden = !style.isRequiredExpDate
        CVVTF.isHidden = !style.isRequiredCVV
        cardIcon.isHidden = !style.isRequiredCardNumber
        saveSwitchStack.isHidden = !style.isSaveCardCheckBoxVisible

        navigationItem.rightBarButtonItems = style.rightBarButtonItems
        if style.rightBarButtonItems.count > 0 {
            navigationController?.setNavigationBarHidden(false, animated: false)
        }
    }
    func addDoneButtonOnKeyboard(_ textfield: UITextField){
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 40))
        doneToolbar.barStyle = .default
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: BGLocalization.done, style: .done, target: self, action: #selector(self.doneButtonAction))
        
        let items = [flexSpace, done]
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        
        textfield.inputAccessoryView = doneToolbar
    }
    @objc func doneButtonAction() {
        self.view.endEditing(true)
    }
    func addNextButtonOnKeyboard(_ textfield: UITextField) {
        let nextToolbar: UIToolbar = UIToolbar(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 40))
        nextToolbar.barStyle = .default
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: BGLocalization.next, style: .done, target: self, action: #selector(self.nextButtonAction))
        
        let items = [flexSpace, done]
        nextToolbar.items = items
        nextToolbar.sizeToFit()
        
        textfield.inputAccessoryView = nextToolbar
    }
    @objc func nextButtonAction() {
        if cardNumberTF.isFirstResponder {
            cardHolderTF.becomeFirstResponder()
        } else if cardHolderTF.isFirstResponder {
            expirationDateTF.becomeFirstResponder()
        } else if expirationDateTF.isFirstResponder {
            CVVTF.becomeFirstResponder()
        }
    }
    
    @objc func keyboardWillChangeFrame(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            if let keyboardHeight = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height {
                self.keyboardHeight = keyboardHeight
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        self.keyboardHeight = 0
    }
    private var keyboardHeight: CGFloat = 0 {
        didSet {
            updateScrollViewContraints()
        }
    }
    private func updateScrollViewContraints() {
        if view?.window == nil || mainScrollBottomConstraint == nil { return }
        mainScrollBottomConstraint.constant = -keyboardHeight
        self.view.setNeedsLayout()
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }
}
