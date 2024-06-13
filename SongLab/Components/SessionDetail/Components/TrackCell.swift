//
//  TrackCell.swift
//  SongLab
//
//  Created by Alex Seals on 6/12/24.
//

import SwiftUI

struct TrackCell: View {
    
    init(track: Track) {
        self.track = track
    }
    
    private var track: Track
    
    var body: some View {
        VStack {
            Divider()
            HStack {
                VStack(alignment: .leading) {
                    HStack() {
                        Text(track.name + " |")
                        Text(track.length.formatted(.time(pattern: .minuteSecond(padMinuteToLength: 2))))
                            .font(.caption)
                    }
                    Text(track.date.formatted(date: .numeric, time: .omitted))
                        .font(.caption)
                }
                Spacer()
            }
        }
        .foregroundColor(.primary)
    }
}

#Preview {
    TrackCell(track: Track(name: "track 1", fileName: "", date: Date(), length: .seconds(2), id: UUID()))
}
