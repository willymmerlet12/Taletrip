//
//  HomeView.swift
//  Taletrip
//
//  Created by Davide Biancardi on 21/02/22.
//

import SwiftUI

struct StoriesView: View {
    
    @StateObject var storiesStore = StoriesStore()
    
    @State var showModal : Bool = false
    @State var isActive: Bool = false
   
    init() {
        
        UITableView.appearance().separatorStyle = .singleLine
        
    }
    
    let impact = UIImpactFeedbackGenerator(style: .soft)
    
    
    var body: some View {
        
        NavigationView{
            if self.isActive {
            ScrollView(showsIndicators: false){
                
                VStack(alignment: .center, spacing: 35){
                    
                    TextView(title: "Stories",size: 37,weight: .bold)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                        .padding(.leading,40)
                    
                    //   Story You will Like
                    if let storyYouWillLike = storiesStore.storyYouWillLike{
                        
                        HighlightedCardView(storyToBeHighlighted: storyYouWillLike,title: "Story You'll Like")
                            
                            .onTapGesture {
                                impact.impactOccurred()
                                showModal.toggle()
                                storiesStore.showStory(of: storyYouWillLike)
                                
                            }
                        
                    }
                    
                    //    All Adventures
                    
                    HorizontalCardsView(stories: storiesStore.adventureStories,title: "Adventure",showModal: $showModal)
                    
                    //    Story Of the  Month
                   
                    if let storyOfTheMonth = storiesStore.storyOfTheMonth{
                        
                        HighlightedCardView(storyToBeHighlighted: storyOfTheMonth,title: "Story Of The Month")
                            
                            .onTapGesture {
                                impact.impactOccurred()
                                showModal.toggle()
                                storiesStore.showStory(of: storyOfTheMonth)
                                 
                            }
                        
                    }
                    
                }.frame(maxWidth:.infinity,alignment: .leading)
                    
                    .navigationBarHidden(true)
                
            }.fullScreenCover(isPresented: $showModal){
                
                
                DescriptionStoryView(story: storiesStore.tappedStory,showModal: $showModal)
                
                
            }
            } else {
                withAnimation{
                    LaunchScreen()
                        .onDisappear{
                            withAnimation{
                            
                            }
                        }
                      //  .animation(.easeInOut(duration: 1))
                }
               
            }
            
        }
        .padding(.top, isActive ? 1 : -10)
            .environmentObject(storiesStore)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.7) {
                    withAnimation {
                        self.isActive = true
                    }
                }
            }
            .transition(.scale)
    }
}

struct StoriesView_Previews: PreviewProvider {
    static var previews: some View {
        StoriesView()
    }
}


struct HiddenNavigationBar: ViewModifier {
    func body(content: Content) -> some View {
        content
        .navigationBarTitle("", displayMode: .inline)
        .navigationBarHidden(true)
    }
}

extension View {
    func hiddenNavigationBarStyle() -> some View {
        modifier(HiddenNavigationBar())
    }
}
