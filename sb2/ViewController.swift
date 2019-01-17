//
//  ViewController.swift
//  sb2
//
//  Created by Eric Hernandez on 1/17/19.
//  Copyright © 2019 Eric Hernandez. All rights reserved.
//

import UIKit
import SwiftSoup
import AVKit

class ViewController: UIViewController {

    @IBOutlet weak var chkBtnSeg: UISegmentedControl!
    @IBOutlet weak var wordInfoSeg: UISegmentedControl!
    @IBOutlet weak var wordTxtView: UITextView!
    @IBOutlet weak var progressLbl: UILabel!
    
    var spellingWord = ""
    var builtUrl = ""
    var wordDefTxt = ""
    var wordTypeTxt = ""
    var wordPronounciationTxt = ""
    var wordSentenceTxt = ""
    var wordSoundFile = ""
    var wordSoundFileDir = ""
    var player: AVPlayer?
    
    var questionNumber: Int = 0
    var randomPick: Int = 0
    var correctAnswers: Int = 0
    var numberAttempts: Int = 0
    var totalNumberOfQuestions: Int = 0
    var markedQuestionsCount: Int = 0
    var isTesting: Bool = true
    var isLoadedTrackedQuestions: Bool = false
    var markedQuestions = [Word]()
    var IsCorrect: Bool = true
    var isStartOver: Bool = false
    var wrongAlready: Bool = false
    
    let congratulateArray = ["Great Job", "Excellent", "Way to go", "Alright", "Right on", "Correct", "Well done", "Awesome"]
    let retryArray = ["Try again","Oooops"]
    let allWords = WordBank()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        buildSearchUrl()
        getWordInfo()
        wordTxtView.text = ""
        
        readMe(myText: "Spell \(allWords.list[0].spellWord).")
        let numberOfQuestions = allWords.list
        totalNumberOfQuestions = numberOfQuestions.count
        self.wordTxtView.becomeFirstResponder()
    }
    func buildSearchUrl(){
        spellingWord = "gulag"
        builtUrl = "https://www.merriam-webster.com/dictionary/\(spellingWord)"
    }
    func getWordInfo(){
        let myURL = URL(string: builtUrl)
        let html = try! String(contentsOf: myURL!, encoding: .utf8)
        
        do {
            let doc: Document = try SwiftSoup.parseBodyFragment(html)
            let wordDef = try doc.getElementsByClass("dtText")
            let wordType = try doc.getElementsByClass("fl")
            let wordPronounciation = try doc.getElementsByClass("prs")
            let wordSentence = try doc.getElementsByClass("t has-aq")
            let wordWavFile = try doc.getElementsByClass("play-pron hw-play-pron")
            
            wordDefTxt = try wordDef.text()
            wordTypeTxt = try wordType.text()
            wordPronounciationTxt = try wordPronounciation.text()
            wordSentenceTxt = try wordSentence.text()
            wordSoundFile = try wordWavFile.attr("data-file")
            wordSoundFileDir = try wordWavFile.attr("data-dir")
            
        } catch Exception.Error(let type, let message) {
            print("Message: \(message)")
        } catch {print("error")}
    }
    @IBAction func wordInfoSeg(_ sender: Any) {
        let wordInfoIndex = wordInfoSeg.selectedSegmentIndex
        switch wordInfoIndex {
        case 0:
            wordTxtView.text = wordTypeTxt
        case 1:
            wordTxtView.text = wordDefTxt
        case 2:
            wordTxtView.text = wordSentenceTxt
        case 3:
            wordTxtView.text = wordPronounciationTxt
        case 4:
            playsound()
        case 5:
            goToYouTube()
        default:
            wordTxtView.text = "There's an Error!"
        }
    }
    @IBAction func checkBtnSeg(_ sender: Any) {
        let chkBtnSegIndex = chkBtnSeg.selectedSegmentIndex
        switch chkBtnSegIndex {
        case 0:
            checkBtn()
        case 1:
            repeatBtn()
        case 2:
            showWord()
        case 3:
            wordTxtView.text = ""
        case 4:
            nextSpellWord()
        default:
            wordTxtView.text = "There's a problem!"
        }
    }
    func playsound(){
        let urlString = "https://media.merriam-webster.com/soundc11/\(wordSoundFileDir)/\(wordSoundFile).wav"
        guard let url = URL.init(string: urlString)
            else {return}
        let playerItem = AVPlayerItem.init(url: url)
        player = AVPlayer.init(playerItem: playerItem)
        player?.play()
    }
    func goToYouTube(){
        let YoutubeQuery =  spellingWord
        let escapedYoutubeQuery = YoutubeQuery.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        let appURL = NSURL(string: "youtube://www.youtube.com/results?search_query=\(escapedYoutubeQuery!)")!
        let webURL = NSURL(string: "https://www.youtube.com/results?search_query=\(escapedYoutubeQuery!)")!
        let application = UIApplication.shared
        
        if application.canOpenURL(appURL as URL) {
            application.open(appURL as URL)
        } else {
            // if Youtube app is not installed, open URL inside Safari
            application.open(webURL as URL)
        }
    }
    func readMe( myText: String) {
        let utterance = AVSpeechUtterance(string: myText )
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.4
        
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(utterance)
    }
    func checkBtn() {
        if isTesting == true {
            checkBtnIsTesting()
        } else {checkBtnIsReview()}
    }
    func checkBtnIsTesting(){
        let spellWord = allWords.list[questionNumber].spellWord
        if spellWord == wordTxtView.text?.lowercased() {
            randomPositiveFeedback()
            //Wait 2 seconds before showing the next question
            let when = DispatchTime.now() + 2
            DispatchQueue.main.asyncAfter(deadline: when){
                //spell next word
                //self.questionNumber += 1
                self.nextWordIsTesting()
            }
            wordTxtView.text = ""
            
            //increment number of correct answers
            correctAnswers += 1
            numberAttempts += 1
            updateProgress()
        } else {
            randomTryAgain()
            numberAttempts += 1
            updateProgress()
            IsCorrect = false
            wrongAlready = true
        }
    }
    func checkBtnIsReview(){
        let correctAnswer = markedQuestions[questionNumber].spellWord
        
        if wordTxtView.text == correctAnswer{
            randomPositiveFeedback()
            
            //questionNumber += 1
            //next Question
            nextWordIsReview()
        }else{
            readMe(myText: "The correct answer is")
            wordTxtView.textColor = (UIColor.red)
            wordTxtView.text = correctAnswer

            let when = DispatchTime.now() + 2
            DispatchQueue.main.asyncAfter(deadline: when){
                //next problem
                self.nextWordIsReview()
            }
        }
    }
    func nextWordIsTesting(){
        
        if IsCorrect == false{
            trackMarkedQuestions()
            IsCorrect = true
        }
        wordTxtView.text = ""
        
        if isStartOver == true {
            questionNumber = 0
            isStartOver = false
        } else {
            questionNumber += 1
        }
        //if there are 14 questions, the number below should be 13 (always one less)
        if questionNumber <= totalNumberOfQuestions - 1 {
            readMe(myText: "Spell \(allWords.list[questionNumber].spellWord).")
            wordTxtView.text = ""
        }
        else if markedQuestionsCount == 0 {
            
            let alert = UIAlertController(title: "Awesome", message: "You've finished all the questions, do you want to start over again?", preferredStyle: .alert)
            
            let restartAction = UIAlertAction(title: "Restart", style: .default, handler: { (UIAlertAction) in
                self.startOver()
            })
            
            alert.addAction(restartAction)
            present(alert, animated: true, completion: nil)
        }
        else {
            isTesting = false
            readMe(myText: "Let us review")
            
            let when1 = DispatchTime.now() + 2
            DispatchQueue.main.asyncAfter(deadline: when1){
                //spell next word
                self.questionNumber = 0
                self.readMe(myText: "Spell \(self.markedQuestions[self.questionNumber].spellWord).")
                self.wordTxtView.text = ""
                self.wordTxtView.textColor = (UIColor.red)
            }
        }
    }
    func nextWordIsReview(){
        questionNumber += 1
        wordTxtView.text = ""
        if questionNumber <= markedQuestionsCount - 1  {
            let when = DispatchTime.now() + 2
            DispatchQueue.main.asyncAfter(deadline: when){
                self.readMe(myText: "Spell \(self.markedQuestions[self.questionNumber].spellWord).")
                self.wordTxtView.text = ""
            }
        }else {
            let alert = UIAlertController(title: "Awesome", message: "You've finished all the questions, do you want to start over again?", preferredStyle: .alert)
            
            let restartAction = UIAlertAction(title: "Restart", style: .default, handler: { (UIAlertAction) in
                self.startOver()
            })
            
            alert.addAction(restartAction)
            present(alert, animated: true, completion: nil)
        }
    }
    func showWord(){
        if isTesting == true && wrongAlready == false {
            wordTxtView.text = allWords.list[questionNumber].spellWord.uppercased()
            trackMarkedQuestions()
        }
        else if isTesting == true && wrongAlready == true{
            wordTxtView.text = allWords.list[questionNumber].spellWord.uppercased()
        }
        else {
            wordTxtView.text = markedQuestions[questionNumber].spellWord.uppercased()
        }
        numberAttempts += 1
        updateProgress()
    }
    func nextSpellWord() {
        if isTesting == true {
            nextWordIsTesting()
        }
        else {
            nextWordIsReview()
        }
    }
    func startOver(){
        questionNumber = 0
        correctAnswers = 0
        numberAttempts = 0
        updateProgress()
        
        markedQuestionsCount = 0
        markedQuestions = [Word]()
        
        isTesting = true
        isStartOver = true
        wordTxtView.textColor = (UIColor.black)
        nextWordIsTesting()
    }
    func randomPositiveFeedback(){
        randomPick = Int(arc4random_uniform(8))
        readMe(myText: congratulateArray[randomPick])
    }
    func randomTryAgain(){
        randomPick = Int(arc4random_uniform(2))
        readMe(myText: retryArray[randomPick])
    }
    func updateProgress(){
        progressLbl.text = "Correct/Attempt: \(correctAnswers) / \(numberAttempts)"
    }
    func repeatBtn() {
        if isTesting == true {
            readMe(myText: allWords.list[questionNumber].spellWord)
        }else {
            readMe(myText: markedQuestions[questionNumber].spellWord)
        }
    }
    func trackMarkedQuestions(){
        let trackedWord = allWords.list[questionNumber].spellWord
        
        markedQuestions.append(Word(word: trackedWord))
        markedQuestionsCount += 1
    }
}

