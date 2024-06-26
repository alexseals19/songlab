//
//  TrackCell.swift
//  SongLab
//
//  Created by Alex Seals on 6/12/24.
//

import SwiftUI

struct TrackCell: View {
    
    //MARK: - API
        
    init(
        track: Track,
        isGlobalSoloActive: Bool,
        muteButtonAction: @escaping (_: Track) -> Void,
        soloButtonAction: @escaping (_: Track) -> Void,
        onTrackVolumeChange: @escaping (_: Track, _ : Double) -> Void
    ) {
        self.track = track
        self.isGlobalSoloActive = isGlobalSoloActive
        self.muteButtonAction = muteButtonAction
        self.soloButtonAction = soloButtonAction
        self.onTrackVolumeChange = onTrackVolumeChange
        self.sliderValue = Double(track.volume)
    }
    
    //MARK: - Variables
    
    @EnvironmentObject private var appTheme: AppTheme
    
    @State private var isShowingVolumeSlider: Bool = true
    @State private var sliderValue: Double
    
    private var track: Track
    private var isGlobalSoloActive: Bool
    
    private let muteButtonAction: (_: Track) -> Void
    private let soloButtonAction: (_: Track) -> Void
    private let onTrackVolumeChange: (_: Track, _ : Double) -> Void
    
    //MARK: - Body
        
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text(track.name)
                        .font(.title3)
                    Text(track.lengthDisplayString)
                        .font(.caption)
                }
                Spacer()
                HStack {
                    Button {
                        soloButtonAction(track)
                    } label: {
                        if track.isSolo, isGlobalSoloActive {
                            TrackCellButtonImage("s.square.fill")
                                .foregroundStyle(.purple)
                        } else {
                            TrackCellButtonImage("s.square")
                        }
                    }
                    
                    Button {
                        muteButtonAction(track)
                    } label: {
                        if track.isMuted {
                            TrackCellButtonImage("m.square.fill")
                                .foregroundStyle(.pink)
                        } else {
                            TrackCellButtonImage("m.square")
                        }
                    }
                }
            }
            Divider()
            HStack {
                Image(systemName: "dial.medium")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 26, height: 26)
                Slider(value: $sliderValue)
                    .tint(.primary)
                    .padding(.trailing, 10)
                    .onChange(of: sliderValue) {
                        onTrackVolumeChange(track, sliderValue)
                    }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .foregroundColor(.primary)
        .background(appTheme.cellBackground)
    }
}

struct TrackCellButtonImage: View {
    let imageName: String
    
    init(_ imageName: String) {
        self.imageName = imageName
    }
    
    var body: some View {
        Image(systemName: imageName)
            .resizable()
            .frame(width: 24, height: 24)
            .aspectRatio(contentMode: .fit)
    }
}

#Preview {
    TrackCell(
        track: Track(
            name: "track 1",
            fileName: "",
            date: Date(),
            length: .seconds(2),
            id: UUID(),
            volume: 1.0,
            isMuted: false,
            isSolo: false
        ),
        isGlobalSoloActive: false,
        muteButtonAction: { _ in },
        soloButtonAction: { _ in },
        onTrackVolumeChange: { _ , _ in }
    )
}
