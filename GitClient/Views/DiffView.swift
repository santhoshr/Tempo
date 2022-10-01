//
//  DiffView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/10/01.
//

import SwiftUI

struct DiffView: View {
    var diff: String

    var body: some View {
        ScrollView {
            Text(diff)
                .textSelection(.enabled)
                .font(Font.system(.body, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .safeAreaInset(edge: .bottom) {
            VStack (spacing: 0) {
                Divider()
                HStack {
                    Spacer()
                    Button("Commit") {

                    }
                    .padding()
                }
                .background(.regularMaterial)
            }
        }
    }
}

struct DiffView_Previews: PreviewProvider {
    static var previews: some View {
        DiffView(diff: """
diff --git a/GitClient/Views/DiffView.swift b/GitClient/Views/DiffView.swift
index 0cd5c16..114b4ae 100644
--- a/GitClient/Views/DiffView.swift
+++ b/GitClient/Views/DiffView.swift
@@ -11,11 +11,25 @@ struct DiffView: View {
     var diff: String

     var body: some View {
-        ScrollView {
-            Text(diff)
-                .font(Font.system(.body, design: .monospaced))
-                .frame(maxWidth: .infinity, alignment: .leading)
-                .padding()
+        ZStack {
+            ScrollView {
+                Text(diff)
+                    .textSelection(.enabled)
+                    .font(Font.system(.body, design: .monospaced))
+                    .frame(maxWidth: .infinity, alignment: .leading)
+                    .padding()
+            }
+            VStack {
+                Spacer()
+                HStack {
+                    Spacer()
+                    Button("Commit") {
+
+                    }
+                    .padding()
+                }
+                .background(.ultraThinMaterial)
+            }
         }
     }
 }
diff --git a/GitClient/Views/DiffView.swift b/GitClient/Views/DiffView.swift
index 0cd5c16..114b4ae 100644
--- a/GitClient/Views/DiffView.swift
+++ b/GitClient/Views/DiffView.swift
@@ -11,11 +11,25 @@ struct DiffView: View {
     var diff: String

     var body: some View {
-        ScrollView {
-            Text(diff)
-                .font(Font.system(.body, design: .monospaced))
-                .frame(maxWidth: .infinity, alignment: .leading)
-                .padding()
+        ZStack {
+            ScrollView {
+                Text(diff)
+                    .textSelection(.enabled)
+                    .font(Font.system(.body, design: .monospaced))
+                    .frame(maxWidth: .infinity, alignment: .leading)
+                    .padding()
+            }
+            VStack {
+                Spacer()
+                HStack {
+                    Spacer()
+                    Button("Commit") {
+
+                    }
+                    .padding()
+                }
+                .background(.ultraThinMaterial)
+            }
         }
     }
 }

""")
    }
}
