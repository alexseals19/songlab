//
//  MasterCellView.swift
//  SongLab
//
//  Created by Alex Seals on 6/12/24.
//

import SwiftUI

struct MasterCellView: View {
    
    //MARK: - API
    
    init(session: Session, 
         currentlyPlaying: Session?,
         useGlobalBpm: Binding<Bool>,
         sessionBpm: Binding<Int>,
         playButtonAction: @escaping (_: Session) -> Void,
         stopButtonAction: @escaping () -> Void,
         globalSoloButtonAction: @escaping () -> Void,
         restartButtonAction: @escaping () -> Void,
         setBpmButtonAction: @escaping (_: Int) -> Void
    ) {
        self.session = session
        self.currentlyPlaying = currentlyPlaying
        _isUsingGlobalBpm = useGlobalBpm
        _sessionBpm = sessionBpm
        self.playButtonAction = playButtonAction
        self.stopButtonAction = stopButtonAction
        self.globalSoloButtonAction = globalSoloButtonAction
        self.restartButtonAction = restartButtonAction
        self.setBpmButtonAction = setBpmButtonAction
    }
    
    //MARK: - Variables
    
    @EnvironmentObject private var appTheme: AppTheme
    
    @Binding private var isUsingGlobalBpm: Bool
    @Binding private var sessionBpm: Int
    
    @State private var isEditingBpm: Bool = false
    @State private var bpm: Int = 120
    
    private var session: Session
    private var currentlyPlaying: Session?
    
    private var bpmSectionOpacity: Double {
        isUsingGlobalBpm ? 0.3 : 1.0
    }
        
    private let playButtonAction: (_ session: Session) -> Void
    private let stopButtonAction: () -> Void
    private let globalSoloButtonAction: () -> Void
    private let restartButtonAction: () -> Void
    private let setBpmButtonAction: (_ newBpm: Int) -> Void
    
    //MARK: - Body
    
    var body: some View {
        VStack(spacing: 0.0) {
            VStack {
                Divider()
                HStack {
                    VStack(alignment: .leading) {
                        HStack() {
                            VStack {
                                Text("Master")
                                    .font(.title2)
                                HStack {
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
                            }
                            .padding(.leading, 5)
                            .padding(.trailing, 15)
                            Spacer()
                            RoundedRectangle(cornerRadius: 1)
                                .frame(width: 1, height: 65)
                                .foregroundStyle(.secondary)
                                .opacity(0.5)
                                .padding(.horizontal, 5)
                            Spacer()
                            VStack {
                                HStack {
                                    Button {
                                        if sessionBpm > 0 {
                                            sessionBpm -= 1
                                        }
                                    } label: {
                                        AppButtonLabelView(name: "minus", color: .primary)
                                    }
                                    .buttonRepeatBehavior(.enabled)
                                    Text("BPM")
                                        .frame(width: 40)
                                    Text("\(sessionBpm == 0 ? "--" : "\(sessionBpm)")")
                                        .frame(width: 33)
                                        .foregroundStyle(.secondary)
                                    Button {
                                        if sessionBpm < 300 {
                                            sessionBpm += 1
                                        }
                                    } label: {
                                        AppButtonLabelView(name: "plus", color: .primary)
                                    }
                                    .buttonRepeatBehavior(.enabled)
                                }
                                .opacity(bpmSectionOpacity)
                                useGlobalBpmButtonView
                            }
                            Spacer()
                            RoundedRectangle(cornerRadius: 1)
                                .frame(width: 1, height: 65)
                                .foregroundStyle(.secondary)
                                .opacity(0.5)
                                .padding(.horizontal, 5)
                            Spacer()
                            HStack(spacing: 20) {
                                Button {
                                    restartButtonAction()
                                } label: {
                                    Image(systemName: "gobackward")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 24, height: 24)
                                }
                                PlaybackControlButtonView(
                                    session: session,
                                    currentlyPlaying: currentlyPlaying,
                                    playButtonAction: playButtonAction,
                                    stopButtonAction: stopButtonAction
                                )
                            }
                        }
                    }
                    Spacer()
                }
                Divider()
            }
            .padding(.vertical, 10)
            .foregroundColor(.primary)
            .background(Color(UIColor.systemBackground).opacity(0.3))
        }
    }
    
    var useGlobalBpmButtonView: some View {
        
        Button {
            isUsingGlobalBpm.toggle()
        } label: {
            ZStack {
                if isUsingGlobalBpm {
                    RoundedRectangle(cornerRadius: 5)
                        .frame(width: 75, height: 15)
                        .foregroundStyle(appTheme.accentColor)
                    Text("Use Global")
                        .font(.caption)
                        .foregroundStyle(.black)
                } else {
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(lineWidth: 1.0)
                        .frame(width: 75, height: 15)
                        .foregroundStyle(appTheme.accentColor)
                    Text("Use Global")
                        .font(.caption)
                        .foregroundStyle(.primary)
                }
            }
        }
    }
}

#Preview {
    MasterCellView(
        session: Session.sessionFixture,
        currentlyPlaying: nil,
        useGlobalBpm: .constant(false),
        sessionBpm: .constant(120),
        playButtonAction: { _ in },
        stopButtonAction: {},
        globalSoloButtonAction: {},
        restartButtonAction: {},
        setBpmButtonAction: { _ in }
    )
}
