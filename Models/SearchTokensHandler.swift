import Foundation

struct SearchToken: Codable {
    let name: String
    let kind: SearchKind
}

extension SearchTokensHandler {
    private var searchHistoryKey: String { "searchHistoryKey" }

    /// 検索履歴を保存
    /// - Parameter token: 保存する検索トークン
    func saveSearchToken(_ token: SearchToken) {
        var history = getSearchHistory()
        if let index = history.firstIndex(where: { $0.name == token.name && $0.kind == token.kind }) {
            history.remove(at: index) // 重複を削除
        }
        history.insert(token, at: 0) // 最新のトークンを先頭に追加
        if history.count > 5 {
            history = Array(history.prefix(5)) // 最大5件に制限
        }
        if let encoded = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(encoded, forKey: searchHistoryKey)
        }
    }

    /// 検索履歴を取得
    /// - Returns: 保存された検索トークンの履歴
    func getSearchHistory() -> [SearchToken] {
        guard let data = UserDefaults.standard.data(forKey: searchHistoryKey),
              let history = try? JSONDecoder().decode([SearchToken].self, from: data) else {
            return []
        }
        return history
    }

    /// 再利用可能な検索関数
    /// - Parameters:
    ///   - query: 検索クエリ
    ///   - tokens: 検索対象のトークン配列
    /// - Returns: クエリに一致するトークンの配列
    func searchTokens(with query: String, in tokens: [SearchToken]) -> [SearchToken] {
        return tokens.filter { token in
            token.name.localizedCaseInsensitiveContains(query)
        }
    }
}