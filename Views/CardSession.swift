//
//  CardSession.swift
//  Flashcard
//
//  Created by Secret Asian Man Dev on 19/7/20.
//

import SwiftUI
import CoreData

struct CardSession: View {
    
    @Environment(\.managedObjectContext) var moc
    @Environment(\.presentationMode) var presentationMode
    @State private var cards: [FlashCard]
    
    enum SessionType {
        case nPull(Int) // pull only an integer number of cards. no repeats
        case marathon // pull every card in the deck
        case training // pull any card in the deck, but allow repeats of wrong cards
    }
    
    var deck: Deck
    var sessionType: SessionType
    
    private var promptTypes = [Snippet]()
    private var answerTypes = [Snippet]()
    
    init(deck: Deck, sessionType: SessionType) {
        self.deck = deck
        self.sessionType = sessionType
        #warning("variable here for whether or not to cycle cards")
        
        /// NOTE: this direct binding was undocumented and hacky. Only here because this view does NOT need to update the parent.
        _cards = State(initialValue: deck.flashcards)
        promptTypes = deck.getPromptTypes(context: moc)
        answerTypes = deck.getAnswerTypes(context: moc)
    }
    
    var body: some View {
        ZStack {
            ForEach(cards, id: \.id) { card in
                CardView(
                    card: card,
                    promptTypes: promptTypes,
                    answerTypes: answerTypes,
                    removal: remove
                )
                    .stacked(
                        at: cards.firstIndex(where: {$0.id == card.id})!,
                        in: cards.count
                    )
            }
        }
        .onChange(of: cards){
            guard $0.count == 0 else { return }
            /// on exit, save changes to card history
            try! moc.save()
            presentationMode.wrappedValue.dismiss()
        }
        .navigationBarHidden(true)
    }
    
    func remove(card: FlashCard, correct: Bool) -> Void {
        /// fetch corresponding card from core data
        let test = deck.getChosenTest(context: moc)
        if test.history[card.objID!] != nil {
            test.history[card.objID!]!.append(correct)
        } else {
            test.history[card.objID!] = [correct]
        }
        
        withAnimation {
            let card = cards.remove(at: cards.firstIndex(where: {$0.id == card.id})!)
            if !correct {
                /// if it was the last card, just stop
                guard cards.count > 1 else { return }
                /// re-insert the card at a random index
                cards.insert(
                    card.copy(),
                    at: Int.random(in: 1..<cards.count)
                )
            }
        }
    }
}


extension View {
    func stacked(at position: Int, in total: Int) -> some View {
        var scale = CGFloat.zero
        switch total - position {
        case 1: scale = 1 /// current card
        case 2: scale = 0.8 /// next card
        default: scale = 0.5 /// all other cards
        }
        /// add 1 due to zero indexing, so front card is always 100% of size
        return self
            .scaleEffect(scale)
    }
}
