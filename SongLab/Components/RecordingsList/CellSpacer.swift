//
//  RecordingCard.swift
//  SongLab
//
//  Created by Alex Seals on 6/2/24.
//

import SwiftUI

struct CellSpacer: View {
    
    // MARK: - API
    
    var screenHeight: CGFloat
    var numberOfSessions: Int
        
    // MARK: - Variables
    
    @EnvironmentObject private var appTheme: AppTheme
    
    private var height: Double {
        let height = (screenHeight - (Double(numberOfSessions) * (65.653320 + 1))) + 25
        if height > 150 {
            return height + screenHeight
        } else {
            return 150.0 + screenHeight
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0.0) {
            Rectangle()
                .frame(maxWidth: .infinity, maxHeight: 1.0)
                .foregroundStyle(appTheme.cellDividerColor)
            ZStack {
                Color.clear
                    .frame(maxWidth: .infinity, minHeight: 150)
                    .frame(height: height)
                    .ignoresSafeArea()
                    .background(.ultraThinMaterial.opacity(appTheme.cellMaterialOpacity))
                    .background(appTheme.cellColor)
                    .padding(.bottom, -height + 225)
                if numberOfSessions == 0 {
                    Text("Create your first recording!")
                        .font(.title)
                        .offset(y: 300)
                }
            }
        }
    }
}

#Preview {
    CellSpacer(screenHeight: 150, numberOfSessions: 0)
}
