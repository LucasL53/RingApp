//: A UIKit based Playground for presenting user interface

import SwiftUI
import PlaygroundSupport

struct ContentView: View{
    @State private var toggleTest: Bool = false
    var body: some View{
        Button {
            print("Smart TV clicked")
        } label: {
            Image(systemName: "pencil")
            Toggle(isOn: $toggleTest){
                Text("Smart TV")
            }
        }.padding(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
    }
}

struct ContentView_Previews:
    PreviewProvider{
    static var previews: some View{
        ContentView()
    }
}
// Present the view controller in the Live View window
//PlaygroundPage.current.liveView = MyViewController()
