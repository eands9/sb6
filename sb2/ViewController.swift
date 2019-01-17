//
//  ViewController.swift
//  sb2
//
//  Created by Eric Hernandez on 1/17/19.
//  Copyright © 2019 Eric Hernandez. All rights reserved.
//

import UIKit
import SwiftSoup

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let myURL = URL(string: "https://www.merriam-webster.com/dictionary/apple")
        let html = try! String(contentsOf: myURL!, encoding: .utf8)
 
        do {
            let doc: Document = try SwiftSoup.parseBodyFragment(html)
            let wordDef = try doc.getElementsByClass("dtText")
            let wordType = try doc.getElementsByClass("fl")
            let wordPronounciation = try doc.getElementsByClass("prs")
            let wordSentence = try doc.getElementsByClass("t has-aq")
            let wordWavFile = try doc.getElementsByClass("play-pron hw-play-pron")

            print(try wordDef.text())
            
            print(try wordType.text())
            
            print(try wordPronounciation.text())
            
            print(try wordSentence.text())
            
            print(try wordWavFile.attr("data-file"))
            
            print(try wordWavFile.attr("data-dir"))
            
        } catch Exception.Error(let type, let message) {
            
            print("Message: \(message)")
            
        } catch {
            
            print("error")
            
        }
    }


}

