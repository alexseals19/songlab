//
//  MasterCell.swift
//  SongLab
//
//  Created by Alex Seals on 6/12/24.
//

import SwiftUI

struct MasterCell: View {
    
    //MARK: - API
    
    init(session: Session, 
         currentlyPlaying: Session?,
         playButtonAction: @escaping (_: Session) -> Void,
         stopButtonAction: @escaping () -> Void,
         globalSoloButtonAction: @escaping () -> Void
    ) {
        self.session = session
        self.currentlyPlaying = currentlyPlaying
        self.playButtonAction = playButtonAction
        self.stopButtonAction = stopButtonAction
        self.globalSoloButtonAction = globalSoloButtonAction
    }
    
    //MARK: - Variables
    
    @EnvironmentObject private var appTheme: AppTheme
    
    private var session: Session
    private var currentlyPlaying: Session?
        
    private let playButtonAction: (_ session: Session) -> Void
    private let stopButtonAction: () -> Void
    private let globalSoloButtonAction: () -> Void
    
    //MARK: - Body
    
    var body: some View {
        VStack(spacing: 0.0) {
            Rectangle()
                .frame(maxWidth: .infinity, maxHeight: 1.0)
                .foregroundStyle(appTheme.cellDividerColor)
            VStack {
                Divider()
                HStack {
                    VStack(alignment: .leading) {
                        HStack() {
                            VStack {
                                Text("Master")
                                    .font(.title2)
                                Button {
                                    globalSoloButtonAction()
                                } label: {
                                    HStack {
                                        if session.isGlobalSoloActive {
                                            Image(systemName: "s.square.fill")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 24, height: 24)
                                                .foregroundStyle(.purple)
                                        } else {
                                            Image(systemName: "s.square")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 24, height: 24)
                                        }
                                    }
                                }
                            }
                            .padding(.leading, 5)
                            Spacer()
                            PlaybackControlButtonView(
                                session: session,
                                currentlyPlaying: currentlyPlaying,
                                playButtonAction: playButtonAction,
                                stopButtonAction: stopButtonAction
                            )
                        }
                    }
                    Spacer()
                }
                Divider()
            }
            .padding(.vertical, 10)
            .foregroundColor(.primary)
            .background(appTheme.cellBackground)
        }
    }
}

#Preview {
    MasterCell(
        session: Session.recordingFixture,
        currentlyPlaying: nil,
        playButtonAction: { _ in },
        stopButtonAction: {},
        globalSoloButtonAction: {}
    )
}
