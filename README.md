<img width="10%" alt="AppIcon" src="https://github.com/user-attachments/assets/d4f781a7-2a8d-4db5-816e-1e6ef7ddd7e3"/>


## 사하라

> 사진을 포토카드로 만들어 기록, 편집하고 탐색할 수 있는 사진 아카이빙 앱

[AppStore Link](https://apps.apple.com)

<img width="200" height="432" alt="image 6" src="https://github.com/user-attachments/assets/ebc49572-fe97-41d9-bd7d-23a52e8fab55" /> | <img width="200" height="432" alt="image 7" src="https://github.com/user-attachments/assets/14d88123-b9a7-4829-9a07-ecb9c3b9c255" /> | <img width="200" height="432" alt="IMG_2300" src="https://github.com/user-attachments/assets/1f3094b0-e73f-4d6d-bf92-2d3faab62147" /> | <img width="200" height="432" alt="IMG_2492" src="https://github.com/user-attachments/assets/42668ebd-35b2-408c-85d8-8048bac24382" /> |
|:--:|:--:|:--:|:--:|

|구분|내용|
|:--:|:--|
|**팀 인원**|1명 / 기획, 디자인, 개발|
|**기획 및 개발 기간**|2025.09 - 2025.10 (3주, 핵심 개발 기간 1주)|
|**최소지원버전**|iOS 16.0+|

## 핵심 기능

- 사진 촬영 및 포토카드 편집 - 스티커, 필터, 펜, 메모, 사진 분류
- 날짜/지역/테마/폴더별 사진 분류
- 비밀 카드 잠금 설정
- 카드 검색 및 정렬 통계 확인
- 서비스 소식 알림 수신
- 4개 국어 지원(한국어, 영어, 중국어, 일본어)

## 기술 스택

| 분류 | 기술 스택 |
|:--:|:--|
| **UI Framework** | ![UIKit](https://img.shields.io/badge/UIKit-2396F3?style=flat-square&logo=uikit&logoColor=white) ![SnapKit](https://img.shields.io/badge/SnapKit-FF6B6B?style=flat-square&logo=swift&logoColor=white) |
| **Asynchronous Programming** | ![RxSwift](https://img.shields.io/badge/RxSwift-B7178C?style=flat-square&logo=reactivex&logoColor=white) ![RxCocoa](https://img.shields.io/badge/RxCocoa-B7178C?style=flat-square&logo=reactivex&logoColor=white) ![RxDataSources](https://img.shields.io/badge/RxDataSources-B7178C?style=flat-square&logo=reactivex&logoColor=white) |
| **Architecture** | ![MVVM](https://img.shields.io/badge/MVVM-6DB33F?style=flat-square&logo=databricks&logoColor=white) ![Input/Output Pattern](https://img.shields.io/badge/Input%2FOutput_Pattern-6DB33F?style=flat-square&logo=databricks&logoColor=white) |
| **Networking** | ![Alamofire](https://img.shields.io/badge/Alamofire-F05138?style=flat-square&logo=swift&logoColor=white) ![Router Pattern](https://img.shields.io/badge/Router_Pattern-F05138?style=flat-square&logo=swift&logoColor=white) |
| **Database** | ![Realm](https://img.shields.io/badge/Realm-39477F?style=flat-square&logo=realm&logoColor=white) |
| **Libraries** | ![Kingfisher](https://img.shields.io/badge/Kingfisher-FFA500?style=flat-square&logo=swift&logoColor=white) ![DiffableDataSource](https://img.shields.io/badge/DiffableDataSource-147EFB?style=flat-square&logo=apple&logoColor=white) |
| **Apple Frameworks** | ![MapKit](https://img.shields.io/badge/MapKit-007AFF?style=flat-square&logo=apple&logoColor=white) ![PencilKit](https://img.shields.io/badge/PencilKit-007AFF?style=flat-square&logo=apple&logoColor=white) ![CoreLocation](https://img.shields.io/badge/CoreLocation-007AFF?style=flat-square&logo=apple&logoColor=white) ![AVFoundation](https://img.shields.io/badge/AVFoundation-007AFF?style=flat-square&logo=apple&logoColor=white) ![CoreImage](https://img.shields.io/badge/CoreImage-007AFF?style=flat-square&logo=apple&logoColor=white) ![Photos](https://img.shields.io/badge/Photos-007AFF?style=flat-square&logo=apple&logoColor=white) ![PhotosUI](https://img.shields.io/badge/PhotosUI-007AFF?style=flat-square&logo=apple&logoColor=white) ![LocalAuthentication](https://img.shields.io/badge/LocalAuthentication-007AFF?style=flat-square&logo=apple&logoColor=white) |
| **Tools** | ![Xcode](https://img.shields.io/badge/Xcode-147EFB?style=flat-square&logo=xcode&logoColor=white) ![Git](https://img.shields.io/badge/Git-F05032?style=flat-square&logo=git&logoColor=white) |
| **Testing** | ![XCTest](https://img.shields.io/badge/XCTest-6C757D?style=flat-square&logo=xcode&logoColor=white) |
| **Firebase** | ![Firebase Analytics](https://img.shields.io/badge/Analytics-FFCA28?style=flat-square&logo=firebase&logoColor=black) ![Firebase Crashlytics](https://img.shields.io/badge/Crashlytics-FFCA28?style=flat-square&logo=firebase&logoColor=black) ![Firebase Cloud Messaging](https://img.shields.io/badge/Cloud_Messaging-FFCA28?style=flat-square&logo=firebase&logoColor=black) |

### 전체 구조
**MVVM + Reactive Programming + Input/Output**

- Protocol 기반 DI를 적용해 데이터 레이어 의존성 분리, 테스트 용이성 확보
- 외부 의존성인 데이터베이스, 네트워크만 DI로 분리하여 핵심 비즈니스 로직 테스트
- 도메인 요구사항의 잦은 변화로 인해 과도한 추상화 배제, MVVM으로 관심사 분리

### 데이터 관리
**데이터베이스 설계**
- Card-Sticker 1:N 정규화 관계 설계
- 날짜 기반 인덱스 활용하여 쿼리 최적화
- 데이터베이스 변경사항 발생시 Observable 스트림으로 UI 실시간 동기화

**DTO 패턴**

- Realm 객체의 스레드 제약을 DTO 변환으로 해결하여 안전하게 데이터 전달
- View는 DTO만 참조하여 write 트랜잭션 충돌 방지

### 캐싱

**이미지 캐싱 전략 (Kingfisher)**

- 메모리 캐시는 100MB 또는 100개 초과 시, 디스크 캐시 는 500MB 초과 시 LRU 방식 삭제로 용량 제한
- 메모리 캐시는 10분 후 자동 삭제, 캐시는 디스크 7일 후 자동 삭제로 시간 제한
- Downsampling을 활용하여 썸네일 200x200, 실사용은 뷰 크기 이미지 사용

## 구현 기능

### 갤러리

<img width="200" height="432" alt="1" src="https://github.com/user-attachments/assets/882bd3a4-acc5-4733-88f9-f53329e5ec7a" />| <img width="200" height="432" alt="2" src="https://github.com/user-attachments/assets/cfe56732-1b8d-4fdf-b0d8-af7d13dc30dd" /> | <img width="200" height="432" alt="3" src="https://github.com/user-attachments/assets/378b1819-cbb2-4769-b606-c3e49088df82" /> | <img width="200" height="432" alt="4" src="https://github.com/user-attachments/assets/f5dcd35f-f981-4105-ab9e-fbc20759204f" />
|:--:|:--:|:--:|:--:|

#### 날짜별 보기

- 월별 캘린더 뷰(Custom Calendar)
- 각 날짜에 최대 4개 표시 (레이아웃 3개)
- 동적 미니/최대 레이아웃 (1개/2개/3개 지도 배치)
- 월 이동, 오늘 날짜 하이라이트

#### 장소별 보기

- MapKit 기반 지도
- 줌 레벨에 따라 핀 클러스터링
- 대표 이미지 표시 (점유 여때에 따라 우선순위 클러스터 정렬)
- 클러스터 개수 표시

</td>
<td width="50%">

#### 주제별 보기

- Vision Framework 지능 분류 (사람/음식/식물/동물/중국어 간체)

#### 폴더별 보기

- 커스텀 폴더 생성/색상/센상
- 폴더별 카드 필터링

### 편집

| <img width="200" height="432" alt="5" src="https://github.com/user-attachments/assets/8208dfbc-949f-4ca3-a305-0f884c32ef51" /> | <img width="200" height="432" alt="6" src="https://github.com/user-attachments/assets/5a6f5c51-575a-45b0-b046-be94d8f8cdf6" /> | <img width="200" height="432" alt="7" src="https://github.com/user-attachments/assets/700802f3-1300-4751-abe7-029cc8b0b1e2" /> |
|:--:|:--:|:--:|
| <img width="200" height="432" alt="8" src="https://github.com/user-attachments/assets/1e8ccdc0-26c2-4280-bfe1-fa5f10846789" /> | <img width="200" height="432" alt="9" src="https://github.com/user-attachments/assets/9dcd86ce-df34-4d9c-b9d7-fd23978063ab" /> | <img width="200" height="432" alt="10" src="https://github.com/user-attachments/assets/81ff99dd-0baa-415e-9b9c-2cd20002db5d" /> |


#### 스티커

- RESTful API + offset 기반 페이지네이션
- 드래그/핀치/회전 제스처 지원
- 신규 스티커 추가 (사진 라이브러리 접근)
- 다중 스티커 배치 지원
- 신규 스티커 추가 시 템플릿에서 선택 가능하도록 틀 제공

#### 그리기(PencilKit)

- 자유 그리기
- 실행 취소/재실행 기능

#### 필터

- 10가지 필터 제공
- 실시간 프리뷰

#### 자료 기입

- 날짜 입력 (OCR 자동 추출, 디폴트 오늘)
- 메모 입력 (OCR 텍스트 Vision Framework 추출)
- 위치 검색 (MapKit 장소 검색, 현재 위치)
- 폴더 선택
- 생체 인증 (Face ID/Touch ID, 실패 시 기기 비밀번호 사용)


### 카드작성
| <img width="200" height="432" alt="11" src="https://github.com/user-attachments/assets/f566fd4b-bc78-4416-88fe-072b4ccf1844" /> | <img width="200" height="432" alt="12" src="https://github.com/user-attachments/assets/cfaec52e-9a9a-4100-af58-a68119a91355" /> | <img width="200" height="432" alt="13" src="https://github.com/user-attachments/assets/d1d299d5-b553-4677-89f6-c965766d77ba" /> | 
|:--:|:--:|:--:|
| <img width="200" height="432" alt="14" src="https://github.com/user-attachments/assets/0da397c0-489c-4831-893f-41119f64d6a0" /> | <img width="200" height="432" alt="15" src="https://github.com/user-attachments/assets/3e315a7c-f4a3-47fe-9d17-03ce45c0ef81" /> |


#### 미디어 선택

- 시스템 카메라/앨범
- Photo Picker (전체 라이브러리 접근)
- 권한 기반 위치 그리드 (GPS/내재 메타데이터 포함)
- Limited/Authorized 권한별 그리드 데이터 템플릿
- 그리드 표시 후 내/외부에서 선택 가능하도록 기능 제공

#### 카드 정보 입력

- 날짜 선택
- 메모 입력 (OCR 텍스트 Vision Framework 추출)
- 위치 검색 (MapKit 장소 검색, 현재 위치)
- 폴더 선택
- 생체 인증 (Face ID/Touch ID 생체 인증, 실패 시 기기 비밀번호 사용)


### 검색 / 통계 / 설정

| <img width="200" height="432" alt="16" src="https://github.com/user-attachments/assets/1f361e67-a8a5-483a-be8f-f91d2417beda" /> | <img width="200" height="432" alt="17" src="https://github.com/user-attachments/assets/6c95ee8a-a3e6-42f7-8a39-c5ed2e69eecf" /> | <img width="20 0" height="432" alt="18" src="https://github.com/user-attachments/assets/5722358d-ec7c-401c-bdd2-35512934c38e" /> | <img width="200" height="432" alt="19" src="https://github.com/user-attachments/assets/55ae5a9a-cb0a-4a4a-aad4-7747268aff70" /> |
|:--:|:--:|:--:|:--:|

### 실시간 검색

- 메모 (서브텍스트 검색) 입력, OCR 텍스트 (Vision Framework 추출) 검색
- Masonry Layout 그리드

### 통계

- 총 카드 수 / 이번 달 카드 수 / 연속 작성 일수 (Streak) 통계
- 막대 차트

### 설정

**일반**
- 언어 선택 (한국어/영어/일본어/중국어 간체)

**알림**
- 서비스 소식 토픽 구독 방식 FCM Topic 구독 관리

**지원**
- 앱 메일을 활용한 개발자 문의
- 기기 정보 자동 수집
- 버전별 변경사항 릴리즈 노트
