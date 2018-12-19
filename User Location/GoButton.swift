//
//  GoButton.swift
//  User Location
//
//  Created by Charles Martin Reed on 12/18/18.
//  Copyright © 2018 Charles Martin Reed. All rights reserved.
//

import UIKit

class GoButton: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButton()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupButton()
    }
    
    private func setupButton() {
        layer.cornerRadius = frame.size.height / 2
        
        backgroundColor = Colors.forestyGreen
        titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        
        setTitle("GO!", for: .normal)
        setTitleColor(.white, for: .normal)
    }
    
}
