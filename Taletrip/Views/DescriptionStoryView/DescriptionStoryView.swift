//
//  DescriptionView.swift
//  Taletrip
//
//  Created by Davide Biancardi on 22/02/22.
//

import SwiftUI

struct DescriptionStoryView: View {
    
    let story: Story
    @Binding var showModal : Bool
    
    
    var body: some View {
        
        ZStack{
            
            VStack(spacing: 10){
                DescriptionImageView(imageName: story.imageName)
                
                DescriptionTextView(descriptionOfTheStory: story.description, titleOfTheStory: story.title, genre: story.genre.rawValue,author:story.author)
                
            }
            
            StatusBarDescriptionStoryView(lengthOfTheStory: story.length,showModal: $showModal)
                .frame(maxHeight:.infinity,alignment: .top)
                .padding(.top,5)
            
            
            SuyashButton(textOfTheButton: "Play", sfSymbol: "play.fill")
                .frame(maxHeight:.infinity,alignment: .bottom)
                .padding(.bottom,22)
           
            
            
        }.ignoresSafeArea().statusBar(hidden: true)
            .background(Color.backgroundBeige)
    }
}




struct DescriptionStoryView_Previews: PreviewProvider {
    
    static var viewModel = StoriesStore()
    
    static var previews: some View {
        
        DescriptionStoryView(story: viewModel.stories[0],showModal: .constant(true))
        
    }
}