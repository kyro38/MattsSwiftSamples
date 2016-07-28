//
//  TokenInputView.swift
//  MattsSwiftSamples
//
//  Created by Matthieu Riegler on 26/07/16.
//  Copyright © 2016 Matthieu Riegler.
//  MIT Licence
//  Inspired by CLTokenInputView https://github.com/clusterinc/CLTokenInputView

import UIKit


protocol TokenInputViewDelegate {
    func tokenInputView(view:TokenInputView, didChangeText text:String?)
    func tokenInputView(view:TokenInputView, didAddToken token:Token)
    func tokenInputView(view:TokenInputView, didRemove token:Token)
    
    func tokenInputViewDidEndEditing(view:TokenInputView)
    func tokenInputViewDidBegingEditing(view:TokenInputView)
}

class TokenInputView:UIView, TokenViewDelegate {
    
    private var tokens = [Token]()
    private var tokenViews = [TokenView]()
    
    private var textField:BackspaceDetectingTextField!
    private var fieldNameLabel:UILabel!
    
    var fieldName:String? {
        didSet {
            setFieldName()
        }
    }
    var delegate:TokenInputViewDelegate?
    var placeholder:String? {
        didSet {
            updatePlaceholderTextVisibility()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        textField = BackspaceDetectingTextField(frame: self.bounds)
        textField.delegate = self
        textField.autocorrectionType = .No
        textField.autocapitalizationType = .None
        
        textField.addTarget(self, action: #selector(onTextFieldDidChange), forControlEvents: .EditingChanged)
        
        addSubview(textField)

        fieldNameLabel = UILabel(frame:CGRect.zero)
        addSubview(fieldNameLabel)
    }
    
    private func setFieldName() {
        fieldNameLabel.text = fieldName
        fieldNameLabel.sizeToFit()
    }
    
    func addToken(token:Token) {
        if tokens.contains(token) { return }
        tokens.append(token)
        let newTokenView = TokenView(token: token)
        newTokenView.tintColor = self.tintColor
        
        newTokenView.delegate = self
        tokenViews.append(newTokenView)
        addSubview(newTokenView)
        
        textField.text = nil
        updatePlaceholderTextVisibility()
        repositionViews()
    }
    
    func removeToken(token:Token) {
        guard let tokenIndex = tokens.indexOf(token) else { return }
        removeTokenAtIndex(tokenIndex)
    }
    
    func removeTokenAtIndex(index:Int) {
        tokenViews[index].removeFromSuperview()
        tokenViews.removeAtIndex(index)
        tokens.removeAtIndex(index)
        updatePlaceholderTextVisibility()
        repositionViews()
    }
    
    func repositionViews() {
        let padding = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 16)
        var curX:CGFloat = padding.left
        var curY:CGFloat = padding.top
        let rowHeight:CGFloat = 25
        let vSpace:CGFloat = 4
        let hSpace:CGFloat = 0
        var totalHeight:CGFloat = 0
        let fieldMarginX:CGFloat = 8
        
        fieldNameLabel.frame = CGRect(x:curX + 8, y:curY+(rowHeight-fieldNameLabel.frame.height)/2, width:fieldNameLabel.frame.width, height:rowHeight)
        curX = max(fieldMarginX, fieldNameLabel.frame.maxX)
        
        var tokenRect =  CGRect.null
        for tokenView in tokenViews {
            tokenRect = tokenView.frame
            let tokenBoundary = bounds.width
            if curX + tokenRect.width > tokenBoundary {
                curX = padding.left
                curY += rowHeight + vSpace
                totalHeight += rowHeight
            }
            tokenRect.origin.x = curX
            tokenRect.origin.y = curY + (rowHeight-tokenRect.height)/2
            tokenView.frame = tokenRect
            
            curX = tokenRect.maxX + hSpace
        }
        let textBoundary = bounds.width
        var availabledWidthForTextfield = textBoundary - curX
        if availabledWidthForTextfield < 60 {
            curX = padding.left
            curY += rowHeight + vSpace
            totalHeight += rowHeight
            availabledWidthForTextfield = textBoundary-curX
        }
        
        let textFieldRect = CGRect(x: curX, y: curY, width: availabledWidthForTextfield, height: rowHeight)
        textField.frame = textFieldRect
    }
    
    func updatePlaceholderTextVisibility() {
        textField.placeholder =  tokens.count > 0 ? nil : placeholder
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        repositionViews()
    }
    
    // MARK: TokenView Delegate
    
    func tokenViewDidRequestSelection(tokenView: TokenView) {
        selectTokenView(tokenView, animated: true)
    }
    
    func tokenViewDidRequestDelete(tokenView: TokenView, replaceWithText replacementText: String?) {
        textField.becomeFirstResponder()
        if replacementText?.characters.count > 0 {
            textField.text = replacementText
        }
        if let index = tokenViews.indexOf(tokenView) {
            removeTokenAtIndex(index)
        }
    }
    
    func selectTokenView(tokenView:TokenView, animated:Bool) {
        tokenView.setSelected(true, animated: animated)
        for otherTokenView in tokenViews where otherTokenView != tokenView {
            otherTokenView.setSelected(false, animated: true)
        }
    }
    
    func unselecAllTokenViewsAnimated(animated:Bool) {
        for tokenView in tokenViews {
            tokenView.setSelected(false, animated: animated)
        }
    }
    
    // MARK - TextField
    
    func onTextFieldDidChange(sender:UITextField) {
        delegate?.tokenInputView(self, didChangeText: sender.text)
    }
}


extension TokenInputView:BackspaceDetectingTextFieldDelegate {
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if let text = textField.text where text != ""{
            let token = Token(string: text)
            addToken(token)
            textField.text = nil
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        delegate?.tokenInputViewDidBegingEditing(self)
        tokenViews.last?.hideComma = false
        unselecAllTokenViewsAnimated(true)
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        delegate?.tokenInputViewDidEndEditing(self)
        tokenViews.last?.hideComma = true
    }
    
    func textFieldDidDeleteBackwards(textField:UITextField) {
        if let text = textField.text where text.characters.count == 0 {
            if let lastTokenView = tokenViews.last {
                selectTokenView(lastTokenView, animated: true)
                textField.resignFirstResponder()
            }
        }
    }
}