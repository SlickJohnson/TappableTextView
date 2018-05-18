//
//  TappableTextView.swift
//  TappableTextView
//
//  Created by Willie Johnson on 5/4/18.
//  Copyright © 2018 Willie Johnson. All rights reserved.
//

import UIKit

@IBDesignable
class TappableTextView: UIView {
  @IBOutlet var contentView: UITextView!
  let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
  let heavyImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
  var wordView: WordView?

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .clear
    setupView()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setupView()
  }
}

extension TappableTextView: UITextViewDelegate {
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    guard let wordView = wordView else { return }
    let distance = abs(wordView.frame.origin.y - scrollView.contentOffset.y)
    guard distance > 20 else { return }
    wordView.closeButtonPressed(self)
  }
}

// MARK: - Helper methods
private extension TappableTextView {
  /// Configure the UITextView with the required gestures to make text in the view tappable.
  func setupView() {
    contentView = loadNib(viewType: UITextView.self)
    addSubview(contentView)
    contentView.delegate = self
    contentView.constrain(to: self)
    contentView.backgroundColor = .white
    let textTapGesture = UITapGestureRecognizer(target: self, action: #selector(textTapped(recognizer:)))
    textTapGesture.numberOfTapsRequired = 1
    contentView.addGestureRecognizer(textTapGesture)
  }

  /// Handle taps on the UITextView.
  ///
  /// - Parameter recognizer: The UITapGestureRecognizer that triggered this handler.
  @objc func textTapped(recognizer: UITapGestureRecognizer) {
    guard wordView == nil else { return }
    impactFeedbackGenerator.prepare()
    heavyImpactFeedbackGenerator.prepare()
    // Grab UITextView and its content.
    guard let textView = recognizer.view as? UITextView else {
      return
    }
    // Grab the word.
    let tapLocation = recognizer.location(in: textView)
    guard let word = self.getWordAt(point: tapLocation, textView: textView) else { return }
    let highlight = HighlightView(word: word)
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapOnHighlightView(recognizer:)))
    tapGesture.delegate = self
    textView.addSubview(highlight)
    highlight.addGestureRecognizer(tapGesture)
    // Animate highlight
    highlight.transform = .init(scaleX: 0.01, y: 1)
    highlight.expandAnimation()
    textView.selectedTextRange = nil
//    UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0, options: [.curveEaseInOut, .allowUserInteraction], animations: {
////      self.impactFeedbackGenerator.impactOccurred()
//      highlight.alpha = 1
//      highlight.transform = .identity
//    }) { _ in
//      UIView.animate(withDuration: 0.4, delay: 2, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [.curveEaseIn, .allowUserInteraction], animations: {
//        highlight.transform = .init(scaleX: 1.1, y: 0.01)
//      }, completion: ({ _ in
//        highlight.removeFromSuperview()
//      }))
//    }
  }

  /// Return the word that was tapped within the textview.
  ///
  /// - Paremeters:
  ///   - point: A position within the tapped UITextView.
  ///   - textView: The textView that was tappped.
  func getWordAt(point: CGPoint, textView: UITextView) -> Word? {
    guard let textPosition = textView.closestPosition(to: point) else { return nil }
    guard let textRange = textView.tokenizer.rangeEnclosingPosition(textPosition, with: .word, inDirection: 1) else { return nil }
    let location = textView.offset(from: textView.beginningOfDocument, to: textRange.start)
    let length = textView.offset(from: textRange.start, to: textRange.end)
    guard let wordText = textView.text(in: textRange) else { return nil }
    let wordRange = NSRange(location: location, length: length)
    let wordRect = textView.firstRect(for: textRange)
    return Word(text: wordText, range: wordRange, rect: wordRect)
  }

  @objc func handleTapOnHighlightView(recognizer: UIGestureRecognizer) {
    guard let highlightView = recognizer.view as? HighlightView else { return }
    if let wordView = wordView {
      wordView.removeFromSuperview()
    }
    wordView = WordView(frame: highlightView.frame, word: highlightView.word)
    guard let wordView = wordView else { return }
    wordView.delegate = self
    wordView.color = highlightView.color
    contentView.addSubview(wordView)
    wordView.expandTo(self)
  }
}

extension TappableTextView: WordViewDelegate {
  func closeButtonPressed() {
    wordView = nil
  }
}

extension TappableTextView: UIGestureRecognizerDelegate {
}