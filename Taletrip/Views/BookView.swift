//
//  BookView.swift
//  Taletrip
//
//  Created by Davide Biancardi on 23/02/22.
//

import SwiftUI
import AVKit
import AVFoundation
import SwiftSpeech

struct BookView: View {
    
    @Environment(\.swiftSpeechState) var state: SwiftSpeech.State
    @EnvironmentObject var storiesStore : StoriesStore
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    var locale: Locale
    
    @State private var text = "Tap to Speak"
    
    
    
    init(locale: Locale = .autoupdatingCurrent) {
        
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor(Color.suyashBlue)]
        UINavigationBar.appearance().barTintColor = UIColor(Color.backgroundBeige)
        UINavigationBar.appearance().backgroundColor = UIColor(Color.backgroundBeige)
        UIToolbar.appearance().barTintColor = UIColor(Color.backgroundBeige)
        self.locale = locale
        
    }
    
   
      
       
        
//        public init(localeIdentifier: String) {
//            self.locale = Locale(identifier: localeIdentifier)
//        }
    
    var btnBack : some View { Button(action: {
        impact.impactOccurred()
        
        self.presentationMode.wrappedValue.dismiss()
        
        storiesStore.emptyPathArray()
        
        storiesStore.reLoad()
        
    }) {
        
        Label("",systemImage: "chevron.backward")
        
        
    }
    }
    
    struct CustomWords: Identifiable {
        let id = UUID()
        var text: String
        var isButton: InteractiveButton?
        
        init(text: String, chunkButtons: [InteractiveButton]) {
            self.text = text
            for chunkButton in chunkButtons {
                if (text == chunkButton.name) {
                    self.isButton = InteractiveButton(name: chunkButton.name, listOfCommands: chunkButton.listOfCommands, isObject: chunkButton.isObject)
                    break //IT'S MANDATORY TO HAVE THIS
                }
                else {
                    self.isButton = nil
                }
            }
        }
        
    }
    
    struct CustomLine: Identifiable {
        let id = UUID()
        var words: [CustomWords]
    }
    
    func stringtoLine(words: [String], buttons: [InteractiveButton], start: Int) -> ([CustomWords], Int) {
        var num = start
        var end = start
        var length = 0
        var tempLine : [CustomWords] = []
        while (num <= words.count - 1 && (length + words[num].count <= 35 || words[num].count == 1) ) {
            tempLine.append(CustomWords(text: words[num], chunkButtons: buttons))
            length += words[num].count + 1
            end = num + 1
            num += 1
        }
        return (tempLine, end)
    }
    
    func stringtoParagraph(chunk: StoryChunk) -> ([CustomLine]) {
        
        let string = chunk.description.components(separatedBy: " ")
        var num = 0
        var index = 0
        var tempParagraph : [CustomLine] = []
        while (num <= string.count - 1) {
            let result = stringtoLine(words: string, buttons: chunk.interactiveButtons, start: index)
            tempParagraph.append(CustomLine(words: result.0))
            index = result.1
            num = result.1
        }
        return tempParagraph
    }
    
    func getUtterance(_ speechString: String) -> AVSpeechUtterance {
        let utterance = AVSpeechUtterance(string: speechString)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceMaximumSpeechRate / 2.0
//        utterance.pitchMultiplier = ...
        utterance.volume = 0.75
//        utterance.preUtteranceDelay = ...
//        utterance.postUtteranceDelay = ...
        return utterance
    }
    
    func text2Speech(_ synthesizer: AVSpeechSynthesizer, chunk: StoryChunk) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)

        } catch let error {
            print("\(error.localizedDescription)")
        }
        synthesizer.speak(getUtterance(chunk.description))
    }
    
    
    
    @State var audioPlayer : AVAudioPlayer!
    @State var audioPlayer1: AVAudioPlayer!
    @State var synthesizer = AVSpeechSynthesizer()
    @State var tapped = false
    
   
    
    let impact = UIImpactFeedbackGenerator(style: .soft)
//    @State var list: [(session: SwiftSpeech.Session, text: String)] = []
//    storiesStore.storedAnswer
    var body: some View {
        
        ScrollView{
            
            ScrollViewReader{ value in
                
                ForEach(storiesStore.tappedStory.path.indices, id: \.self) { storyChunkindex in
                    
                    let paragraph = stringtoParagraph(chunk: storiesStore.tappedStory.path[storyChunkindex])
                    
                    VStack(alignment: .leading, spacing: 3) {
                        
                        if let chapterTitle = storiesStore.tappedStory.path[storyChunkindex].isChapterFirstChunk {
                            
                            CustomText(text: chapterTitle, font: UIFont.init(name: "NewYorkMedium-Bold", size: 20)!,interline : 0.9)
                            
                                .padding(.bottom,10)
                            
                            
                        }
                        
                        ForEach(paragraph) { line in
                            HStack(spacing: 3) {
                                ForEach(line.words) { word in
                                    if let button = word.isButton {
                                        if (button.isTappable && ((button.isObject && storiesStore.isIteminInventory(item: button.name, in: storiesStore.tappedStory)) || !button.isObject)) {
                                            Menu("\(button.name)") {
                                                ForEach(button.listOfCommands){ command in
                                                    
                                                    if !command.isFaded{
                                                        
                                                        Button {
                                                            impact.impactOccurred()
                                                            storiesStore.appendIndexToDescPath(command.descriptionToBeDisplayed)
                                                            storiesStore.nextPieceOfStory(from: storiesStore.tappedStory.path[storyChunkindex], command, button)

                                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                                withAnimation(.easeIn(duration: 4.5)){
                                                                    value.scrollTo(storiesStore.tappedStory.path.indices[storiesStore.tappedStory.path.indices.count - 1],anchor: .bottom)

                                                                }
                                                                text2Speech(synthesizer, chunk: storiesStore.tappedStory.path[storiesStore.tappedStory.path.count - 1])

                                                            }

                                                            if(button.name == "drink" && command.name == "Use"){
                                                                let sound = Bundle.main.path(forResource: "pouring_liquor", ofType: "wav")
                                                                self.audioPlayer = try! AVAudioPlayer(contentsOf: URL(fileURLWithPath: sound!))
                                                                self.audioPlayer.play()
                                                            } else if(button.name == "cigarette" && command.name == "Use") {
                                                                let sound = Bundle.main.path(forResource: "cigarette", ofType: "wav")
                                                                self.audioPlayer = try! AVAudioPlayer(contentsOf: URL(fileURLWithPath: sound!))
                                                                self.audioPlayer.play()
                                                            } else if(button.name == "pub" && (command.name == "Go to Beergarden" || command.name == "Go to Puzzles")) {
                                                                let sound = Bundle.main.path(forResource: "footsteps_outside", ofType: "wav")
                                                                self.audioPlayer = try! AVAudioPlayer(contentsOf: URL(fileURLWithPath: sound!))
                                                                self.audioPlayer.play()
                                                            } else if(button.name == "map" && command.name == "Use") {
                                                                let sound = Bundle.main.path(forResource: "Map", ofType: "wav")
                                                                self.audioPlayer = try! AVAudioPlayer(contentsOf: URL(fileURLWithPath: sound!))
                                                                self.audioPlayer.play()
                                                            }

                                                        } label: {

                                                            Label(command.name,systemImage:command.sfSymbol)

                                                        }
                                                                                                                
                                                        
                                                    }
                                                    
                                                    
                                                }
                                            }
                                            .font(.system(size: 20, weight: .regular, design: .serif))
                                            .foregroundColor(.white)
                                            .padding(3)
                                            .background(Color.suyashBlue)
                                            .cornerRadius(12)
                                            .onTapGesture(perform: {
                                                impact.impactOccurred()
                                            })
                                            
                                        }
                                        else {
                                            
                                            Text("\(word.text)")
                                                .font(.system(size: 20, weight: .regular, design: .serif))
                                                .foregroundColor(.white)
                                                .padding(3)
                                                .background(Color.gray)
                                                .cornerRadius(12)
                                            
                                        }
                                    }
                                    else {
                                        Text("\(word.text)")
                                            .font(.system(size: 20, weight: .regular, design: .serif))
                                        
                                    }
                                }
                                Spacer()
                            }
                        }
                        if (storiesStore.tappedStory.descpath.count > 0 && storyChunkindex < storiesStore.tappedStory.path.count - 1 && storiesStore.tappedStory.descpath[storyChunkindex] != "") {
                            
                            Text("\(storiesStore.tappedStory.descpath[storyChunkindex])")
                                .font(.system(size: 20, weight: .light))
                                .frame(maxWidth: 346, minHeight: 71)
                                .padding(.horizontal, 10)
                                .foregroundColor(.white)
                            
                                .background(Color.suyashBlue)
                                .cornerRadius(12)
                                .padding(.top,20)
                                .padding(.bottom,10)
                        }
                        else {
                         
                        }

                    }.padding([.leading,.trailing],22)
                    
                }
                
                .toolbar {
                    ToolbarItemGroup(placement: .bottomBar) {
                        Button(action: {
                            storiesStore.giveMeaHint()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                withAnimation(.easeIn(duration: 3.0)){
                                    value.scrollTo(storiesStore.tappedStory.path.indices[storiesStore.tappedStory.path.indices.count - 1],anchor: .bottom)
                                    
                                }
                                text2Speech(synthesizer, chunk: storiesStore.tappedStory.path[storiesStore.tappedStory.path.count - 1])
                                
                            }
                            let sound = Bundle.main.path(forResource: "hint", ofType: "wav")
                            self.audioPlayer = try! AVAudioPlayer(contentsOf: URL(fileURLWithPath: sound!))
                            self.audioPlayer.play()
                        }) {
                            Image(systemName: "lightbulb")
                        }
                        Spacer()
                        ZStack {
                                                   
                            Image(systemName: "mic")
                                .font(.system(size: tapped ? 30 : 15, weight: .medium, design: .default))
                                .foregroundColor(tapped ? .red : Color.suyashBlue)
                                .onTapGesture{
                                    tapped.toggle()
                                             }
                                                    
                                }
                                .swiftSpeechToggleRecordingOnTap(locale: self.locale,
                                                                 animation: .spring(response: 0.3, dampingFraction: 0.3, blendDuration: 0))
                                .onStartRecording { session in
                                    storiesStore.storedAnswers.append((session, ""))
                                }.onCancelRecording { session in
                                    _ = storiesStore.storedAnswers.firstIndex { $0.session.id == session.id }
                                    .map { storiesStore.storedAnswers.remove(at: $0) }
                                   
                                    
                                }.onRecognize(includePartialResults: true) { session, result in
                                    storiesStore.storedAnswers.firstIndex { $0.session.id == session.id }
                                    .map { index in
                                        storiesStore.storedAnswers[index].text = result.bestTranscription.formattedString + (result.isFinal ? "" : "...")
                                    }
                                    
                                    storiesStore.appendStoryChunkFromVocalResponse()
                                   
                                } handleError: { session, error in
                                    storiesStore.storedAnswers.firstIndex { $0.session.id == session.id }
                                    .map { index in
                                        storiesStore.storedAnswers[index].text = "Error \((error as NSError).code)"
                                    }
                                }
                              
                             

                      
                        
                        Spacer()
                        Button(action: {
                            
                            storiesStore.tellMeTheInventoryItems()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                withAnimation(.easeIn(duration: 3.0)){
                                    value.scrollTo(storiesStore.tappedStory.path.indices[storiesStore.tappedStory.path.indices.count - 1],anchor: .bottom)
                                    
                                }
                                text2Speech(synthesizer, chunk: storiesStore.tappedStory.path[storiesStore.tappedStory.path.count - 1])
                                
                            }
                            
                            let sound = Bundle.main.path(forResource: "zip_1", ofType: "wav")
                            self.audioPlayer = try! AVAudioPlayer(contentsOf: URL(fileURLWithPath: sound!))
                            self.audioPlayer.play()
                        }) {
                            Image(systemName: "archivebox")
                        }
                    }
                    
                }
                
            }
            
            .navigationTitle(storiesStore.tappedStory.title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(leading: btnBack)
            
            .accentColor(Color.suyashBlue)
            
            
        }
        .onAppear{
            storiesStore.firstChunkInPath(of: storiesStore.tappedStory) //fuck you nello
            text2Speech(synthesizer, chunk: storiesStore.tappedStory.path[storiesStore.tappedStory.path.count - 1])
            let sound = Bundle.main.path(forResource: "Soundtrack", ofType: "wav")
            self.audioPlayer1 = try! AVAudioPlayer(contentsOf: URL(fileURLWithPath: sound!))
            self.audioPlayer1.play()
            audioPlayer1.volume = 0.03
            audioPlayer1.numberOfLoops = -1
        }
        .onDisappear(perform: {
            storiesStore.reLoad()
            synthesizer.stopSpeaking(at: .immediate)
        })
        .frame(width: UIScreen.main.bounds.size.width)
        .background(Color.backgroundBeige)
        
        
        
    }
    
}



