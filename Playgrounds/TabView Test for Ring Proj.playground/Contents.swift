//        TabView {
//                   ButtonView()
//                       .tabItem {
//                           Image(systemName: "house.fill")
//                           Text("Home")
//                       }
//                   AddView()
//                       .tabItem {
//                           Image(systemName: "plus.circle.fill")
//                               .font(.system(size: 44, weight: .ultraLight))
//                               .foregroundColor(.blue)
//                       }
//                   CameraView()
//                       .tabItem {
//                           Image(systemName: "chart.bar.fill")
//                           Text("Graphs")
//                       }
//               }

//struct GraphsView: View {
//    let cameraView = CameraView()
//    var body: some View {
//        ZStack {
//            cameraView
//                .frame(height: 200)
//                .onAppear {
//                    cameraView.startSession()
//                }
//                .onDisappear {
//                    cameraView.stopSession()
//                }
//        }
//    }
//}
