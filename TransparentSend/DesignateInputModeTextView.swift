//
//  DesignateInputModeTextView.swift
//  TransparentSend
//
//  Created by JiaCheng on 2018/12/14.
//  Copyright © 2018 JiaCheng. All rights reserved.
//

import UIKit

class DesignateInputModeTextView: UITextView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    //为了打字时指定是英文，这个UITextInputMode.activeInputModes就是你的settings->Keyboards->Keyboards里面的所有键盘输入模式
    override var textInputMode: UITextInputMode? {
        for mode in UITextInputMode.activeInputModes {
            if mode.primaryLanguage == "en-US" ||  mode.primaryLanguage == "en"{
                return mode
            }
        }
        return UITextInputMode.activeInputModes[1]
    }

}
