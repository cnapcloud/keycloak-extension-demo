# Keycloak Extension Demo

로컬에서 Keycloak SPI 확장 기능을 직접 체험해볼 수 있는 데모 환경입니다.
OTP 인증, 간편인증, 약관 동의, 휴면 계정 관리 등 실제 서비스에서 자주 필요한 기능들을 Docker Compose로 간편하게 실행할 수 있습니다.

---

## 목차

1. [실행 방법](#1-실행-방법)
2. [서비스 접속 URL](#2-서비스-접속-url)
3. [Keycloak React 데모](#3-keycloak-react-데모)
4. [Admin Console](#4-admin-console)
5. [환경 변수 설정](#5-환경-변수-설정)
6. [Make 명령어](#6-make-명령어)
7. [참고 자료](#7-참고-자료)

---

## 1. 실행 방법

Docker Desktop만 설치되어 있으면 됩니다.

```bash
make up
```

처음 실행하면 Keycloak 기동까지 **2~3분** 정도 걸립니다. 기다리는 동안 내부적으로 다음과 같은 작업이 진행됩니다.

```
postgres      → DB 준비
keycloak-init → SPI JAR 복사
keycloak      → 서버 기동
keycloak-cli  → cnap Realm 생성 + 초기 관리자 계정 등록
그 외          → rabbitmq, mailhog, user-storage, react-demo, inicis-mock
```

준비가 완료되면 아래 주소들로 접속할 수 있습니다.

---

## 2. 서비스 접속 URL

| 서비스 | 주소 | 설명 |
|---|---|---|
| **React 인증 데모** | http://localhost:5173 | 로그인·회원가입·간편인증 E2E 체험 |
| **Keycloak** | http://localhost:8080 | Keycloak 서버 |
| **간편인증 Mock** | http://localhost:9091 | 이니시스 인증 Mock 서버 |
| **Mailhog** | http://localhost:8025 | 발송된 이메일 확인 |
| **RabbitMQ** | http://localhost:15672 | 사용자 이벤트 메시지 확인 (`admin` / `password`) |
| **User Storage** | http://localhost:8090 | 외부 사용자 저장소 REST API |
| **User Storage DB** | http://localhost:8090/h2-console | H2 DB 스키마·데이터 조회 (`JDBC URL: jdbc:h2:mem:testdb` / `sa` / `password`) |

---

## 3. Keycloak React 데모

http://localhost:5173 을 열면 실제 로그인 화면이 나옵니다.

> 개발 환경에서는 OTP 입력란에 **`000000`** 을 입력하면 항상 통과됩니다. (`OTP_DEV_MODE=true`)

### 로그인

1. 아이디 + 비밀번호 입력 (`admin` / `password`)
2. OTP 인증 — SMS 또는 이메일 (`000000`)
3. 약관 미동의 상태면 약관 동의 화면이 먼저 뜹니다

### 간편인증 (KG Inicis)

1. 로그인 화면에서 **간편인증** 버튼 클릭
2. Mock 서버(http://localhost:9091)로 이동해 인증
3. 완료되면 동일 전화번호로 가입된 계정과 자동 연동

> 간편인증은 신규 가입이 아닙니다. 먼저 일반 회원가입을 하고 나서 연동하는 흐름입니다.

### 카카오 / 네이버 로그인

> Admin Console → **Identity Providers** 에서 카카오·네이버 OAuth Client ID 및 Secret을 설정한 후에만 사용할 수 있습니다.
> 설정 방법은 [docs/02-installation.md](docs/02-installation.md) 10절을 참고하세요.

1. 로그인 화면에서 **카카오** 또는 **네이버** 버튼 클릭
2. 각 소셜 서비스 OAuth 인증 완료
3. 가입 시 사용한 이메일과 일치하는 계정과 자동 연동

### 회원가입

1. 약관 동의 (필수 / 선택 구분)
2. 아이디 · 이메일 · 전화번호 · 비밀번호 입력
3. 이메일 또는 SMS OTP 인증 (개발 환경: `000000`)

### ID 찾기

1. 이메일 또는 전화번호 입력
2. OTP 인증 후 아이디 확인

### 비밀번호 찾기

1. 아이디(username) 입력
2. OTP 인증 (이메일 / SMS 선택)
3. 새 비밀번호 입력

### 사용자 프로파일

로그인 후 계정 페이지에서 `phoneNumber`, `otpMethod` 같은 커스텀 속성을 확인하고 수정할 수 있습니다.

---

## 4. Admin Console

http://localhost:8080 → **Administration Console** → Realm: **`cnap`**

- ID: `admin` / PW: `password`

이 데모의 핵심은 Admin Console에 등록된 Extension 설정들입니다.

### Authentication Flow

**Authentication → Flows** 에서 아래 커스텀 플로우를 확인할 수 있습니다.

| Flow | 적용 위치 | 설명 |
|---|---|---|
| `browser-otp` | Browser flow | 로그인 OTP + 휴면 계정 차단 |
| `registration-term` | Registration flow | 회원가입 시 약관 동의 수집 |
| `reset credentials-otp` | Reset credentials flow | 비밀번호 재설정 OTP |

### Required Actions

**Authentication → Required Actions** 에서 확인합니다.

- `Terms and Marketing Consent` — 신규 사용자에게 자동으로 할당되는 약관·마케팅 동의 액션
- `Reactivate Dormant Account` — 휴면 계정 재활성화 액션 (Dormant Check가 트리거)

### 이벤트 리스너

**Realm Settings → Events → Event listeners** 에 아래 리스너가 등록되어 있습니다.

- `last-login-tracker` — 로그인 성공마다 `lastLoginDate` 속성 자동 업데이트
- `user-event-publisher` — 사용자 생성·수정·삭제 이벤트를 RabbitMQ로 발행
- `metrics-listener` — Keycloak 이벤트를 Prometheus 메트릭으로 노출

RabbitMQ 관리 UI(http://localhost:15672)에서 실시간으로 메시지가 쌓이는 걸 볼 수 있습니다.

### User Federation

**User Federation** 에 세 가지 Provider가 등록되어 있습니다.

- `dormant-account-scheduler` — 365일 미접속 시 휴면 전환, 90일 후 계정 삭제
- `terms-change-notifier` — 약관 변경 사전 고지 스케줄러
- `REST` — 외부 User Storage API 연동 (http://localhost:8090)

### 소셜 로그인 (Identity Provider)

**Identity Providers** 에서 카카오, 네이버, 이니시스 간편인증 설정을 볼 수 있습니다.

소셜 로그인은 기존 계정과의 **연동** 방식으로 동작합니다. 이메일(카카오·네이버) 또는 전화번호(이니시스)로 가입된 계정을 찾아 자동으로 연결합니다.

### 이용약관 설정

약관 콘텐츠는 아래 경로의 HTML 파일로 관리합니다.

```
docker/terms-content/
  {realm}/
    1.0/ko/
      service.html
      privacy_required.html
      privacy_optional.html
      marketing.html
```

---

## 5. 환경 변수 설정

[docker/compose.yaml](docker/compose.yaml) `keycloak` 서비스의 `environment` 블록입니다.

| 변수 | 기본값 | 설명 |
|---|---|---|
| `OTP_DEV_MODE` | `true` | `000000`으로 OTP 통과 — **운영에서는 반드시 제거** |
| `OTP_CODE_LIFESPAN_SECONDS` | `300` | 인증코드 유효 시간(초) |
| `OTP_RATE_LIMIT_MAX_ATTEMPTS` | `5` | OTP 최대 시도 횟수 |
| `OTP_RATE_LIMIT_LOCKOUT_MINUTES` | `30` | 초과 시 잠금 시간(분) |
| `SMS_PROVIDER` | `aws_sns_x` | 실 SMS: `aws_sns` / 현재는 더미(fallback) |
| `USER_EVENT_CHANNEL` | `rabbitmq` | 이벤트 채널 (`rabbitmq` \| `kafka` \| `redis` \| 미설정 시 log-only) |

---

## 6. Make 명령어

```bash
make up                      # 전체 서비스 시작 (백그라운드)
make down                    # 전체 서비스 중지 및 컨테이너 제거
make clean                   # 컨테이너 + 볼륨 + 이미지 + data/ 전체 삭제

make up-svc SVC=keycloak     # 단일 서비스만 시작 (의존성 제외)
make down-svc SVC=keycloak   # 단일 서비스만 중지 및 제거

make restart                 # 전체 재시작
make logs                    # 전체 로그 스트리밍
make ps                      # 서비스 상태 확인
```

---

## 7. 참고 자료

### 문서

| 문서 | 내용 |
|---|---|
| [docs/01-features.md](docs/01-features.md) | 주요 기능 소개 |
| [docs/02-installation.md](docs/02-installation.md) | SPI 상세 설치 및 Admin Console 설정 가이드 |
| [docs/03-user_guide.md](docs/03-user_guide.md) | 사용자 가이드 |
| [docs/04-developer_guide.md](docs/04-developer_guide.md) | 개발자 가이드 |
| [docs/05-dormant-account-test-runbook.md](docs/05-dormant-account-test-runbook.md) | 휴면 계정 테스트 런북 |
| [docs/06-usp-integration-guide.md](docs/06-usp-integration-guide.md) | User Storage REST API 연동 가이드 |
| [docs/07-terms-guide.md](docs/07-terms-guide.md) | 이용약관 운영 가이드 |

### 관련 저장소

| 저장소 | 설명 |
|---|---|
| [cnapcloud/keycloak-user-storage](https://github.com/cnapcloud/keycloak-user-storage) | 외부 User Storage REST API 구현체 |
| [cnapcloud/react-keycloak-demo](https://github.com/cnapcloud/react-keycloak-demo) | React 인증 데모 앱 |
| [cnapcloud/inicis-mock-server](https://github.com/cnapcloud/inicis-mock-server) | 이니시스 간편인증 Mock 서버 |
