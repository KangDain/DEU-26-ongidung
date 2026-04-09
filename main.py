from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

app = FastAPI()

# 플러터 웹(Chrome)에서 테스트할 때 에러가 나지 않도록 허락(CORS)해주는 세팅
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 프론트에서 받을 데이터의 모양(설계도)을 미리 정해둬
class PurchaseItem(BaseModel):
    title: str
    price: int
    participants: int

# [GET] 데이터 조회 API: 플러터가 데이터 요청 시 이 데이터를 보내줌
@app.get("/api/items")
def get_items():
    return [
        {"id": 1, "title": "햇반 24입 4명 나눠요", "price": 5000, "participants": 1},
        {"id": 2, "title": "자취생 두루마리 휴지 30롤 쉐어", "price": 8000, "participants": 2}
    ]

# [POST] 데이터 생성 API: 플러터가 등록 요청 시 데이터를 보내면 받음
@app.post("/api/items")
def create_item(item: PurchaseItem):
    # DB(SQLite)에 데이터를 저장하는 코드가 들어감
    return {"message": "공동구매 등록 성공!", "data": item}