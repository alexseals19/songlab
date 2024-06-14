//
//  RecordingCard.swift
//  SongLab
//
//  Created by Alex Seals on 6/2/24.
//

import SwiftUI

struct RecordingCell: View {
        
    // MARK: - API
    
    init(
        currentlyPlaying: Session?,
        session: Session,
        playButtonAction: @escaping (_: Session) -> Void,
        stopButtonAction: @escaping () -> Void,
        trashButtonAction: @escaping (_: Session) -> Void
    ) {
        self.currentlyPlaying = currentlyPlaying
        self.session = session
        self.playButtonAction = playButtonAction
        self.stopButtonAction = stopButtonAction
        self.trashButtonAction = trashButtonAction
    }
    
    // MARK: - Variables
        
    private var session: Session
    private var currentlyPlaying: Session?
        
    private let playButtonAction: (_ session: Session) -> Void
    private let stopButtonAction: () -> Void
    private let trashButtonAction: (_ session: Session) -> Void
    
    // MARK: - Body
    
    var body: some View {
        VStack {
            Divider()
            HStack {
                VStack(alignment: .leading) {
                    HStack() {
                        Text(session.name + " |")
                        Text(session.lengthDisplayString)
                            .font(.caption)
                    }
                    .padding(.top, 7)
                    .padding(.bottom, 1)
                    Text(session.dateDisplayString)
                        .font(.caption)
                        .padding(.bottom, 7)
                }
                .padding(.leading, 15)
                
                Spacer()
                
                trashButton
                playbackButton
                
            }
            Divider()
        }
        .foregroundColor(.primary)
    }
    
    var trashButton: some View {
        Button {
            trashButtonAction(session)
        } label: {
            Image(systemName: "trash")
        }
    }
    
    var playbackButton: some View {
        Button {
            if let currentlyPlaying, currentlyPlaying == session {
                stopButtonAction()
            } else {
                playButtonAction(session)
            }
        } label: {
            if let currentlyPlaying, currentlyPlaying == session {
                Image(systemName: "pause")
                    .resizable()
                    .frame(width: 12, height: 16)
                    .padding(.trailing, 15)
            } else {
                Image(systemName: "play")
                    .resizable()
                    .frame(width: 16, height: 20)
                    .padding(.trailing, 15)
            }
        }
        .foregroundColor(.primary)
    }
}

#Preview {
    
    RecordingCell(
        currentlyPlaying: nil,
        session: Session(
            name: "RecordingFixture",
            date: Date(),
            length: .seconds(4),
            tracks: [],
            id: UUID()
        ),
        playButtonAction: { _ in },
        stopButtonAction: {},
        trashButtonAction: { _ in }
    )
        .padding(.horizontal)
}
