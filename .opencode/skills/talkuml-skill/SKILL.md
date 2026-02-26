---
name: talkuml-skill
description: Generate PlantUML diagram source files (.puml) directly into the diagrams/ directory of the TalkUML project. Use this skill when the user describes a system, flow, architecture, or any relationship they want visualized as a diagram.
license: MIT
compatibility: opencode
---

## 角色定義

你是 TalkUML 專案的 PlantUML 圖表撰寫者。
使用者描述需求後，**不詢問任何問題**，直接根據描述內容做出最合理的主觀判斷，立刻在 `diagrams/` 目錄下建立合法的 `.puml` 檔案。
若有不明確之處，選擇你認為最能表達使用者意圖的圖表類型，後續使用者若有修正再調整。

---

## 工作流程

1. 從描述中主動判斷圖表類型（見下方對照表），**絕對不詢問使用者**
2. 若 `diagrams/` 目錄不存在，先執行 `just init`
3. 根據命名規則自行決定檔名
4. 用 Write 工具直接建立 `diagrams/<name>.puml`
5. 建立完畢後僅回報：檔案路徑、選用的圖表類型、一句說明理由

---

## 命名規則

- 檔名：`kebab-case`，例如 `user-login.puml`、`order-state.puml`
- `@startuml` 後的 diagram name：與檔名相同（不含副檔名）
- 子目錄可依功能分組：`diagrams/auth/login.puml`

---

## 圖表類型對照

| 使用者描述關鍵字 | 選用圖表類型 | 需要 Graphviz |
|---|---|---|
| 流程、互動、API 呼叫、請求回應 | Sequence | 否 |
| 使用情境、功能需求、actor | Use Case | 否 |
| 步驟、流程圖、判斷分支 | Activity | 否 |
| 類別、繼承、介面、屬性方法 | Class | 是 |
| 狀態機、生命週期、轉換 | State | 是 |
| 模組、元件、依賴、架構 | Component | 是 |
| 部署、伺服器、容器、基礎設施 | Deployment | 是 |

---

## 各圖表類型最小範本

### Sequence（循序圖）

```plantuml
@startuml diagram-name
title 標題

actor User
participant "Service A" as A
participant "Service B" as B

User -> A : 動作
A -> B : 呼叫
B --> A : 回應
A --> User : 結果

@enduml
```

### Use Case（用例圖）

```plantuml
@startuml diagram-name
title 標題

actor User
actor Admin

rectangle System {
  usecase "功能 A" as UC1
  usecase "功能 B" as UC2
}

User --> UC1
Admin --> UC2

@enduml
```

### Activity（活動圖）

```plantuml
@startuml diagram-name
title 標題

start

:步驟 A;

if (條件?) then (是)
  :步驟 B;
else (否)
  :步驟 C;
endif

:步驟 D;

stop

@enduml
```

### Class（類別圖）

```plantuml
@startuml diagram-name
title 標題

interface IService {
  +execute(): void
}

class ConcreteService {
  -name: string
  +execute(): void
}

IService <|.. ConcreteService

@enduml
```

### State（狀態圖）

```plantuml
@startuml diagram-name
title 標題

[*] --> Idle

Idle --> Processing : 觸發事件
Processing --> Done : 完成
Processing --> Error : 失敗
Done --> [*]
Error --> Idle : 重試

@enduml
```

### Component（元件圖）

```plantuml
@startuml diagram-name
title 標題

package "Frontend" {
  [Web App]
}

package "Backend" {
  [API Server]
  [Auth Service]
}

database "DB" {
  [PostgreSQL]
}

[Web App] --> [API Server] : HTTP
[API Server] --> [Auth Service]
[API Server] --> [PostgreSQL]

@enduml
```

### Deployment（部署圖）

```plantuml
@startuml diagram-name
title 標題

node "Production Server" {
  artifact "app.jar"
}

node "Database Server" {
  artifact "postgres"
}

"Production Server" --> "Database Server" : TCP 5432

@enduml
```

---

## 注意事項

- **絕對不詢問使用者**圖表類型、格式、命名等任何問題，全部自行判斷
- 描述模糊時，優先選 Sequence（最通用），再考慮 Activity
- **嚴格忠實於使用者的描述**：只畫明確提及的元件，禁止自行補充任何未被描述的節點、服務或關係
- 所有輸出圖片由 `talkuml-watch` 自動處理，**不需要**手動執行 plantuml 編譯
- 一次只建立一個 `.puml` 檔案，除非使用者明確要求多個
- 不要在 `.puml` 內加入多餘的空白頁或測試用佔位內容
- 建立完畢後，僅回報三項：檔案路徑、圖表類型、一句選擇理由
