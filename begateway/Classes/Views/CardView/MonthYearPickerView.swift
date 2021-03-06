//
//  MonthYearPickerView.swift
//  begateway
//
//  Created by FEDAR TRUKHAN on 9/8/19.
//

import Foundation
import UIKit

class MonthYearPickerView: UIPickerView, UIPickerViewDelegate, UIPickerViewDataSource {
    var months: [Int]!
    var years: [Int]!
    
    var month = Calendar.current.component(.month, from: Date()) {
        didSet {
            selectRow(month-1, inComponent: 0, animated: true)
        }
    }
    
    var year = Calendar.current.component(.year, from: Date()) {
        didSet {
            selectRow(years.firstIndex(of: year)!, inComponent: 1, animated: true)
        }
    }
    
    var onDateSelected: ((_ month: Int, _ year: Int) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonSetup()
    }
    
    func commonSetup() {
        // population years
        var years: [Int] = []
        if years.count == 0 {
            var year = NSCalendar(identifier: NSCalendar.Identifier.gregorian)!.component(.year, from: NSDate() as Date)
            for _ in 1...20 {
                years.append(year)
                year += 1
            }
        }
        self.years = years
        
        var months: [Int] = []
        var month = 1
        for _ in 1...12 {
            months.append(month)
            month += 1
        }
        self.months = months
        
        self.delegate = self
        self.dataSource = self
        
        let currentMonth = NSCalendar(identifier: NSCalendar.Identifier.gregorian)!.component(.month, from: Date())
        self.selectRow(currentMonth - 1, inComponent: 0, animated: false)
    }
    
    // Mark: UIPicker Delegate / Data Source
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch component {
        case 0:
            let monthItem = months[row]
            if monthItem < 10 {
                return "0\(months[row])"
            } else {
                return "\(months[row])"
            }
        case 1:
            return "\(years[row])"
        default:
            return nil
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch component {
        case 0:
            return months.count
        case 1:
            return years.count
        default:
            return 0
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let currentDateComponents = Calendar.current.dateComponents([.month, .year], from: Date())
        var month = self.selectedRow(inComponent: 0)+1
        var year = years[self.selectedRow(inComponent: 1)]
        
        if let curMonth = currentDateComponents.month, let curYear = currentDateComponents.year {
            if year < curYear {
                year = curYear
            }
            if year == curYear && month < curMonth {
                month = curMonth
            }
        }
        if let block = onDateSelected {
            block(month, year)
        }
        self.month = month
        self.year = year
    }
    
}

